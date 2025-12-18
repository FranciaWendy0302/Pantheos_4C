extends Node2D
class_name WaveSpawner

## Wave-based enemy spawner for Trial of the Gods quest

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed

@export var enemy_scene: PackedScene  # Assign enemy scene in inspector
@export var spawn_radius: float = 300.0
@export var waves: Array[Dictionary] = [
	{"enemy_count": 10, "spawn_delay": 2.0},  # Wave 1
	{"enemy_count": 15, "spawn_delay": 1.5},  # Wave 2
	{"enemy_count": 20, "spawn_delay": 1.0}   # Wave 3
]

var current_wave: int = 0
var enemies_spawned: int = 0
var enemies_alive: int = 0
var is_active: bool = false
var spawn_timer: Timer

func _ready():
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_spawn_next_enemy)

func start_trial():
	"""Start the wave trial"""
	if is_active:
		return
	
	is_active = true
	current_wave = 0
	print("[WaveSpawner] Trial started!")
	_start_next_wave()

func _start_next_wave():
	"""Start the next wave"""
	if current_wave >= waves.size():
		_complete_trial()
		return
	
	var wave_data = waves[current_wave]
	enemies_spawned = 0
	enemies_alive = 0
	
	print("[WaveSpawner] Starting Wave %d - %d enemies" % [current_wave + 1, wave_data.enemy_count])
	wave_started.emit(current_wave + 1)
	
	# Start spawning enemies
	spawn_timer.wait_time = wave_data.spawn_delay
	spawn_timer.start()

func _spawn_next_enemy():
	"""Spawn the next enemy in the current wave"""
	if current_wave >= waves.size():
		return
	
	var wave_data = waves[current_wave]
	
	if enemies_spawned >= wave_data.enemy_count:
		spawn_timer.stop()
		return
	
	_spawn_enemy()
	enemies_spawned += 1

func _spawn_enemy():
	"""Spawn a single enemy"""
	if not enemy_scene:
		print("[WaveSpawner] ERROR: No enemy scene assigned!")
		return
	
	var enemy = enemy_scene.instantiate()
	
	# Random position around spawner
	var angle = randf() * TAU
	var distance = randf_range(spawn_radius * 0.5, spawn_radius)
	var spawn_pos = position + Vector2(cos(angle), sin(angle)) * distance
	
	enemy.position = spawn_pos
	get_parent().add_child(enemy)
	enemies_alive += 1
	
	# Connect to enemy death signal
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	
	print("[WaveSpawner] Spawned enemy at %s (Wave %d: %d/%d)" % [spawn_pos, current_wave + 1, enemies_spawned, waves[current_wave].enemy_count])

func _on_enemy_died():
	"""Called when an enemy dies"""
	enemies_alive -= 1
	print("[WaveSpawner] Enemy died. Remaining: %d" % enemies_alive)
	
	# Check if wave is complete
	if enemies_alive <= 0 and enemies_spawned >= waves[current_wave].enemy_count:
		_complete_wave()

func _complete_wave():
	"""Complete the current wave"""
	print("[WaveSpawner] Wave %d completed!" % (current_wave + 1))
	wave_completed.emit(current_wave + 1)
	
	current_wave += 1
	
	# Wait a bit before next wave
	await get_tree().create_timer(3.0).timeout
	
	if current_wave < waves.size():
		_start_next_wave()
	else:
		_complete_trial()

func _complete_trial():
	"""Complete all waves"""
	is_active = false
	print("[WaveSpawner] All waves completed! Trial finished!")
	all_waves_completed.emit()
	
	# Give quest completion
	_complete_quest()

func _complete_quest():
	"""Mark the Trial of the Gods quest as complete"""
	# Update quest system
	var quest_manager = get_node_or_null("/root/QuestManager")
	if quest_manager and quest_manager.has_method("complete_quest"):
		quest_manager.complete_quest("trial_of_gods")
	
	# Show notification
	var player_hud = get_tree().get_first_node_in_group("player_hud")
	if player_hud and player_hud.has_node("Control/Notification"):
		var notification = player_hud.get_node("Control/Notification")
		if notification.has_method("show_notification"):
			notification.show_notification("Quest Completed: Trial of the Gods!\n+500 XP\nReturn to your god for your reward!")
	
	# Give XP to player
	if PlayerManager.player:
		PlayerManager.player.add_xp(500)
