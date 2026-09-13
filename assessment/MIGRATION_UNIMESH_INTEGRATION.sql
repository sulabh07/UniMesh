USE `skillai`;
ALTER TABLE `attempts`
  ADD COLUMN `unimesh_user_id` INT UNSIGNED NULL AFTER `result`,
  ADD COLUMN `unimesh_skill_id` INT UNSIGNED NULL AFTER `unimesh_user_id`;
