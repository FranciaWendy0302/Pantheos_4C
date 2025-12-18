extends Area2D
class_name FireballProjectile

@export var speed: float = 300.0
@export var damage: float = 25.0
@export var max_distance: float = 300.0  # Maximum travel distance (reduced for better control)
@export var animation_speed: float = 12.0  # frames per second

var direction: Vector2 = Vector2.RIGHT
var caster: Node2D = null
var sprite: Sprite2D = null
var animation_player: AnimationPlayer = null
var start_position: Vector2 = Vector2.ZERO
var has_exploded: bool = false
var current_frame: float = 0.0

func _ready() -> void:
	# Get references
	sprite = get_node_or_null("Sprite2D")
	animation_player = get_node_or_null("AnimationPlayer")
	
	# Disable collision briefly to avoid hitting the caster
	monitoring = false
	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(self):
		monitoring = true
		print("[Fireball] Collision enabled")

func _physics_process(delta: float) -> void:
	if has_exploded:
		return
	
	# Move in direction
	global_position += direction * speed * delta
	
	# Check distance traveled
	var distance_traveled = global_position.distance_to(start_position)
	if distance_traveled >= max_distance:
		print("[Fireball] Reached max distance: %.1f" % distance_traveled)
		_explode()
		return
	
	# Animate sprite frames
	if sprite and sprite.hframes > 1:
		current_frame += animation_speed * delta
		sprite.frame = int(current_frame) % sprite.hframes

func setup(start_pos: Vector2, fire_direction: Vector2, caster_node: Node2D) -> void:
	"""Initialize the fireball"""
	global_position = start_pos
	start_position = start_pos  # Set start position AFTER setting global position
	direction = fire_direction.normalized()
	caster = caster_node
	
	# Rotate sprite to face direction
	rotation = direction.angle()
	
	print("[Fireball] Spawned at %s, direction: %s" % [start_pos, direction])

func _on_body_entered(body: Node2D) -> void:
	"""Handle collision with enemies"""
	if has_exploded or body == caster:
		return
	
	print("[Fireball] Hit body: %s" % body.name)
	
	# Deal damage if it's an enemy
	_deal_damage_to(body)
	
	# Explode on hit
	_explode()

func _on_area_entered(area: Area2D) -> void:
	"""Handle collision with enemy hitboxes"""
	if has_exploded:
		return
	
	# Get the parent (should be the enemy)
	var parent = area.get_parent()
	if not parent or parent == caster:
		return
	
	print("[Fireball] Hit area: %s (parent: %s)" % [area.name, parent.name])
	
	# Deal damage to the parent
	_deal_damage_to(parent)
	
	# Explode on hit
	_explode()

func _deal_damage_to(target: Node2D) -> void:
	"""Deal damage to target using HurtBox system"""
	if not target or target == caster:
		return
	
	print("[Fireball] Attempting to damage: %s" % target.name)
	
	# Create a HurtBox for damage
	var hurt_box = HurtBox.new()
	hurt_box.damage = damage
	hurt_box.global_position = global_position
	
	# Try different damage methods
	if target.has_method("_take_damage"):
		print("[Fireball] Using _take_damage method")
		target._take_damage(hurt_box)
		print("[Fireball] Dealt %.0f damage to %s via _take_damage" % [damage, target.name])
	elif target.has_node("HitBox"):
		var hit_box = target.get_node("HitBox")
		if hit_box.has_method("TakeDamage"):
			print("[Fireball] Using HitBox.TakeDamage")
			hit_box.TakeDamage(hurt_box)
			print("[Fireball] Dealt %.0f damage to %s via HitBox" % [damage, target.name])
	elif target.has_method("take_damage"):
		print("[Fireball] Using take_damage method")
		target.take_damage(damage)
		print("[Fireball] Dealt %.0f damage to %s via take_damage" % [damage, target.name])
	else:
		print("[Fireball] No damage method found on %s" % target.name)
	
	hurt_box.queue_free()

func _explode() -> void:
	"""Play explosion animation from bomb.tscn"""
	if has_exploded:
		return
	
	has_exploded = true
	
	# Stop movement
	set_physics_process(false)
	
	# Disable collision
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").set_deferred("disabled", true)
	
	# Hide trail
	if has_node("Trail"):
		get_node("Trail").emitting = false
	
	# Play explosion animation
	if animation_player and animation_player.has_animation("explode"):
		animation_player.play("explode")
	else:
		# Fallback: just destroy
		queue_free()
