# HUD Icon Buttons Design

## Concept

Instead of a pause menu, create **4 individual icon buttons** on the HUD that directly open their respective panels.

```
Game Screen Layout:
┌─────────────────────────────────────────┐
│  HP/MP Bar          Gold: 1000          │
│                                         │
│                                         │
│         GAMEPLAY AREA                   │
│                                         │
│                                         │
│  [🎒] [🏪] [📜] [⚙️]  ← Icon buttons   │
└─────────────────────────────────────────┘
```

---

## 4 Icon Buttons

### 1. 🎒 Inventory Button
- **Icon**: `inventory.png`
- **Hotkey**: `I` key
- **Action**: Opens inventory panel (full screen overlay)
- **Shows**: Items, equipment, stats

### 2. 🏪 Shop Button
- **Icon**: `shop.png`
- **Hotkey**: `P` key (for Purchase/shoP)
- **Action**: Opens cosmetic shop panel
- **Shows**: Purchasable skins, emotes, effects

### 3. 📜 Quest Button
- **Icon**: `quest.png`
- **Hotkey**: `Q` key
- **Action**: Opens quest log panel
- **Shows**: Active quests, objectives, rewards

### 4. ⚙️ Settings Button
- **Icon**: `settings.png`
- **Hotkey**: `ESC` key
- **Action**: Opens settings panel
- **Shows**: Volume, logout, quit options

---

## Button Placement Options

### Option A: Bottom Center (Recommended)
```
┌─────────────────────────────────────────┐
│                                         │
│         GAMEPLAY                        │
│                                         │
│      [🎒] [🏪] [📜] [⚙️]               │
└─────────────────────────────────────────┘
```

### Option B: Bottom Right
```
┌─────────────────────────────────────────┐
│                                         │
│         GAMEPLAY                        │
│                                         │
│                    [🎒] [🏪] [📜] [⚙️] │
└─────────────────────────────────────────┘
```

### Option C: Right Side (Vertical)
```
┌─────────────────────────────────────┐
│                                 [🎒]│
│         GAMEPLAY                [🏪]│
│                                 [📜]│
│                                 [⚙️]│
└─────────────────────────────────────┘
```

---

## Button Behavior

### Visual States:
1. **Normal**: Icon at 100% opacity
2. **Hover**: Icon glows/scales up 110%
3. **Pressed**: Icon scales down 90%
4. **Active**: Icon has gold border (panel is open)

### Interaction:
- **Click**: Opens panel
- **Click again**: Closes panel
- **ESC key**: Closes any open panel
- **Hotkey**: Toggles panel

---

## Panel Behavior

### When Panel Opens:
- Panel slides in from side or fades in
- Game continues (no pause)
- Other panels close automatically
- Background slightly darkened

### When Panel Closes:
- Panel slides out or fades out
- Icon returns to normal state
- Game fully visible

---

## Implementation Structure

```
PlayerHud (existing)
├── HBoxContainer (NEW - for icon buttons)
│   ├── InventoryButton (TextureButton)
│   ├── ShopButton (TextureButton)
│   ├── QuestButton (TextureButton)
│   └── SettingsButton (TextureButton)
│
└── Panels (NEW - overlay panels)
    ├── InventoryPanel (from pause_menu)
    ├── ShopPanel (NEW)
    ├── QuestPanel (from pause_menu)
    └── SettingsPanel (from pause_menu)
```

---

## Files to Create/Modify

### New Files:
1. `GUI/hud_icon_buttons/hud_icon_buttons.tscn` - Icon button container
2. `GUI/hud_icon_buttons/hud_icon_buttons.gd` - Button logic
3. `GUI/shop_panel/shop_panel.tscn` - NEW shop UI
4. `GUI/shop_panel/shop_panel.gd` - NEW shop logic

### Modified Files:
1. `GUI/player_hud.tscn` - Add icon buttons
2. `GUI/player_hud.gd` - Connect button signals
3. `GUI/pause_menu/pause_menu.gd` - Remove or repurpose

---

## Hotkey Mapping

```gdscript
# In player_hud.gd or input handler
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("inventory"):  # I key
        toggle_inventory()
    elif event.is_action_pressed("shop"):     # P key
        toggle_shop()
    elif event.is_action_pressed("quest"):    # Q key
        toggle_quest()
    elif event.is_action_pressed("settings"): # ESC key
        toggle_settings()
```

---

## Input Actions to Add

Add these to Project Settings → Input Map:

```
inventory: I key
shop: P key
quest: Q key
settings: ESC key
```

---

## Advantages of This Approach

✅ **No pause menu** - Direct access to each function
✅ **Faster navigation** - One click to any panel
✅ **Modern UI** - Clean, icon-based design
✅ **Hotkey support** - Keyboard shortcuts for power users
✅ **Game continues** - No need to pause
✅ **Mobile-friendly** - Large touch targets

---

## Next Steps

1. ✅ Icons added to `GUI/pause_menu/icons/`
2. ⏳ Create icon button container scene
3. ⏳ Add buttons to PlayerHud
4. ⏳ Create/adapt panel scenes
5. ⏳ Connect button signals
6. ⏳ Add hotkey support
7. ⏳ Create shop panel (NEW)
8. ⏳ Test all functionality

---

**Ready to implement?** Let me know and I'll start creating the icon button system!
