extends Node

# Android UI Manager
# Handles mobile-specific UI adaptations and touch controls

signal ui_adapted_for_mobile
signal virtual_controls_ready

var virtual_joystick: Control
var virtual_buttons: Dictionary = {}
var ui_scale_factor: float = 1.0
var is_ui_adapted: bool = false

func _ready():
	if not PlatformManager.is_platform_android():
		print("Android UI Manager: Not on Android, skipping UI adaptation")
		return
	
	print("Android UI Manager: Initializing mobile UI...")
	await get_tree().process_frame
	adapt_ui_for_mobile()

func adapt_ui_for_mobile():
	if is_ui_adapted:
		return
	
	print("Adapting UI for mobile device...")
	
	# Calculate UI scale based on screen DPI
	calculate_ui_scale()
	
	# Adapt existing UI elements
	adapt_existing_ui()
	
	# Create virtual controls
	create_virtual_controls()
	
	# Configure touch-friendly settings
	configure_mobile_settings()
	
	is_ui_adapted = true
	ui_adapted_for_mobile.emit()
	print("Mobile UI adaptation complete!")

func calculate_ui_scale():
	var screen_size = PlatformManager.get_screen_size()
	var screen_dpi = PlatformManager.get_screen_dpi()
	
	# Base scale on screen density
	if screen_dpi > 0:
		ui_scale_factor = screen_dpi / 160.0  # 160 DPI is Android's baseline
		ui_scale_factor = clamp(ui_scale_factor, 0.8, 2.5)
	else:
		# Fallback based on screen size
		var base_width = 1080.0  # Common mobile width
		ui_scale_factor = screen_size.x / base_width
		ui_scale_factor = clamp(ui_scale_factor, 0.8, 2.0)
	
	print("UI Scale Factor: ", ui_scale_factor)

func adapt_existing_ui():
	# Scale UI elements for touch interaction
	var ui_nodes = get_tree().get_nodes_in_group("ui_scalable")
	
	for node in ui_nodes:
		if node is Control:
			scale_control_for_touch(node)

func scale_control_for_touch(control: Control):
	# Minimum touch target size (44dp in Android guidelines)
	var min_touch_size = 44 * ui_scale_factor
	
	if control.size.x < min_touch_size:
		control.size.x = min_touch_size
	if control.size.y < min_touch_size:
		control.size.y = min_touch_size
	
	# Add touch-friendly margins
	if control is Button:
		control.add_theme_constant_override("h_separation", 8 * ui_scale_factor)

func create_virtual_controls():
	var main_scene = get_tree().current_scene
	if not main_scene:
		return
	
	# Create virtual joystick for movement
	create_virtual_joystick(main_scene)
	
	# Create virtual action buttons
	create_virtual_action_buttons(main_scene)
	
	virtual_controls_ready.emit()

func create_virtual_joystick(parent: Node):
	virtual_joystick = AndroidInputManager.create_virtual_joystick(
		Vector2(100 * ui_scale_factor, get_viewport().size.y - 150 * ui_scale_factor),
		80 * ui_scale_factor
	)
	
	virtual_joystick.name = "VirtualJoystick"
	parent.add_child(virtual_joystick)
	
	# Connect joystick to movement input
	setup_joystick_input()

func setup_joystick_input():
	# This would connect the virtual joystick to the player movement
	# Implementation depends on your specific player controller
	pass

func create_virtual_action_buttons(parent: Node):
	var screen_size = get_viewport().size
	
	# Attack button
	var attack_button = create_virtual_button("Attack", Vector2(screen_size.x - 100 * ui_scale_factor, screen_size.y - 100 * ui_scale_factor))
	virtual_buttons["attack"] = attack_button
	parent.add_child(attack_button)
	
	# Ability button
	var ability_button = create_virtual_button("Ability", Vector2(screen_size.x - 200 * ui_scale_factor, screen_size.y - 100 * ui_scale_factor))
	virtual_buttons["ability"] = ability_button
	parent.add_child(ability_button)
	
	# Interact button (appears when near interactable)
	var interact_button = create_virtual_button("Interact", Vector2(screen_size.x / 2, screen_size.y - 100 * ui_scale_factor))
	interact_button.visible = false
	virtual_buttons["interact"] = interact_button
	parent.add_child(interact_button)

func create_virtual_button(text: String, position: Vector2) -> Button:
	var button = Button.new()
	button.text = text
	button.position = position
	button.size = Vector2(80 * ui_scale_factor, 60 * ui_scale_factor)
	
	# Style for mobile
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_color_pressed", Color.YELLOW)
	button.modulate = Color(1, 1, 1, 0.8)  # Semi-transparent
	
	return button

func configure_mobile_settings():
	# Adjust game settings for mobile performance
	var mobile_settings = {
		"rendering/textures/canvas_textures/default_texture_filter": 1,
		"rendering/anti_aliasing/quality/msaa_2d": 0,
		"rendering/anti_aliasing/quality/msaa_3d": 0,
		"audio/driver/mix_rate": 22050,  # Lower audio quality for performance
	}
	
	for setting in mobile_settings:
		if ProjectSettings.has_setting(setting):
			ProjectSettings.set_setting(setting, mobile_settings[setting])

# Public functions for game integration
func show_interact_button(show: bool = true):
	if "interact" in virtual_buttons:
		virtual_buttons["interact"].visible = show

func get_virtual_joystick_input() -> Vector2:
	# Return normalized input from virtual joystick
	# This would be implemented based on your joystick logic
	return Vector2.ZERO

func is_virtual_button_pressed(button_name: String) -> bool:
	if button_name in virtual_buttons:
		return virtual_buttons[button_name].is_pressed()
	return false

func set_ui_visibility(visible: bool):
	if virtual_joystick:
		virtual_joystick.visible = visible
	
	for button in virtual_buttons.values():
		button.visible = visible

func cleanup_virtual_controls():
	if virtual_joystick:
		virtual_joystick.queue_free()
		virtual_joystick = null
	
	for button in virtual_buttons.values():
		button.queue_free()
	
	virtual_buttons.clear()