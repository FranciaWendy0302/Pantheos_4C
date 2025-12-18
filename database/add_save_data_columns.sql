-- ============================================
-- ADD SAVE DATA COLUMNS TO PLAYER_DATA
-- Adds inventory, quests, and persistence columns
-- ============================================

USE mmorpg_game;

-- Add columns for save data (if they don't exist)
ALTER TABLE player_data 
ADD COLUMN IF NOT EXISTS inventory TEXT DEFAULT NULL COMMENT 'JSON string of inventory items',
ADD COLUMN IF NOT EXISTS quests TEXT DEFAULT NULL COMMENT 'JSON string of quest data',
ADD COLUMN IF NOT EXISTS persistence TEXT DEFAULT NULL COMMENT 'JSON string of persistent world state (opened chests, etc)';

-- Verify columns were added
DESCRIBE player_data;

SELECT 'Save data columns added successfully!' as status;
