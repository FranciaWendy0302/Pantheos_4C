# Pause Menu Icon Requirements

## 4 Required Icons

### 1. 🎒 Inventory Icon
**Purpose**: Access player inventory
**Suggested Designs**:
- Backpack
- Bag/satchel
- Chest
- Item grid

**Keywords for searching**: "backpack icon", "inventory icon", "bag icon"

---

### 2. 🏪 Shop Icon
**Purpose**: Access cosmetic shop (real money purchases)
**Suggested Designs**:
- Shopping cart
- Store/shop front
- Credit card
- Coin with dollar sign
- Gift box

**Keywords for searching**: "shop icon", "store icon", "cart icon", "purchase icon"

---

### 3. 📜 Quest Icon
**Purpose**: View quest log
**Suggested Designs**:
- Scroll/parchment
- Checklist
- Book
- Exclamation mark
- Quest marker

**Keywords for searching**: "quest icon", "scroll icon", "mission icon", "task icon"

---

### 4. ⚙️ Settings Icon
**Purpose**: Game settings and system options
**Suggested Designs**:
- Gear/cog
- Wrench
- Sliders
- Control panel

**Keywords for searching**: "settings icon", "gear icon", "options icon"

---

## Icon Specifications

### Technical Requirements
- **Format**: PNG with transparency
- **Size**: 64x64 pixels minimum (128x128 recommended for HD)
- **States**: 3 versions per icon
  - Normal (default state)
  - Hover (mouse over)
  - Active/Selected (currently viewing this panel)

### Visual Style
- **Style**: Flat design or slight 3D effect
- **Colors**: 
  - Normal: Light gray or white
  - Hover: Bright white or gold
  - Active: Gold/yellow highlight
- **Background**: Transparent
- **Border**: Optional subtle outline

---

## Free Icon Resources

### Recommended Sites:
1. **Font Awesome** (https://fontawesome.com)
   - Free icons, can export as PNG
   - Search: "backpack", "shopping-cart", "scroll", "cog"

2. **Material Icons** (https://fonts.google.com/icons)
   - Google's icon library
   - Search: "inventory", "shopping_cart", "assignment", "settings"

3. **Feather Icons** (https://feathericons.com)
   - Simple, clean line icons
   - Search: "package", "shopping-cart", "file-text", "settings"

4. **Game Icons** (https://game-icons.net)
   - Specifically for games
   - Search: "backpack", "shop", "scroll", "gear"

5. **OpenGameArt** (https://opengameart.org)
   - Free game assets
   - Search: "ui icons"

6. **itch.io** (https://itch.io/game-assets/free/tag-icons)
   - Free and paid icon packs
   - Filter by "Free" and "UI"

---

## Quick Icon Creation Guide

### Using Font Awesome (Free):
1. Go to https://fontawesome.com/search
2. Search for icon (e.g., "backpack")
3. Click icon → Download → SVG
4. Open in image editor (GIMP, Photoshop, Inkscape)
5. Export as PNG at 128x128 pixels
6. Create 3 versions (normal, hover, active) with different colors

### Using Figma (Free):
1. Create 128x128 canvas
2. Use icon plugins (Iconify, Material Icons)
3. Customize colors
4. Export as PNG

### Using Godot (Built-in):
1. Use Godot's built-in icons from editor theme
2. Or create simple shapes with ColorRect and Label
3. Use emoji as placeholder: 🎒 🏪 📜 ⚙️

---

## Placeholder Icons (Temporary)

If you don't have icons yet, you can use:

### Text-Based Placeholders:
```gdscript
# In Godot, create buttons with text:
inventory_button.text = "🎒\nInventory"
shop_button.text = "🏪\nShop"
quest_button.text = "📜\nQuests"
settings_button.text = "⚙️\nSettings"
```

### Color-Coded Placeholders:
- Inventory: Blue background
- Shop: Green background
- Quest: Yellow background
- Settings: Gray background

---

## Icon Naming Convention

Save icons with this naming pattern:
```
inventory_normal.png
inventory_hover.png
inventory_active.png

shop_normal.png
shop_hover.png
shop_active.png

quest_normal.png
quest_hover.png
quest_active.png

settings_normal.png
settings_hover.png
settings_active.png
```

---

## Example Icon Colors

### Normal State:
- RGB: (200, 200, 200) - Light gray
- Hex: #C8C8C8

### Hover State:
- RGB: (255, 255, 255) - White
- Hex: #FFFFFF

### Active State:
- RGB: (255, 215, 0) - Gold
- Hex: #FFD700

---

## Testing Checklist

- [ ] All 4 icons created
- [ ] Icons are 128x128 pixels
- [ ] PNG format with transparency
- [ ] 3 states per icon (normal, hover, active)
- [ ] Icons are visually distinct from each other
- [ ] Icons match game's art style
- [ ] Icons are readable at small sizes
- [ ] Icons look good on dark and light backgrounds

---

**Next Step**: Once you have the icons, I'll help you implement them in the pause menu!
