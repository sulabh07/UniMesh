<?php
/**
 * Database + app configuration.
 * Edit these values to match your MySQL / phpMyAdmin setup.
 */

$DB_HOST = '127.0.0.1';
$DB_NAME = 'skillai';
$DB_USER = 'root';
$DB_PASS = '';          // set your MySQL password here (XAMPP/WAMP default is empty)
$DB_PORT = '3306';

// Optional — enables an LLM-written narrative on the results page.
// Leave empty to use the built-in rule-based narrative (no external calls, works offline).
$OPENAI_API_KEY = '';
$OPENAI_MODEL   = 'gpt-4o-mini';

// Unimesh integration settings. These are only used when the assessment is
// launched from /student/assessments.php. Keep the secret identical there.
$UNIMESH_SHARED_SECRET = 'unimesh-skillai-local-integration-2026';
$UNIMESH_DB_HOST = '127.0.0.1';
$UNIMESH_DB_NAME = 'unimesh';
$UNIMESH_DB_USER = 'root';
$UNIMESH_DB_PASS = '';
$UNIMESH_DB_PORT = '3306';

try {
    $pdo = new PDO(
        "mysql:host={$DB_HOST};port={$DB_PORT};dbname={$DB_NAME};charset=utf8mb4",
        $DB_USER,
        $DB_PASS,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]
    );
} catch (PDOException $e) {
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode([
        'error' => 'Database connection failed: ' . $e->getMessage()
            . '. Check config.php and confirm the "skillai" database has been imported via phpMyAdmin.',
    ]);
    exit;
}
