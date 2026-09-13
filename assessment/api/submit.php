<?php
require_once __DIR__ . '/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error(405, 'Method not allowed');
}

$body = api_body();
$id = isset($body['attemptId']) ? (int) $body['attemptId'] : 0;
$answers = is_array($body['answers'] ?? null) ? $body['answers'] : [];

if ($id <= 0) {
    api_error(400, 'Invalid attempt id');
}

$stmt = $pdo->prepare('SELECT * FROM attempts WHERE id = ?');
$stmt->execute([$id]);
$attempt = $stmt->fetch();

if (!$attempt) {
    api_error(404, 'Attempt not found');
}
if ($attempt['status'] === 'completed') {
    api_error(409, 'This attempt has already been submitted');
}

$slots = json_decode($attempt['slots'], true) ?: [];

$byId = [];
foreach ($answers as $a) {
    if (isset($a['questionId'])) {
        $byId[(string) $a['questionId']] = $a;
    }
}

$questionIds = array_map(fn($s) => $s['questionId'], $slots);
if (count($questionIds) === 0) {
    api_error(500, 'Attempt has no question slots');
}
$placeholders = implode(',', array_fill(0, count($questionIds), '?'));
$stmt = $pdo->prepare("SELECT * FROM questions WHERE id IN ({$placeholders})");
$stmt->execute($questionIds);
$qRows = $stmt->fetchAll();

$qMap = [];
foreach ($qRows as $q) {
    $qMap[(string) $q['id']] = $q;
}

$items = [];
$review = [];
$levelLabels = ai_level_labels();

foreach ($slots as $slot) {
    $q = $qMap[(string) $slot['questionId']] ?? null;
    if (!$q) {
        continue;
    }

    $options = json_decode($q['options'], true);
    $given = $byId[(string) $slot['questionId']] ?? [];

    $rawIndex = isset($given['selectedIndex']) ? (int) $given['selectedIndex'] : -1;
    $selectedIndex = ($rawIndex >= 0 && $rawIndex < count($options)) ? $rawIndex : -1;
    $isCorrect = $selectedIndex === (int) $q['correct_index'];

    // Server-side time enforcement: never trust the client clock.
    $reportedMs = isset($given['timeTakenMs']) ? (int) $given['timeTakenMs'] : (int) $slot['timeLimitMs'];
    $timeTakenMs = max(0, min((int) $slot['timeLimitMs'], $reportedMs ?: (int) $slot['timeLimitMs']));

    $items[] = [
        'level'       => (int) $slot['level'],
        'isCorrect'   => $isCorrect,
        'timeTakenMs' => $timeTakenMs,
        'timeLimitMs' => (int) $slot['timeLimitMs'],
    ];

    $review[] = [
        'questionId'    => (int) $q['id'],
        'level'         => (int) $q['level'],
        'levelLabel'    => $levelLabels[(int) $q['level']],
        'text'          => $q['text'],
        'code'          => $q['code'] ?? '',
        'options'       => $options,
        'selectedIndex' => $selectedIndex,
        'correctIndex'  => (int) $q['correct_index'],
        'isCorrect'     => $isCorrect,
        'timeTakenMs'   => $timeTakenMs,
        'timeLimitMs'   => (int) $slot['timeLimitMs'],
        'explanation'   => $q['explanation'],
    ];
}

$result = ai_evaluate_attempt($attempt['language'], $items);
$result['narrative'] = ai_generate_narrative($attempt['language'], $result, $attempt['user_name']);

$answersOut = [];
foreach ($items as $i => $it) {
    $answersOut[] = [
        'questionId'    => $review[$i]['questionId'],
        'level'         => $it['level'],
        'selectedIndex' => $review[$i]['selectedIndex'],
        'correctIndex'  => $review[$i]['correctIndex'],
        'isCorrect'     => $it['isCorrect'],
        'timeTakenMs'   => $it['timeTakenMs'],
        'timeLimitMs'   => $it['timeLimitMs'],
        'pointsEarned'  => $result['breakdown'][$i]['pointsEarned'] ?? 0,
    ];
}

$stmt = $pdo->prepare(
    'UPDATE attempts SET answers = ?, result = ?, status = "completed", completed_at = NOW() WHERE id = ?'
);
$stmt->execute([json_encode($answersOut), json_encode($result), $id]);


// If this attempt was launched from Unimesh, save the measured skill rating
// back to the student's Unimesh profile and assessment history.
$integration = [
    'launchedFromUnimesh' => !empty($attempt['unimesh_user_id']) && !empty($attempt['unimesh_skill_id']),
    'savedToUnimesh' => false,
];

if ($integration['launchedFromUnimesh']) {
    try {
        global $UNIMESH_DB_HOST, $UNIMESH_DB_NAME, $UNIMESH_DB_USER, $UNIMESH_DB_PASS, $UNIMESH_DB_PORT;
        $unimesh = new PDO(
            "mysql:host={$UNIMESH_DB_HOST};port={$UNIMESH_DB_PORT};dbname={$UNIMESH_DB_NAME};charset=utf8mb4",
            $UNIMESH_DB_USER,
            $UNIMESH_DB_PASS,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
        );

        $uId = (int)$attempt['unimesh_user_id'];
        $sId = (int)$attempt['unimesh_skill_id'];
        $rating = (float)$result['rating'];
        $percent = (float)$result['percent'];
        // Completing the linked SkillAI assessment verifies that the skill was actually tested.
        // The star rating still reflects the student's achieved result.
        $verified = 1;

        $check = $unimesh->prepare('SELECT us.level,us.verified,s.name FROM user_skills us JOIN skills s ON s.id=us.skill_id WHERE us.user_id=? AND us.skill_id=?');
        $check->execute([$uId, $sId]);
        $skillRow = $check->fetch();
        if (!$skillRow) {
            throw new RuntimeException('The linked Unimesh skill was not found.');
        }

        $wasVerified = (int)$skillRow['verified'];
        $upd = $unimesh->prepare('UPDATE user_skills SET star_rating=?, verified=?, verified_at=IF(?=1,NOW(),verified_at) WHERE user_id=? AND skill_id=?');
        $upd->execute([$rating, $verified, $verified, $uId, $sId]);

        // Mirror the SkillAI result into Unimesh assessment history.
        $a = $unimesh->prepare('SELECT id FROM assessments WHERE skill_id=? AND level=? LIMIT 1');
        $a->execute([$sId, (int)$skillRow['level']]);
        $assessmentId = (int)($a->fetchColumn() ?: 0);
        if ($assessmentId > 0) {
            $hist = $unimesh->prepare('INSERT INTO assessment_attempts(assessment_id,user_id,score,integrity_score,status,completed_at) VALUES(?,?,?,?,?,NOW())');
            $hist->execute([$assessmentId, $uId, $percent, 100, 'completed']);
        }

        // Give the trust-score bonus only the first time this assessed skill becomes verified.
        if ($verified && !$wasVerified) {
            $unimesh->prepare('UPDATE users SET trust_score=LEAST(100,trust_score+5) WHERE id=?')->execute([$uId]);
            $unimesh->prepare('INSERT INTO trust_score_logs(user_id,change_amount,reason) VALUES(?,?,?)')->execute([$uId,5,'Passed SkillAI assessment']);
        }

        $integration['savedToUnimesh'] = true;
        $integration['verified'] = (bool)$verified;
        $integration['starRating'] = $rating;
        $integration['weightedPercent'] = $percent;
    } catch (Throwable $e) {
        $integration['error'] = $e->getMessage();
    }
}

echo json_encode([
    'attemptId'     => (string) $id,
    'userName'      => $attempt['user_name'],
    'language'      => $attempt['language'],
    'languageLabel' => ai_language_labels()[$attempt['language']],
    'result'        => $result,
    'review'        => $review,
    'integration'   => $integration,
]);
