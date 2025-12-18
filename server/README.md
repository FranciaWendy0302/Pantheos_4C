# Pantheos Node.js Backend Server

Complete Node.js backend with REST API and WebSocket for real-time multiplayer.

## Features

- ✅ REST API for authentication and player data
- ✅ WebSocket server for real-time multiplayer
- ✅ MySQL database integration
- ✅ Bcrypt password hashing
- ✅ CORS enabled for Godot
- ✅ API key authentication
- ✅ Real-time player synchronization

## Quick Start

### 1. Install Dependencies

```bash
cd server
npm install
```

### 2. Configure Environment

```bash
# Copy example env file
copy .env.example .env

# Edit .env with your settings
# DB_HOST=localhost
# DB_USER=root
# DB_PASSWORD=
# DB_NAME=mmorpg_game
```

### 3. Setup Database

Make sure MySQL is running and database is created:
```bash
# Run from project root
C:\xampp\php\php.exe import_database.php
```

### 4. Start Server

```bash
npm start
```

Server will start on:
- REST API: http://localhost:3000
- WebSocket: ws://localhost:9000

## API Endpoints

### Authentication

**POST /api/auth/register**
```json
{
  "username": "player1",
  "password": "password123",
  "nickname": "Hero"
}
```

**POST /api/auth/login**
```json
{
  "username": "player1",
  "password": "password123"
}
```

### Player Data

**GET /api/player/:playerId**
- Get player data by ID

**POST /api/player/save**
```json
{
  "player_id": 1,
  "level": 5,
  "xp": 1000,
  "gold": 500,
  "hp": 100,
  "max_hp": 100,
  "last_map": "tutorial",
  "last_position_x": 100,
  "last_position_y": 200,
  "inventory": [],
  "quests": [],
  "character_class": "Swordsman"
}
```

**POST /api/player/position**
```json
{
  "player_id": 1,
  "x": 100,
  "y": 200,
  "map": "tutorial"
}
```

## WebSocket Protocol

### Client → Server

**Join Game**
```json
{
  "type": "join",
  "data": {
    "player_id": 1,
    "nickname": "Hero",
    "character_class": "Swordsman"
  }
}
```

**Move**
```json
{
  "type": "move",
  "data": {
    "x": 100,
    "y": 200
  }
}
```

**Chat**
```json
{
  "type": "chat",
  "data": {
    "message": "Hello!"
  }
}
```

**Attack**
```json
{
  "type": "attack",
  "data": {
    "target_id": 2,
    "damage": 10
  }
}
```

### Server → Client

**Existing Players**
```json
{
  "type": "players",
  "data": [
    {
      "player_id": 2,
      "nickname": "Player2",
      "character_class": "Mage",
      "x": 50,
      "y": 50,
      "hp": 100
    }
  ]
}
```

**Player Joined**
```json
{
  "type": "player_joined",
  "data": {
    "player_id": 3,
    "nickname": "Player3",
    "character_class": "Archer",
    "x": 0,
    "y": 0,
    "hp": 100
  }
}
```

**Player Moved**
```json
{
  "type": "player_moved",
  "data": {
    "player_id": 2,
    "x": 100,
    "y": 150
  }
}
```

**Player Left**
```json
{
  "type": "player_left",
  "data": {
    "player_id": 2
  }
}
```

## Development

### Run with auto-reload
```bash
npm run dev
```

### Test server
```bash
npm test
```

## Project Structure

```
server/
├── config/
│   └── database.js          # MySQL connection
├── routes/
│   ├── auth.js              # Login/Register
│   └── player.js            # Player data
├── websocket/
│   └── gameServer.js        # WebSocket server
├── server.js                # Main server
├── package.json
├── .env                     # Configuration
└── README.md
```

## Environment Variables

```env
# Database
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=mmorpg_game

# Server
PORT=3000
WS_PORT=9000

# Security
API_KEY=your_secret_api_key_here
JWT_SECRET=your_jwt_secret

# Environment
NODE_ENV=development
```

## Deployment

### Free Hosting Options

1. **Railway.app** (Recommended)
   - Free tier available
   - Supports Node.js + MySQL
   - Easy deployment

2. **Render.com**
   - Free tier available
   - PostgreSQL free tier
   - Auto-deploy from Git

3. **Fly.io**
   - Free tier available
   - Good for WebSocket
   - Global deployment

### Deploy to Railway

1. Create account at railway.app
2. Create new project
3. Add MySQL database
4. Deploy Node.js app
5. Set environment variables
6. Done!

## Security Notes

- Change API_KEY in production
- Use strong JWT_SECRET
- Enable HTTPS in production
- Rate limit API endpoints
- Validate all inputs

## Troubleshooting

### Database connection fails
- Check MySQL is running
- Verify credentials in .env
- Check database exists

### WebSocket won't connect
- Check port 9000 is not in use
- Verify firewall allows connections
- Check WS_PORT in .env

### API returns 401
- Verify X-API-Key header
- Check API_KEY in .env matches

## License

MIT
