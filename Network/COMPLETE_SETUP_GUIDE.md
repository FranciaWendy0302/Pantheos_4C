# Complete MMORPG Network Setup Guide

## ✅ What's Been Implemented

### 1. Server-Authoritative Architecture
- **EntityManager**: Central system for all networked entities
- **Server spawns everything**: Monsters, NPCs, items
- **Clients render only**: What server tells them
- **Server validates combat**: All damage goes through server

### 2. Map-Based Visibility
- Players only see each other in the same map
- Entities are map-specific
- Automatic cleanup on map change

### 3. Quest Monster System
- Quest monsters only visible to quest owner
- Normal monsters visible to everyone in map
- Server tracks ownership

## 🚀 How to Use

### Step 1: Add Monster Spawners to Your Maps

Open any map scene (e.g., `Levels/Area01/area_01.tscn`) and add spawners:

1. **Add Node** → **Node2D** → **ServerMonsterSpawner** (or instance `res://Network/server_monster_spawner.tscn`)
2. **Configure the spawner:**
   - `Monster Scene`: Select your monster (e.g., `res://Enemies/Slime/slime.tscn`)
   - `Spawn Count`: How many monsters (e.g., 3)
   - `Spawn Radius`: Area around spawner (e.g., 100)
   - `Respawn Time`: Seconds before respawn (e.g., 30)
   - `Is Quest Monster`: false for normal, true for quest-specific
   - `Quest Owner Peer Id`: -1 for normal, player ID for quest

3. **Position the spawner** where you want monsters to appear

### Step 2: Spawn Quest Monsters from Code

In your quest script:

```gdscript
func start_quest():
	# Only server spawns
	if not multiplayer.is_server():
		return
	
	var quest_owner_id = get_quest_owner_peer_id()
	var map_path = get_tree().current_scene.scene_file_path
	
	# Spawn 5 quest slimes
	for i in range(5):
		var spawn_pos = get_spawn_position(i)
		
		EntityManager.server_spawn_entity(
			"res://Enemies/Slime/slime.tscn",
			spawn_pos,
			map_path,
			EntityManager.EntityType.MONSTER,
			EntityManager.VisibilityRule.OWNER_ONLY,
			quest_owner_id,
			{
				"hp": 50,
				"max_hp": 50,
				"quest_id": "kill_5_slimes"
			}
		)
```

### Step 3: Test the System

1. **Start Server:**
   ```
   force_restart_server.bat
   ```

2. **Start Client 1** (in Godot editor):
   - Press F5
   - Connect to server

3. **Start Client 2** (separate instance):
   - Run exported game or another Godot instance
   - Connect to server

4. **Test Scenarios:**
   - ✅ Both players in same map → see each other
   - ✅ Both players see same monsters
   - ✅ Both can attack same monster
   - ✅ Monster HP syncs across clients
   - ✅ Players in different maps → don't see each other
   - ✅ Quest monsters → only quest owner sees them

## 📋 Quick Reference

### Spawn Normal Monster (Server-side)
```gdscript
EntityManager.server_spawn_entity(
	"res://Enemies/Slime/slime.tscn",
	Vector2(100, 100),
	get_tree().current_scene.scene_file_path,
	EntityManager.EntityType.MONSTER,
	EntityManager.VisibilityRule.MAP_ONLY,
	-1,  # No specific owner
	{"hp": 100, "max_hp": 100}
)
```

### Spawn Quest Monster (Server-side)
```gdscript
EntityManager.server_spawn_entity(
	"res://Enemies/goblin/goblin.tscn",
	Vector2(200, 200),
	get_tree().current_scene.scene_file_path,
	EntityManager.EntityType.MONSTER,
	EntityManager.VisibilityRule.OWNER_ONLY,
	player_peer_id,  # Only this player sees it
	{"hp": 150, "max_hp": 150, "quest_id": "my_quest"}
)
```

### Attack Entity (Client-side)
```gdscript
# In your weapon/attack code
var entity_id = enemy.get_meta("entity_id", -1)
if entity_id != -1:
	EntityManager.client_attack_entity(entity_id, damage)
```

## 🔧 Integration Checklist

- [x] EntityManager added as autoload
- [x] Enemy script updated with network support
- [x] Level transitions notify map changes
- [x] Server-side spawner created
- [ ] **YOU NEED TO DO:** Add spawners to your maps
- [ ] **YOU NEED TO DO:** Update quest system to use EntityManager
- [ ] **YOU NEED TO DO:** Test with multiple clients

## 🎮 For Tailscale VPN Testing

1. **Server Machine:**
   - Note your Tailscale IP (e.g., `100.x.x.x`)
   - Run `force_restart_server.bat`
   - Server listens on port 9000

2. **Client Machines:**
   - Connect to server using Tailscale IP
   - In your connection UI, use: `100.x.x.x:9000`

3. **Firewall:**
   - Tailscale handles this automatically
   - No port forwarding needed

## 🐛 Troubleshooting

**Problem:** "RPC checksum mismatch"
- **Solution:** Restart BOTH server and all clients

**Problem:** "Monsters not spawning"
- **Solution:** Check server console for errors
- Make sure spawner is in the map scene
- Verify monster scene path is correct

**Problem:** "Can't attack monsters"
- **Solution:** Make sure enemy has `entity_id` meta set
- Check EntityManager is loaded as autoload

**Problem:** "Players see each other across maps"
- **Solution:** Restart server with updated code
- Check level transitions call `NetworkManager.notify_map_changed()`

## 📚 Architecture Overview

```
SERVER (Authoritative)
├── EntityManager
│   ├── Spawns all entities
│   ├── Validates all combat
│   ├── Tracks entity state
│   └── Broadcasts to clients
├── ServerMonsterSpawner (in maps)
│   ├── Spawns monsters via EntityManager
│   └── Handles respawning
└── NetworkManager
    ├── Handles player connections
    ├── Tracks player maps
    └── Syncs player positions

CLIENT (Rendering Only)
├── EntityManager
│   ├── Receives entity spawns
│   ├── Renders entities
│   └── Sends attack requests
├── NetworkManager
│   ├── Sends player position
│   └── Receives remote players
└── Enemy instances
    ├── Visual representation only
    └── Sends damage to server
```

## 🎯 Next Steps

1. **Add spawners to all your maps**
2. **Update quest system** to spawn quest monsters via EntityManager
3. **Test with friends** over Tailscale
4. **Add more features:**
   - Loot drops (server-side)
   - NPC spawning
   - Party system
   - Trading system
   - Chat system

The foundation is complete - now you just need to populate your world!
