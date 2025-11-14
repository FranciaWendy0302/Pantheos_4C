# Network System Usage Guide

## Map-Based Player Visibility

Players now only see each other when they're in the same map/scene.

### When changing maps, call this:
```gdscript
# In your scene transition code
NetworkManager.notify_map_changed(new_scene.scene_file_path)
```

## Quest-Specific Monsters

### Spawning a quest monster (only quest owner can see):
```gdscript
# Example: Spawn a monster for a specific player's quest
var monster_scene = preload("res://Enemies/slime.tscn")
var quest_owner_id = multiplayer.get_unique_id()  # Current player's ID

var monster = QuestMonsterSpawner.spawn_quest_monster(
	monster_scene,
	Vector2(100, 100),  # Position
	quest_owner_id,     # Only this player sees it
	get_tree().current_scene  # Parent node
)
```

### Spawning a normal monster (everyone can see and attack):
```gdscript
# Example: Spawn a normal world monster
var monster_scene = preload("res://Enemies/slime.tscn")

var monster = QuestMonsterSpawner.spawn_global_monster(
	monster_scene,
	Vector2(100, 100),  # Position
	get_tree().current_scene  # Parent node
)
```

## Manual NetworkEntity Setup

If you want to add network visibility to an existing monster:

```gdscript
# Add to your monster scene or script
var net_entity = NetworkEntity.new()
net_entity.visibility_mode = NetworkEntity.VisibilityMode.OWNER_ONLY
net_entity.owner_peer_id = some_player_id
monster.add_child(net_entity)
```

## Visibility Modes

- `GLOBAL`: Everyone can see (normal monsters, NPCs)
- `OWNER_ONLY`: Only the owner can see (quest-specific monsters)
- `PARTY_ONLY`: Only party members can see (not yet implemented)
