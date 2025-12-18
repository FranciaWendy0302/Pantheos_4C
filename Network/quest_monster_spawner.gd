extends Node

## Helper for spawning quest-specific monsters that only the quest owner can see

static func spawn_quest_monster(monster_scene: PackedScene, position: Vector2, owner_peer_id: int, parent: Node) -> Node:
	"""
	Spawn a monster that only the quest owner can see
	
	Args:
		monster_scene: The monster scene to spawn
		position: Where to spawn it
		owner_peer_id: The peer ID of the player who owns this quest
		parent: The parent node to add the monster to
	
	Returns:
		The spawned monster instance
	"""
	var monster = monster_scene.instantiate()
	
	# Add NetworkEntity component if it doesn't exist
	if not monster.has_node("NetworkEntity"):
		var net_entity = NetworkEntity.new()
		net_entity.name = "NetworkEntity"
		net_entity.visibility_mode = NetworkEntity.VisibilityMode.OWNER_ONLY
		net_entity.owner_peer_id = owner_peer_id
		monster.add_child(net_entity)
	
	monster.global_position = position
	parent.add_child(monster)
	
	return monster


static func spawn_global_monster(monster_scene: PackedScene, position: Vector2, parent: Node) -> Node:
	"""
	Spawn a normal monster that everyone can see and attack
	
	Args:
		monster_scene: The monster scene to spawn
		position: Where to spawn it
		parent: The parent node to add the monster to
	
	Returns:
		The spawned monster instance
	"""
	var monster = monster_scene.instantiate()
	
	# Add NetworkEntity component if it doesn't exist
	if not monster.has_node("NetworkEntity"):
		var net_entity = NetworkEntity.new()
		net_entity.name = "NetworkEntity"
		net_entity.visibility_mode = NetworkEntity.VisibilityMode.GLOBAL
		monster.add_child(net_entity)
	
	monster.global_position = position
	parent.add_child(monster)
	
	return monster
