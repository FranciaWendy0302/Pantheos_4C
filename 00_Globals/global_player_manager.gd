extends Node

const PLAYER = preload("res://Player/player.tscn")
const INVENTORY_DATA: InventoryData = preload("res://GUI/pause_menu/inventory/player_inventory.tres")

signal camera_shook(trauma: float)
signal interact_pressed
signal player_leveled_up

var interact_handled: bool = true
var player: Player
var player_spawned: bool = false
var player_addition_pending: bool = false

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

	# Create new player instance
	player = PLAYER.instantiate()
	player.name = "Player"
	# Use call_deferred to avoid "parent node is busy" error
	player_addition_pending = true
	get_tree().current_scene.call_deferred("add_child", player)
	# Reset flag after a short delay
	get_tree().create_timer(0.1).timeout.connect(_reset_addition_flag)

	
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
	
func _reset_addition_flag() -> void:
	player_addition_pending = false
