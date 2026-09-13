<?php
require_once __DIR__ . '/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    api_error(405, 'Method not allowed');
}

$body = api_body();
$language = $body['language'] ?? '';
$userName = trim((string) ($body['userName'] ?? 'Guest'));
if ($userName === '') {
    $userName = 'Guest';
}
$userName = substr($userName, 0, 40);

// Optional signed launch context from the Unimesh Student site.
$unimeshUserId = null;
$unimeshSkillId = null;
if (($body['source'] ?? '') === 'unimesh') {
    global $UNIMESH_SHARED_SECRET;
    $candidateUserId = (int)($body['userId'] ?? 0);
    $candidateSkillId = (int)($body['skillId'] ?? 0);
    $ts = (int)($body['ts'] ?? 0);
    $sig = (string)($body['sig'] ?? '');
    $payload = $candidateUserId . '|' . $candidateSkillId . '|' . $language . '|' . $ts;
    $expected = hash_hmac('sha256', $payload, $UNIMESH_SHARED_SECRET);
    if ($candidateUserId <= 0 || $candidateSkillId <= 0 || abs(time() - $ts) > 1800 || !hash_equals($expected, $sig)) {
        api_error(403, 'Invalid or expired Unimesh assessment link. Return to Unimesh and launch the test again.');
    }
    $unimeshUserId = $candidateUserId;
    $unimeshSkillId = $candidateSkillId;
}

if (!in_array($language, ai_languages(), true)) {
    api_error(400, "Unsupported language: {$language}");
}

$timeLimits  = ai_time_limits();
$levelLabels = ai_level_labels();

// Two random questions per difficulty level 1..5 (10 questions total)
$picked = [];
foreach ([1, 2, 3, 4, 5] as $level) {
    $stmt = $pdo->prepare('SELECT * FROM questions WHERE language = ? AND level = ? ORDER BY RAND() LIMIT 2');
    $stmt->execute([$language, $level]);
    $rows = $stmt->fetchAll();
    if (count($rows) < 2) {
        api_error(500, "Need at least 2 questions for {$language} level {$level}. Run seed.php first.");
    }
    foreach ($rows as $q) {
        $picked[] = $q;
    }
}

$slots = array_map(function ($q) use ($timeLimits) {
    return [
        'questionId'  => (int) $q['id'],
        'level'       => (int) $q['level'],
        'timeLimitMs' => $timeLimits[(int) $q['level']] * 1000,
    ];
}, $picked);

$stmt = $pdo->prepare(
    'INSERT INTO attempts (user_name, language, status, slots, unimesh_user_id, unimesh_skill_id, started_at) VALUES (?, ?, "in_progress", ?, ?, ?, NOW())'
);
$stmt->execute([$userName, $language, json_encode($slots), $unimeshUserId, $unimeshSkillId]);
$attemptId = (int) $pdo->lastInsertId();

// Never leak correct_index / explanation to the client during the test.
$questionsOut = array_map(function ($q) use ($timeLimits, $levelLabels) {
    return [
        'id'          => (int) $q['id'],
        'level'       => (int) $q['level'],
        'levelLabel'  => $levelLabels[(int) $q['level']],
        'text'        => $q['text'],
        'code'        => $q['code'] ?? '',
        'options'     => json_decode($q['options'], true),
        'timeLimitMs' => $timeLimits[(int) $q['level']] * 1000,
    ];
}, $picked);

echo json_encode([
    'attemptId'     => (string) $attemptId,
    'language'      => $language,
    'languageLabel' => ai_language_labels()[$language],
    'timeLimits'    => $timeLimits,
    'questions'     => $questionsOut,
]);
