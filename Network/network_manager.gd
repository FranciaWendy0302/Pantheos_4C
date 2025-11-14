extends Node

signal connected(mode: String)
signal disconnected_signal()
signal peer_joined(peer_id: int, nickname: String)
signal peer_left(peer_id: int)

const DEFAULT_PORT: int = 9000
const SNAPSHOT_INTERVAL_S: float = 0.05
const MAX_PEERS: int = 3

var _is_server: bool = false
var _mode: String = "party" # "party" or "duel"
var _nickname: String = ""
var _peer_id_to_name: Dictionary = {}
var _peer_id_to_avatar: Dictionary = {}
var _peer_id_to_hp: Dictionary = {}  # Track HP for duel mode

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

# =========================
# Server control (headless)
# =========================

func start_server(port: int = DEFAULT_PORT) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PEERS)
	if err != OK:
		push_error("Failed to start ENet server: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	_is_server = true
	print("Server started on port %d" % port)
	pass

# =========================
# Client-side snapshot loop
# =========================

func _on_connected_to_server() -> void:
	_snapshot_timer.start()
	_register_on_server.rpc_id(1, _nickname, _mode)
	_setup_pvp_mode()
	connected.emit(_mode)
	pass

func _setup_pvp_mode() -> void:
	# In duel mode, enable player attacks to hit other players
	if _mode == "duel" and PlayerManager.player and is_instance_valid(PlayerManager.player):
		# Get all HurtBox nodes from player
		var hurt_boxes = _get_all_hurt_boxes(PlayerManager.player)
		for hurt_box in hurt_boxes:
			if hurt_box is HurtBox:
				# Add layer 2 (player HitBox layer) to collision mask
				hurt_box.collision_mask |= 2
	pass

func _get_all_hurt_boxes(node: Node) -> Array:
	var hurt_boxes: Array = []
	if node is HurtBox:
		hurt_boxes.append(node)
	for child in node.get_children():
		hurt_boxes.append_array(_get_all_hurt_boxes(child))
	return hurt_boxes

func _on_connection_failed() -> void:
	push_error("Connection failed")
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
		# Send weapon sprite data
		if PlayerManager.player.sprite.has_node("Sprite2D_Weapon_Below"):
			var weapon_below = PlayerManager.player.sprite.get_node("Sprite2D_Weapon_Below")
			if weapon_below.texture:
				sprite_data["weapon_texture"] = weapon_below.texture.resource_path
		if PlayerManager.player.sprite.has_node("Sprite2D_Weapon_Above"):
			var weapon_above = PlayerManager.player.sprite.get_node("Sprite2D_Weapon_Above")
			if weapon_above.texture:
				sprite_data["weapon_texture"] = weapon_above.texture.resource_path
	_send_transform_to_server.rpc(pos, dir, sprite_data, hp, max_hp)
	pass

# =========================
# Server/Client RPCs
# =========================

@rpc("any_peer", "reliable", "call_local")
func _register_on_server(nickname: String, _mode_unused: String) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	_peer_id_to_name[sender] = nickname
	# Notify everyone of the new peer
	_peer_joined_client.rpc(sender, nickname)
	# Send existing peers to the new one
	for pid in _peer_id_to_name.keys():
		if pid != sender:
			_peer_joined_client.rpc_id(sender, pid, _peer_id_to_name[pid])
	pass

@rpc("authority", "reliable", "call_local")
func _peer_joined_client(peer_id: int, nickname: String) -> void:
	peer_joined.emit(peer_id, nickname)
	_peer_id_to_name[peer_id] = nickname
	_spawn_or_update_avatar(peer_id, nickname, Vector2.ZERO, Vector2.DOWN, {})
	pass

@rpc("any_peer", "unreliable", "call_local")
func _send_transform_to_server(pos: Vector2, dir: Vector2, sprite_data: Dictionary = {}, hp: int = 10, max_hp: int = 10) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	# Store HP on server
	_peer_id_to_hp[sender] = {"hp": hp, "max_hp": max_hp}
	# Broadcast to all except sender
	for pid in multiplayer.get_peers():
		if pid == sender:
			continue
		_broadcast_peer_transform.rpc_id(pid, sender, pos, dir, sprite_data, hp, max_hp)
	pass

@rpc("authority", "unreliable", "call_local")
func _broadcast_peer_transform(peer_id: int, pos: Vector2, dir: Vector2, sprite_data: Dictionary = {}, hp: int = 10, max_hp: int = 10) -> void:
	_spawn_or_update_avatar(peer_id, _peer_id_to_name.get(peer_id, "Player"), pos, dir, sprite_data, hp, max_hp)
	pass

func _on_peer_connected(id: int) -> void:
	# Server-side bookkeeping only
	if multiplayer.is_server():
		print("Peer connected: %d" % id)
	pass

func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		print("Peer disconnected: %d" % id)
		_peer_id_to_name.erase(id)
	_peer_left_client.rpc(id)
	pass

@rpc("authority", "reliable", "call_local")
func _peer_left_client(peer_id: int) -> void:
	peer_left.emit(peer_id)
	if _peer_id_to_avatar.has(peer_id):
		var avatar: Node2D = _peer_id_to_avatar[peer_id]
		if is_instance_valid(avatar):
			avatar.queue_free()
		_peer_id_to_avatar.erase(peer_id)
	pass

# =========================
# Remote avatars
# =========================

func _spawn_or_update_avatar(peer_id: int, nickname: String, pos: Vector2, _dir: Vector2, sprite_data: Dictionary = {}, hp: int = 10, max_hp: int = 10) -> void:
	# Skip avatar spawning on headless server
	if _is_server:
		return
	
	var avatar: Node2D = null
	if _peer_id_to_avatar.has(peer_id) and is_instance_valid(_peer_id_to_avatar[peer_id]):
		avatar = _peer_id_to_avatar[peer_id]
	else:
		var current_scene = get_tree().current_scene
		if not current_scene:
			return
		var scene: PackedScene = load("res://Network/remote_avatar.tscn")
		avatar = scene.instantiate()
		avatar.name = "RemoteAvatar_%d" % peer_id
		avatar.peer_id = peer_id
		current_scene.add_child(avatar)
		_peer_id_to_avatar[peer_id] = avatar
		if avatar.has_method("set_nickname"):
			avatar.set_nickname(nickname)
	avatar.global_position = pos
	if not sprite_data.is_empty() and avatar.has_method("set_sprite_data"):
		avatar.set_sprite_data(sprite_data)
	if avatar.has_method("update_hp"):
		avatar.update_hp(hp, max_hp)
	pass

func _cleanup_all_avatars() -> void:
	for pid in _peer_id_to_avatar.keys():
		var avatar: Node2D = _peer_id_to_avatar[pid]
		if is_instance_valid(avatar):
			avatar.queue_free()
	_peer_id_to_avatar.clear()
	pass

# =========================
# PvP Combat (Duel Mode)
# =========================

@rpc("any_peer", "reliable", "call_local")
func _report_remote_avatar_damage(target_peer_id: int, damage: int) -> void:
	# Server receives damage report from a client about hitting a remote avatar
	if not multiplayer.is_server():
		return
	
	# Apply damage to the target peer's HP
	if _peer_id_to_hp.has(target_peer_id):
		var hp_data = _peer_id_to_hp[target_peer_id]
		hp_data["hp"] = max(0, hp_data["hp"] - damage)
		_peer_id_to_hp[target_peer_id] = hp_data
		
		# Notify the target peer that they took damage
		_apply_damage_to_player.rpc_id(target_peer_id, damage)
	pass

@rpc("authority", "reliable", "call_local")
func _apply_damage_to_player(damage: int) -> void:
	# Client receives notification that they took damage
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		PlayerManager.player.update_hp(-damage)
	pass
