extends Node2D

## Server-side monster spawner for MMORPG
## Place this in your maps to spawn monsters
## Only runs on server, clients receive spawned entities

@export var monster_scene: PackedScene
@export var spawn_count: int = 5
@export var spawn_radius: float = 100.0
@export var respawn_time: float = 30.0
@export var is_quest_monster: bool = false
@export var quest_owner_peer_id: int = -1

var _spawned_entities: Array[int] = []

func _ready() -> void:
	if not multiplayer.is_server():
		# Clients don't spawn - they receive from server
		queue_free()
		return
	
	# Server spawns monsters
	_spawn_initial_monsters()
	
	# Listen for entity deaths to respawn
	EntityManager.entity_despawned.connect(_on_entity_despawned)


func _spawn_initial_monsters() -> void:
	for i in range(spawn_count):
		_spawn_monster()


func _spawn_monster() -> void:
	if not monster_scene:
		push_error("No monster scene assigned to spawner")
		return
	
	# Random position around spawner
	var angle = randf() * TAU
	var distance = randf() * spawn_radius
	var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * distance
	
	# Get current map path
	var map_path = get_tree().current_scene.scene_file_path
	
	# Determine visibility
	var visibility = EntityManager.VisibilityRule.MAP_ONLY
	if is_quest_monster:
		visibility = EntityManager.VisibilityRule.OWNER_ONLY
	
	# Spawn via EntityManager
	var entity_id = EntityManager.server_spawn_entity(
		monster_scene.resource_path,
		spawn_pos,
		map_path,
		EntityManager.EntityType.MONSTER,
		visibility,
		quest_owner_peer_id,
		{
			"hp": 100,
			"max_hp": 100,
			"spawner": get_path()
		}
	)
	
	_spawned_entities.append(entity_id)
	print("[Spawner] Spawned monster entity %d" % entity_id)


func _on_entity_despawned(entity_id: int) -> void:
	if entity_id in _spawned_entities:
		_spawned_entities.erase(entity_id)
		
		# Respawn after delay
		if respawn_time > 0:
			await get_tree().create_timer(respawn_time).timeout
			_spawn_monster()
