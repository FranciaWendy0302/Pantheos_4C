extends Node

# Class-specific player scenes
const PLAYER_SCENES = {
	"Swordsman": "res://Player/swordsman.tscn",
	"Mage": "res://Player/mage.tscn",
	"Archer": "res://Player/archer.tscn",
	"Assassin": "res://Player/assassin.tscn",
	"Support": "res://Player/support.tscn"
}

# Fallback to swordsman if class not found
const DEFAULT_PLAYER = "res://Player/swordsman.tscn"

var INVENTORY_DATA: InventoryData

func _init():
	# Use load instead of preload to avoid circular dependency issues
	INVENTORY_DATA = load("res://GUI/pause_menu/inventory/player_inventory.tres")

signal camera_shook(trauma: float)
signal interact_pressed
signal player_leveled_up

var interact_handled: bool = true
var player: CharacterBody2D
var player_spawned: bool = false
var player_addition_pending: bool = false

var player_id: int = 0  # Online player ID from database
var nickname: String = "Adventurer"
var selected_class: String = "Swordsman"
var character_class: String = "Swordsman"  # Current character class

# Class system
var class_type: int = 0  # ClassManager.PlayerClass enum value

func set_character_class(new_class: String) -> void:
	character_class = new_class
	selected_class = new_class
	# Convert string to class type
	match new_class:
		"Swordsman", "Warrior":
			class_type = 0  # WARRIOR
		"Mage":
			class_type = 1  # MAGE
		"Archer":
			class_type = 2  # ARCHER
		"Assassin", "Rogue":
			class_type = 3  # ROGUE
		_:
			class_type = 0  # Default to WARRIOR
	print("[PlayerManager] Class set to: ", new_class)

# Target system
var current_target: Node2D = null
signal target_changed(new_target)

#var level_requirements = [0, 50, 100, 200, 400, 800, 1600, 3200, 6400, 12800]
var level_requirements = [0, 25, 50, 75, 100]

func _ready() -> void:
	add_player_instance()
	await get_tree().create_timer(0.5).timeout
	player_spawned = true
	

#func add_player_instance() -> void:
	#player = PLAYER.instantiate()
	#add_child(player)
	#pass
	
func add_player_instance() -> void:
	# Prevent multiple simultaneous additions
	if player_addition_pending:
		return
	
	# Load the correct player scene based on class
	var player_scene_path = get_player_scene_path()
	print("[PlayerManager] Loading player scene: ", player_scene_path)
	
	var player_scene = load(player_scene_path)
	if not player_scene:
		print("[PlayerManager] ERROR: Failed to load player scene, using default")
		player_scene = load(DEFAULT_PLAYER)
	
	if player and is_instance_valid(player):
		# Player already exists, make sure it's in the active scene
		if player.get_parent() != get_tree().current_scene:
			# Directly reparent without calling set_as_parent to avoid recursion
			if player.get_parent():
				player.get_parent().remove_child(player)
			# Use call_deferred to avoid "parent node is busy" error
			# Add a check to prevent duplicate additions
			if not get_tree().current_scene.is_ancestor_of(player):
				player_addition_pending = true
				get_tree().current_scene.call_deferred("add_child", player)
				# Reset flag after a short delay
				get_tree().create_timer(0.1).timeout.connect(_reset_addition_flag)
		return

	# Create new player instance with correct class scene
	player = player_scene.instantiate()
	player.name = "Player"
	# Use call_deferred to avoid "parent node is busy" error
	player_addition_pending = true
	get_tree().current_scene.call_deferred("add_child", player)
	# Reset flag after a short delay
	get_tree().create_timer(0.1).timeout.connect(_reset_addition_flag)

func get_player_scene_path() -> String:
	# Get the correct player scene path based on character class
	var player_class = character_class
	
	if player_class == "" or player_class == null:
		player_class = "Swordsman"  # Default
	
	# Check if scene exists for this class
	if PLAYER_SCENES.has(player_class):
		var scene_path = PLAYER_SCENES[player_class]
		# Verify file exists
		if ResourceLoader.exists(scene_path):
			return scene_path
		else:
			print("[PlayerManager] Scene not found: ", scene_path, " - using default")
	
	# Fallback to default
	return DEFAULT_PLAYER

	
func set_health(hp: int, max_hp: int) -> void:
	player.max_hp = max_hp
	player.hp = hp
	player.update_hp(0)
	
func reward_xp(_xp) -> void:
	player.xp += _xp
	check_for_level_advance()

func check_for_level_advance() -> void:
	if player.level >= level_requirements.size():
		return
	if player.xp >= level_requirements[player.level]:
		player.level += 1
		player.attack += 1
		player.defense += 1
		player_leveled_up.emit()
		check_for_level_advance()
	pass
	
#func set_player_position(_new_pos: Vector2) -> void:
	#player.global_position = _new_pos
	#pass
	
func set_player_position(_new_pos: Vector2) -> void:
	if not is_instance_valid(player):
		add_player_instance()
	player.global_position = _new_pos

#func set_as_parent(_p: Node2D) -> void:
	#if player.get_parent():
		#player.get_parent().remove_child(player)
	#_p.add_child(player)
	
func set_as_parent(_p: Node) -> void:
	if not is_instance_valid(player):
		add_player_instance()
		return

	# Already in the correct parent → do nothing
	if player.get_parent() == _p:
		return

	# Prevent multiple simultaneous additions
	if player_addition_pending:
		return

	# Remove from current parent if it exists
	if player.get_parent():
		player.get_parent().remove_child(player)

	# Use call_deferred to avoid "parent node is busy" error
	# Add a check to prevent duplicate additions
	if not _p.is_ancestor_of(player):
		player_addition_pending = true
		_p.call_deferred("add_child", player)
		# Reset flag after a short delay
		get_tree().create_timer(0.1).timeout.connect(_reset_addition_flag)


#func unparent_player(_p: Node2D) -> void:
	#_p.remove_child(player)
	
func unparent_player(_p: Node2D) -> void:
	if player and is_instance_valid(player) and player.get_parent() == _p:
		_p.remove_child(player)
	
func play_audio(_audio: AudioStream) -> void:
	player.audio.stream = _audio
	player.audio.play()

func interact() -> void:
	interact_handled = false
	interact_pressed.emit()

func shake_camera(trauma: float = 1) -> void:
	camera_shook.emit(clampf(trauma, 0, 2))

# Target system functions
func set_target(target: Node2D) -> void:
	if current_target == target:
		return
	
	# Clear old target
	if current_target and is_instance_valid(current_target):
		if current_target.has_method("set_targeted"):
			current_target.set_targeted(false)
	
	# Set new target
	current_target = target
	if current_target and current_target.has_method("set_targeted"):
		current_target.set_targeted(true)
	
	target_changed.emit(current_target)
	print("[Target] Set target: ", current_target.name if current_target else "None")

func clear_target() -> void:
	set_target(null)

func get_target() -> Node2D:
	if current_target and is_instance_valid(current_target):
		return current_target
	else:
		current_target = null
		return null
	
func _reset_addition_flag() -> void:
	player_addition_pending = false
