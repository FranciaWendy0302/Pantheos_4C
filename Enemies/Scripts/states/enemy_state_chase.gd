class_name EnemyStateChase extends EnemyState

const PATHFINDER: PackedScene = preload("res://Enemies/pathfinder.tscn")

@export var anim_name: String = "walk"
@export var chase_speed: float = 40.0
@export var turn_rate: float = 0.25

@export_category("AI")
@export var vision_area: VisionArea
@export var attack_area: HurtBox
@export var state_aggro_duration: float = 0.5
@export var next_state: EnemyState

var pathfinder: Pathfinder

var _timer: float = 0.0
var _direction: Vector2
var _can_see_player: bool = false

func init() -> void:
	if vision_area:
		vision_area.player_entered.connect(_on_player_enter)
		vision_area.player_exited.connect(_on_player_exit)
	pass
	
func enter() -> void:
	# Check if enemy is dead - don't enter chase if dead
	if enemy.hp <= 0:
		return
	
	pathfinder = PATHFINDER.instantiate() as Pathfinder
	enemy.add_child(pathfinder)
	_timer = state_aggro_duration
	enemy.update_animation(anim_name)
	if attack_area:
		attack_area.monitoring = true
	pass
	
func exit() -> void:
	pathfinder.queue_free()
	if attack_area:
		attack_area.monitoring = false
	_can_see_player = false
	pass
	
func process(_delta: float) -> EnemyState:
	# Check if enemy is dead - if so, stop chasing
	if enemy.hp <= 0:
		return next_state
	
	if PlayerManager.player.hp <= 0:
		return next_state
	#var new_dir: Vector2 = enemy.global_position.direction_to(PlayerManager.player.global_position)
	#_direction = lerp(_direction, new_dir, turn_rate)
	_direction = lerp(_direction, pathfinder.move_dir, turn_rate)
	enemy.velocity = _direction * chase_speed
	if enemy.set_direction(_direction):
		enemy.update_animation(anim_name)
	
	# Check if player is in attack range and attack
	if attack_area and attack_area.has_overlapping_bodies():
		for body in attack_area.get_overlapping_bodies():
			if body is Player:
				# Player is in attack range - damage is handled by HurtBox
				# Continue chasing to maintain attack
				_timer = state_aggro_duration
				if _can_see_player:
					_timer = state_aggro_duration
				return null
	
	if _can_see_player == false:
		_timer -= _delta
		if _timer < 0:
			return next_state
	else:
		_timer = state_aggro_duration
	return null
	
func physics(_delta: float) -> EnemyState:
	return null

func _on_player_enter() -> void:
	_can_see_player = true
	if(
		 state_machine.current_state is EnemyStateStun
		 or state_machine.current_state is EnemyStateDestroy
	):	
		return
	state_machine.change_state(self)
	pass
	
func _on_player_exit() -> void:
	_can_see_player = false
	pass
