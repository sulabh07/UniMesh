<?php
$pageTitle='Assessments';
require 'config.php';
require 'includes/functions.php';
require_role('student');
$uid=(int)user()['id'];

$stmt=$pdo->prepare("SELECT us.skill_id,us.level,us.verified,us.star_rating,s.name skill_name
    FROM user_skills us
    JOIN skills s ON s.id=us.skill_id
    WHERE us.user_id=? AND s.name IN ('Python','C++','HTML','Java','SQL')
    ORDER BY FIELD(s.name,'Python','C++','HTML','Java','SQL')");
$stmt->execute([$uid]);
$rows=$stmt->fetchAll();

$hist=$pdo->prepare('SELECT aa.*,a.title FROM assessment_attempts aa JOIN assessments a ON a.id=aa.assessment_id WHERE aa.user_id=? ORDER BY aa.completed_at DESC');
$hist->execute([$uid]);
$hist=$hist->fetchAll();
include 'includes/header.php';
?>
<div class="card">
  <h1>SkillAI Assessments</h1>
  <p class="muted">Choose one of your skills below. Clicking <strong>Start SkillAI Test</strong> will redirect you to the SkillAI website. After the 10-question test is submitted, your 0–5 rating is saved automatically in Unimesh.</p>
</div>

<?php if(!$rows): ?>
<div class="card section-title">
  <h3>No supported skill added yet</h3>
  <p class="muted">Add Python, C++, HTML, Java or SQL first.</p>
  <a class="btn" href="skills.php">Add Skill</a>
</div>
<?php else: ?>
<div class="grid section-title">
<?php foreach($rows as $r):
?>
  <div class="card">
    <span class="badge <?=$r['verified']?'':'warn'?>"><?=$r['verified']?'Verified':'Unverified'?></span>
    <h3><?=e($r['skill_name'])?></h3>
    <p>Declared level: <?=e($r['level'])?> / 5</p>
    <p><strong>SkillAI rating:</strong><br><?=render_stars($r['star_rating'])?></p>
    <a class="btn" href="start_assessment.php?skill_id=<?=(int)$r['skill_id']?>">Start SkillAI Test →</a>
  </div>
<?php endforeach; ?>
</div>
<?php endif; ?>

<h2 class="section-title">Assessment History</h2>
<div class="table-wrap card"><table class="table"><tr><th>Assessment</th><th>Score</th><th>Integrity</th><th>Date</th></tr>
<?php foreach($hist as $h):?><tr><td><?=e($h['title'])?></td><td><?=e($h['score'])?>%</td><td><?=e($h['integrity_score'])?>%</td><td><?=e($h['completed_at'])?></td></tr><?php endforeach;?>
</table></div>
<?php include 'includes/footer.php'; ?>
