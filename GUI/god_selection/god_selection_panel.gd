extends PanelContainer

# God selection panel for character creation

signal god_selected(god_id: int)
signal back_pressed()

@onready var god_grid: GridContainer = $MarginContainer/VBox/ScrollContainer/GodGrid
@onready var description_label: RichTextLabel = $MarginContainer/VBox/DescriptionLabel
@onready var back_button: Button = $MarginContainer/VBox/BackButton

var selected_god_id: int = 0
var god_buttons: Array[Button] = []

func _ready() -> void:
	_create_god_buttons()
	back_button.pressed.connect(_on_back_pressed)
	visible = false

func _create_god_buttons() -> void:
	# Clear existing buttons
	for child in god_grid.get_children():
		child.queue_free()
	god_buttons.clear()
	
	# Create buttons for each god
	var god_manager = get_node_or_null("/root/GodManager")
	if not god_manager:
		push_error("[GodSelection] GodManager not found!")
		return
	
	# Create all 8 god buttons (4 Good, 2 Evil, 2 Fallen)
	# Row 1: Good Gods
	_create_god_button(1, "Athena")     # Tank
	_create_god_button(2, "Zeus")       # Ranged DPS
	_create_god_button(3, "Venus")      # Support
	_create_god_button(4, "Asclepius")  # Healer
	
	# Row 2: Evil Gods + Fallen Angels
	_create_god_button(5, "Hades")      # Off-Tank
	_create_god_button(6, "Ares")       # Melee DPS
	_create_god_button(7, "Titan")      # Hybrid
	_create_god_button(8, "Gigantes")   # Hybrid

func _create_god_button(god_id: int, god_name: String) -> void:
	# Create card container
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(100, 110)
	
	# Card style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.border_color = Color(0.4, 0.4, 0.5, 1)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	card.add_theme_stylebox_override("panel", style)
	
	# Card content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)
	
	# Sprite area (try to load sprite, fallback to placeholder)
	var sprite_path = "res://GUI/god_selection/sprites/" + god_name.to_lower() + ".png"
	var sprite_container = CenterContainer.new()
	sprite_container.custom_minimum_size = Vector2(0, 80)
	
	if ResourceLoader.exists(sprite_path):
		# Use actual sprite
		var texture_rect = TextureRect.new()
		texture_rect.texture = load(sprite_path)
		texture_rect.custom_minimum_size = Vector2(80, 80)
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite_container.add_child(texture_rect)
	else:
		# Placeholder - colored square with initial
		var placeholder = ColorRect.new()
		placeholder.custom_minimum_size = Vector2(60, 60)
		placeholder.color = _get_god_color(god_id)
		sprite_container.add_child(placeholder)
		
		# Add initial letter
		var initial = Label.new()
		initial.text = god_name[0]
		initial.add_theme_font_size_override("font_size", 32)
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.add_child(initial)
	
	vbox.add_child(sprite_container)
	
	# God name label
	var name_label = Label.new()
	name_label.text = god_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(name_label)
	
	# Make card clickable
	var button = Button.new()
	button.flat = true
	button.custom_minimum_size = card.custom_minimum_size
	button.set_meta("god_id", god_id)
	button.set_meta("card", card)
	button.pressed.connect(_on_god_button_pressed.bind(god_id))
	button.mouse_entered.connect(_on_god_button_hover.bind(god_id))
	button.mouse_exited.connect(_on_god_button_exit.bind(god_id))
	
	# Add button on top of card
	card.add_child(button)
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	god_grid.add_child(card)
	god_buttons.append(button)

func _get_god_color(god_id: int) -> Color:
	"""Get color theme for each god"""
	match god_id:
		1: return Color(0.8, 0.7, 0.3)  # Athena - Gold
		2: return Color(0.3, 0.5, 0.9)  # Zeus - Blue
		3: return Color(0.9, 0.4, 0.6)  # Venus - Pink
		4: return Color(0.4, 0.8, 0.5)  # Asclepius - Green
		5: return Color(0.5, 0.3, 0.6)  # Hades - Purple
		6: return Color(0.9, 0.3, 0.3)  # Ares - Red
		7: return Color(0.6, 0.5, 0.4)  # Titan - Brown
		8: return Color(0.5, 0.5, 0.5)  # Gigantes - Gray
	return Color(0.5, 0.5, 0.5)

func _on_god_button_exit(god_id: int) -> void:
	"""Reset card style when mouse exits"""
	for btn in god_buttons:
		if btn.get_meta("god_id", 0) == god_id:
			var card = btn.get_meta("card")
			if card and selected_god_id != god_id:
				var style = card.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					style.border_color = Color(0.4, 0.4, 0.5, 1)
					style.border_width_left = 1
					style.border_width_top = 1
					style.border_width_right = 1
					style.border_width_bottom = 1

func _on_god_button_pressed(god_id: int) -> void:
	selected_god_id = god_id
	
	# Update card styles - highlight selected
	for btn in god_buttons:
		var card = btn.get_meta("card")
		if not card:
			continue
		
		var style = card.get_theme_stylebox("panel") as StyleBoxFlat
		if not style:
			continue
		
		if btn.get_meta("god_id", 0) == god_id:
			# Selected card - gold border
			style.border_color = Color(1.0, 0.8, 0.2, 1)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
			card.modulate = Color(1.1, 1.1, 1.1)
		else:
			# Unselected cards
			style.border_color = Color(0.4, 0.4, 0.5, 1)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			card.modulate = Color(1.0, 1.0, 1.0)
	
	# Show god info
	_update_description(god_id)
	
	# Emit signal
	god_selected.emit(god_id)

func _on_god_button_hover(god_id: int) -> void:
	_update_description(god_id)
	
	# Highlight hovered card
	for btn in god_buttons:
		if btn.get_meta("god_id", 0) == god_id:
			var card = btn.get_meta("card")
			if card and selected_god_id != god_id:
				var style = card.get_theme_stylebox("panel") as StyleBoxFlat
				if style:
					style.border_color = Color(0.7, 0.7, 0.8, 1)
					style.border_width_left = 2
					style.border_width_top = 2
					style.border_width_right = 2
					style.border_width_bottom = 2

func _update_description(god_id: int) -> void:
	var god_manager = get_node_or_null("/root/GodManager")
	if not god_manager:
		return
	
	var god_data = god_manager.get_god_data(god_id)
	if god_data.is_empty():
		return
	
	var desc_text = "[b]%s[/b] - %s\n" % [god_data.name, god_data.title]
	desc_text += "[b]Role:[/b] %s | [b]Pantheon:[/b] %s\n" % [god_data.role, god_data.pantheon]
	desc_text += "%s\n" % god_data.description
	desc_text += "[b]Skill:[/b] %s - %s\n" % [god_data.special_skill, god_data.skill_description]
	desc_text += "[b]Class:[/b] %s" % god_data.recommended_class
	
	description_label.text = desc_text
	description_label.scroll_to_line(0)  # Scroll to top when updating

func _on_back_pressed() -> void:
	back_pressed.emit()

func show_panel() -> void:
	visible = true
	if god_buttons.size() > 0:
		god_buttons[0].grab_focus()

func hide_panel() -> void:
	visible = false

func get_selected_god() -> int:
	return selected_god_id
