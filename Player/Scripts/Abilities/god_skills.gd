class_name GodSkills extends Node

# God-bestowed special skills system
# Each god grants a unique powerful skill

var player: Player
var god_skill_cooldown: float = 0.0
var god_skill_cooldown_duration: float = 30.0  # 30 second cooldown

@onready var state_machine: PlayerStateMachine = $"../StateMachine"
@onready var idle: State_Idle = $"../StateMachine/Idle"
@onready var walk: State_Walk = $"../StateMachine/Walk"

func _ready() -> void:
	player = PlayerManager.player
	pass

func _process(delta: float) -> void:
	# Update god skill cooldown
	if god_skill_cooldown > 0.0:
		god_skill_cooldown -= delta
		god_skill_cooldown = max(0.0, god_skill_cooldown)
		# Update HUD cooldown display
		PlayerHud.update_god_skill_cooldown(god_skill_cooldown, god_skill_cooldown_duration)

func can_use_god_skill() -> bool:
	"""Check if god skill can be used"""
	if not GodManager.is_god_skill_unlocked():
		return false
	if god_skill_cooldown > 0.0:
		return false
	if state_machine.current_state != idle and state_machine.current_state != walk:
		return false
	return true

func use_god_skill() -> void:
	"""Use the god's special skill"""
	if not can_use_god_skill():
		return
	
	var god = GodManager.get_selected_god()
	
	# Play activation animation
	_play_activation_animation()
	
	match god:
		GodManager.GodType.ATHENA:
			_use_aegis_shield()
		GodManager.GodType.ZEUS:
			_use_lightning_bolt()
		GodManager.GodType.VENUS:
			_use_divine_charm()
		GodManager.GodType.ASCLEPIUS:
			_use_divine_restoration()
		GodManager.GodType.HADES:
			_use_shadow_grasp()
		GodManager.GodType.ARES:
			_use_berserker_rage()
		GodManager.GodType.THANATOS:
			_use_deaths_touch()
		GodManager.GodType.NEMESIS:
			_use_divine_vengeance()
	
	# Start cooldown
	god_skill_cooldown = god_skill_cooldown_duration
	
	# Update HUD cooldown
	PlayerHud.update_god_skill_cooldown(god_skill_cooldown, god_skill_cooldown_duration)
	
	print("[GodSkills] Used ", GodManager.get_god_special_skill(god))

func _play_activation_animation() -> void:
	"""Play a quick flash animation when activating skill"""
	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.5)
	flash.size = Vector2(100, 100)
	flash.position = Vector2(-50, -50)
	player.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

# ============================================
# GOOD GODS - Protective & Strategic
# ============================================

func _use_aegis_shield() -> void:
	"""Athena - Aegis Shield: 75% damage reduction for 5 seconds"""
	print("[GodSkills] Athena's Aegis Shield activated!")
	
	# Apply damage reduction buff
	player.defense_bonus += 10  # Massive defense boost
	
	# Activate shield visual on health bar
	player.shield_active = true
	player.shield_amount = int(player.max_hp * 0.75)  # 75% of max HP as shield
	
	# Visual effect - golden shield aura
	_create_shield_effect(Color(1.0, 0.84, 0.0))  # Gold
	
	# Remove buff after 5 seconds
	await get_tree().create_timer(5.0).timeout
	player.defense_bonus -= 10
	player.shield_active = false
	player.shield_amount = 0
	print("[GodSkills] Aegis Shield faded")

func _use_lightning_bolt() -> void:
	"""Zeus - Lightning Bolt: Devastating ranged attack"""
	print("[GodSkills] Zeus's Lightning Bolt!")
	
	# Get direction to mouse or cardinal direction
	var strike_direction = player.get_direction_to_mouse()
	if strike_direction == Vector2.ZERO:
		strike_direction = player.cardinal_direction
	
	# Create lightning projectile
	var lightning_pos = player.global_position + strike_direction * 50
	_create_lightning_effect(lightning_pos)
	
	# Deal massive damage in area
	_deal_area_damage(lightning_pos, 100.0, player.attack * 5)

func _use_divine_charm() -> void:
	"""Venus - Divine Charm: Buff allies or debuff enemies"""
	print("[GodSkills] Venus's Divine Charm!")
	
	# Buff nearby party members
	var party_members = _get_nearby_party_members(200.0)
	for member in party_members:
		_apply_buff(member, 1.5, 10.0)  # 50% damage boost for 10 seconds
	
	# Debuff nearby enemies
	var enemies = _get_nearby_enemies(200.0)
	for enemy in enemies:
		_apply_debuff(enemy, 0.5, 10.0)  # 50% damage reduction for 10 seconds
	
	# Visual effect - pink/red aura
	_create_charm_effect()

func _use_divine_restoration() -> void:
	"""Asclepius - Divine Restoration: Powerful AoE heal"""
	print("[GodSkills] Asclepius's Divine Restoration!")
	
	# Heal self
	var heal_amount = int(player.max_hp * 0.5)  # Heal 50% of max HP
	player.update_hp(heal_amount)
	
	# Heal nearby party members
	var party_members = _get_nearby_party_members(300.0)
	for member in party_members:
		if member.has_method("update_hp"):
			member.update_hp(heal_amount)
	
	# Visual effect - green healing aura
	_create_heal_effect()

# ============================================
# EVIL GODS - Aggressive & Dominant
# ============================================

func _use_shadow_grasp() -> void:
	"""Hades - Shadow Grasp: Immobilize enemies for 3 seconds"""
	print("[GodSkills] Hades's Shadow Grasp!")
	
	# Get enemies in area
	var enemies = _get_nearby_enemies(200.0)
	
	for enemy in enemies:
		# Freeze enemy movement
		if enemy.has_method("set_physics_process"):
			enemy.set_physics_process(false)
		
		# Visual effect - dark tendrils
		_create_shadow_effect(enemy.global_position)
		
		# Unfreeze after 3 seconds
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(enemy) and enemy.has_method("set_physics_process"):
			enemy.set_physics_process(true)

func _use_berserker_rage() -> void:
	"""Ares - Berserker Rage: +50% damage, +30% speed for 8 seconds"""
	print("[GodSkills] Ares's Berserker Rage!")
	
	# Boost attack and speed
	var attack_boost = int(player.attack * 0.5)
	player.attack += attack_boost
	player.speed *= 1.3
	
	# Visual effect - red rage aura
	_create_rage_effect()
	
	# Remove buffs after 8 seconds
	await get_tree().create_timer(8.0).timeout
	player.attack -= attack_boost
	player.speed /= 1.3
	print("[GodSkills] Berserker Rage faded")

# ============================================
# FALLEN ANGELS - Chaotic & Overwhelming
# ============================================

func _use_deaths_touch() -> void:
	"""Thanatos - Death's Touch: Massive damage ignoring armor"""
	print("[GodSkills] Death's Touch activated!")
	
	# Create death effect
	_create_death_effect()
	
	# Deal massive damage to nearest enemy, ignoring armor
	var nearest_enemy = _find_nearest_enemy()
	if nearest_enemy:
		nearest_enemy.take_damage(player.attack * 10, true)  # Massive damage, ignore armor

func _use_divine_vengeance() -> void:
	"""Nemesis - Divine Vengeance: Return damage to enemies"""
	print("[GodSkills] Divine Vengeance activated!")
	
	# Enable damage reflection
	player.damage_reflection_active = true
	player.damage_reflection_percent = 0.5  # Return 50% of damage taken
	
	# Visual effect - golden justice aura
	_create_vengeance_effect()
	
	# Disable after 10 seconds
	await get_tree().create_timer(10.0).timeout
	player.damage_reflection_active = false
	print("[GodSkills] Divine Vengeance faded")

# ============================================
# HELPER FUNCTIONS
# ============================================

func _find_nearest_enemy() -> Node:
	"""Find the nearest enemy to the player"""
	var enemies = _get_nearby_enemies(500.0)  # Search within 500 pixels
	if enemies.is_empty():
		return null
	
	var nearest = null
	var nearest_distance = INF
	for enemy in enemies:
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	
	return nearest

func _create_death_effect() -> void:
	"""Create visual effect for Death's Touch"""
	# TODO: Add dark/death particle effect
	print("[GodSkills] Death effect created")

func _create_vengeance_effect() -> void:
	"""Create visual effect for Divine Vengeance"""
	# TODO: Add golden justice aura effect
	print("[GodSkills] Vengeance effect created")

func _get_nearby_party_members(radius: float) -> Array:
	"""Get party members within radius"""
	var members = []
	# TODO: Implement party member detection
	return members

func _get_nearby_enemies(radius: float) -> Array:
	"""Get enemies within radius"""
	var enemies = []
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0, player.global_position)
	query.collision_mask = 256  # Enemy layer
	
	var results = space_state.intersect_shape(query)
	for result in results:
		if result.collider.is_in_group("enemies"):
			enemies.append(result.collider)
	
	return enemies

func _deal_area_damage(position: Vector2, radius: float, damage: int) -> void:
	"""Deal damage to all enemies in area"""
	var enemies = _get_nearby_enemies(radius)
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)

func _apply_buff(target: Node, multiplier: float, duration: float) -> void:
	"""Apply damage buff to target"""
	if target.has_method("set"):
		var original_attack = target.get("attack")
		if original_attack:
			target.set("attack", int(original_attack * multiplier))
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(target):
				target.set("attack", original_attack)

func _apply_debuff(target: Node, multiplier: float, duration: float) -> void:
	"""Apply damage debuff to target"""
	_apply_buff(target, multiplier, duration)

# ============================================
# VISUAL EFFECTS
# ============================================

func _create_shield_effect(color: Color) -> void:
	"""Create shield visual effect - Golden circular shield"""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 30
	particles.lifetime = 5.0
	particles.one_shot = false
	particles.explosiveness = 0.0
	
	# Shield appearance
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 40.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	
	# Particle properties
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 20.0
	particles.angular_velocity_min = -100.0
	particles.angular_velocity_max = 100.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 5.0
	
	# Color
	particles.color = color
	particles.color.a = 0.8
	
	player.add_child(particles)
	
	# Remove after duration
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(particles):
		particles.emitting = false
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(particles):
			particles.queue_free()

func _create_lightning_effect(position: Vector2) -> void:
	"""Create lightning strike effect - Blue electric burst"""
	var particles = CPUParticles2D.new()
	particles.global_position = position
	particles.emitting = true
	particles.amount = 50
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	# Lightning burst
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	particles.direction = Vector2(0, 0)
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	
	# Electric properties
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.damping_min = 50.0
	particles.damping_max = 100.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	
	# Electric blue color
	particles.color = Color(0.3, 0.6, 1.0, 1.0)
	
	player.get_parent().add_child(particles)
	
	# Flash effect
	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.3)
	flash.size = Vector2(1000, 1000)
	flash.position = position - Vector2(500, 500)
	flash.z_index = 100
	player.get_parent().add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(flash.queue_free)
	
	# Remove particles after lifetime
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _create_charm_effect() -> void:
	"""Create charm aura effect - Pink hearts"""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 40
	particles.lifetime = 10.0
	particles.one_shot = false
	
	# Heart particles rising
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 200.0
	particles.direction = Vector2(0, -1)
	particles.spread = 30.0
	particles.gravity = Vector2(0, -20.0)
	
	# Floating hearts
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.angular_velocity_min = -50.0
	particles.angular_velocity_max = 50.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 7.0
	
	# Pink/red color
	particles.color = Color(1.0, 0.4, 0.6, 0.8)
	
	player.add_child(particles)
	
	# Remove after duration
	await get_tree().create_timer(10.0).timeout
	if is_instance_valid(particles):
		particles.emitting = false
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(particles):
			particles.queue_free()

func _create_heal_effect() -> void:
	"""Create healing effect - Green sparkles"""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 60
	particles.lifetime = 2.0
	particles.one_shot = true
	particles.explosiveness = 0.5
	
	# Healing sparkles
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 300.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, -50.0)
	
	# Sparkle properties
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 60.0
	particles.angular_velocity_min = -200.0
	particles.angular_velocity_max = 200.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	
	# Green healing color
	particles.color = Color(0.3, 1.0, 0.3, 1.0)
	
	player.add_child(particles)
	
	# Pulse effect on player
	var original_scale = player.scale
	var tween = create_tween()
	tween.tween_property(player, "scale", original_scale * 1.2, 0.2)
	tween.tween_property(player, "scale", original_scale, 0.2)
	
	# Remove particles
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _create_shadow_effect(position: Vector2) -> void:
	"""Create shadow tendrils effect - Dark purple smoke"""
	var particles = CPUParticles2D.new()
	particles.global_position = position
	particles.emitting = true
	particles.amount = 40
	particles.lifetime = 3.0
	particles.one_shot = false
	
	# Shadow tendrils
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 20.0
	particles.direction = Vector2(0, 0)
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	
	# Tendril properties
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.damping_min = 10.0
	particles.damping_max = 20.0
	particles.scale_amount_min = 8.0
	particles.scale_amount_max = 15.0
	
	# Dark shadow color
	particles.color = Color(0.2, 0.0, 0.3, 0.8)
	
	player.get_parent().add_child(particles)
	
	# Remove after duration
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(particles):
		particles.emitting = false
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(particles):
			particles.queue_free()

func _create_rage_effect() -> void:
	"""Create rage aura effect - Red flames"""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 50
	particles.lifetime = 8.0
	particles.one_shot = false
	
	# Flame aura
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 30.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, -30.0)
	
	# Flame properties
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 80.0
	particles.angular_velocity_min = -100.0
	particles.angular_velocity_max = 100.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	
	# Red/orange flame color
	particles.color = Color(1.0, 0.3, 0.0, 0.9)
	
	player.add_child(particles)
	
	# Screen shake
	if player.get_viewport().get_camera_2d():
		var camera = player.get_viewport().get_camera_2d()
		var original_offset = camera.offset
		for i in range(10):
			camera.offset = original_offset + Vector2(randf_range(-3, 3), randf_range(-3, 3))
			await get_tree().create_timer(0.05).timeout
		camera.offset = original_offset
	
	# Remove after duration
	await get_tree().create_timer(8.0).timeout
	if is_instance_valid(particles):
		particles.emitting = false
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(particles):
			particles.queue_free()

func _create_shockwave_effect() -> void:
	"""Create shockwave effect - Expanding ring"""
	# Create expanding circle
	var circle = Node2D.new()
	circle.z_index = -1
	player.add_child(circle)
	
	# Draw shockwave ring
	var ring_radius = 0.0
	var max_radius = 250.0
	
	# Particles for shockwave
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 100
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	# Shockwave burst
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	particles.direction = Vector2(0, 0)
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	
	# Shockwave properties
	particles.initial_velocity_min = 200.0
	particles.initial_velocity_max = 300.0
	particles.damping_min = 100.0
	particles.damping_max = 150.0
	particles.scale_amount_min = 6.0
	particles.scale_amount_max = 12.0
	
	# Brown/earth color
	particles.color = Color(0.6, 0.4, 0.2, 1.0)
	
	player.add_child(particles)
	
	# Screen shake
	if player.get_viewport().get_camera_2d():
		var camera = player.get_viewport().get_camera_2d()
		var original_offset = camera.offset
		for i in range(15):
			camera.offset = original_offset + Vector2(randf_range(-5, 5), randf_range(-5, 5))
			await get_tree().create_timer(0.05).timeout
		camera.offset = original_offset
	
	# Remove effects
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()
	if is_instance_valid(circle):
		circle.queue_free()

func _create_giant_effect() -> void:
	"""Create giant growth effect - Purple energy"""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 60
	particles.lifetime = 10.0
	particles.one_shot = false
	
	# Energy aura
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 50.0
	particles.direction = Vector2(0, 1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 20.0)
	
	# Energy properties
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 60.0
	particles.angular_velocity_min = -150.0
	particles.angular_velocity_max = 150.0
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 10.0
	
	# Purple/dark energy color
	particles.color = Color(0.5, 0.0, 0.8, 0.9)
	
	player.add_child(particles)
	
	# Growth animation
	var tween = create_tween()
	tween.tween_property(player, "scale", Vector2(2.0, 2.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Remove after duration
	await get_tree().create_timer(10.0).timeout
	if is_instance_valid(particles):
		particles.emitting = false
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(particles):
			particles.queue_free()
