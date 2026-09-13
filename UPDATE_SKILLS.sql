USE `unimesh`;

-- Rename the two old SkillAI-compatible names if they exist.
UPDATE skills SET name='SQL', category='Database' WHERE name='MySQL';
UPDATE skills SET name='HTML', category='Web' WHERE name='HTML/CSS';

-- Make sure all five supported skills exist.
INSERT INTO skills(name,category)
SELECT 'Python','Programming' WHERE NOT EXISTS (SELECT 1 FROM skills WHERE name='Python');
INSERT INTO skills(name,category)
SELECT 'C++','Programming' WHERE NOT EXISTS (SELECT 1 FROM skills WHERE name='C++');
INSERT INTO skills(name,category)
SELECT 'HTML','Web' WHERE NOT EXISTS (SELECT 1 FROM skills WHERE name='HTML');
INSERT INTO skills(name,category)
SELECT 'Java','Programming' WHERE NOT EXISTS (SELECT 1 FROM skills WHERE name='Java');
INSERT INTO skills(name,category)
SELECT 'SQL','Database' WHERE NOT EXISTS (SELECT 1 FROM skills WHERE name='SQL');

-- Ensure each supported skill has levels 1-5 in the Unimesh assessment history table.
INSERT INTO assessments(skill_id,level,title,duration_minutes,passing_score)
SELECT s.id,l.level,CONCAT(s.name,' Level ',l.level,' Assessment'),60,70
FROM skills s
JOIN (SELECT 1 level UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) l
WHERE s.name IN ('Python','C++','HTML','Java','SQL')
AND NOT EXISTS (
  SELECT 1 FROM assessments a WHERE a.skill_id=s.id AND a.level=l.level
);
