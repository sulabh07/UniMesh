<?php
require_once __DIR__ . '/bootstrap.php';

// Order by the JSON-embedded rating (MySQL 5.7+/MariaDB 10.2+ support JSON_EXTRACT).
$sql = 'SELECT id, user_name, language, result, completed_at
        FROM attempts
        WHERE status = "completed"
        ORDER BY CAST(JSON_EXTRACT(result, "$.rating") AS DECIMAL(3,1)) DESC, completed_at ASC
        LIMIT 10';

$rows = $pdo->query($sql)->fetchAll();
$labels = ai_language_labels();

$out = [];
$rank = 1;
foreach ($rows as $r) {
    $result = $r['result'] ? json_decode($r['result'], true) : null;
    $out[] = [
        'rank'          => $rank++,
        'userName'      => $r['user_name'],
        'language'      => $r['language'],
        'languageLabel' => $labels[$r['language']] ?? $r['language'],
        'rating'        => $result['rating'] ?? 0,
        'band'          => $result['band'] ?? '—',
        'completedAt'   => $r['completed_at'],
    ];
}

echo json_encode(['leaderboard' => $out]);
