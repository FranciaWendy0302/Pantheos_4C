-- ============================================
-- MIGRATE TO MULTI-SLOT CHARACTER SYSTEM
-- Run this on existing mmorpg_game database
-- ============================================

USE mmorpg_game;

-- ============================================
-- BACKUP EXISTING DATA
-- ============================================
-- Before running this, backup your database:
-- mysqldump -u root -p mmorpg_game > backup_before_slots.sql

-- ============================================
-- STEP 1: Add new columns
-- ============================================

-- Add id column as auto-increment (will become new primary key)
ALTER TABLE player_data 
ADD COLUMN id INT AUTO_INCREMENT FIRST,
ADD UNIQUE KEY temp_id (id);

-- Add character_slot column (default to 1 for existing characters)
ALTER TABLE player_data 
ADD COLUMN character_slot TINYINT NOT NULL DEFAULT 1 AFTER player_id;

-- Add created_at if it doesn't exist
ALTER TABLE player_data 
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP AFTER bomb_count;

-- ============================================
-- STEP 2: Update primary key
-- ============================================

-- Drop old primary key
ALTER TABLE player_data DROP PRIMARY KEY;

-- Set id as new primary key
ALTER TABLE player_data DROP KEY temp_id, ADD PRIMARY KEY (id);

-- ============================================
-- STEP 3: Add unique constraint
-- ============================================

-- Ensure each player can only have one character per slot
ALTER TABLE player_data 
ADD UNIQUE KEY unique_player_slot (player_id, character_slot);

-- ============================================
-- STEP 4: Add indexes
-- ============================================

-- Add index on player_id for faster lookups
ALTER TABLE player_data 
ADD INDEX idx_player_id (player_id);

-- ============================================
-- VERIFICATION
-- ============================================

-- Show table structure
DESCRIBE player_data;

-- Show existing data
SELECT id, player_id, character_slot, nickname, character_class, god_id 
FROM player_data 
ORDER BY player_id, character_slot;

SELECT '✓ Migration complete! Multi-slot system ready.' AS status;

-- ============================================
-- NOTES
-- ============================================
-- All existing characters are now in slot 1
-- Players can now create a second character in slot 2
-- Each (player_id, character_slot) combination is unique
