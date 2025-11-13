extends Node2D

const TUTORIAL_NPC: NPCResource = preload("res://npc/00_npcs/tutorial_narrator.tres")
const NEXT_LEVEL: String = "res://Levels/Area01/01.tscn"
const SLIME_SCENE = preload("res://Enemies/Slime/slime.tscn")
const GOBLIN_SCENE = preload("res://Enemies/Goblin/goblin.tscn")
const AMULET_ITEM = preload("res://Items/amulet.tres")
# Dark wizard boss is a script, not a scene - we'll instantiate it manually
const DARK_WIZARD_SCRIPT = preload("res://Levels/Dungeon1/dark_wizard/script/dark_wizard_boss.gd")
const ChaseStateScript = preload("res://Enemies/Scripts/states/enemy_state_chase.gd")

enum TutorialStep {
	WELCOME,
	MOVEMENT,
	ATTACK,
	SKILLS,
	INVENTORY,
	CURRENCY,
	LOOT,
	QUEST_WAVES,
	ITEM_STATS,
	LEVEL_UP,
	BOSS_WAVES,
	COMPLETE
}

var current_step: TutorialStep = TutorialStep.WELCOME
var movement_completed: bool = false
var attack_completed: bool = false
var skills_completed: bool = false
var inventory_completed: bool = false
var currency_completed: bool = false
var loot_completed: bool = false
var quest_waves_completed: bool = false
var item_stats_completed: bool = false
var level_up_explained: bool = false
var boss_waves_completed: bool = false

# Wave system (part 2 - slimes)
var current_wave: int = 0
var enemies_killed_in_wave: int = 0
var wave_enemies: Array[Node] = []
var wave_sizes: Array[int] = [3, 5, 10]
var wave_spawn_positions: Array[Vector2] = []
var wave_completing: bool = false  # Prevent multiple simultaneous wave completions

var tutorial_npc: NPC = null
var tutorial_started: bool = false

func _ready() -> void:
	# Wait a moment for everything to load
	await get_tree().create_timer(0.5).timeout
	
	# Connect enemy signals and level up signal first
	_connect_enemy_signals()
	PlayerManager.player_leveled_up.connect(_on_player_leveled_up)
	
	# Get reference to tutorial NPC
	tutorial_npc = get_node_or_null("TutorialNPC")
	if tutorial_npc:
		var dialog_interaction = tutorial_npc.get_node_or_null("DialogInteraction")
		if dialog_interaction:
			dialog_interaction.player_interacted.connect(_on_tutorial_npc_interacted)
	
	# Check if tutorial was already completed - if so, skip tutorial
	if SaveManager.current_save.get("tutorial_completed", false):
		current_step = TutorialStep.COMPLETE
		return
	
	# Check if we have saved tutorial progress - if so, resume from there
	var tutorial_progress = SaveManager.current_save.get("tutorial_progress", {})
	if tutorial_progress.has("current_step") and tutorial_progress.current_step >= 0:
		# Resume tutorial from saved progress
		tutorial_started = true
		_ensure_tutorial_quest()  # Ensure quest exists when resuming
		resume_tutorial(tutorial_progress)
	pass

func _on_tutorial_npc_interacted() -> void:
	# Only give quest on first interaction
	if not tutorial_started:
		tutorial_started = true
		
		# Show brief welcome dialog and give quest
		var welcome_dialogs: Array[DialogItem] = []
		
		var dialog1: DialogText = DialogText.new()
		dialog1.npc_info = TUTORIAL_NPC
		dialog1.text = "Welcome, " + PlayerManager.nickname + "! I have a quest for you to learn the basics of this world."
		welcome_dialogs.append(dialog1)
		
		var dialog2: DialogText = DialogText.new()
		dialog2.npc_info = TUTORIAL_NPC
		dialog2.text = "Complete the tutorial quest to learn movement, combat, and game mechanics. Good luck!"
		welcome_dialogs.append(dialog2)
		
		DialogSystem.show_dialog(welcome_dialogs)
		await DialogSystem.finished
		
		# Give the tutorial quest
		QuestManager.update_quest("Tutorial Quest", "", false)
		
		# Start the actual tutorial steps
		current_step = TutorialStep.MOVEMENT
		show_movement_tutorial()
	pass

func _connect_enemy_signals() -> void:
	# Connect to existing enemies
	for child in get_children():
		if child is Enemy:
			if not child.enemy_destroyed.is_connected(_on_enemy_destroyed):
				child.enemy_destroyed.connect(_on_enemy_destroyed)
	pass

func _ensure_tutorial_quest() -> void:
	# Ensure the tutorial quest is active in QuestManager
	# Check if tutorial quest already exists
	var tutorial_quest_exists = false
	var quest_index = -1
	for i in range(QuestManager.current_quests.size()):
		var quest = QuestManager.current_quests[i]
		if quest.has("title") and quest.title.to_lower().contains("tutorial"):
			tutorial_quest_exists = true
			quest_index = i
			break
	
	# If tutorial quest doesn't exist and tutorial is not completed, create it
	if not tutorial_quest_exists and not SaveManager.current_save.get("tutorial_completed", false):
		# Create tutorial quest
		var tutorial_progress = SaveManager.current_save.get("tutorial_progress", {})
		var _current_step_value = tutorial_progress.get("current_step", TutorialStep.WELCOME)
		
		# Determine quest status based on current step and completion flags
		var is_complete = false
		var completed_steps = []
		
		# Add completed steps based on completion flags
		if tutorial_progress.get("movement_completed", false):
			completed_steps.append("movement")
		if tutorial_progress.get("attack_completed", false):
			completed_steps.append("attack")
		if tutorial_progress.get("skills_completed", false):
			completed_steps.append("skills")
		if tutorial_progress.get("inventory_completed", false):
			completed_steps.append("inventory")
		if tutorial_progress.get("currency_completed", false):
			completed_steps.append("currency")
		if tutorial_progress.get("loot_completed", false):
			completed_steps.append("loot")
		if tutorial_progress.get("quest_waves_completed", false):
			completed_steps.append("quest_waves")
		if tutorial_progress.get("item_stats_completed", false):
			completed_steps.append("item_stats")
		
		# Check if tutorial is complete
		if SaveManager.current_save.get("tutorial_completed", false):
			is_complete = true
		
		# Update or create tutorial quest
		QuestManager.update_quest("Tutorial Quest", "", is_complete)
		
		# Add completed steps to the quest
		quest_index = QuestManager.get_quest_index_by_title("Tutorial Quest")
		if quest_index >= 0 and completed_steps.size() > 0:
			var quest = QuestManager.current_quests[quest_index]
			for step in completed_steps:
				if not quest.completed_steps.has(step.to_lower()):
					quest.completed_steps.append(step.to_lower())
	pass

func _update_tutorial_quest_progress(step_name: String) -> void:
	# Update tutorial quest when a step is completed
	var quest_index = QuestManager.get_quest_index_by_title("Tutorial Quest")
	if quest_index >= 0:
		var quest = QuestManager.current_quests[quest_index]
		if not quest.completed_steps.has(step_name.to_lower()):
			QuestManager.update_quest("Tutorial Quest", step_name, false)
	pass

func _on_enemy_destroyed(_hurt_box: HurtBox) -> void:
	if current_step == TutorialStep.QUEST_WAVES:
		enemies_killed_in_wave += 1
		_check_wave_complete()
	pass

func _on_player_leveled_up() -> void:
	if current_step >= TutorialStep.QUEST_WAVES and not level_up_explained:
		# Player leveled up during quest waves
		level_up_explained = true
		# Delay explanation until after current dialog
		if not DialogSystem.is_active:
			show_level_up_explanation()
	pass

func start_tutorial() -> void:
	current_step = TutorialStep.WELCOME
	show_welcome_dialog()
	pass

func start_tutorial_with_intro() -> void:
	# Create tutorial quest when starting fresh
	QuestManager.update_quest("Tutorial Quest", "", false)
	# Show intro dialog explaining the game before tutorial
	show_game_intro_dialog()
	pass

func show_game_intro_dialog() -> void:
	var intro_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Welcome, " + PlayerManager.nickname + "! Welcome to Pantheos."
	intro_dialogs.append(dialog1)
	
	var dialog2: DialogText = DialogText.new()
	dialog2.npc_info = TUTORIAL_NPC
	dialog2.text = "This is a multipath adventure. Your journey will be different based on the class you chose and the choices you make."
	intro_dialogs.append(dialog2)
	
	var dialog3: DialogText = DialogText.new()
	dialog3.npc_info = TUTORIAL_NPC
	dialog3.text = "Pantheos is an item-based game. Many items can help you clear quests and fight enemies. Every piece of equipment has unique skills and abilities."
	intro_dialogs.append(dialog3)
	
	var dialog4: DialogText = DialogText.new()
	dialog4.npc_info = TUTORIAL_NPC
	dialog4.text = "There are five classes available: Swordsman, Mage, Assassin, and Support. Each class has unique abilities and playstyles."
	intro_dialogs.append(dialog4)
	
	var dialog5: DialogText = DialogText.new()
	dialog5.npc_info = TUTORIAL_NPC
	dialog5.text = "After completing this tutorial, each class will receive different story quests tailored to their strengths. Swordsmen protect kingdoms, Mages unlock ancient mysteries, Assassins work in the shadows, and Support classes aid their allies."
	intro_dialogs.append(dialog5)
	
	var dialog6: DialogText = DialogText.new()
	dialog6.npc_info = TUTORIAL_NPC
	dialog6.text = "Now, let me teach you the basics of combat and movement."
	intro_dialogs.append(dialog6)
	
	DialogSystem.show_dialog(intro_dialogs)
	await DialogSystem.finished
	
	# Start movement tutorial
	current_step = TutorialStep.MOVEMENT
	show_movement_tutorial()
	pass

func resume_tutorial(progress: Dictionary) -> void:
	# Restore completion flags
	if progress.has("movement_completed"):
		movement_completed = progress.movement_completed
	if progress.has("attack_completed"):
		attack_completed = progress.attack_completed
	if progress.has("skills_completed"):
		skills_completed = progress.skills_completed
	if progress.has("inventory_completed"):
		inventory_completed = progress.inventory_completed
	if progress.has("currency_completed"):
		currency_completed = progress.currency_completed
	if progress.has("loot_completed"):
		loot_completed = progress.loot_completed
	if progress.has("quest_waves_completed"):
		quest_waves_completed = progress.quest_waves_completed
	if progress.has("item_stats_completed"):
		item_stats_completed = progress.item_stats_completed
	
	# Restore current step
	var saved_step = progress.get("current_step", TutorialStep.WELCOME)
	current_step = saved_step
	
	# Resume from the appropriate step
	match current_step:
		TutorialStep.WELCOME:
			current_step = TutorialStep.MOVEMENT
			show_movement_tutorial()
		TutorialStep.MOVEMENT:
			if movement_completed:
				current_step = TutorialStep.ATTACK
				show_attack_tutorial()
			else:
				show_movement_tutorial()
		TutorialStep.ATTACK:
			if attack_completed:
				current_step = TutorialStep.SKILLS
				show_skills_tutorial()
			else:
				show_attack_tutorial()
		TutorialStep.SKILLS:
			if skills_completed:
				current_step = TutorialStep.INVENTORY
				show_inventory_tutorial()
			else:
				show_skills_tutorial()
		TutorialStep.INVENTORY:
			if inventory_completed:
				current_step = TutorialStep.CURRENCY
				show_currency_tutorial()
			else:
				show_inventory_tutorial()
		TutorialStep.CURRENCY:
			if currency_completed:
				current_step = TutorialStep.LOOT
				show_loot_tutorial()
			else:
				show_currency_tutorial()
		TutorialStep.LOOT:
			if loot_completed:
				current_step = TutorialStep.QUEST_WAVES
				show_quest_waves_tutorial()
			else:
				show_loot_tutorial()
		TutorialStep.QUEST_WAVES:
			if quest_waves_completed:
				current_step = TutorialStep.ITEM_STATS
				show_item_stats_tutorial()
			else:
				# Resume wave system
				current_step = TutorialStep.QUEST_WAVES
				quest_waves_completed = false
				current_wave = 0
				start_wave()
		TutorialStep.ITEM_STATS:
			if item_stats_completed:
				current_step = TutorialStep.COMPLETE
				complete_tutorial()
			else:
				show_item_stats_tutorial()
		_:
			# Default: start from movement
			current_step = TutorialStep.MOVEMENT
			show_movement_tutorial()
	pass

func show_welcome_dialog() -> void:
	var welcome_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Welcome, " + PlayerManager.nickname + "! Welcome to Pantheos."
	welcome_dialogs.append(dialog1)
	
	var dialog2: DialogText = DialogText.new()
	dialog2.npc_info = TUTORIAL_NPC
	dialog2.text = "Let me teach you the basics of combat and movement."
	welcome_dialogs.append(dialog2)
	
	DialogSystem.show_dialog(welcome_dialogs)
	await DialogSystem.finished
	
	# Start movement tutorial
	current_step = TutorialStep.MOVEMENT
	show_movement_tutorial()
	pass

func show_movement_tutorial() -> void:
	var movement_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "First, let's learn how to move. Right-click on the ground to move your character."
	movement_dialogs.append(dialog1)
	
	DialogSystem.show_dialog(movement_dialogs)
	await DialogSystem.finished
	
	# Wait for player to right-click
	movement_completed = false
	PlayerHud.queue_notificaiton("Movement", "Right-click on the ground to move!")
	pass

func show_attack_tutorial() -> void:
	var attack_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Good! Now let's learn how to attack. Press SPACEBAR to attack."
	attack_dialogs.append(dialog1)
	
	DialogSystem.show_dialog(attack_dialogs)
	await DialogSystem.finished
	
	# Wait for player to attack
	attack_completed = false
	PlayerHud.queue_notificaiton("Attack", "Press SPACEBAR to attack!")
	pass

func show_skills_tutorial() -> void:
	var skills_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	
	# Customize skill description based on selected class
	var skills_text: String
	if PlayerManager.selected_class == "Archer":
		skills_text = "Excellent! Now let's learn about your skills. Press Q for Invisibility, W for Arrow Barrage, and E for Charge Big Arrow."
	else:
		skills_text = "Excellent! Now let's learn about your skills. Press Q for Dash, W for Charge Dash, and E for Spin Attack."
	
	dialog1.text = skills_text
	skills_dialogs.append(dialog1)
	
	DialogSystem.show_dialog(skills_dialogs)
	await DialogSystem.finished
	
	# Wait for player to use skills
	skills_completed = false
	PlayerHud.queue_notificaiton("Skills", "Try using Q, W, or E skills!")
	pass

func show_inventory_tutorial() -> void:
	var inventory_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Now let's learn about your inventory. Press ESC to open your inventory menu."
	inventory_dialogs.append(dialog1)
	
	DialogSystem.show_dialog(inventory_dialogs)
	await DialogSystem.finished
	
	# Wait for player to open inventory
	inventory_completed = false
	PlayerHud.queue_notificaiton("Inventory", "Press ESC to open inventory!")
	pass

func show_currency_tutorial() -> void:
	var currency_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Good! You'll notice a green orb in your inventory. That's the currency of this world called 'Gem'."
	currency_dialogs.append(dialog1)
	
	var dialog2: DialogText = DialogText.new()
	dialog2.npc_info = TUTORIAL_NPC
	dialog2.text = "Gems can be used to purchase items from shops. You'll earn gems by defeating monsters and completing quests."
	currency_dialogs.append(dialog2)
	
	DialogSystem.show_dialog(currency_dialogs)
	await DialogSystem.finished
	
	currency_completed = true
	# Update tutorial quest
	_update_tutorial_quest_progress("currency")
	# Auto-save progress
	SaveManager.save_game()
	show_loot_tutorial()
	pass

func show_loot_tutorial() -> void:
	var loot_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Let me explain how you can get loot. When you defeat monsters, they drop items automatically."
	loot_dialogs.append(dialog1)
	
	var dialog2: DialogText = DialogText.new()
	dialog2.npc_info = TUTORIAL_NPC
	dialog2.text = "You can get loot from normal monsters, mini bosses, and final bosses. You also get rewards after completing quests."
	loot_dialogs.append(dialog2)
	
	DialogSystem.show_dialog(loot_dialogs)
	await DialogSystem.finished
	
	loot_completed = true
	# Update tutorial quest
	_update_tutorial_quest_progress("loot")
	# Auto-save progress
	SaveManager.save_game()
	show_quest_waves_tutorial()
	pass

func show_quest_waves_tutorial() -> void:
	var quest_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Now let's test your combat skills! I'll send waves of slimes for you to defeat."
	quest_dialogs.append(dialog1)
	
	var dialog2: DialogText = DialogText.new()
	dialog2.npc_info = TUTORIAL_NPC
	dialog2.text = "You need to clear 3 waves: first wave has 3 slimes, second has 5, and third has 10 slimes."
	quest_dialogs.append(dialog2)
	
	var dialog3: DialogText = DialogText.new()
	dialog3.npc_info = TUTORIAL_NPC
	dialog3.text = "After completing all waves, you'll receive a special amulet as a reward!"
	quest_dialogs.append(dialog3)
	
	DialogSystem.show_dialog(quest_dialogs)
	await DialogSystem.finished
	
	# Start wave system
	current_step = TutorialStep.QUEST_WAVES
	quest_waves_completed = false
	current_wave = 0
	start_wave()
	pass

func start_wave() -> void:
	# Safety check to prevent out of bounds access
	if current_wave < 0 or current_wave >= wave_sizes.size():
		# All waves complete
		quest_waves_completed = true
		# Update tutorial quest
		_update_tutorial_quest_progress("quest_waves")
		# Auto-save progress
		SaveManager.save_game()
		reward_amulet()
		return
	
	enemies_killed_in_wave = 0
	wave_completing = false
	var wave_size = wave_sizes[current_wave]
	
	# Show wave counter and update it
	PlayerHud.show_kill_counter()
	PlayerHud.update_wave_counter(current_wave + 1, enemies_killed_in_wave, wave_size)
	
	# Spawn slimes around player in varied locations
	var player_pos = PlayerManager.player.global_position
	wave_enemies.clear()
	
	# Define spawn areas (quadrants around player)
	var spawn_areas = [
		Vector2(1, 0),    # Right
		Vector2(-1, 0),   # Left
		Vector2(0, 1),    # Down
		Vector2(0, -1),   # Up
		Vector2(1, 1),    # Bottom-right
		Vector2(-1, 1),   # Bottom-left
		Vector2(1, -1),   # Top-right
		Vector2(-1, -1)   # Top-left
	]
	
	for i in wave_size:
		var slime = SLIME_SCENE.instantiate()
		add_child(slime)
		
		# Pick a random spawn area (cycle through areas but also add randomness)
		var area_index = (i + randi() % 3) % spawn_areas.size()
		var base_direction = spawn_areas[area_index]
		
		# Add randomness to angle and distance
		var base_angle = base_direction.angle()
		var angle_variation = randf_range(-0.5, 0.5)  # Random variation in radians
		var angle = base_angle + angle_variation
		
		# Vary distance between 120 and 200 pixels
		var distance = randf_range(120.0, 200.0)
		
		# Calculate spawn position
		var offset = Vector2(cos(angle), sin(angle)) * distance
		slime.global_position = player_pos + offset
		
		# Connect to death signal
		if not slime.enemy_destroyed.is_connected(_on_enemy_destroyed):
			slime.enemy_destroyed.connect(_on_enemy_destroyed)
		
		wave_enemies.append(slime)
	pass

func _check_wave_complete() -> void:
	# Safety check to prevent out of bounds access
	if current_wave < 0 or current_wave >= wave_sizes.size():
		return
	
	# Prevent multiple simultaneous wave completions
	if wave_completing:
		return
	
	var wave_size = wave_sizes[current_wave]
	
	# Update wave counter
	PlayerHud.update_wave_counter(current_wave + 1, enemies_killed_in_wave, wave_size)
	
	if enemies_killed_in_wave >= wave_size:
		wave_completing = true
		# Wave complete
		await get_tree().create_timer(2.0).timeout
		current_wave += 1
		if current_wave < wave_sizes.size():
			# Next wave
			await get_tree().create_timer(2.0).timeout
			wave_completing = false
			start_wave()
		else:
			# All waves complete
			wave_completing = false
			PlayerHud.hide_kill_counter()
			quest_waves_completed = true
			# Update tutorial quest
			_update_tutorial_quest_progress("quest_waves")
			# Auto-save progress
			SaveManager.save_game()
			# Remove all slimes and spawn only goblins
			_remove_all_slimes_and_spawn_goblins()
	pass

func _remove_all_slimes_and_spawn_goblins() -> void:
	# Remove all slimes immediately
	for enemy in wave_enemies:
		if is_instance_valid(enemy):
			# Force remove from scene immediately
			if enemy.get_parent():
				enemy.get_parent().remove_child(enemy)
			enemy.queue_free()
	wave_enemies.clear()
	
	# Also remove any remaining slimes in the scene
	for child in get_children():
		if child is Enemy:
			# Check if it's a slime (by checking if it's in our wave_enemies or by name)
			if is_instance_valid(child):
				if child.get_parent():
					child.get_parent().remove_child(child)
				child.queue_free()
	
	# Wait a moment
	await get_tree().create_timer(1.0).timeout
	
	# Spawn goblins around player in varied locations
	var player_pos = PlayerManager.player.global_position
	var goblin_count = 5  # Spawn 5 goblins
	
	# Define spawn areas (quadrants around player)
	var spawn_areas = [
		Vector2(1, 0),    # Right
		Vector2(-1, 0),   # Left
		Vector2(0, 1),    # Down
		Vector2(0, -1),   # Up
		Vector2(1, 1),    # Bottom-right
		Vector2(-1, 1),   # Bottom-left
		Vector2(1, -1),   # Top-right
		Vector2(-1, -1)   # Top-left
	]
	
	for i in goblin_count:
		var goblin = GOBLIN_SCENE.instantiate()
		add_child(goblin)
		
		# Pick a random spawn area (cycle through areas but also add randomness)
		var area_index = (i + randi() % 3) % spawn_areas.size()
		var base_direction = spawn_areas[area_index]
		
		# Add randomness to angle and distance
		var base_angle = base_direction.angle()
		var angle_variation = randf_range(-0.5, 0.5)  # Random variation in radians
		var angle = base_angle + angle_variation
		
		# Vary distance between 120 and 200 pixels
		var distance = randf_range(120.0, 200.0)
		
		# Calculate spawn position
		var offset = Vector2(cos(angle), sin(angle)) * distance
		goblin.global_position = player_pos + offset
		
		# Connect to death signal
		if not goblin.enemy_destroyed.is_connected(_on_enemy_destroyed):
			goblin.enemy_destroyed.connect(_on_enemy_destroyed)
		
		wave_enemies.append(goblin)
	
	# Wait for player to defeat goblins
	await get_tree().create_timer(5.0).timeout
	
	# Give reward
	reward_amulet()
	pass

func reward_amulet() -> void:
	# Give amulet to player
	PlayerManager.INVENTORY_DATA.add_item(AMULET_ITEM, 1)
	
	await get_tree().create_timer(2.5).timeout
	
	# Show item stats tutorial
	current_step = TutorialStep.ITEM_STATS
	show_item_stats_tutorial()
	pass

func show_item_stats_tutorial() -> void:
	var stats_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Excellent work! You've received an amulet. Now let me explain how equipment works."
	stats_dialogs.append(dialog1)
	
	var dialog2: DialogText = DialogText.new()
	dialog2.npc_info = TUTORIAL_NPC
	dialog2.text = "Items that you equip can give stat boosts to your character. Equip the amulet from your inventory to see its effects!"
	stats_dialogs.append(dialog2)
	
	DialogSystem.show_dialog(stats_dialogs)
	await DialogSystem.finished
	
	item_stats_completed = true
	# Update tutorial quest
	_update_tutorial_quest_progress("item_stats")
	# Auto-save progress
	SaveManager.save_game()
	
	# Check if player leveled up during waves
	if level_up_explained:
		# Already explained level up
		complete_tutorial()
	else:
		# Wait a bit then complete, level up explanation will come if needed
		await get_tree().create_timer(3.0).timeout
		complete_tutorial()
	pass

func show_level_up_explanation() -> void:
	if DialogSystem.is_active:
		return  # Wait for current dialog to finish
	
	var level_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "I noticed you leveled up! Accumulating enough experience points (EXP) can level up your character."
	level_dialogs.append(dialog1)
	
	var dialog2: DialogText = DialogText.new()
	dialog2.npc_info = TUTORIAL_NPC
	dialog2.text = "When you level up, your stats increase automatically. This makes you stronger and more resilient!"
	level_dialogs.append(dialog2)
	
	DialogSystem.show_dialog(level_dialogs)
	await DialogSystem.finished
	
	# Continue with tutorial
	if item_stats_completed:
		complete_tutorial()
	pass

func complete_tutorial() -> void:
	# Tutorial complete - proceed to boss fight
	var complete_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Perfect! You've learned the basics. Now teleport to the dungeon to face the Dark Wizard boss!"
	complete_dialogs.append(dialog1)
	
	DialogSystem.show_dialog(complete_dialogs)
	await DialogSystem.finished
	
	# Mark tutorial as completed in save
	SaveManager.current_save.tutorial_completed = true
	SaveManager.save_game()
	
	# Teleport to dungeon level 04 for boss fight
	current_step = TutorialStep.COMPLETE
	# Set target_transition to "PlayerSpawn" so the PlayerSpawn node knows to place the player there
	LevelManager.load_new_level("res://Levels/Dungeon1/04.tscn", "PlayerSpawn", Vector2.ZERO)
	pass

func _input(event: InputEvent) -> void:
	# Don't check input if dialog is active or tutorial is complete
	if DialogSystem.is_active or current_step == TutorialStep.COMPLETE:
		return
	
	# Check for movement (right-click)
	if current_step == TutorialStep.MOVEMENT and not movement_completed:
		if event is InputEventMouseButton:
			var mouse_event = event as InputEventMouseButton
			if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
				movement_completed = true
				# Update tutorial quest
				_update_tutorial_quest_progress("movement")
				# Wait 2-3 seconds before showing next dialog
				await get_tree().create_timer(2.5).timeout
				current_step = TutorialStep.ATTACK
				# Auto-save progress when step changes
				SaveManager.save_game()
				show_attack_tutorial()
				return
	
	# Check for attack (spacebar)
	if current_step == TutorialStep.ATTACK and not attack_completed:
		if event.is_action_pressed("attack"):
			attack_completed = true
			# Update tutorial quest
			_update_tutorial_quest_progress("attack")
			# Wait 2-3 seconds before showing next dialog
			await get_tree().create_timer(2.5).timeout
			current_step = TutorialStep.SKILLS
			# Auto-save progress when step changes
			SaveManager.save_game()
			show_skills_tutorial()
			return
	
	# Check for skills (Q, W, or E)
	if current_step == TutorialStep.SKILLS and not skills_completed:
		if event is InputEventKey:
			var key_event = event as InputEventKey
			if key_event.pressed:
				match key_event.keycode:
					KEY_Q, KEY_W, KEY_E:
						skills_completed = true
						# Update tutorial quest
						_update_tutorial_quest_progress("skills")
						# Wait 2-3 seconds before showing next dialog
						await get_tree().create_timer(2.5).timeout
						current_step = TutorialStep.INVENTORY
						# Auto-save progress when step changes
						SaveManager.save_game()
						show_inventory_tutorial()
						return
	
	# Check for inventory (ESC/pause) - detect when opened
	if current_step == TutorialStep.INVENTORY and not inventory_completed:
		if event.is_action_pressed("pause") and not PauseMenu.is_paused:
			# Player is opening inventory - wait for it to be shown
			await PauseMenu.shown
			# Now wait for player to close inventory
			await PauseMenu.hidden
			inventory_completed = true
			# Update tutorial quest
			_update_tutorial_quest_progress("inventory")
			# Wait 2-3 seconds before showing next dialog
			await get_tree().create_timer(2.5).timeout
			current_step = TutorialStep.CURRENCY
			# Auto-save progress when step changes
			SaveManager.save_game()
			show_currency_tutorial()
			return
	pass


# Boss waves system
var boss_wave: int = 0
var boss_waves_sizes: Array[int] = [1, 1, 1]  # 3 waves, 1 boss each
var boss_wave_bosses: Array[Node] = []
var boss_wave_completing: bool = false

func show_boss_waves_tutorial() -> void:
	var boss_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Now for the final challenge! Face the Dark Wizard boss in 3 waves of increasing difficulty."
	boss_dialogs.append(dialog1)
	
	var dialog2: DialogText = DialogText.new()
	dialog2.npc_info = TUTORIAL_NPC
	dialog2.text = "Wave 1: The boss will only fire dark orbs. Wave 2: Dark beams. Wave 3: Both attacks!"
	boss_dialogs.append(dialog2)
	
	var dialog3: DialogText = DialogText.new()
	dialog3.npc_info = TUTORIAL_NPC
	dialog3.text = "Defeat all 3 bosses to complete the tutorial!"
	boss_dialogs.append(dialog3)
	
	DialogSystem.show_dialog(boss_dialogs)
	await DialogSystem.finished
	
	# Show wave counter
	PlayerHud.show_kill_counter()
	
	# Start boss wave system
	boss_wave = 0
	boss_waves_completed = false
	start_boss_wave()
	pass

func start_boss_wave() -> void:
	if boss_wave < 0 or boss_wave >= boss_waves_sizes.size():
		# All waves complete
		boss_waves_completed = true
		complete_boss_tutorial()
		return
	
	boss_wave_completing = false
	
	# Update wave counter
	PlayerHud.update_wave_counter(boss_wave + 1, 0, 1)
	
	# Spawn boss - create Node2D and attach script
	var boss = Node2D.new()
	boss.set_script(DARK_WIZARD_SCRIPT)
	add_child(boss)
	
	# Create required child nodes for boss
	_setup_boss_structure(boss)
	
	# Configure boss based on wave (this sets HP)
	_configure_boss_for_wave(boss, boss_wave)
	
	# Position boss away from player
	var player_pos = PlayerManager.player.global_position
	boss.global_position = player_pos + Vector2(200, -100)
	
	# Connect to boss death signal (we'll need to modify boss or track HP)
	boss_wave_bosses.append(boss)
	
	# Start monitoring boss HP
	_start_boss_monitoring(boss)
	pass

func _setup_boss_structure(boss: Node2D) -> void:
	# Create BossNode
	var boss_node = Node2D.new()
	boss_node.name = "BossNode"
	boss.add_child(boss_node)
	
	# Create PositionTargets (boss needs at least one position)
	var position_targets = Node2D.new()
	position_targets.name = "PositionTargets"
	position_targets.visible = false
	boss.add_child(position_targets)
	
	# Add a position marker
	var pos_marker = Sprite2D.new()
	position_targets.add_child(pos_marker)
	pos_marker.global_position = boss.global_position
	
	# Create BeamAttacks (empty for now, beams will be optional)
	var beam_attacks = Node2D.new()
	beam_attacks.name = "BeamAttacks"
	boss.add_child(beam_attacks)
	
	# Create minimal required nodes (HurtBox, HitBox, AnimationPlayers, etc.)
	# These are required by the boss script
	var hit_box = preload("res://GeneralNodes/HitBox/hit_box.tscn").instantiate()
	boss_node.add_child(hit_box)
	
	var hurt_box = preload("res://GeneralNodes/HurtBox/hurt_box.tscn").instantiate()
	hurt_box.damage = 1
	boss_node.add_child(hurt_box)
	
	# Create minimal animation players with empty animations
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	boss_node.add_child(anim_player)
	
	# Create empty animations using AnimationLibrary
	var anim_library = AnimationLibrary.new()
	
	var idle_anim = Animation.new()
	idle_anim.length = 1.0
	idle_anim.loop_mode = Animation.LOOP_LINEAR
	anim_library.add_animation("idle", idle_anim)
	
	var appear_anim = Animation.new()
	appear_anim.length = 0.5
	anim_library.add_animation("appear", appear_anim)
	
	var disappear_anim = Animation.new()
	disappear_anim.length = 0.5
	anim_library.add_animation("disappear", disappear_anim)
	
	var cast_anim = Animation.new()
	cast_anim.length = 1.0
	anim_library.add_animation("cast_spell", cast_anim)
	
	var destroy_anim = Animation.new()
	destroy_anim.length = 1.0
	anim_library.add_animation("destroy", destroy_anim)
	
	anim_player.add_animation_library("", anim_library)
	
	var anim_damaged = AnimationPlayer.new()
	anim_damaged.name = "AnimationPlayer_Damaged"
	boss_node.add_child(anim_damaged)
	
	var damaged_anim_library = AnimationLibrary.new()
	var damaged_anim = Animation.new()
	damaged_anim.length = 0.3
	damaged_anim_library.add_animation("damaged", damaged_anim)
	
	var default_anim = Animation.new()
	default_anim.length = 0.1
	damaged_anim_library.add_animation("default", default_anim)
	
	anim_damaged.add_animation_library("", damaged_anim_library)
	
	# Create cloak sprite with animation player
	var cloak_sprite = Sprite2D.new()
	cloak_sprite.name = "CloakSprite"
	boss_node.add_child(cloak_sprite)
	
	var cloak_anim = AnimationPlayer.new()
	cloak_anim.name = "AnimationPlayer"
	cloak_sprite.add_child(cloak_anim)
	
	var cloak_anim_library = AnimationLibrary.new()
	var down_anim = Animation.new()
	down_anim.length = 1.0
	down_anim.loop_mode = Animation.LOOP_LINEAR
	cloak_anim_library.add_animation("down", down_anim)
	
	var up_anim = Animation.new()
	up_anim.length = 1.0
	up_anim.loop_mode = Animation.LOOP_LINEAR
	cloak_anim_library.add_animation("up", up_anim)
	
	var side_anim = Animation.new()
	side_anim.length = 1.0
	side_anim.loop_mode = Animation.LOOP_LINEAR
	cloak_anim_library.add_animation("side", side_anim)
	
	cloak_anim.add_animation_library("", cloak_anim_library)
	
	# Create audio player
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "AudioStreamPlayer2D"
	boss_node.add_child(audio_player)
	
	# Initialize boss HP (will be set based on wave in _configure_boss_for_wave)
	# Default HP, will be overridden
	boss.max_hp = 8
	boss.hp = 8
	pass

func _configure_boss_for_wave(boss: Node2D, wave: int) -> void:
	# Set boss HP based on wave
	# Wave 0: 8 HP
	# Wave 1: 15 HP
	# Wave 2: 25 HP
	var boss_hp_values = [8, 15, 25]
	if wave < boss_hp_values.size():
		boss.max_hp = boss_hp_values[wave]
		boss.hp = boss_hp_values[wave]
	
	# Set boss attack mode based on wave
	# Wave 0: only orbs
	# Wave 1: only beams  
	# Wave 2: both
	boss.set_meta("tutorial_wave", wave)
	boss.set_meta("can_shoot_orb", wave == 0 or wave == 2)
	boss.set_meta("can_use_beam", wave == 1 or wave == 2)
	pass

func _start_boss_monitoring(boss: DarkWizardBoss) -> void:
	# Monitor boss HP to detect defeat
	var check_timer = Timer.new()
	check_timer.name = "BossMonitor"
	check_timer.wait_time = 0.1
	check_timer.one_shot = false
	check_timer.autostart = true
	boss.add_child(check_timer)
	
	check_timer.timeout.connect(func():
		if not is_instance_valid(boss):
			check_timer.queue_free()
			return
		
		if boss.hp <= 0:
			# Boss defeated
			_on_boss_defeated()
			check_timer.queue_free()
	)
	pass

func _on_boss_defeated() -> void:
	if current_step != TutorialStep.BOSS_WAVES:
		return
	
	boss_wave_completing = true
	await get_tree().create_timer(2.0).timeout
	boss_wave += 1
	
	if boss_wave < boss_waves_sizes.size():
		# Next wave
		await get_tree().create_timer(2.0).timeout
		boss_wave_completing = false
		start_boss_wave()
	else:
		# All waves complete
		boss_wave_completing = false
		boss_waves_completed = true
		complete_boss_tutorial()
	pass

func complete_boss_tutorial() -> void:
	# Hide wave counter
	PlayerHud.hide_kill_counter()
	
	var complete_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Incredible! You've defeated all the Dark Wizard bosses!"
	complete_dialogs.append(dialog1)
	
	var dialog2: DialogText = DialogText.new()
	dialog2.npc_info = TUTORIAL_NPC
	dialog2.text = "You've completed the tutorial! Thank you for playing!"
	complete_dialogs.append(dialog2)
	
	DialogSystem.show_dialog(complete_dialogs)
	await DialogSystem.finished
	
	# Fade out the game
	await SceneTransition.fade_out()
	
	# Wait a moment
	await get_tree().create_timer(1.0).timeout
	
	# Exit the game
	get_tree().quit()
	pass
