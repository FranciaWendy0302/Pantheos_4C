-- ============================================
-- MANUAL GOD SYSTEM SETUP
-- ============================================
-- Run this in phpMyAdmin if SETUP_GOD_SYSTEM.bat doesn't work
-- 
-- Instructions:
-- 1. Open phpMyAdmin (http://localhost/phpmyadmin)
-- 2. Select database 'mmorpg_game' from left sidebar
-- 3. Click 'SQL' tab at the top
-- 4. Copy and paste this entire file
-- 5. Click 'Go' button at bottom
-- ============================================

USE mmorpg_game;

-- ============================================
-- STEP 1: Add god columns to player_data
-- ============================================

-- Check if columns already exist before adding
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
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' INT DEFAULT 0 COMMENT ''Selected god: 0=None, 1=Athena, 2=Zeus, 3=Venus, 4=Asclepius, 5=Hades, 6=Ares, 7=Titan, 8=Gigantes'';')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Add god_skill_unlocked column
SET @columnname = 'god_skill_unlocked';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' BOOLEAN DEFAULT FALSE COMMENT ''Whether player has unlocked their god special skill'';')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- ============================================
-- STEP 2: Create god_quests table
-- ============================================

CREATE TABLE IF NOT EXISTS god_quests (
    id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    god_id INT NOT NULL,
    quest_chapter INT DEFAULT 1 COMMENT 'Current chapter of god storyline',
    quest_progress TEXT COMMENT 'JSON data for quest progress',
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES player_data(player_id) ON DELETE CASCADE,
    UNIQUE KEY unique_player_god (player_id, god_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 3: Create gods metadata table
-- ============================================

CREATE TABLE IF NOT EXISTS gods (
    god_id INT PRIMARY KEY,
    god_name VARCHAR(50) NOT NULL,
    god_title VARCHAR(100),
    role VARCHAR(50),
    alignment ENUM('Good', 'Evil', 'Fallen') NOT NULL,
    description TEXT,
    special_skill VARCHAR(100),
    skill_description TEXT,
    recommended_class VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 4: Insert god data
-- ============================================

INSERT INTO gods (god_id, god_name, god_title, role, alignment, description, special_skill, skill_description, recommended_class) VALUES
(1, 'Athena', 'Goddess of Wisdom & War', 'Tank', 'Good', 'Athena grants you divine protection and tactical wisdom.', 'Aegis Shield', 'Summon Athena\'s legendary shield for massive damage reduction', 'Swordsman'),
(2, 'Zeus', 'King of the Gods', 'Ranged DPS (Magic)', 'Good', 'Zeus bestows upon you the power of lightning.', 'Lightning Bolt', 'Call down Zeus\'s thunderbolt to devastate enemies', 'Mage'),
(3, 'Venus', 'Goddess of Love & Beauty', 'Support Buffer/Debuffer', 'Good', 'Venus grants you the power to charm and influence.', 'Divine Charm', 'Enchant allies with buffs or enemies with debuffs', 'Support'),
(4, 'Asclepius', 'God of Medicine & Healing', 'Healer', 'Good', 'Asclepius teaches you the sacred arts of healing.', 'Divine Restoration', 'Channel healing energy to restore HP to allies', 'Support'),
(5, 'Hades', 'God of the Underworld', 'Off-Tank / Control', 'Evil', 'Hades offers you dominion over death and shadows.', 'Shadow Grasp', 'Summon shadowy tendrils to immobilize enemies', 'Swordsman'),
(6, 'Ares', 'God of War', 'Melee DPS', 'Evil', 'Ares fuels your bloodlust and combat prowess.', 'Berserker Rage', 'Enter a rage state for increased damage and attack speed', 'Assassin'),
(7, 'Titan', 'Fallen Primordial', 'Hybrid', 'Fallen', 'The Titans offer raw primordial power.', 'Titanic Fury', 'Unleash primordial energy for massive area damage', 'Swordsman'),
(8, 'Gigantes', 'Fallen Giant', 'Hybrid', 'Fallen', 'The Gigantes grant you colossal might.', 'Giant\'s Wrath', 'Grow in size and power, dealing devastating blows', 'Swordsman')
ON DUPLICATE KEY UPDATE god_name=VALUES(god_name);

-- ============================================
-- STEP 5: Create indexes for performance
-- ============================================

-- Check and create index on player_data
SET @dbname = 'mmorpg_game';
SET @tablename = 'player_data';
SET @indexname = 'idx_player_god';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (index_name = @indexname)
  ) > 0,
  'SELECT 1',
  CONCAT('CREATE INDEX ', @indexname, ' ON ', @tablename, '(player_id, god_id);')
));
PREPARE createIndexIfNotExists FROM @preparedStatement;
EXECUTE createIndexIfNotExists;
DEALLOCATE PREPARE createIndexIfNotExists;

-- Check and create index on god_quests
SET @tablename = 'god_quests';
SET @indexname = 'idx_god_quests_player';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (index_name = @indexname)
  ) > 0,
  'SELECT 1',
  CONCAT('CREATE INDEX ', @indexname, ' ON ', @tablename, '(player_id);')
));
PREPARE createIndexIfNotExists FROM @preparedStatement;
EXECUTE createIndexIfNotExists;
DEALLOCATE PREPARE createIndexIfNotExists;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Show the updated player_data structure
SELECT 'player_data table structure:' AS '';
DESCRIBE player_data;

-- Show all gods
SELECT '' AS '';
SELECT 'All gods in database:' AS '';
SELECT god_id, god_name, role, alignment, special_skill FROM gods ORDER BY god_id;

-- Show god_quests table structure
SELECT '' AS '';
SELECT 'god_quests table structure:' AS '';
DESCRIBE god_quests;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

SELECT '' AS '';
SELECT '============================================' AS '';
SELECT 'GOD SYSTEM SETUP COMPLETE!' AS '';
SELECT '============================================' AS '';
SELECT 'Tables created:' AS '';
SELECT '  - gods (8 gods inserted)' AS '';
SELECT '  - god_quests (quest tracking)' AS '';
SELECT 'Columns added to player_data:' AS '';
SELECT '  - god_id' AS '';
SELECT '  - god_skill_unlocked' AS '';
SELECT '' AS '';
SELECT 'You can now use the god selection system!' AS '';
SELECT '============================================' AS '';
