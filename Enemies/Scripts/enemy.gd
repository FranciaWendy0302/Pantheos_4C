class_name Enemy extends CharacterBody2D

signal direction_changed(new_direction: Vector2)
signal enemy_damaged(hurt_box: HurtBox)
signal enemy_destroyed(hurt_box: HurtBox)

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

@export var hp: int = 1
@export var xp_reward: int = 1
@export var respawn_time: float = 5.0  # Time in seconds before respawning

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var player: Player
var invulnerable: bool = false
var spawn_position: Vector2
var max_hp: int = 1

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: HitBox = $HitBox
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine

func _ready():
	spawn_position = global_position
	max_hp = hp
	state_machine.initialize(self)
	player = PlayerManager.player
	hit_box.Damaged.connect(_take_damage)
	pass


func update_hp(new_hp: int, new_max_hp: int) -> void:
	"""Called by network system to update HP"""
	hp = new_hp
	max_hp = new_max_hp
	
	if hp <= 0 and is_inside_tree():
		enemy_destroyed.emit(null)


func play_death_animation() -> void:
	"""Called by network when entity dies"""
	if animation_player:
		# Play death animation if you have one
		pass
	
func _process(_delta):
	pass

func _physics_process(_delta):
	move_and_slide()
	
func set_direction(_new_direction: Vector2) -> bool:
	direction = _new_direction
	if direction == Vector2.ZERO:
		return false
		
	var direction_id: int = int(round(
			(direction + cardinal_direction * 0.1).angle()
			/ TAU * DIR_4.size()
	))
	var new_dir = DIR_4[direction_id]
	
	if new_dir == cardinal_direction:
		return false
		
	cardinal_direction = new_dir
	direction_changed.emit(new_dir)
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true	
	
func update_animation(state: String) -> void:
	animation_player.play(state + "_" + anim_direction())
	pass

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"		


func _take_damage(hurt_box: HurtBox) -> void:
	if invulnerable == true:
		return
	
	# Network: Send damage to server for validation
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		var entity_id = get_meta("entity_id", -1)
		if entity_id != -1:
			EntityManager.client_attack_entity(entity_id, hurt_box.damage)
			return  # Server will handle the damage
	
	# Local/Server damage handling
	hp -= hurt_box.damage
	PlayerManager.shake_camera()
	EffectManager.damage_text(hurt_box.damage, global_position + Vector2(0, -36))
	if hp > 0:
		enemy_damaged.emit(hurt_box)
	else:
		enemy_destroyed.emit(hurt_box)
