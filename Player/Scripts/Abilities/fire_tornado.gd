extends Area2D
class_name FireTornado

@export var charge_speed: float = 250.0
@export var charge_distance: float = 150.0
@export var spin_duration: float = 4.0  # How long it spins in place
@export var damage_per_second: float = 20.0
@export var damage_tick_rate: float = 0.5  # Damage every 0.5 seconds
@export var deceleration: float = 400.0  # How fast it slows down after hitting

enum State { CHARGING, DECELERATING, SPINNING, EXPIRED }

var state = State.CHARGING
var current_speed: float = 0.0
var direction: Vector2 = Vector2.RIGHT
var caster: Node2D = null
var start_position: Vector2 = Vector2.ZERO
var target_enemy: Node2D = null
var lifetime: float = 0.0
var damage_timer: float = 0.0
var enemies_in_range: Array = []

func _ready() -> void:
	# Setup collision to detect enemies
	collision_layer = 0
	collision_mask = 271  # Same as fireball - detects enemies
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	# Start animation
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player:
		# Try to play "spin" animation specifically
		if anim_player.has_animation("spin"):
			anim_player.play("spin")
			print("[FireTornado] Playing 'spin' animation")
		else:
			# Fallback to first available animation
			var anim_list = anim_player.get_animation_list()
			if anim_list.size() > 0:
				anim_player.play(anim_list[0])
				print("[FireTornado] Playing animation: %s" % anim_list[0])
			else:
				print("[FireTornado] WARNING: No animations found!")
	else:
		print("[FireTornado] WARNING: AnimationPlayer not found!")
	
	print("[FireTornado] Spawned - Charging phase")

func setup(spawn_pos: Vector2, fire_direction: Vector2, caster_node: Node2D) -> void:
	"""Initialize the fire tornado"""
	global_position = spawn_pos
	start_position = spawn_pos
	direction = fire_direction.normalized()
	caster = caster_node
	state = State.CHARGING
	current_speed = charge_speed

func _physics_process(delta: float) -> void:
	lifetime += delta
	
	match state:
		State.CHARGING:
			_process_charging(delta)
		State.DECELERATING:
			_process_decelerating(delta)
		State.SPINNING:
			_process_spinning(delta)
		State.EXPIRED:
			queue_free()
	
	# Deal damage to enemies in range
	_process_damage(delta)

func _process_charging(delta: float) -> void:
	"""Charge forward in initial direction"""
	global_position += direction * current_speed * delta
	
	# Check if we've traveled the charge distance
	var distance_traveled = global_position.distance_to(start_position)
	if distance_traveled >= charge_distance:
		_transition_to_decelerating()

func _process_decelerating(delta: float) -> void:
	"""Slowly decelerate to a stop after hitting something"""
	# Reduce speed gradually
	current_speed = max(0.0, current_speed - deceleration * delta)
	
	# Keep moving forward while decelerating
	if current_speed > 0:
		global_position += direction * current_speed * delta
	else:
		# Fully stopped, transition to spinning
		_transition_to_spinning()

func _process_spinning(delta: float) -> void:
	"""Spin in place and deal damage"""
	# Check if spin duration expired
	if lifetime >= spin_duration:
		print("[FireTornado] Spin duration expired")
		state = State.EXPIRED
		return

func _transition_to_decelerating() -> void:
	"""Start decelerating after hitting something"""
	print("[FireTornado] Hit - Decelerating to a stop...")
	state = State.DECELERATING

func _transition_to_spinning() -> void:
	"""Transition to spinning state after fully stopped"""
	print("[FireTornado] Stopped - Now spinning in place for %.1fs" % spin_duration)
	state = State.SPINNING
	current_speed = 0.0
	lifetime = 0.0  # Reset lifetime for spin duration

func _process_damage(delta: float) -> void:
	"""Deal damage to enemies touching the tornado"""
	damage_timer += delta
	
	if damage_timer >= damage_tick_rate:
		damage_timer = 0.0
		
		# Deal damage to all enemies currently in range
		for enemy in enemies_in_range:
			if is_instance_valid(enemy):
				_deal_damage_to(enemy)

func _on_body_entered(body: Node2D) -> void:
	"""Track enemies entering the tornado and start decelerating if hit"""
	if body == caster:
		return
	
	# If we hit an enemy while charging, start decelerating
	if state == State.CHARGING:
		print("[FireTornado] Hit enemy while charging - decelerating")
		_transition_to_decelerating()
	
	if not enemies_in_range.has(body):
		enemies_in_range.append(body)
		print("[FireTornado] Enemy entered: %s" % body.name)

func _on_body_exited(body: Node2D) -> void:
	"""Track enemies leaving the tornado"""
	enemies_in_range.erase(body)

func _on_area_entered(area: Area2D) -> void:
	"""Track enemy areas entering"""
	var parent = area.get_parent()
	if parent and parent != caster:
		if not enemies_in_range.has(parent):
			enemies_in_range.append(parent)

func _on_area_exited(area: Area2D) -> void:
	"""Track enemy areas leaving"""
	var parent = area.get_parent()
	if parent:
		enemies_in_range.erase(parent)

func _deal_damage_to(target: Node2D) -> void:
	"""Deal damage to an enemy"""
	if not target or target == caster:
		return
	
	var hurt_box = HurtBox.new()
	hurt_box.damage = damage_per_second * damage_tick_rate
	hurt_box.global_position = global_position
	
	if target.has_method("_take_damage"):
		target._take_damage(hurt_box)
		print("[FireTornado] Dealt %.1f damage to %s" % [hurt_box.damage, target.name])
	elif target.has_node("HitBox"):
		var hit_box = target.get_node("HitBox")
		if hit_box.has_method("TakeDamage"):
			hit_box.TakeDamage(hurt_box)
			print("[FireTornado] Dealt %.1f damage to %s" % [hurt_box.damage, target.name])
	
	hurt_box.queue_free()
