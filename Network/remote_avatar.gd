extends Node2D

const FRAME_COUNT: int = 128

var peer_id: int = -1
var hp: int = 10
var max_hp: int = 10
var mana: int = 10
var max_mana: int = 10
var is_hovered: bool = false
var nickname: String = "Player"

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _weapon_below: Sprite2D = $Sprite2D/Sprite2D_Weapon_Below
@onready var _weapon_above: Sprite2D = $Sprite2D/Sprite2D_Weapon_Above
@onready var _hit_box: HitBox = $HitBox
@onready var _click_area: Area2D = null

# HP/Mana bars above player
var hp_bar_container: Control = null
var hp_bar: ProgressBar = null
var mana_bar: ProgressBar = null
var name_label: Label = null

func _ready() -> void:
	# Add to group for easy finding
	add_to_group("remote_avatars")
	
	if _hit_box:
		_hit_box.Damaged.connect(_on_damaged)
	
	# Wait for node to be fully in tree before creating click area
	await get_tree().process_frame
	
	# Create click detection area
	_create_click_area()
	
	# Create HP/Mana bars above player
	_create_status_bars()
	
	# Listen for party changes to update HP bar color
	if PartyManager:
		if not PartyManager.member_joined.is_connected(_on_party_changed):
			PartyManager.member_joined.connect(_on_party_changed)
		if not PartyManager.member_left.is_connected(_on_party_changed):
			PartyManager.member_left.connect(_on_party_changed)
	
	# Listen for duel changes to update HP bar color
	var duel_manager = get_node_or_null("/root/DuelManager")
	if duel_manager:
		if not duel_manager.duel_started.is_connected(_on_duel_changed):
			duel_manager.duel_started.connect(_on_duel_changed)
		if not duel_manager.duel_ended.is_connected(_on_duel_changed):
			duel_manager.duel_ended.connect(_on_duel_changed)
	
	print("[RemoteAvatar] Ready complete for player: ", nickname, " at ", global_position)
	pass

func _input(event: InputEvent) -> void:
	"""Backup method: Check if mouse click is within our bounds"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# Get mouse position in world coordinates
			var mouse_pos = get_global_mouse_position()
			var distance = global_position.distance_to(mouse_pos)
			
			# Check if click is within our click radius
			if distance <= 30.0:  # Match click area radius
				print("[RemoteAvatar] Backup click detected on player: ", nickname)
				PlayerManager.set_target(self)
				get_viewport().set_input_as_handled()

func _create_click_area() -> void:
	"""Create an Area2D for click detection"""
	_click_area = Area2D.new()
	_click_area.name = "ClickArea"
	_click_area.collision_layer = 0  # Don't collide with anything
	_click_area.collision_mask = 0   # Don't detect anything
	_click_area.input_pickable = true  # Enable input detection
	_click_area.z_index = 100  # Make sure it's on top
	
	# Create collision shape for clicking
	var click_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30.0  # Larger click radius for easier clicking
	click_shape.shape = circle
	click_shape.position = Vector2(0, -10)  # Center on player sprite
	click_shape.debug_color = Color(0, 0, 1, 0.3)  # Blue debug color
	
	_click_area.add_child(click_shape)
	add_child(_click_area)
	
	# Set up input detection
	_click_area.input_event.connect(_on_click_area_input)
	_click_area.mouse_entered.connect(_on_mouse_entered)
	_click_area.mouse_exited.connect(_on_mouse_exited)
	
	print("[RemoteAvatar] Click area created for player ", peer_id, " at position ", global_position)
	print("[RemoteAvatar] Click area input_pickable: ", _click_area.input_pickable)
	print("[RemoteAvatar] Click area z_index: ", _click_area.z_index)

func _on_click_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	"""Handle click on this player"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_clicked()

func _on_mouse_entered() -> void:
	"""Mouse entered the player area"""
	print("[RemoteAvatar] Mouse entered player: ", nickname)
	is_hovered = true
	if _sprite:
		_sprite.modulate = Color(1.2, 1.2, 1.2, 1.0)  # Slight highlight

func _on_mouse_exited() -> void:
	"""Mouse left the player area"""
	print("[RemoteAvatar] Mouse exited player: ", nickname)
	is_hovered = false
	if _sprite:
		_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal color

func _on_clicked() -> void:
	"""Called when this player is clicked"""
	print("[RemoteAvatar] Clicked player: ", nickname, " (ID: ", peer_id, ")")
	# Set as target
	PlayerManager.set_target(self)
	# Mark event as handled
	get_viewport().set_input_as_handled()

func set_targeted(targeted: bool) -> void:
	"""Called by PlayerManager when this becomes the target"""
	is_hovered = targeted
	if _sprite:
		if targeted:
			_sprite.modulate = Color(1.3, 1.3, 1.0, 1.0)  # Yellow tint when targeted
		else:
			_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal color

func set_nickname(new_nickname: String) -> void:
	nickname = new_nickname
	pass

func get_player_id() -> int:
	"""Get the player ID for this remote avatar"""
	return peer_id

func set_direction(_dir: Vector2) -> void:
	# Direction is handled by sprite_data scale_x
	pass

func _on_damaged(hurt_box: HurtBox) -> void:
	# Check if in active duel
	var duel_manager = get_node_or_null("/root/DuelManager")
	if not duel_manager:
		print("[RemoteAvatar] No DuelManager found - damage ignored")
		return
	
	var my_id = PlayerManager.player_id
	if not duel_manager.is_in_duel(my_id):
		print("[RemoteAvatar] Not in duel - damage ignored")
		return
	
	if duel_manager.get_opponent_id(my_id) != peer_id:
		print("[RemoteAvatar] Not duel opponent - damage ignored")
		return
	
	# In active duel - send damage to server
	var damage: int = hurt_box.damage
	print("[RemoteAvatar] *** SENDING DAMAGE *** to player ", peer_id, ": ", damage, " damage")
	
	# Send damage through WebSocket
	if NetworkManager and NetworkManager._websocket:
		if NetworkManager._websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			var message = {
				"type": "player_damage",
				"target_player_id": peer_id,
				"damage": damage
			}
			var json_string = JSON.stringify(message)
			NetworkManager._websocket.send_text(json_string)
			print("[RemoteAvatar] Damage message sent successfully")
		else:
			print("[RemoteAvatar] ERROR: WebSocket not open!")
	else:
		print("[RemoteAvatar] ERROR: NetworkManager or WebSocket not available!")
	
	# Visual feedback - flash red
	_flash_damage()
	pass

func _flash_damage() -> void:
	if _sprite:
		_sprite.modulate = Color(1, 0.3, 0.3, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(_sprite):
			_sprite.modulate = Color(1, 1, 1, 1)
	pass

func update_hp(new_hp: int, new_max_hp: int) -> void:
	hp = new_hp
	max_hp = new_max_hp
	
	print("[RemoteAvatar] HP updated for ", nickname, " (ID: ", peer_id, ") - HP: ", hp, "/", max_hp)
	
	# Update HP bar above player (ColorRect version)
	if hp_bar_container and hp_bar_container.has_node("HPRect"):
		var hp_rect = hp_bar_container.get_node("HPRect")
		var hp_percent = float(hp) / float(max_hp) if max_hp > 0 else 0.0
		hp_rect.size.x = 50 * hp_percent
		# Update color based on party status and safezone
		hp_rect.color = _get_hp_bar_color()
	
	# Update target health bar in HUD if this player is targeted
	if PlayerHud and PlayerHud.has_method("update_target_hp_external"):
		PlayerHud.update_target_hp_external(peer_id, hp, max_hp)
	pass

func update_mana(new_mana: int, new_max_mana: int) -> void:
	"""Update mana and mana bar"""
	mana = new_mana
	max_mana = new_max_mana
	
	# Update mana bar above player
	if mana_bar:
		mana_bar.max_value = max_mana
		mana_bar.value = mana
	pass

func set_sprite_data(sprite_data: Dictionary) -> void:
	if not _sprite or sprite_data.is_empty():
		return
	
	# Load texture if provided (only once)
	if sprite_data.has("texture") and sprite_data["texture"] != "":
		if not _sprite.texture or _sprite.texture.resource_path != sprite_data["texture"]:
			var texture = load(sprite_data["texture"])
			if texture:
				_sprite.texture = texture
	
	# Set sprite sheet properties (only once or when changed)
	if sprite_data.has("hframes") and _sprite.hframes != sprite_data["hframes"]:
		_sprite.hframes = sprite_data["hframes"]
	if sprite_data.has("vframes") and _sprite.vframes != sprite_data["vframes"]:
		_sprite.vframes = sprite_data["vframes"]
	
	# Update frame every time (for animation)
	if sprite_data.has("frame"):
		_sprite.frame = sprite_data["frame"]
		# Update weapon frames to match player sprite
		if _weapon_below:
			_weapon_below.frame = sprite_data["frame"]
		if _weapon_above:
			_weapon_above.frame = sprite_data["frame"] + FRAME_COUNT
	
	# Update scale.x for facing direction (not flip_h)
	if sprite_data.has("scale_x"):
		_sprite.scale.x = sprite_data["scale_x"]
	
	# Load weapon texture if provided
	if sprite_data.has("weapon_texture") and sprite_data["weapon_texture"] != "":
		if _weapon_below and (not _weapon_below.texture or _weapon_below.texture.resource_path != sprite_data["weapon_texture"]):
			var weapon_texture = load(sprite_data["weapon_texture"])
			if weapon_texture:
				_weapon_below.texture = weapon_texture
				if _weapon_above:
					_weapon_above.texture = weapon_texture
	pass

func play_attack_animation(attack_type: String, direction: Vector2) -> void:
	"""Play attack animation for remote player"""
	if attack_type == "spin":
		_play_spin_attack()
	elif attack_type == "dash":
		_play_dash_attack(direction)
	else:
		_play_basic_attack(direction)

func _play_basic_attack(direction: Vector2) -> void:
	"""Play basic attack animation - simple flash effect"""
	# Create a simple flash on the sprite
	if _sprite:
		var original_modulate = _sprite.modulate
		_sprite.modulate = Color(1.5, 1.5, 0.5, 1.0)  # Yellow flash
		
		# Flash back to normal
		var tween = create_tween()
		tween.tween_property(_sprite, "modulate", original_modulate, 0.15)
	
	# Optional: Add a small particle burst
	_create_attack_particles(direction, Color(1, 1, 0, 0.8))

func _play_spin_attack() -> void:
	"""Play spin attack animation - simple cyan flash"""
	if _sprite:
		# Just do a cyan flash, no rotation (rotation causes issues)
		var original_modulate = _sprite.modulate
		var original_scale = _sprite.scale
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Cyan flash that fades
		tween.tween_property(_sprite, "modulate", Color(0.5, 1.5, 1.5, 1.0), 0.1)
		tween.chain().tween_property(_sprite, "modulate", original_modulate, 0.4)
		
		# Scale pulse
		tween.tween_property(_sprite, "scale", original_scale * 1.3, 0.2)
		tween.chain().tween_property(_sprite, "scale", original_scale, 0.3)
	
	# Add particle burst
	_create_spin_particles()

func _play_dash_attack(direction: Vector2) -> void:
	"""Play dash attack animation - flash and scale effect (no position change)"""
	if _sprite:
		var original_modulate = _sprite.modulate
		var original_scale = _sprite.scale
		
		# Orange flash
		_sprite.modulate = Color(1.5, 0.8, 0.3, 1.0)
		
		# Create visual "dash" effect with scale and squash
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Quick scale pulse to simulate dash
		tween.tween_property(_sprite, "scale", Vector2(original_scale.x * 1.3, original_scale.y * 0.8), 0.1)
		tween.chain().tween_property(_sprite, "scale", original_scale, 0.15)
		
		# Fade back to normal color
		tween.tween_property(_sprite, "modulate", original_modulate, 0.25)
	
	# Add trail particles
	_create_attack_particles(direction, Color(1, 0.5, 0, 0.8))

func _create_attack_particles(direction: Vector2, color: Color) -> void:
	"""Create simple particle effect for attacks"""
	# Create 3 small colored circles that fade out
	for i in range(3):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = color
		particle.position = direction * (10 + i * 5) - Vector2(2, 2)
		add_child(particle)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "modulate:a", 0.0, 0.3)
		tween.tween_property(particle, "scale", Vector2(2, 2), 0.3)
		
		# Use callback to free particle instead of await
		tween.finished.connect(func(): 
			if is_instance_valid(particle):
				particle.queue_free()
		)

func _create_spin_particles() -> void:
	"""Create circular particle burst for spin attack"""
	# Create particles in a circle
	for i in range(8):
		var angle = (TAU / 8.0) * i
		var direction = Vector2(cos(angle), sin(angle))
		
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = Color(0, 1, 1, 0.8)  # Cyan
		particle.position = direction * 20 - Vector2(3, 3)
		add_child(particle)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", direction * 40 - Vector2(3, 3), 0.4)
		tween.tween_property(particle, "modulate:a", 0.0, 0.4)
		
		# Use callback to free particle instead of await
		tween.finished.connect(func():
			if is_instance_valid(particle):
				particle.queue_free()
		)


func _create_status_bars() -> void:
	"""Create simple HP bar using ColorRect"""
	# Nickname label
	name_label = Label.new()
	name_label.text = nickname
	name_label.position = Vector2(-25, -58)
	name_label.size = Vector2(50, 8)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_label.add_theme_constant_override("outline_size", 1)
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)
	
	# Background bar (dark gray)
	var hp_bg = ColorRect.new()
	hp_bg.position = Vector2(-25, -50)
	hp_bg.size = Vector2(50, 5)
	hp_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_bg)
	
	# HP bar (color depends on party status)
	hp_bar_container = Control.new()
	hp_bar_container.position = Vector2(-25, -50)
	hp_bar_container.size = Vector2(50, 5)
	hp_bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_bar_container)
	
	var hp_rect = ColorRect.new()
	hp_rect.name = "HPRect"
	hp_rect.position = Vector2(0, 0)
	hp_rect.size = Vector2(50 * (float(hp) / float(max_hp)), 5)
	hp_rect.color = _get_hp_bar_color()  # Red for enemy, green for party
	hp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_container.add_child(hp_rect)
	
	print("[RemoteAvatar] HP bar created for ", nickname, " (party member: ", _is_party_member(), ")")

func _get_hp_bar_color() -> Color:
	"""Get HP bar color based on party status, safezone, and duel status"""
	# Check if in duel with this player - RED (hostile)
	var duel_manager = get_node_or_null("/root/DuelManager")
	if duel_manager:
		var my_id = PlayerManager.player_id
		if duel_manager.is_in_duel(my_id) and duel_manager.get_opponent_id(my_id) == peer_id:
			return Color(0.8, 0.2, 0.2, 1.0)  # Red for duel opponent
	
	# Check if in safezone
	var current_scene = get_tree().current_scene
	var in_safezone = false
	if current_scene and current_scene.scene_file_path.contains("safezone"):
		in_safezone = true
	
	if _is_party_member():
		return Color(0.2, 0.8, 0.2, 1.0)  # Green for party members
	elif in_safezone:
		return Color(0.2, 0.5, 0.8, 1.0)  # Blue for neutral (safezone)
	else:
		return Color(0.8, 0.2, 0.2, 1.0)  # Red for hostile (outside safezone)

func _is_party_member() -> bool:
	"""Check if this player is in our party"""
	if not PartyManager or not PartyManager.is_in_party():
		return false
	
	# Check if this player's ID is in the party members list
	var members = PartyManager.get_members()
	for member in members:
		if member.get("id") == peer_id:
			return true
	return false

func refresh_hp_bar_color() -> void:
	"""Manually refresh HP bar color based on current party status, safezone, and duel"""
	if hp_bar_container and hp_bar_container.has_node("HPRect"):
		var hp_rect = hp_bar_container.get_node("HPRect")
		hp_rect.color = _get_hp_bar_color()
		
		# Get color name for debug
		var color_name = "Red (Hostile)"
		var duel_manager = get_node_or_null("/root/DuelManager")
		if duel_manager and duel_manager.is_in_duel(PlayerManager.player_id):
			if duel_manager.get_opponent_id(PlayerManager.player_id) == peer_id:
				color_name = "Red (Duel Opponent)"
		elif _is_party_member():
			color_name = "Green (Party)"
		else:
			var current_scene = get_tree().current_scene
			if current_scene and current_scene.scene_file_path.contains("safezone"):
				color_name = "Blue (Neutral/Safezone)"
		
		print("[RemoteAvatar] HP bar color updated for ", nickname, " - ", color_name)

func _on_party_changed(_player_id: int) -> void:
	"""Called when party membership changes"""
	refresh_hp_bar_color()

func _on_scene_changed() -> void:
	"""Called when scene changes (e.g., entering/leaving safezone)"""
	refresh_hp_bar_color()

func _on_duel_changed(_p1: int, _p2: int) -> void:
	"""Called when duel starts or ends"""
	refresh_hp_bar_color()
