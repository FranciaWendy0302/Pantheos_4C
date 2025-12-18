# Setup God Interactions in Safezone - Step by Step Guide

## Overview
This guide will help you add interaction functionality to all 8 god sprites in safezone.tscn so players can talk to them and receive quests.

## What You'll Do
- Attach the `god_npc_interaction.gd` script to each god sprite
- Add Area2D nodes for player detection
- Configure each god's type and portrait

## Step-by-Step Instructions

### 1. Open the Scene
1. Open Godot Editor
2. Navigate to `Levels/final map/scene/safezone.tscn`
3. Open the scene

### 2. Setup Athena

1. In the Scene tree, find and select the **Athena** Sprite2D node
2. In the Inspector panel, scroll to the bottom
3. Click the **Script** dropdown → **Load**
4. Navigate to `res://NPCs/god_npc_interaction.gd` and select it
5. In the Inspector, you'll now see exported variables:
   - Set **God Type** to `ATHENA (1)`
   - Set **God Portrait Path** to: `res://GUI/god_selection/sprites/athena.png`
6. Right-click **Athena** node → **Add Child Node**
7. Search for **Area2D** and create it
8. Rename it to **InteractionArea**
9. Right-click **InteractionArea** → **Add Child Node**
10. Search for **CollisionShape2D** and create it
11. Select the **CollisionShape2D** node
12. In the Inspector, click **Shape** → **New CircleShape2D**
13. Click the CircleShape2D to expand it
14. Set **Radius** to `50`

### 3. Setup Zeus

Repeat the same process for **Zeus**:
- Script: `res://NPCs/god_npc_interaction.gd`
- God Type: `ZEUS (2)`
- God Portrait Path: `res://GUI/god_selection/sprites/zeus.png`
- Add InteractionArea → CollisionShape2D → CircleShape2D (radius 50)

### 4. Setup Venus

- Script: `res://NPCs/god_npc_interaction.gd`
- God Type: `VENUS (3)`
- God Portrait Path: `res://GUI/god_selection/sprites/venus.png`
- Add InteractionArea → CollisionShape2D → CircleShape2D (radius 50)

### 5. Setup Asclepius

- Script: `res://NPCs/god_npc_interaction.gd`
- God Type: `ASCLEPIUS (4)`
- God Portrait Path: `res://GUI/god_selection/sprites/asclepius.png`
- Add InteractionArea → CollisionShape2D → CircleShape2D (radius 50)

### 6. Setup Hades

- Script: `res://NPCs/god_npc_interaction.gd`
- God Type: `HADES (5)`
- God Portrait Path: `res://GUI/god_selection/sprites/hades.png`
- Add InteractionArea → CollisionShape2D → CircleShape2D (radius 50)

### 7. Setup Ares

- Script: `res://NPCs/god_npc_interaction.gd`
- God Type: `ARES (6)`
- God Portrait Path: `res://GUI/god_selection/sprites/Ares.png` (note capital A)
- Add InteractionArea → CollisionShape2D → CircleShape2D (radius 50)

### 8. Setup Titan

- Script: `res://NPCs/god_npc_interaction.gd`
- God Type: `TITAN (7)`
- God Portrait Path: `res://GUI/god_selection/sprites/titan.png`
- Add InteractionArea → CollisionShape2D → CircleShape2D (radius 50)

### 9. Setup Gigantes

- Script: `res://NPCs/god_npc_interaction.gd`
- God Type: `GIGANTES (8)`
- God Portrait Path: `res://GUI/god_selection/sprites/gigantes.png`
- Add InteractionArea → CollisionShape2D → CircleShape2D (radius 50)

### 10. Save the Scene

1. Press **Ctrl+S** to save
2. Close the scene

## Testing

1. Run the game
2. Create a character and select a god (e.g., Athena)
3. Enter the safezone map
4. Walk near Athena's sprite
5. You should see **"Press G to talk"** appear
6. Press **G** to interact
7. Athena should greet you and unlock your god skill
8. Try walking to other gods (e.g., Zeus)
9. They should reject you since you're not their champion

## Quick Reference - God Types

```
ATHENA = 1
ZEUS = 2
VENUS = 3
ASCLEPIUS = 4
HADES = 5
ARES = 6
TITAN = 7
GIGANTES = 8
```

## Troubleshooting

### "Press G" doesn't appear
- Check that InteractionArea and CollisionShape2D are properly added
- Verify CircleShape2D radius is set to 50
- Make sure the Area2D is named "InteractionArea"

### Nothing happens when pressing G
- Check that "interact" action is mapped in Project Settings → Input Map
- Verify the script is attached to the god sprite
- Check the Output console for errors

### Wrong dialogue appears
- Double-check the god_type value matches the god name
- Verify you selected the correct enum value (number)

### Script errors
- Make sure GodManager is in the autoload list (Project Settings → Autoload)
- Check that all god portrait paths are correct

## What This System Does

- **Player Detection**: Area2D detects when player enters range
- **Visual Feedback**: Shows "Press G to talk" label
- **God Recognition**: Checks if player's selected god matches the NPC
- **Dialogue**: Shows appropriate dialogue based on god relationship
- **Skill Unlock**: Automatically unlocks god skill on first interaction (simplified quest)
- **Rejection**: Other gods will reject players who serve different gods

## Time Estimate

- About 2-3 minutes per god
- Total: 15-25 minutes for all 8 gods

## Need Help?

If you encounter issues:
1. Check the Output console in Godot for error messages
2. Verify all file paths are correct
3. Make sure GodManager autoload is configured
4. Test with one god first before doing all 8
