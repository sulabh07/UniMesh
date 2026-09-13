# Unimesh + SkillAI Assessment Integration

## What changed
- Student > Assessments now redirects supported skills to the bundled SkillAI assessment site.
- The redirect carries the logged-in student, selected Unimesh skill, SkillAI language, timestamp, and an HMAC signature.
- SkillAI verifies the signed launch before starting an integrated assessment.
- On submission, SkillAI writes the test result back into the Unimesh database.
- `user_skills.star_rating` receives the SkillAI 0.0-5.0 rating.
- `user_skills.verified` is set when the weighted SkillAI percentage is at least 70%.
- The completed SkillAI test is also inserted into Unimesh `assessment_attempts` history.
- A newly verified skill adds the existing +5 trust-score reward once.

## Supported Unimesh skill mappings
- Python -> python
- C++ -> cpp
- Java -> java
- MySQL -> sql
- HTML -> html

Other Unimesh skills remain visible but the assessment button explains that a SkillAI question bank is not yet available for them.

## Fresh setup
1. Put this folder under `C:\xampp\htdocs\` (for example `C:\xampp\htdocs\unimesh_php_independent`).
2. Start Apache and MySQL in XAMPP.
3. In phpMyAdmin import the root `database.sql` to create the `unimesh` database.
4. In phpMyAdmin import `assessment/database.sql` to create the `skillai` database and its question bank.
5. Open `http://localhost/unimesh_php_independent/student/`.
6. Log in as a student, add a supported skill, open Assessments and click **Take SkillAI Assessment**.

## Existing SkillAI database
If you already have the `skillai` database and do not want to re-import it, run:

`assessment/MIGRATION_UNIMESH_INTEGRATION.sql`

This adds only the two Unimesh linking columns to the existing SkillAI `attempts` table.

## Configuration
Both sides use the same integration secret. For local demo use it is already configured. If you change it, update it in:
- `student/config.php`
- `assessment/config.php`

The MySQL credentials in both configs must point to the same local MySQL server so SkillAI can update the Unimesh database after a test.


## Latest student profile and rating update
- Completing a linked SkillAI test now marks that Unimesh skill as **Verified**.
- The achieved SkillAI rating remains the measured 0–5 score and is shown as a five-star rating on Skills and Assessments.
- Student Profile now supports JPG, PNG and WEBP profile-photo uploads up to 5 MB. Photos are stored under `student/uploads/profile_photos/` and the existing `users.profile_photo` column is used, so no database migration is required for this feature.
