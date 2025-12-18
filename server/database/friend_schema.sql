-- Friend System Schema
-- Run this to add friend system tables to your database

CREATE TABLE IF NOT EXISTS friends (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT NOT NULL,
    friend_id INT NOT NULL,
    status ENUM('pending', 'accepted') DEFAULT 'pending',
    requester_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES player_data(player_id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES player_data(player_id) ON DELETE CASCADE,
    UNIQUE KEY unique_friendship (player_id, friend_id),
    INDEX idx_player_status (player_id, status),
    INDEX idx_friend_status (friend_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Note: This creates a bidirectional friendship system
-- When a friend request is accepted, two rows are created (one for each direction)
