extends Node

const SAVE_PATH = "user://"

signal game_loaded
signal game_saved

# ONLINE MODE: Set to true when using MySQL database (disables local save/load)
var online_mode: bool = false

# Flag to apply saved position on next level load
var should_restore_position: bool = false
var position_to_restore: Vector2 = Vector2.ZERO

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
		currency = 0
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
		god_id = 0,
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

# Auto-save timer
var auto_save_timer: Timer

func _ready() -> void:
	# Connect to quest updates to auto-save when quests change
	if QuestManager:
		if not QuestManager.quest_updated.is_connected(_on_quest_updated):
			QuestManager.quest_updated.connect(_on_quest_updated)
	
	# Connect to level loaded to start auto-save
	if LevelManager:
		if not LevelManager.level_loaded.is_connected(_on_level_loaded):
			LevelManager.level_loaded.connect(_on_level_loaded)
	
	# Setup auto-save timer (save every 30 seconds in online mode)
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 30.0
	auto_save_timer.autostart = false
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	add_child(auto_save_timer)

func _on_level_loaded() -> void:
	"""Called when a level finishes loading"""
	print("[SaveManager] Level loaded, online_mode:", online_mode)
	
	if online_mode:
		start_auto_save()
	
	# Apply saved position if flagged
	if should_restore_position:
		_apply_saved_position_after_load()
	else:
		pass

func start_auto_save() -> void:
	"""Start periodic auto-save (call this when entering game)"""
	if not online_mode:
		print("[SaveManager] Auto-save disabled (offline mode)")
		return
	
	if not auto_save_timer.is_stopped():
		print("[SaveManager] Auto-save already running")
		return
	
	auto_save_timer.start()
	print("[SaveManager] ✓ Auto-save started (every 30 seconds)")

func stop_auto_save() -> void:
	"""Stop periodic auto-save (call this when exiting game)"""
	if auto_save_timer:
		auto_save_timer.stop()

func _on_auto_save_timer_timeout() -> void:
	"""Periodic auto-save"""
	if online_mode:
		print("[SaveManager] Auto-saving...")
		save_game()
		print("[SaveManager] ✓ Auto-save complete")

func _notification(what: int) -> void:
	# Auto-save when the game is about to exit
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game()  # Save in both online and offline mode

func _on_quest_updated(_q: Dictionary) -> void:
	# Auto-save when a quest is updated (including tutorial quest progress)
	save_game()  # Save in both online and offline mode

func save_game() -> void:
	# Update all data first
	update_player_data()
	update_scene_path()
	update_item_data()
	update_quest_data()
	update_character_meta()
	update_tutorial_progress()
	
	# In online mode, save to database
	if online_mode:
		_save_to_database()
		game_saved.emit()
		return
	
	# Offline mode - save to local file
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
	# Skip local load in online mode
	if online_mode:
		return
	
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
	
	var p = PlayerManager.player
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
		p.currency = current_save.player.get("currency", 0)
		
		# Update nameplate to show correct level
		if p.has_method("_update_nameplate"):
			p._update_nameplate()
		
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
	
	# Restore god selection
	if current_save.has("character_meta") and current_save.character_meta.has("god_id"):
		var god_id = current_save.character_meta.god_id
		if god_id > 0:
			GodManager.select_god(god_id)
			print("[SaveManager] Restored god selection: ", GodManager.get_god_name(god_id))
	
	game_loaded.emit()
	pass	

func update_player_data() -> void:
	var p = PlayerManager.player
	if not p or not is_instance_valid(p):
		return
	
	current_save.player.hp = p.hp
	current_save.player.max_hp = p.max_hp
	current_save.player.mp = p.mana if "mana" in p else 100
	current_save.player.max_mp = p.max_mana if "max_mana" in p else 100
	current_save.player.pos_x = p.global_position.x
	current_save.player.pos_y = p.global_position.y
	current_save.player.level = p.level
	current_save.player.xp = p.xp
	current_save.player.attack = p.attack
	current_save.player.defense = p.defense
	current_save.player.arrow_count = p.arrow_count
	current_save.player.currency = p.currency
	
	# Safely access abilities
	if p.player_abilities and is_instance_valid(p.player_abilities):
		if "abilities" in p.player_abilities:
			current_save.abilities = p.player_abilities.abilities
		else:
			current_save.abilities = ["", "", "", ""]
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
	print("[SaveManager] ========== SAVING INVENTORY ==========")
	print("[SaveManager] Items to save: ", current_save.items.size())
	print("[SaveManager] Items data: ", current_save.items)

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
	current_save.character_meta.god_id = GodManager.get_selected_god()
	current_save.character_meta.slot = current_slot
	
	# Set created date only if it doesn't exist
	if not current_save.character_meta.has("created_date") or current_save.character_meta.created_date == "":
		var time = Time.get_datetime_dict_from_system()
		current_save.character_meta.created_date = str(time.month) + "/" + str(time.day) + "/" + str(time.year)

func save_character_slot(slot: int, nickname: String, character_class: String, god_id: int = 0) -> void:
	# For online mode, update database with character class AND nickname
	if online_mode:
		
		# Update PlayerManager with character data
		PlayerManager.nickname = nickname
		PlayerManager.character_class = character_class
		PlayerManager.selected_class = character_class
		
		# Update current_save with character data
		current_save.character_meta.nickname = nickname
		current_save.character_meta.character_class = character_class
		current_save.character_meta.god_id = god_id
		current_save.character_meta.slot = slot
		
		# Save both class and nickname to database
		var nm = get_node_or_null("/root/NetworkManager")
		if nm:
			# Update character class
			if nm.has_method("update_player_character_class"):
				nm.update_player_character_class(PlayerManager.player_id, character_class)
			
			# Also do a full save to update nickname
			if nm.has_method("save_player_data"):
				var player_data = {
					"player_id": PlayerManager.player_id,
					"nickname": nickname,
					"character_class": character_class,
					"level": 1,
					"xp": 0,
					"gold": 100,
					"hp": 100,
					"max_hp": 100
				}
				nm.save_player_data(player_data)
		else:
			pass
		
		# Don't create local save file in online mode
		return
	
	# Offline mode - create local save file
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
			currency = 0
		},
		items = [],
		persistence = [],
		quests = [],
		abilities = ["", "", "", ""],
		character_meta = {
			nickname = nickname,
			character_class = character_class,
			god_id = god_id,
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
	
	# In online mode, check if player has character data from database
	if online_mode:
		# Online accounts only use slot 1 - slot 2 should always be empty
		if slot != 1:
			return {}
		
		# For online accounts, character data comes from the database
		# If PlayerManager has character_class set, there's a character
		if PlayerManager.character_class != "" and PlayerManager.character_class != null:
			# Get level from current_save
			var player_level = current_save.player.get("level", 1)
			
			# Get nickname from character_meta (in-game nickname), fallback to PlayerManager.nickname (account username)
			var display_nickname = current_save.character_meta.get("nickname", PlayerManager.nickname)
			if display_nickname == "":
				display_nickname = PlayerManager.nickname
			
			return {
				"nickname": display_nickname,
				"character_class": PlayerManager.character_class,
				"level": player_level,
				"slot": slot
			}
		else:
			# Fresh online account - no character created yet
			return {}
	
	# Offline mode - check local save files
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
	
	# In online mode, check if player has character data
	if online_mode:
		# Character exists if PlayerManager has a character_class set
		return PlayerManager.character_class != "" and PlayerManager.character_class != null
	
	# Offline mode - check local save files
	var file := get_save_file(slot)
	if file:
		file.close()
		return true
	return false

func delete_character_slot(slot: int) -> bool:
	# Delete character from slot
	
	# In online mode, delete from database
	if online_mode:
		# Clear character_class in database
		var nm = get_node_or_null("/root/NetworkManager")
		if nm and nm.has_method("update_player_character_class"):
			# Set character_class to empty string to delete
			nm.update_player_character_class(PlayerManager.player_id, "")
			# Clear local PlayerManager data
			PlayerManager.character_class = ""
			PlayerManager.selected_class = ""
			return true
		else:
			push_error("NetworkManager not available for character deletion")
			return false
	
	# Offline mode - delete local save file
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


# =========================
# Online Mode Functions
# =========================

func enable_online_mode() -> void:
	"""Enable online mode - disables local save/load"""
	online_mode = true


func disable_online_mode() -> void:
	"""Disable online mode - re-enables local save/load"""
	online_mode = false


func load_from_database(player_data: Dictionary) -> void:
	"""Load player data from MySQL database"""
	if not online_mode:
		push_warning("[SaveManager] load_from_database called but online_mode is false")
		return
	
	
	# Parse player data from database
	current_save.player.level = player_data.get("level", 1)
	current_save.player.xp = player_data.get("xp", 0)
	current_save.player.hp = player_data.get("hp", 100)
	current_save.player.max_hp = player_data.get("max_hp", 100)
	current_save.player.pos_x = player_data.get("position_x", 0)
	current_save.player.pos_y = player_data.get("position_y", 0)
	
	# Parse JSON fields
	var inventory = player_data.get("inventory", [])
	print("[SaveManager] ========== LOADING INVENTORY ==========")
	print("[SaveManager] Raw inventory from DB: ", inventory)
	print("[SaveManager] Inventory type: ", typeof(inventory))
	
	if inventory is String:
		print("[SaveManager] Inventory is String, parsing JSON...")
		var json = JSON.new()
		if json.parse(inventory) == OK:
			current_save.items = json.data
			print("[SaveManager] ✓ Parsed inventory: ", current_save.items.size(), " items")
		else:
			print("[SaveManager] ✗ Failed to parse inventory JSON!")
			current_save.items = []
	elif inventory is Array:
		print("[SaveManager] Inventory is Array, using directly")
		current_save.items = inventory
	else:
		print("[SaveManager] ✗ Inventory is null or invalid type!")
		current_save.items = []
	
	print("[SaveManager] Final items count: ", current_save.items.size())
	
	var quests = player_data.get("quests", [])
	if quests is String:
		var json = JSON.new()
		if json.parse(quests) == OK:
			current_save.quests = json.data
	elif quests is Array:
		current_save.quests = quests
	
	# Set scene path
	var current_map = player_data.get("current_map", "")
	if current_map != "" and ResourceLoader.exists(current_map):
		current_save.scene_path = current_map
	else:
		current_save.scene_path = "res://Levels/Area01/tutorial.tscn"
	
	# Character meta - load from database
	# The database nickname field contains the character's in-game nickname (set during character creation)
	current_save.character_meta.nickname = player_data.get("nickname", "Player")
	current_save.character_meta.character_class = player_data.get("character_class", "Swordsman")
	current_save.character_meta.god_id = player_data.get("god_id", 0)
	
	# Set player class in PlayerManager
	PlayerManager.set_character_class(current_save.character_meta.character_class)
	
	# Restore god selection
	if current_save.character_meta.god_id > 0:
		GodManager.select_god(current_save.character_meta.god_id)
		print("[SaveManager] Restored god from database: ", GodManager.get_god_name(current_save.character_meta.god_id))
	else:
		print("[SaveManager] No god selection found in database (god_id = 0)")
		
	# Restore god skill unlock status
	if player_data.get("god_skill_unlocked", false):
		GodManager.unlock_god_skill()
		print("[SaveManager] Restored god skill unlock status")
	
	# Apply to player
	_apply_loaded_data()
	


func _apply_loaded_data() -> void:
	"""Apply loaded data to player"""
	# Set player position
	PlayerManager.set_player_position(Vector2(current_save.player.pos_x, current_save.player.pos_y))
	PlayerManager.set_health(current_save.player.hp, current_save.player.max_hp)
	
	# Wait for player to be ready
	await get_tree().create_timer(0.1).timeout
	
	var p = PlayerManager.player
	if p and is_instance_valid(p):
		p.level = current_save.player.level
		p.xp = current_save.player.xp
		p.attack = current_save.player.get("attack", 1)
		p.defense = current_save.player.get("defense", 1)
		
		# Update nameplate to show correct level
		if p.has_method("_update_nameplate"):
			p._update_nameplate()
	else:
		pass
	
	# Load inventory
	print("[SaveManager] ========== APPLYING INVENTORY ==========")
	print("[SaveManager] Items to load: ", current_save.items.size())
	print("[SaveManager] Items data: ", current_save.items)
	PlayerManager.INVENTORY_DATA.parse_save_data(current_save.items)
	print("[SaveManager] ✓ Inventory loaded into INVENTORY_DATA")
	
	# Load quests
	QuestManager.current_quests = current_save.quests
	
	game_loaded.emit()


func _save_to_database() -> void:
	"""Save current player data to MySQL database via NetworkManager"""
	
	# Check if we have a valid player_id
	if PlayerManager.player_id <= 0:
		push_error("[SaveManager] Cannot save - invalid player_id")
		return
	
	# Get gold from player instance if available
	var gold_amount = 100  # Default
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		if "gold" in PlayerManager.player:
			gold_amount = PlayerManager.player.gold
	
	# Get mana from player instance if available
	var mana_amount = 100  # Default
	var max_mana_amount = 100  # Default
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		if "mana" in PlayerManager.player:
			mana_amount = PlayerManager.player.mana
		if "max_mana" in PlayerManager.player:
			max_mana_amount = PlayerManager.player.max_mana
	
	# Prepare player data for database
	var player_data = {
		"player_id": PlayerManager.player_id,
		"character_slot": current_slot,
		"nickname": current_save.character_meta.nickname,
		"level": current_save.player.level,
		"xp": current_save.player.xp,
		"gold": gold_amount,
		"hp": current_save.player.hp,
		"max_hp": current_save.player.max_hp,
		"mp": mana_amount,
		"max_mp": max_mana_amount,
		"position_x": current_save.player.pos_x,
		"position_y": current_save.player.pos_y,
		"current_map": current_save.scene_path,
		"character_class": PlayerManager.character_class,
		"god_id": current_save.character_meta.get("god_id", 0),
		"god_skill_unlocked": GodManager.is_god_skill_unlocked(),
		"inventory": JSON.stringify(current_save.items),
		"quests": JSON.stringify(current_save.quests),
		"persistence": JSON.stringify(current_save.persistence)
	}
	
	print("[SaveManager] ========== SAVING TO DATABASE ==========")
	print("[SaveManager] Slot: ", current_slot)
	print("[SaveManager] Map: ", current_save.scene_path)
	print("[SaveManager] Position: (", current_save.player.pos_x, ", ", current_save.player.pos_y, ")")
	print("[SaveManager] God ID: ", current_save.character_meta.get("god_id", 0))
	print("[SaveManager] God Skill: ", GodManager.is_god_skill_unlocked())
	print("[SaveManager] Inventory items: ", current_save.items.size())
	print("[SaveManager] Inventory JSON length: ", JSON.stringify(current_save.items).length())
	
	# Save to database (fire and forget - don't block gameplay)
	_async_save_to_database(player_data)
	
	# Also emit game_saved immediately so UI can respond
	game_saved.emit()
	pass

func _async_save_to_database(player_data: Dictionary) -> void:
	"""Async helper to save to database without blocking"""
	var nm = get_node_or_null("/root/NetworkManager")
	if not nm:
		push_error("[SaveManager] ✗ NetworkManager not found!")
		return
	
	if not nm.has_method("save_player_data"):
		push_error("[SaveManager] ✗ NetworkManager doesn't have save_player_data method!")
		return
	
	
	# Call the async function and await it properly
	var result = await nm.save_player_data(player_data)
	
	
	if result and result.has("success") and result.success:
		pass
	else:
		var error_msg = "Unknown error"
		if result and result.has("error"):
			error_msg = str(result.error)
		push_error("[SaveManager] ✗✗✗ Failed to save: " + error_msg)


func get_player_data_for_database() -> Dictionary:
	"""Get current player data formatted for database"""
	update_player_data()
	update_scene_path()
	update_item_data()
	update_quest_data()
	
	# Get character class from character_meta
	var character_class = current_save.character_meta.get("character_class", "")
	if character_class == "":
		character_class = PlayerManager.selected_class if PlayerManager.selected_class != "" else "Swordsman"
	
	return {
		"player_id": PlayerManager.player_id,
		"character_slot": current_slot,
		"nickname": current_save.character_meta.nickname,
		"level": current_save.player.level,
		"xp": current_save.player.xp,
		"hp": current_save.player.hp,
		"max_hp": current_save.player.max_hp,
		"position_x": current_save.player.pos_x,
		"position_y": current_save.player.pos_y,
		"current_map": current_save.scene_path,
		"character_class": character_class,
		"god_id": current_save.character_meta.get("god_id", 0),
		"god_skill_unlocked": GodManager.is_god_skill_unlocked()
	}


func _apply_saved_position_after_load() -> void:
	"""Apply saved position after level loads - called from _on_level_loaded"""
	
	# Wait for player to be ready
	for i in range(30):
		await get_tree().create_timer(0.2).timeout
		
		if PlayerManager.player and is_instance_valid(PlayerManager.player):
			
			# Apply position
			PlayerManager.player.global_position = position_to_restore
			
			# Apply stats
			PlayerManager.set_health(current_save.player.hp, current_save.player.max_hp)
			var p = PlayerManager.player
			p.level = current_save.player.level
			p.xp = current_save.player.xp
			p.attack = current_save.player.get("attack", 1)
			p.defense = current_save.player.get("defense", 1)
			
			# Update nameplate to show correct level
			if p.has_method("_update_nameplate"):
				p._update_nameplate()
			
			# Clear flag
			should_restore_position = false
			return
	
	should_restore_position = false
