/* SkillAI — vanilla JS front end (no build step needed).
 * Talks to the PHP API in /api. Mirrors the structure of the original
 * React version (Home -> TestRunner -> ResultView) using plain DOM updates. */

const API_BASE = 'api';

const state = {
  meta: null,
  screen: 'home', // home | test | result
  attempt: null,
  result: null,
  userName: localStorage.getItem('skillai.user') || '',
  busy: false,
  error: '',
};

let selectedLang = null;
let testState = null; // { index, selected, answers, startTime, timerId }

const launchParams = new URLSearchParams(window.location.search);
const integration = launchParams.get('source') === 'unimesh' ? {
  source: 'unimesh',
  userId: launchParams.get('userId') || '',
  skillId: launchParams.get('skillId') || '',
  userName: launchParams.get('userName') || '',
  language: launchParams.get('language') || '',
  ts: launchParams.get('ts') || '',
  sig: launchParams.get('sig') || '',
} : null;

/* ---------------- API helper ---------------- */
async function apiRequest(path, options = {}) {
  const res = await fetch(`${API_BASE}/${path}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || `Request failed (${res.status})`);
  return data;
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str ?? '';
  return div.innerHTML;
}

/* ---------------- Boot ---------------- */
async function init() {
  try {
    state.meta = await apiRequest('meta.php');
    if (integration) {
      state.userName = integration.userName || state.userName;
      if (state.meta.languages.includes(integration.language)) selectedLang = integration.language;
    }
  } catch (e) {
    state.error = e.message;
  }
  render();
}

/* ---------------- Root render ---------------- */
function render() {
  const root = document.getElementById('root');

  if (!state.meta) {
    root.innerHTML = `
      <div class="app">
        ${state.error
          ? `<div class="error">${escapeHtml(state.error)} — is the API reachable at api/meta.php?</div>`
          : `<div class="loading"><span class="spinner"></span> Booting the AI engine…</div>`}
      </div>`;
    return;
  }

  root.innerHTML = `
    <div class="app">
      <header class="topbar">
        <div class="brand">
          <div class="brand-mark">AI</div>
          <div>
            <h1>SkillAI</h1>
            <span>Adaptive multi-language skill analyzer</span>
          </div>
        </div>
        ${state.screen !== 'home' ? `<button class="ghost" id="btn-reset">← New test</button>` : ''}
      </header>
      ${state.error ? `<div class="error">${escapeHtml(state.error)}</div>` : ''}
      <div id="screen-container"></div>
      <p class="footer-note">Scoring: weighted by difficulty (L1–L5) + speed bonus • Rating on a 0–5 scale</p>
    </div>`;

  const container = document.getElementById('screen-container');
  if (state.screen === 'home') renderHome(container);
  else if (state.screen === 'test') renderTest(container);
  else if (state.screen === 'result') renderResult(container);

  const resetBtn = document.getElementById('btn-reset');
  if (resetBtn) resetBtn.addEventListener('click', resetApp);
}

function resetApp() {
  state.attempt = null;
  state.result = null;
  state.screen = 'home';
  testState = null;
  render();
}

/* ---------------- HOME ---------------- */
function renderHome(container) {
  const meta = state.meta;
  if (!selectedLang) selectedLang = meta.languages[0];
  const icons = { python: '🐍', cpp: '⚙️', html: '🌐', java: '☕', sql: '🗄️' };

  container.innerHTML = `
    <div class="card">
      <h2>Evaluate your coding skills</h2>
      <p class="sub">
        Take a 10-question adaptive test — two random questions from each difficulty level (Basic → Expert).
        Each question has its own timer. The AI engine scores correctness, difficulty weight
        and response speed, then returns a rating from <b>0.0 to 5.0</b>.
      </p>
      ${integration ? `<div class="chip good">✓ Launched securely from Unimesh for ${escapeHtml(state.userName || 'student')}</div>` : `
      <label class="field">Your name (optional)</label>
      <input type="text" id="input-name" placeholder="e.g. Aarav" maxlength="40" value="${escapeHtml(state.userName)}" />`}
    </div>

    <div class="card">
      <h3>Choose a language</h3>
      <div class="lang-grid">
        ${meta.languages.filter((l) => !integration || l === selectedLang).map((l) => `
          <button class="lang ${l === selectedLang ? 'active' : ''}" data-lang="${l}">
            <div class="icon">${icons[l] || '💻'}</div>
            <div class="name">${escapeHtml(meta.languageLabels[l])}</div>
            <div class="meta">10 questions · 2 per level · ${Math.round(meta.totalTimeMs / 1000)}s total</div>
          </button>`).join('')}
      </div>
      <button class="primary" id="btn-start" ${state.busy ? 'disabled' : ''}>
        ${state.busy ? 'Preparing your test…' : `Start ${escapeHtml(meta.languageLabels[selectedLang])} assessment`}
      </button>
    </div>

    <div class="card">
      <h3>Difficulty & time limits</h3>
      <div class="chips">
        ${[1, 2, 3, 4, 5].map((lv) => `<span class="pill lv${lv}">L${lv} ${meta.levelLabels[lv]} · ${meta.timeLimits[lv]}s</span>`).join('')}
      </div>
    </div>
  `;

  if (!integration) {
    container.querySelectorAll('.lang').forEach((btn) => {
      btn.addEventListener('click', () => {
        selectedLang = btn.dataset.lang;
        renderHome(container);
      });
    });
    document.getElementById('input-name').addEventListener('input', (e) => {
      state.userName = e.target.value;
    });
  }
  document.getElementById('btn-start').addEventListener('click', handleStart);
}

async function handleStart() {
  state.error = '';
  state.busy = true;
  render();
  try {
    localStorage.setItem('skillai.user', state.userName);
    const data = await apiRequest('start.php', {
      method: 'POST',
      body: JSON.stringify({
        language: selectedLang,
        userName: state.userName || 'Guest',
        ...(integration || {}),
      }),
    });
    state.attempt = data;
    state.result = null;
    state.screen = 'test';
    testState = null;
  } catch (e) {
    state.error = e.message;
  } finally {
    state.busy = false;
    render();
  }
}

/* ---------------- TEST RUNNER ---------------- */
function renderTest(container) {
  const attempt = state.attempt;
  if (!testState) {
    testState = { index: 0, selected: null, answers: [], startTime: Date.now(), timerId: null };
  }
  const q = attempt.questions[testState.index];
  const limitMs = attempt.timeLimits[q.level] * 1000;
  const isLast = testState.index === attempt.questions.length - 1;

  container.innerHTML = `
    <div class="card">
      <div class="test-head">
        <span class="pill lv${q.level}">Level ${q.level} · ${q.levelLabel}</span>
        <span style="font-size:13px;color:var(--muted);font-weight:600;">Question ${testState.index + 1} / ${attempt.questions.length}</span>
      </div>

      <div class="progress-track"><div class="progress-fill" id="progress-fill" style="width:0%"></div></div>

      <div class="q-text">${escapeHtml(q.text)}</div>
      ${q.code ? `<pre class="code">${escapeHtml(q.code)}</pre>` : ''}

      <div class="options">
        ${q.options.map((opt, i) => `
          <button class="opt ${testState.selected === i ? 'selected' : ''}" data-idx="${i}">
            <span class="key">${String.fromCharCode(65 + i)}</span>
            <span>${escapeHtml(opt)}</span>
          </button>`).join('')}
      </div>

      <div class="timer-row">
        <div class="timer" id="timer-display">00:00</div>
        <button class="primary" style="width:auto;padding:13px 30px;" id="btn-next" ${state.busy ? 'disabled' : ''}>
          ${state.busy ? 'Analyzing…' : (isLast ? 'Finish & analyze' : 'Next →')}
        </button>
      </div>
    </div>`;

  container.querySelectorAll('.opt').forEach((btn) => {
    btn.addEventListener('click', () => {
      testState.selected = parseInt(btn.dataset.idx, 10);
      renderTest(container);
    });
  });
  document.getElementById('btn-next').addEventListener('click', () => commitAnswer(false, limitMs));

  startTimerIfNeeded(limitMs);
}

function startTimerIfNeeded(limitMs) {
  if (testState.timerId) return; // already running for this question
  testState.startTime = Date.now();
  testState.timerId = setInterval(() => {
    const left = Math.max(0, limitMs - (Date.now() - testState.startTime));
    updateTimerDisplay(left, limitMs);
    if (left <= 0) {
      clearInterval(testState.timerId);
      testState.timerId = null;
      commitAnswer(true, limitMs); // auto-submit whatever is picked (or skip)
    }
  }, 100);
  updateTimerDisplay(limitMs, limitMs);
}

function updateTimerDisplay(remaining, limitMs) {
  const timerEl = document.getElementById('timer-display');
  const fillEl = document.getElementById('progress-fill');
  if (!timerEl) return;
  const seconds = Math.ceil(remaining / 1000);
  timerEl.textContent = `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;
  timerEl.className = `timer ${seconds <= 10 ? 'danger' : ''}`;
  if (fillEl) {
    const total = state.attempt.questions.length;
    const pct = ((testState.index + (1 - remaining / limitMs)) / total) * 100;
    fillEl.style.width = `${pct}%`;
  }
}

function commitAnswer(forceSkip, limitMs) {
  if (testState.timerId) {
    clearInterval(testState.timerId);
    testState.timerId = null;
  }
  const attempt = state.attempt;
  const q = attempt.questions[testState.index];
  const timeTakenMs = Math.min(Date.now() - testState.startTime, limitMs);
  const record = {
    questionId: q.id,
    selectedIndex: forceSkip ? -1 : (testState.selected ?? -1),
    timeTakenMs,
  };
  testState.answers.push(record);
  testState.selected = null;

  if (testState.index + 1 < attempt.questions.length) {
    testState.index += 1;
    render();
  } else {
    handleFinish(testState.answers);
  }
}

async function handleFinish(answers) {
  state.busy = true;
  state.error = '';
  render();
  try {
    const data = await apiRequest('submit.php', {
      method: 'POST',
      body: JSON.stringify({ attemptId: state.attempt.attemptId, answers }),
    });
    state.result = data;
    state.screen = 'result';
  } catch (e) {
    state.error = e.message;
  } finally {
    state.busy = false;
    render();
  }
}

/* ---------------- RESULT VIEW ---------------- */
function gaugeSvg(rating) {
  const R = 62;
  const C = 2 * Math.PI * R;
  const pct = Math.max(0, Math.min(1, rating / 5));
  const color = rating >= 4 ? '#37d67a' : rating >= 3 ? '#39d0c8' : rating >= 2 ? '#ffb020' : '#ff5c72';
  const offset = C * (1 - pct);
  return `
    <div class="gauge">
      <svg width="150" height="150">
        <circle cx="75" cy="75" r="${R}" fill="none" stroke="rgba(255,255,255,.08)" stroke-width="12" />
        <circle cx="75" cy="75" r="${R}" fill="none" stroke="${color}" stroke-width="12" stroke-linecap="round"
                stroke-dasharray="${C}" stroke-dashoffset="${offset}" />
      </svg>
      <div class="val">
        <div>
          <b style="color:${color};">${rating.toFixed(1)}</b>
          <small>out of 5.0</small>
        </div>
      </div>
    </div>`;
}

function renderResult(container) {
  const result = state.result;
  const r = result.result;

  container.innerHTML = `
    <div class="card">
      <div class="rating-wrap">
        ${gaugeSvg(r.rating)}
        <div class="rating-info" style="flex:1;min-width:220px;">
          <h2>${escapeHtml(result.languageLabel)} — ${r.band}</h2>
          <div class="band">${r.correctCount}/${r.totalQuestions} correct · ${r.percent}% weighted score</div>
          <div class="stat-row">
            <div class="stat"><b>${r.totalTimeSec}s</b>Time used</div>
            <div class="stat"><b>${Math.round(r.avgSpeedRatio * 100)}%</b>Speed score</div>
            <div class="stat"><b>${r.consistency}%</b>Consistency</div>
            <div class="stat"><b>${r.earnedPoints.toFixed(1)}</b>Points / ${r.maxPoints}</div>
          </div>
        </div>
      </div>
    </div>

    <div class="card">
      <h3>🧠 AI analysis</h3>
      <p class="narrative">${escapeHtml(r.narrative)}</p>
    </div>

    <div class="card">
      <h3>Level-by-level breakdown</h3>
      ${r.breakdown.map((b) => {
        const pct = (b.pointsEarned / b.maxPoints) * 100;
        const color = b.isCorrect ? (b.speedRatio > 0.4 ? '#37d67a' : '#39d0c8') : '#ff5c72';
        return `
        <div class="bd-row">
          <div class="bd-label">L${b.level} ${b.levelLabel}</div>
          <div class="bd-track"><div class="bd-fill" style="width:${pct}%;background:${color};"></div></div>
          <div class="bd-pts">${b.pointsEarned.toFixed(2)}/${b.maxPoints}</div>
        </div>`;
      }).join('')}
    </div>

    <div class="card">
      <h3>✅ Strengths</h3>
      <div class="chips" style="margin-bottom:22px;">
        ${r.strengths.length
          ? r.strengths.map((s) => `<span class="chip good">${escapeHtml(s)}</span>`).join('')
          : `<span class="chip">No clear strengths detected yet — keep practising!</span>`}
      </div>
      <h3>⚠️ Weak areas</h3>
      <div class="chips">
        ${r.weaknesses.length
          ? r.weaknesses.map((w) => `<span class="chip bad">${escapeHtml(w)}</span>`).join('')
          : `<span class="chip good">None — flawless run 🎉</span>`}
      </div>
    </div>

    <div class="card">
      <h3>📚 Recommended next steps</h3>
      <ul class="recs">
        ${r.recommendations.map((rec) => `<li>${escapeHtml(rec)}</li>`).join('')}
      </ul>
    </div>

    <div class="card">
      <h3>🔍 Full answer review</h3>
      ${result.review.map((item) => `
        <div class="review-item ${item.isCorrect ? 'correct' : 'wrong'}">
          <div class="rv-head">
            <span class="pill lv${item.level}">L${item.level}</span>
            <span style="font-size:12px;color:${item.isCorrect ? 'var(--ok)' : 'var(--bad)'};font-weight:700;">
              ${item.isCorrect ? '✓ Correct' : (item.selectedIndex === -1 ? '⏱ Skipped / timed out' : '✕ Incorrect')}
              · ${(item.timeTakenMs / 1000).toFixed(1)}s
            </span>
          </div>
          <div class="rv-q">${escapeHtml(item.text)}</div>
          <div class="rv-ans">
            Your answer: <b>${item.selectedIndex === -1 ? '—' : escapeHtml(item.options[item.selectedIndex])}</b><br/>
            Correct answer: <b style="color:var(--ok);">${escapeHtml(item.options[item.correctIndex])}</b>
          </div>
          <div class="rv-exp">💡 ${escapeHtml(item.explanation)}</div>
        </div>`).join('')}
    </div>

    ${integration ? `
    <div class="card">
      <h3>🔗 Unimesh profile update</h3>
      <p class="narrative">${result.integration?.savedToUnimesh
        ? `Your ${escapeHtml(result.languageLabel)} skill has been rated <b>${r.rating.toFixed(1)} / 5.0</b> and saved to your Unimesh profile. Status: <b>${result.integration.verified ? 'Verified' : 'Unverified'}</b>.`
        : `Your SkillAI result is complete, but it could not be saved to Unimesh automatically${result.integration?.error ? `: ${escapeHtml(result.integration.error)}` : '.'}`}</p>
      <a class="primary" style="display:inline-block;text-decoration:none;" href="../student/assessments.php">Return to Unimesh Assessments</a>
    </div>` : `
    <div style="margin-top:20px;">
      <button class="primary" id="btn-retake">Take another assessment</button>
    </div>`}
  `;

  const retakeBtn = document.getElementById('btn-retake');
  if (retakeBtn) retakeBtn.addEventListener('click', resetApp);
}

init();
