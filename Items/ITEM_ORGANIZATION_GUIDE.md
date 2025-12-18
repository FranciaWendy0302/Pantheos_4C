# Item Organization Guide

## Folder Structure for Class-Specific Items

Organize your `.tres` item files by class for easy management:

```
Items/
├── equipment/
│   ├── swordsman/
│   │   ├── knight_helmet.tres
│   │   ├── knight_armor.tres
│   │   ├── knight_sword.tres
│   │   └── knight_boots.tres
│   ├── archer/
│   │   ├── hunter_hood.tres
│   │   ├── hunter_vest.tres
│   │   ├── hunter_bow.tres
│   │   └── hunter_boots.tres
│   ├── mage/
│   │   ├── fire_mage_hat.tres
│   │   ├── fire_mage_robe.tres
│   │   ├── fire_mage_staff.tres
│   │   └── fire_mage_shoes.tres
│   └── universal/
│       ├── basic_sword.tres
│       ├── leather_armor.tres
│       └── common_boots.tres
└── consumables/
    ├── health_potion.tres
    └── mana_potion.tres
```

## Setting Class Requirements

### For Class-Specific Items:
1. Open the `.tres` file in Godot Inspector
2. Find **"Class Restriction"** group
3. Set `Class Requirement` to:
   - **SWORDSMAN** - For Knight/Warrior sets
   - **ARCHER** - For Hunter/Ranger sets
   - **MAGE** - For Wizard/Sorcerer sets

### For Universal Items:
- Set `Class Requirement` to **NONE**
- These can be equipped by any class

## Naming Convention

Use prefixes to quickly identify item class:
- `knight_*` or `warrior_*` → Swordsman items
- `hunter_*` or `archer_*` → Archer items
- `mage_*` or `wizard_*` → Mage items
- `basic_*` or `common_*` → Universal items

## Quick Setup Checklist

For each new equipment item:
- [ ] Place in appropriate class folder
- [ ] Set `Class Requirement` enum
- [ ] Use class-specific naming
- [ ] Set appropriate stats/modifiers
- [ ] Assign weapon/equipment skills (if applicable)

## Testing Class Restrictions

1. Create a character of each class
2. Try to equip class-specific items
3. Verify:
   - ✓ Items gray out for wrong class
   - ✓ Description shows "Required Class: X"
   - ✓ Cannot equip wrong class items
   - ✓ Can equip correct class items
   - ✓ Universal items work for all classes

## Common Issues

**Problem**: Swordsman can equip Mage items
**Solution**: Check that the item's `class_requirement` is set to `MAGE`, not `NONE`

**Problem**: Item shows as "Any Class" but should be restricted
**Solution**: Open the `.tres` file and set the `Class Requirement` dropdown

**Problem**: All items are grayed out
**Solution**: Verify `PlayerManager.character_class` is set correctly (check in debugger)
