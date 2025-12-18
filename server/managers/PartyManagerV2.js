const { pool: db } = require('../config/database');

/**
 * Enhanced Party Manager V2.0
 * Production-ready with caching, validation, and fault tolerance
 */
class PartyManagerV2 {
    constructor() {
        this.parties = new Map(); // party_id -> Party object
        this.playerParties = new Map(); // player_id -> party_id
        this.pendingInvites = new Map(); // invite_id -> invite data
        this.MAX_PARTY_SIZE = 5;
        this.INVITE_EXPIRY_MS = 10000; // 10 seconds
        
        // Rate limiting
        this.inviteRateLimits = new Map(); // player_id -> { count, resetTime }
        this.MAX_INVITES_PER_MINUTE = 10;
        
        // Performance metrics
        this.metrics = {
            partiesCreated: 0,
            invitesSent: 0,
            membersJoined: 0,
            errors: 0
        };
    }

    // ==================== VALIDATION ====================
    
    validatePlayerId(playerId) {
        if (!playerId || playerId <= 0) {
            return { valid: false, error: 'Invalid player ID' };
        }
        return { valid: true };
    }
    
    validatePartySize(currentSize) {
        if (currentSize >= this.MAX_PARTY_SIZE) {
            return { valid: false, error: `Party is full (${this.MAX_PARTY_SIZE}/${this.MAX_PARTY_SIZE})` };
        }
        return { valid: true };
    }
    
    checkInviteRateLimit(playerId) {
        const now = Date.now();
        const limit = this.inviteRateLimits.get(playerId);
        
        if (!limit || now > limit.resetTime) {
            this.inviteRateLimits.set(playerId, {
                count: 1,
                resetTime: now + 60000 // 1 minute
            });
            return { allowed: true };
        }
        
        if (limit.count >= this.MAX_INVITES_PER_MINUTE) {
            return { allowed: false, error: 'Too many invites. Please wait.' };
        }
        
        limit.count++;
        return { allowed: true };
    }

    // ==================== CORE PARTY OPERATIONS ====================
    
    async createParty(leaderId, options = {}) {
        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();
            
            // Validate
            const validation = this.validatePlayerId(leaderId);
            if (!validation.valid) {
                return { success: false, error: validation.error };
            }
            
            if (this.playerParties.has(leaderId)) {
                return { success: false, error: 'Already in a party' };
            }
            
            // Create party
            const [result] = await connection.query(
                'INSERT INTO parties (leader_id, party_name, is_public, max_members) VALUES (?, ?, ?, ?)',
                [leaderId, options.name || null, options.isPublic || false, options.maxMembers || this.MAX_PARTY_SIZE]
            );
            
            const partyId = result.insertId;
            
            // Clean up any stale party_members entries for this player
            await connection.query(
                'DELETE FROM party_members WHERE player_id = ?',
                [leaderId]
            );
            
            // Add leader as member
            await connection.query(
                'INSERT INTO party_members (party_id, player_id, role) VALUES (?, ?, ?)',
                [partyId, leaderId, 'leader']
            );
            
            // Create settings
            await connection.query(
                'INSERT INTO party_settings (party_id, description) VALUES (?, ?)',
                [partyId, options.description || null]
            );
            
            await connection.commit();
            
            // Load party data
            const party = await this.loadPartyData(partyId);
            this.parties.set(partyId, party);
            this.playerParties.set(leaderId, partyId);
            
            this.metrics.partiesCreated++;
            console.log(`[PartyV2] Created party ${partyId} by player ${leaderId}`);
            
            return { success: true, party_id: partyId, party };
        } catch (error) {
            await connection.rollback();
            this.metrics.errors++;
            console.error('[PartyV2] Error creating party:', error);
            return { success: false, error: error.message };
        } finally {
            connection.release();
        }
    }

    async invitePlayer(partyId, inviterId, inviteeId, gameServer, message = null) {
        try {
            // Rate limit check
            const rateCheck = this.checkInviteRateLimit(inviterId);
            if (!rateCheck.allowed) {
                return { success: false, error: rateCheck.error };
            }
            
            // Validate party exists
            const party = this.parties.get(partyId);
            if (!party) {
                return { success: false, error: 'Party not found' };
            }
            
            // Check inviter is in party
            if (!party.members.includes(inviterId)) {
                return { success: false, error: 'You are not in this party' };
            }
            
            // Check if invitee is already in same party
            const inviteePartyId = this.playerParties.get(inviteeId);
            if (inviteePartyId === partyId) {
                return { success: false, error: 'Player is already in your party' };
            }
            
            // Check if target is online
            const targetClient = gameServer.getClientByPlayerId(inviteeId);
            if (!targetClient || !targetClient.ws || targetClient.ws.readyState !== 1) {
                return { success: false, error: 'Player is offline' };
            }
            
            // Clean up ALL expired invites for this player (not just from this party)
            const [expiredResult] = await db.query(
                `UPDATE party_invites 
                 SET status = 'expired' 
                 WHERE invitee_id = ? AND status = 'pending' AND expires_at <= NOW()`,
                [inviteeId]
            );
            
            if (expiredResult.affectedRows > 0) {
                console.log(`[PartyV2] Cleaned up ${expiredResult.affectedRows} expired invites for player ${inviteeId}`);
            }
            
            // Check for existing pending invite (that hasn't expired)
            const [existing] = await db.query(
                `SELECT id, party_id, inviter_id, expires_at 
                 FROM party_invites 
                 WHERE invitee_id = ? AND status = 'pending' AND expires_at > NOW()`,
                [inviteeId]
            );
            
            if (existing.length > 0) {
                const existingInvite = existing[0];
                const timeLeft = Math.ceil((new Date(existingInvite.expires_at) - new Date()) / 1000);
                console.log(`[PartyV2] Player ${inviteeId} already has pending invite ${existingInvite.id} (expires in ${timeLeft}s)`);
                return { success: false, error: `Player already has a pending invite (expires in ${timeLeft}s)` };
            }
            
            // Check party size
            const sizeCheck = this.validatePartySize(party.members.length);
            if (!sizeCheck.valid) {
                return { success: false, error: sizeCheck.error };
            }
            
            // Create invite (expires in 10 seconds)
            const [result] = await db.query(
                'INSERT INTO party_invites (party_id, inviter_id, invitee_id, message, expires_at) VALUES (?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 10 SECOND))',
                [partyId, inviterId, inviteeId, message]
            );
            
            const inviteId = result.insertId;
            
            this.pendingInvites.set(inviteId, {
                invite_id: inviteId,
                party_id: partyId,
                inviter_id: inviterId,
                invitee_id: inviteeId,
                created_at: Date.now()
            });
            
            this.metrics.invitesSent++;
            console.log(`[PartyV2] Invite created: ${inviteId} (${inviterId} → ${inviteeId})`);
            
            return { success: true, invite_id: inviteId };
        } catch (error) {
            this.metrics.errors++;
            console.error('[PartyV2] Error inviting player:', error);
            return { success: false, error: error.message };
        }
    }

    async acceptInvite(inviteId, playerId) {
        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();
            
            // Get invite
            const [invites] = await connection.query(
                `SELECT pi.*, p.leader_id 
                 FROM party_invites pi
                 JOIN parties p ON pi.party_id = p.party_id
                 WHERE pi.id = ? AND pi.invitee_id = ? AND pi.status = 'pending' AND pi.expires_at > NOW()`,
                [inviteId, playerId]
            );
            
            if (invites.length === 0) {
                await connection.rollback();
                return { success: false, error: 'Invite not found or expired' };
            }
            
            const invite = invites[0];
            const targetPartyId = invite.party_id;
            const targetParty = this.parties.get(targetPartyId);
            
            if (!targetParty) {
                await connection.rollback();
                return { success: false, error: 'Party no longer exists' };
            }
            
            // Check party size
            const sizeCheck = this.validatePartySize(targetParty.members.length);
            if (!sizeCheck.valid) {
                await connection.rollback();
                return { success: false, error: sizeCheck.error };
            }
            
            // Check if player is already in a party
            const currentPartyId = this.playerParties.get(playerId);
            if (currentPartyId) {
                const currentParty = this.parties.get(currentPartyId);
                if (currentParty && currentParty.leader_id !== playerId) {
                    await connection.rollback();
                    return { success: false, error: 'You must leave your current party first' };
                }
                
                // Leader joining - merge parties
                if (currentParty && currentParty.leader_id === playerId) {
                    const mergeResult = await this.mergeParties(currentPartyId, targetPartyId, connection);
                    if (!mergeResult.success) {
                        await connection.rollback();
                        return mergeResult;
                    }
                    
                    await connection.query(
                        'UPDATE party_invites SET status = "accepted", responded_at = NOW() WHERE id = ?',
                        [inviteId]
                    );
                    
                    await connection.commit();
                    this.pendingInvites.delete(inviteId);
                    
                    return { 
                        success: true, 
                        party_id: targetPartyId, 
                        merged: true,
                        old_party_id: currentPartyId
                    };
                }
            }
            
            // Normal join
            // First, clean up any stale party_members entries for this player
            await connection.query(
                'DELETE FROM party_members WHERE player_id = ?',
                [playerId]
            );
            
            // Now insert the new membership
            await connection.query(
                'INSERT INTO party_members (party_id, player_id, role) VALUES (?, ?, ?)',
                [targetPartyId, playerId, 'member']
            );
            
            await connection.query(
                'UPDATE party_invites SET status = "accepted", responded_at = NOW() WHERE id = ?',
                [inviteId]
            );
            
            await connection.commit();
            
            // Update memory
            targetParty.members.push(playerId);
            this.playerParties.set(playerId, targetPartyId);
            this.pendingInvites.delete(inviteId);
            
            this.metrics.membersJoined++;
            console.log(`[PartyV2] Player ${playerId} joined party ${targetPartyId}`);
            
            return { success: true, party_id: targetPartyId };
        } catch (error) {
            await connection.rollback();
            this.metrics.errors++;
            console.error('[PartyV2] Error accepting invite:', error);
            return { success: false, error: error.message };
        } finally {
            connection.release();
        }
    }

    async mergeParties(sourcePartyId, targetPartyId, connection) {
        try {
            const sourceParty = this.parties.get(sourcePartyId);
            const targetParty = this.parties.get(targetPartyId);
            
            if (!sourceParty || !targetParty) {
                return { success: false, error: 'One or both parties not found' };
            }
            
            // Check merged size
            if (sourceParty.members.length + targetParty.members.length > this.MAX_PARTY_SIZE) {
                return { success: false, error: 'Merged party would exceed size limit' };
            }
            
            // Move all members
            for (const memberId of sourceParty.members) {
                await connection.query(
                    'UPDATE party_members SET party_id = ?, role = ? WHERE player_id = ?',
                    [targetPartyId, 'member', memberId]
                );
                
                targetParty.members.push(memberId);
                this.playerParties.set(memberId, targetPartyId);
            }
            
            // Delete source party
            await connection.query('DELETE FROM parties WHERE party_id = ?', [sourcePartyId]);
            this.parties.delete(sourcePartyId);
            
            console.log(`[PartyV2] Merged party ${sourcePartyId} → ${targetPartyId}`);
            return { success: true };
        } catch (error) {
            console.error('[PartyV2] Error merging parties:', error);
            return { success: false, error: error.message };
        }
    }
    
    async leaveParty(playerId) {
        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();
            
            const partyId = this.playerParties.get(playerId);
            if (!partyId) {
                await connection.rollback();
                return { success: false, error: 'Not in a party' };
            }
            
            const party = this.parties.get(partyId);
            if (!party) {
                await connection.rollback();
                return { success: false, error: 'Party not found' };
            }
            
            // Remove from database
            await connection.query(
                'DELETE FROM party_members WHERE party_id = ? AND player_id = ?',
                [partyId, playerId]
            );
            
            // Update memory
            party.members = party.members.filter(id => id !== playerId);
            this.playerParties.delete(playerId);
            
            console.log(`[PartyV2] After removing player ${playerId}, party ${partyId} has ${party.members.length} members`);
            console.log(`[PartyV2] Is leader leaving? ${playerId === party.leader_id}`);
            console.log(`[PartyV2] Should disband? ${playerId === party.leader_id || party.members.length <= 1}`);
            
            // If leader left, party has 0 members, or only 1 member remains, disband
            // A party needs at least 2 members to exist
            if (playerId === party.leader_id || party.members.length <= 1) {
                // Remove remaining members from party
                for (const memberId of party.members) {
                    this.playerParties.delete(memberId);
                }
                
                // Expire all pending invites for this party
                await connection.query(
                    `UPDATE party_invites 
                     SET status = 'expired' 
                     WHERE party_id = ? AND status = 'pending'`,
                    [partyId]
                );
                console.log(`[PartyV2] Expired pending invites for disbanded party ${partyId}`);
                
                await connection.query('DELETE FROM parties WHERE party_id = ?', [partyId]);
                this.parties.delete(partyId);
                await connection.commit();
                
                const reason = playerId === party.leader_id ? 'leader left' : 
                              party.members.length === 0 ? 'no members' : 
                              'only 1 member remaining';
                console.log(`[PartyV2] Party ${partyId} disbanded (${reason})`);
                return { success: true, disbanded: true, reason };
            }
            
            await connection.commit();
            console.log(`[PartyV2] Player ${playerId} left party ${partyId}`);
            
            return { success: true, party_id: partyId };
        } catch (error) {
            await connection.rollback();
            this.metrics.errors++;
            console.error('[PartyV2] Error leaving party:', error);
            return { success: false, error: error.message };
        } finally {
            connection.release();
        }
    }

    // ==================== UTILITY FUNCTIONS ====================
    
    async loadPartyData(partyId) {
        try {
            const [parties] = await db.query('SELECT * FROM parties WHERE party_id = ?', [partyId]);
            if (parties.length === 0) return null;
            
            const [members] = await db.query(
                'SELECT player_id, role FROM party_members WHERE party_id = ? ORDER BY role DESC, joined_at ASC',
                [partyId]
            );
            
            const party = {
                id: partyId,
                leader_id: parties[0].leader_id,
                members: members.map(m => m.player_id),
                member_data: new Map(),
                loot_mode: parties[0].loot_mode,
                created_at: parties[0].created_at
            };
            
            return party;
        } catch (error) {
            console.error('[PartyV2] Error loading party data:', error);
            return null;
        }
    }
    
    async loadAllParties() {
        try {
            const [parties] = await db.query('SELECT party_id FROM parties');
            
            for (const party of parties) {
                const partyData = await this.loadPartyData(party.party_id);
                if (partyData) {
                    this.parties.set(party.party_id, partyData);
                    partyData.members.forEach(memberId => {
                        this.playerParties.set(memberId, party.party_id);
                    });
                }
            }
            
            console.log(`[PartyV2] Loaded ${parties.length} parties from database`);
        } catch (error) {
            console.error('[PartyV2] Error loading parties:', error);
        }
    }
    
    async getPartyMembers(partyId) {
        try {
            const [members] = await db.query(
                `SELECT 
                    a.player_id as id, 
                    COALESCE(pd.nickname, a.username) as username,
                    pd.level,
                    pd.hp,
                    pd.max_hp,
                    pm.role
                FROM party_members pm
                JOIN accounts a ON pm.player_id = a.player_id
                LEFT JOIN player_data pd ON a.player_id = pd.player_id
                WHERE pm.party_id = ?
                ORDER BY pm.role DESC, pm.joined_at ASC`,
                [partyId]
            );
            
            console.log(`[PartyV2] getPartyMembers(${partyId}) returned:`, members);
            return { success: true, members };
        } catch (error) {
            console.error('[PartyV2] Error getting party members:', error);
            return { success: false, error: error.message };
        }
    }
    
    getPlayerPartyId(playerId) {
        return this.playerParties.get(playerId) || null;
    }
    
    getParty(partyId) {
        return this.parties.get(partyId) || null;
    }
    
    async cleanupExpiredInvites() {
        try {
            await db.query(
                'UPDATE party_invites SET status = "expired" WHERE status = "pending" AND expires_at < NOW()'
            );
            
            const now = Date.now();
            for (const [inviteId, invite] of this.pendingInvites.entries()) {
                if (now - invite.created_at > this.INVITE_EXPIRY_MS) {
                    this.pendingInvites.delete(inviteId);
                }
            }
        } catch (error) {
            console.error('[PartyV2] Error cleaning up invites:', error);
        }
    }
    
    broadcastToParty(partyId, message, gameServer) {
        const party = this.parties.get(partyId);
        if (!party) return;
        
        party.members.forEach(memberId => {
            const client = gameServer.getClientByPlayerId(memberId);
            if (client && client.ws && client.ws.readyState === 1) {
                try {
                    client.ws.send(JSON.stringify(message));
                } catch (error) {
                    console.error(`[PartyV2] Error broadcasting to player ${memberId}:`, error.message);
                }
            }
        });
    }
    
    getMetrics() {
        return {
            ...this.metrics,
            activeParties: this.parties.size,
            playersInParties: this.playerParties.size,
            pendingInvites: this.pendingInvites.size
        };
    }
}

module.exports = new PartyManagerV2();
