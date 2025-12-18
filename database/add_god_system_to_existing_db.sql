-- ============================================
-- ADD GOD SYSTEM TO EXISTING DATABASE
-- Run this if you already have mmorpg_game database
-- ============================================

USE mmorpg_game;

-- ============================================
-- Add god_id column if it doesn't exist
-- ============================================
SET @dbname = 'mmorpg_game';
SET @tablename = 'player_data';
SET @columnname = 'god_id';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 'Column god_id already exists' AS msg;",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " INT NOT NULL DEFAULT 0 AFTER character_class;")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- ============================================
-- Add god_skill_unlocked column if it doesn't exist
-- ============================================
SET @columnname = 'god_skill_unlocked';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 'Column god_skill_unlocked already exists' AS msg;",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " BOOLEAN NOT NULL DEFAULT FALSE AFTER god_id;")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- ============================================
-- Add arrow_count column if it doesn't exist
-- ============================================
SET @columnname = 'arrow_count';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 'Column arrow_count already exists' AS msg;",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " INT NOT NULL DEFAULT 0 AFTER current_map;")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- ============================================
-- Add bomb_count column if it doesn't exist
-- ============================================
SET @columnname = 'bomb_count';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 'Column bomb_count already exists' AS msg;",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " INT NOT NULL DEFAULT 0 AFTER arrow_count;")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- ============================================
-- Add index on god_id if it doesn't exist
-- ============================================
SET @indexname = 'idx_god_id';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (index_name = @indexname)
  ) > 0,
  "SELECT 'Index idx_god_id already exists' AS msg;",
  CONCAT("CREATE INDEX ", @indexname, " ON ", @tablename, " (god_id);")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- ============================================
-- Verify the changes
-- ============================================
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_DEFAULT,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'mmorpg_game'
AND TABLE_NAME = 'player_data'
AND COLUMN_NAME IN ('god_id', 'god_skill_unlocked', 'arrow_count', 'bomb_count')
ORDER BY ORDINAL_POSITION;

SELECT '✓ God system columns added successfully!' AS status;

-- ============================================
-- GOD REFERENCE
-- ============================================
-- god_id values:
-- 0 = None (no god selected)
-- 1 = Athena (Tank)
-- 2 = Zeus (Ranged DPS)
-- 3 = Venus (Support)
-- 4 = Asclepius (Healer)
-- 5 = Hades (Off-Tank)
-- 6 = Ares (Melee DPS)
-- 7 = Thanatos (Assassin)
-- 8 = Nemesis (Vengeance)
