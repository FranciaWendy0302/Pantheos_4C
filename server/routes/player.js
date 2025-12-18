// Player data routes - Save, Load, Update
const express = require('express');
const { pool } = require('../config/database');

const router = express.Router();

// Get player data
router.get('/:playerId', async (req, res) => {
    try {
        const { playerId } = req.params;
        const { character_slot } = req.query;  // Get slot from query params

        // Get player data for specific slot (default to slot 1)
        const slot = character_slot || 1;
        const [playerData] = await pool.query(
            'SELECT * FROM player_data WHERE player_id = ? AND character_slot = ?',
            [playerId, slot]
        );

        if (playerData.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Character not found in slot ' + slot
            });
        }

        const player = playerData[0];
        
        console.log('[GET Player] Returning player data:');
        console.log('  - Player ID:', playerId);
        console.log('  - Slot:', slot);
        console.log('  - Inventory:', player.inventory ? (typeof player.inventory === 'string' ? player.inventory.substring(0, 100) + '...' : 'Present') : 'NULL');
        console.log('  - Quests:', player.quests ? (typeof player.quests === 'string' ? player.quests.substring(0, 100) + '...' : 'Present') : 'NULL');

        res.json({
            success: true,
            player_data: player
        });

    } catch (error) {
        console.error('Get player error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get player data'
        });
    }
});

// Get all character slots for a player
router.get('/:playerId/slots', async (req, res) => {
    try {
        const { playerId } = req.params;

        const [characters] = await pool.query(
            'SELECT character_slot, nickname, character_class, level, god_id FROM player_data WHERE player_id = ? ORDER BY character_slot',
            [playerId]
        );

        res.json({
            success: true,
            characters: characters
        });

    } catch (error) {
        console.error('Get character slots error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get character slots'
        });
    }
});

// Save player data
router.post('/save', async (req, res) => {
    try {
        const {
            player_id,
            character_slot,
            nickname,
            level,
            xp,
            gold,
            currency,
            hp,
            max_hp,
            mp,
            max_mp,
            attack,
            defense,
            position_x,
            position_y,
            current_map,
            character_class,
            god_id,
            god_skill_unlocked,
            arrow_count,
            bomb_count,
            inventory,
            quests,
            persistence
        } = req.body;

        console.log('\n=== SAVE PLAYER DATA ===');
        console.log('Player ID:', player_id);
        console.log('Character Slot:', character_slot);
        console.log('Nickname:', nickname);
        console.log('Class:', character_class);
        console.log('God ID:', god_id);
        console.log('God Skill Unlocked:', god_skill_unlocked);
        console.log('Position:', position_x, position_y, current_map);
        console.log('Inventory:', inventory ? (typeof inventory === 'string' ? inventory.substring(0, 100) + '...' : 'Array') : 'NULL');
        console.log('Quests:', quests ? (typeof quests === 'string' ? quests.substring(0, 100) + '...' : 'Array') : 'NULL');
        console.log('Persistence:', persistence ? (typeof persistence === 'string' ? persistence.substring(0, 100) + '...' : 'Array') : 'NULL');

        if (!player_id) {
            return res.status(400).json({
                success: false,
                error: 'Missing player_id'
            });
        }

        const slot = character_slot || 1;

        // Check if player_data exists for this slot
        const [existing] = await pool.query(
            'SELECT player_id FROM player_data WHERE player_id = ? AND character_slot = ?',
            [player_id, slot]
        );

        if (existing.length === 0) {
            // Create new player_data
            console.log('Creating new player_data for slot', slot, '...');
            await pool.query(
                `INSERT INTO player_data (
                    player_id, character_slot, nickname, character_class, god_id, god_skill_unlocked,
                    level, xp, currency, hp, max_hp, mp, max_mp, attack, defense,
                    position_x, position_y, current_map, inventory, quests, persistence
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                [
                    player_id,
                    slot,
                    nickname || 'Player',
                    character_class || 'Swordsman',
                    god_id || 0,
                    god_skill_unlocked || false,
                    level || 1,
                    xp || 0,
                    currency || gold || 0,
                    hp || 100,
                    max_hp || 100,
                    mp || 50,
                    max_mp || 50,
                    attack || 10,
                    defense || 5,
                    position_x || 0,
                    position_y || 0,
                    current_map || 'res://Levels/final map/scene/safezone.tscn',
                    inventory || null,
                    quests || null,
                    persistence || null
                ]
            );
            console.log('✓ Player data created for slot', slot, 'with god_id:', god_id || 0);
        } else {
            // Update existing player_data
            console.log('Updating existing player_data for slot', slot, '...');
            await pool.query(
                `UPDATE player_data SET
                    nickname = ?,
                    character_class = ?,
                    god_id = ?,
                    god_skill_unlocked = ?,
                    level = ?,
                    xp = ?,
                    currency = ?,
                    hp = ?,
                    max_hp = ?,
                    mp = ?,
                    max_mp = ?,
                    attack = ?,
                    defense = ?,
                    position_x = ?,
                    position_y = ?,
                    current_map = ?,
                    inventory = ?,
                    quests = ?,
                    persistence = ?
                WHERE player_id = ? AND character_slot = ?`,
                [
                    nickname || 'Player',
                    character_class || 'Swordsman',
                    god_id !== undefined ? god_id : 0,
                    god_skill_unlocked !== undefined ? god_skill_unlocked : false,
                    level || 1,
                    xp || 0,
                    currency || gold || 0,
                    hp || 100,
                    max_hp || 100,
                    mp || 50,
                    max_mp || 50,
                    attack || 10,
                    defense || 5,
                    position_x || 0,
                    position_y || 0,
                    current_map || 'res://Levels/final map/scene/safezone.tscn',
                    inventory || null,
                    quests || null,
                    persistence || null,
                    player_id,
                    slot
                ]
            );
            console.log('✓ Player data updated for slot', slot, 'with god_id:', god_id !== undefined ? god_id : 0);
        }

        res.json({
            success: true,
            message: 'Player data saved'
        });

    } catch (error) {
        console.error('Save player error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to save player data: ' + error.message
        });
    }
});

// Update player position (frequent updates)
router.post('/position', async (req, res) => {
    try {
        const { player_id, character_slot, x, y, map } = req.body;

        if (!player_id) {
            return res.status(400).json({
                success: false,
                error: 'Missing player_id'
            });
        }

        const slot = character_slot || 1;

        await pool.query(
            `UPDATE player_data SET
                position_x = ?,
                position_y = ?,
                current_map = ?
            WHERE player_id = ? AND character_slot = ?`,
            [x || 0, y || 0, map || '', player_id, slot]
        );

        res.json({ success: true });

    } catch (error) {
        console.error('Update position error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update position'
        });
    }
});

// Update player character class (when creating character)
router.post('/update-class', async (req, res) => {
    try {
        const { player_id, character_slot, character_class, nickname, god_id } = req.body;

        console.log('\n=== UPDATE CHARACTER CLASS ===');
        console.log('Player ID:', player_id);
        console.log('Character Slot:', character_slot);
        console.log('Class:', character_class);
        console.log('Nickname:', nickname);
        console.log('God ID:', god_id);

        if (!player_id) {
            return res.status(400).json({
                success: false,
                error: 'Missing player_id'
            });
        }

        const slot = character_slot || 1;

        // Check if player_data exists for this slot
        const [existing] = await pool.query(
            'SELECT player_id FROM player_data WHERE player_id = ? AND character_slot = ?',
            [player_id, slot]
        );

        if (existing.length === 0) {
            // Create player_data if it doesn't exist
            console.log('Creating new player_data for slot', slot, 'with class and god...');
            await pool.query(
                `INSERT INTO player_data (player_id, character_slot, nickname, character_class, god_id) VALUES (?, ?, ?, ?, ?)`,
                [player_id, slot, nickname || 'Player', character_class || 'Swordsman', god_id || 0]
            );
            console.log('✓ Player data created for slot', slot, 'with god_id:', god_id || 0);
        } else {
            // Update existing player_data
            console.log('Updating existing player_data for slot', slot, '...');
            
            await pool.query(
                'UPDATE player_data SET character_class = ?, nickname = COALESCE(?, nickname), god_id = COALESCE(?, god_id) WHERE player_id = ? AND character_slot = ?',
                [character_class || 'Swordsman', nickname, god_id, player_id, slot]
            );
            console.log('✓ Character class and god updated for slot', slot);
        }

        res.json({
            success: true,
            message: 'Character class updated'
        });

    } catch (error) {
        console.error('Update character class error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update character class: ' + error.message
        });
    }
});

module.exports = router;
