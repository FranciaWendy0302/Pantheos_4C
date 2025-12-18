-- ============================================
-- ADD INVENTORY AND QUESTS COLUMNS TO player_data
-- This allows storing inventory/quests as JSON
-- ============================================

USE mmorpg_game;

-- Add inventory column (stores JSON array of items)
ALTER TABLE player_data 
ADD COLUMN inventory TEXT DEFAULT NULL COMMENT 'JSON array of inventory items';

-- Add quests column (stores JSON array of quests)
ALTER TABLE player_data 
ADD COLUMN quests TEXT DEFAULT NULL COMMENT 'JSON array of quest data';

-- Add abilities column (stores JSON array of abilities)
ALTER TABLE player_data 
ADD COLUMN abilities TEXT DEFAULT NULL COMMENT 'JSON array of ability slots';

-- Add persistence column (stores JSON array of world state)
ALTER TABLE player_data 
ADD COLUMN persistence TEXT DEFAULT NULL COMMENT 'JSON array of world persistence data';

-- Verify columns were added
DESCRIBE player_data;

SELECT 'Columns added successfully!' as status;
SELECT 'inventory, quests, abilities, persistence' as new_columns;
