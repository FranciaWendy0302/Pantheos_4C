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
	connected.emit(_mode)
	pass

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
	var sprite_data: Dictionary = {}
	if PlayerManager.player.sprite and PlayerManager.player.sprite.texture:
		sprite_data["texture"] = PlayerManager.player.sprite.texture.resource_path
		sprite_data["hframes"] = PlayerManager.player.sprite.hframes
		sprite_data["vframes"] = PlayerManager.player.sprite.vframes
		sprite_data["frame"] = PlayerManager.player.sprite.frame
		sprite_data["flip_h"] = PlayerManager.player.sprite.flip_h
	_send_transform_to_server.rpc(pos, dir, sprite_data)
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
func _send_transform_to_server(pos: Vector2, dir: Vector2, sprite_data: Dictionary = {}) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	# Broadcast to all except sender
	for pid in multiplayer.get_peers():
		if pid == sender:
			continue
		_broadcast_peer_transform.rpc_id(pid, sender, pos, dir, sprite_data)
	pass

@rpc("authority", "unreliable", "call_local")
func _broadcast_peer_transform(peer_id: int, pos: Vector2, dir: Vector2, sprite_data: Dictionary = {}) -> void:
	_spawn_or_update_avatar(peer_id, _peer_id_to_name.get(peer_id, "Player"), pos, dir, sprite_data)
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

func _spawn_or_update_avatar(peer_id: int, nickname: String, pos: Vector2, dir: Vector2, sprite_data: Dictionary = {}) -> void:
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
		current_scene.add_child(avatar)
		_peer_id_to_avatar[peer_id] = avatar
		if avatar.has_method("set_nickname"):
			avatar.set_nickname(nickname)
	avatar.global_position = pos
	if not sprite_data.is_empty() and avatar.has_method("set_sprite_data"):
		avatar.set_sprite_data(sprite_data)
	pass

func _cleanup_all_avatars() -> void:
	for pid in _peer_id_to_avatar.keys():
		var avatar: Node2D = _peer_id_to_avatar[pid]
		if is_instance_valid(avatar):
			avatar.queue_free()
	_peer_id_to_avatar.clear()
	pass
