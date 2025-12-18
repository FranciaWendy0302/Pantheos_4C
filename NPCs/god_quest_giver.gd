extends Area2D

## God NPC that gives the first quest and starter equipment

@export var god_id: int = 1  # Set in inspector to match god
@export var god_name: String = "Zeus"  # Set in inspector

var player_in_range: bool = false
var quest_given: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		_show_interaction_prompt()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		_hide_interaction_prompt()

func _input(event):
	if not player_in_range:
		return
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_interact_with_god()

func _interact_with_god():
	"""Player interacts with the god NPC"""
	if quest_given:
		_show_already_completed_dialogue()
		return
	
	# Show quest dialogue
	_show_quest_dialogue()
	
	# Start the wave trial
	_start_wave_trial()
	
	quest_given = true

func _start_wave_trial():
	"""Start the 3-wave enemy trial"""
	# Find wave spawner in the level
	var wave_spawner = get_tree().get_first_node_in_group("wave_spawner")
	if wave_spawner and wave_spawner.has_method("start_trial"):
		print("[God NPC] Starting wave trial...")
		wave_spawner.start_trial()
		
		# Connect to completion signal
		if wave_spawner.has_signal("all_waves_completed"):
			wave_spawner.all_waves_completed.connect(_on_trial_completed)
	else:
		print("[God NPC] ERROR: No wave spawner found!")
		# Give equipment anyway for demo purposes
		_give_starter_equipment()

func _on_trial_completed():
	"""Called when player completes all 3 waves"""
	print("[God NPC] Trial completed! Giving rewards...")
	_give_starter_equipment()

func _show_interaction_prompt():
	"""Show 'Press E to interact' prompt"""
	# You can add a label here or use existing notification system
	print("[God NPC] Press E to talk to %s" % god_name)

func _hide_interaction_prompt():
	"""Hide interaction prompt"""
	pass

func _show_quest_dialogue():
	"""Show dialogue when accepting quest"""
	var player_class = PlayerManager.character_class
	
	var dialogue_text = ""
	match god_name:
		"Zeus":
			dialogue_text = "Excellent, %s. You have proven yourself worthy. Take this equipment and begin your journey. Show the world the power of lightning!" % PlayerManager.nickname
		"Athena":
			dialogue_text = "Wisdom guides your path, %s. Use this equipment to defend the innocent and uphold justice." % PlayerManager.nickname
		"Ares":
			dialogue_text = "War calls, %s! Take these weapons and show no mercy to your enemies!" % PlayerManager.nickname
		_:
			dialogue_text = "Welcome, champion. Take this equipment and prove your worth."
	
	print("[God NPC] %s: %s" % [god_name, dialogue_text])
	
	# Show notification
	var player_hud = get_tree().get_first_node_in_group("player_hud")
	if player_hud and player_hud.has_node("Control/Notification"):
		var notification = player_hud.get_node("Control/Notification")
		if notification.has_method("show_notification"):
			notification.show_notification("Quest Completed: Trial of the Gods\n+100 XP\nReceived Starter Equipment!")

func _show_already_completed_dialogue():
	"""Show dialogue if player already completed quest"""
	print("[God NPC] %s: You have already received my blessing, champion." % god_name)

func _give_starter_equipment():
	"""Give starter equipment based on player class"""
	var player_class = PlayerManager.character_class
	
	# This would give actual equipment items
	# For now, just print what would be given
	match player_class:
		"Mage":
			print("[God NPC] Giving Mage starter set:")
			print("  - Basic Staff (Fire skills)")
			print("  - Apprentice Robes")
			print("  - Cloth Boots")
			# TODO: Actually add items to inventory
			# PlayerManager.INVENTORY_DATA.add_item(load("res://Items/Equipment/Mage/basic_staff.tres"))
		
		"Swordsman":
			print("[God NPC] Giving Swordsman starter set:")
			print("  - Iron Sword")
			print("  - Leather Armor")
			print("  - Leather Boots")
		
		"Archer":
			print("[God NPC] Giving Archer starter set:")
			print("  - Short Bow")
			print("  - Leather Vest")
			print("  - Light Boots")
	
	# Give some starting gold
	if PlayerManager.player:
		PlayerManager.player.currency += 100
		print("[God NPC] +100 Gold")
