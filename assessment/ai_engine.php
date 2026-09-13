<?php
/**
 * SkillAI Engine (PHP port)
 * -------------------------
 * Deterministic, explainable scoring model that:
 *   1. Picks two questions per difficulty level (1–5), 10 total
 *   2. Enforces a per-level time limit (server-side, never trusts the client clock)
 *   3. Scores each answer on (difficulty weight) x (speed factor)
 *   4. Produces a 0–5 rating, band, strengths, weaknesses, recommendations
 *   5. Optionally augments the narrative with an LLM (set $OPENAI_API_KEY in config.php)
 */

function ai_languages(): array {
    return ['python', 'cpp', 'html', 'java', 'sql'];
}

function ai_language_labels(): array {
    return [
        'python' => 'Python',
        'cpp'    => 'C++',
        'html'   => 'HTML',
        'java'   => 'Java',
        'sql'    => 'SQL',
    ];
}

/** Seconds allowed per difficulty level. */
function ai_time_limits(): array {
    return [1 => 30, 2 => 45, 3 => 60, 4 => 90, 5 => 120];
}

function ai_level_labels(): array {
    return [1 => 'Basic', 2 => 'Easy', 3 => 'Medium', 4 => 'Hard', 5 => 'Expert'];
}

/** Two questions per level: 2 × (1+2+3+4+5) = 30 max weighted points. */
define('AI_MAX_POINTS', 30);
define('AI_MAX_RATING', 5);

/** Guaranteed share for a correct answer, however slow, plus a speed bonus. */
define('AI_BASE_WEIGHT', 0.85);
define('AI_SPEED_WEIGHT', 0.15);

/** Topic roadmap used to generate recommendations. Index = level - 1. */
function ai_topic_map(): array {
    return [
        'python' => [
            'Syntax, variables, types and I/O',
            'Operators, control flow and loops',
            'Functions, lists, dicts, sets and comprehensions',
            'OOP, exceptions, iterators and decorators',
            'Generators, async/await, GIL, metaclasses and performance',
        ],
        'cpp' => [
            'Syntax, headers, types and std::cin/cout',
            'Control flow, arrays, references and functions',
            'Pointers, dynamic memory, classes and STL basics',
            'OOP, STL containers, RAII and smart pointers',
            'Move semantics, templates, concurrency and the rule of five',
        ],
        'html' => [
            'Tags, attributes and document structure',
            'Lists, links, images, tables and forms',
            'Semantic elements and native form validation',
            'Accessibility, ARIA and labels',
            'Resource hints, performance, SEO and Web Components',
        ],
        'java' => [
            'Syntax, primitive types and the main method',
            'Loops, arrays, Strings and ArrayList',
            'Classes, inheritance, interfaces and exceptions',
            'Collections, generics, equals/hashCode and streams',
            'Concurrency, volatile, the memory model and the JVM',
        ],
        'sql' => [
            'SELECT, WHERE, ORDER BY and LIMIT',
            'JOINs, GROUP BY and aggregate functions',
            'Subqueries, CASE, set operators and WHERE vs HAVING',
            'Indexes, normalisation, transactions and isolation',
            'Window functions, execution plans and query tuning',
        ],
    ];
}

/**
 * Score a completed attempt.
 * @param string $language
 * @param array  $items  [{ level, isCorrect, timeTakenMs, timeLimitMs }, ...]
 */
function ai_evaluate_attempt(string $language, array $items): array {
    usort($items, fn($a, $b) => $a['level'] <=> $b['level']);

    $levelLabels = ai_level_labels();
    $earnedPoints = 0.0;
    $correctCount = 0;
    $totalTimeMs = 0;
    $breakdown = [];

    foreach ($items as $it) {
        $timeLimitMs = (int) $it['timeLimitMs'];
        $timeTakenMs = max(0, min($timeLimitMs, (int) ($it['timeTakenMs'] ?? $timeLimitMs)));
        $speedRatio  = max(0, min(1, 1 - $timeTakenMs / max(1, $timeLimitMs)));
        $speedFactor = AI_BASE_WEIGHT + AI_SPEED_WEIGHT * $speedRatio;
        $maxPoints   = (int) $it['level'];
        $pointsEarned = $it['isCorrect'] ? $maxPoints * $speedFactor : 0.0;

        $earnedPoints += $pointsEarned;
        $totalTimeMs  += $timeTakenMs;
        if ($it['isCorrect']) {
            $correctCount++;
        }

        $breakdown[] = [
            'level'        => (int) $it['level'],
            'levelLabel'   => $levelLabels[(int) $it['level']],
            'isCorrect'    => (bool) $it['isCorrect'],
            'timeTakenMs'  => $timeTakenMs,
            'timeLimitMs'  => $timeLimitMs,
            'speedRatio'   => round($speedRatio, 3),
            'pointsEarned' => round($pointsEarned, 3),
            'maxPoints'    => $maxPoints,
        ];
    }

    $rating  = round(($earnedPoints / AI_MAX_POINTS) * AI_MAX_RATING, 1);
    $percent = round(($earnedPoints / AI_MAX_POINTS) * 100, 1);
    $speedSum = array_sum(array_column($breakdown, 'speedRatio'));
    $avgSpeedRatio = count($breakdown) ? round($speedSum / count($breakdown), 3) : 0;

    // Consistency: how often a harder question was answered at least as well as an easier one.
    $flags = array_map(fn($i) => $i['isCorrect'] ? 1 : 0, $items);
    $pairs = 0;
    $ordered = 0;
    $n = count($flags);
    for ($i = 0; $i < $n; $i++) {
        for ($j = $i + 1; $j < $n; $j++) {
            $pairs++;
            if ($flags[$i] >= $flags[$j]) {
                $ordered++;
            }
        }
    }
    $consistency = $pairs ? (int) round(($ordered / $pairs) * 100) : 100;

    $band = ai_band_for($rating);
    $insights = ai_build_insights($breakdown, $avgSpeedRatio);
    $recommendations = ai_build_recommendations($language, $breakdown, $avgSpeedRatio, $rating);

    $result = [
        'rating'          => $rating,
        'percent'         => $percent,
        'band'            => $band,
        'correctCount'    => $correctCount,
        'totalQuestions'  => count($items),
        'earnedPoints'    => round($earnedPoints, 2),
        'maxPoints'       => AI_MAX_POINTS,
        'totalTimeMs'     => $totalTimeMs,
        'totalTimeSec'    => round($totalTimeMs / 1000, 1),
        'avgSpeedRatio'   => $avgSpeedRatio,
        'consistency'     => $consistency,
        'breakdown'       => $breakdown,
        'strengths'       => $insights['strengths'],
        'weaknesses'      => $insights['weaknesses'],
        'recommendations' => $recommendations,
    ];
    $result['summary'] = ai_build_summary($rating, $band, $correctCount, count($items), $breakdown);

    return $result;
}

function ai_band_for(float $rating): string {
    if ($rating >= 4.0) return 'Expert';
    if ($rating >= 3.0) return 'Advanced';
    if ($rating >= 2.0) return 'Intermediate';
    if ($rating >= 1.0) return 'Novice';
    return 'Beginner';
}

function ai_build_insights(array $breakdown, float $avgSpeedRatio): array {
    $strengths = [];
    $weaknesses = [];

    foreach ($breakdown as $b) {
        if ($b['isCorrect']) {
            $strengths[] = $b['speedRatio'] >= 0.4
                ? "Confident & fast at L{$b['level']} — {$b['levelLabel']}"
                : "Solid grasp of L{$b['level']} — {$b['levelLabel']} (just slow)";
        } else {
            $weaknesses[] = "Gap at L{$b['level']} — {$b['levelLabel']}";
        }
    }

    if ($avgSpeedRatio < 0.25 && count($strengths)) {
        $strengths[] = 'Accurate, though your pace leaves room to improve';
    }
    if ($avgSpeedRatio > 0.6) {
        $strengths[] = 'Excellent time management under pressure';
    }

    return ['strengths' => $strengths, 'weaknesses' => $weaknesses];
}

function ai_build_recommendations(string $language, array $breakdown, float $avgSpeedRatio, float $rating): array {
    $topics = ai_topic_map()[$language] ?? [];
    $labels = ai_language_labels();
    $recs = [];

    $failed = array_values(array_map(
        fn($b) => $b['level'],
        array_filter($breakdown, fn($b) => !$b['isCorrect'])
    ));
    $slowCorrect = array_values(array_map(
        fn($b) => $b['level'],
        array_filter($breakdown, fn($b) => $b['isCorrect'] && $b['speedRatio'] < 0.3)
    ));

    if (count($failed) === 0) {
        $recs[] = "You cleared every difficulty level in {$labels[$language]}. Move on to timed mock interviews and L5 material: {$topics[4]}.";
    } else {
        $lowest = min($failed);
        $recs[] = "Start from the lowest failed level (L{$lowest}). Revise: {$topics[$lowest - 1]}.";
        if ($lowest > 1) {
            $recs[] = "Reinforce the foundation at L" . ($lowest - 1) . " too — {$topics[$lowest - 2]} — since later levels build on it.";
        }
        foreach ($failed as $lv) {
            if ($lv > $lowest) {
                $recs[] = "Then drill L{$lv}: {$topics[$lv - 1]}.";
            }
        }
    }

    if (count($slowCorrect)) {
        $recs[] = "You answered L" . implode(', L', $slowCorrect) . " correctly but slowly. Do timed drills (60% of the normal clock) to build recall speed.";
    }

    if ($avgSpeedRatio < 0.3 && count($failed) === 0) {
        $recs[] = 'Practise with a stopwatch — speed is the only thing between you and a 5.0 rating.';
    }

    if ($rating >= 4.5) {
        $recs[] = 'Excellent. Try the same format in a second language to test transfer of fundamentals.';
    }

    $recs[] = "Build one small end-to-end project in {$labels[$language]} that forces you to use L4–L5 concepts in practice.";

    return $recs;
}

function ai_build_summary(float $rating, string $band, int $correctCount, int $totalQuestions, array $breakdown): string {
    $failedLevels = array_map(
        fn($b) => "L{$b['level']}",
        array_values(array_filter($breakdown, fn($b) => !$b['isCorrect']))
    );
    $ratingStr = number_format($rating, 1);
    if ($correctCount === $totalQuestions) {
        return "Perfect run — {$correctCount}/{$totalQuestions} correct with a {$ratingStr}/5.0 rating ({$band}).";
    }
    $failStr = count($failedLevels) ? implode(', ', $failedLevels) : 'none';
    return "{$correctCount}/{$totalQuestions} correct. Rating {$ratingStr}/5.0 ({$band}). Weakest levels: {$failStr}.";
}

/* ------------------------------------------------------------------ */
/*  Narrative generation (rule-based, with optional LLM augmentation)  */
/* ------------------------------------------------------------------ */

function ai_rule_based_narrative(string $language, array $result, string $userName): string {
    $labels = ai_language_labels();
    $name = ($userName && $userName !== 'Guest') ? $userName : 'You';

    $strong = count($result['strengths'])
        ? strtolower(implode(' and ', array_slice($result['strengths'], 0, 2)))
        : 'no standout strengths yet';
    $weak = count($result['weaknesses'])
        ? strtolower(implode(', ', $result['weaknesses']))
        : 'no significant gaps';

    if ($result['correctCount'] >= 4) {
        $tail = 'This is a strong, interview-ready result for most junior-to-mid roles — keep the momentum with timed practice.';
    } elseif ($result['correctCount'] >= 2) {
        $tail = 'This is a reasonable base. Focus on the failed levels in order, and re-test within a week to confirm improvement.';
    } else {
        $tail = 'The fundamentals need shoring up first. Work through the recommended topics slowly, then retake the assessment.';
    }

    $ratingStr = number_format($result['rating'], 1);
    $speedPct = round($result['avgSpeedRatio'] * 100);

    return "{$name} scored {$ratingStr} / 5.0 in {$labels[$language]}, placing you in the {$result['band']} band "
        . "with {$result['correctCount']} of {$result['totalQuestions']} questions correct. "
        . "Strengths: {$strong}. Gaps: {$weak}. "
        . "You used {$result['totalTimeSec']}s of the available clock and your speed score was {$speedPct}%. "
        . $tail;
}

function ai_generate_narrative(string $language, array $result, string $userName): string {
    global $OPENAI_API_KEY, $OPENAI_MODEL;

    $fallback = ai_rule_based_narrative($language, $result, $userName);

    if (empty($OPENAI_API_KEY)) {
        return $fallback;
    }

    $labels = ai_language_labels();
    $payload = [
        'model'       => $OPENAI_MODEL ?: 'gpt-4o-mini',
        'temperature' => 0.5,
        'max_tokens'  => 220,
        'messages'    => [
            [
                'role'    => 'system',
                'content' => 'You are a concise technical skills assessor. Given a scored coding assessment, write a 3-4 sentence '
                    . 'encouraging but honest analysis. Mention the rating, band, one strength, one gap, and one concrete '
                    . 'next step. No markdown, no bullet points, plain prose only.',
            ],
            [
                'role'    => 'user',
                'content' => json_encode([
                    'language'          => $labels[$language] ?? $language,
                    'rating'            => $result['rating'],
                    'band'              => $result['band'],
                    'correct'           => "{$result['correctCount']}/{$result['totalQuestions']}",
                    'speedScorePercent' => round($result['avgSpeedRatio'] * 100),
                    'breakdown'         => array_map(fn($b) => [
                        'level'   => $b['level'],
                        'label'   => $b['levelLabel'],
                        'correct' => $b['isCorrect'],
                        'seconds' => round($b['timeTakenMs'] / 1000, 1),
                    ], $result['breakdown']),
                ]),
            ],
        ],
    ];

    try {
        $ch = curl_init('https://api.openai.com/v1/chat/completions');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                "Authorization: Bearer {$OPENAI_API_KEY}",
            ],
            CURLOPT_POSTFIELDS => json_encode($payload),
            CURLOPT_TIMEOUT    => 15,
        ]);
        $res = curl_exec($ch);
        $err = curl_errno($ch);
        curl_close($ch);

        if ($err || !$res) {
            return $fallback;
        }

        $data = json_decode($res, true);
        $text = $data['choices'][0]['message']['content'] ?? null;
        return $text ? trim($text) : $fallback;
    } catch (\Throwable $e) {
        return $fallback;
    }
}
