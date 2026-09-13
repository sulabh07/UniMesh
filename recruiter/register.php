<?php
$pageTitle='Recruiter Registration'; require 'config.php'; require 'includes/functions.php';
if($_SERVER['REQUEST_METHOD']==='POST'){
 $name=trim($_POST['name']??'');$email=trim($_POST['email']??'');$password=$_POST['password']??'';$role='recruiter';
 if(!$name||!filter_var($email,FILTER_VALIDATE_EMAIL)||strlen($password)<6){flash('error','Enter valid details. Password must be at least 6 characters.');}
 else{try{$stmt=$pdo->prepare('INSERT INTO users(name,email,password_hash,role,email_verified,verification_status,trust_score) VALUES(?,?,?,?,0,?,0)');$stmt->execute([$name,$email,password_hash($password,PASSWORD_DEFAULT),$role,'pending']);flash('success','Recruiter account created. You can now log in.');header('Location: login.php');exit;}catch(PDOException $e){flash('error','Email is already registered.');}}
}
include 'includes/header.php'; ?>
<div class="form-card card"><div class="kicker">💼 Recruiter Site</div><h1>Create Recruiter Account</h1><p class="muted">Accounts created here are automatically registered with the Recruiter role.</p><form method="post"><div class="form-group"><label>Name</label><input name="name" required></div><div class="form-group"><label>Email</label><input type="email" name="email" required></div><div class="form-group"><label>Password</label><input type="password" name="password" minlength="6" required></div><button class="btn">Create Recruiter Account</button></form></div>
<?php include 'includes/footer.php'; ?>