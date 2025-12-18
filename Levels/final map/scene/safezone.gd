extends Node2D

## Safezone level script with manual camera limits

func _ready() -> void:
	self.y_sort_enabled = true
	PlayerManager.set_as_parent(self)
	LevelManager.level_load_started.connect(_free_level)
	
	# Set large camera limits for the safezone (covers the entire map)
	_set_camera_limits()

func _set_camera_limits() -> void:
	# Find all TileMapLayers and get the combined bounds
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	var found_tilemap: bool = false
	
	for child in get_children():
		if child is TileMapLayer:
			var tilemap: TileMapLayer = child
			
			# Skip if no tileset assigned
			if tilemap.tile_set == null:
				print("[Safezone] TileMap '%s' has no tileset, skipping" % child.name)
				continue
			
			found_tilemap = true
			var used_rect: Rect2i = tilemap.get_used_rect()
			var tile_size: Vector2i = tilemap.tile_set.tile_size
			
			# Calculate world bounds for this tilemap
			var tl: Vector2 = Vector2(used_rect.position) * Vector2(tile_size)
			var br: Vector2 = Vector2(used_rect.end) * Vector2(tile_size)
			
			# Update min/max
			min_x = min(min_x, tl.x)
			min_y = min(min_y, tl.y)
			max_x = max(max_x, br.x)
			max_y = max(max_y, br.y)
			
			print("[Safezone] TileMap '%s' bounds: %s to %s" % [child.name, tl, br])
	
	if not found_tilemap:
		print("[Safezone] No TileMapLayer found!")
		return
	
	var map_top_left: Vector2 = Vector2(min_x, min_y)
	var map_bottom_right: Vector2 = Vector2(max_x, max_y)
	
	# Get viewport size for padding calculation
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var half_viewport: Vector2 = viewport_size / 2.0
	
	# Add padding so camera stops when map edge reaches screen edge
	var top_left: Vector2 = map_top_left + half_viewport
	var bottom_right: Vector2 = map_bottom_right - half_viewport
	
	# Set the bounds via LevelManager
	LevelManager.current_tilemap_bounds = [top_left, bottom_right]
	LevelManager.TileMapBoundsChanged.emit(LevelManager.current_tilemap_bounds)
	
	print("[Safezone] Combined map bounds: ", map_top_left, " to ", map_bottom_right)
	print("[Safezone] Camera limits (with padding): ", top_left, " to ", bottom_right)
	print("[Safezone] Viewport size: ", viewport_size)

func _free_level() -> void:
	PlayerManager.unparent_player(self)
	queue_free()
