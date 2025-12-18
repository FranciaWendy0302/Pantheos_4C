extends Area2D
class_name FlameConvergence

# Flame Convergence - Mage Ultimate (R key)
# Summons fire streams that converge on a point, dealing massive AoE damage

@export var convergence_time: float = 0.5  # Time for flames to converge
@export var burn_duration: float = 4.0  # Total duration of burning zone
@export var initial_damage: float = 100.0  # Damage on convergence
@export var burn_damage_per_tick: float = 15.0  # Damage per 0.5s
@export var slow_amount: float = 0.5  # 50% slow
@export var radius: float = 80.0

var caster: Node2D = null
var enemies_in_zone: Array = []
var has_converged: bool = false
var flame_streams: Array = []
var anim_player: AnimationPlayer = null

func _ready():
	# Setup collision
	collision_layer = 0
	collision_mask = 271  # Detect enemies
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	# Get animation player
	anim_player = get_node_or_null("AnimationPlayer")
	
	if anim_player:
		# Play the flameconvergence animation
		if anim_player.has_animation("flameconvergence"):
			anim_player.play("flameconvergence")
			print("[FlameConvergence] Playing flameconvergence animation")
		else:
			print("[FlameConvergence] WARNING: 'flameconvergence' animation not found!")
	else:
		print("[FlameConvergence] WARNING: AnimationPlayer not found!")
	
	# Start convergence phase
	_create_flame_streams()
	
	print("[FlameConvergence] Ultimate activated! Converging flames...")

func setup(spawn_pos: Vector2, caster_node: Node2D):
	"""Initialize the flame convergence"""
	global_position = spawn_pos
	caster = caster_node

func _create_flame_streams():
	"""Create visual flame streams converging from 8 directions"""
	var directions = [
		Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP,
		Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
		Vector2(-1, -1).normalized(), Vector2(1, -1).normalized()
	]
	
	for direction in directions:
		var stream = CPUParticles2D.new()
		stream.emitting = true
		stream.amount = 20
		stream.lifetime = convergence_time
		stream.one_shot = true
		stream.explosiveness = 0.7
		stream.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		stream.emission_sphere_radius = 5.0
		
		# Particles move toward center
		stream.direction = -direction
		stream.spread = 15.0
		stream.gravity = Vector2.ZERO
		stream.initial_velocity_min = 150.0
		stream.initial_velocity_max = 200.0
		stream.scale_amount_min = 3.0
		stream.scale_amount_max = 5.0
		stream.color = Color(1, 0.5, 0, 1)
		
		# Position stream at distance from center
		stream.position = direction * 150.0
		
		add_child(stream)
		flame_streams.append(stream)
	
	# Start convergence timer
	$ConvergenceTimer.start(convergence_time)

func _on_convergence_complete():
	"""Called when flames have converged"""
	has_converged = true
	print("[FlameConvergence] Flames converged! Dealing initial damage...")
	
	# Animation is already playing from _ready()
	
	# Deal initial damage to all enemies in zone
	for enemy in enemies_in_zone:
		if is_instance_valid(enemy):
			_deal_damage(enemy, initial_damage)
			_apply_slow(enemy)
	
	# Start burn ticks
	$BurnTimer.start()
	
	# Cleanup flame streams
	for stream in flame_streams:
		if is_instance_valid(stream):
			stream.queue_free()
	flame_streams.clear()

func _on_burn_tick():
	"""Deal burn damage every 0.5 seconds"""
	for enemy in enemies_in_zone:
		if is_instance_valid(enemy):
			_deal_damage(enemy, burn_damage_per_tick)

func _on_duration_timeout():
	"""Cleanup when duration expires"""
	print("[FlameConvergence] Burning zone expired")
	
	# Animation will finish naturally
	
	# Remove slow from all enemies
	for enemy in enemies_in_zone:
		if is_instance_valid(enemy):
			_remove_slow(enemy)
	
	queue_free()

func _on_body_entered(body: Node2D):
	"""Enemy entered the burning zone"""
	if body == caster:
		return
	
	if not enemies_in_zone.has(body):
		enemies_in_zone.append(body)
		print("[FlameConvergence] Enemy entered zone: %s" % body.name)
		
		# If convergence already happened, deal initial damage
		if has_converged:
			_deal_damage(body, initial_damage)
			_apply_slow(body)

func _on_body_exited(body: Node2D):
	"""Enemy left the burning zone"""
	enemies_in_zone.erase(body)
	_remove_slow(body)

func _on_area_entered(area: Area2D):
	"""Enemy area entered"""
	var parent = area.get_parent()
	if parent and parent != caster:
		if not enemies_in_zone.has(parent):
			enemies_in_zone.append(parent)
			if has_converged:
				_deal_damage(parent, initial_damage)
				_apply_slow(parent)

func _on_area_exited(area: Area2D):
	"""Enemy area exited"""
	var parent = area.get_parent()
	if parent:
		enemies_in_zone.erase(parent)
		_remove_slow(parent)

func _deal_damage(target: Node2D, damage: float):
	"""Deal fire damage to target"""
	if not target or target == caster:
		return
	
	var hurt_box = HurtBox.new()
	hurt_box.damage = damage
	hurt_box.global_position = global_position
	
	if target.has_method("_take_damage"):
		target._take_damage(hurt_box)
		print("[FlameConvergence] Dealt %.1f damage to %s" % [damage, target.name])
	elif target.has_node("HitBox"):
		var hit_box = target.get_node("HitBox")
		if hit_box.has_method("TakeDamage"):
			hit_box.TakeDamage(hurt_box)
			print("[FlameConvergence] Dealt %.1f damage to %s" % [damage, target.name])
	
	hurt_box.queue_free()

func _apply_slow(target: Node2D):
	"""Apply slow effect to target"""
	if not target or target == caster:
		return
	
	# Try to slow the target's movement
	var state_machine = target.get_node_or_null("StateMachine")
	if state_machine:
		var walk_state = state_machine.get_node_or_null("Walk")
		if walk_state and "move_speed" in walk_state:
			# Store original speed if not already stored
			if not "flame_convergence_original_speed" in walk_state:
				walk_state.set_meta("flame_convergence_original_speed", walk_state.move_speed)
			walk_state.move_speed *= slow_amount
			print("[FlameConvergence] Slowed %s by %.0f%%" % [target.name, (1.0 - slow_amount) * 100])

func _remove_slow(target: Node2D):
	"""Remove slow effect from target"""
	if not target or not is_instance_valid(target):
		return
	
	var state_machine = target.get_node_or_null("StateMachine")
	if state_machine:
		var walk_state = state_machine.get_node_or_null("Walk")
		if walk_state and walk_state.has_meta("flame_convergence_original_speed"):
			walk_state.move_speed = walk_state.get_meta("flame_convergence_original_speed")
			walk_state.remove_meta("flame_convergence_original_speed")
			print("[FlameConvergence] Removed slow from %s" % target.name)
