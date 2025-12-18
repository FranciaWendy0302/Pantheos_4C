extends Node

# Helper script to spawn all 8 god NPCs in safezone
# Attach this to safezone scene and it will create all god NPCs automatically

@export var spawn_center: Vector2 = Vector2(500, 400)  # Center point for god circle
@export var circle_radius: float = 200.0  # Radius of god circle
@export var auto_spawn: bool = true  # Auto-spawn on ready

# God data with sprite paths
const GOD_DATA = [
	{
		"type": 1,  # GodManager.GodType.ATHENA
		"name": "Athena",
		"sprite": "res://GUI/god_selection/sprites/athena.png",
		"angle": 0  # Top
	},
	{
		"type": 2,  # GodManager.GodType.ZEUS
		"name": "Zeus",
		"sprite": "res://GUI/god_selection/sprites/zeus.png",
		"angle": 45  # Top-right
	},
	{
		"type": 4,  # GodManager.GodType.ASCLEPIUS
		"name": "Asclepius",
		"sprite": "res://GUI/god_selection/sprites/asclepius.png",
		"angle": 90  # Right
	},
	{
		"type": 6,  # GodManager.GodType.ARES
		"name": "Ares",
		"sprite": "res://GUI/god_selection/sprites/ares.png",
		"angle": 135  # Bottom-right
	},
	{
		"type": 8,  # GodManager.GodType.GIGANTES
		"name": "Gigantes",
		"sprite": "res://GUI/god_selection/sprites/gigantes.png",
		"angle": 180  # Bottom
	},
	{
		"type": 7,  # GodManager.GodType.TITAN
		"name": "Titan",
		"sprite": "res://GUI/god_selection/sprites/titan.png",
		"angle": 225  # Bottom-left
	},
	{
		"type": 5,  # GodManager.GodType.HADES
		"name": "Hades",
		"sprite": "res://GUI/god_selection/sprites/hades.png",
		"angle": 270  # Left
	},
	{
		"type": 3,  # GodManager.GodType.VENUS
		"name": "Venus",
		"sprite": "res://GUI/god_selection/sprites/venus.png",
		"angle": 315  # Top-left
	}
]

func _ready():
	if auto_spawn:
		call_deferred("spawn_all_gods")

func spawn_all_gods():
	"""Spawn all 8 god NPCs in a circle"""
	print("[GodNPCSpawner] Spawning all god NPCs...")
	
	for god_data in GOD_DATA:
		_spawn_god_npc(god_data)
	
	print("[GodNPCSpawner] All god NPCs spawned!")

func _spawn_god_npc(god_data: Dictionary):
	"""Spawn a single god NPC"""
	# Calculate position in circle
	var angle_rad = deg_to_rad(god_data.angle)
	var offset = Vector2(
		cos(angle_rad) * circle_radius,
		sin(angle_rad) * circle_radius
	)
	var position = spawn_center + offset
	
	# Create StaticBody2D
	var npc = StaticBody2D.new()
	npc.name = god_data.name + "QuestGiver"
	npc.position = position
	
	# Add Sprite2D
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	
	# Load sprite texture
	if ResourceLoader.exists(god_data.sprite):
		sprite.texture = load(god_data.sprite)
		sprite.scale = Vector2(2.0, 2.0)
	else:
		print("[GodNPCSpawner] Sprite not found: ", god_data.sprite)
	
	npc.add_child(sprite)
	
	# Add CollisionShape2D for body
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 60)  # Adjust based on sprite size
	collision.shape = shape
	npc.add_child(collision)
	
	# Add InteractionArea
	var interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	
	var interaction_collision = CollisionShape2D.new()
	var interaction_shape = CircleShape2D.new()
	interaction_shape.radius = 80.0  # Interaction range
	interaction_collision.shape = interaction_shape
	interaction_area.add_child(interaction_collision)
	
	npc.add_child(interaction_area)
	
	# Add InteractionLabel
	var label = Label.new()
	label.name = "InteractionLabel"
	label.text = "Press G to talk"
	label.position = Vector2(-40, -80)  # Above sprite
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.visible = false
	npc.add_child(label)
	
	# Add name label (always visible)
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = god_data.name
	name_label.position = Vector2(-30, 40)  # Below sprite
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))  # Gold
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 2)
	npc.add_child(name_label)
	
	# Attach script
	var script = load("res://NPCs/god_quest_giver.gd")
	if script:
		npc.set_script(script)
		# Set exported variables
		npc.god_type = god_data.type
		npc.god_sprite_path = god_data.sprite
	else:
		print("[GodNPCSpawner] Script not found: NPCs/god_quest_giver.gd")
	
	# Add to scene
	add_child(npc)
	
	print("[GodNPCSpawner] Spawned: ", god_data.name, " at ", position)

func clear_all_gods():
	"""Remove all spawned god NPCs"""
	for child in get_children():
		if child.name.ends_with("QuestGiver"):
			child.queue_free()
	print("[GodNPCSpawner] All god NPCs removed")
