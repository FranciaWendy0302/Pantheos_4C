@tool
class_name TreasureChest extends Node2D

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export_category("Loot")
@export var item_data: ItemData: set = _set_item_data
@export var quantity: int = 1 : set = _set_quantity
@export var loot_table: Array[ItemData] = []
@export var min_items: int = 1
@export var max_items: int = 3
@export var gem_min: int = 10
@export var gem_max: int = 50

@export_category("Rarity")
@export var rarity: Rarity = Rarity.COMMON: set = _set_rarity
@export var use_rarity_system: bool = false

var is_open: bool = false
var glow_light: PointLight2D = null
var particles: GPUParticles2D = null

@onready var sprite: Sprite2D = $ItemSprite
@onready var label: Label = $ItemSprite/Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interact_area: Area2D = $Area2D
@onready var is_open_data: PersistentDataHandler = $IsOpen


func _ready() -> void:
	_update_texture()
	_update_label()
	
	# Setup rarity effects
	if use_rarity_system:
		_create_rarity_effects()
		_setup_rarity()
	
	if Engine.is_editor_hint():
		return
	
	interact_area.area_entered.connect(_on_area_enter)
	interact_area.area_exited.connect(_on_area_exit)
	is_open_data.data_loaded.connect(set_chest_state)
	set_chest_state()
	pass

func set_chest_state() -> void:
	is_open = is_open_data.value
	if is_open:
		animation_player.play("openned")
	else:
		animation_player.play("closed")
	

func player_interact() -> void:
	if is_open == true:
		return
	is_open = true
	is_open_data.set_value()
	animation_player.play("open_chest")
	
	# Stop glow effects
	if glow_light:
		var tween = create_tween()
		tween.tween_property(glow_light, "energy", 0.0, 0.5)
	if particles:
		particles.emitting = false
	
	# Wait for chest to open animation
	await get_tree().create_timer(0.2).timeout
	
	# Use rarity system or single item
	if use_rarity_system:
		_spawn_loot_burst()
	else:
		if item_data and quantity > 0:
			_spawn_single_item_burst(item_data, quantity)
		else:
			printerr("No Items in Chest!")
			push_error("No Items in Chest! Chest Name: ", name)
	
	# Vanish chest after 20 seconds
	await get_tree().create_timer(20.0).timeout
	_vanish_chest()
	pass

func _vanish_chest() -> void:
	"""Make the chest fade out and disappear"""
	# Fade out animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
	# Wait for fade to complete
	await tween.finished
	
	# Remove from scene
	queue_free()

func _on_area_enter(_a: Area2D) -> void:
	PlayerManager.interact_pressed.connect(player_interact)
	pass
	
func _on_area_exit(_a: Area2D) -> void:
	PlayerManager.interact_pressed.disconnect(player_interact)
	pass
func _set_item_data(value: ItemData) -> void:
	item_data = value
	_update_texture()
	pass
	
func _set_quantity(value: int) -> void:
	quantity = value
	_update_label()
	pass

func _update_texture() -> void:
	if item_data and sprite:
		sprite.texture = item_data.texture
		
func _update_label() -> void:
	if label:
		if quantity <= 1:
			label.text = ""
		else:
			label.text = "x" + str(quantity)

func _set_rarity(value: Rarity) -> void:
	rarity = value
	if is_node_ready() and use_rarity_system:
		_setup_rarity()

func _create_rarity_effects() -> void:
	"""Create glow light and particles for rarity effects"""
	# Create glow light
	if not glow_light:
		glow_light = PointLight2D.new()
		glow_light.name = "GlowLight"
		glow_light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		glow_light.texture_scale = 2.0
		add_child(glow_light)
	
	# Create particles
	if not particles:
		particles = GPUParticles2D.new()
		particles.name = "RarityParticles"
		particles.amount = 16
		particles.lifetime = 2.0
		particles.preprocess = 1.0
		
		# Create particle material
		var particle_mat = ParticleProcessMaterial.new()
		particle_mat.particle_flag_disable_z = true
		particle_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		particle_mat.emission_sphere_radius = 16.0
		particle_mat.direction = Vector3(0, -1, 0)
		particle_mat.spread = 45.0
		particle_mat.gravity = Vector3(0, -20, 0)
		particle_mat.initial_velocity_min = 10.0
		particle_mat.initial_velocity_max = 30.0
		particle_mat.angular_velocity_min = -90.0
		particle_mat.angular_velocity_max = 90.0
		particle_mat.scale_min = 0.5
		particle_mat.scale_max = 1.5
		
		particles.process_material = particle_mat
		add_child(particles)

func _setup_rarity() -> void:
	"""Setup visual effects based on rarity"""
	if not use_rarity_system or not glow_light or not particles:
		return
	
	match rarity:
		Rarity.COMMON:
			# No glow for common
			glow_light.visible = false
			particles.visible = false
		
		Rarity.UNCOMMON:
			# Green glow
			glow_light.visible = true
			glow_light.color = Color(0.2, 1.0, 0.2, 0.8)
			glow_light.energy = 0.5
			glow_light.texture_scale = 2.0
			particles.visible = true
			particles.modulate = Color(0.2, 1.0, 0.2, 0.6)
			particles.emitting = true
		
		Rarity.RARE:
			# Blue glow
			glow_light.visible = true
			glow_light.color = Color(0.2, 0.5, 1.0, 0.9)
			glow_light.energy = 0.7
			glow_light.texture_scale = 2.5
			particles.visible = true
			particles.modulate = Color(0.2, 0.5, 1.0, 0.7)
			particles.emitting = true
		
		Rarity.EPIC:
			# Purple glow
			glow_light.visible = true
			glow_light.color = Color(0.8, 0.2, 1.0, 1.0)
			glow_light.energy = 0.9
			glow_light.texture_scale = 3.0
			particles.visible = true
			particles.modulate = Color(0.8, 0.2, 1.0, 0.8)
			particles.emitting = true
		
		Rarity.LEGENDARY:
			# Yellow/gold glow
			glow_light.visible = true
			glow_light.color = Color(1.0, 0.9, 0.2, 1.0)
			glow_light.energy = 1.2
			glow_light.texture_scale = 3.5
			particles.visible = true
			particles.modulate = Color(1.0, 0.9, 0.2, 1.0)
			particles.emitting = true
	
	# Start pulse animation for glow
	if glow_light and glow_light.visible and not Engine.is_editor_hint():
		_start_glow_pulse()

func _start_glow_pulse() -> void:
	"""Create pulsing glow effect"""
	if not glow_light:
		return
	
	var base_energy = glow_light.energy
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(glow_light, "energy", base_energy * 1.3, 1.0)
	tween.tween_property(glow_light, "energy", base_energy * 0.7, 1.0)

func _give_rarity_loot() -> void:
	"""Give loot based on rarity system"""
	var loot = _generate_loot()
	
	# Give gold
	if loot.gold > 0:
		var gem_item = preload("res://Items/gem.tres")
		if PlayerManager.INVENTORY_DATA:
			PlayerManager.INVENTORY_DATA.add_item(gem_item, loot.gold)
	
	# Give items
	for item in loot.items:
		if PlayerManager.INVENTORY_DATA:
			PlayerManager.INVENTORY_DATA.add_item(item, 1)
	
	# Show notification
	_show_loot_notification(loot)

func _generate_loot() -> Dictionary:
	"""Generate loot based on rarity"""
	var loot = {
		"items": [],
		"gems": 0
	}
	
	# Generate gems based on rarity
	var gem_multiplier = 1.0
	match rarity:
		Rarity.UNCOMMON:
			gem_multiplier = 1.5
		Rarity.RARE:
			gem_multiplier = 2.0
		Rarity.EPIC:
			gem_multiplier = 3.0
		Rarity.LEGENDARY:
			gem_multiplier = 5.0
	
	loot.gems = randi_range(gem_min, gem_max) * gem_multiplier
	
	# Generate items
	var num_items = randi_range(min_items, max_items)
	
	# Increase item count for higher rarities
	match rarity:
		Rarity.RARE:
			num_items += 1
		Rarity.EPIC:
			num_items += 2
		Rarity.LEGENDARY:
			num_items += 3
	
	# Pick random items from loot table
	if loot_table.size() > 0:
		for i in range(num_items):
			var item = loot_table[randi() % loot_table.size()]
			if item:
				loot.items.append(item)
	
	return loot

func _show_loot_notification(loot: Dictionary) -> void:
	"""Show what the player received"""
	var rarity_name = Rarity.keys()[rarity]
	
	# Print to console for now
	print("[Chest] Opened %s chest!" % rarity_name)
	if loot.gold > 0:
		print("  Gold: %d" % loot.gold)
	for item in loot.items:
		print("  Item: %s" % item.name)

func _get_rarity_color() -> Color:
	"""Get color for rarity"""
	match rarity:
		Rarity.COMMON:
			return Color.WHITE
		Rarity.UNCOMMON:
			return Color(0.2, 1.0, 0.2)
		Rarity.RARE:
			return Color(0.2, 0.5, 1.0)
		Rarity.EPIC:
			return Color(0.8, 0.2, 1.0)
		Rarity.LEGENDARY:
			return Color(1.0, 0.9, 0.2)
	return Color.WHITE

# ============================================
# LOOT BURST SYSTEM
# ============================================

func _spawn_loot_burst() -> void:
	"""Spawn multiple items that burst out from chest"""
	var loot = _generate_loot()
	
	print("[Chest] Opened %s chest!" % Rarity.keys()[rarity])
	print("  Gems: %d" % loot.gems)
	print("  Items: %d" % loot.items.size())
	
	# Debug check
	print("[Chest] PlayerManager exists: ", PlayerManager != null)
	print("[Chest] INVENTORY_DATA exists: ", PlayerManager.INVENTORY_DATA != null)
	
	if not PlayerManager.INVENTORY_DATA:
		push_error("[Chest] ERROR: PlayerManager.INVENTORY_DATA is null!")
		return
	
	# Add items to inventory FIRST
	for item in loot.items:
		if item:
			var success = PlayerManager.INVENTORY_DATA.add_item(item, 1)
			print("[Chest] Added to inventory: %s (success: %s)" % [item.name, success])
		else:
			print("[Chest] ERROR: Item is null!")
	
	# Add gems to inventory
	if loot.gems > 0:
		var gem_item = preload("res://Items/gem.tres")
		if gem_item:
			var success = PlayerManager.INVENTORY_DATA.add_item(gem_item, loot.gems)
			print("[Chest] Added to inventory: %d gems (success: %s)" % [loot.gems, success])
		else:
			print("[Chest] ERROR: Gem item is null!")
	
	# Force inventory UI to refresh
	PlayerManager.INVENTORY_DATA.emit_changed()
	print("[Chest] Inventory refresh signal emitted")
	
	# Also emit equipment_changed to trigger UI update
	PlayerManager.INVENTORY_DATA.equipment_changed.emit()
	print("[Chest] Equipment changed signal emitted")
	
	# THEN spawn visual items for effect
	for item in loot.items:
		_spawn_loot_item_visual(item)
	
	# Spawn gem visuals
	if loot.gems > 0:
		_spawn_gem_burst(loot.gems)

func _spawn_single_item_burst(item: ItemData, qty: int) -> void:
	"""Spawn single item burst (old system)"""
	# Add to inventory FIRST
	PlayerManager.INVENTORY_DATA.add_item(item, qty)
	print("[Chest] Added to inventory: %s x%d" % [item.name, qty])
	
	# Then spawn visuals
	for i in range(qty):
		_spawn_loot_item_visual(item)

func _spawn_loot_item_visual(item: ItemData) -> void:
	"""Create a visual item sprite that bursts out and gets collected"""
	var item_sprite = Sprite2D.new()
	item_sprite.texture = item.texture
	item_sprite.position = global_position + Vector2(0, -16)
	item_sprite.z_index = 10
	get_parent().add_child(item_sprite)
	
	# Random burst direction
	var angle = randf_range(0, TAU)
	var distance = randf_range(30, 60)
	var target_pos = item_sprite.position + Vector2(cos(angle), sin(angle)) * distance
	
	# Animate burst out
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move to burst position
	tween.tween_property(item_sprite, "position", target_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Scale up then down
	tween.tween_property(item_sprite, "scale", Vector2(1.5, 1.5), 0.15)
	tween.chain().tween_property(item_sprite, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Rotate
	tween.tween_property(item_sprite, "rotation", randf_range(-PI, PI), 0.3)
	
	# After burst animation, wait then collect
	tween.finished.connect(func():
		# Can't use await in lambda, so create a timer
		var timer = get_tree().create_timer(0.3)
		timer.timeout.connect(func():
			_collect_item(item_sprite, item)
		)
	)

func _collect_item(item_sprite: Sprite2D, item: ItemData) -> void:
	"""Collect animation (item already in inventory)"""
	# Collect animation - move to top of screen and fade
	var collect_tween = create_tween()
	collect_tween.set_parallel(true)
	
	var collect_target = item_sprite.get_viewport_rect().size * Vector2(0.5, 0.1)
	collect_tween.tween_property(item_sprite, "global_position", collect_target, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	collect_tween.tween_property(item_sprite, "modulate:a", 0.0, 0.5)
	collect_tween.tween_property(item_sprite, "scale", Vector2(0.5, 0.5), 0.5)
	
	# Remove sprite after animation
	collect_tween.finished.connect(func():
		item_sprite.queue_free()
	)

func _spawn_gem_burst(amount: int) -> void:
	"""Spawn individual gem items that burst out"""
	var gem_item = preload("res://Items/gem.tres")
	
	# Calculate how many gem sprites to spawn (cap at 20 for performance)
	var num_gems = min(amount, 20)
	var gems_per_sprite = ceil(float(amount) / float(num_gems))
	
	# Spawn individual gem sprites
	for i in range(num_gems):
		var gem_value = gems_per_sprite if i < num_gems - 1 else (amount - (gems_per_sprite * (num_gems - 1)))
		_spawn_gem_item_visual(gem_item, gem_value)
		# Small delay between gem spawns for staggered effect
		await get_tree().create_timer(0.05).timeout

func _spawn_gem_item_visual(gem_item: ItemData, value: int) -> void:
	"""Create a visual gem sprite that bursts out"""
	var gem_sprite = Sprite2D.new()
	gem_sprite.texture = gem_item.texture
	gem_sprite.position = global_position + Vector2(0, -16)
	gem_sprite.z_index = 10
	get_parent().add_child(gem_sprite)
	
	# Add value label if more than 1
	if value > 1:
		var value_label = Label.new()
		value_label.text = "x%d" % value
		value_label.add_theme_font_size_override("font_size", 10)
		value_label.add_theme_color_override("font_color", Color.WHITE)
		value_label.add_theme_color_override("font_outline_color", Color.BLACK)
		value_label.add_theme_constant_override("outline_size", 2)
		value_label.position = Vector2(8, -8)
		gem_sprite.add_child(value_label)
	
	# Random burst direction
	var angle = randf_range(0, TAU)
	var distance = randf_range(30, 60)
	var target_pos = gem_sprite.position + Vector2(cos(angle), sin(angle)) * distance
	
	# Animate burst out
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move to burst position
	tween.tween_property(gem_sprite, "position", target_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Scale up then down
	tween.tween_property(gem_sprite, "scale", Vector2(1.5, 1.5), 0.15)
	tween.chain().tween_property(gem_sprite, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Rotate
	tween.tween_property(gem_sprite, "rotation", randf_range(-PI, PI), 0.3)
	
	# Add sparkle effect
	tween.tween_property(gem_sprite, "modulate", Color(1.5, 1.5, 1.0), 0.15)
	tween.chain().tween_property(gem_sprite, "modulate", Color.WHITE, 0.15)
	
	# After burst animation, wait then collect
	# After burst animation, wait then collect
	tween.finished.connect(func():
		# Can't use await in lambda, so create a timer
		var timer = get_tree().create_timer(0.3)
		timer.timeout.connect(func():
			_collect_gem(gem_sprite, gem_item, value)
		)
	)

func _collect_gem(gem_sprite: Sprite2D, gem_item: ItemData, value: int) -> void:
	"""Collect gem animation and add to inventory"""
	# Collect animation - move to top of screen and fade
	var collect_tween = create_tween()
	collect_tween.set_parallel(true)
	
	var collect_target = gem_sprite.get_viewport_rect().size * Vector2(0.5, 0.1)
	collect_tween.tween_property(gem_sprite, "global_position", collect_target, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	collect_tween.tween_property(gem_sprite, "modulate:a", 0.0, 0.5)
	collect_tween.tween_property(gem_sprite, "scale", Vector2(0.5, 0.5), 0.5)
	
	# Add gems to inventory immediately (don't wait for animation)
	PlayerManager.INVENTORY_DATA.add_item(gem_item, value)
	print("[Chest] Added to inventory: %d gems" % value)
	
	# Remove sprite after animation
	collect_tween.finished.connect(func():
		gem_sprite.queue_free()
	)
