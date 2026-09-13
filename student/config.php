<?php
// All independent sites connect to the SAME MySQL database.
define('DB_HOST', 'localhost');
define('DB_NAME', 'unimesh');
define('DB_USER', 'root');
define('DB_PASS', '');
define('SITE_ROLE', 'student');
define('SITE_LABEL', 'Student');

// SkillAI integration. Keep this secret identical to assessment/config.php.
define('SKILLAI_SHARED_SECRET', 'unimesh-skillai-local-integration-2026');
define('SKILLAI_URL', '../assessment/index.html');

// A unique session name is what allows simultaneous logins in the same browser.
if (session_status() === PHP_SESSION_NONE) {
    session_name('UNIMESH_STUDENT_SESSION');
    session_start();
}

try {
    $pdo = new PDO(
        'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
         PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
    );
} catch (PDOException $e) {
    exit('Database connection failed. Check config.php and import ../database.sql in phpMyAdmin.');
}
