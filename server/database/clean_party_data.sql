-- Clean party data for testing
USE mmorpg_game;

-- Delete all party data
DELETE FROM party_invites;
DELETE FROM party_members;
DELETE FROM parties;

-- Reset auto-increment
ALTER TABLE parties AUTO_INCREMENT = 1;
ALTER TABLE party_members AUTO_INCREMENT = 1;
ALTER TABLE party_invites AUTO_INCREMENT = 1;

-- Clear party_id from player_data
UPDATE player_data SET party_id = NULL WHERE party_id IS NOT NULL;

SELECT 'Party data cleaned!' AS status;
