# Icon Buttons Implementation Plan

## Current Status
✅ Icons added to `GUI/pause_menu/icons/`:
- inventory.png
- quest.png
- settings.png
- shop.png

## Goal
Remove the pause menu (ESC key) and create **4 individual icon buttons** on the HUD that directly open their panels.

---

## Implementation Steps

### Step 1: Create Icon Button Container Scene
Create: `GUI/hud_icon_buttons/hud_icon_buttons.tscn`

Structure:
```
HBoxContainer (hud_icon_buttons)
├── InventoryButton (TextureButton)
├── ShopButton (TextureButton)
├── QuestButton (TextureButton)
└── SettingsButton (TextureButton)
```

### Step 2: Create Icon Button Script
Create: `GUI/hud_icon_buttons/hud_icon_buttons.gd`

Functions:
- `_ready()` - Setup buttons, connect signals
- `_on_inventory_pressed()` - Open inventory panel
- `_on_shop_pressed()` - Open shop panel
- `_on_quest_pressed()` - Open quest panel
- `_on_settings_pressed()` - Open settings panel
- `_unhandled_input()` - Handle hotkeys (I, P, Q, ESC)

### Step 3: Add to PlayerHud
Modify: `GUI/player_hud/player_hud.tscn`

Add icon buttons container to bottom-center of screen.

### Step 4: Create/Adapt Panel Scenes

#### Inventory Panel
- Use existing from `GUI/pause_menu/pause_menu.tscn` (Inventory tab)
- Make it a standalone overlay panel

#### Quest Panel
- Use existing from `GUI/pause_menu/pause_menu.tscn` (Quest tab)
- Make it a standalone overlay panel

#### Settings Panel
- Use existing from `GUI/pause_menu/pause_menu.tscn` (System tab)
- Make it a standalone overlay panel

#### Shop Panel (NEW)
- Create: `GUI/shop_panel/shop_panel.tscn`
- Create: `GUI/shop_panel/shop_panel.gd`
- Design cosmetic shop UI

### Step 5: Remove/Disable Pause Menu
Modify: `GUI/pause_menu/pause_menu.gd`

Option A: Delete pause menu entirely
Option B: Disable ESC key, keep for reference

### Step 6: Add Input Actions
Add to Project Settings → Input Map:
- `open_inventory` → I key
- `open_shop` → P key
- `open_quest` → Q key
- `open_settings` → ESC key

### Step 7: Test
- [ ] Click each icon button
- [ ] Test hotkeys (I, P, Q, ESC)
- [ ] Verify panels open/close correctly
- [ ] Verify only one panel open at a time
- [ ] Test in-game (not paused)

---

## Button Specifications

### Size & Position
- **Button Size**: 48x48 pixels
- **Icon Size**: 32x32 pixels (centered in button)
- **Spacing**: 8px between buttons
- **Position**: Bottom-center of screen, 20px from bottom

### Visual States
```gdscript
# Normal
button.modulate = Color(1, 1, 1, 0.8)

# Hover
button.modulate = Color(1, 1, 1, 1.0)
button.scale = Vector2(1.1, 1.1)

# Pressed
button.scale = Vector2(0.9, 0.9)

# Active (panel open)
button.modulate = Color(1, 0.84, 0, 1)  # Gold
```

---

## Panel Behavior

### Opening:
1. Close any other open panel
2. Darken background (ColorRect overlay)
3. Slide panel in from side or fade in
4. Set button to "active" state
5. Game continues (no pause)

### Closing:
1. Slide panel out or fade out
2. Remove background overlay
3. Set button to "normal" state
4. Return focus to game

---

## File Structure

```
GUI/
├── hud_icon_buttons/          # NEW
│   ├── hud_icon_buttons.tscn
│   └── hud_icon_buttons.gd
│
├── inventory_panel/           # Extracted from pause_menu
│   ├── inventory_panel.tscn
│   └── inventory_panel.gd
│
├── quest_panel/               # Extracted from pause_menu
│   ├── quest_panel.tscn
│   └── quest_panel.gd
│
├── settings_panel/            # Extracted from pause_menu
│   ├── settings_panel.tscn
│   └── settings_panel.gd
│
├── shop_panel/                # NEW
│   ├── shop_panel.tscn
│   └── shop_panel.gd
│
└── pause_menu/                # DEPRECATED or REMOVED
    └── (old files)
```

---

## Next Actions

**What I'll do:**
1. Create icon button container scene
2. Create icon button script
3. Extract panels from pause menu
4. Create shop panel
5. Wire everything together
6. Test functionality

**What you need to decide:**
1. Button position preference (bottom-center, bottom-right, or right-side)?
2. Keep or delete pause menu files?
3. What cosmetics to sell in shop?

---

**Ready to start implementation?** Let me know your button position preference and I'll begin!
