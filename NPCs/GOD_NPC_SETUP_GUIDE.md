# 🏛️ God NPC Setup Guide

## How to Add God Quest Givers to Safezone

### Step 1: Create God NPC Scene

For each god, create an NPC in the safezone:

1. **Open safezone.tscn** (`Levels/final map/scene/safezone.tscn`)

2. **Add StaticBody2D node:**
   - Right-click in scene tree
   - Add Child Node → StaticBody2D
   - Name it: "AthenaQuestGiver" (or god name)

3. **Add Sprite2D:**
   - Add child to StaticBody2D → Sprite2D
   - In Inspector, set Texture to god sprite PNG
   - Adjust scale (e.g., 2.0, 2.0)

4. **Add CollisionShape2D:**
   - Add child to StaticBody2D → CollisionShape2D
   - Set Shape → RectangleShape2D
   - Adjust size to match sprite

5. **Add InteractionArea (Area2D):**
   - Add child to StaticBody2D → Area2D
   - Name it: "InteractionArea"
   - Add child → CollisionShape2D
   - Set Shape → CircleShape2D
   - Set radius: 50-100 (interaction range)

6. **Add InteractionLabel:**
   - Add child to StaticBody2D → Label
   - Name it: "InteractionLabel"
   - Set text: "Press G to talk"
   - Center the label above sprite
   - Set modulate to make it visible

7. **Attach Script:**
   - Select the StaticBody2D
   - Attach script: `NPCs/god_quest_giver.gd`
   - In Inspector, set:
     - `God Type`: Choose god (Athena, Zeus, etc.)
     - `God Sprite Path`: Path to god PNG

8. **Position in Safezone:**
   - Move the NPC to desired location
   - Arrange all 8 gods in a circle or line

---

## God Sprite Paths

Use these paths for each god:

```gdscript
Athena:     "res://GUI/god_selection/sprites/athena.png"
Zeus:       "res://GUI/god_selection/sprites/zeus.png"
Venus:      "res://GUI/god_selection/sprites/venus.png"
Asclepius:  "res://GUI/god_selection/sprites/asclepius.png"
Hades:      "res://GUI/god_selection/sprites/hades.png"
Ares:       "res://GUI/god_selection/sprites/ares.png"
Titan:      "res://GUI/god_selection/sprites/titan.png"
Gigantes:   "res://GUI/god_selection/sprites/gigantes.png"
```

---

## Quick Setup (All 8 Gods)

### Recommended Layout in Safezone:

```
        Athena    Zeus
          
Venus                 Asclepius

        [SPAWN]

Hades                 Ares

        Titan    Gigantes
```

### Position Coordinates (Example):

- **Athena:** (400, 200)
- **Zeus:** (600, 200)
- **Venus:** (300, 350)
- **Asclepius:** (700, 350)
- **Hades:** (300, 550)
- **Ares:** (700, 550)
- **Titan:** (400, 700)
- **Gigantes:** (600, 700)

---

## How It Works

### Player Interaction:
1. Player walks near god NPC
2. "Press G to talk" appears
3. Player presses G
4. Dialogue shows with god's sprite
5. Quest objectives displayed
6. Player accepts quest
7. **God skill unlocks immediately** (simplified)
8. Notification shows skill unlocked

### Dialogue Content:
- Uses quest data from `quests/god_quests/[god]_chapter1.gd`
- Shows god's personality
- Displays quest objectives
- Shows rewards

### Smart Detection:
- Only YOUR god gives you the quest
- Other gods reject you ("You're not my champion")
- Already completed? God acknowledges your power

---

## Testing

1. **Place all 8 god NPCs** in safezone
2. **Start game** with a character
3. **Walk to your god's NPC**
4. **Press G** to interact
5. **Read dialogue** and accept quest
6. **Skill unlocks** immediately
7. **Press R** to test skill!

---

## Customization

### Change Interaction Key:
In `god_quest_giver.gd`, line 35:
```gdscript
if player_in_range and Input.is_action_just_pressed("interact"):
```

### Change Interaction Range:
Adjust InteractionArea CircleShape2D radius (50-150)

### Change Sprite Scale:
In `god_quest_giver.gd`, line 30:
```gdscript
sprite.scale = Vector2(2.0, 2.0)  # Make bigger/smaller
```

### Add Name Labels:
Add a Label node above each NPC showing god name

---

## Alternative: Batch Create Script

If you want to create all 8 NPCs programmatically, I can create a script that spawns them all at once!

---

## Troubleshooting

### "Press G" not showing:
- Check InteractionArea exists
- Check CollisionShape2D in InteractionArea
- Check player has collision layer

### Dialogue not showing:
- Check DialogSystem exists
- Check god_sprite_path is set
- Check quest file exists

### Skill not unlocking:
- Check GodManager.get_selected_god() returns correct god
- Check god_type matches player's god
- Check GodSkills node exists on player

---

## Next Steps

After setting up NPCs:
1. Add GodSkills node to Player scene
2. Test interaction with each god
3. Test skill activation (R key)
4. Add visual polish (name labels, effects)

---

**Your safezone will become a divine temple where players meet their gods!** 🏛️⚡
