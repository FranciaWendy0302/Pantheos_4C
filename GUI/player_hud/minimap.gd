extends Control

@export var minimap_size: Vector2 = Vector2(120, 120)
@export var player_color: Color = Color.BLUE
@export var enemy_color: Color = Color.RED
@export var map_bounds_color: Color = Color.WHITE
@export var background_color: Color = Color(0, 0, 0, 0.5)
@export var chest_color: Color = Color.GOLD
@export var npc_color: Color = Color.CYAN
@export var shop_color: Color = Color.GREEN
@export var toggle_key: Key = KEY_M
@export var show_interactables: bool = true
@export var view_radius: float = 200.0  # World units visible around player
@export var show_map_texture: bool = false  # Option to show/hide map texture

var world_bounds: Rect2
var view_bounds: Rect2  # Current visible area around player
var world_scale: Vector2 = Vector2.ONE
var minimap_visible: bool = true
var map_texture: ImageTexture
var map_image: Image

func _ready() -> void:
	custom_minimum_size = minimap_size
	size = minimap_size
	
	# Listen for tilemap bounds changes
	LevelManager.TileMapBoundsChanged.connect(_on_tilemap_bounds_changed)
	
	# Initialize bounds if available
	if LevelManager.current_tilemap_bounds.size() >= 2:
		_on_tilemap_bounds_changed(LevelManager.current_tilemap_bounds)
	
	pass

func _on_tilemap_bounds_changed(bounds: Array[Vector2]) -> void:
	if bounds.size() < 2:
		return
	
	# Calculate world bounds from the tilemap bounds
	var min_pos = bounds[0]
	var max_pos = bounds[1]
	
	world_bounds = Rect2(min_pos, max_pos - min_pos)
	
	# Calculate actual used area from tilemaps (tighter bounds)
	var used_bounds = _calculate_actual_used_bounds()
	if used_bounds.size != Vector2.ZERO:
		# Use the tighter bounds, but add a small padding
		var padding = 32.0  # Small padding in world units
		world_bounds = Rect2(
			used_bounds.position - Vector2(padding, padding),
			used_bounds.size + Vector2(padding * 2, padding * 2)
		)
	
	# Calculate scale based on view radius (zoom level)
	# view_radius is the half-width/height of visible area
	var view_size = Vector2(view_radius * 2, view_radius * 2)
	world_scale = minimap_size / view_size
	# Keep aspect ratio
	var scale_factor = min(world_scale.x, world_scale.y)
	world_scale = Vector2(scale_factor, scale_factor)
	
	# Generate map texture only if enabled (defer to avoid blocking)
	if show_map_texture:
		call_deferred("_generate_map_texture")
	
	queue_redraw()
	pass

func _calculate_actual_used_bounds() -> Rect2:
	var scene = get_tree().current_scene
	if not scene:
		return Rect2()
	
	# Find all tilemap layers
	var tilemaps = get_tree().get_nodes_in_group("tilemaps")
	if tilemaps.is_empty():
		tilemaps = _find_tilemaps_recursive(scene)
	
	if tilemaps.is_empty():
		return world_bounds
	
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	var found_any = false
	
	# Calculate the actual bounds of used tiles
	for tilemap in tilemaps:
		if not is_instance_valid(tilemap) or not _is_tilemap_node(tilemap):
			continue
		
		var used_rect = tilemap.get_used_rect()
		if used_rect.size == Vector2i.ZERO:
			continue
		
		var tile_set = tilemap.tile_set
		if not tile_set:
			continue
		
		var tile_size = Vector2(tile_set.tile_size)
		
		# Calculate world bounds for this tilemap
		# Build the four local corners of the used rect in TileMap local space (in pixels)
		var local_min: Vector2 = Vector2(used_rect.position) * tile_size
		var local_max: Vector2 = Vector2(used_rect.end) * tile_size
		var corners: Array[Vector2] = [
			local_min,
			Vector2(local_max.x, local_min.y),
			Vector2(local_min.x, local_max.y),
			local_max
		]
		# Transform corners by the TileMap's global transform to account for rotation/scale/translation
		var tm2d := tilemap as Node2D
		for c in corners:
			var wc: Vector2 = tm2d.global_transform * c
			min_x = min(min_x, wc.x)
			min_y = min(min_y, wc.y)
			max_x = max(max_x, wc.x)
			max_y = max(max_y, wc.y)
		found_any = true
	
	if not found_any:
		return world_bounds
	
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

func _generate_map_texture() -> void:
	if world_bounds.size == Vector2.ZERO:
		return
	
	# Update view bounds first
	_update_view_bounds()
	
	# Find all tilemap layers in the scene
	var tilemaps = get_tree().get_nodes_in_group("tilemaps")
	if tilemaps.is_empty():
		# Try to find LevelTileMap instances
		var scene = get_tree().current_scene
		if scene:
			tilemaps = _find_tilemaps_recursive(scene)
	
	if tilemaps.is_empty():
		return
	
	# Create image for the minimap (only for visible area)
	var image_size = minimap_size
	map_image = Image.create(int(image_size.x), int(image_size.y), false, Image.FORMAT_RGBA8)
	map_image.fill(Color(0, 0, 0, 0))
	
	# Draw each tilemap layer (only visible area)
	var has_rotated_tilemaps: bool = false
	for tilemap in tilemaps:
		if not is_instance_valid(tilemap):
			continue
		if _is_tilemap_node(tilemap):
			# If the tilemap node is rotated/scaled, skip baking to image (Image can't rotate)
			# We'll render rotated layers via direct draw path instead
			if abs((tilemap as Node2D).global_rotation) > 0.0001 or (tilemap as Node2D).global_scale != Vector2.ONE:
				has_rotated_tilemaps = true
				continue
			_draw_tilemap_to_image(tilemap)

	# If any rotated layers exist, clear map_texture so _draw uses direct tile rendering
	if has_rotated_tilemaps:
		map_texture = null
	
	# Create texture from image
	if map_image:
		map_texture = ImageTexture.create_from_image(map_image)
	pass

func _is_tilemap_node(n: Node) -> bool:
	if not (n is Node2D):
		return false
	if not n.has_method("get_used_rect"):
		return false
	if not n.has_method("get_cell_source_id"):
		return false
	if not ("tile_set" in n):
		return false
	return n.tile_set != null

func _find_tilemaps_recursive(node: Node) -> Array:
	var tilemaps: Array = []
	if _is_tilemap_node(node):
		tilemaps.append(node)
	
	for child in node.get_children():
		tilemaps.append_array(_find_tilemaps_recursive(child))
	
	return tilemaps

func _draw_tilemap_to_image(tilemap) -> void:
	if not map_image:
		return
	
	var used_rect = tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return
	
	var tile_set = tilemap.tile_set
	if not tile_set:
		return
	
	var tile_size = tile_set.tile_size
	
	# Only draw tiles within the current view bounds
	var view_used_rect = Rect2i(
		Vector2i(
			int(floor((view_bounds.position.x - tilemap.global_position.x) / tile_size.x)),
			int(floor((view_bounds.position.y - tilemap.global_position.y) / tile_size.y))
		),
		Vector2i(
			int(ceil(view_bounds.size.x / tile_size.x)),
			int(ceil(view_bounds.size.y / tile_size.y))
		)
	)
	
	# Clamp to actual used rect
	var start_x = max(used_rect.position.x, view_used_rect.position.x - 1)
	var start_y = max(used_rect.position.y, view_used_rect.position.y - 1)
	var end_x = min(used_rect.end.x, view_used_rect.end.x + 1)
	var end_y = min(used_rect.end.y, view_used_rect.end.y + 1)
	
	# Iterate through tiles in view
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var tile_pos = Vector2i(x, y)
			var source_id = _tm_get_cell_source_id(tilemap, tile_pos)
			
			if source_id == -1:  # Invalid source
				continue
			
			var atlas_coords = _tm_get_cell_atlas_coords(tilemap, tile_pos)
			var alternative_id = _tm_get_cell_alternative_tile(tilemap, tile_pos)
			
			# Get the tile source
			var source = tile_set.get_source(source_id)
			if not source or not (source is TileSetAtlasSource):
				continue
			
			var atlas_source = source as TileSetAtlasSource
			var texture = atlas_source.texture
			if not texture:
				continue
			
			# Get the texture region for this tile (use 0 for frame, alternative_id is for tile variants)
			var texture_region: Rect2
			if atlas_source.has_tile(atlas_coords):
				# Get the base texture region for this tile
				var tile_data = atlas_source.get_tile_data(atlas_coords, alternative_id)
				if tile_data:
					texture_region = atlas_source.get_tile_texture_region(atlas_coords, 0)
				else:
					# Fallback: try to get region directly
					texture_region = atlas_source.get_tile_texture_region(atlas_coords, 0)
			else:
				continue
			
			# Calculate world position of this tile (use tile center for better alignment)
			var tile_size_vec2 = Vector2(tile_size)
			var world_tile_pos = Vector2(
				(x + 0.5) * tile_size.x, 
				(y + 0.5) * tile_size.y
			) + tilemap.global_position
			
			# Convert to minimap coordinates
			var minimap_tile_pos = world_to_minimap_view(world_tile_pos)
			var minimap_tile_size = tile_size_vec2 * world_scale
			
			# Skip if tile size is invalid or too small
			if minimap_tile_size.x <= 0 or minimap_tile_size.y <= 0:
				continue
			
			# Calculate exact pixel positions (round to avoid gaps)
			var minimap_width = max(1, int(ceil(minimap_tile_size.x)))
			var minimap_height = max(1, int(ceil(minimap_tile_size.y)))
			
			# Calculate top-left corner position (center the tile)
			var blit_pos_x = int(floor(minimap_tile_pos.x - minimap_width * 0.5))
			var blit_pos_y = int(floor(minimap_tile_pos.y - minimap_height * 0.5))
			var blit_pos = Vector2i(blit_pos_x, blit_pos_y)
			
			# Skip if outside minimap bounds
			if blit_pos.x + minimap_width < 0 or blit_pos.y + minimap_height < 0:
				continue
			if blit_pos.x > minimap_size.x or blit_pos.y > minimap_size.y:
				continue
			
			# Resize the texture region to minimap size
			var tile_image = texture.get_image()
			if tile_image:
				# Ensure texture region is within image bounds
				var image_size = tile_image.get_size()
				if texture_region.position.x < 0 or texture_region.position.y < 0:
					continue
				if texture_region.position.x + texture_region.size.x > image_size.x:
					continue
				if texture_region.position.y + texture_region.size.y > image_size.y:
					continue
				
				var tile_region_image = tile_image.get_region(texture_region)
				
				# Convert to RGBA8 format to match map_image
				if tile_region_image.get_format() != Image.FORMAT_RGBA8:
					tile_region_image.convert(Image.FORMAT_RGBA8)
				
				tile_region_image.resize(minimap_width, minimap_height, Image.INTERPOLATE_NEAREST)
				
				# Calculate blit rect with bounds checking
				var src_x = 0
				var src_y = 0
				var src_width = minimap_width
				var src_height = minimap_height
				
				# Clamp blit position to image bounds
				if blit_pos.x < 0:
					src_x = -blit_pos.x
					src_width += blit_pos.x
					blit_pos.x = 0
				if blit_pos.y < 0:
					src_y = -blit_pos.y
					src_height += blit_pos.y
					blit_pos.y = 0
				if blit_pos.x + src_width > minimap_size.x:
					src_width = minimap_size.x - blit_pos.x
				if blit_pos.y + src_height > minimap_size.y:
					src_height = minimap_size.y - blit_pos.y
				
				if src_width > 0 and src_height > 0:
					# Blit the tile image onto the map image
					map_image.blit_rect(tile_region_image, 
						Rect2i(src_x, src_y, src_width, src_height),
						blit_pos)
	pass

func _update_view_bounds() -> void:
	if not PlayerManager.player or not is_instance_valid(PlayerManager.player):
		if world_bounds.size != Vector2.ZERO:
			view_bounds = Rect2(world_bounds.position, Vector2(view_radius * 2, view_radius * 2))
		return
	
	var player_pos = PlayerManager.player.global_position
	
	# Calculate desired view bounds centered on player
	var desired_view = Rect2(
		player_pos - Vector2(view_radius, view_radius),
		Vector2(view_radius * 2, view_radius * 2)
	)
	
	# Clamp to world bounds (stop following at edges, but don't move beyond boundaries)
	view_bounds = desired_view
	if view_bounds.position.x < world_bounds.position.x:
		view_bounds.position.x = world_bounds.position.x
	if view_bounds.position.y < world_bounds.position.y:
		view_bounds.position.y = world_bounds.position.y
	if view_bounds.end.x > world_bounds.end.x:
		view_bounds.position.x = world_bounds.end.x - view_bounds.size.x
	if view_bounds.end.y > world_bounds.end.y:
		view_bounds.position.y = world_bounds.end.y - view_bounds.size.y
	
	# Ensure view_bounds doesn't exceed world bounds
	if view_bounds.position.x < world_bounds.position.x:
		view_bounds.position.x = world_bounds.position.x
	if view_bounds.position.y < world_bounds.position.y:
		view_bounds.position.y = world_bounds.position.y
	if view_bounds.size.x > world_bounds.size.x:
		view_bounds.size.x = world_bounds.size.x
	if view_bounds.size.y > world_bounds.size.y:
		view_bounds.size.y = world_bounds.size.y
	
	pass

func _draw() -> void:
	if world_bounds.size == Vector2.ZERO:
		return
	
	# Update view bounds to follow player
	_update_view_bounds()
	
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, minimap_size), background_color)
	
	# Draw map texture if enabled (only for the visible area)
	if show_map_texture and map_texture:
		# Draw only the visible area around player
		var scaled_view_size = view_bounds.size * world_scale
		var view_offset = (minimap_size - scaled_view_size) / 2.0
		
		# Draw the texture for the visible area
		var texture_rect = Rect2(view_offset, scaled_view_size)
		var modulate_color = Color(1, 1, 1, 0.3)
		draw_texture_rect(map_texture, texture_rect, false, modulate_color)
	else:
		# Draw tiles directly if texture is disabled
		_draw_tiles_directly()
	
	# Draw view bounds border
	var view_rect = Rect2(Vector2.ZERO, minimap_size)
	draw_rect(view_rect, Color.TRANSPARENT, false, 2.0)
	draw_rect(view_rect, map_bounds_color, false, 1.0)
	
	# Draw player at actual position (moves to edge when at world boundaries)
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		var player_pos = world_to_minimap_view(PlayerManager.player.global_position)
		draw_circle(player_pos, 3, player_color)
		# Draw direction indicator (small line)
		var direction = PlayerManager.player.direction
		if direction.length() > 0:
			var end_pos = player_pos + direction.normalized() * 5
			draw_line(player_pos, end_pos, player_color, 2.0)
	
	# Draw enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		# Fallback: search for Enemy class instances
		enemies = _find_enemies()
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy is Enemy and enemy.hp > 0:  # Only show alive enemies
			var enemy_pos = world_to_minimap_view(enemy.global_position)
			if _is_in_view(enemy_pos):
				draw_circle(enemy_pos, 2, enemy_color)
	
	# Draw interactables
	if show_interactables:
		_draw_interactables()
	
	pass

func world_to_minimap_view(world_pos: Vector2) -> Vector2:
	if view_bounds.size == Vector2.ZERO:
		return Vector2.ZERO
	
	# Convert world position to view-relative position
	var relative_pos = world_pos - view_bounds.position
	var minimap_pos = relative_pos * world_scale
	
	# Center in minimap (player is at center)
	var scaled_view_size = view_bounds.size * world_scale
	var view_offset = (minimap_size - scaled_view_size) / 2.0
	minimap_pos += view_offset
	
	# Clamp to minimap bounds
	minimap_pos.x = clamp(minimap_pos.x, 0, minimap_size.x)
	minimap_pos.y = clamp(minimap_pos.y, 0, minimap_size.y)
	
	return minimap_pos

func _is_in_view(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x <= minimap_size.x and pos.y <= minimap_size.y

func world_to_minimap(world_pos: Vector2) -> Vector2:
	# For backwards compatibility, use view-based conversion
	return world_to_minimap_view(world_pos)

func _find_enemies() -> Array:
	var enemies: Array = []
	var scene = get_tree().current_scene
	if not scene:
		return enemies
	
	_find_enemies_recursive(scene, enemies)
	return enemies

func _find_enemies_recursive(node: Node, enemies: Array) -> void:
	if node is Enemy:
		enemies.append(node)
	
	for child in node.get_children():
		_find_enemies_recursive(child, enemies)

# --- TileMap compatibility helpers (TileMapLayer or TileMap) ---
func _tm_get_cell_source_id(tm, pos: Vector2i) -> int:
	# TileMapLayer: get_cell_source_id(pos)
	# TileMap: get_cell_source_id(layer, pos)
	if tm is TileMapLayer:
		return tm.get_cell_source_id(pos)
	else:
		return tm.get_cell_source_id(0, pos)

func _tm_get_cell_atlas_coords(tm, pos: Vector2i) -> Vector2i:
	if tm is TileMapLayer:
		return tm.get_cell_atlas_coords(pos)
	else:
		return tm.get_cell_atlas_coords(0, pos)

func _tm_get_cell_alternative_tile(tm, pos: Vector2i) -> int:
	if tm is TileMapLayer:
		return tm.get_cell_alternative_tile(pos)
	else:
		return tm.get_cell_alternative_tile(0, pos)

func _input(event: InputEvent) -> void:
	# Handle toggle key
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed and key_event.keycode == toggle_key:
			toggle_minimap()
			get_viewport().set_input_as_handled()
	pass

func _draw_tiles_directly() -> void:
	# Find all tilemap layers in the scene
	var tilemaps = get_tree().get_nodes_in_group("tilemaps")
	if tilemaps.is_empty():
		var scene = get_tree().current_scene
		if scene:
			tilemaps = _find_tilemaps_recursive(scene)
	
	if tilemaps.is_empty():
		return
	
	# Draw each tilemap layer directly
	for tilemap in tilemaps:
		if not is_instance_valid(tilemap) or not (tilemap is TileMapLayer):
			continue
		
		var used_rect = tilemap.get_used_rect()
		if used_rect.size == Vector2i.ZERO:
			continue
		
		var tile_set = tilemap.tile_set
		if not tile_set:
			continue
		
		var tile_size = tile_set.tile_size
		
		# For rotated/scaled TileMaps, draw the entire used rect to ensure visibility
		var is_transformed: bool = abs((tilemap as Node2D).global_rotation) > 0.0001 or (tilemap as Node2D).global_scale != Vector2.ONE
		var start_x: int
		var start_y: int
		var end_x: int
		var end_y: int
		if is_transformed:
			start_x = used_rect.position.x
			start_y = used_rect.position.y
			end_x = used_rect.end.x
			end_y = used_rect.end.y
		else:
			# Only draw tiles within the current view bounds (fast path for non-rotated)
			var view_used_rect = Rect2i(
				Vector2i(
					int(floor((view_bounds.position.x - tilemap.global_position.x) / tile_size.x)),
					int(floor((view_bounds.position.y - tilemap.global_position.y) / tile_size.y))
				),
				Vector2i(
					int(ceil(view_bounds.size.x / tile_size.x)),
					int(ceil(view_bounds.size.y / tile_size.y))
				)
			)
			# Clamp to actual used rect
			start_x = max(used_rect.position.x, view_used_rect.position.x - 1)
			start_y = max(used_rect.position.y, view_used_rect.position.y - 1)
			end_x = min(used_rect.end.x, view_used_rect.end.x + 1)
			end_y = min(used_rect.end.y, view_used_rect.end.y + 1)
		
		# Iterate through tiles in view
		for y in range(start_y, end_y):
			for x in range(start_x, end_x):
				var tile_pos = Vector2i(x, y)
				var source_id = tilemap.get_cell_source_id(tile_pos)
				
				if source_id == -1:
					continue
				
				var atlas_coords = _tm_get_cell_atlas_coords(tilemap, tile_pos)
				var alternative_id = _tm_get_cell_alternative_tile(tilemap, tile_pos)
				
				var source = tile_set.get_source(source_id)
				if not source or not (source is TileSetAtlasSource):
					continue
				
				var atlas_source = source as TileSetAtlasSource
				var texture = atlas_source.texture
				if not texture:
					continue
				
				# Get texture region
				var texture_region: Rect2
				if atlas_source.has_tile(atlas_coords):
					var tile_data = atlas_source.get_tile_data(atlas_coords, alternative_id)
					if tile_data:
						texture_region = atlas_source.get_tile_texture_region(atlas_coords, 0)
					else:
						texture_region = atlas_source.get_tile_texture_region(atlas_coords, 0)
				else:
					continue
				
				# Calculate world position using the tilemap's transform (handles rotation/scale)
				var tile_size_vec2 = Vector2(tile_size)
				var local_tile_center := Vector2((x + 0.5) * tile_size.x, (y + 0.5) * tile_size.y)
				var world_tile_pos: Vector2 = (tilemap as Node2D).global_transform * local_tile_center
				
				# Convert to minimap coordinates
				var minimap_tile_pos = world_to_minimap_view(world_tile_pos)
				# Include tilemap global scale so rotated/scaled TileMaps draw with correct size
				var tm2d_local := tilemap as Node2D
				var scale_vec: Vector2 = Vector2(abs(tm2d_local.global_scale.x), abs(tm2d_local.global_scale.y))
				var minimap_tile_size = (tile_size_vec2 * scale_vec) * world_scale
				
				if minimap_tile_size.x <= 0 or minimap_tile_size.y <= 0:
					continue
				
				# Prepare rotation from the tilemap node
				var angle: float = (tilemap as Node2D).global_rotation
				
				# Draw the tile centered at origin with a temporary transform so rotation is applied
				var half_size: Vector2 = minimap_tile_size * 0.5
				var local_rect := Rect2(-half_size, minimap_tile_size)
				
				# Only draw if in view (rough check using unrotated bounds around center)
				var approx_rect := Rect2(minimap_tile_pos - half_size, minimap_tile_size)
				if approx_rect.intersects(Rect2(Vector2.ZERO, minimap_size)):
					# Apply transform, draw, then reset
					draw_set_transform(minimap_tile_pos, angle, Vector2.ONE)
					draw_texture_rect_region(
						texture,
						local_rect,
						texture_region,
						Color(1, 1, 1, 0.7)
					)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	pass

func _process(_delta: float) -> void:
	# Regenerate texture if needed (when player moves significantly)
	if show_map_texture and (not map_texture or view_bounds.size == Vector2.ZERO):
		call_deferred("_generate_map_texture")
	
	queue_redraw()
	pass

func toggle_minimap() -> void:
	minimap_visible = !minimap_visible
	visible = minimap_visible
	pass

func _draw_interactables() -> void:
	var scene = get_tree().current_scene
	if not scene:
		return
	
	# Find and draw chests
	var chests = _find_nodes_of_type(scene, "TreasureChest")
	for chest in chests:
		if not is_instance_valid(chest):
			continue
		if chest is TreasureChest and not chest.is_open:  # Only show closed chests
			var chest_pos = world_to_minimap_view(chest.global_position)
			if _is_in_view(chest_pos):
				draw_circle(chest_pos, 2, chest_color)
	
	# Find shopkeepers first (they take priority over NPCs)
	var shopkeepers = _find_nodes_of_type(scene, "Shopkeeper")
	var shopkeeper_positions: Array[Vector2] = []
	for shop in shopkeepers:
		if not is_instance_valid(shop):
			continue
		if shop is Shopkeeper:
			var shop_pos = world_to_minimap_view(shop.global_position)
			if _is_in_view(shop_pos):
				shopkeeper_positions.append(shop_pos)
				draw_circle(shop_pos, 2.5, shop_color)
	
	# Find and draw NPCs (skip those that are children of shopkeepers)
	var npcs = _find_nodes_of_type(scene, "NPC")
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		if npc is NPC:
			# Skip NPCs that are children of Shopkeepers
			var is_shopkeeper_npc: bool = false
			var parent = npc.get_parent()
			while parent:
				if parent is Shopkeeper:
					is_shopkeeper_npc = true
					break
				parent = parent.get_parent()
			
			# Only draw standalone NPCs (not part of shopkeepers)
			if not is_shopkeeper_npc:
				var npc_pos = world_to_minimap_view(npc.global_position)
				if _is_in_view(npc_pos):
					# Also check if position overlaps with shopkeeper (avoid double-drawing)
					var overlaps_shop: bool = false
					for shop_pos in shopkeeper_positions:
						if npc_pos.distance_to(shop_pos) < 3:
							overlaps_shop = true
							break
					
					if not overlaps_shop:
						draw_circle(npc_pos, 2, npc_color)
	
	pass

func _find_nodes_of_type(root: Node, target_class_name: String) -> Array:
	var results: Array = []
	_find_nodes_recursive(root, target_class_name, results)
	return results

func _find_nodes_recursive(node: Node, target_class_name: String, results: Array) -> void:
	# Check if node is instance of the target class using class name
	var script = node.get_script()
	if script != null:
		var node_class_name = script.get_global_name()
		if node_class_name == target_class_name:
			results.append(node)
	# Fallback: direct type check (for cases where get_global_name doesn't work)
	elif target_class_name == "TreasureChest" and node is TreasureChest:
		results.append(node)
	elif target_class_name == "NPC" and node is NPC:
		results.append(node)
	elif target_class_name == "Shopkeeper" and node is Shopkeeper:
		results.append(node)
	
	for child in node.get_children():
		_find_nodes_recursive(child, target_class_name, results)
