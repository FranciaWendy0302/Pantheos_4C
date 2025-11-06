class_name EnemyStateIdle extends EnemyState

@export var anim_name: String = "idle"

@export_category("AI")
@export var state_duration_min: float = 0.5
@export var state_duration_max: float = 1.5
@export var after_idle_state: EnemyState
@export var chase_state: EnemyStateChase

var _timer: float = 0.0
var _vision_area: VisionArea

func init() -> void:
	# Find vision area on enemy
	_vision_area = enemy.get_node_or_null("VisionArea")
	if _vision_area:
		_vision_area.player_entered.connect(_on_player_entered_vision)
	pass
	
func _on_player_entered_vision() -> void:
	# Transition to chase when player enters vision area
	print("Idle state: Player entered vision area!")
	if chase_state:
		state_machine.change_state(chase_state)
	pass
	
func enter() -> void:
	enemy.velocity = Vector2.ZERO
	_timer = randf_range(state_duration_min, state_duration_max)
	enemy.update_animation(anim_name)
	pass
	
func exit() -> void:
	pass
	
func process(_delta: float) -> EnemyState:
	_timer -= _delta
	if _timer <= 0:
		return after_idle_state
	return null
	
func physics(_delta: float) -> EnemyState:
	return null
