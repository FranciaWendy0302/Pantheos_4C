extends Node

# God Quest Manager
# Manages 3-wave monster quests for each god

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal quest_completed(god_id: int)
signal monster_killed(monsters_remaining: int)

enum QuestState {
	NOT_STARTED,
	WAVE_1,
	WAVE_2,
	WAVE_3,
	COMPLETED
}

var current_quest_state: QuestState = QuestState.NOT_STARTED
var current_wave: int = 0
var monsters_to_spawn: int = 0
var monsters_spawned: int = 0
var monsters_killed: int = 0
var quest_active: bool = false
var player_god_id: int = 0

# Wave configurations for each god
var god_wave_configs = {
	1: { # Zeus
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	2: { # Poseidon
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	3: { # Hades
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	4: { # Athena
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	5: { # Ares
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	6: { # Apollo
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	7: { # Artemis
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	8: { # Hephaestus
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	9: { # Aphrodite
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	10: { # Hermes
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	11: { # Dionysus
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	12: { # Demeter
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	13: { # Asclepius
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	14: { # Nemesis
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	},
	15: { # Thanatos
		"wave_1": {"monster": "slime", "count": 5},
		"wave_2": {"monster": "goblin", "count": 7},
		"wave_3": {"monster": "orc", "count": 10}
	}
}

func _ready():
	# Get player's selected god
	if GodManager:
		player_god_id = GodManager.get_selected_god()

func start_quest():
	"""Start the god quest"""
	if quest_active:
		print("[GodQuest] Quest already active!")
		return
	
	if player_god_id == 0:
		print("[GodQuest] No god selected!")
		return
	
	print("[GodQuest] Starting quest for god ID: ", player_god_id)
	quest_active = true
	current_wave = 0
	start_next_wave()

func start_next_wave():
	"""Start the next wave"""
	current_wave += 1
	
	if current_wave > 3:
		complete_quest()
		return
	
	# Update quest state
	match current_wave:
		1: current_quest_state = QuestState.WAVE_1
		2: current_quest_state = QuestState.WAVE_2
		3: current_quest_state = QuestState.WAVE_3
	
	# Get wave config
	var wave_key = "wave_" + str(current_wave)
	var wave_config = god_wave_configs[player_god_id][wave_key]
	
	monsters_to_spawn = wave_config["count"]
	monsters_spawned = 0
	monsters_killed = 0
	
	print("[GodQuest] Starting Wave ", current_wave, " - Spawn ", monsters_to_spawn, " ", wave_config["monster"], "s")
	wave_started.emit(current_wave)
	
	# Spawn monsters
	spawn_wave_monsters(wave_config)

func spawn_wave_monsters(wave_config: Dictionary):
	"""Spawn monsters for the current wave"""
	var monster_type = wave_config["monster"]
	var count = wave_config["count"]
	
	# Get player position for spawning around them
	var player = PlayerManager.player
	if not player:
		print("[GodQuest] ERROR: Player not found!")
		return
	
	var player_pos = player.global_position
	
	# Spawn monsters in a circle around player
	for i in range(count):
		var angle = (TAU / count) * i
		var offset = Vector2(cos(angle), sin(angle)) * 200.0  # 200 pixels away
		var spawn_pos = player_pos + offset
		
		spawn_monster(monster_type, spawn_pos)
		monsters_spawned += 1

func spawn_monster(monster_type: String, position: Vector2):
	"""Spawn a single monster"""
	# This will be implemented based on your monster spawning system
	# For now, send request to server
	if NetworkManager and NetworkManager._websocket:
		var message = {
			"type": "spawn_quest_monster",
			"monster_type": monster_type,
			"x": position.x,
			"y": position.y,
			"quest_monster": true
		}
		var json_string = JSON.stringify(message)
		NetworkManager._websocket.send_text(json_string)
		print("[GodQuest] Requested spawn: ", monster_type, " at ", position)

func on_monster_killed():
	"""Called when a quest monster is killed"""
	monsters_killed += 1
	var remaining = monsters_to_spawn - monsters_killed
	
	print("[GodQuest] Monster killed! ", monsters_killed, "/", monsters_to_spawn, " (", remaining, " remaining)")
	monster_killed.emit(remaining)
	
	# Check if wave is complete
	if monsters_killed >= monsters_to_spawn:
		complete_wave()

func complete_wave():
	"""Complete the current wave"""
	print("[GodQuest] Wave ", current_wave, " completed!")
	wave_completed.emit(current_wave)
	
	# Wait a bit before starting next wave
	await get_tree().create_timer(3.0).timeout
	
	if current_wave < 3:
		start_next_wave()
	else:
		complete_quest()

func complete_quest():
	"""Complete the entire quest"""
	print("[GodQuest] Quest completed!")
	quest_active = false
	current_quest_state = QuestState.COMPLETED
	quest_completed.emit(player_god_id)
	
	# Unlock god skill
	if GodManager:
		GodManager.unlock_god_skill()
	
	# Give rewards
	give_quest_rewards()

func give_quest_rewards():
	"""Give rewards for completing the quest"""
	var player = PlayerManager.player
	if not player:
		return
	
	# Give XP
	var xp_reward = 1000
	player.xp += xp_reward
	print("[GodQuest] Rewarded ", xp_reward, " XP")
	
	# Give currency
	var gold_reward = 500
	player.currency += gold_reward
	print("[GodQuest] Rewarded ", gold_reward, " gold")
	
	# Show notification
	var player_hud = get_tree().get_first_node_in_group("player_hud")
	if player_hud:
		# TODO: Show quest complete notification
		pass

func is_quest_active() -> bool:
	return quest_active

func get_current_wave() -> int:
	return current_wave

func get_monsters_remaining() -> int:
	return monsters_to_spawn - monsters_killed
