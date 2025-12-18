# 🎮 Pantheos MMORPG

A 2D pixel-art MMORPG built with Godot Engine and Node.js backend.

## Features

- ✅ Account-based login system
- ✅ Real-time multiplayer (WebSocket)
- ✅ MySQL database integration
- ✅ Character classes (Swordsman, Mage, Assassin, Support)
- ✅ Trading system
- ✅ Quest system
- ✅ Online/Offline modes
- ✅ Ready for free hosting

## Quick Start

### 1. Install Requirements

- **Node.js** - https://nodejs.org/ (LTS version)
- **MySQL** - XAMPP or standalone
- **Godot Engine** - For game development

### 2. Setup Database

```cmd
# Make sure MySQL is running (XAMPP)
# Import database
mysql -u root < complete_database_setup.sql
```

### 3. Setup Backend Server

```cmd
cd server
setup.bat
```

Edit `server/.env` with your database credentials.

### 4. Start Server

**Option A: Godot Server (Recommended for now)**
```cmd
start_server.bat
```
Uses existing Godot headless server on port 9000

**Option B: Node.js Server (For production later)**
```cmd
cd server
start.bat
```
REST API: http://localhost:3000, WebSocket: ws://localhost:9000

See [SERVER_ARCHITECTURE.md](SERVER_ARCHITECTURE.md) for details.

### 5. Run Game

- Open project in Godot
- Press F5 to run
- Login and connect to server

## Documentation

- **[NODEJS_QUICK_START.txt](NODEJS_QUICK_START.txt)** - Quick reference
- **[NODEJS_MIGRATION_GUIDE.md](NODEJS_MIGRATION_GUIDE.md)** - Complete guide
- **[NEW_FLOW_VISUAL.txt](NEW_FLOW_VISUAL.txt)** - Login flow diagram
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Project organization
- **[server/README.md](server/README.md)** - Server documentation

## Project Structure

```
Pantheos/
├── server/                   # Node.js backend
│   ├── server.js
│   ├── routes/              # REST API
│   └── websocket/           # Multiplayer
├── Network/                  # Godot network scripts
├── 00_Globals/              # Global scripts
├── Enemies/                 # Enemy scripts
├── GUI/                     # UI scripts
├── Levels/                  # Game levels
├── title_scene/             # Login screen
├── website/                 # Website (optional)
├── complete_database_setup.sql
└── project.godot
```

## Technology Stack

- **Game Engine:** Godot 4.x
- **Backend:** Node.js + Express
- **Database:** MySQL
- **Real-time:** WebSocket (ws)
- **Authentication:** Bcrypt

## API Endpoints

### Authentication
- `POST /api/auth/register` - Create account
- `POST /api/auth/login` - Login

### Player Data
- `GET /api/player/:id` - Get player data
- `POST /api/player/save` - Save player data
- `POST /api/player/position` - Update position

### WebSocket
- `ws://localhost:9000` - Real-time multiplayer

## Deployment

Ready for free hosting on:
- **Railway.app** (Recommended)
- **Render.com**
- **Fly.io**

See [NODEJS_MIGRATION_GUIDE.md](NODEJS_MIGRATION_GUIDE.md) for deployment instructions.

## Development

### Start Development Server
```cmd
cd server
npm run dev
```

### Test API
```cmd
curl http://localhost:3000/health
```

### Test WebSocket
Connect to `ws://localhost:9000` from Godot or WebSocket client.

## Game Flow

1. **Create Account** - On website or in-game
2. **Login** - Enter credentials
3. **Server Connection** - Enter server address (Tailscale IP or localhost)
4. **Play** - Real-time multiplayer!

## Contributing

This is a learning project. Feel free to fork and modify!

## License

MIT

## Credits

- **Development Team:** Wendy, Aisa Jeene, Adrian, Gerick
- **Engine:** Godot Engine
- **Assets:** Custom pixel art

---

**Ready to play? Start with [NODEJS_QUICK_START.txt](NODEJS_QUICK_START.txt)!** 🚀
