class_name EnemyStateWander extends EnemyState

@export var anim_name: String = "walk"
@export var wander_speed: float = 20.0

@export_category("AI")
@export var state_animation_duration: float = 0.5
@export var state_cycles_min: int = 1
@export var state_cycles_max: int = 3
@export var wander_range: float = 16.0  # Maximum distance from spawn position
@export var next_state: EnemyState
@export var chase_state: EnemyStateChase

var _timer: float = 0.0
var _direction: Vector2
var _original_position: Vector2
var _current_target: Vector2
var _vision_area: VisionArea

func init() -> void:
	# Find vision area on enemy
	_vision_area = enemy.get_node_or_null("VisionArea")
	if _vision_area:
		_vision_area.player_entered.connect(_on_player_entered_vision)
	pass
	
func _on_player_entered_vision() -> void:
	# Transition to chase when player enters vision area
	print("Wander state: Player entered vision area!")
	if chase_state:
		state_machine.change_state(chase_state)
	pass
	
func enter() -> void:
	if _original_position == Vector2.ZERO:
		_original_position = enemy.global_position
	_current_target = _original_position
	_timer = randf_range(state_cycles_min, state_cycles_max) * state_animation_duration
	_choose_new_direction()
	pass
	
func _choose_new_direction() -> void:
	var distance_from_origin = enemy.global_position.distance_to(_original_position)
	
	# If too far from origin, move back towards it
	if distance_from_origin > wander_range:
		var dir_to_origin = enemy.global_position.direction_to(_original_position)
		# Snap to nearest cardinal direction
		var best_dir = enemy.DIR_4[0]
		var best_dot = dir_to_origin.dot(enemy.DIR_4[0])
		for dir in enemy.DIR_4:
			var dot = dir_to_origin.dot(dir)
			if dot > best_dot:
				best_dot = dot
				best_dir = dir
		_direction = best_dir
	else:
		# Choose random direction
		var rand = randi_range(0, 3)
		_direction = enemy.DIR_4[rand]
	
	enemy.velocity = _direction * wander_speed
	enemy.set_direction(_direction)
	enemy.update_animation(anim_name)
	
func exit() -> void:
	enemy.velocity = Vector2.ZERO
	pass
	
func process(_delta: float) -> EnemyState:
	_timer -= _delta
	
	# Check if we've wandered too far and need to turn around
	var distance_from_origin = enemy.global_position.distance_to(_original_position)
	if distance_from_origin > wander_range:
		_choose_new_direction()
	
	if _timer < 0:
		return next_state
	return null
	
func physics(_delta: float) -> EnemyState:
	return null
