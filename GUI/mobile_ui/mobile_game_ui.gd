extends Control

# Complete Mobile UI Layout Example
# This creates the full mobile interface with all elements positioned

@onready var screen_size = get_viewport().size
var ui_scale: float = 1.0

# UI Elements
var top_hud: Control
var bottom_controls: Control
var virtual_joystick: Control
var action_buttons: Control
var side_panels: Control

# HUD Elements
var health_bar: ProgressBar
var mana_bar: ProgressBar
var level_label: Label
var exp_bar: ProgressBar

# Control Elements
var joystick_base: ColorRect
var joystick_knob: ColorRect
var attack_button: Button
var ability_button: Button
var interact_button: Button
var menu_button: Button

# Panels
var inventory_panel: Panel
var chat_panel: Panel

func _ready():
	if not PlatformManager or not PlatformManager.is_platform_android():
		visible = false
		return
	
	print("Creating mobile UI layout...")
	calculate_ui_scale()
	create_mobile_ui()

func calculate_ui_scale():
	# Scale based on screen size (assuming 1080p as baseline)
	var base_width = 1080.0
	ui_scale = screen_size.x / base_width
	ui_scale = clamp(ui_scale, 0.7, 2.0)
	print("Mobile UI Scale: ", ui_scale)

func create_mobile_ui():
	# Set up main container
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create all UI sections
	create_top_hud()
	create_bottom_controls()
	create_side_panels()
	
	print("Mobile UI layout created successfully!")

# ===== TOP HUD =====
func create_top_hud():
	top_hud = Control.new()
	top_hud.name = "TopHUD"
	top_hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_hud.size.y = 120 * ui_scale
	add_child(top_hud)
	
	# Health Bar
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(20, 20) * ui_scale
	health_bar.size = Vector2(200, 25) * ui_scale
	health_bar.value = 80
	health_bar.add_theme_color_override("fill", Color.RED)
	top_hud.add_child(health_bar)
	
	# Health Label
	var health_label = Label.new()
	health_label.text = "HP: 800/1000"
	health_label.position = Vector2(25, 5) * ui_scale
	health_label.add_theme_color_override("font_color", Color.WHITE)
	top_hud.add_child(health_label)
	
	# Mana Bar
	mana_bar = ProgressBar.new()
	mana_bar.position = Vector2(240, 20) * ui_scale
	mana_bar.size = Vector2(180, 25) * ui_scale
	mana_bar.value = 60
	mana_bar.add_theme_color_override("fill", Color.BLUE)
	top_hud.add_child(mana_bar)
	
	# Mana Label
	var mana_label = Label.new()
	mana_label.text = "MP: 300/500"
	mana_label.position = Vector2(245, 5) * ui_scale
	mana_label.add_theme_color_override("font_color", Color.WHITE)
	top_hud.add_child(mana_label)
	
	# Level and EXP
	level_label = Label.new()
	level_label.text = "Level 25"
	level_label.position = Vector2(20, 55) * ui_scale
	level_label.add_theme_color_override("font_color", Color.YELLOW)
	top_hud.add_child(level_label)
	
	exp_bar = ProgressBar.new()
	exp_bar.position = Vector2(100, 60) * ui_scale
	exp_bar.size = Vector2(250, 15) * ui_scale
	exp_bar.value = 75
	exp_bar.add_theme_color_override("fill", Color.GREEN)
	top_hud.add_child(exp_bar)
	
	# Network Status Indicator
	var network_status = Label.new()
	network_status.text = "📶 WiFi"
	network_status.position = Vector2(screen_size.x - 120 * ui_scale, 80 * ui_scale)
	network_status.add_theme_color_override("font_color", Color.GREEN)
	top_hud.add_child(network_status)
	
	# Menu Button (hamburger menu)
	menu_button = Button.new()
	menu_button.text = "☰"
	menu_button.position = Vector2(screen_size.x - 60 * ui_scale, 20 * ui_scale)
	menu_button.size = Vector2(40, 40) * ui_scale
	menu_button.pressed.connect(_on_menu_pressed)
	top_hud.add_child(menu_button)
	
	# Connect to network status updates
	if MobileNetworkManager:
		MobileNetworkManager.network_status_changed.connect(_on_network_status_changed)
		MobileNetworkManager.connection_quality_changed.connect(_on_connection_quality_changed)

# ===== BOTTOM CONTROLS =====
func create_bottom_controls():
	bottom_controls = Control.new()
	bottom_controls.name = "BottomControls"
	bottom_controls.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_controls.size.y = 200 * ui_scale
	add_child(bottom_controls)
	
	# Virtual Joystick
	create_virtual_joystick()
	
	# Action Buttons
	create_action_buttons()
	
	# Chat area
	create_chat_area()

func create_virtual_joystick():
	var joystick_size = 160 * ui_scale
	var joystick_pos = Vector2(80 * ui_scale, bottom_controls.size.y - 120 * ui_scale)
	
	# Joystick Base (outer circle)
	joystick_base = ColorRect.new()
	joystick_base.color = Color(0.2, 0.2, 0.2, 0.6)
	joystick_base.position = joystick_pos
	joystick_base.size = Vector2(joystick_size, joystick_size)
	bottom_controls.add_child(joystick_base)
	
	# Joystick Knob (inner circle)
	joystick_knob = ColorRect.new()
	joystick_knob.color = Color(0.8, 0.8, 0.8, 0.9)
	var knob_size = joystick_size * 0.6
	joystick_knob.position = Vector2(joystick_size * 0.2, joystick_size * 0.2)
	joystick_knob.size = Vector2(knob_size, knob_size)
	joystick_base.add_child(joystick_knob)
	
	# Add joystick label
	var joystick_label = Label.new()
	joystick_label.text = "MOVE"
	joystick_label.position = Vector2(joystick_pos.x + 20, joystick_pos.y - 25)
	joystick_label.add_theme_color_override("font_color", Color.WHITE)
	bottom_controls.add_child(joystick_label)

func create_action_buttons():
	var button_size = Vector2(80, 60) * ui_scale
	var right_margin = 40 * ui_scale
	
	# Attack Button (primary action)
	attack_button = Button.new()
	attack_button.text = "⚔️\nATTACK"
	attack_button.position = Vector2(screen_size.x - right_margin - button_size.x, bottom_controls.size.y - 120 * ui_scale)
	attack_button.size = button_size
	attack_button.add_theme_color_override("font_color", Color.WHITE)
	attack_button.modulate = Color(1.0, 0.3, 0.3, 0.9)  # Red tint
	attack_button.pressed.connect(_on_attack_pressed)
	bottom_controls.add_child(attack_button)
	
	# Ability Button (secondary action)
	ability_button = Button.new()
	ability_button.text = "🎯\nSKILL"
	ability_button.position = Vector2(screen_size.x - right_margin - button_size.x * 2 - 20 * ui_scale, bottom_controls.size.y - 120 * ui_scale)
	ability_button.size = button_size
	ability_button.add_theme_color_override("font_color", Color.WHITE)
	ability_button.modulate = Color(0.3, 0.3, 1.0, 0.9)  # Blue tint
	ability_button.pressed.connect(_on_ability_pressed)
	bottom_controls.add_child(ability_button)
	
	# Interact Button (context-sensitive, hidden by default)
	interact_button = Button.new()
	interact_button.text = "💬 INTERACT"
	interact_button.position = Vector2(screen_size.x / 2 - 70 * ui_scale, bottom_controls.size.y - 60 * ui_scale)
	interact_button.size = Vector2(140, 40) * ui_scale
	interact_button.add_theme_color_override("font_color", Color.WHITE)
	interact_button.modulate = Color(0.3, 1.0, 0.3, 0.9)  # Green tint
	interact_button.visible = false  # Hidden until near interactable
	interact_button.pressed.connect(_on_interact_pressed)
	bottom_controls.add_child(interact_button)

func create_chat_area():
	# Chat input area (expandable)
	var chat_bg = ColorRect.new()
	chat_bg.color = Color(0, 0, 0, 0.7)
	chat_bg.position = Vector2(200 * ui_scale, bottom_controls.size.y - 40 * ui_scale)
	chat_bg.size = Vector2(screen_size.x - 400 * ui_scale, 35 * ui_scale)
	bottom_controls.add_child(chat_bg)
	
	var chat_label = Label.new()
	chat_label.text = "💬 Tap to chat..."
	chat_label.position = Vector2(210 * ui_scale, bottom_controls.size.y - 35 * ui_scale)
	chat_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	bottom_controls.add_child(chat_label)

# ===== SIDE PANELS =====
func create_side_panels():
	# Inventory Panel (slides in from right)
	inventory_panel = Panel.new()
	inventory_panel.position = Vector2(screen_size.x, 120 * ui_scale)  # Off-screen initially
	inventory_panel.size = Vector2(300 * ui_scale, screen_size.y - 320 * ui_scale)
	inventory_panel.modulate = Color(0.2, 0.2, 0.2, 0.95)
	add_child(inventory_panel)
	
	var inv_label = Label.new()
	inv_label.text = "INVENTORY"
	inv_label.position = Vector2(20, 20) * ui_scale
	inv_label.add_theme_color_override("font_color", Color.WHITE)
	inventory_panel.add_child(inv_label)
	
	# Add inventory grid (example)
	create_inventory_grid()

func create_inventory_grid():
	var grid_container = GridContainer.new()
	grid_container.columns = 4
	grid_container.position = Vector2(20, 60) * ui_scale
	grid_container.add_theme_constant_override("h_separation", 5)
	grid_container.add_theme_constant_override("v_separation", 5)
	inventory_panel.add_child(grid_container)
	
	# Create inventory slots
	for i in range(20):
		var slot = Button.new()
		slot.size = Vector2(60, 60) * ui_scale
		slot.text = str(i + 1)
		slot.modulate = Color(0.3, 0.3, 0.3, 0.8)
		grid_container.add_child(slot)

# ===== BUTTON HANDLERS =====
func _on_attack_pressed():
	print("Attack button pressed!")
	# Add attack logic here
	
func _on_ability_pressed():
	print("Ability button pressed!")
	# Add ability logic here
	
func _on_interact_pressed():
	print("Interact button pressed!")
	# Add interaction logic here
	
func _on_menu_pressed():
	print("Menu button pressed!")
	toggle_inventory_panel()

# ===== PANEL ANIMATIONS =====
func toggle_inventory_panel():
	var tween = create_tween()
	if inventory_panel.position.x >= screen_size.x:
		# Slide in from right
		tween.tween_property(inventory_panel, "position:x", screen_size.x - inventory_panel.size.x, 0.3)
	else:
		# Slide out to right
		tween.tween_property(inventory_panel, "position:x", screen_size.x, 0.3)

# ===== PUBLIC FUNCTIONS =====
func show_interact_button(show: bool = true):
	interact_button.visible = show

func update_health(current: int, maximum: int):
	health_bar.value = (float(current) / float(maximum)) * 100
	var health_label = top_hud.get_child(1) as Label
	health_label.text = "HP: %d/%d" % [current, maximum]

func update_mana(current: int, maximum: int):
	mana_bar.value = (float(current) / float(maximum)) * 100
	var mana_label = top_hud.get_child(3) as Label
	mana_label.text = "MP: %d/%d" % [current, maximum]

func update_level(level: int, exp_percent: float):
	level_label.text = "Level %d" % level
	exp_bar.value = exp_percent

# Network status handlers
func _on_network_status_changed(is_connected: bool, connection_type: String):
	var network_label = top_hud.get_child(6) as Label  # Network status label
	if is_connected:
		var icon = "📶" if connection_type == "WiFi" else "📱"
		network_label.text = "%s %s" % [icon, connection_type]
		network_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		network_label.text = "❌ Offline"
		network_label.add_theme_color_override("font_color", Color.RED)

func _on_connection_quality_changed(quality: String):
	var network_label = top_hud.get_child(6) as Label
	var color = Color.GREEN
	
	match quality:
		"Excellent":
			color = Color.GREEN
		"Good":
			color = Color.LIME_GREEN
		"Fair":
			color = Color.YELLOW
		"Poor":
			color = Color.ORANGE
		"Offline":
			color = Color.RED
	
	network_label.add_theme_color_override("font_color", color)

func update_network_status(status_text: String, is_connected: bool):
	var network_label = top_hud.get_child(6) as Label
	network_label.text = status_text
	var color = Color.GREEN if is_connected else Color.RED
	network_label.add_theme_color_override("font_color", color)