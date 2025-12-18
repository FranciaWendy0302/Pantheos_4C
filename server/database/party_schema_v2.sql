-- Enhanced Party System Database Schema v2.0
-- Production-ready with indexing, constraints, and audit trails

USE mmorpg_game;

-- Drop existing tables if upgrading (CAUTION: This will delete data!)
-- Uncomment only if you want a fresh start
-- DROP TABLE IF EXISTS party_invites;
-- DROP TABLE IF EXISTS party_members;
-- DROP TABLE IF EXISTS party_settings;
-- DROP TABLE IF EXISTS parties;

-- ==================== PARTIES TABLE ====================
CREATE TABLE IF NOT EXISTS parties (
    party_id INT PRIMARY KEY AUTO_INCREMENT,
    leader_id INT NOT NULL,
    party_name VARCHAR(50) DEFAULT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    max_members TINYINT DEFAULT 5,
    min_level TINYINT DEFAULT 1,
    max_level TINYINT DEFAULT 100,
    loot_mode ENUM('round_robin', 'free_for_all', 'master_loot', 'need_before_greed') DEFAULT 'round_robin',
    auto_accept_invites BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_leader (leader_id),
    INDEX idx_public (is_public),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== PARTY MEMBERS TABLE ====================
CREATE TABLE IF NOT EXISTS party_members (
    id INT PRIMARY KEY AUTO_INCREMENT,
    party_id INT NOT NULL,
    player_id INT NOT NULL,
    role ENUM('leader', 'member', 'assistant') DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_player (player_id),
    INDEX idx_party (party_id),
    INDEX idx_player (player_id),
    INDEX idx_role (role),
    
    FOREIGN KEY (party_id) REFERENCES parties(party_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== PARTY INVITES TABLE ====================
CREATE TABLE IF NOT EXISTS party_invites (
    id INT PRIMARY KEY AUTO_INCREMENT,
    party_id INT NOT NULL,
    inviter_id INT NOT NULL,
    invitee_id INT NOT NULL,
    message VARCHAR(200) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    status ENUM('pending', 'accepted', 'declined', 'expired', 'cancelled') DEFAULT 'pending',
    responded_at TIMESTAMP NULL DEFAULT NULL,
    
    INDEX idx_party (party_id),
    INDEX idx_invitee (invitee_id),
    INDEX idx_status (status),
    INDEX idx_expires (expires_at),
    INDEX idx_created (created_at),
    
    FOREIGN KEY (party_id) REFERENCES parties(party_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== PARTY SETTINGS TABLE ====================
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

-- ==================== PARTY ACTIVITY LOG ====================
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

-- ==================== PARTY STATISTICS ====================
CREATE TABLE IF NOT EXISTS party_statistics (
    party_id INT PRIMARY KEY,
    total_members_joined INT DEFAULT 0,
    total_monsters_killed INT DEFAULT 0,
    total_quests_completed INT DEFAULT 0,
    total_playtime_seconds BIGINT DEFAULT 0,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (party_id) REFERENCES parties(party_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== PLAYER PARTY PREFERENCES ====================
CREATE TABLE IF NOT EXISTS player_party_preferences (
    player_id INT PRIMARY KEY,
    auto_decline_invites BOOLEAN DEFAULT FALSE,
    preferred_loot_mode ENUM('round_robin', 'free_for_all', 'master_loot', 'need_before_greed') DEFAULT 'round_robin',
    allow_party_finder BOOLEAN DEFAULT TRUE,
    preferred_party_size TINYINT DEFAULT 5,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== TRIGGERS ====================

-- Auto-update party statistics when member joins
DELIMITER //
CREATE TRIGGER IF NOT EXISTS after_party_member_insert
AFTER INSERT ON party_members
FOR EACH ROW
BEGIN
    INSERT INTO party_statistics (party_id, total_members_joined)
    VALUES (NEW.party_id, 1)
    ON DUPLICATE KEY UPDATE total_members_joined = total_members_joined + 1;
END//
DELIMITER ;

-- Log party activity
DELIMITER //
CREATE TRIGGER IF NOT EXISTS after_party_member_insert_log
AFTER INSERT ON party_members
FOR EACH ROW
BEGIN
    INSERT INTO party_activity_log (party_id, player_id, action)
    VALUES (NEW.party_id, NEW.player_id, 'joined');
END//
DELIMITER ;

-- ==================== VIEWS ====================

-- Active parties view (for party finder)
CREATE OR REPLACE VIEW active_parties AS
SELECT 
    p.party_id,
    p.party_name,
    p.leader_id,
    p.is_public,
    p.max_members,
    p.min_level,
    p.max_level,
    p.loot_mode,
    COUNT(pm.player_id) as current_members,
    ps.description,
    ps.tags,
    p.created_at
FROM parties p
LEFT JOIN party_members pm ON p.party_id = pm.party_id
LEFT JOIN party_settings ps ON p.party_id = ps.party_id
WHERE p.is_public = TRUE
GROUP BY p.party_id
HAVING current_members < p.max_members
ORDER BY p.created_at DESC;

-- ==================== STORED PROCEDURES ====================

-- Clean up expired invites
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS cleanup_expired_invites()
BEGIN
    UPDATE party_invites 
    SET status = 'expired' 
    WHERE status = 'pending' 
    AND expires_at < NOW();
    
    SELECT ROW_COUNT() as expired_count;
END//
DELIMITER ;

-- Get party full details
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS get_party_details(IN p_party_id INT)
BEGIN
    -- Party info
    SELECT * FROM parties WHERE party_id = p_party_id;
    
    -- Members
    SELECT 
        pm.player_id,
        pm.role,
        a.username,
        pd.level,
        pd.hp,
        pd.max_hp,
        pm.joined_at
    FROM party_members pm
    JOIN accounts a ON pm.player_id = a.player_id
    LEFT JOIN player_data pd ON pm.player_id = pd.player_id
    WHERE pm.party_id = p_party_id
    ORDER BY pm.role DESC, pm.joined_at ASC;
    
    -- Settings
    SELECT * FROM party_settings WHERE party_id = p_party_id;
    
    -- Statistics
    SELECT * FROM party_statistics WHERE party_id = p_party_id;
END//
DELIMITER ;

-- ==================== INDEXES FOR PERFORMANCE ====================

-- Add composite indexes for common queries
ALTER TABLE party_invites 
ADD INDEX idx_invitee_status (invitee_id, status, expires_at);

ALTER TABLE party_members 
ADD INDEX idx_party_player (party_id, player_id);

-- ==================== DATA MIGRATION ====================

-- Migrate existing parties (if upgrading from v1)
INSERT IGNORE INTO party_settings (party_id, allow_cross_zone, share_experience)
SELECT party_id, TRUE, TRUE FROM parties;

INSERT IGNORE INTO party_statistics (party_id, total_members_joined)
SELECT party_id, COUNT(*) FROM party_members GROUP BY party_id;

-- ==================== VERIFICATION ====================

SELECT 'Party system v2.0 schema created successfully!' AS status;

SELECT 
    'parties' as table_name, 
    COUNT(*) as row_count 
FROM parties
UNION ALL
SELECT 'party_members', COUNT(*) FROM party_members
UNION ALL
SELECT 'party_invites', COUNT(*) FROM party_invites
UNION ALL
SELECT 'party_settings', COUNT(*) FROM party_settings
UNION ALL
SELECT 'party_statistics', COUNT(*) FROM party_statistics;

SHOW TABLES LIKE 'party%';
