# God Sprite Loader
# Helper script to load god sprites
# This will be integrated into god_selection_panel.gd once sprites are added

extends Node

const SPRITE_PATH = "res://GUI/god_selection/sprites/"

# Map god IDs to sprite filenames
const GOD_SPRITES = {
	1: "athena.png",      # Athena
	2: "zeus.png",        # Zeus
	3: "venus.png",       # Venus
	4: "asclepius.png",   # Asclepius
	5: "hades.png",       # Hades
	6: "ares.png",        # Ares
	7: "titan.png",       # Titan
	8: "gigantes.png"     # Gigantes
}

static func load_god_sprite(god_id: int) -> Texture2D:
	"""Load sprite for a specific god"""
	if not GOD_SPRITES.has(god_id):
		push_error("[GodSpriteLoader] Invalid god_id: " + str(god_id))
		return null
	
	var sprite_file = GOD_SPRITES[god_id]
	var sprite_path = SPRITE_PATH + sprite_file
	
	if ResourceLoader.exists(sprite_path):
		var texture = load(sprite_path) as Texture2D
		if texture:
			return texture
		else:
			push_error("[GodSpriteLoader] Failed to load texture: " + sprite_path)
	else:
		push_warning("[GodSpriteLoader] Sprite not found: " + sprite_path)
	
	return null

static func has_sprite(god_id: int) -> bool:
	"""Check if a god has a sprite available"""
	if not GOD_SPRITES.has(god_id):
		return false
	
	var sprite_file = GOD_SPRITES[god_id]
	var sprite_path = SPRITE_PATH + sprite_file
	return ResourceLoader.exists(sprite_path)

static func get_all_available_sprites() -> Dictionary:
	"""Get all available god sprites"""
	var available = {}
	for god_id in GOD_SPRITES.keys():
		if has_sprite(god_id):
			available[god_id] = load_god_sprite(god_id)
	return available
