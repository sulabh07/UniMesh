CREATE DATABASE IF NOT EXISTS unimesh CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE unimesh;

SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS notifications,messages,screening_submissions,screening_tasks,team_join_requests,team_invitations,team_members,teams,applications,jobs,peer_reviews,projects,trust_score_logs,verification_records,assessment_integrity_events,assessment_attempts,assessment_questions,assessments,user_skills,skills,external_profiles,users;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE users (
 id INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(120) NOT NULL,
 email VARCHAR(190) NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,
 role ENUM('student','recruiter','team_leader','admin') NOT NULL DEFAULT 'student',
 email_verified TINYINT(1) NOT NULL DEFAULT 0,
 verification_status ENUM('pending','verified','rejected','manual_review') NOT NULL DEFAULT 'pending',
 account_status ENUM('active','suspended') NOT NULL DEFAULT 'active',
 trust_score INT NOT NULL DEFAULT 0,
 profile_photo VARCHAR(255) NULL,
 bio TEXT NULL,
 college VARCHAR(190) NULL,
 branch VARCHAR(120) NULL,
 graduation_year INT NULL,
 location VARCHAR(190) NULL,
 resume_path VARCHAR(255) NULL,
 company_name VARCHAR(190) NULL,
 company_description TEXT NULL,
 company_document VARCHAR(255) NULL,
 google_id VARCHAR(190) NULL,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE skills (id INT AUTO_INCREMENT PRIMARY KEY,name VARCHAR(120) NOT NULL UNIQUE,category VARCHAR(120) NULL,active TINYINT(1) DEFAULT 1);
CREATE TABLE user_skills (
 id INT AUTO_INCREMENT PRIMARY KEY,user_id INT NOT NULL,skill_id INT NOT NULL,level TINYINT NOT NULL DEFAULT 1,verified TINYINT(1) DEFAULT 0,verified_at DATETIME NULL,star_rating DECIMAL(2,1) NULL,
 UNIQUE KEY uq_user_skill(user_id,skill_id),FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,FOREIGN KEY(skill_id) REFERENCES skills(id) ON DELETE CASCADE
);
CREATE TABLE external_profiles (id INT AUTO_INCREMENT PRIMARY KEY,user_id INT NOT NULL,provider ENUM('github','leetcode','codechef','hackerrank','codeforces','linkedin_learning','certificate') NOT NULL,profile_url VARCHAR(500),external_username VARCHAR(190),score DECIMAL(8,2) DEFAULT 0,metadata_json JSON NULL,verified TINYINT(1) DEFAULT 0,updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);

CREATE TABLE assessments (id INT AUTO_INCREMENT PRIMARY KEY,skill_id INT NOT NULL,level TINYINT NOT NULL,title VARCHAR(190) NOT NULL,duration_minutes INT DEFAULT 60,passing_score INT DEFAULT 70,randomize_questions TINYINT(1) DEFAULT 1,active TINYINT(1) DEFAULT 1,FOREIGN KEY(skill_id) REFERENCES skills(id) ON DELETE CASCADE);
CREATE TABLE assessment_questions (id INT AUTO_INCREMENT PRIMARY KEY,assessment_id INT NOT NULL,question_type ENUM('mcq','coding','text') DEFAULT 'mcq',question_text TEXT NOT NULL,options_json JSON NULL,correct_answer TEXT NULL,points INT DEFAULT 1,FOREIGN KEY(assessment_id) REFERENCES assessments(id) ON DELETE CASCADE);
CREATE TABLE assessment_attempts (id INT AUTO_INCREMENT PRIMARY KEY,assessment_id INT NOT NULL,user_id INT NOT NULL,started_at DATETIME DEFAULT CURRENT_TIMESTAMP,completed_at DATETIME NULL,score DECIMAL(6,2) DEFAULT 0,integrity_score DECIMAL(6,2) DEFAULT 100,status ENUM('started','completed','flagged','under_review') DEFAULT 'started',manual_review_requested TINYINT(1) DEFAULT 0,FOREIGN KEY(assessment_id) REFERENCES assessments(id) ON DELETE CASCADE,FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE assessment_integrity_events (id INT AUTO_INCREMENT PRIMARY KEY,attempt_id INT NOT NULL,event_type VARCHAR(80) NOT NULL,event_data TEXT NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(attempt_id) REFERENCES assessment_attempts(id) ON DELETE CASCADE);

CREATE TABLE projects (id INT AUTO_INCREMENT PRIMARY KEY,user_id INT NOT NULL,title VARCHAR(190) NOT NULL,description TEXT NOT NULL,tech_stack VARCHAR(500),live_link VARCHAR(500),github_link VARCHAR(500),start_date DATE NULL,end_date DATE NULL,status ENUM('unverified','pending','verified','rejected') DEFAULT 'unverified',project_score DECIMAL(6,2) DEFAULT 0,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE peer_reviews (id INT AUTO_INCREMENT PRIMARY KEY,project_id INT NOT NULL,reviewer_id INT NOT NULL,originality TINYINT,complexity TINYINT,code_quality TINYINT,documentation TINYINT,comments TEXT,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,FOREIGN KEY(reviewer_id) REFERENCES users(id) ON DELETE CASCADE);

CREATE TABLE jobs (id INT AUTO_INCREMENT PRIMARY KEY,recruiter_id INT NOT NULL,title VARCHAR(190) NOT NULL,company_name VARCHAR(190) NOT NULL,description TEXT NOT NULL,responsibilities TEXT,requirements TEXT,required_skills VARCHAR(500),experience_required VARCHAR(190),location VARCHAR(190),salary VARCHAR(120),duration VARCHAR(120),deadline DATE NULL,status ENUM('draft','open','closed') DEFAULT 'open',priority_listing TINYINT(1) DEFAULT 0,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(recruiter_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE applications (id INT AUTO_INCREMENT PRIMARY KEY,job_id INT NOT NULL,student_id INT NOT NULL,status ENUM('interested','applied','shortlisted','screening','selected','rejected','withdrawn') DEFAULT 'interested',match_score DECIMAL(6,2) DEFAULT 0,saved_by_recruiter TINYINT(1) DEFAULT 0,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,UNIQUE KEY uq_job_student(job_id,student_id),FOREIGN KEY(job_id) REFERENCES jobs(id) ON DELETE CASCADE,FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE);

CREATE TABLE teams (id INT AUTO_INCREMENT PRIMARY KEY,leader_id INT NOT NULL,name VARCHAR(190) NOT NULL,hackathon_name VARCHAR(190) NOT NULL,description TEXT,max_size INT DEFAULT 4,roles_needed VARCHAR(500),skills_required VARCHAR(500),created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,UNIQUE KEY uq_leader_hackathon(leader_id,hackathon_name),FOREIGN KEY(leader_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE team_members (id INT AUTO_INCREMENT PRIMARY KEY,team_id INT NOT NULL,user_id INT NOT NULL,member_role VARCHAR(120),status ENUM('active','left') DEFAULT 'active',joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,UNIQUE KEY uq_team_user(team_id,user_id),FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE,FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE team_invitations (id INT AUTO_INCREMENT PRIMARY KEY,team_id INT NOT NULL,student_id INT NOT NULL,role_offered VARCHAR(120),message TEXT,status ENUM('pending','accepted','declined') DEFAULT 'pending',created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE,FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE team_join_requests (id INT AUTO_INCREMENT PRIMARY KEY,team_id INT NOT NULL,user_id INT NOT NULL,status ENUM('pending','accepted','declined') DEFAULT 'pending',created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,UNIQUE KEY uq_team_request(team_id,user_id),FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE,FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);

CREATE TABLE screening_tasks (id INT AUTO_INCREMENT PRIMARY KEY,creator_id INT NOT NULL,job_id INT NULL,team_id INT NULL,title VARCHAR(190) NOT NULL,task_type ENUM('mcq','coding','text') NOT NULL,description TEXT,time_limit_minutes INT DEFAULT 60,programming_language VARCHAR(50),automatic_test_cases JSON NULL,deadline DATETIME NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(creator_id) REFERENCES users(id) ON DELETE CASCADE,FOREIGN KEY(job_id) REFERENCES jobs(id) ON DELETE CASCADE,FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE);
CREATE TABLE screening_submissions (id INT AUTO_INCREMENT PRIMARY KEY,task_id INT NOT NULL,user_id INT NOT NULL,response_text MEDIUMTEXT,status ENUM('not_started','working','submitted','evaluated') DEFAULT 'submitted',score DECIMAL(6,2) NULL,passed TINYINT(1) DEFAULT 0,manual_feedback TEXT,submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(task_id) REFERENCES screening_tasks(id) ON DELETE CASCADE,FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);

CREATE TABLE messages (id INT AUTO_INCREMENT PRIMARY KEY,sender_id INT NOT NULL,receiver_id INT NOT NULL,message TEXT NOT NULL,read_at DATETIME NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(sender_id) REFERENCES users(id) ON DELETE CASCADE,FOREIGN KEY(receiver_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE notifications (id INT AUTO_INCREMENT PRIMARY KEY,user_id INT NOT NULL,title VARCHAR(190) NOT NULL,body TEXT,event_type VARCHAR(80),is_read TINYINT(1) DEFAULT 0,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE trust_score_logs (id INT AUTO_INCREMENT PRIMARY KEY,user_id INT NOT NULL,change_amount INT NOT NULL,reason VARCHAR(255) NOT NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE verification_records (id INT AUTO_INCREMENT PRIMARY KEY,user_id INT NOT NULL,verification_type ENUM('identity','institution','company','skill','project','screening','external') NOT NULL,reference_id INT NULL,status ENUM('pending','verified','rejected','manual_review') DEFAULT 'pending',notes TEXT,reviewed_by INT NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,FOREIGN KEY(reviewed_by) REFERENCES users(id) ON DELETE SET NULL);

INSERT INTO skills(name,category) VALUES
('Python','Programming'),('C++','Programming'),('HTML','Web'),('Java','Programming'),('SQL','Database');

INSERT INTO assessments(skill_id,level,title,duration_minutes,passing_score)
SELECT id,1,CONCAT(name,' Level 1 Assessment'),60,70 FROM skills;
INSERT INTO assessments(skill_id,level,title,duration_minutes,passing_score)
SELECT id,2,CONCAT(name,' Level 2 Assessment'),60,70 FROM skills;
INSERT INTO assessments(skill_id,level,title,duration_minutes,passing_score)
SELECT id,3,CONCAT(name,' Level 3 Assessment'),60,70 FROM skills;
INSERT INTO assessments(skill_id,level,title,duration_minutes,passing_score)
SELECT id,4,CONCAT(name,' Level 4 Assessment'),60,70 FROM skills;
INSERT INTO assessments(skill_id,level,title,duration_minutes,passing_score)
SELECT id,5,CONCAT(name,' Level 5 Assessment'),60,70 FROM skills;

-- Demo admin password is admin123 (PHP password_hash output below)
INSERT INTO users(name,email,password_hash,role,email_verified,verification_status,trust_score)
VALUES('Unimesh Admin','admin@unimesh.local','$2y$12$oD2p5VVFG53gIV50P6i4zutKAAI2B850vE8EaTs9hJ5JRWJN5AMOm','admin',1,'verified',100);

INSERT INTO users(name,email,password_hash,role,email_verified,verification_status,trust_score,college,branch,location,bio)
VALUES('Demo Student','student@unimesh.local','$2y$12$oD2p5VVFG53gIV50P6i4zutKAAI2B850vE8EaTs9hJ5JRWJN5AMOm','student',1,'verified',78,'Thapar Institute','CSE','Patiala','Student building verified technical skills.');
INSERT INTO users(name,email,password_hash,role,email_verified,verification_status,trust_score,company_name,company_description)
VALUES('Demo Recruiter','recruiter@unimesh.local','$2y$12$oD2p5VVFG53gIV50P6i4zutKAAI2B850vE8EaTs9hJ5JRWJN5AMOm','recruiter',1,'verified',80,'Unimesh Labs','Demo recruiting organization.');
INSERT INTO users(name,email,password_hash,role,email_verified,verification_status,trust_score,college)
VALUES('Demo Team Leader','leader@unimesh.local','$2y$12$oD2p5VVFG53gIV50P6i4zutKAAI2B850vE8EaTs9hJ5JRWJN5AMOm','team_leader',1,'verified',82,'Thapar Institute');

INSERT INTO jobs(recruiter_id,title,company_name,description,required_skills,location,salary,duration,status)
SELECT id,'Software Engineering Intern','Unimesh Labs','Build product features for a skill-verification platform.','Python, C++, SQL','Hybrid','₹30,000/month','6 months','open' FROM users WHERE email='recruiter@unimesh.local';
INSERT INTO teams(leader_id,name,hackathon_name,description,max_size,roles_needed,skills_required)
SELECT id,'MeshMakers','Smart India Hackathon','Building a transparent talent verification product.',4,'Backend Developer, ML Engineer','Python, C++, HTML, Java, SQL' FROM users WHERE email='leader@unimesh.local';
INSERT INTO team_members(team_id,user_id,member_role,status)
SELECT t.id,u.id,'Leader','active' FROM teams t JOIN users u ON u.id=t.leader_id WHERE t.name='MeshMakers';
