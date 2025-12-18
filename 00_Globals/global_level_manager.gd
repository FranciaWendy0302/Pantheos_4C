extends Node

signal level_load_started
signal level_loaded
signal TileMapBoundsChanged(bounds: Array[Vector2])

var current_tilemap_bounds: Array[Vector2]
var target_transition: String
var position_offset: Vector2

func _ready() -> void:
	await get_tree().process_frame
	level_loaded.emit()

func ChangeTilemapBounds(bounds: Array[Vector2]) -> void:
	current_tilemap_bounds = bounds
	TileMapBoundsChanged.emit(bounds)


#func load_new_level(
		#level_path: String,
		#_target_transition: String,
		#_position_offset: Vector2
#) -> void:
	#
	#get_tree().paused = true
	#target_transition = _target_transition
	#position_offset = _position_offset
	#
	#await SceneTransition.fade_out()
	#
	#level_load_started.emit()
	#
	#await get_tree().process_frame
	#
	#get_tree().change_scene_to_file(level_path)
	#
	#await SceneTransition.fade_in()
	#
	#get_tree().paused = false
	#
	#await get_tree().process_frame
	#
	#level_loaded.emit()
	#
	#pass
	
func load_new_level(level_path: String, _target_transition: String, _position_offset: Vector2) -> void:
	# Notify PvPManager of map change
	var pvp_manager = get_node_or_null("/root/PvPManager")
	if pvp_manager:
		pvp_manager.set_map_type(level_path)
	
	# Validate level path
	if level_path == null or level_path.is_empty():
		push_error("LevelManager.load_new_level: Invalid level path provided")
		return
	
	if not ResourceLoader.exists(level_path):
		push_error("LevelManager.load_new_level: Level path does not exist: " + level_path)
		return
	
	get_tree().paused = true
	target_transition = _target_transition
	position_offset = _position_offset
	
	await SceneTransition.fade_out()
	level_load_started.emit()
	
	await get_tree().process_frame
	get_tree().change_scene_to_file(level_path)
	
	await get_tree().process_frame
	var new_scene = get_tree().current_scene
	PlayerManager.set_as_parent(new_scene) # reparent to active scene
	
	await SceneTransition.fade_in()
	get_tree().paused = false
	
	await get_tree().process_frame
	level_loaded.emit()
	
	# Refresh remote avatar HP bar colors (for safezone detection)
	_refresh_remote_avatar_colors()


	
	
	
	


func _refresh_remote_avatar_colors() -> void:
	"""Refresh HP bar colors for all remote avatars (called on scene change)"""
	var remote_avatars = get_tree().get_nodes_in_group("remote_avatars")
	for avatar in remote_avatars:
		if avatar.has_method("refresh_hp_bar_color"):
			avatar.refresh_hp_bar_color()
	print("[LevelManager] Refreshed HP bar colors for ", remote_avatars.size(), " remote avatars")
