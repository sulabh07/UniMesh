<?php
require 'config.php';
require 'includes/functions.php';
require_role('student');

$uid=(int)user()['id'];
$skillId=(int)($_GET['skill_id'] ?? 0);

$stmt=$pdo->prepare("SELECT us.skill_id, s.name AS skill_name
    FROM user_skills us
    JOIN skills s ON s.id=us.skill_id
    WHERE us.user_id=? AND us.skill_id=?
      AND s.name IN ('Python','C++','HTML','Java','SQL')
    LIMIT 1");
$stmt->execute([$uid,$skillId]);
$skill=$stmt->fetch();

if(!$skill){
    flash('error','Please add one of the supported skills before taking an assessment.');
    header('Location: skills.php');
    exit;
}

$languageMap=[
    'Python'=>'python',
    'C++'=>'cpp',
    'HTML'=>'html',
    'Java'=>'java',
    'SQL'=>'sql',
];
$lang=$languageMap[$skill['skill_name']] ?? null;
if(!$lang){
    flash('error','This skill is not available in SkillAI.');
    header('Location: assessments.php');
    exit;
}

$ts=time();
$payload=$uid.'|'.$skillId.'|'.$lang.'|'.$ts;
$sig=hash_hmac('sha256',$payload,SKILLAI_SHARED_SECRET);
$query=http_build_query([
    'source'=>'unimesh',
    'userId'=>$uid,
    'skillId'=>$skillId,
    'userName'=>user()['name'],
    'language'=>$lang,
    'ts'=>$ts,
    'sig'=>$sig,
]);

header('Location: '.SKILLAI_URL.'?'.$query);
exit;
