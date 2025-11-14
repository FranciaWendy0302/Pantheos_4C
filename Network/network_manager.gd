extends Node

signal connected(mode: String)
signal disconnected_signal()
signal peer_joined(peer_id: int, nickname: String)
signal peer_left(peer_id: int)

const DEFAULT_PORT: int = 9000
const SNAPSHOT_INTERVAL_S: float = 0.05
const MAX_PEERS: int = 3

var _is_server: bool = false
var _mode: String = "party"
var _nickname: String = ""
var _peer_id_to_name: Dictionary = {}
var _peer_id_to_avatar: Dictionary = {}
var _peer_id_to_hp: Dictionary = {}
var _peer_id_to_map: Dictionary = {}  # Track which map each player is in
var _current_map: String = ""  # Client's current map

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
	print("Server started on port %d" % port)
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

func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		print("Peer connected: %d" % id)
	pass


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		print("Peer disconnected: %d" % id)
		_peer_id_to_name.erase(id)

	_peer_left_client.rpc(id)
	pass
