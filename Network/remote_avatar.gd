extends Node2D

@onready var _label: Label = $NameLabel
@onready var _sprite: Sprite2D = $Sprite2D

func set_nickname(nickname: String) -> void:
	if _label:
		_label.text = nickname
	pass

func set_direction(_dir: Vector2) -> void:
	# Direction is handled by sprite_data flip_h
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
	
	# Update frame and flip every time (for animation)
	if sprite_data.has("frame"):
		_sprite.frame = sprite_data["frame"]
	if sprite_data.has("flip_h"):
		_sprite.flip_h = sprite_data["flip_h"]
	pass
