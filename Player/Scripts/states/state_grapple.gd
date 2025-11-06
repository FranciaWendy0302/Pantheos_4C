class_name State_Grapple extends State

@onready var idle: State_Idle = $"../Idle"
@onready var grapple_hook: Node2D = %GrappleHook
@onready var nine_patch_rect: NinePatchRect = $"../../GrappleHook/NinePatchRect"
@onready var chain_audio_player: AudioStreamPlayer2D = $"../../GrappleHook/AudioStreamPlayer2D"
@onready var grapple_ray_cast_2d: RayCast2D = %GrappleRayCast2D
@onready var grapple_hurt_box: HurtBox = $"../../GrappleHook/NinePatchRect/Control/GrappleHurtBox"

@export var grapple_distance: float = 100.0
@export var grapple_speed: float = 200.0
@export var teleport_fade_duration: float = 0.15  # Duration for fade out/in

@export_group("Audio SFX")
@export var grapple_fire_audio: AudioStream
@export var grapple_stick_audio: AudioStream
@export var grapple_bounce_audio: AudioStream

var collision_distance : float
var collision_type: int = 0

var tween: Tween

var next_state: State = null

func init() -> void:
	grapple_hook.visible = false
	grapple_ray_cast_2d.enabled = false
	grapple_ray_cast_2d.target_position.y = grapple_distance
	grapple_hurt_box.monitoring = false
	# Reset player sprite modulation in case it was changed
	if player.sprite:
		player.sprite.modulate = Color.WHITE
	pass

func Enter() -> void:
	player.UpdateAnimation("idle")
	# Hide grapple hook visuals - using teleport instead
	grapple_hook.visible = false
	grapple_hurt_box.monitoring = false
	
	# Update player direction to face mouse
	var mouse_dir = player.get_direction_to_mouse()
	if mouse_dir != Vector2.ZERO:
		# Update cardinal direction based on mouse position
		if abs(mouse_dir.x) > abs(mouse_dir.y):
			player.cardinal_direction = Vector2.RIGHT if mouse_dir.x > 0 else Vector2.LEFT
		else:
			player.cardinal_direction = Vector2.DOWN if mouse_dir.y > 0 else Vector2.UP
		player.SetDirection()
	
	raycast_detection()
	teleport_player()
	
	play_audio(grapple_fire_audio)
	pass

func Exit() -> void:
	next_state = null
	grapple_hook.visible = false
	grapple_hurt_box.monitoring = false
	chain_audio_player.stop()
	if tween:
		tween.kill()
	# Ensure player sprite is visible
	if player.sprite:
		player.sprite.modulate = Color.WHITE
	pass
	
func Process(_delta: float) -> State:
	player.velocity = Vector2.ZERO
	return next_state

func Physics(_delta: float) -> State:
	return null
	
func HandleInput(_event: InputEvent) -> State:
	return null

# Removed set_grapple_position - not needed for teleport
	
func raycast_detection() -> void:
	collision_type = 0
	collision_distance = grapple_distance
	
	# Enable raycast for detection
	grapple_ray_cast_2d.enabled = true
	
	# Aim raycast at mouse position
	var mouse_pos = player.get_mouse_world_position()
	var raycast_global_pos = grapple_ray_cast_2d.global_position
	var direction_to_mouse = (mouse_pos - raycast_global_pos).normalized()
	
	# Convert world direction to local space (raycast is child of Interactions node)
	var local_direction = grapple_ray_cast_2d.to_local(raycast_global_pos + direction_to_mouse * grapple_distance)
	local_direction = local_direction.normalized() * grapple_distance
	
	# Set target position in local space
	grapple_ray_cast_2d.target_position = local_direction
	grapple_ray_cast_2d.rotation_degrees = 0  # Ensure no rotation offset
	
	# First, check for grapple posts (layer 6) - this will detect grapple posts even through walls
	grapple_ray_cast_2d.set_collision_mask_value(5, false)  # Disable walls
	grapple_ray_cast_2d.set_collision_mask_value(6, true)    # Enable grapple posts
	grapple_ray_cast_2d.force_raycast_update()
	var grapple_post_hit: bool = false
	var _grapple_post_distance: float = grapple_distance
	if grapple_ray_cast_2d.is_colliding():
		grapple_post_hit = true
		_grapple_post_distance = grapple_ray_cast_2d.get_collision_point().distance_to(player.global_position)
	
	# Now check for walls (layer 5) with grapple posts enabled to see what hits first
	grapple_ray_cast_2d.set_collision_mask_value(5, true)   # Enable walls
	grapple_ray_cast_2d.set_collision_mask_value(6, true)   # Keep grapple posts enabled
	grapple_ray_cast_2d.force_raycast_update()
	var wall_hit: bool = false
	var wall_distance: float = grapple_distance
	if grapple_ray_cast_2d.is_colliding():
		var collider = grapple_ray_cast_2d.get_collider()
		if collider:
			# Check if we hit a grapple post (layer 6) or wall (layer 5)
			# For StaticBody2D, check collision_layer. For TileMapLayer, check parent
			var collider_layer: int = 0
			if collider is StaticBody2D:
				collider_layer = collider.collision_layer
			elif collider is TileMapLayer:
				# TileMapLayer doesn't have collision_layer directly, check parent TileMap
				var tilemap = collider.get_parent()
				if tilemap is TileMap:
					# Get the physics layer that corresponds to this collision
					# For now, assume walls are on layer 5
					collider_layer = 16  # Layer 5 (walls)
			
			if collider_layer & 32:  # Layer 6 (grapple post) - 2^5 = 32
				# Grapple post detected - prioritize it even if wall is closer
				collision_type = 2
				collision_distance = grapple_ray_cast_2d.get_collision_point().distance_to(player.global_position)
				grapple_ray_cast_2d.enabled = false
				return
			elif collider_layer & 16 or collider is TileMapLayer:  # Layer 5 (wall) - 2^4 = 16
				wall_hit = true
				wall_distance = grapple_ray_cast_2d.get_collision_point().distance_to(player.global_position)
	
	# If we detected a grapple post earlier (even if wall blocks it), prioritize grapple post
	if grapple_post_hit:
		# Re-check grapple post to get the correct collision point
		grapple_ray_cast_2d.set_collision_mask_value(5, false)  # Disable walls
		grapple_ray_cast_2d.set_collision_mask_value(6, true)    # Enable grapple posts
		grapple_ray_cast_2d.force_raycast_update()
		if grapple_ray_cast_2d.is_colliding():
			collision_type = 2
			collision_distance = grapple_ray_cast_2d.get_collision_point().distance_to(player.global_position)
			grapple_ray_cast_2d.enabled = false
			return
	
	# If only wall was hit, bounce back quickly
	if wall_hit:
		collision_type = 1
		collision_distance = wall_distance
		grapple_ray_cast_2d.enabled = false
		return
	
	grapple_ray_cast_2d.enabled = false  # Disable if no collision
	pass

func play_audio(audio: AudioStream) -> void:
	player.audio.stream = audio
	player.audio.play()
	pass
	
func teleport_player() -> void:
	# Only teleport if connected to grapple post (collision_type == 2)
	if collision_type != 2:
		# No grapple post detected, just return to idle without teleporting
		if collision_type > 0:
			play_audio(grapple_bounce_audio)
		teleport_finished()
		return
	
	if tween:
		tween.kill()
	
	# Calculate target position from grapple post collision
	# Re-check grapple post without walls to get accurate position
	grapple_ray_cast_2d.enabled = true
	grapple_ray_cast_2d.set_collision_mask_value(5, false)  # Disable walls
	grapple_ray_cast_2d.set_collision_mask_value(6, true)   # Enable grapple posts
	grapple_ray_cast_2d.force_raycast_update()
	
	var target_position: Vector2 = player.global_position
	
	if grapple_ray_cast_2d.is_colliding():
		# Calculate direction to grapple collision point
		var grapple_direction = (grapple_ray_cast_2d.get_collision_point() - player.global_position).normalized()
		target_position = grapple_ray_cast_2d.get_collision_point()
		# Pull back slightly from collision point
		target_position -= grapple_direction * 10.0  # Small offset from wall
	else:
		# Shouldn't happen if collision_type == 2, but fallback just in case
		grapple_ray_cast_2d.enabled = false
		teleport_finished()
		return
	
	grapple_ray_cast_2d.enabled = false
	
	# Create teleport effect: fade out -> move -> fade in
	tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out player sprite
	if player.sprite:
		tween.tween_property(player.sprite, "modulate:a", 0.0, teleport_fade_duration)
	
	# Wait for fade out, then teleport and fade in
	tween.set_parallel(false)
	tween.tween_callback(func(): 
		# Teleport player instantly
		# Disable wall collisions (layer 5) to allow teleport through walls when grapple post is detected
		player.set_collision_mask_value(5, false)
		player.global_position = target_position
		player.set_collision_mask_value(4, false)
		player._make_invulnerable(0.3)  # Brief invulnerability after teleport
	)
	
	# Fade in player sprite
	tween.tween_property(player.sprite, "modulate:a", 1.0, teleport_fade_duration)
	
	# Play success sound
	tween.tween_callback(func(): play_audio(grapple_stick_audio))
	
	tween.tween_callback(teleport_finished)
	pass

func teleport_finished() -> void:
	# Re-enable wall collisions (layer 5)
	player.set_collision_mask_value(5, true)
	player.set_collision_mask_value(4, true)
	next_state = idle
	pass
