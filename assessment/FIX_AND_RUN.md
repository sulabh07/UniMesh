# IMPORTANT FIX — 250-question version

This package uses the original working SkillAI PHP files.

## Recommended clean install
1. Start Apache and MySQL in XAMPP.
2. Open phpMyAdmin.
3. Delete the old `skillai` database if it exists (only if you do not need its old attempts).
4. Import this package's `database.sql`.
   - It now creates the tables AND inserts all 250 questions automatically.
5. In phpMyAdmin open `skillai` > `questions`. It should contain 250 rows.
6. Open `http://localhost/YOUR_FOLDER/index.html`.

## Alternative
If you already imported the schema, visit `http://localhost/YOUR_FOLDER/seed.php`.
It should print `Inserted 250 questions successfully` and show 10 for each language/level.

If the site still says no questions found, make sure `config.php` points to database name `skillai` and the same MySQL server opened by XAMPP.
