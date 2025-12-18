-- ============================================
-- GOD SELECTION SYSTEM SCHEMA
-- ============================================
-- Add god selection column to player_data table

-- Add god_id column to store player's selected god
ALTER TABLE player_data 
ADD COLUMN IF NOT EXISTS god_id INT DEFAULT 0 COMMENT 'Selected god: 0=None, 1=Athena, 2=Zeus, 3=Venus, 4=Asclepius, 5=Hades, 6=Ares, 7=Titan, 8=Gigantes';

-- Add god_skill_unlocked column to track if player has unlocked their god's special skill
ALTER TABLE player_data 
ADD COLUMN IF NOT EXISTS god_skill_unlocked BOOLEAN DEFAULT FALSE COMMENT 'Whether player has unlocked their god special skill';

-- ============================================
-- GOD QUEST TRACKING TABLE
-- ============================================
-- Track god-specific quest progress

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
-- GOD METADATA TABLE (Optional - for future expansion)
-- ============================================
-- Store god information (can be used for dynamic god system)

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

-- Insert god data
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
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_player_god ON player_data(player_id, god_id);
CREATE INDEX idx_god_quests_player ON god_quests(player_id);
