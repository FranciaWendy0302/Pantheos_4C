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

# TAB-TARGET: Attack cooldown
var _attack_cooldown: float = 0.0
var _attack_cooldown_duration: float = 1.5  # 1.5 seconds between attacks
var _is_tackling: bool = false  # Flag to pause movement during tackle

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
	
	# TAB-TARGET: Disable collision-based attack
	if attack_area:
		attack_area.monitoring = false
	pass
	
func exit() -> void:
	pathfinder.queue_free()
	if attack_area:
		attack_area.monitoring = false
	_can_see_player = false
	pass
	
func process(_delta: float) -> EnemyState:
	# Update attack cooldown
	if _attack_cooldown > 0.0:
		_attack_cooldown -= _delta
	
	# Check if enemy is dead - if so, stop chasing
	if enemy.hp <= 0:
		return next_state
	
	if PlayerManager.player.hp <= 0:
		return next_state
	# Don't move if tackling
	if not _is_tackling:
		#var new_dir: Vector2 = enemy.global_position.direction_to(PlayerManager.player.global_position)
		#_direction = lerp(_direction, new_dir, turn_rate)
		_direction = lerp(_direction, pathfinder.move_dir, turn_rate)
		enemy.velocity = _direction * chase_speed
		if enemy.set_direction(_direction):
			enemy.update_animation(anim_name)
	else:
		# Stop movement during tackle
		enemy.velocity = Vector2.ZERO
	
	# TAB-TARGET: Check if player is in attack range and apply direct damage
	var distance_to_player = enemy.global_position.distance_to(PlayerManager.player.global_position)
	if distance_to_player <= 40.0:  # Attack range: 40 pixels
		# Player is in attack range - apply direct damage
		print("[Monster] In attack range! Distance: ", distance_to_player, " Cooldown: ", _attack_cooldown)
		_apply_direct_damage_to_player()
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

func _apply_direct_damage_to_player() -> void:
	"""TAB-TARGET: Apply damage directly to the player with tackle animation"""
	# Check cooldown
	if _attack_cooldown > 0.0:
		return
	
	# Check if already tackling
	if _is_tackling:
		return
	
	# Check if player is valid
	if not PlayerManager.player or not is_instance_valid(PlayerManager.player):
		return
	
	# Check if player is dead
	if PlayerManager.player.hp <= 0:
		return
	
	# Get damage from attack_area if it exists, otherwise use default
	var damage = 5  # Default damage
	if attack_area and attack_area.damage > 0:
		damage = attack_area.damage
	
	# Set tackling flag to pause movement
	_is_tackling = true
	
	# Play tackle animation (quick lunge toward player)
	_play_tackle_animation()
	
	# Apply damage to player after a short delay (tackle animation timing)
	await enemy.get_tree().create_timer(0.15).timeout
	
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		if PlayerManager.player.has_method("update_hp"):
			PlayerManager.player.update_hp(-damage)
			print("[Monster] Tackle! Dealt ", damage, " damage to player")
	
	# Wait for tackle animation to complete
	await enemy.get_tree().create_timer(0.15).timeout
	
	# Resume movement
	_is_tackling = false
	
	# Start cooldown
	_attack_cooldown = _attack_cooldown_duration

func _play_tackle_animation() -> void:
	"""Play a quick tackle/lunge animation by moving the sprite"""
	if not enemy or not is_instance_valid(enemy):
		return
	
	# Get the sprite node
	var sprite = enemy.get_node_or_null("Sprite2D")
	if not sprite:
		print("[Monster] No Sprite2D found for tackle animation")
		return
	
	# Calculate tackle direction toward player
	var player_pos = PlayerManager.player.global_position
	var tackle_direction = (player_pos - enemy.global_position).normalized()
	
	# Store original sprite position
	var original_sprite_pos = sprite.position
	
	# Quick lunge forward (15 pixels on sprite)
	var tackle_offset = tackle_direction * 15.0
	var tackle_target = original_sprite_pos + tackle_offset
	
	# Create tween for smooth tackle animation on sprite
	var tween = enemy.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Lunge forward
	tween.tween_property(sprite, "position", tackle_target, 0.1)
	# Return to original position
	tween.tween_property(sprite, "position", original_sprite_pos, 0.15)
	
	print("[Monster] Playing tackle animation")
