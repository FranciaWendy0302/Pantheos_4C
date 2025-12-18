extends Node

signal connected(mode: String)
signal disconnected_signal()
signal peer_joined(peer_id: int, nickname: String)
signal peer_left(peer_id: int)
signal connected_to_server()
signal friend_request(data: Dictionary)
signal friend_accepted(data: Dictionary)
signal friend_removed(data: Dictionary)
signal friend_online(data: Dictionary)
signal friend_offline(data: Dictionary)
signal friend_request_expired(data: Dictionary)

const DEFAULT_PORT: int = 9000
const SNAPSHOT_INTERVAL_S: float = 0.05
const MAX_PEERS: int = 3

# Node.js Server Configuration
# Use localhost for local testing, or your server IP for remote access
var api_url: String = "http://100.92.219.104:3000/api"
var ws_url: String = "ws://100.92.219.104:9000"
var api_key: String = "pantheos_dev_key_12345"  # Must match server/.env

var _is_server: bool = false
var _mode: String = "party"
var _nickname: String = ""
var _peer_id_to_name: Dictionary = {}
var _peer_id_to_avatar: Dictionary = {}
var _peer_id_to_hp: Dictionary = {}
var _peer_id_to_map: Dictionary = {}  # Track which map each player is in
var _current_map: String = ""  # Client's current map

# WebSocket for Node.js server
var _websocket: WebSocketPeer = null
var _player_id: int = 0

@onready var _snapshot_timer: Timer = Timer.new()

func _ready() -> void:
	add_child(_snapshot_timer)
	_snapshot_timer.wait_time = SNAPSHOT_INTERVAL_S
	_snapshot_timer.one_shot = false
	_snapshot_timer.timeout.connect(_on_snapshot_timer_timeout)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	pass


# =========================
# Client API
# =========================

func connect_to_server(address: String, port: int, nickname: String, mode: String) -> void:
	_mode = mode
	_nickname = nickname if nickname != "" else PlayerManager.nickname

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("Failed to create ENet client: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	pass


func disconnect_from_server() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()

	multiplayer.multiplayer_peer = null
	_cleanup_all_avatars()
	disconnected_signal.emit()
	pass


func notify_map_changed(new_map_path: String) -> void:
	"""Call this when the player changes maps/scenes"""
	_current_map = new_map_path
	# Clean up all remote avatars since we're in a new map
	_cleanup_all_avatars()
	pass


# =========================
# Server Control
# =========================

func start_server(port: int = DEFAULT_PORT) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PEERS)

	if err != OK:
		push_error("Failed to start ENet server: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	_is_server = true
	pass


# =========================
# Client-side Snapshot Loop
# =========================

func _on_connected_to_server() -> void:
	_snapshot_timer.start()
	_register_on_server.rpc_id(1, _nickname, _mode)
	_setup_pvp_mode()
	connected.emit(_mode)
	pass


func _setup_pvp_mode() -> void:
	if _mode == "duel" and PlayerManager.player and is_instance_valid(PlayerManager.player):
		var hurt_boxes = _get_all_hurt_boxes(PlayerManager.player)
		for hurt_box in hurt_boxes:
			if hurt_box is HurtBox:
				hurt_box.collision_mask |= 2
	pass


func _get_all_hurt_boxes(node: Node) -> Array:
	var arr: Array = []

	if node is HurtBox:
		arr.append(node)

	for child in node.get_children():
		arr.append_array(_get_all_hurt_boxes(child))

	return arr


func _on_connection_failed() -> void:
	pass


func _on_server_disconnected() -> void:
	_snapshot_timer.stop()
	_cleanup_all_avatars()
	disconnected_signal.emit()
	pass


func _on_snapshot_timer_timeout() -> void:
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		return

	if not PlayerManager.player or not is_instance_valid(PlayerManager.player):
		return

	var pos: Vector2 = PlayerManager.player.global_position
	var dir: Vector2 = PlayerManager.player.cardinal_direction
	var hp: int = PlayerManager.player.hp
	var max_hp: int = PlayerManager.player.max_hp

	var sprite_data: Dictionary = {}

	if PlayerManager.player.sprite and PlayerManager.player.sprite.texture:
		sprite_data["texture"] = PlayerManager.player.sprite.texture.resource_path
		sprite_data["hframes"] = PlayerManager.player.sprite.hframes
		sprite_data["vframes"] = PlayerManager.player.sprite.vframes
		sprite_data["frame"] = PlayerManager.player.sprite.frame
		sprite_data["scale_x"] = PlayerManager.player.sprite.scale.x

		if PlayerManager.player.sprite.has_node("Sprite2D_Weapon_Below"):
			var weapon_b = PlayerManager.player.sprite.get_node("Sprite2D_Weapon_Below")
			if weapon_b.texture:
				sprite_data["weapon_texture"] = weapon_b.texture.resource_path

		if PlayerManager.player.sprite.has_node("Sprite2D_Weapon_Above"):
			var weapon_a = PlayerManager.player.sprite.get_node("Sprite2D_Weapon_Above")
			if weapon_a.texture:
				sprite_data["weapon_texture"] = weapon_a.texture.resource_path

	# Get current map/scene name
	var current_scene = get_tree().current_scene
	if current_scene:
		_current_map = current_scene.scene_file_path
	
	_send_transform_to_server.rpc(pos, dir, sprite_data, hp, max_hp, _current_map)
	pass


# =========================
# RPCs (Checksum Safe)
# =========================

@rpc("any_peer", "reliable", "call_local")
func _register_on_server(nickname: String, _mode_unused: String) -> void:
	if not multiplayer.is_server():
		return

	var sender := multiplayer.get_remote_sender_id()
	_peer_id_to_name[sender] = nickname

	_peer_joined_client.rpc(sender, nickname)

	for pid in _peer_id_to_name.keys():
		if pid != sender:
			_peer_joined_client.rpc_id(sender, pid, _peer_id_to_name[pid])
	pass


@rpc("authority", "reliable", "call_local")
func _peer_joined_client(peer_id: int, nickname: String) -> void:
	peer_joined.emit(peer_id, nickname)
	_peer_id_to_name[peer_id] = nickname
	_spawn_or_update_avatar(peer_id, nickname, Vector2.ZERO, Vector2.DOWN, {}, 10, 10)
	pass


@rpc("any_peer", "unreliable", "call_local")
func _send_transform_to_server(pos: Vector2, dir: Vector2, sprite_data: Dictionary, hp: int, max_hp: int, map_path: String) -> void:
	if not multiplayer.is_server():
		return

	var sender := multiplayer.get_remote_sender_id()
	_peer_id_to_hp[sender] = {"hp": hp, "max_hp": max_hp}
	_peer_id_to_map[sender] = map_path  # Track sender's map

	# Only broadcast to players in the same map
	for pid in multiplayer.get_peers():
		if pid == sender:
			continue
		
		# Check if target player is in the same map
		if _peer_id_to_map.get(pid, "") == map_path:
			_broadcast_peer_transform.rpc_id(pid, sender, pos, dir, sprite_data, hp, max_hp)
	pass


@rpc("authority", "unreliable", "call_local")
func _broadcast_peer_transform(peer_id: int, pos: Vector2, dir: Vector2, sprite_data: Dictionary, hp: int, max_hp: int) -> void:
	_spawn_or_update_avatar(peer_id, _peer_id_to_name.get(peer_id, "Player"), pos, dir, sprite_data, hp, max_hp)
	pass


@rpc("authority", "reliable", "call_local")
func _peer_left_client(peer_id: int) -> void:
	peer_left.emit(peer_id)

	if _peer_id_to_avatar.has(peer_id):
		var avatar = _peer_id_to_avatar[peer_id]
		if is_instance_valid(avatar):
			avatar.queue_free()

		_peer_id_to_avatar.erase(peer_id)
	pass


# PvP: client → server (hit someone)
@rpc("any_peer", "reliable", "call_local")
func _report_remote_avatar_damage(target_peer_id: int, damage: int) -> void:
	if not multiplayer.is_server():
		return

	if _peer_id_to_hp.has(target_peer_id):
		var hp_data = _peer_id_to_hp[target_peer_id]
		hp_data["hp"] = max(0, hp_data["hp"] - damage)
		_peer_id_to_hp[target_peer_id] = hp_data

		_apply_damage_to_player.rpc_id(target_peer_id, damage)
	pass


# PvP: server → client (you took damage)
@rpc("authority", "reliable", "call_local")
func _apply_damage_to_player(damage: int) -> void:
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		PlayerManager.player.update_hp(-damage)
	pass


# =========================
# Avatars
# =========================

func _spawn_or_update_avatar(peer_id: int, nickname: String, pos: Vector2, _dir: Vector2, sprite_data: Dictionary, hp: int, max_hp: int) -> void:
	if _is_server:
		return

	var avatar: Node2D

	if _peer_id_to_avatar.has(peer_id) and is_instance_valid(_peer_id_to_avatar[peer_id]):
		avatar = _peer_id_to_avatar[peer_id]
	else:
		var scene := load("res://Network/remote_avatar.tscn") as PackedScene
		var inst = scene.instantiate() as Node2D
		inst.name = "RemoteAvatar_%d" % peer_id
		inst.peer_id = peer_id

		var current_scene = get_tree().current_scene
		if not current_scene:
			return

		current_scene.add_child(inst)
		_peer_id_to_avatar[peer_id] = inst
		avatar = inst
		avatar = inst

		if avatar.has_method("set_nickname"):
			avatar.set_nickname(nickname)

	avatar.global_position = pos

	if avatar.has_method("set_sprite_data"):
		avatar.set_sprite_data(sprite_data)

	if avatar.has_method("update_hp"):
		avatar.update_hp(hp, max_hp)
	pass


func _cleanup_all_avatars() -> void:
	for pid in _peer_id_to_avatar.keys():
		var avatar = _peer_id_to_avatar[pid]
		if is_instance_valid(avatar):
			avatar.queue_free()

	_peer_id_to_avatar.clear()
	pass


# =========================
# Peer Events
# =========================

func _on_peer_connected(_id: int) -> void:
	if multiplayer.is_server():
		pass
	pass


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		_peer_id_to_name.erase(id)

	_peer_left_client.rpc(id)
	pass


# =========================
# Node.js Server Functions
# =========================

func connect_to_nodejs_server(player_id: int, nickname: String, character_class: String) -> void:
	"""Connect to Node.js WebSocket server for online multiplayer"""
	print("[MP] ========== CONNECTING TO WEBSOCKET ==========")
	print("[MP] Player ID: ", player_id)
	print("[MP] Nickname: ", nickname)
	print("[MP] Class: ", character_class)
	print("[MP] WebSocket URL: ", ws_url)
	
	_player_id = player_id
	_nickname = nickname
	
	_websocket = WebSocketPeer.new()
	var err = _websocket.connect_to_url(ws_url)
	
	if err != OK:
		push_error("Failed to connect to WebSocket server: %s" % err)
		print("[MP] ✗ WebSocket connection FAILED!")
		return
	
	print("[MP] ✓ WebSocket connection initiated, waiting for OPEN state...")
	
	# Send join message once connected
	await get_tree().create_timer(0.5).timeout
	
	if _websocket and _websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		print("[MP] ✓ WebSocket is OPEN, sending join message...")
	else:
		if _websocket:
			print("[MP] ✗ WebSocket not open yet, state: ", _websocket.get_ready_state())
		else:
			print("[MP] ✗ WebSocket is null")
	
	# Get player stats to send to server
	var player = PlayerManager.player
	var hp = player.hp if player else 100
	var max_hp = player.max_hp if player else 100
	var mana = player.mana if player else 100
	var max_mana = player.max_mana if player else 100
	
	send_websocket_message({
		"type": "join",
		"data": {
			"player_id": player_id,
			"nickname": nickname,
			"character_class": character_class,
			"hp": hp,
			"max_hp": max_hp,
			"mana": mana,
			"max_mana": max_mana
		}
	})
	
	# Emit connected signal for friend manager
	connected_to_server.emit()

	pass


func disconnect_from_nodejs_server() -> void:
	"""Disconnect from Node.js WebSocket server"""
	if _websocket:
		_websocket.close()
		_websocket = null
	pass


func send_websocket_message(message: Dictionary) -> void:
	"""Send message to Node.js server"""
	if _websocket and _websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json_string = JSON.stringify(message)
		_websocket.send_text(json_string)
	pass


func send_position_to_server(position: Vector2) -> void:
	"""Send player position to Node.js server"""
	send_websocket_message({
		"type": "move",
		"data": {
			"x": position.x,
			"y": position.y
		}
	})
	pass


func send_chat_message(channel: String, message: String, target_player_id: int = -1) -> void:
	"""Send chat message to Node.js server"""
	var data = {
		"channel": channel,
		"message": message
	}
	
	# Add target player ID for whispers
	if channel == "whisper" and target_player_id > 0:
		data["target_player_id"] = target_player_id
	
	send_websocket_message({
		"type": "chat",
		"data": data
	})
	pass


func send_attack(target_id: int, damage: int) -> void:
	"""Send attack to Node.js server"""
	send_websocket_message({
		"type": "attack",
		"data": {
			"target_id": target_id,
			"damage": damage
		}
	})
	pass





var _last_position: Vector2 = Vector2.ZERO
var _position_update_timer: float = 0.0
const POSITION_UPDATE_INTERVAL: float = 0.05  # Send updates every 50ms (20 times per second)

func _send_hp_update(hp: int, max_hp: int) -> void:
	"""Send immediate HP update to server (for real-time sync when taking damage)"""
	if _websocket and _websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		print("[NetworkManager] *** SENDING HP UPDATE *** HP:", hp, "/", max_hp)
		var message = {
			"type": "player_hp_update",
			"hp": hp,
			"max_hp": max_hp
		}
		
		var json_string = JSON.stringify(message)
		_websocket.send_text(json_string)
		print("[NetworkManager] HP update sent to server")

func _send_position_update(position: Vector2) -> void:
	"""Send player position to server (throttled)"""
	_position_update_timer += get_process_delta_time()
	
	# Only send if position changed significantly or enough time passed
	if position.distance_to(_last_position) < 1.0 and _position_update_timer < POSITION_UPDATE_INTERVAL:
		return
	
	_position_update_timer = 0.0
	_last_position = position
	
	if _websocket and _websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var player = PlayerManager.player
		if not player:
			return
			
		# Get sprite data for animation sync
		var sprite_data = {}
		if player.has_node("Sprite2D"):
			var sprite = player.get_node("Sprite2D")
			sprite_data = {
				"texture": sprite.texture.resource_path if sprite.texture else "",
				"hframes": sprite.hframes,
				"vframes": sprite.vframes,
				"frame": sprite.frame,
				"scale_x": sprite.scale.x
			}
			
			# Add weapon texture if available
			if player.has_node("Sprite2D/Sprite2D_Weapon_Below"):
				var weapon = player.get_node("Sprite2D/Sprite2D_Weapon_Below")
				if weapon.texture:
					sprite_data["weapon_texture"] = weapon.texture.resource_path
		
		var message = {
			"type": "player_move",
			"x": position.x,
			"y": position.y,
			"sprite_data": sprite_data,
			"hp": player.hp,
			"max_hp": player.max_hp,
			"mana": player.mana,
			"max_mana": player.max_mana
		}
		
		var json_string = JSON.stringify(message)
		_websocket.send_text(json_string)


func _process(_delta: float) -> void:
	"""Poll WebSocket for messages"""
	if _websocket:
		_websocket.poll()
		
		var state = _websocket.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			while _websocket.get_available_packet_count():
				var packet = _websocket.get_packet()
				var json_string = packet.get_string_from_utf8()
				var json = JSON.new()
				var parse_result = json.parse(json_string)
				
				if parse_result == OK:
					var message = json.data
					_handle_websocket_message(message)
		
		elif state == WebSocketPeer.STATE_CLOSED:
			var _code = _websocket.get_close_code()
			var _reason = _websocket.get_close_reason()
			_websocket = null
	pass


func _handle_websocket_message(message: Dictionary) -> void:
	"""Handle incoming WebSocket messages from Node.js server"""
	var msg_type = message.get("type", "")
	# Only print non-movement messages to reduce spam
	if msg_type != "player_moved":
		print("[MP] Received message type: ", msg_type)
	var data = message.get("data", {})
	
	match msg_type:
		"players":
			# List of existing players
			for player_data in data:
				_spawn_nodejs_player(player_data)
		
		"player_joined":
			# New player joined
			print("[MP] Player joined: ", data.get("nickname", "Unknown"), " ID: ", data.get("player_id", -1))
			_spawn_nodejs_player(data)
		
		"player_moved":
			# Player moved
			_update_nodejs_player_position(data)
		
		"player_hp_update":
			# Player HP updated
			print("[NetworkManager] Received player_hp_update message, data:", data)
			_update_nodejs_player_hp(data)
		
		"player_attack":
			# Player attacked - show attack animation
			_handle_player_attack(data)
		
		"player_left":
			# Player left
			_remove_nodejs_player(data.player_id)
		
		"chat":
			# Chat message received (old format)
			print("[MP] Handling OLD chat format")
			_handle_chat_message_received(data)
		
		"chat_message":
			# Chat message received (new format)
			print("[MP] Handling NEW chat_message format")
			_handle_chat_message_received(data)
		
		"chat_error":
			# Chat error
			print("[Chat] Error: ", data.get("error", "Unknown error"))
		
		"monsters":
			# Initial monster list from server
			print("[MP] Received ", data.size(), " monsters from server")
			_spawn_server_monsters(data)
		
		"monster_spawn":
			# New monster spawned (respawn)
			print("[MP] Monster spawned: ID ", int(data.get("monster_id", -1)))
			_spawn_server_monster(data)
		
		"monster_update":
			# Monster HP updated
			_update_server_monster(data)
		
		"monster_death":
			# Monster died
			var monster_id = int(data.get("monster_id", -1))  # Convert to int
			print("[MP] ========== MONSTER DEATH ==========")
			print("[MP] Monster died: ID ", monster_id)
			print("[MP] Current server monsters: ", _server_monsters.keys())
			print("[MP] Has monster? ", _server_monsters.has(monster_id))
			_remove_server_monster(monster_id)
		
		"monster_positions":
			# Bulk position update from server
			_update_monster_positions(data)
		
		# Party system messages
		"party_created":
			PartyManager.handle_party_created(data)
		
		"party_invite_received":
			PartyManager.handle_party_invite_received(data)
		
		"party_invite_sent":
			# Confirmation that invite was sent
			print("[MP] Invite sent to player ", data.get("target_player_id", -1))
		
		"party_member_joined":
			PartyManager.handle_party_member_joined(data)
		
		"party_member_left":
			PartyManager.handle_party_member_left(data)
		
		"party_left":
			PartyManager.handle_party_left(data)
		
		"party_disbanded":
			PartyManager.handle_party_disbanded(data)
		
		"party_kicked":
			PartyManager.handle_party_kicked(data)
		
		# Friend system messages
		"friend_request":
			friend_request.emit(data)
		
		"friend_accepted":
			friend_accepted.emit(data)
		
		"friend_removed":
			friend_removed.emit(data)
		
		"friend_online":
			friend_online.emit(data)
		
		"friend_offline":
			friend_offline.emit(data)
		
		"friend_request_expired":
			friend_request_expired.emit(data)
		
		# Duel system messages
		"duel_request":
			duel_request_received.emit(data)
		
		"duel_accepted":
			duel_accepted.emit(data)
		
		"duel_declined":
			duel_declined.emit(data)
		
		"duel_started":
			duel_started.emit(data)
		
		"duel_ended":
			duel_ended.emit(data)
		
		"player_damaged":
			_handle_player_damaged(data)
		
		"party_leadership_changed":
			PartyManager.handle_party_leadership_changed(data)
		
		"party_member_hp_update":
			print("[NetworkManager] *** RECEIVED party_member_hp_update *** Data:", data)
			PartyManager.handle_party_member_hp_update(data)
		
		"party_error":
			PartyManager.handle_party_error(data)
		
		"gain_xp":
			# Received XP from monster kill
			_handle_xp_gain(data)

	pass


func _spawn_nodejs_player(player_data: Dictionary) -> void:
	print("[MP] _spawn_nodejs_player called with data: ", player_data)
	"""Spawn a remote player from Node.js server"""
	var player_id = player_data.get("player_id", 0)
	
	if player_id == _player_id:
		return  # Don't spawn ourselves
	
	if _peer_id_to_avatar.has(player_id):
		return  # Already spawned
	
	var scene := load("res://Network/remote_avatar.tscn") as PackedScene
	var avatar = scene.instantiate() as Node2D
	avatar.name = "RemoteAvatar_%d" % player_id
	avatar.peer_id = player_id
	
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(avatar)
		_peer_id_to_avatar[player_id] = avatar
		
		if avatar.has_method("set_nickname"):
			avatar.set_nickname(player_data.get("nickname", "Player"))
		
		avatar.global_position = Vector2(player_data.get("x", 0), player_data.get("y", 0))
		
	pass


func _update_nodejs_player_position(data: Dictionary) -> void:
	"""Update remote player position from Node.js server"""
	var player_id = data.get("player_id", 0)
	
	if _peer_id_to_avatar.has(player_id):
		var avatar = _peer_id_to_avatar[player_id]
		if is_instance_valid(avatar):
			# Update position
			avatar.global_position = Vector2(data.get("x", 0), data.get("y", 0))
			
			# Update sprite data (animation, facing direction, etc.)
			if data.has("sprite_data"):
				avatar.set_sprite_data(data.sprite_data)
			
			# Update HP if provided (for real-time HP sync)
			if data.has("hp") and data.has("max_hp"):
				var hp = data.get("hp")
				var max_hp = data.get("max_hp")
				if avatar.has_method("update_hp"):
					avatar.update_hp(hp, max_hp)
				
				# ALWAYS send to party manager (it checks internally if player is in party)
				PartyManager.handle_party_member_hp_update({
					"player_id": player_id,
					"hp": hp,
					"max_hp": max_hp
				})
			
			# Update Mana if provided
			if data.has("mana") and data.has("max_mana"):
				var mana = data.get("mana")
				var max_mana = data.get("max_mana")
				if avatar.has_method("update_mana"):
					avatar.update_mana(mana, max_mana)
	pass

func _update_nodejs_player_hp(data: Dictionary) -> void:
	"""Update remote player HP from Node.js server (immediate HP sync)"""
	var player_id = data.get("player_id", 0)
	var hp = data.get("hp", 100)
	var max_hp = data.get("max_hp", 100)
	
	# Update remote avatar (for target healthbar)
	if _peer_id_to_avatar.has(player_id):
		var avatar = _peer_id_to_avatar[player_id]
		if is_instance_valid(avatar):
			if avatar.has_method("update_hp"):
				avatar.update_hp(hp, max_hp)
	
	# ALWAYS try to update party viewer (it will check if player is in party internally)
	PartyManager.handle_party_member_hp_update({
		"player_id": player_id,
		"hp": hp,
		"max_hp": max_hp
	})
	pass


func _handle_xp_gain(data: Dictionary) -> void:
	"""Handle XP gain from server"""
	var xp = data.get("xp", 0)
	var shared = data.get("shared", false)
	
	# Give XP to player
	if PlayerManager.player:
		PlayerManager.player.xp += xp
		
		# Show notification
		var _message = "+%d XP" % xp
		if shared:
			_message += " (Party)"
		
		# TODO: Show XP notification on screen (using _message)
		print("[XP] Gained ", xp, " XP", " (shared)" if shared else "")
		
		# Check for level up
		_check_level_up()

func _check_level_up() -> void:
	"""Check if player should level up"""
	if not PlayerManager.player:
		return
	
	var xp_needed = PlayerManager.player.level * 25  # 25 XP per level (was 100)
	
	while PlayerManager.player.xp >= xp_needed:
		PlayerManager.player.xp -= xp_needed
		PlayerManager.player.level += 1
		print("[XP] LEVEL UP! Now level ", PlayerManager.player.level)
		# Emit level up signal
		PlayerManager.player_leveled_up.emit()
		# Recalculate XP needed for next level
		xp_needed = PlayerManager.player.level * 25

func _remove_nodejs_player(player_id: int) -> void:
	"""Remove remote player from Node.js server"""
	if _peer_id_to_avatar.has(player_id):
		var avatar = _peer_id_to_avatar[player_id]
		if is_instance_valid(avatar):
			avatar.queue_free()
		_peer_id_to_avatar.erase(player_id)
	pass


# =========================
# HTTP API Functions
# =========================

func http_request(endpoint: String, method: int, data: Dictionary = {}) -> Dictionary:
	"""Make HTTP request to Node.js API"""
	
	var http = HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS  # Allow HTTP requests when game is paused
	add_child(http)
	
	var url = api_url + endpoint
	var headers = [
		"Content-Type: application/json",
		"x-api-key: " + api_key
	]
	
	var json_data = JSON.stringify(data) if data else ""
	
	http.request(url, headers, method, json_data)
	var response = await http.request_completed
	
	http.queue_free()
	
	var result = response[0]
	var _response_code = response[1]
	var body = response[3]
	
	
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("HTTP request failed: %s" % result)
		return {"success": false, "error": "Request failed"}
	
	var body_string = body.get_string_from_utf8()
	
	# Check if response is HTML (404 error page)
	if body_string.begins_with("<!DOCTYPE") or body_string.begins_with("<html"):
		push_error("Server returned HTML instead of JSON - endpoint may not exist. Did you restart the server?")
		return {"success": false, "error": "Endpoint not found - restart server"}
	
	var json = JSON.new()
	var parse_result = json.parse(body_string)
	
	if parse_result != OK:
		push_error("Failed to parse JSON response. Body: " + body_string.substr(0, 200))
		return {"success": false, "error": "Invalid JSON"}
	
	return json.data


func login(username: String, password: String) -> Dictionary:
	"""Login to Node.js server"""
	return await http_request("/auth/login", HTTPClient.METHOD_POST, {
		"username": username,
		"password": password
	})


func register(username: String, password: String, nickname: String = "") -> Dictionary:
	"""Register new account on Node.js server"""
	var data = {
		"username": username,
		"password": password
	}
	# Only include nickname if provided
	if nickname != "":
		data["nickname"] = nickname
	return await http_request("/auth/register", HTTPClient.METHOD_POST, data)


# =========================
# SERVER MONSTER MANAGEMENT
# =========================

var _server_monsters: Dictionary = {}  # monster_id -> Enemy node

func _spawn_server_monsters(monsters_data: Array) -> void:
	"""Spawn multiple monsters from server data"""
	print("[MP] Spawning ", monsters_data.size(), " server monsters")
	for monster_data in monsters_data:
		_spawn_server_monster(monster_data)

func _spawn_server_monster(monster_data: Dictionary) -> void:
	"""Spawn a single monster from server"""
	var monster_id = int(monster_data.get("monster_id", -1))  # Convert to int
	if monster_id == -1:
		print("[MP] ERROR: Invalid monster_id in data: ", monster_data)
		return
	
	# Don't spawn if already exists
	if _server_monsters.has(monster_id):
		print("[MP] Monster ", monster_id, " already spawned, skipping")
		return
	
	# Get the current level/scene
	var level = get_tree().current_scene
	if not level:
		print("[MP] ERROR: No current scene found!")
		return
	
	# Find the Enemies node
	var enemies_node = level.get_node_or_null("Enemies")
	if not enemies_node:
		# Try to spawn directly in level as fallback
		enemies_node = level
	
	# Load enemy scene based on type
	var enemy_scene_path = "res://Enemies/Slime/slime.tscn"  # Default to slime
	var enemy_scene = load(enemy_scene_path)
	if not enemy_scene:
		print("[MP] ERROR: Failed to load enemy scene: ", enemy_scene_path)
		return
	
	# Spawn the enemy
	var enemy = enemy_scene.instantiate()
	enemy.global_position = Vector2(monster_data.get("x", 0), monster_data.get("y", 0))
	enemy.hp = monster_data.get("hp", 30)
	enemy.max_hp = monster_data.get("max_hp", 30)
	enemy.set_meta("server_monster_id", monster_id)
	enemy.set_meta("is_server_monster", true)
	enemy.set_meta("server_controlled", true)  # Flag for disabling local behavior
	
	# Connect to enemy damage signal to send to server
	if enemy.has_signal("enemy_damaged"):
		enemy.enemy_damaged.connect(_on_server_monster_damaged.bind(monster_id))
	
	enemies_node.add_child(enemy)
	
	# IMPORTANT: Set collision layers and connect signals after adding to tree
	await get_tree().process_frame
	if is_instance_valid(enemy):
		# DISABLE LOCAL AI - Server controls all behavior
		if enemy.has_node("EnemyStateMachine"):
			var state_machine = enemy.get_node("EnemyStateMachine")
			state_machine.set_process(false)
			state_machine.set_physics_process(false)
			print("[MP] Disabled AI for server monster ID ", monster_id)
		
		# Disable physics processing to prevent knockback/velocity
		enemy.set_physics_process(false)
		enemy.velocity = Vector2.ZERO
		
		# Set collision layers
		if enemy.has_node("HitBox"):
			var hitbox = enemy.get_node("HitBox")
			hitbox.collision_layer = 256  # Enemy layer
			hitbox.collision_mask = 0
			
			# CRITICAL: Connect the Damaged signal to _take_damage
			# This might not be connected if _ready() hasn't run yet
			if not hitbox.Damaged.is_connected(enemy._take_damage):
				hitbox.Damaged.connect(enemy._take_damage)
	_server_monsters[monster_id] = enemy
	
	# Wait for enemy to be ready, then start its animation
	await get_tree().process_frame
	if is_instance_valid(enemy):
		# Make sure sprite is visible
		if enemy.has_node("Sprite2D"):
			var sprite = enemy.get_node("Sprite2D")
			sprite.visible = true
		
		# Start animation
		if enemy.has_node("AnimationPlayer"):
			var anim_player = enemy.get_node("AnimationPlayer")
			if anim_player.has_animation("idle_down"):
				anim_player.play("idle_down")
			elif anim_player.has_animation("idle"):
				anim_player.play("idle")
	
	print("[MP] Spawned server monster ID ", monster_id, " at ", enemy.global_position)

func _update_server_monster(monster_data: Dictionary) -> void:
	"""Update monster HP from server"""
	var monster_id = int(monster_data.get("monster_id", -1))  # Convert to int
	if not _server_monsters.has(monster_id):
		return
	
	var enemy = _server_monsters[monster_id]
	if is_instance_valid(enemy):
		var new_hp = monster_data.get("hp", enemy.hp)
		var new_max_hp = monster_data.get("max_hp", enemy.max_hp)
		
		# Use update_hp to properly update health bar
		if enemy.has_method("update_hp"):
			enemy.update_hp(new_hp, new_max_hp)
		else:
			enemy.hp = new_hp
			enemy.max_hp = new_max_hp

func _update_monster_positions(positions_data: Array) -> void:
	"""Update monster positions from server (Phase 1.2)"""
	for pos_data in positions_data:
		var monster_id = int(pos_data.get("monster_id", -1))
		if _server_monsters.has(monster_id):
			var enemy = _server_monsters[monster_id]
			if is_instance_valid(enemy):
				var target_pos = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
				var current_pos = enemy.global_position
				
				# Only update if there's significant movement (more than 2 pixels)
				var distance = current_pos.distance_to(target_pos)
				if distance > 2.0:
					# Smooth interpolation to target position
					enemy.global_position = current_pos.lerp(target_pos, 0.3)
					
					# Update animation based on movement direction
					var movement = target_pos - current_pos
					_update_monster_animation(enemy, movement)
				else:
					# Monster is idle - play idle animation
					_set_monster_idle(enemy)

func _update_monster_animation(enemy: Node2D, movement: Vector2) -> void:
	"""Update monster animation based on movement direction"""
	if not enemy.has_node("AnimationPlayer"):
		return
	
	var anim_player = enemy.get_node("AnimationPlayer")
	var sprite = enemy.get_node_or_null("Sprite2D")
	
	# Determine direction
	var direction = "down"
	var flip_h = false
	
	if abs(movement.x) > abs(movement.y):
		# Horizontal movement
		if movement.x > 0:
			direction = "right"
			flip_h = false  # Face right (normal)
		else:
			direction = "right"  # Use right animation
			flip_h = true   # Flip to face left
	else:
		# Vertical movement
		direction = "down" if movement.y > 0 else "up"
		flip_h = false
	
	# Update sprite flip
	if sprite:
		sprite.flip_h = flip_h
	
	# Play walk animation in that direction
	var anim_name = "walk_" + direction
	if anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)

func _set_monster_idle(enemy: Node2D) -> void:
	"""Set monster to idle animation"""
	if not enemy.has_node("AnimationPlayer"):
		return
	
	var anim_player = enemy.get_node("AnimationPlayer")
	
	# Play idle animation (default to idle_down)
	if anim_player.current_animation and anim_player.current_animation.begins_with("walk"):
		# Switch from walk to idle
		if anim_player.has_animation("idle_down"):
			anim_player.play("idle_down")
		elif anim_player.has_animation("idle"):
			anim_player.play("idle")

func _remove_server_monster(monster_id: int) -> void:
	"""Remove a dead monster"""
	print("[MP] _remove_server_monster called for ID ", monster_id)
	print("[MP] Monster exists in dict? ", _server_monsters.has(monster_id))
	
	if _server_monsters.has(monster_id):
		var enemy = _server_monsters[monster_id]
		print("[MP] Found enemy node: ", enemy)
		print("[MP] Enemy is valid? ", is_instance_valid(enemy))
		
		if is_instance_valid(enemy):
			# Immediately disable collision and AI so it can't attack
			enemy.set_physics_process(false)
			enemy.set_process(false)
			if enemy.has_node("HitBox"):
				enemy.get_node("HitBox").monitoring = false
				enemy.get_node("HitBox").monitorable = false
			
			# Hide the monster immediately
			enemy.visible = false
			print("[MP] Monster hidden")
			
			# Play death animation if available (visual only)
			if enemy.has_node("AnimationPlayer"):
				var anim_player = enemy.get_node("AnimationPlayer")
				if anim_player.has_animation("destroy_down"):
					enemy.visible = true  # Show for death animation
					anim_player.play("destroy_down")
					# Wait for animation then free
					await anim_player.animation_finished
			
			# Free the monster
			if is_instance_valid(enemy):
				enemy.queue_free()
				print("[MP] Monster freed")
		
		# Remove from tracking
		_server_monsters.erase(monster_id)
		print("[MP] Removed dead monster ID ", monster_id, " from tracking")
	else:
		print("[MP] ERROR: Monster ID ", monster_id, " not found in _server_monsters!")
		print("[MP] Available monster IDs: ", _server_monsters.keys())

func _on_server_monster_damaged(hurt_box, monster_id: int) -> void:
	"""Called when player damages a server monster"""
	if not _websocket or _websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	
	var damage = hurt_box.damage if hurt_box else 10
	
	# Send damage to server
	send_websocket_message({
		"type": "monster_damage",
		"data": {
			"monster_id": monster_id,
			"damage": damage
		}
	})
	
	print("[MP] Sent monster damage: ID ", monster_id, " damage ", damage)

func _handle_player_attack(data: Dictionary) -> void:
	"""Handle player attack event from server"""
	var player_id = data.get("player_id", 0)
	var attack_type = data.get("attack_type", "basic")
	var direction_data = data.get("direction", {"x": 0, "y": 1})
	var direction = Vector2(direction_data.get("x", 0), direction_data.get("y", 1))
	
	# Find the remote avatar and play attack animation
	if _peer_id_to_avatar.has(player_id):
		var avatar = _peer_id_to_avatar[player_id]
		if is_instance_valid(avatar) and avatar.has_method("play_attack_animation"):
			avatar.play_attack_animation(attack_type, direction)
			print("[MP] Player ", player_id, " attacked with ", attack_type)

# =========================
# PLAYER CHARACTER MANAGEMENT
# =========================

func update_player_character_class(player_id: int, character_class: String, god_id: int = 0, character_slot: int = 1) -> void:
	"""Update player's character class and god in database"""
	
	# Validate inputs
	if player_id <= 0:
		push_error("Invalid player_id: " + str(player_id))
		return
	
	var request_data = {
		"player_id": player_id,
		"character_slot": character_slot,
		"character_class": character_class
	}
	
	# Add god_id if provided
	if god_id > 0:
		request_data["god_id"] = god_id
		print("[NetworkManager] Updating character with god_id: ", god_id)
	
	var result = await http_request("/player/update-class", HTTPClient.METHOD_POST, request_data)
	
	if result.has("success") and result.success:
		# Update PlayerManager to reflect the save
		PlayerManager.character_class = character_class
		if god_id > 0:
			GodManager.select_god(god_id)
		print("[NetworkManager] ✓ Character class and god saved for slot ", character_slot)
	else:
		# Only show error if not a deletion operation
		if character_class != "":
			push_error("✗ Failed to save character class: " + str(result.get("error", "Unknown error")))


func save_player_data(player_data: Dictionary) -> Dictionary:
	"""Save player data to Node.js server"""
	return await http_request("/player/save", HTTPClient.METHOD_POST, player_data)


# =========================
# CHAT SYSTEM
# =========================

func _handle_chat_message_received(data: Dictionary) -> void:
	"""Handle incoming chat message from server"""
	var channel = data.get("channel", "global")
	var player_id = data.get("player_id", 0)
	var nickname = data.get("nickname", "Unknown")
	var message = data.get("message", "")
	var timestamp = data.get("timestamp", "")
	
	print("[Chat] *** RECEIVED MESSAGE FROM SERVER ***")
	print("[Chat] Channel: ", channel)
	print("[Chat] Player ID: ", player_id)
	print("[Chat] Nickname: ", nickname)
	print("[Chat] Message: ", message)
	print("[Chat] Timestamp: ", timestamp)
	
	# Forward to chat panel
	var chat_panel = get_tree().get_first_node_in_group("chat_panel")
	print("[Chat] Chat panel found: ", chat_panel != null)
	
	if chat_panel and chat_panel.has_method("add_message"):
		print("[Chat] Calling add_message on chat panel...")
		chat_panel.add_message(channel, player_id, nickname, message, timestamp)
		print("[Chat] Message added to chat panel!")
	else:
		print("[Chat] ERROR: Chat panel not found or doesn't have add_message method!")


# =========================
# DUEL SYSTEM
# =========================

signal duel_request_received(data: Dictionary)
signal duel_accepted(data: Dictionary)
signal duel_declined(data: Dictionary)
signal duel_started(data: Dictionary)
signal duel_ended(data: Dictionary)

func send_duel_request(target_player_id: int) -> void:
	"""Send duel request to another player"""
	if not _websocket or _websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("[NetworkManager] Cannot send duel request - not connected")
		return
	
	var message = {
		"type": "duel_request",
		"target_player_id": target_player_id
	}
	
	var json_string = JSON.stringify(message)
	_websocket.send_text(json_string)
	print("[NetworkManager] Duel request sent to player ID: ", target_player_id)

func accept_duel_request(requester_id: int) -> void:
	"""Accept a duel request"""
	if not _websocket or _websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("[NetworkManager] Cannot accept duel - not connected")
		return
	
	var message = {
		"type": "duel_accept",
		"requester_id": requester_id
	}
	
	var json_string = JSON.stringify(message)
	_websocket.send_text(json_string)
	print("[NetworkManager] Duel accepted from player ID: ", requester_id)

func decline_duel_request(requester_id: int) -> void:
	"""Decline a duel request"""
	if not _websocket or _websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("[NetworkManager] Cannot decline duel - not connected")
		return
	
	var message = {
		"type": "duel_decline",
		"requester_id": requester_id
	}
	
	var json_string = JSON.stringify(message)
	_websocket.send_text(json_string)
	print("[NetworkManager] Duel declined from player ID: ", requester_id)


func _handle_player_damaged(data: Dictionary):
	"""Handle receiving damage from another player"""
	print("[NetworkManager] *** RECEIVED PLAYER_DAMAGED MESSAGE ***")
	print("[NetworkManager] Data: ", data)
	
	var attacker_name = data.get("attacker_name", "Unknown")
	var damage = data.get("damage", 0)
	var new_hp = data.get("new_hp", 0)
	var max_hp = data.get("max_hp", 100)
	
	print("[NetworkManager] Received damage from ", attacker_name, ": ", damage, " damage")
	print("[NetworkManager] New HP should be: ", new_hp, "/", max_hp)
	
	# Update local player HP
	var player = PlayerManager.player
	if player:
		print("[NetworkManager] Current HP: ", player.hp, " -> New HP: ", new_hp)
		
		# Calculate HP delta
		var hp_delta = new_hp - player.hp
		print("[NetworkManager] HP delta: ", hp_delta)
		
		# Use player's update_hp function which handles all updates
		player.update_hp(hp_delta)
		
		print("[NetworkManager] HP after update: ", player.hp, "/", player.max_hp)
	else:
		print("[NetworkManager] ERROR: Player not found!")
