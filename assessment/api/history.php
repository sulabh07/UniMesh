<?php
require_once __DIR__ . '/bootstrap.php';

$userName = $_GET['userName'] ?? '';
if ($userName === '') {
    api_error(400, 'userName is required');
}

$stmt = $pdo->prepare(
    'SELECT id, language, result, completed_at FROM attempts
     WHERE user_name = ? AND status = "completed"
     ORDER BY completed_at DESC LIMIT 20'
);
$stmt->execute([$userName]);
$rows = $stmt->fetchAll();
$labels = ai_language_labels();

$out = array_map(function ($r) use ($labels) {
    $result = $r['result'] ? json_decode($r['result'], true) : null;
    return [
        'attemptId'     => (string) $r['id'],
        'language'      => $r['language'],
        'languageLabel' => $labels[$r['language']] ?? $r['language'],
        'rating'        => $result['rating'] ?? 0,
        'band'          => $result['band'] ?? '—',
        'correctCount'  => $result['correctCount'] ?? 0,
        'completedAt'   => $r['completed_at'],
    ];
}, $rows);

echo json_encode(['userName' => $userName, 'attempts' => $out]);
