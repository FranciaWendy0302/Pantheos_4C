// Friend System Manager
// Handles friend requests, friend list, online status

class FriendManager {
    constructor(db, clients) {
        this.db = db;
        this.clients = clients; // WebSocket clients map (playerId -> WebSocket)
        this.pendingRequests = new Map(); // playerId -> Set of request objects
    }

    // Send friend request
    async sendFriendRequest(requesterId, targetId) {
        try {
            // Validate players exist
            const [requester] = await this.db.query(
                'SELECT player_id, nickname FROM player_data WHERE player_id = ?',
                [requesterId]
            );
            const [target] = await this.db.query(
                'SELECT player_id, nickname FROM player_data WHERE player_id = ?',
                [targetId]
            );

            if (!requester.length || !target.length) {
                return { success: false, error: 'Player not found' };
            }

            // Check if already friends
            const [existing] = await this.db.query(
                'SELECT * FROM friends WHERE player_id = ? AND friend_id = ? AND status = "accepted"',
                [requesterId, targetId]
            );

            if (existing.length > 0) {
                return { success: false, error: 'Already friends' };
            }

            // Check if pending request exists
            const [pending] = await this.db.query(
                'SELECT * FROM friends WHERE ((player_id = ? AND friend_id = ?) OR (player_id = ? AND friend_id = ?)) AND status = "pending"',
                [requesterId, targetId, targetId, requesterId]
            );

            if (pending.length > 0) {
                return { success: false, error: 'Friend request already pending' };
            }

            // Create pending request in database
            await this.db.query(
                'INSERT INTO friends (player_id, friend_id, status) VALUES (?, ?, "pending")',
                [requesterId, targetId]
            );

            // Store in memory for expiry
            const requestData = {
                requesterId,
                requesterName: requester[0].nickname,
                targetId,
                timestamp: Date.now()
            };

            if (!this.pendingRequests.has(targetId)) {
                this.pendingRequests.set(targetId, new Set());
            }
            this.pendingRequests.get(targetId).add(requestData);

            // NO AUTO-EXPIRATION - requests persist until accepted/declined

            // Send to target player via WebSocket
            const targetWs = this.clients.get(targetId);
            if (targetWs && targetWs.readyState === 1) { // 1 = OPEN
                targetWs.send(JSON.stringify({
                    type: 'friend_request',
                    data: {
                        requesterId,
                        requesterName: requester[0].nickname
                    }
                }));
            }

            return { success: true };
        } catch (error) {
            console.error('Error sending friend request:', error);
            return { success: false, error: 'Database error' };
        }
    }

    // Accept friend request
    async acceptFriendRequest(playerId, requesterId) {
        try {
            // Check if request exists
            const [request] = await this.db.query(
                'SELECT * FROM friends WHERE player_id = ? AND friend_id = ? AND status = "pending"',
                [requesterId, playerId]
            );

            if (request.length === 0) {
                return { success: false, error: 'Friend request not found or expired' };
            }

            // Update status to accepted
            await this.db.query(
                'UPDATE friends SET status = "accepted" WHERE player_id = ? AND friend_id = ?',
                [requesterId, playerId]
            );

            // Create reverse friendship
            await this.db.query(
                'INSERT INTO friends (player_id, friend_id, status) VALUES (?, ?, "accepted")',
                [playerId, requesterId]
            );

            // Remove from pending requests
            if (this.pendingRequests.has(playerId)) {
                const requests = this.pendingRequests.get(playerId);
                for (const req of requests) {
                    if (req.requesterId === requesterId) {
                        requests.delete(req);
                        break;
                    }
                }
            }

            // Get player names
            const [players] = await this.db.query(
                'SELECT player_id, nickname FROM player_data WHERE player_id IN (?, ?)',
                [playerId, requesterId]
            );

            const playerName = players.find(p => p.player_id === playerId)?.nickname;
            const requesterName = players.find(p => p.player_id === requesterId)?.nickname;

            // Notify both players via WebSocket
            const playerWs = this.clients.get(playerId);
            if (playerWs && playerWs.readyState === 1) {
                playerWs.send(JSON.stringify({
                    type: 'friend_accepted',
                    data: {
                        friendId: requesterId,
                        friendName: requesterName
                    }
                }));
            }

            const requesterWs = this.clients.get(requesterId);
            if (requesterWs && requesterWs.readyState === 1) {
                requesterWs.send(JSON.stringify({
                    type: 'friend_accepted',
                    data: {
                        friendId: playerId,
                        friendName: playerName
                    }
                }));
            }

            return { success: true };
        } catch (error) {
            console.error('Error accepting friend request:', error);
            return { success: false, error: 'Database error' };
        }
    }

    // Decline friend request
    async declineFriendRequest(playerId, requesterId) {
        try {
            // Delete pending request
            await this.db.query(
                'DELETE FROM friends WHERE player_id = ? AND friend_id = ? AND status = "pending"',
                [requesterId, playerId]
            );

            // Remove from pending requests
            if (this.pendingRequests.has(playerId)) {
                const requests = this.pendingRequests.get(playerId);
                for (const req of requests) {
                    if (req.requesterId === requesterId) {
                        requests.delete(req);
                        break;
                    }
                }
            }

            return { success: true };
        } catch (error) {
            console.error('Error declining friend request:', error);
            return { success: false, error: 'Database error' };
        }
    }

    // Remove friend
    async removeFriend(playerId, friendId) {
        try {
            // Delete both directions of friendship
            await this.db.query(
                'DELETE FROM friends WHERE (player_id = ? AND friend_id = ?) OR (player_id = ? AND friend_id = ?)',
                [playerId, friendId, friendId, playerId]
            );

            // Notify both players via WebSocket
            const playerWs = this.clients.get(playerId);
            if (playerWs && playerWs.readyState === 1) {
                playerWs.send(JSON.stringify({
                    type: 'friend_removed',
                    data: { friendId }
                }));
            }

            const friendWs = this.clients.get(friendId);
            if (friendWs && friendWs.readyState === 1) {
                friendWs.send(JSON.stringify({
                    type: 'friend_removed',
                    data: { friendId: playerId }
                }));
            }

            return { success: true };
        } catch (error) {
            console.error('Error removing friend:', error);
            return { success: false, error: 'Database error' };
        }
    }

    // Get friend list
    async getFriendList(playerId) {
        try {
            const [friends] = await this.db.query(`
                SELECT 
                    p.player_id AS id,
                    p.nickname,
                    p.level,
                    p.character_class AS class,
                    f.status
                FROM friends f
                JOIN player_data p ON f.friend_id = p.player_id
                WHERE f.player_id = ? AND f.status = "accepted"
                ORDER BY p.nickname
            `, [playerId]);

            // Add online status (check if player is in active sessions)
            const friendList = friends.map(friend => ({
                id: friend.id,
                nickname: friend.nickname,
                level: friend.level,
                class: friend.class,
                online: this.isPlayerOnline(friend.id)
            }));

            return { success: true, friends: friendList };
        } catch (error) {
            console.error('Error getting friend list:', error);
            return { success: false, error: 'Database error', friends: [] };
        }
    }

    // Get pending friend requests
    async getPendingRequests(playerId) {
        try {
            const [requests] = await this.db.query(`
                SELECT 
                    p.player_id AS id,
                    p.nickname,
                    f.created_at
                FROM friends f
                JOIN player_data p ON f.player_id = p.player_id
                WHERE f.friend_id = ? AND f.status = "pending"
            `, [playerId]);

            return { success: true, requests };
        } catch (error) {
            console.error('Error getting pending requests:', error);
            return { success: false, error: 'Database error', requests: [] };
        }
    }

    // Check if player is online
    isPlayerOnline(playerId) {
        // Check if player has an active WebSocket connection
        const ws = this.clients.get(playerId);
        return ws && ws.readyState === 1; // 1 = OPEN
    }

    // Expire friend request
    async expireFriendRequest(requesterId, targetId) {
        try {
            // Check if still pending
            const [request] = await this.db.query(
                'SELECT * FROM friends WHERE player_id = ? AND friend_id = ? AND status = "pending"',
                [requesterId, targetId]
            );

            if (request.length > 0) {
                // Delete expired request
                await this.db.query(
                    'DELETE FROM friends WHERE player_id = ? AND friend_id = ? AND status = "pending"',
                    [requesterId, targetId]
                );

                // Remove from memory
                if (this.pendingRequests.has(targetId)) {
                    const requests = this.pendingRequests.get(targetId);
                    for (const req of requests) {
                        if (req.requesterId === requesterId) {
                            requests.delete(req);
                            break;
                        }
                    }
                }

                // Notify target that request expired via WebSocket
                const targetWs = this.clients.get(targetId);
                if (targetWs && targetWs.readyState === 1) {
                    targetWs.send(JSON.stringify({
                        type: 'friend_request_expired',
                        data: { requesterId }
                    }));
                }
            }
        } catch (error) {
            console.error('Error expiring friend request:', error);
        }
    }

    // Notify friends when player comes online
    async notifyFriendsOnline(playerId) {
        try {
            const [friends] = await this.db.query(
                'SELECT friend_id FROM friends WHERE player_id = ? AND status = "accepted"',
                [playerId]
            );

            const [player] = await this.db.query(
                'SELECT nickname FROM player_data WHERE player_id = ?',
                [playerId]
            );

            if (player.length > 0) {
                friends.forEach(friend => {
                    const friendWs = this.clients.get(friend.friend_id);
                    if (friendWs && friendWs.readyState === 1) {
                        friendWs.send(JSON.stringify({
                            type: 'friend_online',
                            data: {
                                friendId: playerId,
                                friendName: player[0].nickname
                            }
                        }));
                    }
                });
            }
        } catch (error) {
            console.error('Error notifying friends online:', error);
        }
    }

    // Notify friends when player goes offline
    async notifyFriendsOffline(playerId) {
        try {
            const [friends] = await this.db.query(
                'SELECT friend_id FROM friends WHERE player_id = ? AND status = "accepted"',
                [playerId]
            );

            friends.forEach(friend => {
                const friendWs = this.clients.get(friend.friend_id);
                if (friendWs && friendWs.readyState === 1) {
                    friendWs.send(JSON.stringify({
                        type: 'friend_offline',
                        data: {
                            friendId: playerId
                        }
                    }));
                }
            });
        } catch (error) {
            console.error('Error notifying friends offline:', error);
        }
    }
}

module.exports = FriendManager;
