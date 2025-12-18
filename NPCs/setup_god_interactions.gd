extends Node

# Script to add interaction areas to existing god sprites in safezone
# Run this once in the editor to setup all god NPCs

const GOD_SPRITE_NAMES = {
	"Athena": GodManager.GodType.ATHENA,
	"Zeus": GodManager.GodType.ZEUS,
	"Venus": GodManager.GodType.VENUS,
	"Asclepius": GodManager.GodType.ASCLEPIUS,
	"Hades": GodManager.GodType.HADES,
	"Ares": GodManager.GodType.ARES,
	"Thanatos": GodManager.GodType.THANATOS,
	"Nemesis": GodManager.GodType.NEMESIS
}

const GOD_PORTRAIT_PATHS = {
	"Athena": "res://GUI/god_selection/sprites/athena.png",
	"Zeus": "res://GUI/god_selection/sprites/zeus.png",
	"Venus": "res://GUI/god_selection/sprites/venus.png",
	"Asclepius": "res://GUI/god_selection/sprites/asclepius.png",
	"Hades": "res://GUI/god_selection/sprites/hades.png",
	"Ares": "res://GUI/god_selection/sprites/Ares.png",
	"Thanatos": "res://GUI/god_selection/sprites/titan.png",
	"Nemesis": "res://GUI/god_selection/sprites/gigantes.png"
}

func setup_god_interactions(root_node: Node):
	"""Add interaction areas to all god sprites"""
	print("[SetupGodInteractions] Starting setup...")
	
	for god_name in GOD_SPRITE_NAMES.keys():
		var sprite = root_node.get_node_or_null(god_name)
		if sprite and sprite is Sprite2D:
			_add_interaction_to_sprite(sprite, god_name)
		else:
			print("[SetupGodInteractions] Warning: Could not find sprite for ", god_name)
	
	print("[SetupGodInteractions] Setup complete!")

func _add_interaction_to_sprite(sprite: Sprite2D, god_name: String):
	"""Add interaction area and script to a god sprite"""
	
	# Check if already has interaction area
	if sprite.has_node("InteractionArea"):
		print("[SetupGodInteractions] ", god_name, " already has interaction area")
		return
	
	# Create Area2D for interaction
	var area = Area2D.new()
	area.name = "InteractionArea"
	
	# Create collision shape
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 50.0  # Interaction radius
	collision.shape = shape
	
	# Add collision to area
	area.add_child(collision)
	collision.owner = sprite.get_tree().edited_scene_root
	
	# Add area to sprite
	sprite.add_child(area)
	area.owner = sprite.get_tree().edited_scene_root
	
	# Attach the god quest giver script
	var script = load("res://NPCs/god_quest_giver.gd")
	sprite.set_script(script)
	
	# Set god type
	sprite.set("god_type", GOD_SPRITE_NAMES[god_name])
	sprite.set("god_sprite_path", GOD_PORTRAIT_PATHS[god_name])
	
	# Create interaction label
	var label = Label.new()
	label.name = "InteractionLabel"
	label.text = "Press G to talk"
	label.position = Vector2(-50, -80)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.visible = false
	
	sprite.add_child(label)
	label.owner = sprite.get_tree().edited_scene_root
	
	print("[SetupGodInteractions] Added interaction to ", god_name)
