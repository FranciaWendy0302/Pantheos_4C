// WebSocket server for real-time multiplayer
const WebSocket = require('ws');
const MonsterManager = require('../managers/MonsterManager');
const PartyManager = require('../managers/PartyManagerV2');
const FriendManager = require('../managers/FriendManager');

class GameServer {
    constructor(port, db) {
        this.wss = new WebSocket.Server({ port });
        this.clients = new Map(); // playerId -> WebSocket
        this.players = new Map(); // playerId -> player data
        this.monsterManager = new MonsterManager();
        this.partyManager = PartyManager;
        this.friendManager = new FriendManager(db, this.clients);
        
        this.setupServer();
        this.initializeMonsters();
        this.startPositionBroadcast();
        this.startPartyCleanup();
        console.log(`✓ WebSocket server running on port ${port}`);
    }

    // Initialize default monster spawns
    initializeMonsters() {
        // Set respawn callback to broadcast to all clients
        this.monsterManager.setRespawnCallback((monster) => {
            this.broadcastMonsterRespawn(monster);
        });

        // No default spawns - monsters should be spawned per-map by clients
        // Safezone is a safe area with no monsters
        // Other maps will have their own spawn points defined in the map files
        console.log(`✓ Monster system initialized (no default spawns)`);
    }

    setupServer() {
        this.wss.on('connection', (ws) => {
            console.log('New client connected');
            
            ws.on('message', (data) => {
                this.handleMessage(ws, data);
            });

            ws.on('close', () => {
                this.handleDisconnect(ws);
            });

            ws.on('error', (error) => {
                console.error('WebSocket error:', error);
            });
        });
    }

    handleMessage(ws, data) {
        try {
            const message = JSON.parse(data);
            
            // Log all non-movement messages
            if (message.type !== 'player_move' && message.type !== 'move') {
                console.log('[WS] Received message:', message.type, 'from player', ws.playerId);
            }
            
            switch (message.type) {
                case 'join':
                    this.handleJoin(ws, message);
                    break;
                case 'move':
                case 'player_move':  // Support both formats
                    this.handleMove(ws, message);
                    break;
                case 'player_hp_update':
                    this.handleHPUpdate(ws, message);
                    break;
                case 'chat':
                    this.handleChat(ws, message);
                    break;
                case 'attack':
                    this.handleAttack(ws, message);
                    break;
                case 'monster_damage':
                    this.handleMonsterDamage(ws, message);
                    break;
                case 'request_monsters':
                    this.handleRequestMonsters(ws, message);
                    break;
                // Party system messages
                case 'party_create':
                    this.handlePartyCreate(ws, message);
                    break;
                case 'party_invite':
                    this.handlePartyInvite(ws, message);
                    break;
                case 'party_accept':
                    this.handlePartyAccept(ws, message);
                    break;
                case 'party_decline':
                    this.handlePartyDecline(ws, message);
                    break;
                case 'party_leave':
                    this.handlePartyLeave(ws, message);
                    break;
                case 'party_kick':
                    this.handlePartyKick(ws, message);
                    break;
                case 'party_transfer_leadership':
                    this.handlePartyTransferLeadership(ws, message);
                    break;
                case 'party_hp_update':
                    this.handlePartyHPUpdate(ws, message);
                    break;
                // Duel system messages
                case 'duel_request':
                    this.handleDuelRequest(ws, message);
                    break;
                case 'duel_accept':
                    this.handleDuelAccept(ws, message);
                    break;
                case 'duel_decline':
                    this.handleDuelDecline(ws, message);
                    break;
                case 'duel_end':
                    this.handleDuelEnd(ws, message);
                    break;
                case 'player_damage':
                    this.handlePlayerDamage(ws, message);
                    break;
                default:
                    console.log('Unknown message type:', message.type);
            }
        } catch (error) {
            console.error('Error handling message:', error);
        }
    }

    async handleJoin(ws, message) {
        const { player_id, nickname, character_class, hp, max_hp, mana, max_mana } = message.data;
        
        // Store client
        this.clients.set(player_id, ws);
        ws.playerId = player_id;
        
        // Store player data (use provided stats or defaults)
        this.players.set(player_id, {
            player_id,
            nickname,
            character_class,
            x: 0,
            y: 0,
            hp: hp || 100,
            max_hp: max_hp || 100,
            mana: mana || 100,
            max_mana: max_mana || 100
        });

        // Send existing players to new player
        const existingPlayers = Array.from(this.players.values())
            .filter(p => p.player_id !== player_id);
        
        this.send(ws, {
            type: 'players',
            data: existingPlayers
        });

        // Send monsters to new player (shared + their quest monsters)
        const monsters = this.monsterManager.getMonsters(player_id);
        this.send(ws, {
            type: 'monsters',
            data: monsters
        });

        // Broadcast new player to others
        this.broadcast({
            type: 'player_joined',
            data: this.players.get(player_id)
        }, player_id);

        // Notify friends that player came online
        if (this.friendManager) {
            await this.friendManager.notifyFriendsOnline(player_id);
        }

        console.log(`Player ${nickname} (${player_id}) joined - sent ${monsters.length} monsters`);
    }

    handleHPUpdate(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const player = this.players.get(playerId);
        if (!player) return;

        // Update HP
        const hp = message.data?.hp ?? message.hp;
        const max_hp = message.data?.max_hp ?? message.max_hp;
        
        if (hp !== undefined) player.hp = hp;
        if (max_hp !== undefined) player.max_hp = max_hp;

        // Broadcast HP update to others immediately
        this.broadcast({
            type: 'player_hp_update',
            data: {
                player_id: playerId,
                hp: player.hp,
                max_hp: player.max_hp
            }
        }, playerId);
    }

    handleMove(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const player = this.players.get(playerId);
        if (!player) return;

        // Update position (support both data formats)
        const x = message.data?.x ?? message.x;
        const y = message.data?.y ?? message.y;
        const sprite_data = message.data?.sprite_data ?? message.sprite_data;
        const hp = message.data?.hp ?? message.hp;
        const max_hp = message.data?.max_hp ?? message.max_hp;
        const mana = message.data?.mana ?? message.mana;
        const max_mana = message.data?.max_mana ?? message.max_mana;
        
        player.x = x;
        player.y = y;
        
        // Update HP if provided
        if (hp !== undefined) player.hp = hp;
        if (max_hp !== undefined) player.max_hp = max_hp;
        // Update Mana if provided
        if (mana !== undefined) player.mana = mana;
        if (max_mana !== undefined) player.max_mana = max_mana;

        // Broadcast to others (include HP/Mana for real-time updates)
        this.broadcast({
            type: 'player_moved',
            data: {
                player_id: playerId,
                x: player.x,
                y: player.y,
                sprite_data: sprite_data,
                hp: player.hp || 100,
                max_hp: player.max_hp || 100,
                mana: player.mana || 100,
                max_mana: player.max_mana || 100
            }
        }, playerId);
    }

    handleChat(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const player = this.players.get(playerId);
        if (!player) return;

        const { channel, message: chatMessage, target_player_id } = message.data;
        
        // Validate message
        if (!chatMessage || chatMessage.trim().length === 0) {
            return;
        }
        
        // Sanitize message (basic XSS prevention)
        const sanitizedMessage = chatMessage.substring(0, 500).trim();
        
        const timestamp = new Date().toISOString();
        
        switch (channel) {
            case 'global':
                // Broadcast to all players
                this.broadcast({
                    type: 'chat_message',
                    data: {
                        channel: 'global',
                        player_id: playerId,
                        nickname: player.nickname,
                        message: sanitizedMessage,
                        timestamp: timestamp
                    }
                });
                console.log(`[Chat] Global message from ${player.nickname}: ${sanitizedMessage}`);
                break;
                
            case 'party':
                // Send to party members only
                const partyId = this.partyManager.getPlayerPartyId(playerId);
                if (!partyId) {
                    this.send(ws, {
                        type: 'chat_error',
                        data: { error: 'You are not in a party' }
                    });
                    return;
                }
                
                this.partyManager.broadcastToParty(partyId, {
                    type: 'chat_message',
                    data: {
                        channel: 'party',
                        player_id: playerId,
                        nickname: player.nickname,
                        message: sanitizedMessage,
                        timestamp: timestamp
                    }
                }, this);
                console.log(`[Chat] Party message from ${player.nickname}: ${sanitizedMessage}`);
                break;
                
            case 'whisper':
                // Send to specific player only
                if (!target_player_id) {
                    this.send(ws, {
                        type: 'chat_error',
                        data: { error: 'No target player specified' }
                    });
                    return;
                }
                
                const targetClient = this.getClientByPlayerId(target_player_id);
                if (!targetClient || !targetClient.ws) {
                    this.send(ws, {
                        type: 'chat_error',
                        data: { error: 'Player not found or offline' }
                    });
                    return;
                }
                
                // Send to target
                this.send(targetClient.ws, {
                    type: 'chat_message',
                    data: {
                        channel: 'whisper',
                        player_id: playerId,
                        nickname: player.nickname,
                        message: sanitizedMessage,
                        timestamp: timestamp,
                        is_incoming: true
                    }
                });
                
                // Send confirmation to sender
                this.send(ws, {
                    type: 'chat_message',
                    data: {
                        channel: 'whisper',
                        player_id: target_player_id,
                        nickname: this.players.get(target_player_id)?.nickname || 'Unknown',
                        message: sanitizedMessage,
                        timestamp: timestamp,
                        is_outgoing: true
                    }
                });
                
                console.log(`[Chat] Whisper from ${player.nickname} to ${target_player_id}: ${sanitizedMessage}`);
                break;
                
            default:
                console.log(`[Chat] Unknown channel: ${channel}`);
        }
    }

    handleAttack(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const { attack_type, direction, position } = message.data;

        // Broadcast attack to all other players
        this.broadcast({
            type: 'player_attack',
            data: {
                player_id: playerId,
                attack_type: attack_type || 'basic',
                direction: direction,
                position: position
            }
        }, playerId);

        console.log(`Player ${playerId} attacked: ${attack_type} at (${position.x}, ${position.y})`);
    }

    async handleDisconnect(ws) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const player = this.players.get(playerId);
        if (player) {
            console.log(`Player ${player.nickname} (${playerId}) disconnected`);
        }

        // Clear pending party invites
        await this.clearPendingInvites(playerId);
        
        // Auto-leave party on disconnect
        const partyId = this.partyManager.getPlayerPartyId(playerId);
        if (partyId) {
            console.log(`[Party] Player ${playerId} disconnected, auto-leaving party ${partyId}`);
            
            // Get party members BEFORE leaving (to notify them if disbanded)
            const party = this.partyManager.getParty(partyId);
            const remainingMemberIds = party ? party.members.filter(id => id !== playerId) : [];
            
            const result = await this.partyManager.leaveParty(playerId);
            
            if (result.success) {
                if (result.disbanded) {
                    // Party was disbanded - notify remaining members
                    for (const memberId of remainingMemberIds) {
                        const memberClient = this.getClientByPlayerId(memberId);
                        if (memberClient && memberClient.ws) {
                            this.send(memberClient.ws, {
                                type: 'party_disbanded',
                                data: { 
                                    party_id: partyId,
                                    reason: 'Member disconnected'
                                }
                            });
                        }
                    }
                    console.log(`[Party] Party ${partyId} disbanded (member disconnected)`);
                } else {
                    // Notify remaining members
                    const members = await this.partyManager.getPartyMembers(partyId);
                    if (members.success) {
                        this.partyManager.broadcastToParty(partyId, {
                            type: 'party_member_left',
                            data: {
                                party_id: partyId,
                                player_id: playerId,
                                members: members.members,
                                reason: 'disconnected'
                            }
                        }, this);
                    }
                }
            }
        }

        // Remove from maps
        this.clients.delete(playerId);
        this.players.delete(playerId);

        // Broadcast disconnect
        this.broadcast({
            type: 'player_left',
            data: { player_id: playerId }
        });
    }

    send(ws, message) {
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify(message));
        }
    }

    broadcast(message, excludePlayerId = null) {
        this.clients.forEach((ws, playerId) => {
            if (playerId !== excludePlayerId) {
                this.send(ws, message);
            }
        });
    }

    getPlayerCount() {
        return this.players.size;
    }

    // Handle monster damage from player
    async distributeMonsterXP(monsterId, killerId, monsterData) {
        console.log(`[XP] Starting XP distribution for monster ${monsterId}, killer ${killerId}`);
        
        // Calculate base XP from monster level
        const baseXP = (monsterData.level || 1) * 10; // 10 XP per level
        console.log(`[XP] Base XP: ${baseXP}`);
        
        // Check if killer is in a party
        const killerPartyId = this.partyManager.getPlayerPartyId(killerId);
        console.log(`[XP] Killer party ID: ${killerPartyId}`);
        
        if (killerPartyId) {
            console.log(`[XP] Killer is in party ${killerPartyId}, fetching members...`);
            
            // Party XP distribution
            const partyMembersResult = await this.partyManager.getPartyMembers(killerPartyId);
            console.log(`[XP] Party members result:`, partyMembersResult);
            
            const killerPlayer = this.players.get(killerId);
            console.log(`[XP] Killer player data:`, killerPlayer ? 'found' : 'NOT FOUND');
            
            if (!killerPlayer || !partyMembersResult || !partyMembersResult.success || !partyMembersResult.members || !Array.isArray(partyMembersResult.members)) {
                console.log('[XP] Party data not found or invalid, giving solo XP');
                console.log('[XP] Debug - killerPlayer:', !!killerPlayer, 'partyMembersResult:', partyMembersResult);
                // Fallback to solo XP
                const killerWs = this.getPlayerWebSocket(killerId);
                if (killerWs) {
                    this.send(killerWs, {
                        type: 'gain_xp',
                        data: {
                            xp: baseXP,
                            source: 'monster',
                            monster_id: monsterId,
                            shared: false
                        }
                    });
                    console.log(`[XP] Sent solo XP (${baseXP}) to killer ${killerId}`);
                }
                return;
            }
            
            const partyMembers = partyMembersResult.members;
            console.log(`[XP] Party has ${partyMembers.length} members:`, partyMembers.map(m => m.id));
            
            // Find party members within range (500 pixels)
            const nearbyMembers = [];
            for (const member of partyMembers) {
                const memberPlayer = this.players.get(member.id);
                if (memberPlayer && member.id !== killerId) {
                    // Calculate distance
                    const dx = memberPlayer.x - killerPlayer.x;
                    const dy = memberPlayer.y - killerPlayer.y;
                    const distance = Math.sqrt(dx * dx + dy * dy);
                    
                    console.log(`[XP] Member ${member.id} distance: ${distance.toFixed(2)} pixels`);
                    
                    if (distance <= 500) {
                        nearbyMembers.push(member.id);
                        console.log(`[XP] Member ${member.id} is within range`);
                    } else {
                        console.log(`[XP] Member ${member.id} is too far away`);
                    }
                }
            }
            
            // Include killer in XP distribution
            nearbyMembers.push(killerId);
            console.log(`[XP] Total nearby members (including killer): ${nearbyMembers.length}`);
            
            // Split XP equally
            const xpPerMember = Math.floor(baseXP / nearbyMembers.length);
            
            console.log(`[XP] Distributing ${baseXP} XP to ${nearbyMembers.length} party members (${xpPerMember} each)`);
            
            // Send XP to each member
            for (const memberId of nearbyMembers) {
                const memberWs = this.getPlayerWebSocket(memberId);
                if (memberWs) {
                    this.send(memberWs, {
                        type: 'gain_xp',
                        data: {
                            xp: xpPerMember,
                            source: 'monster',
                            monster_id: monsterId,
                            shared: nearbyMembers.length > 1
                        }
                    });
                    console.log(`[XP] Sent ${xpPerMember} XP to member ${memberId}`);
                } else {
                    console.log(`[XP] ERROR: Could not find WebSocket for member ${memberId}`);
                }
            }
            console.log(`[XP] Party XP distribution complete`);
        } else {
            console.log(`[XP] Killer is solo, giving full XP`);
            // Solo XP - give full amount to killer
            const killerWs = this.getPlayerWebSocket(killerId);
            if (killerWs) {
                this.send(killerWs, {
                    type: 'gain_xp',
                    data: {
                        xp: baseXP,
                        source: 'monster',
                        monster_id: monsterId,
                        shared: false
                    }
                });
                console.log(`[XP] Sent solo XP (${baseXP}) to killer ${killerId}`);
            } else {
                console.log(`[XP] ERROR: Could not find WebSocket for killer ${killerId}`);
            }
        }
    }
    
    getPlayerWebSocket(playerId) {
        // Find WebSocket for player ID
        for (const ws of this.wss.clients) {
            if (ws.playerId === playerId) {
                return ws;
            }
        }
        return null;
    }

    async handleMonsterDamage(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const { monster_id, damage } = message.data;
        
        console.log(`[Monster] Player ${playerId} damaged monster ${monster_id} for ${damage} damage`);
        
        const result = this.monsterManager.damageMonster(monster_id, damage, playerId);
        
        if (result) {
            console.log(`[Monster] Monster ${monster_id} result:`, result);
            
            // Broadcast monster update to all players
            this.broadcast({
                type: 'monster_update',
                data: result
            });

            // If monster died, handle death
            if (result.state === 'dead') {
                console.log(`[Monster] Monster ${monster_id} DIED - killed by player ${playerId}`);
                
                // Broadcast monster death FIRST (don't let XP block death)
                this.broadcast({
                    type: 'monster_death',
                    data: {
                        monster_id: monster_id,
                        killer_id: playerId
                    }
                });
                console.log(`[Monster] Broadcasted monster_death for ${monster_id}`);
                
                // Then try to distribute XP (errors won't block death)
                try {
                    const monster = this.monsterManager.monsters.get(monster_id);
                    if (monster) {
                        console.log(`[Monster] Distributing XP for monster ${monster_id}`);
                        await this.distributeMonsterXP(monster_id, playerId, monster);
                        console.log(`[Monster] XP distribution complete for monster ${monster_id}`);
                    } else {
                        console.log(`[Monster] ERROR: Monster ${monster_id} not found in manager`);
                    }
                } catch (error) {
                    console.error('[XP] Error distributing XP:', error);
                }
            }
        } else {
            console.log(`[Monster] ERROR: No result from damageMonster for ${monster_id}`);
        }
    }

    // Handle request for monster list
    handleRequestMonsters(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const monsters = this.monsterManager.getMonsters(playerId);
        this.send(ws, {
            type: 'monsters',
            data: monsters
        });
    }

    // Broadcast monster respawn
    broadcastMonsterRespawn(monster) {
        this.broadcast({
            type: 'monster_spawn',
            data: monster
        });
    }

    // Start broadcasting monster positions
    startPositionBroadcast() {
        // Update AI and broadcast positions every 100ms (10 times per second)
        setInterval(() => {
            // Update monster AI with current player positions
            const playerPositions = Array.from(this.players.values());
            this.monsterManager.updateAI(playerPositions, 0.1);
            
            // Broadcast updated positions
            const positions = this.monsterManager.getMonsterPositions();
            if (positions.length > 0) {
                this.broadcast({
                    type: 'monster_positions',
                    data: positions
                });
            }
        }, 100);
        
        console.log('✓ Monster AI and position broadcast started (10 Hz)');
    }
    
    // Helper method to get client by player ID
    getClientByPlayerId(playerId) {
        const ws = this.clients.get(playerId);
        return ws ? { ws, playerId } : null;
    }

    // ==================== PARTY SYSTEM HANDLERS ====================

    async handlePartyCreate(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const result = await this.partyManager.createParty(playerId, message.data || {});
        
        if (result.success) {
            // Send party created confirmation
            this.send(ws, {
                type: 'party_created',
                data: {
                    party_id: result.party_id,
                    leader_id: playerId
                }
            });
            
            // Send full member list with nicknames
            const members = await this.partyManager.getPartyMembers(result.party_id);
            if (members.success) {
                this.send(ws, {
                    type: 'party_member_joined',
                    data: {
                        party_id: result.party_id,
                        player_id: playerId,
                        members: members.members
                    }
                });
            }
            
            console.log(`[Party] Player ${playerId} created party ${result.party_id}`);
        } else {
            this.send(ws, {
                type: 'party_error',
                data: { error: result.error }
            });
        }
    }

    async handlePartyInvite(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const { target_player_id } = message.data;
        const partyId = this.partyManager.getPlayerPartyId(playerId);
        
        if (!partyId) {
            this.send(ws, {
                type: 'party_error',
                data: { error: 'You are not in a party' }
            });
            return;
        }

        const result = await this.partyManager.invitePlayer(
            partyId, 
            playerId, 
            target_player_id, 
            this,
            message.data.message
        );
        
        if (result.success) {
            // Send confirmation to inviter
            this.send(ws, {
                type: 'party_invite_sent',
                data: { target_player_id }
            });

            // Send invite to target player
            const targetClient = this.getClientByPlayerId(target_player_id);
            if (targetClient && targetClient.ws) {
                const inviter = this.players.get(playerId);
                this.send(targetClient.ws, {
                    type: 'party_invite_received',
                    data: {
                        invite_id: result.invite_id,
                        inviter_id: playerId,
                        inviter_name: inviter?.nickname || 'Unknown',
                        party_id: partyId
                    }
                });
            }
            
            console.log(`[Party] Player ${playerId} invited ${target_player_id} to party ${partyId}`);
        } else {
            this.send(ws, {
                type: 'party_error',
                data: { error: result.error }
            });
        }
    }

    async handlePartyAccept(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const { invite_id } = message.data;
        const result = await this.partyManager.acceptInvite(invite_id, playerId);
        
        if (result.success) {
            const partyId = result.party_id;
            const members = await this.partyManager.getPartyMembers(partyId);
            
            if (members.success) {
                // Notify all party members
                this.partyManager.broadcastToParty(partyId, {
                    type: 'party_member_joined',
                    data: {
                        party_id: partyId,
                        player_id: playerId,
                        members: members.members
                    }
                }, this);
                
                console.log(`[Party] Player ${playerId} joined party ${partyId}`);
            }
        } else {
            this.send(ws, {
                type: 'party_error',
                data: { error: result.error }
            });
        }
    }

    async handlePartyDecline(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const { invite_id } = message.data;
        
        // Update invite status in database
        const { pool: db } = require('../config/database');
        await db.query(
            'UPDATE party_invites SET status = "declined", responded_at = NOW() WHERE id = ? AND invitee_id = ?',
            [invite_id, playerId]
        );
        
        this.send(ws, {
            type: 'party_invite_declined',
            data: { invite_id }
        });
        
        console.log(`[Party] Player ${playerId} declined invite ${invite_id}`);
    }

    async handlePartyLeave(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const partyId = this.partyManager.getPlayerPartyId(playerId);
        if (!partyId) {
            this.send(ws, {
                type: 'party_error',
                data: { error: 'You are not in a party' }
            });
            return;
        }

        // Get party members BEFORE leaving (to notify them if disbanded)
        const party = this.partyManager.getParty(partyId);
        const remainingMemberIds = party ? party.members.filter(id => id !== playerId) : [];
        
        console.log(`[Party] Player ${playerId} leaving party ${partyId}`);
        console.log(`[Party] Party members before leave:`, party ? party.members : 'none');
        console.log(`[Party] Remaining members after leave:`, remainingMemberIds);

        const result = await this.partyManager.leaveParty(playerId);
        
        console.log(`[Party] Leave result:`, result);
        
        if (result.success) {
            if (result.disbanded) {
                console.log(`[Party] Party ${partyId} DISBANDED - sending messages to ${remainingMemberIds.length + 1} players`);
                
                // Party was disbanded - notify the player who left
                this.send(ws, {
                    type: 'party_disbanded',
                    data: { 
                        party_id: partyId,
                        reason: result.reason || 'Party disbanded'
                    }
                });
                console.log(`[Party] Sent party_disbanded to player ${playerId} (who left)`);

                // Notify remaining members (if any) that party was disbanded
                for (const memberId of remainingMemberIds) {
                    const memberClient = this.getClientByPlayerId(memberId);
                    console.log(`[Party] Checking member ${memberId}: client exists? ${!!memberClient}, ws exists? ${!!(memberClient && memberClient.ws)}`);
                    if (memberClient && memberClient.ws) {
                        this.send(memberClient.ws, {
                            type: 'party_disbanded',
                            data: { 
                                party_id: partyId,
                                reason: result.reason || 'Party disbanded'
                            }
                        });
                        console.log(`[Party] Sent party_disbanded to remaining member ${memberId}`);
                    } else {
                        console.log(`[Party] Could not send to member ${memberId} - client not found or disconnected`);
                    }
                }
                
                console.log(`[Party] Party ${partyId} disbanded (${result.reason || 'unknown reason'})`);
            } else {
                // Party continues - notify the player who left
                this.send(ws, {
                    type: 'party_left',
                    data: { party_id: partyId }
                });

                // Notify remaining members
                const members = await this.partyManager.getPartyMembers(partyId);
                if (members.success) {
                    this.partyManager.broadcastToParty(partyId, {
                        type: 'party_member_left',
                        data: {
                            party_id: partyId,
                            player_id: playerId,
                            members: members.members
                        }
                    }, this);
                }
                console.log(`[Party] Player ${playerId} left party ${partyId}`);
            }
        } else {
            this.send(ws, {
                type: 'party_error',
                data: { error: result.error }
            });
        }
    }

    async handlePartyKick(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const { target_player_id } = message.data;
        const partyId = this.partyManager.getPlayerPartyId(playerId);
        
        if (!partyId) {
            this.send(ws, {
                type: 'party_error',
                data: { error: 'You are not in a party' }
            });
            return;
        }

        const party = this.partyManager.getParty(partyId);
        if (!party || party.leader_id !== playerId) {
            this.send(ws, {
                type: 'party_error',
                data: { error: 'Only the leader can kick members' }
            });
            return;
        }

        // Get party members BEFORE kicking (to notify them if disbanded)
        const remainingMemberIds = party.members.filter(id => id !== target_player_id);

        // Notify kicked player before removing them
        const targetClient = this.getClientByPlayerId(target_player_id);
        if (targetClient && targetClient.ws) {
            this.send(targetClient.ws, {
                type: 'party_kicked',
                data: { party_id: partyId }
            });
        }

        // Use leaveParty to properly handle removal and auto-disband
        const result = await this.partyManager.leaveParty(target_player_id);
        
        if (result.success) {
            if (result.disbanded) {
                // Party was disbanded - notify remaining members (the leader)
                for (const memberId of remainingMemberIds) {
                    const memberClient = this.getClientByPlayerId(memberId);
                    if (memberClient && memberClient.ws) {
                        this.send(memberClient.ws, {
                            type: 'party_disbanded',
                            data: { 
                                party_id: partyId,
                                reason: 'Only 1 member remaining after kick'
                            }
                        });
                    }
                }
                console.log(`[Party] Party ${partyId} disbanded after kick (only 1 member remaining)`);
            } else {
                // Notify remaining members
                const members = await this.partyManager.getPartyMembers(partyId);
                if (members.success) {
                    this.partyManager.broadcastToParty(partyId, {
                        type: 'party_member_left',
                        data: {
                            party_id: partyId,
                            player_id: target_player_id,
                            members: members.members,
                            reason: 'kicked'
                        }
                    }, this);
                }
                console.log(`[Party] Player ${target_player_id} kicked from party ${partyId} by ${playerId}`);
            }
        } else {
            this.send(ws, {
                type: 'party_error',
                data: { error: result.error }
            });
        }
    }

    async handlePartyTransferLeadership(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const { target_player_id } = message.data;
        const partyId = this.partyManager.getPlayerPartyId(playerId);
        
        if (!partyId) {
            this.send(ws, {
                type: 'party_error',
                data: { error: 'You are not in a party' }
            });
            return;
        }

        const party = this.partyManager.getParty(partyId);
        if (!party || party.leader_id !== playerId) {
            this.send(ws, {
                type: 'party_error',
                data: { error: 'Only the leader can transfer leadership' }
            });
            return;
        }

        if (!party.members.includes(target_player_id)) {
            this.send(ws, {
                type: 'party_error',
                data: { error: 'Target player is not in the party' }
            });
            return;
        }

        // Update database
        const { pool: db } = require('../config/database');
        await db.query('UPDATE parties SET leader_id = ? WHERE party_id = ?', [target_player_id, partyId]);
        await db.query('UPDATE party_members SET role = "member" WHERE party_id = ? AND player_id = ?', [partyId, playerId]);
        await db.query('UPDATE party_members SET role = "leader" WHERE party_id = ? AND player_id = ?', [partyId, target_player_id]);

        // Update memory
        party.leader_id = target_player_id;

        // Notify all party members
        this.partyManager.broadcastToParty(partyId, {
            type: 'party_leadership_changed',
            data: {
                party_id: partyId,
                old_leader_id: playerId,
                new_leader_id: target_player_id
            }
        }, this);

        console.log(`[Party] Leadership transferred from ${playerId} to ${target_player_id} in party ${partyId}`);
    }

    async clearPendingInvites(playerId) {
        /**
         * Clear all pending invites for a player (on disconnect/logout)
         */
        try {
            const { pool: db } = require('../config/database');
            
            // Expire invites sent by this player
            await db.query(
                `UPDATE party_invites 
                 SET status = 'expired' 
                 WHERE inviter_id = ? AND status = 'pending'`,
                [playerId]
            );
            
            // Decline invites received by this player
            await db.query(
                `UPDATE party_invites 
                 SET status = 'declined', responded_at = NOW() 
                 WHERE invitee_id = ? AND status = 'pending'`,
                [playerId]
            );
            
            console.log(`[Party] Cleared pending invites for player ${playerId}`);
        } catch (error) {
            console.error('[Party] Error clearing pending invites:', error);
        }
    }

    async handlePartyHPUpdate(ws, message) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const partyId = this.partyManager.getPlayerPartyId(playerId);
        if (!partyId) {
            console.log(`[Party] HP update from player ${playerId} - not in party`);
            return;
        }

        const { hp, max_hp } = message.data;
        
        console.log(`[Party] HP update from player ${playerId}: ${hp}/${max_hp} - broadcasting to party ${partyId}`);

        // Broadcast HP update to party members
        this.partyManager.broadcastToParty(partyId, {
            type: 'party_member_hp_update',
            data: {
                player_id: playerId,
                hp: hp,
                max_hp: max_hp
            }
        }, this);
        
        console.log(`[Party] HP update broadcasted to party ${partyId}`);
    }

    // Start party cleanup interval
    startPartyCleanup() {
        // Clean up expired invites every 30 seconds
        setInterval(async () => {
            await this.partyManager.cleanupExpiredInvites();
        }, 30000);
        
        console.log('✓ Party invite cleanup started (30s interval)');
    }

    // Override handleDisconnect to include party cleanup
    async handleDisconnect(ws) {
        const playerId = ws.playerId;
        if (!playerId) return;

        const player = this.players.get(playerId);
        if (player) {
            console.log(`Player ${player.nickname} (${playerId}) disconnected`);
        }

        // Notify friends that player went offline
        if (this.friendManager) {
            await this.friendManager.notifyFriendsOffline(playerId);
        }

        // Auto-leave party on disconnect
        const partyId = this.partyManager.getPlayerPartyId(playerId);
        if (partyId) {
            const result = await this.partyManager.leaveParty(playerId);
            if (result.success) {
                if (result.disbanded) {
                    this.partyManager.broadcastToParty(partyId, {
                        type: 'party_disbanded',
                        data: { party_id: partyId }
                    }, this);
                } else {
                    const members = await this.partyManager.getPartyMembers(partyId);
                    if (members.success) {
                        this.partyManager.broadcastToParty(partyId, {
                            type: 'party_member_left',
                            data: {
                                party_id: partyId,
                                player_id: playerId,
                                members: members.members
                            }
                        }, this);
                    }
                }
                console.log(`[Party] Player ${playerId} auto-left party ${partyId} on disconnect`);
            }
        }

        // Remove from maps
        this.clients.delete(playerId);
        this.players.delete(playerId);

        // Broadcast disconnect
        this.broadcast({
            type: 'player_left',
            data: { player_id: playerId }
        });
    }

    // =========================
    // DUEL SYSTEM
    // =========================

    handleDuelRequest(ws, message) {
        const requesterId = ws.playerId;
        if (!requesterId) return;

        const targetPlayerId = message.target_player_id;
        if (!targetPlayerId) {
            console.log('[Duel] Invalid target player ID');
            return;
        }

        const requester = this.players.get(requesterId);
        if (!requester) return;

        // Send duel request to target player
        const targetWs = this.clients.get(targetPlayerId);
        if (targetWs) {
            this.send(targetWs, {
                type: 'duel_request',
                data: {
                    requester_id: requesterId,
                    requester_name: requester.nickname
                }
            });
            console.log(`[Duel] ${requester.nickname} challenged player ${targetPlayerId}`);
        } else {
            console.log('[Duel] Target player not online');
        }
    }

    handleDuelAccept(ws, message) {
        const accepterId = ws.playerId;
        if (!accepterId) return;

        const requesterId = message.requester_id;
        if (!requesterId) return;

        const accepter = this.players.get(accepterId);
        const requester = this.players.get(requesterId);
        
        if (!accepter || !requester) return;

        // Notify requester that duel was accepted
        const requesterWs = this.clients.get(requesterId);
        if (requesterWs) {
            this.send(requesterWs, {
                type: 'duel_accepted',
                data: {
                    accepter_id: accepterId,
                    accepter_name: accepter.nickname
                }
            });
        }

        // Notify both players that duel is starting
        this.send(ws, {
            type: 'duel_started',
            data: {
                player1_id: requesterId,
                player1_name: requester.nickname,
                player2_id: accepterId,
                player2_name: accepter.nickname
            }
        });

        if (requesterWs) {
            this.send(requesterWs, {
                type: 'duel_started',
                data: {
                    player1_id: requesterId,
                    player1_name: requester.nickname,
                    player2_id: accepterId,
                    player2_name: accepter.nickname
                }
            });
        }

        console.log(`[Duel] Duel started: ${requester.nickname} vs ${accepter.nickname}`);
    }

    handleDuelDecline(ws, message) {
        const declinerId = ws.playerId;
        if (!declinerId) return;

        const requesterId = message.requester_id;
        if (!requesterId) return;

        const decliner = this.players.get(declinerId);
        if (!decliner) return;

        // Notify requester that duel was declined
        const requesterWs = this.clients.get(requesterId);
        if (requesterWs) {
            this.send(requesterWs, {
                type: 'duel_declined',
                data: {
                    decliner_id: declinerId,
                    decliner_name: decliner.nickname
                }
            });
        }

        console.log(`[Duel] ${decliner.nickname} declined duel from player ${requesterId}`);
    }

    handleDuelEnd(ws, message) {
        const reporterId = ws.playerId;
        if (!reporterId) return;

        const winnerId = message.winner_id;
        const loserId = message.loser_id;

        if (!winnerId || !loserId) return;

        const winner = this.players.get(winnerId);
        const loser = this.players.get(loserId);

        if (!winner || !loser) return;

        // Broadcast duel end to both players
        const winnerWs = this.clients.get(winnerId);
        const loserWs = this.clients.get(loserId);

        const endData = {
            type: 'duel_ended',
            data: {
                winner_id: winnerId,
                winner_name: winner.nickname,
                loser_id: loserId,
                loser_name: loser.nickname
            }
        };

        if (winnerWs) {
            this.send(winnerWs, endData);
        }

        if (loserWs) {
            this.send(loserWs, endData);
        }

        console.log(`[Duel] Duel ended: ${winner.nickname} defeated ${loser.nickname}`);
    }

    handlePlayerDamage(ws, message) {
        console.log('[Duel] *** RECEIVED PLAYER_DAMAGE MESSAGE ***');
        console.log('[Duel] Message:', message);
        
        const attackerId = ws.playerId;
        if (!attackerId) {
            console.log('[Duel] ERROR: No attacker ID');
            return;
        }

        const targetId = message.target_player_id;
        const damage = message.damage || 0;

        console.log(`[Duel] Attacker ID: ${attackerId}, Target ID: ${targetId}, Damage: ${damage}`);

        if (!targetId || damage <= 0) {
            console.log('[Duel] ERROR: Invalid target or damage');
            return;
        }

        const attacker = this.players.get(attackerId);
        const target = this.players.get(targetId);

        if (!attacker || !target) {
            console.log('[Duel] ERROR: Attacker or target not found');
            console.log(`[Duel] Attacker exists: ${!!attacker}, Target exists: ${!!target}`);
            return;
        }

        console.log(`[Duel] ${attacker.nickname} dealt ${damage} damage to ${target.nickname}`);

        // Update target's HP
        target.hp = Math.max(0, target.hp - damage);

        // Send damage notification to target
        const targetWs = this.clients.get(targetId);
        if (targetWs) {
            this.send(targetWs, {
                type: 'player_damaged',
                data: {
                    attacker_id: attackerId,
                    attacker_name: attacker.nickname,
                    damage: damage,
                    new_hp: target.hp,
                    max_hp: target.max_hp
                }
            });
        }

        // Broadcast HP update to all players
        this.broadcast({
            type: 'player_hp_update',
            data: {
                player_id: targetId,
                hp: target.hp,
                max_hp: target.max_hp
            }
        });

        console.log(`[Duel] ${target.nickname} HP: ${target.hp}/${target.max_hp}`);
    }

}

module.exports = GameServer;
