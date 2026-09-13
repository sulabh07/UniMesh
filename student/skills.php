<?php
$pageTitle='Skills';
require 'config.php';
require 'includes/functions.php';
require_role('student');
$uid=(int)user()['id'];

$allowedSkillNames = ['Python','C++','HTML','Java','SQL'];

if($_SERVER['REQUEST_METHOD']==='POST'){
    $sid=(int)($_POST['skill_id']??0);
    $lvl=max(1,min(5,(int)($_POST['level']??1)));

    $check=$pdo->prepare("SELECT id FROM skills WHERE id=? AND name IN ('Python','C++','HTML','Java','SQL')");
    $check->execute([$sid]);
    if(!$check->fetch()){
        flash('error','Please select one of the supported SkillAI skills.');
        header('Location: skills.php');
        exit;
    }

    // Verify the current student still exists in the database before inserting.
    $userCheck=$pdo->prepare('SELECT id FROM users WHERE id=? AND role=\'student\' LIMIT 1');
    $userCheck->execute([$uid]);
    if(!$userCheck->fetch()){
        $_SESSION=[];
        session_regenerate_id(true);
        $_SESSION['flash']['error']='Your login session is outdated. Please log in again.';
        header('Location: login.php');
        exit;
    }

    $stmt=$pdo->prepare('INSERT INTO user_skills(user_id,skill_id,level,verified) VALUES(?,?,?,0) ON DUPLICATE KEY UPDATE level=VALUES(level)');
    $stmt->execute([$uid,$sid,$lvl]);
    flash('success','Skill added. Take the SkillAI assessment to receive your verified rating.');
    header('Location: skills.php');
    exit;
}

$all=$pdo->query("SELECT * FROM skills WHERE name IN ('Python','C++','HTML','Java','SQL') ORDER BY FIELD(name,'Python','C++','HTML','Java','SQL')")->fetchAll();
$stmt=$pdo->prepare("SELECT us.*,s.name skill_name FROM user_skills us JOIN skills s ON s.id=us.skill_id WHERE user_id=? AND s.name IN ('Python','C++','HTML','Java','SQL') ORDER BY verified DESC, FIELD(s.name,'Python','C++','HTML','Java','SQL')");
$stmt->execute([$uid]);
$mine=$stmt->fetchAll();
include 'includes/header.php';
?>
<div class="grid two">
  <div class="card">
    <h2>Add Skill</h2>
    <?php if(!$all): ?>
      <p class="muted">The five SkillAI skills are missing from the database. Run <code>UPDATE_SKILLS.sql</code> in phpMyAdmin.</p>
    <?php else: ?>
    <form method="post">
      <div class="form-group">
        <label>Skill</label>
        <select name="skill_id" required>
          <?php foreach($all as $s):?><option value="<?=$s['id']?>"><?=e($s['name'])?></option><?php endforeach;?>
        </select>
      </div>
      <div class="form-group">
        <label>Declared Level (1–5)</label>
        <select name="level"><?php for($i=1;$i<=5;$i++):?><option><?=$i?></option><?php endfor;?></select>
      </div>
      <button class="btn">Add Skill</button>
    </form>
    <?php endif; ?>
  </div>
  <div class="card">
    <h2>Level Guide</h2>
    <p class="muted">1 Beginner • 2 Rookie • 3 Intermediate • 4 Advanced • 5 Professional</p>
    <a class="btn secondary" href="assessments.php">Open Assessments</a>
  </div>
</div>
<h2 class="section-title">Your Skills</h2>
<div class="grid">
<?php foreach($mine as $s):?>
  <div class="card">
    <span class="badge <?=$s['verified']?'':'warn'?>"><?=$s['verified']?'Verified':'Unverified'?></span>
    <h3><?=e($s['skill_name'])?></h3>
    <p>Declared Level <?=e($s['level'])?> / 5</p>
    <p><strong>SkillAI Rating:</strong><br><?=render_stars($s['star_rating'])?></p>
    <a class="btn" href="start_assessment.php?skill_id=<?=(int)$s['skill_id']?>">Take Assessment</a>
  </div>
<?php endforeach;?>
</div>
<?php include 'includes/footer.php'; ?>
