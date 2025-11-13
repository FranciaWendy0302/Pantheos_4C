extends Node

const SAVE_PATH = "user://"

signal game_loaded
signal game_saved

var current_save: Dictionary = {
	scene_path = "",
	player = {
		level = 1,
		xp = 1,
		hp = 10,
		max_hp = 10,
		attacks = 1,
		defense = 1,
		pos_x = 0,
		pos_y = 0,
		arrow_count = 0,
		bomb_count = 0
	},
	items = [],
	persistence = [],
	quests = [
		#{title = "not found", is_complete = false, completed_steps = ['']}
	],
	abilities = ["", "", "", ""],
	character_meta = {
		nickname = "",
		character_class = "",
		slot = 1,
		created_date = ""
	},
	tutorial_completed = false,
	tutorial_progress = {
		current_step = -1,
		movement_completed = false,
		attack_completed = false,
		skills_completed = false,
		inventory_completed = false,
		currency_completed = false,
		loot_completed = false,
		quest_waves_completed = false,
		item_stats_completed = false,
		original_class = ""
	}
}

var current_slot: int = 1  # Current active slot (1 or 2)

func _ready() -> void:
	# Connect to quest updates to auto-save when quests change
	if QuestManager:
		if not QuestManager.quest_updated.is_connected(_on_quest_updated):
			QuestManager.quest_updated.connect(_on_quest_updated)

func _notification(what: int) -> void:
	# Auto-save when the game is about to exit
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game()

func _on_quest_updated(_q: Dictionary) -> void:
	# Auto-save when a quest is updated (including tutorial quest progress)
	save_game()

func save_game() -> void:
	update_player_data()
	update_scene_path()
	update_item_data()
	update_quest_data()
	update_character_meta()
	update_tutorial_progress()
	
	# Save to slot-specific file
	var slot_file = SAVE_PATH + "slot" + str(current_slot) + ".sav"
	var file := FileAccess.open(slot_file, FileAccess.WRITE)
	if file:
		var save_json = JSON.stringify(current_save)
		file.store_line(save_json)
		file.close()
		game_saved.emit()
	pass

func get_save_file(slot: int = -1) -> FileAccess:
	# If slot not specified, use current_slot
	if slot == -1:
		slot = current_slot
	var slot_file = SAVE_PATH + "slot" + str(slot) + ".sav"
	return FileAccess.open(slot_file, FileAccess.READ)
	
func load_game(slot: int = -1) -> void:
	# If slot not specified, use current_slot
	if slot == -1:
		slot = current_slot
	
	current_slot = slot
	var file := get_save_file(slot)
	if not file:
		push_error("SaveManager.load_game: No save file found for slot " + str(slot))
		return
	
	var json := JSON.new()
	json.parse(file.get_line())
	file.close()
	var save_dict : Dictionary = json.get_data() as Dictionary
	current_save = save_dict
	
	# Get scene path from save, with fallback to tutorial level if invalid
	var scene_path = current_save.get("scene_path", "")
	if scene_path == null or scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		# Fallback to tutorial level if save path is invalid
		scene_path = "res://Levels/Area01/tutorial.tscn"
		push_warning("SaveManager.load_game: Invalid scene_path in save file, defaulting to tutorial level")
	
	# Load level and set target to PlayerSpawn so player spawns at PlayerSpawn node
	LevelManager.load_new_level(scene_path, "PlayerSpawn", Vector2.ZERO)
	
	await LevelManager.level_load_started
	
	# Wait for level to fully load before setting player position
	await LevelManager.level_loaded
	
	# Find PlayerSpawn node and use its position
	var scene = get_tree().current_scene
	var player_spawn = scene.get_node_or_null("PlayerSpawn")
	if player_spawn:
		# Use PlayerSpawn position
		PlayerManager.set_player_position(player_spawn.global_position)
	else:
		# Fallback to saved position if PlayerSpawn doesn't exist
		PlayerManager.set_player_position(Vector2(current_save.player.pos_x, current_save.player.pos_y))
	
	PlayerManager.set_health(current_save.player.hp, current_save.player.max_hp)
	
	# Wait for player to be initialized
	await get_tree().create_timer(0.1).timeout
	
	var p: Player = PlayerManager.player
	if not p or not is_instance_valid(p):
		# Player not ready yet, wait a bit more
		await get_tree().create_timer(0.2).timeout
		p = PlayerManager.player
	
	# Ensure player exists before accessing properties
	if p and is_instance_valid(p):
		p.level = current_save.player.get("level", 1)
		p.attack = current_save.player.get("attack", 1)
		p.xp = current_save.player.get("xp", 0)
		p.defense = current_save.player.get("defense", 1)
		p.arrow_count = current_save.player.get("arrow_count", 0)
		p.bomb_count = current_save.player.get("bomb_count", 0)
		
		# Restore abilities if player_abilities is available
		if p.player_abilities and is_instance_valid(p.player_abilities):
			var saved_abilities = current_save.get("abilities", ["", "", "", ""])
			if saved_abilities is Array:
				# Clear and rebuild the abilities array to ensure proper typing
				p.player_abilities.abilities.clear()
				for ability in saved_abilities:
					if ability is String:
						p.player_abilities.abilities.append(ability)
		
	PlayerManager.INVENTORY_DATA.parse_save_data(current_save.items)
	QuestManager.current_quests = current_save.quests
	
	game_loaded.emit()
	pass	

func update_player_data() -> void:
	var p: Player = PlayerManager.player
	if not p or not is_instance_valid(p):
		return
	
	current_save.player.hp = p.hp
	current_save.player.max_hp = p.max_hp
	current_save.player.pos_x = p.global_position.x
	current_save.player.pos_y = p.global_position.y
	current_save.player.level = p.level
	current_save.player.xp = p.xp
	current_save.player.attack = p.attack
	current_save.player.defense = p.defense
	current_save.player.arrow_count = p.arrow_count
	current_save.player.bomb_count = p.bomb_count
	
	# Safely access abilities
	if p.player_abilities and is_instance_valid(p.player_abilities):
		current_save.abilities = p.player_abilities.abilities
	else:
		current_save.abilities = ["", "", "", ""]
	
func update_scene_path() -> void:
	var p: String = ""
	
	# First check if we're in tutorial - if so, always save tutorial path
	var current_scene = get_tree().current_scene
	if current_scene and is_instance_valid(current_scene):
		var scene_path = current_scene.get("scene_file_path")
		if scene_path == "res://Levels/Area01/tutorial.tscn":
			current_save.scene_path = "res://Levels/Area01/tutorial.tscn"
			return
	
	# Otherwise, find Level node and get its scene path
	for c in get_tree().root.get_children():
		if c is Level and c and is_instance_valid(c):
			# Check if scene_file_path exists and is not empty
			var scene_path = c.get("scene_file_path")
			if scene_path != null and scene_path is String and not scene_path.is_empty():
				p = scene_path
				break
	current_save.scene_path = p

func update_item_data() -> void:
	current_save.items = PlayerManager.INVENTORY_DATA.get_save_data()

func update_quest_data() -> void:
	current_save.quests = QuestManager.current_quests

func update_tutorial_progress() -> void:
	# Check if we're in the tutorial level and get its completion status
	var current_scene = get_tree().current_scene
	if current_scene and is_instance_valid(current_scene):
		var scene_path = current_scene.get("scene_file_path")
		if scene_path == "res://Levels/Area01/tutorial.tscn":
			# Check if tutorial has a current_step property
			if "current_step" in current_scene:
				var tutorial_step = current_scene.current_step
				# If tutorial step is COMPLETE (25), mark as completed
				if tutorial_step == 25:  # TutorialStep.COMPLETE
					current_save.tutorial_completed = true
				else:
					# Save current tutorial progress
					if not current_save.has("tutorial_progress"):
						current_save.tutorial_progress = {}
					
					current_save.tutorial_progress.current_step = tutorial_step
					
					# Save all completion flags
					if "movement_completed" in current_scene:
						current_save.tutorial_progress.movement_completed = current_scene.movement_completed
					if "attack_completed" in current_scene:
						current_save.tutorial_progress.attack_completed = current_scene.attack_completed
					if "skills_completed" in current_scene:
						current_save.tutorial_progress.skills_completed = current_scene.skills_completed
					if "inventory_completed" in current_scene:
						current_save.tutorial_progress.inventory_completed = current_scene.inventory_completed
					if "currency_completed" in current_scene:
						current_save.tutorial_progress.currency_completed = current_scene.currency_completed
					if "loot_completed" in current_scene:
						current_save.tutorial_progress.loot_completed = current_scene.loot_completed
					if "quest_waves_completed" in current_scene:
						current_save.tutorial_progress.quest_waves_completed = current_scene.quest_waves_completed
					if "item_stats_completed" in current_scene:
						current_save.tutorial_progress.item_stats_completed = current_scene.item_stats_completed
					if "original_player_class" in current_scene:
						current_save.tutorial_progress.original_class = current_scene.original_player_class
	pass

func update_character_meta() -> void:
	# Update character metadata if not already set
	if not current_save.has("character_meta"):
		current_save.character_meta = {}
	
	current_save.character_meta.nickname = PlayerManager.nickname
	current_save.character_meta.character_class = PlayerManager.selected_class
	current_save.character_meta.slot = current_slot
	
	# Set created date only if it doesn't exist
	if not current_save.character_meta.has("created_date") or current_save.character_meta.created_date == "":
		var time = Time.get_datetime_dict_from_system()
		current_save.character_meta.created_date = str(time.month) + "/" + str(time.day) + "/" + str(time.year)

func save_character_slot(slot: int, nickname: String, character_class: String) -> void:
	# Create a new character save file for the specified slot
	var slot_save = {
		scene_path = "res://Levels/Area01/tutorial.tscn",
		player = {
			level = 1,
			xp = 0,
			hp = 10,
			max_hp = 10,
			attack = 1,
			defense = 1,
			pos_x = 0,
			pos_y = 0,
			arrow_count = 10,
			bomb_count = 10
		},
		items = [],
		persistence = [],
		quests = [],
		abilities = ["", "", "", ""],
		character_meta = {
			nickname = nickname,
			character_class = character_class,
			slot = slot,
			created_date = ""
		},
		tutorial_completed = false,
		tutorial_progress = {
			current_step = -1,
			movement_completed = false,
			attack_completed = false,
			skills_completed = false,
			inventory_completed = false,
			currency_completed = false,
			loot_completed = false,
			quest_waves_completed = false,
			item_stats_completed = false,
			original_class = ""
		}
	}
	
	# Set creation date
	var time = Time.get_datetime_dict_from_system()
	slot_save.character_meta.created_date = str(time.month) + "/" + str(time.day) + "/" + str(time.year)
	
	# Save to slot file
	var slot_file = SAVE_PATH + "slot" + str(slot) + ".sav"
	var file := FileAccess.open(slot_file, FileAccess.WRITE)
	if file:
		var save_json = JSON.stringify(slot_save)
		file.store_line(save_json)
		file.close()
	pass

func get_character_slot_info(slot: int) -> Dictionary:
	# Returns character metadata for a slot, or empty dict if slot doesn't exist
	var file := get_save_file(slot)
	if not file:
		return {}
	
	var json := JSON.new()
	json.parse(file.get_line())
	file.close()
	var save_dict : Dictionary = json.get_data() as Dictionary
	
	var info = {}
	if save_dict.has("character_meta"):
		info = save_dict.character_meta.duplicate()
	
	# Add level info from player data
	if save_dict.has("player") and save_dict.player.has("level"):
		info["level"] = save_dict.player.level
	
	return info

func slot_exists(slot: int) -> bool:
	# Check if a save file exists for the given slot
	var file := get_save_file(slot)
	if file:
		file.close()
		return true
	return false

func delete_character_slot(slot: int) -> bool:
	# Delete the save file for the specified slot
	var slot_file = SAVE_PATH + "slot" + str(slot) + ".sav"
	if FileAccess.file_exists(slot_file):
		var dir = DirAccess.open(SAVE_PATH)
		if dir:
			var error = dir.remove("slot" + str(slot) + ".sav")
			if error == OK:
				return true
			else:
				push_error("Failed to delete slot " + str(slot) + " save file. Error: " + str(error))
				return false
		else:
			push_error("Failed to open save directory")
			return false
	return false

func add_persistent_value(value: String) -> void:
	if check_persistent_value(value) == false:
		current_save.persistence.append(value)
	pass

func remove_persistent_value(value: String) -> void:
	var p = current_save.persistence as Array
	p.erase(value)
	pass
	
func check_persistent_value(value: String) -> bool:
	var p = current_save.persistence as Array
	return p.has(value)
