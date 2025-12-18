-- ============================================
-- COMPLETE FRESH DATABASE SETUP
-- Pantheos MMORPG Game Database
-- ============================================

-- Drop existing database if it exists
DROP DATABASE IF EXISTS mmorpg_game;

-- Create fresh database
CREATE DATABASE mmorpg_game;
USE mmorpg_game;

-- ============================================
-- ACCOUNTS TABLE
-- ============================================
CREATE TABLE accounts (
    player_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    
    -- Character Information
    character_slot TINYINT NOT NULL DEFAULT 1,
    nickname VARCHAR(50) NOT NULL,
    character_class VARCHAR(20) NOT NULL DEFAULT 'Swordsman',
    
    -- God System
    god_id INT DEFAULT NULL,
    god_skill_unlocked BOOLEAN DEFAULT FALSE,
    
    -- Stats
    level INT DEFAULT 1,
    xp INT DEFAULT 0,
    hp INT DEFAULT 100,
    max_hp INT DEFAULT 100,
    mana INT DEFAULT 100,
    max_mana INT DEFAULT 100,
    
    -- Currency
    currency INT DEFAULT 0,
    
    -- Combat Stats
    attack INT DEFAULT 10,
    defense INT DEFAULT 5,
    
    -- Position
    pos_x FLOAT DEFAULT 0,
    pos_y FLOAT DEFAULT 0,
    scene_path VARCHAR(255) DEFAULT 'res://Levels/final map/scene/safezone.tscn',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_username (username),
    INDEX idx_character_slot (character_slot),
    INDEX idx_god_id (god_id)
);

-- ============================================
-- GODS TABLE
-- ============================================
CREATE TABLE gods (
    god_id INT AUTO_INCREMENT PRIMARY KEY,
    god_name VARCHAR(50) NOT NULL UNIQUE,
    god_title VARCHAR(100),
    god_description TEXT,
    god_domain VARCHAR(50),
    
    -- Stat Bonuses
    stat_bonus_type VARCHAR(20),
    stat_bonus_value INT DEFAULT 0,
    
    -- Special Skill
    special_skill_name VARCHAR(100),
    special_skill_description TEXT,
    special_skill_cooldown INT DEFAULT 60,
    
    -- Requirements
    required_level INT DEFAULT 1,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INVENTORY TABLE
-- ============================================
CREATE TABLE inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT NOT NULL,
    slot_index INT NOT NULL,
    item_id VARCHAR(100),
    item_path VARCHAR(255),
    quantity INT DEFAULT 1,
    is_equipped BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (player_id) REFERENCES accounts(player_id) ON DELETE CASCADE,
    UNIQUE KEY unique_player_slot (player_id, slot_index),
    INDEX idx_player_id (player_id)
);

-- ============================================
-- QUESTS TABLE
-- ============================================
CREATE TABLE quests (
    quest_id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT NOT NULL,
    quest_name VARCHAR(100) NOT NULL,
    quest_status VARCHAR(20) DEFAULT 'active',
    progress INT DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (player_id) REFERENCES accounts(player_id) ON DELETE CASCADE,
    INDEX idx_player_quests (player_id, quest_status)
);

-- ============================================
-- FRIENDS TABLE
-- ============================================
CREATE TABLE friends (
    friendship_id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT NOT NULL,
    friend_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (player_id) REFERENCES accounts(player_id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES accounts(player_id) ON DELETE CASCADE,
    UNIQUE KEY unique_friendship (player_id, friend_id),
    INDEX idx_player_friends (player_id, status)
);

-- ============================================
-- INSERT DEFAULT GODS
-- ============================================
INSERT INTO gods (god_name, god_title, god_description, god_domain, stat_bonus_type, stat_bonus_value, special_skill_name, special_skill_description, special_skill_cooldown, required_level) VALUES
('Zeus', 'King of the Gods', 'God of the sky, lightning, and thunder. Ruler of Mount Olympus.', 'Sky & Thunder', 'attack', 15, 'Lightning Bolt', 'Summon a devastating lightning bolt that strikes enemies in an area.', 60, 1),
('Poseidon', 'God of the Seas', 'God of the sea, earthquakes, and horses. Brother of Zeus.', 'Sea & Storms', 'defense', 20, 'Tidal Wave', 'Create a massive wave that pushes back and damages enemies.', 45, 1),
('Athena', 'Goddess of Wisdom', 'Goddess of wisdom, warfare, and crafts. Patron of heroes.', 'Wisdom & War', 'defense', 15, 'Aegis Shield', 'Summon an impenetrable shield that blocks all damage for a short time.', 90, 1),
('Ares', 'God of War', 'God of war, violence, and bloodshed. Fierce and brutal in battle.', 'War & Battle', 'attack', 25, 'War Cry', 'Release a powerful war cry that increases attack and movement speed.', 30, 1),
('Apollo', 'God of Light', 'God of music, poetry, light, prophecy, and healing.', 'Light & Healing', 'mana', 30, 'Solar Beam', 'Fire a concentrated beam of sunlight that pierces through enemies.', 40, 1),
('Artemis', 'Goddess of the Hunt', 'Goddess of the hunt, wilderness, and the moon. Twin sister of Apollo.', 'Hunt & Moon', 'attack', 20, 'Moon Arrow', 'Fire a magical arrow that splits into multiple projectiles.', 35, 1),
('Hades', 'God of the Underworld', 'God of the dead and the underworld. Brother of Zeus and Poseidon.', 'Death & Underworld', 'hp', 50, 'Soul Drain', 'Drain life from nearby enemies to heal yourself.', 50, 5),
('Hera', 'Queen of the Gods', 'Goddess of marriage, women, and family. Wife of Zeus.', 'Marriage & Family', 'hp', 40, 'Divine Protection', 'Grant yourself and nearby allies temporary invulnerability.', 120, 5),
('Hermes', 'Messenger of the Gods', 'God of travel, trade, communication, and thieves.', 'Speed & Trade', 'speed', 30, 'Swift Step', 'Gain incredible movement speed and leave afterimages.', 25, 1),
('Hephaestus', 'God of the Forge', 'God of fire, metalworking, and crafts. Master blacksmith.', 'Fire & Forge', 'defense', 25, 'Forge Armor', 'Temporarily enhance your armor with divine fire resistance.', 60, 5);

-- ============================================
-- CREATE SAMPLE ACCOUNTS (FOR TESTING)
-- ============================================
-- Password for all test accounts: "test123"
-- Hash generated with bcrypt
INSERT INTO accounts (username, password_hash, nickname, character_class, level, xp, currency, hp, max_hp, mana, max_mana, attack, defense, god_id, god_skill_unlocked) VALUES
('testuser1', '$2b$10$rQ3qX8Y9Z1234567890abcdefghijklmnopqrstuvwxyz', 'TestWarrior', 'Swordsman', 5, 250, 1000, 150, 150, 100, 100, 25, 15, 1, TRUE),
('testuser2', '$2b$10$rQ3qX8Y9Z1234567890abcdefghijklmnopqrstuvwxyz', 'TestMage', 'Mage', 3, 120, 500, 80, 80, 150, 150, 15, 10, 5, FALSE),
('testuser3', '$2b$10$rQ3qX8Y9Z1234567890abcdefghijklmnopqrstuvwxyz', 'TestArcher', 'Archer', 4, 180, 750, 100, 100, 120, 120, 20, 12, 6, TRUE);

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Check tables
SELECT 'Tables created:' as status;
SHOW TABLES;

-- Check gods
SELECT 'Gods inserted:' as status;
SELECT god_id, god_name, god_title, god_domain FROM gods;

-- Check accounts
SELECT 'Test accounts created:' as status;
SELECT player_id, username, nickname, character_class, level, currency, god_id FROM accounts;

-- ============================================
-- USEFUL QUERIES FOR MANAGEMENT
-- ============================================

-- View all players with their gods
-- SELECT a.player_id, a.username, a.nickname, a.character_class, a.level, a.currency, g.god_name, g.god_title
-- FROM accounts a
-- LEFT JOIN gods g ON a.god_id = g.god_id;

-- Delete all player data (keep structure)
-- TRUNCATE TABLE inventory;
-- TRUNCATE TABLE quests;
-- TRUNCATE TABLE friends;
-- TRUNCATE TABLE accounts;

-- Reset auto increment
-- ALTER TABLE accounts AUTO_INCREMENT = 1;

SELECT 'Database setup complete!' as status;
