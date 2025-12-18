class_name State_Bow extends State

const ARROW = preload("res://Interactables/arrow/arrow.tscn")

@export var auto_attack_cooldown: float = 0.3  # Time between auto attacks
@export var charge_time: float = 1.0  # Time to charge big arrow
@export var charge_required: float = 0.5  # Minimum charge time for big arrow

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"

var direction: Vector2 = Vector2.ZERO
var next_state: State = null
var _is_auto_attacking: bool = false
var _charge_timer: float = 0.0
var _is_charging: bool = false
var _animation_finished: bool = false

func _ready():
	pass
	
func Enter() -> void:
	# Update player direction to face mouse cursor
	_update_player_facing()
	
	player.UpdateAnimation("bow")
	player.animation_player.animation_finished.connect(_on_animation_finished)
	
	# Get direction to mouse cursor
	direction = player.get_direction_to_mouse()
	if direction == Vector2.ZERO:
		direction = player.cardinal_direction
	
	# Normal attack - single shot (no charge, no hold)
	_shoot_arrow(false)
	_is_auto_attacking = false
	pass

func Exit() -> void:
	player.animation_player.animation_finished.disconnect(_on_animation_finished)
	next_state = null
	_is_auto_attacking = false
	_is_charging = false
	_animation_finished = false
	# Restore invulnerability
	player.invulnerable = false
	pass
	
func Process(_delta: float) -> State:
	# While charging, player cannot move (uninterruptible)
	if _is_charging:
		player.velocity = Vector2.ZERO
		_charge_timer += _delta
		# Update facing direction while charging
		_update_player_facing()
		# Update charge indicator
		var charge_progress = min(_charge_timer / charge_time, 1.0)
		var is_ready = _charge_timer >= charge_required
		PlayerHud.update_charge_indicator(charge_progress, is_ready)
		# Don't check state changes here - charging is uninterruptible
		# Let HandleInput handle button release
		return null
	
	# During normal attack, player cannot move
	if not _is_charging:
		player.velocity = Vector2.ZERO
	
	# If not charging and animation finished, return to idle
	if not _is_charging and not _is_auto_attacking:
		return next_state
	
	return null

func Physics(_delta: float) -> State:
	return null
	
func HandleInput(_event: InputEvent) -> State:
	return null

func _shoot_arrow(is_big: bool) -> void:
	# Update player facing direction before shooting
	_update_player_facing()
	
	# Get direction to mouse cursor
	direction = player.get_direction_to_mouse()
	if direction == Vector2.ZERO:
		direction = player.cardinal_direction
	
	# Consume arrows for attacks
	var should_consume_arrow = true
	
	if should_consume_arrow:
		# Check if we have arrows for big arrow
		if player.arrow_count <= 0:
			return
	
	var arrow: Arrow = ARROW.instantiate()
	arrow.is_big_arrow = is_big
	# Add arrow as sibling to player (same as original implementation)
	player.add_sibling(arrow)
	# Spawn big arrows further away to avoid immediate collision with player
	var spawn_distance = 64.0 if is_big else 32.0
	arrow.global_position = player.global_position + (direction * spawn_distance)
	arrow.fire(direction)
	
	# Consume arrow only for big arrow
	if should_consume_arrow:
		player.arrow_count -= 1
		PlayerHud.update_arrow_count(player.arrow_count)
	
	# If big arrow, restore invulnerability after a short delay
	if is_big:
		get_tree().create_timer(0.1).timeout.connect(_on_big_arrow_shot)
	pass

func _update_player_facing() -> void:
	# Update player direction to face mouse cursor
	var mouse_dir = player.get_direction_to_mouse()
	if mouse_dir != Vector2.ZERO:
		# Update cardinal direction based on mouse position
		if abs(mouse_dir.x) > abs(mouse_dir.y):
			player.cardinal_direction = Vector2.RIGHT if mouse_dir.x > 0 else Vector2.LEFT
		else:
			player.cardinal_direction = Vector2.DOWN if mouse_dir.y > 0 else Vector2.UP
		player.SetDirection()
	pass

func _on_big_arrow_shot() -> void:
	player.invulnerable = false
	pass

func _on_animation_finished(_anim_name: String) -> void:
	_animation_finished = true
	
	# If not charging, go to idle
	if not _is_charging:
		next_state = idle
	elif _is_charging:
		# Keep in bow state while charging
		# Restart animation loop
		player.UpdateAnimation("bow")
	pass
