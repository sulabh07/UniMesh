# SkillAI — PHP + MySQL edition

A straight port of the MERN SkillAI app to a **PHP + MySQL** stack, built to deploy on any
standard LAMP/WAMP/XAMPP setup where the database is managed through **phpMyAdmin**. No
Node, no MongoDB, no build step — just PHP files and a static front end.

## How the "AI" works

Same deterministic, explainable scoring engine as the original, ported line-for-line into
`ai_engine.php`:

- Each level (1–5) is worth points equal to its level number (1+2+3+4+5 = 15 max).
- A correct answer earns `level × speedFactor` points, where `speedFactor` blends a
  guaranteed 85% base weight with up to a 15% bonus for answering quickly.
- The total is normalized to a **0.0–5.0 rating** with bands: Beginner → Novice →
  Intermediate → Advanced → Expert.
- A **consistency score** checks whether harder questions were answered at least as well
  as easier ones.
- Strengths, weaknesses, and next-step recommendations come from the per-level breakdown
  and a topic roadmap for each language.
- The "AI analysis" paragraph is built by a rule-based template by default — the whole app
  works with zero external dependencies. If you set `$OPENAI_API_KEY` in `config.php`, it
  calls OpenAI's chat completions API via cURL instead to phrase the same facts more
  naturally. The score itself never depends on the LLM.
- Time limits are enforced **server-side** in `api/submit.php` — the client's reported
  `timeTakenMs` is clamped to the level's time limit, so a tampered browser clock can't
  earn extra points.

## Requirements

- PHP 8.0+ with the **PDO MySQL** extension (`pdo_mysql`) enabled
- MySQL 5.7+ or MariaDB 10.2+ (needed for the `JSON` column type used by `attempts`/`questions`)
- Any web server that runs PHP: Apache/XAMPP, Nginx+PHP-FPM, WAMP, MAMP, or shared hosting

## Deploying via phpMyAdmin (XAMPP/WAMP example)

1. **Copy the project** into your web root, e.g. `C:\xampp\htdocs\skillai-php` or
   `/opt/lampp/htdocs/skillai-php`.

2. **Create the database and tables.**
   Open phpMyAdmin → **Import** tab → choose `database.sql` → Go.
   (This file contains `CREATE DATABASE IF NOT EXISTS skillai` plus the `questions` and
   `attempts` tables, so importing it is the only manual DB step.)

3. **Set your DB credentials** in `config.php` if they differ from the XAMPP defaults
   (`root` / empty password / `localhost`).

4. **Load the question bank.** The 50 built-in questions live in `data/questions.json`
   (kept as JSON specifically so no manual SQL-escaping of quotes/apostrophes is needed).
   Load them with `seed.php` — either:
   - visit `http://localhost/skillai-php/seed.php` in a browser, or
   - run `php seed.php` from the command line in the project folder.

   You should see a per-language/level count table confirming 50 rows were inserted.
   Safe to re-run any time — it clears and reloads the table.

5. **Open the app**: `http://localhost/skillai-php/index.html`.

No build step, no `npm install` — `index.html` loads `assets/app.js` (vanilla JS) and talks
to the PHP endpoints under `/api` directly via `fetch()`.

## Project layout

```
skillai-php/
├── database.sql          # CREATE DATABASE + tables — import via phpMyAdmin
├── config.php             # DB credentials + optional OPENAI_API_KEY
├── ai_engine.php           # the scoring/analysis engine (PHP port of aiEngine.js)
├── seed.php                # loads data/questions.json into the questions table
├── data/
│   └── questions.json      # 50 questions (5 languages × 5 levels × 2), JSON to avoid SQL-quote pain
├── api/
│   ├── bootstrap.php        # shared headers/config include for every endpoint
│   ├── meta.php              # GET  — languages, level labels, time limits
│   ├── start.php              # POST — start a test: { language, userName }
│   ├── submit.php              # POST — submit answers, get the scored result
│   ├── attempt.php               # GET  ?id=123 — fetch a stored attempt
│   ├── history.php                # GET  ?userName=... — a user's past attempts
│   └── leaderboard.php              # GET  — top 10 attempts by rating
├── assets/
│   ├── app.js               # vanilla-JS SPA (Home → TestRunner → ResultView), no build step
│   └── styles.css            # same visual design as the original
└── index.html                 # entry point
```

## API reference

| Method | Route                        | Purpose                                   |
|--------|-------------------------------|--------------------------------------------|
| GET    | `api/meta.php`                | Languages, level labels, time limits       |
| POST   | `api/start.php`                | Start a test: `{ language, userName }`     |
| POST   | `api/submit.php`                | Submit `{ attemptId, answers }`, get result |
| GET    | `api/attempt.php?id=123`         | Fetch a stored attempt                     |
| GET    | `api/history.php?userName=...`    | A user's past attempts                     |
| GET    | `api/leaderboard.php`              | Top 10 attempts by rating                  |

All endpoints return JSON and send permissive CORS headers, so the front end can also be
hosted on a different origin from the API if you ever split them up.

## Data model

Two tables, using MySQL's native `JSON` column type to keep the same flexible document
shape as the original Mongoose models:

- **`questions`** — `language`, `level`, `text`, `code`, `options` (JSON array),
  `correct_index`, `explanation`, `tags` (JSON array).
- **`attempts`** — `user_name`, `language`, `status`, `slots` (JSON — the 5 questions picked
  for this attempt), `answers` (JSON — what the user submitted, scored), `result` (JSON —
  the full AI-engine output), `started_at`, `completed_at`.

## Extending the question bank

Add objects to `data/questions.json` following the existing shape
(`language`, `level`, `text`, optional `code`, `options`, `correctIndex`, `explanation`),
then re-run `seed.php` to reload the table.

## Notes on the port from the MERN version

- MongoDB's flexible/mixed `result` field became a MySQL `JSON` column — same shape, no
  schema migration needed if you add fields to the AI engine's output later.
- Auto-incrementing MySQL integer IDs replace Mongo ObjectIds; the API still returns them
  as strings so the front end doesn't care which backend it's talking to.
- The React front end was replaced with a small vanilla-JS SPA (`assets/app.js`) doing
  direct DOM updates — no React/Vite/npm required, so it runs on any PHP host with zero
  build tooling.
- All SQL access uses PDO **prepared statements** (parameterized queries) — no manual
  string concatenation of user input into SQL, avoiding SQL-injection issues that raw
  string-built queries would risk.
