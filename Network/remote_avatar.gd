extends Node2D

const FRAME_COUNT: int = 128

var peer_id: int = -1
var hp: int = 10
var max_hp: int = 10

@onready var _label: Label = $NameLabel
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _weapon_below: Sprite2D = $Sprite2D/Sprite2D_Weapon_Below
@onready var _weapon_above: Sprite2D = $Sprite2D/Sprite2D_Weapon_Above
@onready var _hit_box: HitBox = $HitBox

func _ready() -> void:
	if _hit_box:
		_hit_box.Damaged.connect(_on_damaged)
	pass

func set_nickname(nickname: String) -> void:
	if _label:
		_label.text = nickname
	pass

func set_direction(_dir: Vector2) -> void:
	# Direction is handled by sprite_data scale_x
	pass

func _on_damaged(hurt_box: HurtBox) -> void:
	# Only process damage in duel mode
	if NetworkManager._mode != "duel":
		return
	
	# Send damage to the network
	var damage: int = hurt_box.damage
	NetworkManager._report_remote_avatar_damage.rpc_id(1, peer_id, damage)
	
	# Visual feedback - flash red
	_flash_damage()
	pass

func _flash_damage() -> void:
	if _sprite:
		_sprite.modulate = Color(1, 0.3, 0.3, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(_sprite):
			_sprite.modulate = Color(1, 1, 1, 1)
	pass

func update_hp(new_hp: int, new_max_hp: int) -> void:
	hp = new_hp
	max_hp = new_max_hp
	# Could add a health bar here later
	pass

func set_sprite_data(sprite_data: Dictionary) -> void:
	if not _sprite or sprite_data.is_empty():
		return
	
	# Load texture if provided (only once)
	if sprite_data.has("texture") and sprite_data["texture"] != "":
		if not _sprite.texture or _sprite.texture.resource_path != sprite_data["texture"]:
			var texture = load(sprite_data["texture"])
			if texture:
				_sprite.texture = texture
	
	# Set sprite sheet properties (only once or when changed)
	if sprite_data.has("hframes") and _sprite.hframes != sprite_data["hframes"]:
		_sprite.hframes = sprite_data["hframes"]
	if sprite_data.has("vframes") and _sprite.vframes != sprite_data["vframes"]:
		_sprite.vframes = sprite_data["vframes"]
	
	# Update frame every time (for animation)
	if sprite_data.has("frame"):
		_sprite.frame = sprite_data["frame"]
		# Update weapon frames to match player sprite
		if _weapon_below:
			_weapon_below.frame = sprite_data["frame"]
		if _weapon_above:
			_weapon_above.frame = sprite_data["frame"] + FRAME_COUNT
	
	# Update scale.x for facing direction (not flip_h)
	if sprite_data.has("scale_x"):
		_sprite.scale.x = sprite_data["scale_x"]
	
	# Load weapon texture if provided
	if sprite_data.has("weapon_texture") and sprite_data["weapon_texture"] != "":
		if _weapon_below and (not _weapon_below.texture or _weapon_below.texture.resource_path != sprite_data["weapon_texture"]):
			var weapon_texture = load(sprite_data["weapon_texture"])
			if weapon_texture:
				_weapon_below.texture = weapon_texture
				if _weapon_above:
					_weapon_above.texture = weapon_texture
	pass
