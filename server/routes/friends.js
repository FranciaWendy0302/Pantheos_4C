const express = require('express');
const router = express.Router();

module.exports = (db, friendManager) => {
    // Get friend list
    router.get('/list/:playerId', async (req, res) => {
        try {
            const playerId = parseInt(req.params.playerId);
            const result = await friendManager.getFriendList(playerId);
            res.json(result);
        } catch (error) {
            console.error('Error getting friend list:', error);
            res.status(500).json({ success: false, error: 'Server error' });
        }
    });

    // Get pending friend requests
    router.get('/pending/:playerId', async (req, res) => {
        try {
            const playerId = parseInt(req.params.playerId);
            const result = await friendManager.getPendingRequests(playerId);
            res.json(result);
        } catch (error) {
            console.error('Error getting pending requests:', error);
            res.status(500).json({ success: false, error: 'Server error' });
        }
    });

    // Send friend request
    router.post('/request', async (req, res) => {
        try {
            const { requesterId, targetId } = req.body;
            const result = await friendManager.sendFriendRequest(requesterId, targetId);
            res.json(result);
        } catch (error) {
            console.error('Error sending friend request:', error);
            res.status(500).json({ success: false, error: 'Server error' });
        }
    });

    // Accept friend request
    router.post('/accept', async (req, res) => {
        try {
            const { playerId, requesterId } = req.body;
            const result = await friendManager.acceptFriendRequest(playerId, requesterId);
            res.json(result);
        } catch (error) {
            console.error('Error accepting friend request:', error);
            res.status(500).json({ success: false, error: 'Server error' });
        }
    });

    // Decline friend request
    router.post('/decline', async (req, res) => {
        try {
            const { playerId, requesterId } = req.body;
            const result = await friendManager.declineFriendRequest(playerId, requesterId);
            res.json(result);
        } catch (error) {
            console.error('Error declining friend request:', error);
            res.status(500).json({ success: false, error: 'Server error' });
        }
    });

    // Remove friend
    router.post('/remove', async (req, res) => {
        try {
            const { playerId, friendId } = req.body;
            const result = await friendManager.removeFriend(playerId, friendId);
            res.json(result);
        } catch (error) {
            console.error('Error removing friend:', error);
            res.status(500).json({ success: false, error: 'Server error' });
        }
    });

    // Get player info for inspection
    router.get('/inspect/:playerId', async (req, res) => {
        try {
            const playerId = parseInt(req.params.playerId);
            
            const [player] = await db.query(`
                SELECT 
                    player_id AS id,
                    nickname,
                    level,
                    character_class AS class,
                    hp,
                    max_hp,
                    mp AS mana,
                    max_mp AS max_mana
                FROM player_data
                WHERE player_id = ?
            `, [playerId]);

            if (player.length === 0) {
                return res.json({ success: false, error: 'Player not found' });
            }

            res.json({ success: true, player: player[0] });
        } catch (error) {
            console.error('Error inspecting player:', error);
            res.status(500).json({ success: false, error: 'Server error' });
        }
    });

    return router;
};
