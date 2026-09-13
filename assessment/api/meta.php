<?php
require_once __DIR__ . '/bootstrap.php';

$timeLimits = ai_time_limits();
$totalTimeMs = 0;
foreach ($timeLimits as $seconds) {
    $totalTimeMs += $seconds * 1000 * 2;
}

echo json_encode([
    'languages'       => ai_languages(),
    'languageLabels'  => ai_language_labels(),
    'levelLabels'     => ai_level_labels(),
    'timeLimits'      => $timeLimits,
    'totalTimeMs'     => $totalTimeMs,
    'maxRating'       => AI_MAX_RATING,
    'questionsPerTest' => 10,
]);
