<?php
function e($value){ return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8'); }
function logged_in(){ return !empty($_SESSION['user']); }
function user(){ return $_SESSION['user'] ?? null; }
function require_login(){ if(!logged_in()){ header('Location: login.php'); exit; } }
function require_role($roles){ require_login(); $roles=(array)$roles; if(!in_array(user()['role'],$roles,true)){ http_response_code(403); exit('Access denied for this site.'); } }
function flash($key,$value=null){ if($value!==null){$_SESSION['flash'][$key]=$value;return;} $v=$_SESSION['flash'][$key]??null; unset($_SESSION['flash'][$key]); return $v; }
function trust_tier($score){ if($score>=85)return 'Elite'; if($score>=70)return 'Trusted'; if($score>=50)return 'Verified'; if($score>=30)return 'Growing'; return 'New'; }
function nav_active($file){ return basename($_SERVER['PHP_SELF'])===$file?'active':''; }
