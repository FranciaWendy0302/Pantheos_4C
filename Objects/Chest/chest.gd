extends StaticBody2D
class_name Chest

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var rarity: Rarity = Rarity.COMMON
@export var loot_table: Array[ItemData] = []
@export var min_items: int = 1
@export var max_items: int = 3
@export var gold_min: int = 10
@export var gold_max: int = 50

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow_light: PointLight2D = $GlowLight
@onready var interaction_area: Area2D = $InteractionArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var particles: GPUParticles2D = $Particles

var is_open: bool = false
var player_nearby: bool = false
var nearby_player: CharacterBody2D = null

func _ready():
	_setup_rarity()
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Start idle animation
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func _setup_rarity():
	"""Setup visual effects based on rarity"""
	match rarity:
		Rarity.COMMON:
			# No glow for common
			if glow_light:
				glow_light.visible = false
			if particles:
				particles.visible = false
		
		Rarity.UNCOMMON:
			# Green glow
			if glow_light:
				glow_light.visible = true
				glow_light.color = Color(0.2, 1.0, 0.2, 0.8)
				glow_light.energy = 0.5
				glow_light.texture_scale = 2.0
			if particles:
				particles.visible = true
				particles.modulate = Color(0.2, 1.0, 0.2, 0.6)
		
		Rarity.RARE:
			# Blue glow
			if glow_light:
				glow_light.visible = true
				glow_light.color = Color(0.2, 0.5, 1.0, 0.9)
				glow_light.energy = 0.7
				glow_light.texture_scale = 2.5
			if particles:
				particles.visible = true
				particles.modulate = Color(0.2, 0.5, 1.0, 0.7)
		
		Rarity.EPIC:
			# Purple glow
			if glow_light:
				glow_light.visible = true
				glow_light.color = Color(0.8, 0.2, 1.0, 1.0)
				glow_light.energy = 0.9
				glow_light.texture_scale = 3.0
			if particles:
				particles.visible = true
				particles.modulate = Color(0.8, 0.2, 1.0, 0.8)
		
		Rarity.LEGENDARY:
			# Yellow/gold glow
			if glow_light:
				glow_light.visible = true
				glow_light.color = Color(1.0, 0.9, 0.2, 1.0)
				glow_light.energy = 1.2
				glow_light.texture_scale = 3.5
			if particles:
				particles.visible = true
				particles.modulate = Color(1.0, 0.9, 0.2, 1.0)
	
	# Pulse animation for glow
	if glow_light and glow_light.visible:
		_start_glow_pulse()

func _start_glow_pulse():
	"""Create pulsing glow effect"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(glow_light, "energy", glow_light.energy * 1.3, 1.0)
	tween.tween_property(glow_light, "energy", glow_light.energy * 0.7, 1.0)

func _process(_delta: float):
	if player_nearby and not is_open and Input.is_action_just_pressed("interact"):
		open_chest()

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and not is_open:
		player_nearby = true
		nearby_player = body
		_show_interaction_prompt()

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_nearby = false
		nearby_player = null
		_hide_interaction_prompt()

func _show_interaction_prompt():
	"""Show 'Press E to open' prompt"""
	if PlayerManager.player_hud:
		var rarity_name = Rarity.keys()[rarity]
		var color = _get_rarity_color()
		PlayerManager.player_hud.queue_notificaiton(
			"[color=#%s]%s Chest[/color]" % [color.to_html(false), rarity_name],
			"Press E to open"
		)

func _hide_interaction_prompt():
	"""Hide interaction prompt"""
	pass

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

func open_chest():
	"""Open the chest and give loot"""
	if is_open:
		return
	
	is_open = true
	player_nearby = false
	
	# Play open animation
	if animation_player and animation_player.has_animation("open"):
		animation_player.play("open")
	
	# Stop glow
	if glow_light:
		var tween = create_tween()
		tween.tween_property(glow_light, "energy", 0.0, 0.5)
	
	# Stop particles
	if particles:
		particles.emitting = false
	
	# Generate and give loot
	var loot = _generate_loot()
	_give_loot_to_player(loot)
	
	# Play sound
	_play_open_sound()

func _generate_loot() -> Dictionary:
	"""Generate loot based on rarity"""
	var loot = {
		"items": [],
		"gold": 0
	}
	
	# Generate gold based on rarity
	var gold_multiplier = 1.0
	match rarity:
		Rarity.UNCOMMON:
			gold_multiplier = 1.5
		Rarity.RARE:
			gold_multiplier = 2.0
		Rarity.EPIC:
			gold_multiplier = 3.0
		Rarity.LEGENDARY:
			gold_multiplier = 5.0
	
	loot.gold = randi_range(gold_min, gold_max) * gold_multiplier
	
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

func _give_loot_to_player(loot: Dictionary):
	"""Give loot to the player"""
	if not nearby_player:
		return
	
	# Give gold
	if loot.gold > 0:
		var gem_item = preload("res://Items/gem.tres")
		if PlayerManager.INVENTORY_DATA:
			PlayerManager.INVENTORY_DATA.add_item(gem_item, loot.gold)
	
	# Give items
	for item in loot.items:
		if PlayerManager.INVENTORY_DATA:
			PlayerManager.INVENTORY_DATA.add_item(item, 1)
	
	# Show loot notification
	_show_loot_notification(loot)

func _show_loot_notification(loot: Dictionary):
	"""Show what the player received"""
	var rarity_name = Rarity.keys()[rarity]
	var color = _get_rarity_color()
	
	var message = ""
	if loot.gold > 0:
		message += "%d Gold\n" % loot.gold
	
	for item in loot.items:
		message += "• %s\n" % item.name
	
	if PlayerManager.player_hud:
		PlayerManager.player_hud.queue_notificaiton(
			"[color=#%s]%s Chest Opened![/color]" % [color.to_html(false), rarity_name],
			message
		)

func _play_open_sound():
	"""Play chest opening sound"""
	# TODO: Add sound effect
	pass
