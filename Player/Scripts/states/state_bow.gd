class_name State_Bow extends State

const ARROW = preload("res://Interactables/arrow/arrow.tscn")

@export var auto_attack_cooldown: float = 0.3  # Time between auto attacks
@export var charge_time: float = 1.0  # Time to charge big arrow
@export var charge_required: float = 0.5  # Minimum charge time for big arrow

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"

var direction: Vector2 = Vector2.ZERO
var next_state: State = null
var _auto_attack_timer: float = 0.0
var _is_auto_attacking: bool = false
var _charge_timer: float = 0.0
var _is_charging: bool = false
var _animation_finished: bool = false

func _ready():
	pass
	
var _is_e_skill_charge: bool = false  # Track if this is E skill charge

func Enter() -> void:
	# Update player direction to face mouse cursor
	_update_player_facing()
	
	player.UpdateAnimation("bow")
	player.animation_player.animation_finished.connect(_on_animation_finished)
	
	# Get direction to mouse cursor
	direction = player.get_direction_to_mouse()
	if direction == Vector2.ZERO:
		direction = player.cardinal_direction
	
	# Check if this is E skill charge (set by player.gd when E is pressed)
	if _is_e_skill_charge and PlayerManager.selected_class == "Archer":
		# This is Archer E skill charge - start charging
		_is_charging = true
		_charge_timer = 0.0
		_auto_attack_timer = 0.0
		# Make player invulnerable during charge (uninterruptible)
		player.invulnerable = true
		_is_e_skill_charge = false  # Reset flag
		# Show skill name label
		PlayerHud.show_skill_name("E", "Charge Arrow")
		# Show charge indicator
		PlayerHud.update_charge_indicator(0.0, false)
	else:
		# Normal attack - single shot (no charge, no hold)
		if PlayerManager.selected_class == "Archer":
			# Start basic attack cooldown
			player.basic_attack_cooldown = player.basic_attack_cooldown_duration
			_shoot_arrow(false)
		else:
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
	# Hide skill name and charge indicator
	if PlayerManager.selected_class == "Archer":
		PlayerHud.hide_skill_name("E")
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
	# Handle Archer E skill release (for charge attack)
	if PlayerManager.selected_class == "Archer" and _is_charging:
		if _event is InputEventKey:
			var key_event = _event as InputEventKey
			if key_event.keycode == KEY_E and not key_event.pressed:
				# E key released - fire big arrow if charged enough
				if _charge_timer >= charge_required:
					# Shoot big arrow (uninterruptible)
					# Big arrow consumes arrows, so check if we have arrows
					if player.arrow_count > 0:
						# Shoot big arrow
						_shoot_arrow(true)  # Big arrow
						_animation_finished = false
						_is_charging = false
						# Player is invulnerable during shot
						player.invulnerable = true
					else:
						# No arrows for big arrow, go to idle
						_is_charging = false
						player.invulnerable = false
						return idle
				else:
					# Not charged enough, go back to idle
					_is_charging = false
					player.invulnerable = false
					return idle
	
	# Disable attack button hold to charge - only E key works for Archer
	# For non-Archer, attack button release should not trigger charge
	if _event.is_action_released("attack"):
		# Only allow charge from attack button for non-Archer classes
		# But since we removed hold-to-charge, this should just return to idle
		if _is_charging and PlayerManager.selected_class != "Archer":
			# Not Archer, but somehow charging from attack - cancel it
			_is_charging = false
			player.invulnerable = false
			return idle
	
	return null

func _shoot_arrow(is_big: bool) -> void:
	# Update player facing direction before shooting
	_update_player_facing()
	
	# Get direction to mouse cursor
	direction = player.get_direction_to_mouse()
	if direction == Vector2.ZERO:
		direction = player.cardinal_direction
	
	# For Archer class, normal attacks don't consume arrows (unlimited)
	# Only big arrow (E skill) consumes arrows
	var should_consume_arrow = is_big  # Only consume for big arrow
	
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
