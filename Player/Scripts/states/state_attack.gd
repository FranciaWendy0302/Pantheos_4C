class_name State_Attack extends State

var attacking: bool = false
var animation_connected: bool = false  # Track if signal is connected

@export var attack_sound: AudioStream
@export_range(1,20,0.5) var decelerate_speed: float = 5.0

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var attack_anim: AnimationPlayer = $"../../Sprite2D/AttackEffectSprite/AnimationPlayer"
@onready var audio: AudioStreamPlayer2D = $"../../Audio/AudioStreamPlayer2D"

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var charge_attack: State = $"../ChargeAttack"
@onready var hurt_box: HurtBox = %AttackHurtBox

	
func Enter() -> void:
	# Check if we have a valid target and are in range
	var target = PlayerManager.get_target()
	if not target or not is_instance_valid(target):
		# No target - cancel attack and return to idle
		attacking = false
		animation_connected = false
		return
	
	# Check if target is in range
	var distance = player.global_position.distance_to(target.global_position)
	if distance > player.attack_range:
		# Too far - cancel attack
		attacking = false
		animation_connected = false
		return
	
	# Valid target and in range - proceed with attack
	player.UpdateAnimation("attack")
	attack_anim.play("attack_" + player.AnimDirection())
	animation_player.animation_finished.connect(EndAttack)
	animation_connected = true  # Mark signal as connected
	
	audio.stream = attack_sound
	audio.pitch_scale = randf_range(0.9, 1.1)
	audio.play()
	
	attacking = true
	
	# Send attack event to server for multiplayer sync
	_send_attack_to_server()
	
	# TAB-TARGET: Apply direct damage to target after attack animation starts
	await get_tree().create_timer(0.2).timeout  # Wait for attack animation hit frame
	if attacking and is_instance_valid(target):
		_apply_direct_damage_to_target(target)
	pass

func Exit() -> void:
	# Only disconnect if we actually connected the signal
	if animation_connected:
		animation_player.animation_finished.disconnect(EndAttack)
		animation_connected = false
	attacking = false
	hurt_box.monitoring = false
	pass
	
func Process(_delta: float) -> State:
	player.velocity -= player.velocity * decelerate_speed * _delta
	
	if attacking == false:
		if player.direction == Vector2.ZERO:
			return idle
		else: 
			return walk
	return null

func Physics(_delta: float) -> State:
	return null
	
func HandleInput(_event: InputEvent) -> State:
	return null

func EndAttack(_newAnimName: String) -> void:
	attacking = false

func _apply_direct_damage_to_target(target: Node2D) -> void:
	"""TAB-TARGET: Apply damage directly to the targeted enemy"""
	if not target or not is_instance_valid(target):
		return
	
	# Check if target is still in range
	var distance = player.global_position.distance_to(target.global_position)
	if distance > player.attack_range + 20:  # Add 20 pixel buffer
		print("[Attack] Target moved out of range, attack missed")
		return
	
	# Calculate damage
	var damage = player.attack + PlayerManager.INVENTORY_DATA.get_attack_bonus()
	
	# Apply damage to target
	if target.has_method("_take_damage"):
		# Create a fake HurtBox for compatibility with existing damage system
		var fake_hurt_box = HurtBox.new()
		fake_hurt_box.damage = damage
		target._take_damage(fake_hurt_box)
		fake_hurt_box.queue_free()
		
		print("[Attack] Direct hit! Dealt ", damage, " damage to target")
	else:
		print("[Attack] Target doesn't have _take_damage method")

func _send_attack_to_server() -> void:
	"""Send attack event to server for multiplayer synchronization"""
	if not NetworkManager._websocket:
		return
	
	if NetworkManager._websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	
	# Get attack direction and position
	var attack_direction = player.cardinal_direction
	var attack_position = player.global_position
	
	NetworkManager.send_websocket_message({
		"type": "attack",
		"data": {
			"attack_type": "basic",
			"direction": {
				"x": attack_direction.x,
				"y": attack_direction.y
			},
			"position": {
				"x": attack_position.x,
				"y": attack_position.y
			}
		}
	})
