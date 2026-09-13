<?php
/**
 * Optional re-seeder for SkillAI.
 * database.sql already inserts the 250 questions automatically.
 * Use this file only when you want to reload data/questions.json.
 */
require_once __DIR__ . '/config.php';
header('Content-Type: text/plain; charset=utf-8');

$jsonPath = __DIR__ . '/data/questions.json';
$raw = @file_get_contents($jsonPath);
if ($raw === false) {
    echo "ERROR: Could not read {$jsonPath}\n";
    exit(1);
}
$questions = json_decode($raw, true);
if (!is_array($questions)) {
    echo "ERROR: Failed to parse data/questions.json: " . json_last_error_msg() . "\n";
    exit(1);
}

$expectedLanguages = ['python','cpp','html','java','sql'];
$counts = [];
foreach ($questions as $i => $q) {
    foreach (['language','level','text','options','correctIndex'] as $field) {
        if (!array_key_exists($field, $q)) {
            echo "ERROR: Question #" . ($i + 1) . " is missing {$field}.\n";
            exit(1);
        }
    }
    if (!in_array($q['language'], $expectedLanguages, true) || (int)$q['level'] < 1 || (int)$q['level'] > 5) {
        echo "ERROR: Invalid language/level in question #" . ($i + 1) . ".\n";
        exit(1);
    }
    if (!is_array($q['options']) || count($q['options']) !== 4) {
        echo "ERROR: Question #" . ($i + 1) . " must have exactly 4 options.\n";
        exit(1);
    }
    $key = $q['language'] . ':' . (int)$q['level'];
    $counts[$key] = ($counts[$key] ?? 0) + 1;
}
if (count($questions) !== 250) {
    echo "ERROR: Expected 250 questions, found " . count($questions) . ".\n";
    exit(1);
}
foreach ($expectedLanguages as $lang) {
    for ($level = 1; $level <= 5; $level++) {
        $key = $lang . ':' . $level;
        if (($counts[$key] ?? 0) !== 10) {
            echo "ERROR: Expected 10 questions for {$lang} level {$level}; found " . ($counts[$key] ?? 0) . ".\n";
            exit(1);
        }
    }
}

echo "Validated 250 questions (10 per level for each language).\n";
$pdo->beginTransaction();
try {
    $pdo->exec('DELETE FROM questions');
    $stmt = $pdo->prepare(
        'INSERT INTO questions (language, level, text, code, options, correct_index, explanation, tags)
         VALUES (:language, :level, :text, :code, :options, :correct_index, :explanation, :tags)'
    );
    $inserted = 0;
    foreach ($questions as $q) {
        $stmt->execute([
            ':language'      => $q['language'],
            ':level'         => (int)$q['level'],
            ':text'          => $q['text'],
            ':code'          => is_string($q['code'] ?? '') ? ($q['code'] ?? '') : '',
            ':options'       => json_encode($q['options'], JSON_UNESCAPED_UNICODE),
            ':correct_index' => (int)$q['correctIndex'],
            ':explanation'   => $q['explanation'] ?? '',
            ':tags'          => json_encode(is_array($q['tags'] ?? null) ? $q['tags'] : [], JSON_UNESCAPED_UNICODE),
        ]);
        $inserted++;
    }
    $pdo->commit();
} catch (Throwable $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    echo "ERROR while inserting questions: " . $e->getMessage() . "\n";
    exit(1);
}

echo "Inserted {$inserted} questions successfully.\n\n";
$result = $pdo->query('SELECT language, level, COUNT(*) AS n FROM questions GROUP BY language, level ORDER BY language, level')->fetchAll();
printf("%-10s %-6s %s\n", 'language', 'level', 'count');
foreach ($result as $r) printf("%-10s %-6s %s\n", $r['language'], $r['level'], $r['n']);
echo "\nSUCCESS. Open index.html and start a test.\n";
