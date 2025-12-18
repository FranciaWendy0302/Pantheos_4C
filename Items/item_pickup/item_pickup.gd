@tool
class_name ItemPickup extends CharacterBody2D

signal picked_up

@export var item_data: ItemData: set = _set_item_data
@export var item_count: int = 1: set = _set_item_count
@export var fade_out_duration: float = 1.0  # Time before auto-collecting
@export var auto_collect: bool = false  # If true, fade out and auto-collect

@onready var area_2d: Area2D = $Area2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var count_label: Label = %CountLabel

var _fade_timer: float = 0.0
var _is_fading: bool = false
var _original_modulate: Color = Color.WHITE


func _ready() -> void:
	_update_texture()
	_update_count_label() 
	if Engine.is_editor_hint():
		return
	
	# Store original modulate color
	_original_modulate = sprite_2d.modulate if sprite_2d else Color.WHITE
	
	# If auto-collect is enabled (dropped from enemy), start fade-out
	if auto_collect:
		# Disable player collection (Area2D)
		area_2d.monitoring = false
		if area_2d.body_entered.is_connected(_on_body_entered):
			area_2d.body_entered.disconnect(_on_body_entered)
		_is_fading = true
		_fade_timer = fade_out_duration
	else:
		# Enable player collection (Area2D)
		area_2d.collision_mask = 4
		area_2d.body_entered.connect(_on_body_entered)
	
func _physics_process(delta: float) -> void:
	# Handle auto-collect fade-out
	if _is_fading:
		_fade_timer -= delta
		if _fade_timer > 0:
			# Fade out the sprite
			var fade_alpha = _fade_timer / fade_out_duration
			if sprite_2d:
				sprite_2d.modulate = Color(_original_modulate.r, _original_modulate.g, _original_modulate.b, fade_alpha)
			if count_label:
				count_label.modulate = Color(1, 1, 1, fade_alpha)
		else:
			# Fade complete - auto-collect to inventory
			_auto_collect_to_inventory()
		return
	
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal())
	velocity -= velocity * delta * 4

func _on_body_entered(b) -> void:
	if b is Player:
		item_pick_up()
	pass
	
func item_pick_up() -> void:
	if _is_fading:
		return  # Already fading/collecting
	
	if area_2d.body_entered.is_connected(_on_body_entered):
		area_2d.body_entered.disconnect(_on_body_entered)
	_add_to_inventory()
	audio_stream_player_2d.play()
	visible = false
	picked_up.emit()
	await audio_stream_player_2d.finished
	queue_free()
	pass

func _auto_collect_to_inventory() -> void:
	# Add to inventory silently (no sound yet, sound will play when item is actually added)
	_add_to_inventory()
	# Play pickup sound
	audio_stream_player_2d.play()
	await audio_stream_player_2d.finished
	picked_up.emit()
	queue_free()
	pass

func _add_to_inventory() -> void:
	if item_data:
		if item_data.name == "Bomb":
			PlayerManager.player.bomb_count += item_count
		elif item_data.name == "Arrow":
			PlayerManager.player.arrow_count += item_count
		else:
			PlayerManager.INVENTORY_DATA.add_item(item_data, item_count)
	pass	

func _set_item_data(value: ItemData) -> void:
	item_data = value
	_update_texture()
	pass
	
func _update_texture() -> void:
	if item_data and sprite_2d:
		sprite_2d.texture = item_data.texture
	pass

func _set_item_count(value: int) -> void:
	item_count = value
	_update_count_label()
	pass

func _update_count_label() -> void:
	if item_data and count_label:
		count_label.text = ""
		if item_count > 1:
			count_label.text = str(item_count)
	pass
