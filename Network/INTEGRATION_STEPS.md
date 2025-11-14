# Network Integration Steps

## ✅ Already Done

1. ✅ Map-based player visibility system implemented
2. ✅ Quest monster visibility system implemented  
3. ✅ Level transition now notifies network manager

## 🔧 What You Need To Do

### Step 1: Update Your Monster Spawning Code

Find where you spawn monsters in your code and replace it with the network-aware version.

**OLD WAY (everyone sees everything):**
```gdscript
var monster = slime_scene.instantiate()
monster.global_position = spawn_pos
get_tree().current_scene.add_child(monster)
```

**NEW WAY - Normal Monster (everyone can see):**
```gdscript
var monster = QuestMonsterSpawner.spawn_global_monster(
    slime_scene,
    spawn_pos,
    get_tree().current_scene
)
```

**NEW WAY - Quest Monster (only quest owner sees):**
```gdscript
var monster = QuestMonsterSpawner.spawn_quest_monster(
    slime_scene,
    spawn_pos,
    multiplayer.get_unique_id(),  # Current player's ID
    get_tree().current_scene
)
```

### Step 2: Update Quest System

In your quest scripts, when spawning quest-specific monsters:

```gdscript
# In your quest trigger/start function
func start_quest():
    var quest_owner_id = multiplayer.get_unique_id()
    
    # Spawn quest monsters
    for i in range(5):
        var monster = QuestMonsterSpawner.spawn_quest_monster(
            monster_scene,
            spawn_positions[i],
            quest_owner_id,
            get_tree().current_scene
        )
```

### Step 3: Test It

1. **Start the server:** Run `force_restart_server.bat`
2. **Start client 1:** Press F5 in Godot
3. **Start client 2:** Run another instance
4. **Test scenarios:**
   - Both players in same map → should see each other ✓
   - Players in different maps → should NOT see each other ✓
   - Quest monster spawned → only quest owner sees it ✓
   - Normal monster spawned → everyone sees it ✓

## 📝 Common Locations to Update

Look for monster spawning in these places:

1. **Quest scripts** (`quests/` folder)
   - When quest starts
   - When quest objectives spawn enemies

2. **Level/Map scripts** (`Levels/` folder)
   - World monster spawners
   - Enemy spawn points

3. **Enemy spawner nodes**
   - Any custom spawner scripts
   - Timer-based spawners

4. **Event triggers**
   - Boss spawns
   - Wave spawners
   - Ambush triggers

## 🔍 How to Find Your Spawning Code

Search your project for:
- `instantiate()` + enemy/monster scene
- `.add_child()` with enemy nodes
- Any custom spawn functions

## ⚠️ Important Notes

- **Server must be restarted** after any RPC changes
- **Both client and server** must have the same code
- **Map changes** are automatically handled by level transitions
- **Quest monsters** need the owner's peer ID to work correctly

## 📚 See Also

- `Network/example_monster_spawning.gd` - Complete examples
- `Network/USAGE_GUIDE.md` - API reference
- `Network/network_entity.gd` - Visibility system
- `Network/quest_monster_spawner.gd` - Helper functions
