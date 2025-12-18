// Monster Manager - Server-side monster spawning and management
class MonsterManager {
    constructor() {
        this.monsters = new Map(); // monster_id -> monster data
        this.nextMonsterId = 1;
        this.spawnPoints = [];
    }

    // Initialize spawn points for a zone
    initializeZone(zoneName, spawnPoints) {
        console.log(`Initializing zone: ${zoneName} with ${spawnPoints.length} spawn points`);
        this.spawnPoints = spawnPoints;
        
        // Spawn initial monsters
        spawnPoints.forEach(spawnPoint => {
            this.spawnMonster(spawnPoint);
        });
    }

    // Spawn a monster at a spawn point
    spawnMonster(spawnPoint) {
        const monsterId = this.nextMonsterId++;
        
        const monster = {
            monster_id: monsterId,
            type: spawnPoint.type || 'slime',
            x: spawnPoint.x,
            y: spawnPoint.y,
            hp: spawnPoint.max_hp || 30,
            max_hp: spawnPoint.max_hp || 30,
            level: spawnPoint.level || 1,
            state: 'idle', // idle, chasing, attacking, dead
            target_player_id: null,
            spawn_point: spawnPoint,
            owner_id: spawnPoint.owner_id || null, // null = shared, player_id = quest monster
            respawn_time: spawnPoint.respawn_time || 30000, // 30 seconds default
            last_damage_time: Date.now()
        };

        this.monsters.set(monsterId, monster);
        return monster;
    }

    // Get all monsters (or filtered by owner)
    getMonsters(ownerId = null) {
        if (ownerId === null) {
            // Return only shared monsters (no owner)
            return Array.from(this.monsters.values()).filter(m => m.owner_id === null && m.state !== 'dead');
        } else {
            // Return shared monsters + this player's quest monsters
            return Array.from(this.monsters.values()).filter(m => 
                (m.owner_id === null || m.owner_id === ownerId) && m.state !== 'dead'
            );
        }
    }

    // Damage a monster
    damageMonster(monsterId, damage, attackerId) {
        const monster = this.monsters.get(monsterId);
        if (!monster || monster.state === 'dead') {
            return null;
        }

        monster.hp -= damage;
        monster.last_damage_time = Date.now();

        if (monster.hp <= 0) {
            monster.hp = 0;
            monster.state = 'dead';
            
            // Schedule respawn
            setTimeout(() => {
                this.respawnMonster(monsterId);
            }, monster.respawn_time);

            return {
                monster_id: monsterId,
                state: 'dead',
                killer_id: attackerId
            };
        }

        return {
            monster_id: monsterId,
            hp: monster.hp,
            max_hp: monster.max_hp,
            state: monster.state
        };
    }

    // Respawn a dead monster
    respawnMonster(monsterId) {
        const monster = this.monsters.get(monsterId);
        if (!monster) return;

        // Reset monster to spawn point
        monster.hp = monster.max_hp;
        monster.state = 'idle';
        monster.target_player_id = null;
        monster.x = monster.spawn_point.x;
        monster.y = monster.spawn_point.y;

        console.log(`Monster ${monsterId} respawned at (${monster.x}, ${monster.y})`);
        
        // Notify callback if set (for broadcasting)
        if (this.onRespawn) {
            this.onRespawn(monster);
        }
        
        return monster;
    }

    // Set respawn callback
    setRespawnCallback(callback) {
        this.onRespawn = callback;
    }

    // Update monster position (for AI movement)
    updateMonsterPosition(monsterId, x, y) {
        const monster = this.monsters.get(monsterId);
        if (monster && monster.state !== 'dead') {
            monster.x = x;
            monster.y = y;
            monster.last_position_update = Date.now();
            return true;
        }
        return false;
    }

    // Get all monster positions for broadcasting
    getMonsterPositions() {
        const positions = [];
        this.monsters.forEach((monster, id) => {
            if (monster.state !== 'dead') {
                positions.push({
                    monster_id: id,
                    x: monster.x,
                    y: monster.y
                });
            }
        });
        return positions;
    }

    // Update monster AI (called every tick)
    updateAI(players, deltaTime = 0.1) {
        this.monsters.forEach((monster, id) => {
            if (monster.state === 'dead') return;

            const AGGRO_RANGE = 150;
            const WANDER_RANGE = 50;
            const MOVE_SPEED = 30; // pixels per second
            const RETURN_DISTANCE = 100;

            // Find nearest player
            let nearestPlayer = null;
            let nearestDistance = Infinity;

            players.forEach(player => {
                const dx = player.x - monster.x;
                const dy = player.y - monster.y;
                const distance = Math.sqrt(dx * dx + dy * dy);
                
                if (distance < nearestDistance) {
                    nearestDistance = distance;
                    nearestPlayer = player;
                }
            });

            // Check distance from spawn
            const spawnDx = monster.spawn_point.x - monster.x;
            const spawnDy = monster.spawn_point.y - monster.y;
            const spawnDistance = Math.sqrt(spawnDx * spawnDx + spawnDy * spawnDy);

            // AI State Machine
            if (spawnDistance > RETURN_DISTANCE) {
                // Too far from spawn - return home
                monster.state = 'returning';
                this.moveToward(monster, monster.spawn_point.x, monster.spawn_point.y, MOVE_SPEED * deltaTime);
            } else if (nearestPlayer && nearestDistance < AGGRO_RANGE) {
                // Player nearby - chase
                monster.state = 'chasing';
                monster.target_player_id = nearestPlayer.player_id;
                this.moveToward(monster, nearestPlayer.x, nearestPlayer.y, MOVE_SPEED * deltaTime);
            } else {
                // Idle - wander near spawn
                monster.state = 'idle';
                monster.target_player_id = null;
                
                // Random wander every few seconds
                if (!monster.wander_timer || monster.wander_timer <= 0) {
                    monster.wander_timer = 2 + Math.random() * 3; // 2-5 seconds
                    monster.wander_target = {
                        x: monster.spawn_point.x + (Math.random() - 0.5) * WANDER_RANGE * 2,
                        y: monster.spawn_point.y + (Math.random() - 0.5) * WANDER_RANGE * 2
                    };
                }
                
                monster.wander_timer -= deltaTime;
                
                if (monster.wander_target) {
                    const dx = monster.wander_target.x - monster.x;
                    const dy = monster.wander_target.y - monster.y;
                    const distance = Math.sqrt(dx * dx + dy * dy);
                    
                    if (distance > 5) {
                        this.moveToward(monster, monster.wander_target.x, monster.wander_target.y, MOVE_SPEED * 0.5 * deltaTime);
                    }
                }
            }
        });
    }

    // Move monster toward target position
    moveToward(monster, targetX, targetY, speed) {
        const dx = targetX - monster.x;
        const dy = targetY - monster.y;
        const distance = Math.sqrt(dx * dx + dy * dy);
        
        if (distance > 1) {
            monster.x += (dx / distance) * speed;
            monster.y += (dy / distance) * speed;
        }
    }

    // Get monster by ID
    getMonster(monsterId) {
        return this.monsters.get(monsterId);
    }

    // Remove all monsters (for cleanup)
    clearAll() {
        this.monsters.clear();
        this.nextMonsterId = 1;
    }
}

module.exports = MonsterManager;
