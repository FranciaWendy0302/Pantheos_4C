extends Node

## EXAMPLE: How to spawn monsters with network visibility
## Copy these examples into your actual spawning code

# ============================================
# EXAMPLE 1: Spawning a NORMAL monster
# Everyone in the same map can see and attack it
# ============================================
func spawn_normal_monster_example():
	var slime_scene = preload("res://Enemies/Slime/slime.tscn")
	var spawn_position = Vector2(100, 100)
	
	# Use the helper function
	var monster = QuestMonsterSpawner.spawn_global_monster(
		slime_scene,
		spawn_position,
		get_tree().current_scene
	)
	
	print("Spawned normal monster that everyone can see")


# ============================================
# EXAMPLE 2: Spawning a QUEST-SPECIFIC monster
# Only the quest owner can see it
# ============================================
func spawn_quest_monster_example():
	var goblin_scene = preload("res://Enemies/goblin/goblin.tscn")
	var spawn_position = Vector2(200, 200)
	
	# Get the current player's peer ID (the quest owner)
	var quest_owner_id = multiplayer.get_unique_id()
	
	# Use the helper function
	var monster = QuestMonsterSpawner.spawn_quest_monster(
		goblin_scene,
		spawn_position,
		quest_owner_id,
		get_tree().current_scene
	)
	
	print("Spawned quest monster - only peer %d can see it" % quest_owner_id)


# ============================================
# EXAMPLE 3: Spawning for a SPECIFIC player
# (e.g., when server spawns a quest monster for a client)
# ============================================
func spawn_quest_monster_for_player(player_peer_id: int):
	var slime_scene = preload("res://Enemies/Slime/slime.tscn")
	var spawn_position = Vector2(300, 300)
	
	# Spawn for a specific player
	var monster = QuestMonsterSpawner.spawn_quest_monster(
		slime_scene,
		spawn_position,
		player_peer_id,  # This specific player will see it
		get_tree().current_scene
	)
	
	print("Spawned quest monster for peer %d" % player_peer_id)


# ============================================
# EXAMPLE 4: Manual setup (if you need more control)
# ============================================
func spawn_with_manual_setup():
	var slime_scene = preload("res://Enemies/Slime/slime.tscn")
	var monster = slime_scene.instantiate()
	
	# Add NetworkEntity component manually
	var net_entity = NetworkEntity.new()
	net_entity.name = "NetworkEntity"
	net_entity.visibility_mode = NetworkEntity.VisibilityMode.OWNER_ONLY
	net_entity.owner_peer_id = multiplayer.get_unique_id()
	monster.add_child(net_entity)
	
	monster.global_position = Vector2(400, 400)
	get_tree().current_scene.add_child(monster)
	
	print("Spawned with manual NetworkEntity setup")


# ============================================
# EXAMPLE 5: Integration with quest system
# ============================================
func on_quest_started(quest_title: String):
	# When a quest starts, spawn quest-specific monsters
	if quest_title == "Kill 5 Slimes":
		var slime_scene = preload("res://Enemies/Slime/slime.tscn")
		var quest_owner_id = multiplayer.get_unique_id()
		
		# Spawn 5 quest slimes
		for i in range(5):
			var spawn_pos = Vector2(100 + i * 50, 100)
			QuestMonsterSpawner.spawn_quest_monster(
				slime_scene,
				spawn_pos,
				quest_owner_id,
				get_tree().current_scene
			)
		
		print("Spawned 5 quest slimes for player %d" % quest_owner_id)


# ============================================
# EXAMPLE 6: World monster spawner
# ============================================
func spawn_world_monsters():
	# These are normal monsters that spawn in the world
	# Everyone can see and attack them
	var slime_scene = preload("res://Enemies/Slime/slime.tscn")
	
	var spawn_points = [
		Vector2(100, 100),
		Vector2(200, 150),
		Vector2(300, 200),
	]
	
	for pos in spawn_points:
		QuestMonsterSpawner.spawn_global_monster(
			slime_scene,
			pos,
			get_tree().current_scene
		)
	
	print("Spawned %d world monsters" % spawn_points.size())
