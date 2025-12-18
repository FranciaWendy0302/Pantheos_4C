// Main server file - Express REST API + WebSocket
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { testConnection, pool } = require('./config/database');
const authRoutes = require('./routes/auth');
const playerRoutes = require('./routes/player');
const friendRoutes = require('./routes/friends');
const GameServer = require('./websocket/gameServer');
const FriendManager = require('./managers/FriendManager');

const app = express();
const PORT = process.env.PORT || 3000;
const WS_PORT = process.env.WS_PORT || 9000;

// Middleware
app.use(cors());
app.use(express.json());

// API Key verification middleware
const verifyApiKey = (req, res, next) => {
    const apiKey = req.headers['x-api-key'];
    if (apiKey !== process.env.API_KEY) {
        return res.status(401).json({
            success: false,
            error: 'Invalid API key'
        });
    }
    next();
};

// Initialize managers (will be set after GameServer starts)
let friendManager;

// Routes
app.use('/api/auth', verifyApiKey, authRoutes);
app.use('/api/player', verifyApiKey, playerRoutes);
// Friend routes will be added after GameServer initialization

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        players_online: gameServer ? gameServer.getPlayerCount() : 0
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        name: 'Pantheos MMORPG Server',
        version: '1.0.0',
        endpoints: {
            auth: '/api/auth/login, /api/auth/register',
            player: '/api/player/:id, /api/player/save, /api/player/position',
            websocket: `ws://localhost:${WS_PORT}`
        }
    });
});

// Initialize servers
let gameServer;

async function startServer() {
    try {
        // Test database connection
        const dbConnected = await testConnection();
        if (!dbConnected) {
            console.error('Failed to connect to database. Exiting...');
            process.exit(1);
        }

        // Start REST API server
        app.listen(PORT, () => {
            console.log(`✓ REST API server running on port ${PORT}`);
            console.log(`  http://localhost:${PORT}`);
        });

        // Start WebSocket server with database
        gameServer = new GameServer(WS_PORT, pool);
        console.log(`  ws://localhost:${WS_PORT}`);

        // Get FriendManager from GameServer
        friendManager = gameServer.friendManager;

        // Add friend routes after GameServer is initialized
        app.use('/api/friends', verifyApiKey, friendRoutes(pool, friendManager));

        // Load existing parties from database
        const PartyManager = require('./managers/PartyManagerV2');
        await PartyManager.loadAllParties();

        console.log('\n✓ Pantheos server is ready!');
        console.log('  Press Ctrl+C to stop\n');

    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\nShutting down server...');
    process.exit(0);
});

// Start the server
startServer();

module.exports = app;
