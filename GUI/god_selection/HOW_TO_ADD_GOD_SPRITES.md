# How to Add God Sprites to Selection Panel

## 📁 Folder Structure

Put your god sprite images in:
```
GUI/god_selection/sprites/
```

## 🖼️ Sprite Naming Convention

Name your sprite files like this:
```
athena.png      (or .jpg, .webp)
zeus.png
venus.png
asclepius.png
hades.png
ares.png
titan.png
gigantes.png
```

**Important:** Use lowercase names to match the god names in code.

## 📐 Recommended Sprite Size

For the 480x270 viewport with 4 columns:
- **Width:** 80-100 pixels
- **Height:** 80-100 pixels
- **Format:** PNG with transparency (recommended)

## 🎨 Sprite Style Suggestions

### Option 1: Portrait Style
- Head/bust of the god
- Circular or square frame
- Clear, recognizable features

### Option 2: Icon Style
- Symbol representing the god
- Athena: Shield/Owl
- Zeus: Lightning bolt
- Venus: Heart/Rose
- Asclepius: Staff with snake
- Hades: Skull/Underworld symbol
- Ares: Sword/Helmet
- Titan: Mountain/Giant
- Gigantes: Giant fist

### Option 3: Full Character
- Small character sprite
- Standing pose
- Distinctive silhouette

## 🔧 After Adding Sprites

Once you've added the sprite files, I'll help you:
1. Update the god button creation to use TextureButton instead of Button
2. Add hover effects
3. Show the sprite in the description area
4. Add visual feedback for selection

## 📝 Example File Structure

```
GUI/god_selection/
├── sprites/
│   ├── athena.png       ← Put your sprites here
│   ├── zeus.png
│   ├── venus.png
│   ├── asclepius.png
│   ├── hades.png
│   ├── ares.png
│   ├── titan.png
│   └── gigantes.png
├── god_selection_panel.gd
├── god_selection_panel.tscn
└── HOW_TO_ADD_GOD_SPRITES.md (this file)
```

## 🎯 Quick Steps

1. **Create your 8 god sprites** (80x100 pixels recommended)
2. **Name them correctly** (lowercase, matching god names)
3. **Put them in** `GUI/god_selection/sprites/`
4. **Let me know** and I'll update the code to use them!

## 💡 Tips

- Use consistent art style for all 8 gods
- Make sure sprites are clear at small size
- Use transparency (PNG) for better visual quality
- Consider adding a subtle glow or border for selected state
- Test visibility on dark background

## 🎨 Color Themes (Optional)

You can use these color themes for each alignment:
- **Good Gods:** Gold/White/Blue tones
- **Evil Gods:** Red/Black/Purple tones
- **Fallen Angels:** Gray/Orange/Dark tones

---

**Ready to add sprites?** Just put your images in the `sprites` folder and let me know! 🏛️⚡
