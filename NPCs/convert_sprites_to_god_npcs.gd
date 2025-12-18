extends Node

# Converts existing Sprite2D nodes in safezone to interactive god NPCs
# Attach this to safezone scene root
# It will find all Sprite2D nodes and add interaction to them

@export var auto_convert: bool = true
@export var interaction_range: float = 80.0

# Map sprite names to god types
# Adjust these names to match your actual Sprite2D node names
const SPRITE_TO_GOD = {
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
	if auto_convert:
		call_deferred("convert_all_sprites")

func convert_all_sprites():
	"""Find all Sprite2D nodes and convert them to god NPCs"""
	print("[GodNPCConverter] Searching for god sprites...")
	
	var sprites = _find_all_sprite2d_nodes(get_parent())
	print("[GodNPCConverter] Found ", sprites.size(), " Sprite2D nodes")
	
	for sprite in sprites:
		_convert_sprite_to_npc(sprite)
	
	print("[GodNPCConverter] Conversion complete!")

func _find_all_sprite2d_nodes(node: Node) -> Array:
	"""Recursively find all Sprite2D nodes"""
	var sprites = []
	
	if node is Sprite2D:
		sprites.append(node)
	
	for child in node.get_children():
		sprites.append_array(_find_all_sprite2d_nodes(child))
	
	return sprites

func _convert_sprite_to_npc(sprite: Sprite2D):
	"""Convert a Sprite2D to an interactive god NPC"""
	var sprite_name = sprite.name.to_lower()
	
	# Try to identify which god this is
	var god_type = _identify_god(sprite_name)
	if god_type == GodManager.GodType.NONE:
		print("[GodNPCConverter] Skipping sprite: ", sprite.name, " (not a god)")
		return
	
	print("[GodNPCConverter] Converting ", sprite.name, " to god NPC")
	
	# Get the parent (should be StaticBody2D or similar)
	var parent = sprite.get_parent()
	if not parent:
		print("[GodNPCConverter] Error: Sprite has no parent")
		return
	
	# Add InteractionArea if it doesn't exist
	var interaction_area = parent.get_node_or_null("InteractionArea")
	if not interaction_area:
		interaction_area = Area2D.new()
		interaction_area.name = "InteractionArea"
		
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = interaction_range
		collision.shape = shape
		interaction_area.add_child(collision)
		
		parent.add_child(interaction_area)
		print("[GodNPCConverter] Added InteractionArea to ", sprite.name)
	
	# Add InteractionLabel if it doesn't exist
	var interaction_label = parent.get_node_or_null("InteractionLabel")
	if not interaction_label:
		interaction_label = Label.new()
		interaction_label.name = "InteractionLabel"
		interaction_label.text = "Press G to talk"
		interaction_label.position = Vector2(-40, -80)  # Above sprite
		interaction_label.add_theme_font_size_override("font_size", 12)
		interaction_label.add_theme_color_override("font_color", Color.WHITE)
		interaction_label.add_theme_color_override("font_outline_color", Color.BLACK)
		interaction_label.add_theme_constant_override("outline_size", 2)
		interaction_label.visible = false
		parent.add_child(interaction_label)
		print("[GodNPCConverter] Added InteractionLabel to ", sprite.name)
	
	# Add name label if it doesn't exist
	var name_label = parent.get_node_or_null("NameLabel")
	if not name_label:
		var god_data = GodManager.get_god_data(god_type)
		name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = god_data.name
		name_label.position = Vector2(-30, 40)  # Below sprite
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))  # Gold
		name_label.add_theme_color_override("font_outline_color", Color.BLACK)
		name_label.add_theme_constant_override("outline_size", 2)
		parent.add_child(name_label)
		print("[GodNPCConverter] Added NameLabel to ", sprite.name)
	
	# Attach god_quest_giver script if not already attached
	if not parent.get_script():
		var script = load("res://NPCs/god_quest_giver.gd")
		if script:
			parent.set_script(script)
			# Set exported variables
			parent.god_type = god_type
			parent.god_sprite_path = sprite.texture.resource_path if sprite.texture else ""
			print("[GodNPCConverter] Attached script to ", sprite.name)
		else:
			print("[GodNPCConverter] Error: Could not load god_quest_giver.gd")
	else:
		print("[GodNPCConverter] Script already attached to ", sprite.name)

func _identify_god(sprite_name: String) -> GodManager.GodType:
	"""Identify which god this sprite represents"""
	sprite_name = sprite_name.to_lower()
	
	# Check each god name
	for god_name in SPRITE_TO_GOD.keys():
		if god_name in sprite_name:
			return SPRITE_TO_GOD[god_name]
	
	return GodManager.GodType.NONE

func manual_convert():
	"""Call this manually if auto_convert is disabled"""
	convert_all_sprites()
