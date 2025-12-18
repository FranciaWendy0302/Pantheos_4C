-- MySQL Database Setup for MMORPG
-- Run this SQL to create the database and tables

CREATE DATABASE IF NOT EXISTS mmorpg_game;
USE mmorpg_game;

-- Players table
CREATE TABLE IF NOT EXISTS players (
    player_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(50) NOT NULL,
    level INT DEFAULT 1,
    xp INT DEFAULT 0,
    gold INT DEFAULT 100,
    hp INT DEFAULT 100,
    max_hp INT DEFAULT 100,
    last_map VARCHAR(255) DEFAULT '',
    last_position_x FLOAT DEFAULT 0,
    last_position_y FLOAT DEFAULT 0,
    inventory TEXT,
    quests TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Trades table
CREATE TABLE IF NOT EXISTS trades (
    trade_id INT AUTO_INCREMENT PRIMARY KEY,
    from_player_id INT NOT NULL,
    to_player_id INT NOT NULL,
    item_id VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    gold_amount INT DEFAULT 0,
    trade_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_player_id) REFERENCES players(player_id),
    FOREIGN KEY (to_player_id) REFERENCES players(player_id),
    INDEX idx_from_player (from_player_id),
    INDEX idx_to_player (to_player_id),
    INDEX idx_trade_date (trade_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Game logs table (optional - for monitoring)
CREATE TABLE IF NOT EXISTS game_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT,
    action VARCHAR(50),
    details TEXT,
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    INDEX idx_player_logs (player_id),
    INDEX idx_log_date (log_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create indexes for better performance
CREATE INDEX idx_player_level ON players(level);
CREATE INDEX idx_player_gold ON players(gold);

-- Show tables
SHOW TABLES;

SELECT 'Database setup complete!' AS status;
