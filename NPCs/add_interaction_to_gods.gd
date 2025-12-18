extends Node

# Simple script to add interaction to existing god sprites
# Just adds Area2D with collision and the simple dialogue script

@export var auto_setup: bool = true
@export var interaction_radius: float = 60.0

# God sprite paths for dialogue portraits
const GOD_PORTRAITS = {
	"athena": "res://GUI/god_selection/sprites/athena.png",
	"zeus": "res://GUI/god_selection/sprites/zeus.png",
	"venus": "res://GUI/god_selection/sprites/venus.png",
	"asclepius": "res://GUI/god_selection/sprites/asclepius.png",
	"hades": "res://GUI/god_selection/sprites/hades.png",
	"ares": "res://GUI/god_selection/sprites/ares.png",
	"titan": "res://GUI/god_selection/sprites/titan.png",
	"gigantes": "res://GUI/god_selection/sprites/gigantes.png"
}

const GOD_TYPES = {
	"athena": GodManager.GodType.ATHENA,
	"zeus": GodManager.GodType.ZEUS,
	"venus": GodManager.GodType.VENUS,
	"asclepius": GodManager.GodType.ASCLEPIUS,
	"hades": GodManager.GodType.HADES,
	"ares": GodManager.GodType.ARES,
	"titan": GodManager.GodType.TITAN,
	"gigantes": GodManager.GodType.GIGANTES
}

func _ready():
	if auto_setup:
		call_deferred("setup_all_gods")

func setup_all_gods():
	"""Find all god sprites and add interaction"""
	print("[GodInteraction] Setting up god NPCs...")
	
	var sprites = _find_all_sprite2d(get_parent())
	print("[GodInteraction] Found ", sprites.size(), " Sprite2D nodes")
	
	for sprite in sprites:
		_add_interaction_to_sprite(sprite)
	
	print("[GodInteraction] Setup complete!")

func _find_all_sprite2d(node: Node) -> Array:
	"""Find all Sprite2D nodes"""
	var sprites = []
	
	if node is Sprite2D:
		sprites.append(node)
	
	for child in node.get_children():
		sprites.append_array(_find_all_sprite2d(child))
	
	return sprites

func _add_interaction_to_sprite(sprite: Sprite2D):
	"""Add interaction to a god sprite"""
	var sprite_name = sprite.name.to_lower()
	
	# Check if this is a god sprite
	var god_name = _identify_god(sprite_name)
	if god_name == "":
		return
	
	print("[GodInteraction] Setting up: ", sprite.name)
	
	var parent = sprite.get_parent()
	if not parent:
		return
	
	# Check if Area2D already exists
	var area = parent.get_node_or_null("InteractionArea")
	if area:
		print("[GodInteraction] InteractionArea already exists for ", sprite.name)
		return
	
	# Create Area2D
	area = Area2D.new()
	area.name = "InteractionArea"
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = interaction_radius
	collision.shape = shape
	area.add_child(collision)
	
	# Attach script
	var script = load("res://NPCs/simple_god_npc.gd")
	if script:
		area.set_script(script)
		area.god_type = GOD_TYPES[god_name]
		area.god_portrait_path = GOD_PORTRAITS[god_name]
	
	# Add to parent
	parent.add_child(area)
	
	print("[GodInteraction] Added interaction to ", sprite.name)

func _identify_god(sprite_name: String) -> String:
	"""Check if sprite name contains a god name"""
	sprite_name = sprite_name.to_lower()
	
	for god_name in GOD_TYPES.keys():
		if god_name in sprite_name:
			return god_name
	
	return ""
