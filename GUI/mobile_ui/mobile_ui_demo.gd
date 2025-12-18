extends Node2D

# Mobile UI Demo Scene
# Shows the mobile interface in action with sample data

var mobile_ui: Control
var demo_timer: float = 0.0
var health: int = 800
var max_health: int = 1000
var mana: int = 300
var max_mana: int = 500

func _ready():
	print("Starting Mobile UI Demo...")
	
	# Load the mobile UI
	var mobile_ui_scene = preload("res://GUI/mobile_ui/mobile_game_ui.tscn")
	mobile_ui = mobile_ui_scene.instantiate()
	add_child(mobile_ui)
	
	# Start demo animations
	start_demo()

func start_demo():
	print("Demo: Mobile UI loaded and running")
	
	# Simulate some game events
	await get_tree().create_timer(2.0).timeout
	mobile_ui.show_interact_button(true)
	print("Demo: Interact button appeared (simulating near NPC)")
	
	await get_tree().create_timer(3.0).timeout
	mobile_ui.show_interact_button(false)
	print("Demo: Interact button hidden")
	
	# Start health/mana animation
	animate_stats()

func animate_stats():
	var tween = create_tween()
	tween.set_loops()
	
	# Animate health going down and up
	tween.tween_method(update_health_demo, 800, 200, 2.0)
	tween.tween_method(update_health_demo, 200, 800, 2.0)
	
	# Animate mana
	var mana_tween = create_tween()
	mana_tween.set_loops()
	mana_tween.tween_method(update_mana_demo, 300, 50, 1.5)
	mana_tween.tween_method(update_mana_demo, 50, 500, 3.0)

func update_health_demo(value: int):
	health = value
	mobile_ui.update_health(health, max_health)

func update_mana_demo(value: int):
	mana = value
	mobile_ui.update_mana(mana, max_mana)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("Demo: Simulating attack button press")
			KEY_2:
				print("Demo: Simulating ability button press")
			KEY_3:
				print("Demo: Toggling interact button")
				mobile_ui.show_interact_button(not mobile_ui.interact_button.visible)
			KEY_SPACE:
				print("Demo: Toggling inventory panel")
				mobile_ui.toggle_inventory_panel()

func _process(delta):
	demo_timer += delta
	
	# Update level/exp every 5 seconds
	if int(demo_timer) % 5 == 0 and int(demo_timer * 10) % 50 == 0:
		var level = 25 + int(demo_timer / 10)
		var exp_percent = (demo_timer * 10) % 100
		mobile_ui.update_level(level, exp_percent)