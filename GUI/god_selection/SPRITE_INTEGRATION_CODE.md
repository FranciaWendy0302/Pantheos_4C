# God Sprite Integration Code

## Once you add the sprites, use this code:

### Step 1: Update `_create_god_button` function

Replace the current button creation with this:

```gdscript
func _create_god_button(god_id: int, god_name: String) -> void:
	# Try to load sprite
	var sprite_path = "res://GUI/god_selection/sprites/" + god_name.to_lower() + ".png"
	
	if ResourceLoader.exists(sprite_path):
		# Create TextureButton with sprite
		var button = TextureButton.new()
		var texture = load(sprite_path) as Texture2D
		button.texture_normal = texture
		button.custom_minimum_size = Vector2(100, 100)
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.set_meta("god_id", god_id)
		button.pressed.connect(_on_god_button_pressed.bind(god_id))
		button.mouse_entered.connect(_on_god_button_hover.bind(god_id))
		
		# Add label below sprite
		var vbox = VBoxContainer.new()
		vbox.add_child(button)
		
		var label = Label.new()
		label.text = god_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(label)
		
		god_grid.add_child(vbox)
		god_buttons.append(button)
	else:
		# Fallback to text button if sprite not found
		var button = Button.new()
		button.text = god_name
		button.custom_minimum_size = Vector2(100, 28)
		button.set_meta("god_id", god_id)
		button.pressed.connect(_on_god_button_pressed.bind(god_id))
		button.mouse_entered.connect(_on_god_button_hover.bind(god_id))
		god_grid.add_child(button)
		god_buttons.append(button)
```

### Step 2: Add hover effect

```gdscript
func _on_god_button_hover(god_id: int) -> void:
	_update_description(god_id)
	
	# Highlight hovered button
	for btn in god_buttons:
		if btn.get_meta("god_id", 0) == god_id:
			btn.modulate = Color(1.3, 1.3, 1.3)  # Brighten
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)  # Normal
```

### Step 3: Add selection effect

```gdscript
func _on_god_button_pressed(god_id: int) -> void:
	selected_god_id = god_id
	
	# Update button styles - selected button gets colored border
	for btn in god_buttons:
		if btn.get_meta("god_id", 0) == god_id:
			btn.modulate = Color(1.5, 1.5, 0.8)  # Gold tint for selected
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)
	
	_update_description(god_id)
	god_selected.emit(god_id)
```

### Step 4: Show sprite in description (Optional)

Add this to the description panel:

```gdscript
func _update_description(god_id: int) -> void:
	var god_manager = get_node_or_null("/root/GodManager")
	if not god_manager:
		return
	
	var god_data = god_manager.get_god_data(god_id)
	if god_data.is_empty():
		return
	
	# Load sprite for description
	var sprite_path = "res://GUI/god_selection/sprites/" + god_data.name.to_lower() + ".png"
	var sprite_text = ""
	
	if ResourceLoader.exists(sprite_path):
		# You can add an image to RichTextLabel if needed
		sprite_text = "[img=64x64]" + sprite_path + "[/img]\n"
	
	var desc_text = sprite_text
	desc_text += "[b]%s[/b] - %s\n" % [god_data.name, god_data.title]
	desc_text += "[b]Role:[/b] %s | [b]Align:[/b] %s\n" % [god_data.role, god_data.alignment]
	desc_text += "%s\n" % god_data.description
	desc_text += "[b]Skill:[/b] %s - %s\n" % [god_data.special_skill, god_data.skill_description]
	desc_text += "[b]Class:[/b] %s" % god_data.recommended_class
	
	description_label.text = desc_text
	description_label.scroll_to_line(0)
```

## Alternative: Simple Icon Buttons

If you want smaller icon-style buttons:

```gdscript
func _create_god_button(god_id: int, god_name: String) -> void:
	var sprite_path = "res://GUI/god_selection/sprites/" + god_name.to_lower() + ".png"
	
	var button = TextureButton.new()
	if ResourceLoader.exists(sprite_path):
		button.texture_normal = load(sprite_path)
	
	button.custom_minimum_size = Vector2(80, 80)
	button.tooltip_text = god_name  # Show name on hover
	button.set_meta("god_id", god_id)
	button.pressed.connect(_on_god_button_pressed.bind(god_id))
	button.mouse_entered.connect(_on_god_button_hover.bind(god_id))
	
	god_grid.add_child(button)
	god_buttons.append(button)
```

## Visual Effects

### Glow Effect on Selection
```gdscript
# Add to selected button
var glow = ColorRect.new()
glow.color = Color(1, 0.8, 0, 0.3)  # Gold glow
glow.show_behind_parent = true
button.add_child(glow)
```

### Border on Hover
```gdscript
# Add StyleBox to button
var style = StyleBoxFlat.new()
style.border_color = Color(1, 1, 0)
style.border_width_all = 2
button.add_theme_stylebox_override("hover", style)
```

---

**Let me know when you've added the sprites and I'll integrate this code!** 🏛️⚡
