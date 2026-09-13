<?php
$pageTitle='Team Leader Login'; require 'config.php'; require 'includes/functions.php';
if(logged_in()){ header('Location: dashboard.php'); exit; }
if($_SERVER['REQUEST_METHOD']==='POST'){
 $email=trim($_POST['email']??''); $password=$_POST['password']??'';
 $stmt=$pdo->prepare('SELECT * FROM users WHERE email=? LIMIT 1'); $stmt->execute([$email]); $u=$stmt->fetch();
 if($u && password_verify($password,$u['password_hash'])){
   if($u['role']!=='team_leader'){ flash('error','This account is not a Team Leader account. Please use the correct Unimesh site.'); }
   elseif($u['account_status']==='suspended'){ flash('error','This account is suspended.'); }
   else { $_SESSION['user']=['id'=>$u['id'],'name'=>$u['name'],'email'=>$u['email'],'role'=>$u['role'],'trust_score'=>$u['trust_score']]; header('Location: dashboard.php'); exit; }
 } else flash('error','Invalid email or password.');
}
include 'includes/header.php'; ?>
<div class="form-card card"><div class="kicker">🚀 Team Leader Site</div><h1>Team Leader Login</h1><p class="muted">This login is independent from the other Unimesh gateways.</p><form method="post"><div class="form-group"><label>Email</label><input type="email" name="email" required></div><div class="form-group"><label>Password</label><input type="password" name="password" required></div><button class="btn">Login as Team Leader</button></form></div>
<?php include 'includes/footer.php'; ?>