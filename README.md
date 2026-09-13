# Unimesh PHP + MySQL — Independent Sites

This version has three independent gateways that share the same MySQL database:

- `/student/` — Student Site
- `/recruiter/` — Recruiter Site
- `/team-leader/` — Team Leader Site

Each gateway uses a different PHP session cookie, so you can log in to all three at the same time in separate tabs/windows on the same browser/device.

## Setup
1. Copy the folder to `C:\xampp\htdocs\unimesh_independent`.
2. Start Apache and MySQL in XAMPP.
3. Open phpMyAdmin and import `database.sql`.
4. Open `http://localhost/unimesh_independent/`.

## Direct URLs
- Student: `http://localhost/unimesh_independent/student/`
- Recruiter: `http://localhost/unimesh_independent/recruiter/`
- Team Leader: `http://localhost/unimesh_independent/team-leader/`

All three use the database configured in each site's `config.php` (default database: `unimesh`).

## Existing demo accounts
If you imported the included seeded SQL:
- Student: `student@unimesh.local` / `admin123`
- Recruiter: `recruiter@unimesh.local` / `admin123`
- Team Leader: `leader@unimesh.local` / `admin123`

Open all three URLs in separate tabs and log in simultaneously to test the independent sessions.


## SkillAI assessment integration

This build includes a new `/assessment/` folder containing the 10-question SkillAI engine.

### Fresh setup
1. Copy the whole `unimesh_php_independent` folder into `C:\xampp\htdocs\`.
2. Start Apache and MySQL in XAMPP.
3. In phpMyAdmin import the root `database.sql` (creates the `unimesh` database).
4. In phpMyAdmin import `assessment/database.sql` (creates the separate `skillai` database and its 250-question bank).
5. Open `http://localhost/unimesh_php_independent/student/` and log in.
6. Add one of the supported skills: Python, C++, Java, MySQL, or HTML/CSS.
7. Open Assessments and click **Take SkillAI Assessment**.
8. After submission, SkillAI writes the 0–5 rating back to `unimesh.user_skills.star_rating`. A weighted score of 70% or more marks the skill verified and the attempt appears in Unimesh assessment history.

The student-to-assessment link is HMAC-signed and expires after 30 minutes, so changing the student/skill IDs in the URL will invalidate the launch.
