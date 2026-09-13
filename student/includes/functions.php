<?php
function e($value){ return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8'); }
function logged_in(){ return !empty($_SESSION['user']); }
function user(){ return $_SESSION['user'] ?? null; }
function require_login(){
    global $pdo;
    if(!logged_in()){
        header('Location: login.php');
        exit;
    }

    // A database re-import can invalidate an old PHP session. Verify the
    // session user still exists before any page writes rows using user_id.
    $sessionUser = user();
    $stmt = $pdo->prepare('SELECT id,name,email,role,trust_score,account_status FROM users WHERE id=? LIMIT 1');
    $stmt->execute([(int)$sessionUser['id']]);
    $dbUser = $stmt->fetch();

    if(!$dbUser){
        $_SESSION = [];
        session_regenerate_id(true);
        $_SESSION['flash']['error'] = 'Your previous login session was no longer valid. Please log in again.';
        header('Location: login.php');
        exit;
    }

    // Refresh session data from the current database record.
    $_SESSION['user'] = [
        'id' => (int)$dbUser['id'],
        'name' => $dbUser['name'],
        'email' => $dbUser['email'],
        'role' => $dbUser['role'],
        'trust_score' => (int)$dbUser['trust_score']
    ];
}
function require_role($roles){ require_login(); $roles=(array)$roles; if(!in_array(user()['role'],$roles,true)){ http_response_code(403); exit('Access denied for this site.'); } }
function flash($key,$value=null){ if($value!==null){$_SESSION['flash'][$key]=$value;return;} $v=$_SESSION['flash'][$key]??null; unset($_SESSION['flash'][$key]); return $v; }
function trust_tier($score){ if($score>=85)return 'Elite'; if($score>=70)return 'Trusted'; if($score>=50)return 'Verified'; if($score>=30)return 'Growing'; return 'New'; }
function nav_active($file){ return basename($_SERVER['PHP_SELF'])===$file?'active':''; }

function render_stars($rating){
    if($rating===null || $rating==='') return '<span class="muted">Not tested yet</span>';
    $r=max(0,min(5,(float)$rating));
    $pct=($r/5)*100;
    return '<span class="star-rating" role="img" aria-label="'.e(number_format($r,1)).' out of 5 stars"><span class="stars-empty">★★★★★</span><span class="stars-fill" style="width:'.e(number_format($pct,2,'.','')).'%">★★★★★</span></span> <strong>'.e(number_format($r,1)).'/5</strong>';
}
