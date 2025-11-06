class_name State_ChargeAttack extends State

@export var charge_duration: float = 1.0
@export var move_speed: float = 80.0
@export var sfx_charged: AudioStream
@export var sfx_spin: AudioStream

@export_group("Charge Dash")
@export var dash_speed: float = 280.0
@export var dash_duration: float = 0.25

var timer : float = 0.0
var walking: bool = false
var is_attacking: bool = false
var particles : ParticleProcessMaterial

var _dash_mode: bool = false
var _dash_timer: float = 0.0

@onready var idle: State_Idle = $"../Idle"
@onready var charge_hurt_box: HurtBox = %ChargeHurtBox
@onready var charge_spin_hurt_box: HurtBox = %ChargeSpinHurtBox
@onready var attack_hurt_box: HurtBox = %AttackHurtBox
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $"../../Audio/AudioStreamPlayer2D"
@onready var spin_effect_sprite_2d: Sprite2D = $"../../Sprite2D/SpinEffectSprite2D"
@onready var spin_animation_player: AnimationPlayer = $"../../Sprite2D/SpinEffectSprite2D/AnimationPlayer"
@onready var gpu_particles_2d: GPUParticles2D = $"../../Sprite2D/ChargeHurtBox/GPUParticles2D"

func init() -> void:
	gpu_particles_2d.emitting = false
	particles = gpu_particles_2d.process_material as ParticleProcessMaterial
	spin_effect_sprite_2d.visible = false
	pass

func _on_dash_did_damage() -> void:
	# Apply a small bounce-back to the player when we hit something during dash mode
	if _dash_mode:
		player.velocity = -player.direction * 100.0
	pass
	
func Enter() -> void:
	# Prevent Archer from using Warrior charge attack skills
	if PlayerManager.selected_class == "Archer":
		# Archer should not be in this state, go back to idle
		state_machine.ChangeState(idle)
		return
	
	timer = charge_duration
	is_attacking = false
	walking = false
	gpu_particles_2d.emitting = true
	gpu_particles_2d.amount = 4
	gpu_particles_2d.explosiveness = 0
	particles.initial_velocity_min = 10
	particles.initial_velocity_max = 30

	# If entering in dash mode (W key), set up immediate dash using charge visuals
	if _dash_mode:
		player.UpdateAnimation("charge")
		_dash_timer = dash_duration
		player.invulnerable = true
		# Enable ChargeHurtBox for damage during W charge dash
		charge_hurt_box.monitoring = true
		# Set ChargeHurtBox damage to player attack value
		var damage_value = player.attack + PlayerManager.INVENTORY_DATA.get_attack_bonus()
		charge_hurt_box.damage = damage_value
		# Disable AttackHurtBox during W dash (ChargeHurtBox handles damage)
		attack_hurt_box.monitoring = false
		# Listen for damage dealt to bounce slightly
		if not charge_hurt_box.did_damage.is_connected(_on_dash_did_damage):
			charge_hurt_box.did_damage.connect(_on_dash_did_damage)
		# Start W skill cooldown
		PlayerHud.start_charge_dash_cooldown()
		# Show skill name label
		if PlayerManager.selected_class != "Archer":
			PlayerHud.show_skill_name("W", "Charge Dash")
	else:
		# E charge mode (spin attack charge) - disable all hurtboxes during charge
		charge_hurt_box.monitoring = false
		attack_hurt_box.monitoring = false
		# Show skill name label
		if PlayerManager.selected_class != "Archer":
			PlayerHud.show_skill_name("E", "Spin Attack")
	
	# Face mouse direction when starting charge
	var mouse_dir = player.get_direction_to_mouse()
	if mouse_dir != Vector2.ZERO:
		if abs(mouse_dir.x) > abs(mouse_dir.y):
			player.cardinal_direction = Vector2.RIGHT if mouse_dir.x > 0 else Vector2.LEFT
		else:
			player.cardinal_direction = Vector2.DOWN if mouse_dir.y > 0 else Vector2.UP
		player.SetDirection()
	pass

func Exit() -> void:
	charge_hurt_box.monitoring = false
	charge_spin_hurt_box.monitoring = false
	attack_hurt_box.monitoring = false
	spin_effect_sprite_2d.visible = false
	gpu_particles_2d.emitting = false
	
	# Hide skill name labels (check before resetting _dash_mode)
	if PlayerManager.selected_class != "Archer":
		if _dash_mode:
			PlayerHud.hide_skill_name("W")
		else:
			PlayerHud.hide_skill_name("E")
	
	_dash_mode = false
	player.invulnerable = false
	pass
	
func Process(_delta: float) -> State:
	# Dash branch: move quickly for a short burst using charge visuals
	if _dash_mode:
		_dash_timer -= _delta
		player.velocity = player.direction * dash_speed
		if _dash_timer <= 0.0:
			# End dash
			player.velocity = Vector2.ZERO
			return idle
		return null

	if timer > 0:
		timer -= _delta
		if timer <= 0:
			timer =0
			charge_complete()
	if is_attacking == false:
		# Update direction toward mouse during charge
		var mouse_dir = player.get_direction_to_mouse()
		if mouse_dir != Vector2.ZERO:
			player.direction = mouse_dir
			if abs(mouse_dir.x) > abs(mouse_dir.y):
				player.cardinal_direction = Vector2.RIGHT if mouse_dir.x > 0 else Vector2.LEFT
			else:
				player.cardinal_direction = Vector2.DOWN if mouse_dir.y > 0 else Vector2.UP
			player.SetDirection()
		
		if player.direction == Vector2.ZERO:
			walking = false
			player.UpdateAnimation("charge")
		elif player.SetDirection() or walking == false:
			walking = true
			player.UpdateAnimation("charge_walk")
			pass
	player.velocity = player.direction * move_speed
	return null

func Physics(_delta: float) -> State:
	return null
	
func HandleInput(_event: InputEvent) -> State:
	# Handle attack button release (for normal charge attack)
	if _event.is_action_released("attack"):
		if timer > 0:
			return idle
		elif is_attacking == false:
			if not PlayerHud.is_spin_on_cooldown():
				charge_attack()
	
	# Handle E key release (for spin attack)
	if _event is InputEventKey:
		var key_event = _event as InputEventKey
		if key_event.keycode == KEY_E and not key_event.pressed:
			# E key released - fire spin attack if charging and not on cooldown
			if timer > 0:
				return idle
			elif is_attacking == false:
				if not PlayerHud.is_spin_on_cooldown():
					charge_attack()
	
	return null

func start_dash_mode() -> void:
	# Called externally before changing to this state to turn it into a charge dash
	_dash_mode = true
	pass

func trigger_instant_spin() -> void:
	# Deprecated - use charge_attack() directly instead
	# This function is kept for compatibility but shouldn't be used
	if not PlayerHud.is_spin_on_cooldown() and is_attacking == false:
		charge_attack()
	pass

func charge_attack() -> void:
	is_attacking = true
	# Disable charge hurtbox, enable spin hurtbox and sword collision
	charge_hurt_box.monitoring = false
	charge_spin_hurt_box.monitoring = true
	attack_hurt_box.monitoring = true
	player.animation_player.play("charge_attack")
	player.animation_player.seek(get_spin_frame())
	play_audio(sfx_spin)
	spin_effect_sprite_2d.visible = true
	spin_animation_player.play("spin")
	var _duration: float = player.animation_player.current_animation_length
	player._make_invulnerable(_duration)
	
	# Start spin attack cooldown
	PlayerHud.start_spin_cooldown()
	
	await get_tree().create_timer(_duration * 0.875).timeout
	
	# Disable all hurtboxes after spin
	attack_hurt_box.monitoring = false
	charge_spin_hurt_box.monitoring = false
	state_machine.ChangeState(idle)
	pass

func get_spin_frame() -> float:
	var interval: float = 0.05
	match player.cardinal_direction:
		Vector2.DOWN:
			return interval * 0
		Vector2.UP:
			return interval * 4
		_:
			return interval * 6

func charge_complete() -> void:
	play_audio(sfx_charged)
	gpu_particles_2d.amount = 50
	gpu_particles_2d.explosiveness = 1
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	await get_tree().create_timer(0.5).timeout
	gpu_particles_2d.amount = 10
	gpu_particles_2d.explosiveness = 0
	particles.initial_velocity_min = 10
	particles.initial_velocity_max = 30
	pass

func play_audio(_audio: AudioStream) -> void:
	audio_stream_player_2d.stream = _audio
	audio_stream_player_2d.play()
	pass
