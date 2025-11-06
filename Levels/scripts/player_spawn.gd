extends Node2D

func _ready() -> void:
	visible = false
	# Wait for level to fully load
	await LevelManager.level_loaded
	
	# Check if this is the target spawn point from LevelManager
	# If target_transition matches this node's name, or if player hasn't spawned yet
	if LevelManager.target_transition == name or (LevelManager.target_transition == "" and PlayerManager.player_spawned == false):
		# Set player position to this spawn point
		PlayerManager.set_player_position(global_position)
		PlayerManager.player_spawned = true
		# Reset target_transition so it doesn't affect other spawns
		if LevelManager.target_transition == name:
			LevelManager.target_transition = ""
