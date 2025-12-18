-- ============================================
-- FIX PLAYER_DATA SCHEMA
-- Fixes the "Unknown column 'id'" error
-- ============================================

USE mmorpg_game;

-- Backup existing data
CREATE TABLE IF NOT EXISTS player_data_backup_20241201 AS 
SELECT * FROM player_data;

SELECT 'Backup created: player_data_backup_20241201' as status;

-- Check current structure
DESCRIBE player_data;

-- Option 1: If player_data has wrong structure, recreate it
-- Uncomment the following if you want to recreate the table:

/*
DROP TABLE IF EXISTS player_data;

CREATE TABLE player_data (
    player_id INT NOT NULL,
    character_slot TINYINT NOT NULL DEFAULT 1,
    nickname VARCHAR(50) NOT NULL,
    character_class VARCHAR(20) DEFAULT 'Swordsman',
    
    -- Stats
    level INT DEFAULT 1,
    xp INT DEFAULT 0,
    hp INT DEFAULT 100,
    max_hp INT DEFAULT 100,
    mp INT DEFAULT 100,
    max_mp INT DEFAULT 100,
    
    -- Currency
    currency INT DEFAULT 0,
    
    -- Combat Stats
    attack INT DEFAULT 10,
    defense INT DEFAULT 5,
    
    -- Position
    position_x FLOAT DEFAULT 0,
    position_y FLOAT DEFAULT 0,
    current_map VARCHAR(100) DEFAULT 'res://Levels/final map/scene/safezone.tscn',
    
    -- God System
    god_id INT DEFAULT NULL,
    god_skill_unlocked BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (player_id, character_slot),
    INDEX idx_nickname (nickname),
    INDEX idx_level (level),
    INDEX idx_god_id (god_id),
    FOREIGN KEY (player_id) REFERENCES accounts(player_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Restore data from backup (all as slot 1)
INSERT INTO player_data (
    player_id, character_slot, nickname, character_class,
    level, xp, hp, max_hp, mp, max_mp, currency,
    attack, defense, position_x, position_y, current_map,
    god_id, god_skill_unlocked
)
SELECT 
    player_id, 
    1 as character_slot,  -- Default to slot 1
    nickname, 
    character_class,
    level, 
    xp, 
    hp, 
    max_hp, 
    mp, 
    max_mp, 
    currency,
    attack, 
    defense, 
    position_x, 
    position_y, 
    current_map,
    god_id, 
    god_skill_unlocked
FROM player_data_backup_20241201;

SELECT 'Table recreated and data restored' as status;
*/

-- Option 2: If table structure is correct, just verify
SELECT 'Checking player_data structure...' as status;
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    COLUMN_KEY,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'mmorpg_game' 
  AND TABLE_NAME = 'player_data'
ORDER BY ORDINAL_POSITION;

-- Show current data
SELECT 'Current player_data records:' as status;
SELECT 
    player_id, 
    character_slot, 
    nickname, 
    character_class, 
    level,
    god_id
FROM player_data;

-- ============================================
-- VERIFICATION
-- ============================================

SELECT '========================================' as '';
SELECT 'FIX VERIFICATION' as '';
SELECT '========================================' as '';

-- Check if primary key is correct
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✓ Primary key includes player_id'
        ELSE '✗ Primary key missing player_id'
    END as primary_key_check
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'mmorpg_game'
  AND TABLE_NAME = 'player_data'
  AND CONSTRAINT_NAME = 'PRIMARY'
  AND COLUMN_NAME = 'player_id';

-- Check if character_slot is in primary key
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✓ Primary key includes character_slot (multi-character support)'
        ELSE '⚠ Primary key does not include character_slot (single character only)'
    END as slot_check
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'mmorpg_game'
  AND TABLE_NAME = 'player_data'
  AND CONSTRAINT_NAME = 'PRIMARY'
  AND COLUMN_NAME = 'character_slot';

-- Check if 'id' column exists (should NOT exist)
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ No "id" column (correct)'
        ELSE '✗ "id" column exists (should be removed)'
    END as id_column_check
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'mmorpg_game'
  AND TABLE_NAME = 'player_data'
  AND COLUMN_NAME = 'id';

SELECT '========================================' as '';
SELECT 'If all checks show ✓, the schema is correct!' as '';
SELECT 'If not, uncomment Option 1 above and re-run.' as '';
SELECT '========================================' as '';
