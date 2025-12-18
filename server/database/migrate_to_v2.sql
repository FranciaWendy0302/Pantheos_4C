-- Migrate Party System from V1 to V2
-- This adds missing columns to existing tables

USE mmorpg_game;

-- Add missing columns to parties table
ALTER TABLE parties 
ADD COLUMN IF NOT EXISTS party_name VARCHAR(50) DEFAULT NULL AFTER leader_id,
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE AFTER party_name,
ADD COLUMN IF NOT EXISTS max_members TINYINT DEFAULT 5 AFTER is_public,
ADD COLUMN IF NOT EXISTS min_level TINYINT DEFAULT 1 AFTER max_members,
ADD COLUMN IF NOT EXISTS max_level TINYINT DEFAULT 100 AFTER min_level,
ADD COLUMN IF NOT EXISTS loot_mode ENUM('round_robin', 'free_for_all', 'master_loot', 'need_before_greed') DEFAULT 'round_robin' AFTER max_level,
ADD COLUMN IF NOT EXISTS auto_accept_invites BOOLEAN DEFAULT FALSE AFTER loot_mode,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at;

-- Add missing indexes to parties table
ALTER TABLE parties
ADD INDEX IF NOT EXISTS idx_public (is_public);

-- Add missing columns to party_members table
ALTER TABLE party_members
ADD COLUMN IF NOT EXISTS role ENUM('leader', 'member', 'assistant') DEFAULT 'member' AFTER player_id;

-- Add missing indexes to party_members table
ALTER TABLE party_members
ADD INDEX IF NOT EXISTS idx_role (role);

-- Add missing columns to party_invites table
ALTER TABLE party_invites
ADD COLUMN IF NOT EXISTS message VARCHAR(200) DEFAULT NULL AFTER invitee_id,
ADD COLUMN IF NOT EXISTS responded_at TIMESTAMP NULL DEFAULT NULL AFTER status;

-- Update expires_at to be NOT NULL with default
ALTER TABLE party_invites
MODIFY COLUMN expires_at TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL 5 MINUTE);

-- Add missing indexes to party_invites table
ALTER TABLE party_invites
ADD INDEX IF NOT EXISTS idx_expires (expires_at),
ADD INDEX IF NOT EXISTS idx_created (created_at);

-- Create party_settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS party_settings (
    party_id INT PRIMARY KEY,
    allow_cross_zone BOOLEAN DEFAULT TRUE,
    share_experience BOOLEAN DEFAULT TRUE,
    share_quest_progress BOOLEAN DEFAULT TRUE,
    voice_chat_enabled BOOLEAN DEFAULT FALSE,
    description VARCHAR(200) DEFAULT NULL,
    tags VARCHAR(100) DEFAULT NULL,
    
    FOREIGN KEY (party_id) REFERENCES parties(party_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create party_activity_log table if it doesn't exist
CREATE TABLE IF NOT EXISTS party_activity_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    party_id INT NOT NULL,
    player_id INT DEFAULT NULL,
    action ENUM('created', 'joined', 'left', 'kicked', 'disbanded', 'leadership_changed', 'settings_changed') NOT NULL,
    details JSON DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_party (party_id),
    INDEX idx_player (player_id),
    INDEX idx_action (action),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create party_statistics table if it doesn't exist
CREATE TABLE IF NOT EXISTS party_statistics (
    party_id INT PRIMARY KEY,
    total_members_joined INT DEFAULT 0,
    total_monsters_killed INT DEFAULT 0,
    total_quests_completed INT DEFAULT 0,
    total_playtime_seconds BIGINT DEFAULT 0,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (party_id) REFERENCES parties(party_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create player_party_preferences table if it doesn't exist
CREATE TABLE IF NOT EXISTS player_party_preferences (
    player_id INT PRIMARY KEY,
    auto_decline_invites BOOLEAN DEFAULT FALSE,
    preferred_loot_mode ENUM('round_robin', 'free_for_all', 'master_loot', 'need_before_greed') DEFAULT 'round_robin',
    allow_party_finder BOOLEAN DEFAULT TRUE,
    preferred_party_size TINYINT DEFAULT 5,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'Migration to V2 complete!' AS status;
SELECT 'Checking tables...' AS status;
SHOW TABLES LIKE 'party%';
