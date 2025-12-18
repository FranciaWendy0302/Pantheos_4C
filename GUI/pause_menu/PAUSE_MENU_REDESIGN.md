# Pause Menu Redesign - Icon-Based UI

## Overview
Redesigning the pause menu to use individual icon buttons instead of tabs for a cleaner, more modern interface.

## New Layout

### Icon Buttons (Top or Side Bar)
```
┌─────────────────────────────────────┐
│  [🎒]  [🏪]  [📜]  [⚙️]  [❌]      │  ← Icon buttons
├─────────────────────────────────────┤
│                                     │
│         CONTENT AREA                │
│     (Shows selected panel)          │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

## 4 Main Panels

### 1. 🎒 Inventory Panel
- **Icon**: Backpack/bag
- **Content**: 
  - Player inventory grid
  - Item details/description
  - Equipment slots
  - Item stats preview
  - Arrow/bomb count display

### 2. 🏪 Shop Panel (NEW)
- **Icon**: Shopping cart/store
- **Content**:
  - Cosmetic items for purchase
  - Real money transactions
  - Character skins
  - Weapon skins
  - Emotes/animations
  - Preview system
  - Purchase confirmation

### 3. 📜 Quest Panel
- **Icon**: Scroll/checklist
- **Content**:
  - Active quests list
  - Quest objectives
  - Quest rewards
  - Completed quests
  - Quest tracking toggle

### 4. ⚙️ Settings Panel
- **Icon**: Gear
- **Content**:
  - Volume controls (Master, Music, SFX)
  - Mute button
  - Change Account button (online mode only)
  - Quit to Title button
  - Quit Game button
  - Graphics settings (optional)
  - Keybindings (optional)

## Icon Specifications

### Size & Style
- **Icon Size**: 64x64 pixels (or 128x128 for HD)
- **Style**: Flat design with subtle shadows
- **Colors**: 
  - Default: Light gray (#CCCCCC)
  - Hover: White (#FFFFFF)
  - Selected: Gold/Yellow (#FFD700)
  - Disabled: Dark gray (#666666)

### Icon Sources
You can use:
1. **Free icon packs**: Font Awesome, Material Icons, Feather Icons
2. **Game asset stores**: itch.io, Unity Asset Store, OpenGameArt
3. **Custom creation**: Design in Figma, Inkscape, or Photoshop

## Recommended Icon Files

Create these icon files in `GUI/pause_menu/icons/`:

```
icons/
├── inventory_icon.png       # 🎒 Backpack
├── inventory_icon_hover.png
├── inventory_icon_active.png
├── shop_icon.png            # 🏪 Shopping cart
├── shop_icon_hover.png
├── shop_icon_active.png
├── quest_icon.png           # 📜 Scroll
├── quest_icon_hover.png
├── quest_icon_active.png
├── settings_icon.png        # ⚙️ Gear
├── settings_icon_hover.png
├── settings_icon_active.png
└── close_icon.png           # ❌ Close/X
```

## Implementation Plan

### Phase 1: UI Structure
1. Remove TabContainer
2. Add HBoxContainer for icon buttons
3. Create 4 panel containers (one for each section)
4. Add close button

### Phase 2: Icon Buttons
1. Create TextureButton nodes for each icon
2. Add hover/pressed states
3. Connect button signals
4. Add tooltips

### Phase 3: Shop Panel (NEW)
1. Create shop UI layout
2. Add cosmetic item grid
3. Implement purchase system
4. Add payment integration (Stripe, PayPal, etc.)
5. Add preview system

### Phase 4: Polish
1. Add transition animations
2. Add sound effects
3. Test all functionality
4. Balance layout for different screen sizes

## Shop System Requirements

### Database Schema (NEW)
```sql
-- Cosmetic items table
CREATE TABLE cosmetic_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- 'skin', 'weapon_skin', 'emote', etc.
    price_usd DECIMAL(10,2),
    image_path VARCHAR(255),
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Player purchases table
CREATE TABLE player_cosmetics (
    id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    cosmetic_id INT NOT NULL,
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES accounts(id),
    FOREIGN KEY (cosmetic_id) REFERENCES cosmetic_items(id),
    UNIQUE KEY unique_purchase (player_id, cosmetic_id)
);
```

### API Endpoints (NEW)
```javascript
// Get available cosmetics
GET /api/shop/cosmetics

// Purchase cosmetic
POST /api/shop/purchase
{
    "player_id": 1,
    "cosmetic_id": 5,
    "payment_token": "stripe_token_here"
}

// Get player's owned cosmetics
GET /api/shop/owned/:playerId
```

## File Structure

```
GUI/pause_menu/
├── pause_menu.tscn          # Main scene (updated)
├── pause_menu.gd            # Main script (updated)
├── icons/                   # NEW folder for icons
│   ├── inventory_icon.png
│   ├── shop_icon.png
│   ├── quest_icon.png
│   └── settings_icon.png
├── panels/                  # NEW folder for panel scenes
│   ├── inventory_panel.tscn
│   ├── shop_panel.tscn      # NEW
│   ├── quest_panel.tscn
│   └── settings_panel.tscn
└── PAUSE_MENU_REDESIGN.md  # This file
```

## Benefits of Icon-Based Design

✅ **Cleaner UI** - Less visual clutter
✅ **Faster Navigation** - One click to any section
✅ **Modern Look** - Matches contemporary game UIs
✅ **Mobile-Friendly** - Works well on touch screens
✅ **Scalable** - Easy to add more sections later
✅ **Intuitive** - Icons are universally understood

## Next Steps

1. **Gather/Create Icons** - Find or design the 4 main icons
2. **Update pause_menu.tscn** - Replace TabContainer with icon buttons
3. **Create Shop Panel** - Build the new cosmetic shop UI
4. **Implement Shop Backend** - Add database tables and API endpoints
5. **Test & Polish** - Ensure everything works smoothly

---

**Status**: Design Complete - Ready for Implementation
