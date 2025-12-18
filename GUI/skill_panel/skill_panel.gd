extends Control
class_name SkillPanel

# Comprehensive skill panel showing all 6 skill slots with key bindings

@onready var skill_container: HBoxContainer = $VBoxContainer/SkillContainer
@onready var title_label: Label = $VBoxContainer/TitleLabel

# Skill slot containers
var q_skill_container: VBoxContainer
var w_skill_container: VBoxContainer
var e_skill_container: VBoxContainer
var r_skill_container: VBoxContainer
var d_skill_container: VBoxContainer
var f_skill_container: VBoxContainer
var helmet_passive_container: VBoxContainer

# Skill buttons
var q_button: Button
var w_button: Button
var e_button: Button
var r_button: Button
var d_button: Button
var f_button: Button
var helmet_passive_button: Button

# Skill labels
var q_name_label: Label
var w_name_label: Label
var e_name_label: Label
var r_name_label: Label
var d_name_label: Label
var f_name_label: Label
var helmet_passive_label: Label

# Cooldown overlays and labels
var skill_cooldowns: Dictionary = {}
var cooldown_timers: Dictionary = {}

# HP/MP bars
var hp_bar: ProgressBar
var mp_bar: ProgressBar

signal skill_button_pressed(slot: String)

func _ready():
	_create_skill_slots()
	_setup_panel_style()
	
	# Connect to ability system signals
	var player = PlayerManager.player
	if player and player.has_method("get_ability_system"):
		var ability_system = player.get_ability_system()
		if ability_system:
			ability_system.ability_used.connect(_on_ability_used)
			ability_system.cooldown_updated.connect(_on_cooldown_updated)
	
	# Update skills when equipment changes
	if PlayerManager.INVENTORY_DATA:
		PlayerManager.INVENTORY_DATA.equipment_changed.connect(_update_all_skills)
	
	# Initial skill update
	call_deferred("_update_all_skills")

func _create_skill_slots():
	"""Create all 6 skill slots plus helmet passive"""
	
	# Create main container
	if not skill_container:
		skill_container = HBoxContainer.new()
		skill_container.name = "SkillContainer"
		skill_container.add_theme_constant_override("separation", 8)
		add_child(skill_container)
	
	# Create each skill slot
	q_skill_container = _create_skill_slot("Q", "Weapon Skill 1", Color(0.8, 0.3, 0.3))
	w_skill_container = _create_skill_slot("W", "Weapon Skill 2", Color(0.3, 0.8, 0.3))
	e_skill_container = _create_skill_slot("E", "Weapon Skill 3", Color(0.3, 0.3, 0.8))
	r_skill_container = _create_skill_slot("R", "Class Ultimate", Color(0.9, 0.7, 0.2))
	d_skill_container = _create_skill_slot("D", "Armor Skill", Color(0.6, 0.4, 0.8))
	f_skill_container = _create_skill_slot("F", "Shoes Skill", Color(0.8, 0.5, 0.2))
	
	# Add separator before consumable
	var separator1 = VSeparator.new()
	separator1.custom_minimum_size = Vector2(2, 60)
	skill_container.add_child(separator1)
	
	# Consumable slot (key "1")
	var consumable_container = _create_consumable_slot("1", "Consumable", Color(0.3, 0.9, 0.6))
	
	# Add separator before passive
	var separator2 = VSeparator.new()
	separator2.custom_minimum_size = Vector2(2, 60)
	skill_container.add_child(separator2)
	
	# Helmet passive (different style)
	helmet_passive_container = _create_passive_slot("Helmet Passive", Color(0.7, 0.7, 0.7))
	
	# Store button references
	q_button = q_skill_container.get_node("SkillButton")
	w_button = w_skill_container.get_node("SkillButton")
	e_button = e_skill_container.get_node("SkillButton")
	r_button = r_skill_container.get_node("SkillButton")
	d_button = d_skill_container.get_node("SkillButton")
	f_button = f_skill_container.get_node("SkillButton")
	helmet_passive_button = helmet_passive_container.get_node("PassiveButton")
	
	# Store label references
	q_name_label = q_skill_container.get_node("SkillNameLabel")
	w_name_label = w_skill_container.get_node("SkillNameLabel")
	e_name_label = e_skill_container.get_node("SkillNameLabel")
	r_name_label = r_skill_container.get_node("SkillNameLabel")
	d_name_label = d_skill_container.get_node("SkillNameLabel")
	f_name_label = f_skill_container.get_node("SkillNameLabel")
	helmet_passive_label = helmet_passive_container.get_node("PassiveNameLabel")

func _create_skill_slot(key: String, default_name: String, key_color: Color) -> VBoxContainer:
	"""Create a skill slot with button, key label, and name label"""
	var container = VBoxContainer.new()
	container.name = key + "SkillContainer"
	container.custom_minimum_size = Vector2(40, 50)
	container.add_theme_constant_override("separation", 1)
	skill_container.add_child(container)
	
	# Key label (top)
	var key_label = Label.new()
	key_label.name = "KeyLabel"
	key_label.text = key
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.add_theme_color_override("font_color", key_color)
	key_label.add_theme_color_override("font_outline_color", Color.BLACK)
	key_label.add_theme_constant_override("outline_size", 2)
	container.add_child(key_label)
	
	# Skill button (middle)
	var button = Button.new()
	button.name = "SkillButton"
	button.custom_minimum_size = Vector2(32, 32)
	button.text = ""
	button.flat = true
	
	# Style the button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.border_color = key_color
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", button_style)
	
	# Hover style
	var hover_style = button_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Disabled style
	var disabled_style = button_style.duplicate()
	disabled_style.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	disabled_style.border_color = Color(0.3, 0.3, 0.3, 0.5)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	container.add_child(button)
	
	# Cooldown overlay
	var cooldown_overlay = ColorRect.new()
	cooldown_overlay.name = "CooldownOverlay"
	cooldown_overlay.color = Color(0, 0, 0, 0.7)
	cooldown_overlay.visible = false
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(cooldown_overlay)
	
	# Cooldown label
	var cooldown_label = Label.new()
	cooldown_label.name = "CooldownLabel"
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 18)
	cooldown_label.add_theme_color_override("font_color", Color.WHITE)
	cooldown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	cooldown_label.add_theme_constant_override("outline_size", 2)
	cooldown_label.visible = false
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(cooldown_label)
	
	# Skill name label (bottom)
	var name_label = Label.new()
	name_label.name = "SkillNameLabel"
	name_label.text = default_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 1)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(50, 0)
	container.add_child(name_label)
	
	# Connect button signal
	button.pressed.connect(_on_skill_button_pressed.bind(key))
	
	return container

func _create_passive_slot(default_name: String, border_color: Color) -> VBoxContainer:
	"""Create a passive skill slot (for helmet)"""
	var container = VBoxContainer.new()
	container.name = "HelmetPassiveContainer"
	container.custom_minimum_size = Vector2(40, 50)
	container.add_theme_constant_override("separation", 1)
	skill_container.add_child(container)
	
	# Passive label (top)
	var passive_label = Label.new()
	passive_label.name = "PassiveLabel"
	passive_label.text = "PASSIVE"
	passive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_label.add_theme_font_size_override("font_size", 10)
	passive_label.add_theme_color_override("font_color", border_color)
	passive_label.add_theme_color_override("font_outline_color", Color.BLACK)
	passive_label.add_theme_constant_override("outline_size", 1)
	container.add_child(passive_label)
	
	# Passive button (middle) - not clickable
	var button = Button.new()
	button.name = "PassiveButton"
	button.custom_minimum_size = Vector2(32, 32)
	button.text = ""
	button.flat = true
	button.disabled = true
	
	# Style the button (different from active skills)
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.border_color = border_color
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("disabled", button_style)
	
	container.add_child(button)
	
	# Passive name label (bottom)
	var name_label = Label.new()
	name_label.name = "PassiveNameLabel"
	name_label.text = default_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 1)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(50, 0)
	container.add_child(name_label)
	
	return container

func _create_consumable_slot(key: String, default_name: String, key_color: Color) -> VBoxContainer:
	"""Create a consumable slot that shows the quick slot item"""
	var container = VBoxContainer.new()
	container.name = "ConsumableContainer"
	container.custom_minimum_size = Vector2(40, 50)
	container.add_theme_constant_override("separation", 1)
	skill_container.add_child(container)
	
	# Key label (top)
	var key_label = Label.new()
	key_label.name = "KeyLabel"
	key_label.text = key
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.add_theme_color_override("font_color", key_color)
	key_label.add_theme_color_override("font_outline_color", Color.BLACK)
	key_label.add_theme_constant_override("outline_size", 2)
	container.add_child(key_label)
	
	# Consumable display (middle) - shows item icon and quantity
	var display = PanelContainer.new()
	display.name = "ConsumableDisplay"
	display.custom_minimum_size = Vector2(32, 32)
	
	# Style the display
	var display_style = StyleBoxFlat.new()
	display_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	display_style.border_width_left = 2
	display_style.border_width_right = 2
	display_style.border_width_top = 2
	display_style.border_width_bottom = 2
	display_style.border_color = key_color
	display_style.corner_radius_top_left = 8
	display_style.corner_radius_top_right = 8
	display_style.corner_radius_bottom_left = 8
	display_style.corner_radius_bottom_right = 8
	display.add_theme_stylebox_override("panel", display_style)
	
	container.add_child(display)
	
	# Item icon
	var icon = TextureRect.new()
	icon.name = "ItemIcon"
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.add_child(icon)
	
	# Quantity label (overlay on icon)
	var quantity_label = Label.new()
	quantity_label.name = "QuantityLabel"
	quantity_label.text = ""
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quantity_label.add_theme_font_size_override("font_size", 10)
	quantity_label.add_theme_color_override("font_color", Color.WHITE)
	quantity_label.add_theme_color_override("font_outline_color", Color.BLACK)
	quantity_label.add_theme_constant_override("outline_size", 2)
	quantity_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	quantity_label.offset_right = -2
	quantity_label.offset_bottom = -2
	display.add_child(quantity_label)
	
	# Consumable name label (bottom)
	var name_label = Label.new()
	name_label.name = "ConsumableNameLabel"
	name_label.text = default_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 1)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(50, 0)
	container.add_child(name_label)
	
	# Update consumable display when quick slot changes
	if PlayerManager.INVENTORY_DATA:
		PlayerManager.INVENTORY_DATA.quick_slot_changed.connect(_update_consumable_display)
	
	# Initial update
	call_deferred("_update_consumable_display")
	
	return container

func _update_consumable_display():
	"""Update the consumable slot display"""
	var container = skill_container.get_node_or_null("ConsumableContainer")
	if not container:
		return
	
	var display = container.get_node_or_null("ConsumableDisplay")
	if not display:
		return
	
	var icon = display.get_node_or_null("ItemIcon")
	var quantity_label = display.get_node_or_null("QuantityLabel")
	var name_label = container.get_node_or_null("ConsumableNameLabel")
	
	if not icon or not quantity_label or not name_label:
		return
	
	var quick_slot = PlayerManager.INVENTORY_DATA.quick_slot
	
	if quick_slot and quick_slot.item_data:
		# Show item
		icon.texture = quick_slot.item_data.texture
		quantity_label.text = str(quick_slot.quantity)
		name_label.text = quick_slot.item_data.name
		icon.modulate = Color.WHITE
	else:
		# Empty slot
		icon.texture = null
		quantity_label.text = ""
		name_label.text = "No Item"
		icon.modulate = Color(0.5, 0.5, 0.5)

func _create_hp_mp_bars(vbox: VBoxContainer):
	"""Create HP and MP bars at the top of the skill panel"""
	var hp_mp_container = HBoxContainer.new()
	hp_mp_container.name = "HPMPContainer"
	hp_mp_container.add_theme_constant_override("separation", 20)
	hp_mp_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hp_mp_container)
	
	# HP Bar
	var hp_vbox = VBoxContainer.new()
	hp_vbox.add_theme_constant_override("separation", 2)
	hp_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_mp_container.add_child(hp_vbox)
	
	var hp_label = Label.new()
	hp_label.text = "HP"
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 8)
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hp_label.add_theme_constant_override("outline_size", 1)
	hp_vbox.add_child(hp_label)
	
	var hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.custom_minimum_size = Vector2(150, 10)
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	
	# Style HP bar
	var hp_bg = StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	hp_bg.corner_radius_top_left = 4
	hp_bg.corner_radius_top_right = 4
	hp_bg.corner_radius_bottom_left = 4
	hp_bg.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	hp_fill.corner_radius_top_left = 4
	hp_fill.corner_radius_top_right = 4
	hp_fill.corner_radius_bottom_left = 4
	hp_fill.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	
	hp_vbox.add_child(hp_bar)
	
	# MP Bar
	var mp_vbox = VBoxContainer.new()
	mp_vbox.add_theme_constant_override("separation", 2)
	mp_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_mp_container.add_child(mp_vbox)
	
	var mp_label = Label.new()
	mp_label.text = "MP"
	mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mp_label.add_theme_font_size_override("font_size", 8)
	mp_label.add_theme_color_override("font_color", Color.WHITE)
	mp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	mp_label.add_theme_constant_override("outline_size", 1)
	mp_vbox.add_child(mp_label)
	
	var mp_bar = ProgressBar.new()
	mp_bar.name = "MPBar"
	mp_bar.custom_minimum_size = Vector2(150, 10)
	mp_bar.max_value = 100
	mp_bar.value = 100
	mp_bar.show_percentage = false
	
	# Style MP bar
	var mp_bg = StyleBoxFlat.new()
	mp_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	mp_bg.corner_radius_top_left = 4
	mp_bg.corner_radius_top_right = 4
	mp_bg.corner_radius_bottom_left = 4
	mp_bg.corner_radius_bottom_right = 4
	mp_bar.add_theme_stylebox_override("background", mp_bg)
	
	var mp_fill = StyleBoxFlat.new()
	mp_fill.bg_color = Color(0.2, 0.5, 0.9, 1.0)
	mp_fill.corner_radius_top_left = 4
	mp_fill.corner_radius_top_right = 4
	mp_fill.corner_radius_bottom_left = 4
	mp_fill.corner_radius_bottom_right = 4
	mp_bar.add_theme_stylebox_override("fill", mp_fill)
	
	mp_vbox.add_child(mp_bar)
	
	# Store references for updates
	self.hp_bar = hp_bar
	self.mp_bar = mp_bar

func _setup_panel_style():
	"""Setup the overall panel styling"""
	# Panel background
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", panel_style)
	
	# Get VBoxContainer
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return
	
	# Create HP/MP bars at the top
	_create_hp_mp_bars(vbox)
	
	# Move HP/MP bars to the top (index 0)
	var hp_mp_container = vbox.get_node_or_null("HPMPContainer")
	if hp_mp_container:
		vbox.move_child(hp_mp_container, 0)
	
	# Move title label to position 1 (after HP/MP bars)
	if title_label:
		vbox.move_child(title_label, 1)
	
	# Skill container should be at position 2 (already there)

func _on_skill_button_pressed(slot: String):
	"""Handle skill button press"""
	skill_button_pressed.emit(slot)
	
	# Also trigger the ability directly
	var player = PlayerManager.player
	if player and player.has_method("get_ability_system"):
		var ability_system = player.get_ability_system()
		if ability_system:
			ability_system.use_ability(slot)

func _update_all_skills():
	"""Update all skill displays based on current equipment and abilities"""
	print("[SkillPanel] _update_all_skills called")
	var player = PlayerManager.player
	if not player or not player.has_method("get_ability_system"):
		print("[SkillPanel] No player or ability system")
		return
	
	var ability_system = player.get_ability_system()
	if not ability_system:
		print("[SkillPanel] No ability system")
		return
	
	print("[SkillPanel] Updating all skill slots...")
	
	# Update Q/W/E from weapon skill references
	_update_weapon_skill_display("Q", q_name_label, q_button)
	_update_weapon_skill_display("W", w_name_label, w_button)
	_update_weapon_skill_display("E", e_name_label, e_button)
	
	# Update D/F from equipment skill references
	_update_weapon_skill_display("D", d_name_label, d_button)
	_update_weapon_skill_display("F", f_name_label, f_button)
	
	# Update R - Class Ultimate
	_update_class_ultimate_display(r_name_label, r_button)
	
	# Update helmet passive from equipment
	_update_helmet_passive_display(helmet_passive_label, helmet_passive_button)
	
	print("[SkillPanel] All skills updated")

func _update_weapon_skill_display(slot: String, name_label: Label, button: Button):
	"""Update weapon skill display from SkillReference"""
	if not name_label or not button:
		return
	
	# Get skill reference from ability system
	var player = PlayerManager.player
	if not player or not player.has_method("get_ability_system"):
		return
	
	var ability_system = player.get_ability_system()
	if not ability_system:
		return
	
	var skill_ref: SkillReference = ability_system._get_skill_reference(slot)
	
	print("[SkillPanel] Updating slot %s: skill_ref = %s" % [slot, skill_ref])
	
	if skill_ref and skill_ref.display_name != "":
		print("[SkillPanel] Slot %s has skill: %s" % [slot, skill_ref.display_name])
		name_label.text = skill_ref.display_name
		button.disabled = false
		button.tooltip_text = skill_ref.description + "\nCost: " + str(skill_ref.mana_cost) + "\nCooldown: " + str(skill_ref.cooldown) + "s"
		
		# Add skill icon from SkillReference
		if skill_ref.icon:
			_add_skill_icon_texture(button, skill_ref.icon)
		else:
			_add_skill_icon(button, slot)
	else:
		print("[SkillPanel] Slot %s has no skill - removing icon" % slot)
		name_label.text = "No Skill"
		button.disabled = true
		button.tooltip_text = "No weapon equipped or weapon has no skills"
		_remove_skill_icon(button)

func _update_class_ultimate_display(name_label: Label, button: Button):
	"""Update class ultimate display (R key)"""
	if not name_label or not button:
		return
	
	var player = PlayerManager.player
	if not player:
		name_label.text = "No Skill"
		button.disabled = true
		_remove_skill_icon(button)
		return
	
	# Get player class and set ultimate info
	var player_class = player.get_player_class()
	print("[SkillPanel] Updating R skill for class: %s" % player_class)
	
	match player_class:
		"Mage":
			name_label.text = "Flame Convergence"
			button.disabled = false
			button.tooltip_text = "Summons fire streams to converge on a point\nCost: 80 mana\nCooldown: 60s"
			_add_skill_icon(button, "R")
		"Swordsman", "Warrior":
			name_label.text = "Berserker Rage"
			button.disabled = false
			button.tooltip_text = "Ultimate warrior skill\nCost: 60 mana\nCooldown: 60s"
			_add_skill_icon(button, "R")
		_:
			name_label.text = "No Ultimate"
			button.disabled = true
			button.tooltip_text = "No ultimate skill for this class"
			_remove_skill_icon(button)

func _update_helmet_passive_display(name_label: Label, button: Button):
	"""Update helmet passive display from SkillReference"""
	if not name_label or not button:
		return
	
	# Get helmet skill reference
	if not PlayerManager.INVENTORY_DATA:
		name_label.text = "No Passive"
		button.tooltip_text = "No helmet equipped"
		_remove_skill_icon(button)
		return
	
	var equipment_slots = PlayerManager.INVENTORY_DATA.equipment_slots()
	if equipment_slots.size() < 2:
		name_label.text = "No Passive"
		button.tooltip_text = "No helmet equipped"
		_remove_skill_icon(button)
		return
	
	# Get helmet slot (index 1)
	var helmet_slot = equipment_slots[1]
	if not helmet_slot or not helmet_slot.item_data:
		name_label.text = "No Passive"
		button.tooltip_text = "No helmet equipped"
		_remove_skill_icon(button)
		return
	
	var helmet_item = helmet_slot.item_data
	if not "equipment_skills" in helmet_item or not helmet_item.equipment_skills:
		name_label.text = "No Passive"
		button.tooltip_text = "Helmet has no passive"
		_remove_skill_icon(button)
		return
	
	if not "skill" in helmet_item.equipment_skills or not helmet_item.equipment_skills.skill:
		name_label.text = "No Passive"
		button.tooltip_text = "Helmet has no passive"
		_remove_skill_icon(button)
		return
	
	var skill_ref: SkillReference = helmet_item.equipment_skills.skill
	
	if skill_ref and skill_ref.display_name != "":
		name_label.text = skill_ref.display_name
		button.tooltip_text = skill_ref.description
		
		# Add passive icon from SkillReference
		if skill_ref.icon:
			_add_skill_icon_texture(button, skill_ref.icon)
		else:
			_add_passive_icon(button)
	else:
		name_label.text = "No Passive"
		button.tooltip_text = "Helmet has no passive"
		_remove_skill_icon(button)

func _update_skill_display(slot: String, ability, name_label: Label, button: Button):
	"""Update a single skill display"""
	if not name_label or not button:
		return
	
	if ability and ability.name != "":
		name_label.text = ability.name
		button.disabled = false
		button.tooltip_text = ability.description + "\nCost: " + str(ability.cost) + "\nCooldown: " + str(ability.cooldown) + "s"
		
		# Add skill icon if available
		_add_skill_icon(button, slot)
	else:
		name_label.text = "No Skill"
		button.disabled = true
		button.tooltip_text = "No skill equipped in this slot"
		_remove_skill_icon(button)

func _update_passive_display(ability, name_label: Label, button: Button):
	"""Update passive skill display"""
	if not name_label or not button:
		return
	
	if ability and ability.name != "":
		name_label.text = ability.name
		button.tooltip_text = ability.description
		
		# Add passive icon if available
		_add_passive_icon(button)
	else:
		name_label.text = "No Passive"
		button.tooltip_text = "No helmet equipped"
		_remove_skill_icon(button)

func _add_skill_icon_texture(button: Button, texture: Texture2D):
	"""Add skill icon from texture to button"""
	# Remove existing icon first
	_remove_skill_icon(button)
	
	if texture:
		var icon_rect = TextureRect.new()
		icon_rect.name = "SkillIcon"
		icon_rect.texture = texture
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_rect.offset_left = 5
		icon_rect.offset_top = 5
		icon_rect.offset_right = -5
		icon_rect.offset_bottom = -5
		button.add_child(icon_rect)
		button.move_child(icon_rect, 0)  # Behind other elements

func _add_skill_icon(button: Button, slot: String):
	"""Add skill icon to button (fallback for old system)"""
	# Remove existing icon
	_remove_skill_icon(button)
	
	# Load appropriate icon based on slot
	var icon_path = ""
	match slot:
		"Q", "W", "E":
			icon_path = "res://Player/Sprites/skill icon/sword_skill.png"
		"R":
			# Try class-specific ultimate icon first
			icon_path = "res://Player/Sprites/skill icon/flameconvergence.jpg"
			if not ResourceLoader.exists(icon_path):
				icon_path = "res://Player/Sprites/skill icon/ultimate_skill.png"
		"D":
			icon_path = "res://Player/Sprites/skill icon/armor_skill.png"
		"F":
			icon_path = "res://Player/Sprites/skill icon/shoes_skill.png"
	
	# Try to load the icon
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon_texture = load(icon_path)
		if icon_texture:
			_add_skill_icon_texture(button, icon_texture)

func _add_passive_icon(button: Button):
	"""Add passive icon to button"""
	_remove_skill_icon(button)
	
	var icon_path = "res://Player/Sprites/skill icon/passive_skill.png"
	if ResourceLoader.exists(icon_path):
		var icon_texture = load(icon_path)
		if icon_texture:
			var icon_rect = TextureRect.new()
			icon_rect.name = "SkillIcon"
			icon_rect.texture = icon_texture
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_rect.offset_left = 5
			icon_rect.offset_top = 5
			icon_rect.offset_right = -5
			icon_rect.offset_bottom = -5
			button.add_child(icon_rect)
			button.move_child(icon_rect, 0)

func _remove_skill_icon(button: Button):
	"""Remove skill icon from button"""
	var icon = button.get_node_or_null("SkillIcon")
	if icon:
		button.remove_child(icon)
		icon.queue_free()

func _on_ability_used(slot: String, ability_name: String):
	"""Handle ability used signal"""
	print("[SkillPanel] Ability used: %s - %s" % [slot, ability_name])

func _on_cooldown_updated(slot: String, remaining: float, max_time: float):
	"""Handle cooldown update signal"""
	var button: Button = null
	var overlay: ColorRect = null
	var label: Label = null
	
	# Get the appropriate UI elements
	match slot:
		"Q":
			button = q_button
			overlay = q_button.get_node_or_null("CooldownOverlay")
			label = q_button.get_node_or_null("CooldownLabel")
		"W":
			button = w_button
			overlay = w_button.get_node_or_null("CooldownOverlay")
			label = w_button.get_node_or_null("CooldownLabel")
		"E":
			button = e_button
			overlay = e_button.get_node_or_null("CooldownOverlay")
			label = e_button.get_node_or_null("CooldownLabel")
		"R":
			button = r_button
			overlay = r_button.get_node_or_null("CooldownOverlay")
			label = r_button.get_node_or_null("CooldownLabel")
		"D":
			button = d_button
			overlay = d_button.get_node_or_null("CooldownOverlay")
			label = d_button.get_node_or_null("CooldownLabel")
		"F":
			button = f_button
			overlay = f_button.get_node_or_null("CooldownOverlay")
			label = f_button.get_node_or_null("CooldownLabel")
	
	if not button or not overlay or not label:
		return
	
	# Update cooldown display
	if remaining > 0.0:
		overlay.visible = true
		label.visible = true
		label.text = str(int(ceil(remaining)))
		button.disabled = true
	else:
		overlay.visible = false
		label.visible = false
		button.disabled = false

func refresh_panel():
	"""Refresh the skill panel display"""
	_update_all_skills()

func update_hp(current_hp: int, max_hp: int):
	"""Update HP bar"""
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
		
		# Color based on HP percentage
		var hp_percent = float(current_hp) / float(max_hp)
		var hp_fill = hp_bar.get_theme_stylebox("fill")
		if hp_fill is StyleBoxFlat:
			if hp_percent > 0.6:
				hp_fill.bg_color = Color(0.2, 0.8, 0.2, 1.0)  # Green
			elif hp_percent > 0.3:
				hp_fill.bg_color = Color(0.9, 0.9, 0.2, 1.0)  # Yellow
			else:
				hp_fill.bg_color = Color(0.9, 0.2, 0.2, 1.0)  # Red

func update_mp(current_mp: int, max_mp: int):
	"""Update MP bar"""
	if mp_bar:
		mp_bar.max_value = max_mp
		mp_bar.value = current_mp
