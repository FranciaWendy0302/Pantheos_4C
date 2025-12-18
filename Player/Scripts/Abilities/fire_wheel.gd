extends Area2D
class_name FireWheel

@export var speed: float = 400.0
@export var max_distance: float = 500.0
@export var damage: float = 35.0
@export var pierce_count: int = 2  # Can hit 2 enemies before disappearing

var direction: Vector2 = Vector2.RIGHT
var caster: Node2D = null
var start_position: Vector2 = Vector2.ZERO
var enemies_hit: Array = []
var hit_count: int = 0

func _ready() -> void:
	# Setup collision to detect enemies
	collision_layer = 0
	collision_mask = 271  # Detects enemies
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Start spinning animation
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation("spin"):
		anim_player.play("spin")
	
	print("[FireWheel] Spawned - Speed: %.1f" % speed)

func setup(spawn_pos: Vector2, fire_direction: Vector2, caster_node: Node2D) -> void:
	"""Initialize the fire wheel projectile"""
	global_position = spawn_pos
	start_position = spawn_pos
	direction = fire_direction.normalized()
	caster = caster_node
	
	# Rotate sprite to face direction
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	# Move forward
	global_position += direction * speed * delta
	
	# Check if traveled max distance
	var distance_traveled = global_position.distance_to(start_position)
	if distance_traveled >= max_distance:
		print("[FireWheel] Max distance reached - destroying")
		queue_free()
		return
	
	# Check if hit enough enemies
	if hit_count >= pierce_count:
		print("[FireWheel] Pierce limit reached - destroying")
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	"""Handle collision with enemies"""
	if body == caster:
		return
	
	# Don't hit the same enemy twice
	if enemies_hit.has(body):
		return
	
	# Deal damage
	_deal_damage_to(body)
	enemies_hit.append(body)
	hit_count += 1
	
	print("[FireWheel] Hit enemy %d/%d: %s" % [hit_count, pierce_count, body.name])

func _on_area_entered(area: Area2D) -> void:
	"""Handle collision with enemy areas"""
	var parent = area.get_parent()
	if parent and parent != caster:
		if not enemies_hit.has(parent):
			_deal_damage_to(parent)
			enemies_hit.append(parent)
			hit_count += 1
			print("[FireWheel] Hit enemy area %d/%d: %s" % [hit_count, pierce_count, parent.name])

func _deal_damage_to(target: Node2D) -> void:
	"""Deal damage to an enemy"""
	if not target or target == caster:
		return
	
	var hurt_box = HurtBox.new()
	hurt_box.damage = damage
	hurt_box.global_position = global_position
	
	if target.has_method("_take_damage"):
		target._take_damage(hurt_box)
		print("[FireWheel] Dealt %.1f damage to %s" % [damage, target.name])
	elif target.has_node("HitBox"):
		var hit_box = target.get_node("HitBox")
		if hit_box.has_method("TakeDamage"):
			hit_box.TakeDamage(hurt_box)
			print("[FireWheel] Dealt %.1f damage to %s" % [damage, target.name])
	
	hurt_box.queue_free()
