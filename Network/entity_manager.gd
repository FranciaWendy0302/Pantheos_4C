extends Node

## Server-authoritative entity manager for MMORPG
## Handles spawning, syncing, and despawning of all networked entities

signal entity_spawned(entity_id: int, entity_data: Dictionary)
signal entity_despawned(entity_id: int)

# Entity types
enum EntityType {
	MONSTER,
	NPC,
	ITEM,
	QUEST_OBJECT
}

# Visibility rules
enum VisibilityRule {
	GLOBAL,        # Everyone can see
	MAP_ONLY,      # Only players in same map
	OWNER_ONLY,    # Only specific player
	PARTY_ONLY     # Only party members
}

# Server-side entity registry
var _entities: Dictionary = {}  # entity_id -> entity_data
var _next_entity_id: int = 1000

# Client-side entity instances
var _entity_instances: Dictionary = {}  # entity_id -> Node2D instance

func _ready() -> void:
	if multiplayer.is_server():
		print("[EntityManager] Running in SERVER mode")
	else:
		print("[EntityManager] Running in CLIENT mode")
	pass


# =========================
# SERVER: Entity Spawning
# =========================

func server_spawn_entity(scene_path: String, position: Vector2, map_path: String, 
						 entity_type: EntityType, visibility: VisibilityRule, 
						 owner_peer_id: int = -1, custom_data: Dictionary = {}) -> int:
	"""
	SERVER ONLY: Spawn an entity and broadcast to relevant clients
	Returns: entity_id
	"""
	if not multiplayer.is_server():
		push_error("server_spawn_entity can only be called on server")
		return -1
	
	var entity_id = _next_entity_id
	_next_entity_id += 1
	
	var entity_data = {
		"id": entity_id,
		"scene_path": scene_path,
		"position": position,
		"map_path": map_path,
		"entity_type": entity_type,
		"visibility": visibility,
		"owner_peer_id": owner_peer_id,
		"custom_data": custom_data,
		"hp": custom_data.get("hp", 100),
		"max_hp": custom_data.get("max_hp", 100),
		"is_alive": true
	}
	
	_entities[entity_id] = entity_data
	
	# Broadcast to relevant clients
	_broadcast_entity_spawn(entity_data)
	
	print("[Server] Spawned entity %d (%s) at %s" % [entity_id, scene_path, map_path])
	return entity_id


func server_despawn_entity(entity_id: int) -> void:
	"""SERVER ONLY: Despawn an entity"""
	if not multiplayer.is_server():
		return
	
	if not _entities.has(entity_id):
		return
	
	_entities.erase(entity_id)
	
	# Broadcast despawn to all clients
	_rpc_despawn_entity.rpc(entity_id)
	
	print("[Server] Despawned entity %d" % entity_id)


func server_update_entity(entity_id: int, position: Vector2, hp: int = -1) -> void:
	"""SERVER ONLY: Update entity state and broadcast"""
	if not multiplayer.is_server():
		return
	
	if not _entities.has(entity_id):
		return
	
	var entity = _entities[entity_id]
	entity["position"] = position
	
	if hp >= 0:
		entity["hp"] = hp
		if hp <= 0:
			entity["is_alive"] = false
	
	# Broadcast to relevant clients
	_broadcast_entity_update(entity)


func server_damage_entity(entity_id: int, damage: int, attacker_peer_id: int) -> bool:
	"""SERVER ONLY: Apply damage to entity. Returns true if entity died"""
	if not multiplayer.is_server():
		return false
	
	if not _entities.has(entity_id):
		return false
	
	var entity = _entities[entity_id]
	entity["hp"] = max(0, entity["hp"] - damage)
	
	print("[Server] Entity %d took %d damage (HP: %d/%d)" % [entity_id, damage, entity["hp"], entity["max_hp"]])
	
	if entity["hp"] <= 0:
		entity["is_alive"] = false
		_handle_entity_death(entity_id, attacker_peer_id)
		return true
	
	# Broadcast HP update
	_broadcast_entity_update(entity)
	return false


func _handle_entity_death(entity_id: int, killer_peer_id: int) -> void:
	"""Handle entity death - drop loot, give XP, etc."""
	var _entity = _entities[entity_id]
	
	print("[Server] Entity %d died, killed by peer %d" % [entity_id, killer_peer_id])
	
	# Broadcast death
	_rpc_entity_died.rpc(entity_id, killer_peer_id)
	
	# Despawn after delay
	await get_tree().create_timer(2.0).timeout
	server_despawn_entity(entity_id)


func _broadcast_entity_spawn(entity_data: Dictionary) -> void:
	"""Broadcast entity spawn to relevant clients"""
	var visibility = entity_data["visibility"]
	var map_path = entity_data["map_path"]
	var owner_id = entity_data["owner_peer_id"]
	
	for peer_id in multiplayer.get_peers():
		var should_send = false
		
		match visibility:
			VisibilityRule.GLOBAL:
				should_send = true
			VisibilityRule.MAP_ONLY:
				# Check if peer is in same map
				if NetworkManager._peer_id_to_map.get(peer_id, "") == map_path:
					should_send = true
			VisibilityRule.OWNER_ONLY:
				if peer_id == owner_id:
					should_send = true
			VisibilityRule.PARTY_ONLY:
				# TODO: Implement party check
				should_send = true
		
		if should_send:
			_rpc_spawn_entity.rpc_id(peer_id, entity_data)


func _broadcast_entity_update(entity_data: Dictionary) -> void:
	"""Broadcast entity update to relevant clients"""
	var visibility = entity_data["visibility"]
	var map_path = entity_data["map_path"]
	var owner_id = entity_data["owner_peer_id"]
	
	for peer_id in multiplayer.get_peers():
		var should_send = false
		
		match visibility:
			VisibilityRule.GLOBAL:
				should_send = true
			VisibilityRule.MAP_ONLY:
				if NetworkManager._peer_id_to_map.get(peer_id, "") == map_path:
					should_send = true
			VisibilityRule.OWNER_ONLY:
				if peer_id == owner_id:
					should_send = true
		
		if should_send:
			_rpc_update_entity.rpc_id(peer_id, entity_data["id"], entity_data["position"], entity_data["hp"])


# =========================
# CLIENT: Entity Rendering
# =========================

@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_entity(entity_data: Dictionary) -> void:
	"""CLIENT: Receive entity spawn from server"""
	var entity_id = entity_data["id"]
	
	if _entity_instances.has(entity_id):
		return  # Already spawned
	
	var scene = load(entity_data["scene_path"]) as PackedScene
	if not scene:
		push_error("Failed to load entity scene: %s" % entity_data["scene_path"])
		return
	
	var instance = scene.instantiate()
	instance.name = "Entity_%d" % entity_id
	instance.global_position = entity_data["position"]
	
	# Store entity ID on the instance
	instance.set_meta("entity_id", entity_id)
	instance.set_meta("entity_data", entity_data)
	
	# Add to scene
	get_tree().current_scene.add_child(instance)
	_entity_instances[entity_id] = instance
	
	entity_spawned.emit(entity_id, entity_data)
	print("[Client] Spawned entity %d" % entity_id)


@rpc("authority", "call_remote", "unreliable")
func _rpc_update_entity(entity_id: int, position: Vector2, hp: int) -> void:
	"""CLIENT: Receive entity update from server"""
	if not _entity_instances.has(entity_id):
		return
	
	var instance = _entity_instances[entity_id]
	if not is_instance_valid(instance):
		_entity_instances.erase(entity_id)
		return
	
	# Smooth movement
	instance.global_position = position
	
	# Update HP if entity has update_hp method
	if hp >= 0 and instance.has_method("update_hp"):
		var entity_data = instance.get_meta("entity_data", {})
		var max_hp = entity_data.get("max_hp", 100)
		instance.update_hp(hp, max_hp)


@rpc("authority", "call_remote", "reliable")
func _rpc_despawn_entity(entity_id: int) -> void:
	"""CLIENT: Receive entity despawn from server"""
	if not _entity_instances.has(entity_id):
		return
	
	var instance = _entity_instances[entity_id]
	if is_instance_valid(instance):
		instance.queue_free()
	
	_entity_instances.erase(entity_id)
	entity_despawned.emit(entity_id)
	print("[Client] Despawned entity %d" % entity_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_entity_died(entity_id: int, _killer_peer_id: int) -> void:
	"""CLIENT: Entity died notification"""
	if not _entity_instances.has(entity_id):
		return
	
	var instance = _entity_instances[entity_id]
	if is_instance_valid(instance):
		# Play death animation
		if instance.has_method("play_death_animation"):
			instance.play_death_animation()
		
		# Show death effect
		print("[Client] Entity %d died" % entity_id)


# =========================
# CLIENT: Combat Actions
# =========================

func client_attack_entity(entity_id: int, damage: int) -> void:
	"""CLIENT: Request to attack an entity"""
	if multiplayer.is_server():
		return
	
	_rpc_request_attack.rpc_id(1, entity_id, damage)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_attack(entity_id: int, damage: int) -> void:
	"""SERVER: Receive attack request from client"""
	if not multiplayer.is_server():
		return
	
	var attacker_id = multiplayer.get_remote_sender_id()
	
	# Validate attack (distance, cooldown, etc.)
	# For now, just apply damage
	server_damage_entity(entity_id, damage, attacker_id)


# =========================
# Utility
# =========================

func get_entities_in_map(map_path: String) -> Array:
	"""Get all entity IDs in a specific map"""
	var result: Array = []
	for entity_id in _entities:
		if _entities[entity_id]["map_path"] == map_path:
			result.append(entity_id)
	return result


func cleanup_all_entities() -> void:
	"""Clean up all entities (on disconnect)"""
	for entity_id in _entity_instances.keys():
		var instance = _entity_instances[entity_id]
		if is_instance_valid(instance):
			instance.queue_free()
	
	_entity_instances.clear()
	
	if multiplayer.is_server():
		_entities.clear()
