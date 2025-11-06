class_name Player extends CharacterBody2D

signal DirectionChanged(new_direction: Vector2)
signal player_damaged(hurt_box: HurtBox)

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var move_target: Vector2 = Vector2.ZERO
var has_move_target: bool = false
var follow_mouse: bool = false  # Whether to continuously follow mouse

var invulnerable: bool = false
var hp: int = 6
var max_hp: int = 6

var level: int = 1
var xp: int = 0

var basic_attack_cooldown: float = 0.0
var basic_attack_cooldown_duration: float = 1.0  # 1 second gap between basic attacks

var attack: int = 1:
	set(v):
		attack = v
		update_damage_values()
		
var defense: int = 1
var defense_bonus: int = 0

var arrow_count: int = 10 : set = _set_arrow_count
var bomb_count: int = 10 : set = _set_bomb_count

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var hit_box: HitBox = $HitBox
@onready var audio: AudioStreamPlayer2D = $Audio/AudioStreamPlayer2D
@onready var lift: Node = $StateMachine/Lift
@onready var held_item: Node2D = $Sprite2D/HeldItem
@onready var carry: State_Carry = $StateMachine/Carry
@onready var player_abilities: PlayerAbilities = $Abilities
@onready var nameplate: Label = $Nameplate2D/Label


func _ready():
	PlayerManager.player = self
	state_machine.Initialize(self)
	hit_box.Damaged.connect(_take_damage)
	update_hp(99)
	update_damage_values()
	PlayerManager.player_leveled_up.connect(_on_player_leveled_up)
	PlayerManager.INVENTORY_DATA.equipment_changed.connect(_on_equipment_changed)
	_update_nameplate()
	basic_attack_cooldown = 0.0
	pass
	
	
func _process(_delta):
	# Update basic attack cooldown
	if basic_attack_cooldown > 0.0:
		basic_attack_cooldown -= _delta
		basic_attack_cooldown = max(0.0, basic_attack_cooldown)
	# Handle mouse right-click movement
	if follow_mouse:
		# Continuously update target to follow mouse
		var camera = get_viewport().get_camera_2d()
		if camera:
			move_target = camera.get_global_mouse_position()
			has_move_target = true
	
	if has_move_target:
		var distance_to_target = global_position.distance_to(move_target)
		if distance_to_target > 5.0:  # Stop within 5 pixels of target
			direction = (move_target - global_position).normalized()
		else:
			direction = Vector2.ZERO
			if not follow_mouse:
				has_move_target = false
	else:
		direction = Vector2.ZERO
	pass
	
	
func _physics_process(_delta):
	move_and_slide()

func _input(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		var mouse_event = _event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			var viewport = get_viewport()
			
			# Check if clicking on skill buttons area (bottom-right) - skip if so
			var screen_size = viewport.get_visible_rect().size
			if mouse_event.position.x > screen_size.x - 200 and mouse_event.position.y > screen_size.y - 80:
				return  # Clicking on skill buttons area, don't move
			
			if mouse_event.pressed:
				# Right mouse button pressed - start following
				follow_mouse = true
				var camera = viewport.get_camera_2d()
				if camera:
					move_target = camera.get_global_mouse_position()
					has_move_target = true
			else:
				# Right mouse button released - stop following
				follow_mouse = false
				# Keep moving to last target position, but stop following
				# has_move_target stays true until reached or S is pressed
			
			# Mark as handled to prevent UI from processing it
			_event.set_meta("handled", true)
	
	# Stop movement when S is pressed
	if _event is InputEventKey:
		var key_event = _event as InputEventKey
		if key_event.keycode == KEY_S and key_event.pressed:
			follow_mouse = false
			has_move_target = false
			move_target = global_position
			direction = Vector2.ZERO
		# Skill bindings - different for Archer class
		# Skills should work from any state, so handle them here before state machine
		if key_event.pressed:
			if PlayerManager.selected_class == "Archer":
				# Archer-specific skills
				match key_event.keycode:
					KEY_Q:
						# Invisibility - transparent, undetectable, immune for 2 seconds
						if not PlayerHud.is_dash_on_cooldown():
							var invis = $StateMachine/Invisibility as State_Invisibility
							if invis:
								state_machine.ChangeState(invis)
								PlayerHud.start_dash_cooldown()
								# Mark event as handled to prevent state machine from processing it
								_event.set_meta("handled", true)
					KEY_W:
						# Arrow barrage - fire 5 arrows in short distance
						if not PlayerHud.is_charge_dash_on_cooldown():
							var barrage = $StateMachine/ArrowBarrage as State_ArrowBarrage
							if barrage and arrow_count >= 5:
								state_machine.ChangeState(barrage)
								# Mark event as handled to prevent state machine from processing it
								_event.set_meta("handled", true)
							else:
								# Not enough arrows - could show feedback here
								pass
					KEY_E:
						# Charge big unstoppable arrow - enter bow state with charge
						if not PlayerHud.is_spin_on_cooldown() and arrow_count > 0:
							var bow = $StateMachine/Bow as State_Bow
							if bow:
								# Set flag to indicate this is E skill charge
								bow._is_e_skill_charge = true
								# Enter bow state - it will handle the charge on enter
								state_machine.ChangeState(bow)
								PlayerHud.start_spin_cooldown()
								# Mark event as handled to prevent state machine from processing it
								_event.set_meta("handled", true)
			else:
				# Default skills for other classes
				match key_event.keycode:
					KEY_Q:
						# Dash if available
						if not PlayerHud.is_dash_on_cooldown():
							state_machine.ChangeState($StateMachine/Dash)
					KEY_E:
						# Hold E to charge, release to fire spin attack
						# Enter charge state if not already charging and not on cooldown
						if not PlayerHud.is_spin_on_cooldown():
							var st = $StateMachine/ChargeAttack as State_ChargeAttack
							if st and state_machine.current_state != st:
								state_machine.ChangeState(st)
					KEY_W:
						# Charge dash: charge visuals + dash movement + invuln
						if not PlayerHud.is_charge_dash_on_cooldown():
							var ca = $StateMachine/ChargeAttack as State_ChargeAttack
							if ca:
								ca.start_dash_mode()
								state_machine.ChangeState(ca)
	pass

func SetDirection() -> bool:
	if direction == Vector2.ZERO:
		return false
		
	var direction_id: int = int(round((direction + cardinal_direction * 0.1).angle() / TAU * DIR_4.size()))
	var new_dir = DIR_4[direction_id]
		
	if new_dir == cardinal_direction:
		return false
		
	cardinal_direction = new_dir
	DirectionChanged.emit(new_dir)
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true
	
func UpdateAnimation(state: String) -> void:
	animation_player.play(state + "_" + AnimDirection())
	
	pass
	
func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"

func get_mouse_world_position() -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if camera:
		return camera.get_global_mouse_position()
	return global_position

func get_direction_to_mouse() -> Vector2:
	var mouse_pos = get_mouse_world_position()
	var dir = (mouse_pos - global_position).normalized()
	return dir

func _take_damage(hurt_box: HurtBox) -> void:
	if invulnerable == true:
		return
	if hp > 0:
		var dmg: int = hurt_box.damage
		if dmg > 0:
			dmg = clampi(dmg - defense - defense_bonus, 1, dmg)
		update_hp(-dmg)
		player_damaged.emit(hurt_box)
	pass
	
func update_hp(delta: int) -> void:
	hp = clampi(hp + delta, 0, max_hp)
	PlayerHud.update_hp(hp, max_hp)
	pass
	
func _make_invulnerable(_duration: float = 1.0) -> void:
	invulnerable = true
	hit_box.monitoring = false
	
	await get_tree().create_timer(_duration).timeout
	
	invulnerable = false
	hit_box.monitoring = true
	pass

func pickup_item(_t: Throwable) -> void:
	state_machine.ChangeState(lift)
	carry.throwable = _t
	pass
	
func revive_player() -> void:
	update_hp(99)
	state_machine.ChangeState($StateMachine/Idle)

func update_damage_values() -> void:
	var damage_value: int = attack + PlayerManager.INVENTORY_DATA.get_attack_bonus()
	%AttackHurtBox.damage = damage_value
	%ChargeSpinHurtBox.damage = damage_value * 2

func _on_player_leveled_up() -> void:
	effect_animation_player.play("level_up")
	update_hp(max_hp)
	_update_nameplate()
	pass

func _on_equipment_changed() -> void:
	update_damage_values()
	defense_bonus = PlayerManager.INVENTORY_DATA.get_defense_bonus()

func _set_arrow_count(value: int) -> void:
	arrow_count = value
	PlayerHud.update_arrow_count(value)
	pass
	
func _set_bomb_count(value: int) -> void:
	bomb_count = value
	PlayerHud.update_bomb_count(value)
	pass

func _update_nameplate() -> void:
	if nameplate:
		nameplate.text = str(PlayerManager.nickname, " Lv.", level)
	
