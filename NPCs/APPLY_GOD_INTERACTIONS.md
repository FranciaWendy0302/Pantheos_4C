# How to Add God Interactions to Safezone

## Quick Setup (Manual - Recommended)

1. Open `Levels/final map/scene/safezone.tscn` in Godot Editor

2. For EACH god sprite (Athena, Zeus, Venus, Asclepius, Hades, Ares, Titan, Gigantes):
   
   a. Select the god Sprite2D node
   
   b. In the Inspector, click "Attach Script"
   
   c. Choose `res://NPCs/god_npc_interaction.gd`
   
   d. Set the exported variables:
      - `god_type`: Select the matching god from dropdown
      - `god_portrait_path`: Enter the sprite path
   
   e. Add an Area2D child node named "InteractionArea"
      - Add CollisionShape2D child to Area2D
      - Set shape to CircleShape2D with radius 50

3. Save the scene

## God Configuration Reference

```
Athena:
  - god_type: ATHENA (1)
  - god_portrait_path: res://GUI/god_selection/sprites/athena.png

Zeus:
  - god_type: ZEUS (2)
  - god_portrait_path: res://GUI/god_selection/sprites/zeus.png

Venus:
  - god_type: VENUS (3)
  - god_portrait_path: res://GUI/god_selection/sprites/venus.png

Asclepius:
  - god_type: ASCLEPIUS (4)
  - god_portrait_path: res://GUI/god_selection/sprites/asclepius.png

Hades:
  - god_type: HADES (5)
  - god_portrait_path: res://GUI/god_selection/sprites/hades.png

Ares:
  - god_type: ARES (6)
  - god_portrait_path: res://GUI/god_selection/sprites/Ares.png

Titan:
  - god_type: TITAN (7)
  - god_portrait_path: res://GUI/god_selection/sprites/titan.png

Gigantes:
  - god_type: GIGANTES (8)
  - god_portrait_path: res://GUI/god_selection/sprites/gigantes.png
```

## Testing

1. Run the game and select a god during character creation
2. Enter the safezone map
3. Walk near your god's sprite
4. You should see "Press G to talk"
5. Press G to interact
6. Your god should greet you and unlock your skill
7. Try talking to other gods - they should reject you

## What This Does

- Adds interaction detection to each god sprite
- Shows "Press G to talk" when player is nearby
- When player presses G:
  - If it's their god: Shows welcome dialogue and unlocks skill
  - If it's not their god: Shows rejection dialogue
- Auto-unlocks god skill on first interaction (simplified quest system)

## Troubleshooting

- **"Press G" doesn't appear**: Check that Area2D and CollisionShape2D are properly set up
- **Nothing happens when pressing G**: Make sure "interact" action is mapped in Input Map
- **Wrong dialogue**: Verify god_type is set correctly for each sprite
- **Script errors**: Check that GodManager autoload is properly configured
