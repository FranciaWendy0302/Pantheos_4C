class_name Arrow extends Node2D

@export var move_speed: float = 300
@export var fire_audio: AudioStream
@export var is_big_arrow: bool = false  # If true, this is a big/charged arrow
@export var big_arrow_damage_multiplier: float = 2.0  # Damage multiplier for big arrows
@export var big_arrow_size_scale: Vector2 = Vector2(2.0, 2.0)  # Size scale for big arrows

var move_dir: Vector2 = Vector2.RIGHT
var _player_ignore_timer: float = 0.0  # Timer to ignore player collision initially

@onready var hurt_box: HurtBox = $HurtBox
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var sprite_2d_2: Sprite2D = $Sprite2D2
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	if not is_big_arrow:
		# Normal arrows disappear on hit
		hurt_box.did_damage.connect(_on_did_damage)
	# Big arrows don't disappear on hit, only on timeout
	get_tree().create_timer(10.0).timeout.connect(_on_timeout)
	if fire_audio:
		audio_stream_player_2d.stream = fire_audio
		audio_stream_player_2d.play()
	
	# Ensure sprites are visible
	if sprite_2d:
		sprite_2d.visible = true
		sprite_2d.modulate = Color(1, 1, 1, 1)
	if sprite_2d_2:
		sprite_2d_2.visible = true
	
	# For big arrows, disable monitoring initially to avoid hitting player
	if is_big_arrow:
		hurt_box.monitoring = false
		_player_ignore_timer = 0.2  # 0.2 seconds to clear player area
	else:
		hurt_box.monitoring = true
	
	# Apply big arrow modifications
	if is_big_arrow:
		# Set metadata for piercing behavior
		set_meta("is_big_arrow", true)
		set_meta("hit_enemies", [])
		
		# Scale sprites
		if sprite_2d:
			sprite_2d.scale = big_arrow_size_scale
		if sprite_2d_2:
			sprite_2d_2.scale = big_arrow_size_scale
		
		# Scale collision shape by scaling the CollisionShape2D node
		var collision_shape = hurt_box.get_node_or_null("CollisionShape2D")
		if collision_shape:
			collision_shape.scale = big_arrow_size_scale
		
		# Increase damage
		if hurt_box:
			hurt_box.damage = int(hurt_box.damage * big_arrow_damage_multiplier)
		
		# Increase speed for big arrow
		move_speed *= 1.5
	pass
	
func _process(delta: float) -> void:
	position += move_dir * move_speed * delta
	
	# Enable monitoring after player ignore timer expires
	if is_big_arrow and not hurt_box.monitoring:
		_player_ignore_timer -= delta
		if _player_ignore_timer <= 0.0:
			hurt_box.monitoring = true
	
func fire(fire_dir: Vector2) -> void:
	move_dir = fire_dir
	rotate_nodes()
	pass
	
func rotate_nodes() -> void:
	var angle: float = move_dir.angle()
	sprite_2d.rotation = angle
	sprite_2d_2.rotation = angle
	hurt_box.rotation = angle
	pass

func _on_did_damage() -> void:
	# Only normal arrows disappear on hit
	# Big arrows pierce through enemies
	if not is_big_arrow:
		queue_free()
	pass
	
func _on_timeout() -> void:
	queue_free()
	pass
