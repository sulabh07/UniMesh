<?php
require_once __DIR__ . '/bootstrap.php';

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
if ($id <= 0) {
    api_error(400, 'Invalid attempt id');
}

$stmt = $pdo->prepare('SELECT * FROM attempts WHERE id = ?');
$stmt->execute([$id]);
$a = $stmt->fetch();

if (!$a) {
    api_error(404, 'Attempt not found');
}

echo json_encode([
    'attemptId'     => (string) $a['id'],
    'userName'      => $a['user_name'],
    'language'      => $a['language'],
    'languageLabel' => ai_language_labels()[$a['language']] ?? $a['language'],
    'status'        => $a['status'],
    'result'        => $a['result'] ? json_decode($a['result'], true) : null,
]);
