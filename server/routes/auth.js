// Authentication routes - Login, Register
const express = require('express');
const bcrypt = require('bcrypt');
const { pool } = require('../config/database');

const router = express.Router();

// Register new account
router.post('/register', async (req, res) => {
    try {
        const { username, password, nickname } = req.body;

        console.log('\n=== REGISTER ATTEMPT ===');
        console.log('Username:', username);
        console.log('Nickname:', nickname);

        // Validation - nickname is optional, will be set during character creation
        if (!username || !password) {
            return res.status(400).json({
                success: false,
                error: 'Username and password are required'
            });
        }

        // Check if username exists
        const [existing] = await pool.query(
            'SELECT player_id FROM accounts WHERE username = ?',
            [username]
        );

        if (existing.length > 0) {
            console.log('✗ Username already exists');
            return res.status(400).json({
                success: false,
                error: 'Username already exists'
            });
        }

        // Hash password
        const passwordHash = await bcrypt.hash(password, 10);
        console.log('✓ Password hashed');

        // Create account
        const [accountResult] = await pool.query(
            'INSERT INTO accounts (username, password_hash) VALUES (?, ?)',
            [username, passwordHash]
        );

        const playerId = accountResult.insertId;
        console.log('✓ Account created, player_id:', playerId);
        console.log('✓ Registration successful - character will be created in-game');

        res.json({
            success: true,
            message: 'Account created successfully',
            player_id: playerId
        });

    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create account: ' + error.message
        });
    }
});

// Login
router.post('/login', async (req, res) => {
    try {
        const { username, password } = req.body;

        console.log('\n=== LOGIN ATTEMPT ===');
        console.log('Username:', username);
        console.log('Password length:', password ? password.length : 0);

        if (!username || !password) {
            console.log('✗ Missing credentials');
            return res.status(400).json({
                success: false,
                error: 'Missing credentials'
            });
        }

        // Get account data
        const [accounts] = await pool.query(
            'SELECT * FROM accounts WHERE username = ?',
            [username]
        );

        if (accounts.length === 0) {
            console.log('✗ User not found');
            return res.status(401).json({
                success: false,
                error: 'Invalid username or password'
            });
        }

        const account = accounts[0];
        console.log('✓ User found:', account.username);
        console.log('Hash type:', account.password_hash.substring(0, 4));
        console.log('Hash length:', account.password_hash.length);

        // Verify password
        console.log('Verifying password...');
        const validPassword = await bcrypt.compare(password, account.password_hash);
        console.log('Password valid:', validPassword);
        
        if (!validPassword) {
            console.log('✗ Password verification failed');
            return res.status(401).json({
                success: false,
                error: 'Invalid username or password'
            });
        }
        
        console.log('✓ Login successful');

        // Update last login
        await pool.query(
            'UPDATE accounts SET last_login = NOW() WHERE player_id = ?',
            [account.player_id]
        );

        // Get player data (default to slot 1)
        const [playerData] = await pool.query(
            'SELECT * FROM player_data WHERE player_id = ? AND character_slot = 1',
            [account.player_id]
        );

        // Combine all data
        const player = {
            player_id: account.player_id,
            username: account.username,
            created_at: account.created_at,
            last_login: account.last_login,
            ...(playerData[0] || {})
            // inventory and quests are already in playerData[0]
        };

        console.log('✓ Player data loaded');
        console.log('  - Character slot: 1');
        console.log('  - Inventory type:', typeof player.inventory);
        console.log('  - Inventory length:', player.inventory ? player.inventory.length : 0);
        console.log('  - Inventory preview:', player.inventory ? player.inventory.substring(0, 100) : 'NULL');

        res.json({
            success: true,
            player_data: player
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            error: 'Login failed: ' + error.message
        });
    }
});

module.exports = router;
