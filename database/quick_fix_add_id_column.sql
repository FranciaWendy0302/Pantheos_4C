-- ============================================
-- QUICK FIX: Add 'id' column to player_data
-- Alternative approach - adds the column the code expects
-- ============================================
-- 
-- NOTE: This is NOT the recommended approach!
-- The better fix is to update the server code (already done).
-- Use this ONLY if you want to keep the old query structure.
-- 
-- ============================================

USE mmorpg_game;

-- Check if 'id' column already exists
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN 'Column "id" already exists'
        ELSE 'Column "id" does not exist - will add it'
    END as status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'mmorpg_game'
  AND TABLE_NAME = 'player_data'
  AND COLUMN_NAME = 'id';

-- Add 'id' column as auto-increment primary key
-- This will fail if the column already exists (which is fine)

-- Step 1: Drop existing primary key if it's on player_id
ALTER TABLE player_data DROP PRIMARY KEY;

-- Step 2: Add auto-increment id column
ALTER TABLE player_data 
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- Step 3: Add unique constraint on player_id + character_slot
ALTER TABLE player_data 
ADD UNIQUE KEY unique_player_slot (player_id, character_slot);

-- Verify the change
DESCRIBE player_data;

SELECT '========================================' as '';
SELECT 'QUICK FIX APPLIED' as '';
SELECT '========================================' as '';
SELECT 'Added "id" column as primary key' as '';
SELECT 'player_id + character_slot now have unique constraint' as '';
SELECT '' as '';
SELECT 'WARNING: This is a workaround!' as '';
SELECT 'The recommended fix is to update server code (already done).' as '';
SELECT '========================================' as '';

-- Show current structure
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    COLUMN_KEY,
    EXTRA
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'mmorpg_game' 
  AND TABLE_NAME = 'player_data'
ORDER BY ORDINAL_POSITION;
