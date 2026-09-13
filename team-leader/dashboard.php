<?php
$pageTitle='Dashboard'; require 'config.php'; require 'includes/functions.php'; require_role('team_leader');
$uid=user()['id']; $role=user()['role'];
if($role==='student'){
 $skills=$pdo->prepare('SELECT us.*,s.name skill_name FROM user_skills us JOIN skills s ON s.id=us.skill_id WHERE us.user_id=? ORDER BY us.verified DESC, s.name');$skills->execute([$uid]);$skills=$skills->fetchAll();
 $projects=$pdo->prepare('SELECT * FROM projects WHERE user_id=? ORDER BY created_at DESC LIMIT 4');$projects->execute([$uid]);$projects=$projects->fetchAll();
 $jobs=$pdo->query("SELECT j.*,u.name recruiter_name FROM jobs j JOIN users u ON u.id=j.recruiter_id WHERE j.status='open' ORDER BY j.created_at DESC LIMIT 6")->fetchAll();
 $teams=$pdo->query("SELECT t.*,u.name leader_name FROM teams t JOIN users u ON u.id=t.leader_id ORDER BY t.created_at DESC LIMIT 6")->fetchAll();
}elseif($role==='recruiter'){
 $jobs=$pdo->prepare('SELECT * FROM jobs WHERE recruiter_id=? ORDER BY created_at DESC');$jobs->execute([$uid]);$jobs=$jobs->fetchAll();
 $candidateCount=$pdo->query("SELECT COUNT(*) FROM users WHERE role='student'")->fetchColumn();
 $appCount=$pdo->prepare('SELECT COUNT(*) FROM applications a JOIN jobs j ON j.id=a.job_id WHERE j.recruiter_id=?');$appCount->execute([$uid]);$appCount=$appCount->fetchColumn();
}elseif($role==='team_leader'){
 $teams=$pdo->prepare('SELECT * FROM teams WHERE leader_id=? ORDER BY created_at DESC');$teams->execute([$uid]);$teams=$teams->fetchAll();
 $students=$pdo->query("SELECT id,name,email,trust_score FROM users WHERE role='student' ORDER BY trust_score DESC LIMIT 8")->fetchAll();
}
include 'includes/header.php'; ?>
<div class="kicker"><?=e(str_replace('_',' ',$role))?> dashboard</div><h1>Hello, <?=e(user()['name'])?></h1>
<?php if($role==='student'): ?>
<div class="grid"><div class="card"><span class="badge"><?=e(trust_tier((int)user()['trust_score']))?></span><div class="stat"><?=e(user()['trust_score'])?></div><p class="muted">Trust Score</p><div class="progress"><span style="width:<?=min(100,(int)user()['trust_score'])?>%"></span></div></div><div class="card"><div class="stat"><?=count($skills)?></div><p class="muted">Skills on profile</p><a class="btn secondary" href="skills.php">Manage Skills</a></div><div class="card"><div class="stat"><?=count($projects)?></div><p class="muted">Recent projects</p><a class="btn secondary" href="projects.php">Portfolio</a></div></div>
<h2 class="section-title">Recommended Jobs</h2><div class="grid"><?php foreach($jobs as $j):?><div class="card"><span class="badge"><?=e($j['location']?:'Flexible')?></span><h3><?=e($j['title'])?></h3><p class="muted"><?=e($j['company_name'])?> • <?=e($j['salary']?:'Salary not listed')?></p><p><?=e(mb_strimwidth($j['description'],0,130,'…'))?></p><a class="btn secondary" href="jobs.php">View Jobs</a></div><?php endforeach;?></div>
<h2 class="section-title">Hackathon Teams</h2><div class="grid"><?php foreach($teams as $t):?><div class="card"><span class="badge">Team</span><h3><?=e($t['name'])?></h3><p class="muted"><?=e($t['hackathon_name'])?> • Leader: <?=e($t['leader_name'])?></p><p><?=e(mb_strimwidth($t['description'],0,120,'…'))?></p></div><?php endforeach;?></div>
<?php elseif($role==='recruiter'): ?>
<div class="grid"><div class="card"><div class="stat"><?=count($jobs)?></div><p class="muted">Your job listings</p></div><div class="card"><div class="stat"><?=$candidateCount?></div><p class="muted">Available student profiles</p></div><div class="card"><div class="stat"><?=$appCount?></div><p class="muted">Applications received</p></div></div><div class="actions section-title"><a class="btn" href="jobs.php?action=create">Create Job</a><a class="btn secondary" href="candidates.php">Discover Candidates</a></div>
<h2>Your Listings</h2><div class="table-wrap card"><table class="table"><tr><th>Title</th><th>Company</th><th>Location</th><th>Status</th></tr><?php foreach($jobs as $j):?><tr><td><?=e($j['title'])?></td><td><?=e($j['company_name'])?></td><td><?=e($j['location'])?></td><td><span class="badge"><?=e($j['status'])?></span></td></tr><?php endforeach;?></table></div>
<?php elseif($role==='team_leader'): ?>
<div class="grid"><div class="card"><div class="stat"><?=count($teams)?></div><p class="muted">Teams created</p></div><div class="card"><div class="stat"><?=count($students)?></div><p class="muted">Recommended candidates</p></div><div class="card"><h3>Skill-gap workflow</h3><p class="muted">Create a team, list needed skills, then compare verified students.</p></div></div><div class="actions section-title"><a class="btn" href="teams.php?action=create">Create Team</a><a class="btn secondary" href="candidates.php">Find Teammates</a></div>
<h2>Recommended Students</h2><div class="grid"><?php foreach($students as $s):?><div class="card"><span class="badge"><?=e(trust_tier($s['trust_score']))?></span><h3><?=e($s['name'])?></h3><p class="muted">Trust Score <?=e($s['trust_score'])?></p><a class="btn secondary" href="candidates.php">View Profile</a></div><?php endforeach;?></div>
<?php elseif($role==='admin'): ?><div class="card"><h2>Administration</h2><p class="muted">Manage users, manual verification, jobs, teams and platform content.</p><a class="btn" href="admin.php">Open Admin Panel</a></div><?php endif;?>
<?php include 'includes/footer.php'; ?>
