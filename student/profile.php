<?php
$pageTitle='Profile';
require 'config.php';
require 'includes/functions.php';
require_role('student');
$uid=(int)user()['id'];

if($_SERVER['REQUEST_METHOD']==='POST'){
    $stmt=$pdo->prepare('SELECT profile_photo FROM users WHERE id=?');
    $stmt->execute([$uid]);
    $current=$stmt->fetch();
    $photoPath=$current['profile_photo'] ?? null;

    if(isset($_FILES['profile_photo']) && $_FILES['profile_photo']['error'] !== UPLOAD_ERR_NO_FILE){
        $file=$_FILES['profile_photo'];
        if($file['error'] !== UPLOAD_ERR_OK){
            flash('error','Profile photo upload failed. Please try again.');
            header('Location: profile.php'); exit;
        }
        if($file['size'] > 5 * 1024 * 1024){
            flash('error','Profile photo must be 5 MB or smaller.');
            header('Location: profile.php'); exit;
        }

        $finfo=new finfo(FILEINFO_MIME_TYPE);
        $mime=$finfo->file($file['tmp_name']);
        $allowed=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'];
        if(!isset($allowed[$mime])){
            flash('error','Use a JPG, PNG or WEBP image for the profile photo.');
            header('Location: profile.php'); exit;
        }

        $uploadDir=__DIR__.'/uploads/profile_photos';
        if(!is_dir($uploadDir) && !mkdir($uploadDir,0755,true)){
            flash('error','Could not create the profile photo folder.');
            header('Location: profile.php'); exit;
        }
        $filename='user_'.$uid.'_'.bin2hex(random_bytes(8)).'.'.$allowed[$mime];
        $destination=$uploadDir.'/'.$filename;
        if(!move_uploaded_file($file['tmp_name'],$destination)){
            flash('error','Could not save the profile photo.');
            header('Location: profile.php'); exit;
        }

        if($photoPath && str_starts_with($photoPath,'uploads/profile_photos/')){
            $old=__DIR__.'/'.$photoPath;
            if(is_file($old)) @unlink($old);
        }
        $photoPath='uploads/profile_photos/'.$filename;
    }

    $stmt=$pdo->prepare('UPDATE users SET profile_photo=?,bio=?,college=?,branch=?,graduation_year=?,location=?,company_name=?,company_description=? WHERE id=?');
    $stmt->execute([
        $photoPath,
        trim($_POST['bio']??''),
        trim($_POST['college']??''),
        trim($_POST['branch']??''),
        ($_POST['graduation_year']??'')?:null,
        trim($_POST['location']??''),
        trim($_POST['company_name']??''),
        trim($_POST['company_description']??''),
        $uid
    ]);
    flash('success','Profile updated.');
    header('Location: profile.php'); exit;
}
$stmt=$pdo->prepare('SELECT * FROM users WHERE id=?');
$stmt->execute([$uid]);
$u=$stmt->fetch();
include 'includes/header.php';
?>
<div class="grid two">
  <div class="card">
    <div class="profile-photo-wrap">
      <?php if(!empty($u['profile_photo'])): ?>
        <img class="profile-photo" src="<?=e($u['profile_photo'])?>" alt="<?=e($u['name'])?> profile photo">
      <?php else: ?>
        <div class="profile-photo placeholder"><?=e(strtoupper(substr($u['name'],0,1)))?></div>
      <?php endif; ?>
    </div>
    <div class="kicker">Public profile</div>
    <h1><?=e($u['name'])?></h1>
    <span class="badge"><?=e($u['role'])?></span>
    <p><?=e($u['bio']?:'Add a professional bio.')?></p>
    <p class="muted"><?=e($u['email'])?> • <?=e($u['location']?:'Location not set')?></p>
    <h3>Trust Score: <?=e($u['trust_score'])?></h3>
    <p class="muted">Verification: <?=e($u['verification_status'])?></p>
  </div>

  <div class="card">
    <h2>Edit Profile</h2>
    <form method="post" enctype="multipart/form-data">
      <div class="form-group">
        <label>Profile Photo</label>
        <input type="file" name="profile_photo" accept="image/jpeg,image/png,image/webp">
        <p class="muted">JPG, PNG or WEBP • Maximum 5 MB</p>
      </div>
      <div class="form-group"><label>Bio</label><textarea name="bio"><?=e($u['bio'])?></textarea></div>
      <div class="form-group"><label>Location</label><input name="location" value="<?=e($u['location'])?>"></div>
      <div class="form-group"><label>College</label><input name="college" value="<?=e($u['college'])?>"></div>
      <div class="form-group"><label>Branch</label><input name="branch" value="<?=e($u['branch'])?>"></div>
      <div class="form-group"><label>Graduation Year</label><input type="number" name="graduation_year" value="<?=e($u['graduation_year'])?>"></div>
      <button class="btn">Save Profile</button>
    </form>
  </div>
</div>
<?php include 'includes/footer.php'; ?>
