extends Node
class_name MageAbilities

# Mage-specific abilities with visual effects
# This class contains ALL mage skill implementations
# Weapons just reference which skills to enable via skill_id

var player: Player

# Skill costs
const TELEPORT_COST = 30
const FIREBALL_COST = 20
const FIRE_WHEEL_COST = 18
const FIRE_TORNADO_COST = 25
const MANA_SPRINT_REGEN_PERCENT = 0.15  # 15% of max mana

# Preload projectile scenes
const FIREBALL_SCENE = preload("res://Player/Scripts/Abilities/fireball_projectile.tscn")
const FIRE_WHEEL_SCENE = preload("res://Player/Scripts/Abilities/fire_wheel.tscn")
const FIRE_TORNADO_SCENE = preload("res://Player/Scripts/Abilities/firetornado.tscn")
const ARCANE_WEAVE_SCENE = preload("res://Player/Scripts/Abilities/arcane_weave.tscn")
const MANA_SPRINT_SCENE = preload("res://Player/Scripts/Abilities/mana_sprint.tscn")
const FLAME_CONVERGENCE_SCENE = preload("res://Player/Scripts/Abilities/flame_convergence.tscn")

# Skill registry - maps skill_id to execution function
var skill_registry: Dictionary = {}

var is_mana_sprinting: bool = false
var mana_sprint_timer: float = 0.0
var mana_sprint_duration: float = 3.0  # Sprint lasts 3 seconds
var mana_regen_from_sprint: float = 0.0

signal ability_used(ability_name: String)
signal mana_changed(current: float, max: float)
signal mana_sprint_started()
signal mana_sprint_ended()

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	await get_tree().process_frame
	
	# Register all mage skills
	_register_skills()
	
	if player:
		# Initialize player mana if needed
		if player.max_mana == 0:
			player.max_mana = 150
			player.mana = 150
		mana_changed.emit(player.mana, player.max_mana)

func _register_skills() -> void:
	"""Register all mage skills with their IDs"""
	skill_registry["teleport"] = use_teleport
	skill_registry["fireball"] = use_fireball
	skill_registry["fire_wheel"] = use_fire_wheel
	skill_registry["fire_tornado"] = use_fire_tornado
	skill_registry["mana_sprint"] = use_mana_sprint_skill
	skill_registry["arcane_weave"] = use_arcane_weave
	skill_registry["flame_convergence"] = use_flame_convergence
	
	print("[MageAbilities] Registered %d skills" % skill_registry.size())

func execute_skill(skill_id: String) -> bool:
	"""Execute a skill by its ID - called by ability system"""
	print("[MageAbilities] execute_skill called with ID: %s" % skill_id)
	print("[MageAbilities] Registered skills: ", skill_registry.keys())
	
	if not skill_registry.has(skill_id):
		print("[MageAbilities] ERROR: Unknown skill ID: %s" % skill_id)
		return false
	
	print("[MageAbilities] Found skill in registry, executing...")
	var skill_func: Callable = skill_registry[skill_id]
	var result = skill_func.call()
	print("[MageAbilities] Skill function returned: ", result)
	return result

func use_teleport() -> bool:
	"""Q - Teleport: Teleport short distance towards mouse"""
	if not player or player.mana < TELEPORT_COST:
		print("[Mage] Not enough mana for Teleport (%d/%d)" % [player.mana if player else 0, TELEPORT_COST])
		return false
	
	player.mana -= TELEPORT_COST
	mana_changed.emit(player.mana, player.max_mana)
	
	# Teleport player forward with visual effect
	_perform_teleport()
	
	print("[Mage] Teleported! (Mana: %d/%d)" % [player.mana, player.max_mana])
	ability_used.emit("teleport")
	return true

func use_fireball() -> bool:
	"""W - Fireball: Launch a powerful fireball projectile"""
	if not player:
		print("[Mage] Player not found")
		return false
	
	# Use stat system if available
	var stat_system = player.get_node_or_null("StatSystem")
	if stat_system:
		if not stat_system.consume_mp(FIREBALL_COST):
			print("[Mage] Not enough mana for Fireball")
			return false
	else:
		# Fallback to old system
		if player.mana < FIREBALL_COST:
			print("[Mage] Not enough mana for Fireball (%d/%d)" % [player.mana, FIREBALL_COST])
			return false
		player.mana -= FIREBALL_COST
		mana_changed.emit(player.mana, player.max_mana)
		_update_player_hud()
	
	# Spawn fireball projectile
	_spawn_fireball()
	
	ability_used.emit("fireball")
	return true

func use_fire_wheel() -> bool:
	"""W - Fire Wheel: Launch a fast spinning fire wheel projectile"""
	if not player:
		print("[Mage] Player not found")
		return false
		
	print("[Mage] Fire Wheel - Current mana: %d, Cost: %d" % [player.mana, FIRE_WHEEL_COST])
	
	if player.mana < FIRE_WHEEL_COST:
		print("[Mage] Not enough mana for Fire Wheel (%d/%d)" % [player.mana, FIRE_WHEEL_COST])
		return false
	
	# Consume mana
	player.mana -= FIRE_WHEEL_COST
	print("[Mage] Mana consumed! New mana: %d/%d" % [player.mana, player.max_mana])
	
	# Update HUD
	mana_changed.emit(player.mana, player.max_mana)
	_update_player_hud()
	
	# Spawn fire wheel
	_spawn_fire_wheel()
	
	print("[Mage] Cast Fire Wheel! (Mana: %d/%d)" % [player.mana, player.max_mana])
	ability_used.emit("fire_wheel")
	return true

func use_fire_tornado() -> bool:
	"""E - Fire Tornado: Summon a chasing fire tornado"""
	if not player:
		print("[Mage] Player not found")
		return false
		
	print("[Mage] Fire Tornado - Current mana: %d, Cost: %d" % [player.mana, FIRE_TORNADO_COST])
	
	if player.mana < FIRE_TORNADO_COST:
		print("[Mage] Not enough mana for Fire Tornado (%d/%d)" % [player.mana, FIRE_TORNADO_COST])
		return false
	
	# Consume mana
	player.mana -= FIRE_TORNADO_COST
	print("[Mage] Mana consumed! New mana: %d/%d" % [player.mana, player.max_mana])
	
	# Update HUD
	mana_changed.emit(player.mana, player.max_mana)
	_update_player_hud()
	
	# Spawn fire tornado
	_spawn_fire_tornado()
	
	print("[Mage] Cast Fire Tornado! (Mana: %d/%d)" % [player.mana, player.max_mana])
	ability_used.emit("fire_tornado")
	return true

func start_mana_sprint() -> bool:
	"""Q - Mana Sprint: Sprint while regenerating mana and increasing speed"""
	if not player:
		return false
		
	if is_mana_sprinting:
		print("[Mage] Mana Sprint already active")
		return false
	
	is_mana_sprinting = true
	mana_sprint_timer = 0.0
	mana_regen_from_sprint = player.max_mana * MANA_SPRINT_REGEN_PERCENT
	
	print("[Mage] *** MANA SPRINT STARTED *** Speed multiplier: %.1f, Duration: %.1fs" % [get_speed_multiplier(), mana_sprint_duration])
	
	mana_sprint_started.emit()
	ability_used.emit("mana_sprint")
	return true

func stop_mana_sprint() -> void:
	"""Stop mana sprint"""
	if not is_mana_sprinting:
		return
	
	is_mana_sprinting = false
	print("[Mage] *** MANA SPRINT ENDED *** Speed back to normal")
	mana_sprint_ended.emit()

func get_speed_multiplier() -> float:
	"""Get current speed multiplier for mana sprint"""
	return 1.3 if is_mana_sprinting else 1.0

func regenerate_mana(delta: float) -> void:
	"""Passive mana regeneration"""
	if not player:
		return
		
	var regen_rate = 8.0  # mana per second
	
	# Mana sprint regeneration
	if is_mana_sprinting:
		mana_sprint_timer += delta
		
		# Regenerate mana over sprint duration
		var sprint_regen_rate = mana_regen_from_sprint / mana_sprint_duration
		regen_rate += sprint_regen_rate
		
		print("[Mage] Mana Sprint regen - Timer: %.1f/%.1f, Base regen: %.1f, Sprint regen: %.1f, Total: %.1f" % [mana_sprint_timer, mana_sprint_duration, 8.0, sprint_regen_rate, regen_rate])
		
		# End sprint after duration
		if mana_sprint_timer >= mana_sprint_duration:
			stop_mana_sprint()
	
	if player.mana < player.max_mana:
		var old_mana = player.mana
		var mana_to_add = int(regen_rate * delta)
		player.mana = min(player.mana + mana_to_add, player.max_mana)
		
		if player.mana != old_mana:
			print("[Mage] Mana regenerated: %d -> %d (added %d)" % [old_mana, player.mana, mana_to_add])
			mana_changed.emit(player.mana, player.max_mana)
			_update_player_hud()

func _update_player_hud() -> void:
	"""Update PlayerHud mana display"""
	if not player:
		return
	
	# Find PlayerHud and update mana
	var player_hud = get_tree().get_first_node_in_group("player_hud")
	if not player_hud:
		player_hud = get_node_or_null("/root/PlayerHud")
	
	if player_hud and player_hud.has_method("update_mana"):
		player_hud.update_mana(player.mana, player.max_mana)

func basic_attack(target: Node2D) -> void:
	"""Ranged basic attack - shoots a magic bolt at target"""
	if not player or not target or not is_instance_valid(target):
		return
	
	# Spawn magic bolt projectile
	_spawn_magic_bolt(target)

# Skill implementations
func _spawn_fireball():
	"""Spawn a fireball projectile using the fireball.png sprite"""
	if not player or not player.get_parent():
		return
	
	# Get firing direction towards mouse
	var mouse_pos = player.get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()
	
	# Spawn fireball projectile
	var fireball = FIREBALL_SCENE.instantiate()
	player.get_parent().add_child(fireball)
	
	# Setup fireball with position, direction, and damage
	var spawn_offset = direction * 25  # Spawn slightly in front of player
	fireball.setup(player.global_position + spawn_offset, direction, player)
	fireball.damage = player.attack * 1.5 if "attack" in player else 25.0

func _spawn_fire_wheel():
	"""Spawn a fast spinning fire wheel projectile"""
	if not player or not player.get_parent():
		return
	
	# Get firing direction towards mouse
	var mouse_pos = player.get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()
	
	# Spawn fire wheel projectile
	var fire_wheel = FIRE_WHEEL_SCENE.instantiate()
	player.get_parent().add_child(fire_wheel)
	
	# Setup fire wheel with position, direction, and damage
	var spawn_offset = direction * 25  # Spawn slightly in front of player
	fire_wheel.setup(player.global_position + spawn_offset, direction, player)
	fire_wheel.damage = player.attack * 1.2 if "attack" in player else 35.0

func _spawn_fire_tornado():
	"""Spawn a fire tornado that charges then chases enemies"""
	if not player or not player.get_parent():
		return
	
	# Get firing direction towards mouse
	var mouse_pos = player.get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()
	
	# Spawn fire tornado
	var tornado = FIRE_TORNADO_SCENE.instantiate()
	player.get_parent().add_child(tornado)
	
	# Setup tornado with position, direction, and caster
	tornado.setup(player.global_position, direction, player)

func _spawn_ice_shards_old():
	"""Spawn ice shard projectiles in a spread pattern"""
	if not player:
		return
	
	var direction = player.cardinal_direction if player.cardinal_direction != Vector2.ZERO else Vector2.RIGHT
	var angles = [-20, 0, 20]  # Three shards in a spread
	
	for angle_offset in angles:
		var ice_shard = CPUParticles2D.new()
		ice_shard.emitting = true
		ice_shard.amount = 15
		ice_shard.lifetime = 0.6
		ice_shard.one_shot = true
		ice_shard.explosiveness = 0.7
		ice_shard.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		ice_shard.emission_sphere_radius = 5.0
		ice_shard.gravity = Vector2.ZERO
		ice_shard.initial_velocity_min = 180.0
		ice_shard.initial_velocity_max = 220.0
		ice_shard.scale_amount_min = 2.0
		ice_shard.scale_amount_max = 4.0
		ice_shard.color = Color.CYAN
		
		# Calculate direction with angle offset
		var angle_rad = direction.angle() + deg_to_rad(angle_offset)
		var shard_direction = Vector2(cos(angle_rad), sin(angle_rad))
		
		ice_shard.global_position = player.global_position + direction * 15
		ice_shard.direction = shard_direction
		ice_shard.spread = 15.0
		
		player.get_parent().add_child(ice_shard)
		
		# Auto-cleanup
		var timer = get_tree().create_timer(0.8)
		timer.timeout.connect(func(): 
			if is_instance_valid(ice_shard):
				ice_shard.queue_free()
		)

func _perform_teleport():
	"""Teleport player towards mouse with visual effect"""
	if not player:
		return
	
	# Spawn disappear effect at current position
	_spawn_teleport_effect(player.global_position, Color.PURPLE)
	
	# Get teleport direction towards mouse
	var mouse_pos = player.get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()
	
	# Teleport player
	var teleport_distance = 100.0
	player.global_position += direction * teleport_distance
	
	# Spawn appear effect at new position
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(player):
		_spawn_teleport_effect(player.global_position, Color.MAGENTA)

func _spawn_teleport_effect(pos: Vector2, color: Color):
	"""Spawn teleport visual effect"""
	var effect = CPUParticles2D.new()
	effect.emitting = true
	effect.amount = 30
	effect.lifetime = 0.5
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	effect.emission_sphere_radius = 15.0
	effect.direction = Vector2.UP
	effect.spread = 180.0
	effect.gravity = Vector2.ZERO
	effect.initial_velocity_min = 50.0
	effect.initial_velocity_max = 100.0
	effect.scale_amount_min = 3.0
	effect.scale_amount_max = 6.0
	effect.color = color
	
	effect.global_position = pos
	
	if player and player.get_parent():
		player.get_parent().add_child(effect)
		
		# Auto-cleanup
		await get_tree().create_timer(0.6).timeout
		if is_instance_valid(effect):
			effect.queue_free()

func _spawn_magic_bolt(target: Node2D):
	"""Spawn a magic bolt projectile that travels to target"""
	if not player or not target:
		return
	
	# Create magic bolt visual
	var bolt = CPUParticles2D.new()
	bolt.emitting = true
	bolt.amount = 10
	bolt.lifetime = 0.3
	bolt.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	bolt.emission_sphere_radius = 5.0
	bolt.gravity = Vector2.ZERO
	bolt.initial_velocity_min = 20.0
	bolt.initial_velocity_max = 40.0
	bolt.scale_amount_min = 2.0
	bolt.scale_amount_max = 3.0
	bolt.color = Color.LIGHT_BLUE
	
	bolt.global_position = player.global_position
	
	if player.get_parent():
		player.get_parent().add_child(bolt)
		
		# Animate bolt to target
		_animate_projectile_to_target(bolt, target)

func _animate_projectile_to_target(projectile: Node2D, target: Node2D):
	"""Animate projectile moving to target and deal damage on hit"""
	if not projectile or not target or not is_instance_valid(target):
		return
	
	var start_pos = projectile.global_position
	var travel_time = 0.5  # seconds
	var elapsed = 0.0
	
	while elapsed < travel_time:
		var delta = await get_tree().process_frame
		elapsed += 0.016  # Approximate frame time
		
		if not is_instance_valid(projectile) or not is_instance_valid(target):
			break
		
		var progress = elapsed / travel_time
		projectile.global_position = start_pos.lerp(target.global_position, progress)
		
		# Check if reached target
		if progress >= 1.0 or projectile.global_position.distance_to(target.global_position) < 10.0:
			# Deal damage to target using HurtBox system
			if target.has_node("HitBox"):
				var hit_box = target.get_node("HitBox")
				# Create a temporary hurt box to deal damage
				var hurt_box = HurtBox.new()
				hurt_box.damage = player.attack if player else 5
				hurt_box.global_position = projectile.global_position
				# Trigger damage
				if hit_box.has_method("TakeDamage"):
					hit_box.TakeDamage(hurt_box)
				hurt_box.queue_free()
			elif target.has_method("_take_damage"):
				# Direct damage method
				var hurt_box = HurtBox.new()
				hurt_box.damage = player.attack if player else 5
				target._take_damage(hurt_box)
				hurt_box.queue_free()
			
			# Spawn hit effect
			_spawn_hit_effect(target.global_position)
			break
	
	# Cleanup projectile
	if is_instance_valid(projectile):
		projectile.queue_free()

func _spawn_hit_effect(pos: Vector2):
	"""Spawn impact effect when projectile hits"""
	var effect = CPUParticles2D.new()
	effect.emitting = true
	effect.amount = 15
	effect.lifetime = 0.3
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	effect.emission_sphere_radius = 8.0
	effect.direction = Vector2.UP
	effect.spread = 180.0
	effect.gravity = Vector2.ZERO
	effect.initial_velocity_min = 30.0
	effect.initial_velocity_max = 60.0
	effect.scale_amount_min = 2.0
	effect.scale_amount_max = 4.0
	effect.color = Color.LIGHT_BLUE
	
	effect.global_position = pos
	
	if player and player.get_parent():
		player.get_parent().add_child(effect)
		
		# Auto-cleanup
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(effect):
			effect.queue_free()


func use_arcane_weave() -> bool:
	"""D - Arcane Weave: Enhance spell power with mana"""
	const ARCANE_WEAVE_COST = 25
	
	if not player:
		print("[Mage] Player not found")
		return false
	
	if player.mana < ARCANE_WEAVE_COST:
		print("[Mage] Not enough mana for Arcane Weave (%d/%d)" % [player.mana, ARCANE_WEAVE_COST])
		return false
	
	# Consume mana
	player.mana -= ARCANE_WEAVE_COST
	mana_changed.emit(player.mana, player.max_mana)
	_update_player_hud()
	
	# Spawn arcane weave effect
	_spawn_arcane_weave()
	
	print("[Mage] Cast Arcane Weave! (Mana: %d/%d)" % [player.mana, player.max_mana])
	ability_used.emit("arcane_weave")
	return true

func use_mana_sprint_skill() -> bool:
	"""F - Mana Sprint: Boost movement speed with mana"""
	const MANA_SPRINT_COST = 20
	
	if not player:
		print("[Mage] Player not found")
		return false
	
	if player.mana < MANA_SPRINT_COST:
		print("[Mage] Not enough mana for Mana Sprint (%d/%d)" % [player.mana, MANA_SPRINT_COST])
		return false
	
	# Consume mana
	player.mana -= MANA_SPRINT_COST
	mana_changed.emit(player.mana, player.max_mana)
	_update_player_hud()
	
	# Spawn mana sprint effect
	_spawn_mana_sprint()
	
	print("[Mage] Cast Mana Sprint! (Mana: %d/%d)" % [player.mana, player.max_mana])
	ability_used.emit("mana_sprint")
	return true

func _spawn_arcane_weave():
	"""Spawn arcane weave buff effect"""
	if not player or not player.get_parent():
		return
	
	var arcane_weave = ARCANE_WEAVE_SCENE.instantiate()
	player.get_parent().add_child(arcane_weave)
	arcane_weave.setup(player, 5.0)  # 5 second duration

func _spawn_mana_sprint():
	"""Spawn mana sprint buff effect"""
	if not player or not player.get_parent():
		return
	
	var mana_sprint = MANA_SPRINT_SCENE.instantiate()
	player.get_parent().add_child(mana_sprint)
	mana_sprint.setup(player, 3.0)  # 3 second duration


func use_flame_convergence() -> bool:
	"""R - Flame Convergence: Ultimate AoE skill"""
	const FLAME_CONVERGENCE_COST = 80
	
	if not player:
		print("[Mage] Player not found")
		return false
	
	if player.mana < FLAME_CONVERGENCE_COST:
		print("[Mage] Not enough mana for Flame Convergence (%d/%d)" % [player.mana, FLAME_CONVERGENCE_COST])
		return false
	
	# Consume mana
	player.mana -= FLAME_CONVERGENCE_COST
	mana_changed.emit(player.mana, player.max_mana)
	_update_player_hud()
	
	# Spawn flame convergence at mouse position
	_spawn_flame_convergence()
	
	print("[Mage] Cast Flame Convergence! (Mana: %d/%d)" % [player.mana, player.max_mana])
	ability_used.emit("flame_convergence")
	return true

func _spawn_flame_convergence():
	"""Spawn flame convergence ultimate at target location"""
	if not player or not player.get_parent():
		return
	
	# Get target position (mouse)
	var target_pos = player.get_global_mouse_position()
	
	# Spawn flame convergence
	var flame_convergence = FLAME_CONVERGENCE_SCENE.instantiate()
	player.get_parent().add_child(flame_convergence)
	
	# Setup with position and damage scaling
	flame_convergence.setup(target_pos, player)
	
	# Scale damage with player attack
	if "attack" in player:
		flame_convergence.initial_damage = player.attack * 3.0  # 300% attack damage
		flame_convergence.burn_damage_per_tick = player.attack * 0.5  # 50% attack per tick
	
	print("[Mage] Flame Convergence spawned at: ", target_pos)
