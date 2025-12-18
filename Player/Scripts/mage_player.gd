extends Player
class_name MagePlayer

# Mage-specific player script with floating animation and Q, W, E skills

var mage_abilities: MageAbilities = null
@onready var float_timer: Timer = Timer.new()

# Floating animation variables
var float_offset: float = 0.0
var float_speed: float = 2.0
var float_amplitude: float = 3.0

# Skill cooldowns
var q_cooldown: float = 0.0
var w_cooldown: float = 0.0
var e_cooldown: float = 0.0

const Q_COOLDOWN_TIME: float = 5.0  # Fireball
const W_COOLDOWN_TIME: float = 3.0  # Ice Shard
const E_COOLDOWN_TIME: float = 8.0  # Teleport

func _ready():
	super._ready()
	
	# Mage is a ranged class - increase attack range
	attack_range = 200.0  # Long range for magic attacks
	
	# Disable attack hitbox for mage (uses magic skills instead)
	await get_tree().process_frame
	if has_node("Sprite2D/AttackHurtBox"):
		var attack_hurtbox = get_node("Sprite2D/AttackHurtBox")
		attack_hurtbox.monitoring = false
		attack_hurtbox.set_deferred("monitoring", false)
	
	# Setup floating animation timer
	add_child(float_timer)
	float_timer.wait_time = 0.016  # ~60 FPS
	float_timer.timeout.connect(_update_float_animation)
	float_timer.start()
	
	# Get mage abilities node (already exists in scene with MageAbilities script)
	if has_node("Abilities"):
		mage_abilities = get_node("Abilities")
		print("[MagePlayer] Found Abilities node: ", mage_abilities, " (type: ", mage_abilities.get_class(), ")")
	else:
		print("[MagePlayer] WARNING: No Abilities node found in scene!")
	
	print("[MagePlayer] Mage initialized with floating animation and Q/W/E skills")

func _process(delta):
	super._process(delta)
	
	# Update skill cooldowns
	if q_cooldown > 0.0:
		q_cooldown -= delta
	if w_cooldown > 0.0:
		w_cooldown -= delta
	if e_cooldown > 0.0:
		e_cooldown -= delta
	
	# Regenerate mana
	if mage_abilities:
		mage_abilities.regenerate_mana(delta)

func _physics_process(delta):
	# Apply mana sprint speed boost to velocity
	if mage_abilities and mage_abilities.is_mana_sprinting:
		var original_velocity = velocity
		var multiplier = mage_abilities.get_speed_multiplier()
		velocity *= multiplier
		print("[Mage] Mana Sprint active! Original velocity: %s, Multiplier: %.1f, New velocity: %s" % [original_velocity, multiplier, velocity])
	
	super._physics_process(delta)

func _update_float_animation():
	# Create floating effect by oscillating sprite position
	float_offset += float_speed * 0.016
	if sprite:
		var base_y = -20  # Original sprite Y position
		sprite.position.y = base_y + sin(float_offset) * float_amplitude
		# Update sprite frame based on direction
		_update_sprite_frame()

func _update_sprite_frame():
	# Mage sprite has 3 frames: 0=down, 1=side, 2=up
	if not sprite:
		return
	
	match cardinal_direction:
		Vector2.DOWN:
			sprite.frame = 0
		Vector2.LEFT, Vector2.RIGHT:
			sprite.frame = 1
		Vector2.UP:
			sprite.frame = 2

func _input(event: InputEvent) -> void:
	super._input(event)
	
	# DISABLED: Old skill system - now using AbilitySystem with SkillReference
	# The parent Player class handles Q/W/E through ability_system
	
	# BLOCK ALL INPUT WHEN CHAT IS OPEN
	#var chat_panel = get_tree().get_first_node_in_group("chat_panel")
	#if chat_panel and chat_panel.is_chat_open:
	#	return
	#
	#if event is InputEventKey:
	#	var key_event = event as InputEventKey
	#	if key_event.pressed and not key_event.echo:
	#		match key_event.keycode:
	#			KEY_Q:
	#				_use_skill_q()
	#			KEY_W:
	#				_use_skill_w()
	#			KEY_E:
	#				_use_skill_e()

func _use_skill_q():
	"""Q - Mana Sprint: Activate mana regeneration sprint"""
	if q_cooldown > 0.0:
		print("[Mage] Mana Sprint on cooldown: %.1fs" % q_cooldown)
		return
	
	if not mage_abilities:
		print("[Mage] ERROR: mage_abilities not found!")
		return
	
	print("[Mage] Attempting to start Mana Sprint...")
	# Start mana sprint (auto-stops after duration)
	if mage_abilities.start_mana_sprint():
		q_cooldown = Q_COOLDOWN_TIME
		print("[Mage] Mana Sprint activated! Cooldown: %.1fs" % Q_COOLDOWN_TIME)
	else:
		print("[Mage] Failed to start Mana Sprint!")

func _use_skill_w():
	"""W - Fireball: Launch a powerful fireball projectile"""
	if w_cooldown > 0.0:
		print("[Mage] Fireball on cooldown: %.1fs" % w_cooldown)
		return
	
	if mage_abilities and mage_abilities.use_fireball():
		w_cooldown = W_COOLDOWN_TIME
		print("[Mage] Fireball cast! Cooldown: %.1fs" % W_COOLDOWN_TIME)

func _use_skill_e():
	"""E - Fire Tornado: Summon a chasing fire tornado"""
	if e_cooldown > 0.0:
		print("[Mage] Fire Tornado on cooldown: %.1fs" % e_cooldown)
		return
	
	if mage_abilities and mage_abilities.use_fire_tornado():
		e_cooldown = E_COOLDOWN_TIME
		print("[Mage] Fire Tornado cast! Cooldown: %.1fs" % E_COOLDOWN_TIME)

func get_skill_cooldown(skill: String) -> float:
	"""Get remaining cooldown for a skill"""
	match skill:
		"Q":
			return q_cooldown
		"W":
			return w_cooldown
		"E":
			return e_cooldown
	return 0.0

func get_skill_max_cooldown(skill: String) -> float:
	"""Get max cooldown time for a skill"""
	match skill:
		"Q":
			return Q_COOLDOWN_TIME
		"W":
			return W_COOLDOWN_TIME
		"E":
			return E_COOLDOWN_TIME
	return 0.0

func _on_death():
	# Mage-specific death effect: fade out with purple particles
	if sprite:
		# Create fade out tween
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 1.5)
		
		# Spawn purple death particles
		_spawn_death_particles()

func _on_revive():
	# Reset sprite visibility when reviving
	if sprite:
		sprite.modulate.a = 1.0

func perform_basic_attack():
	# Mage ranged basic attack - shoot magic bolt at target
	var target = PlayerManager.get_target()
	if target and is_instance_valid(target) and mage_abilities:
		mage_abilities.basic_attack(target)
		return true
	return false

func _spawn_death_particles():
	# Create purple splatter particle effect
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 50
	particles.lifetime = 1.5
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 20.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0, 200)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = Color.PURPLE
	
	particles.global_position = global_position
	
	if get_parent():
		get_parent().add_child(particles)
		
		# Auto-cleanup
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(particles):
			particles.queue_free()
