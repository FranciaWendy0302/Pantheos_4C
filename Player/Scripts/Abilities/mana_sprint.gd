extends Node2D
class_name ManaSprint

# Mana Sprint buff effect - boosts movement speed

var duration: float = 3.0
var speed_bonus: float = 0.3  # 30% speed increase
var player: Node2D = null
var original_speed: float = 0.0

func _ready():
	# Auto-cleanup after duration
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self):
		_remove_buff()
		queue_free()

func setup(target_player: Node2D, buff_duration: float = 3.0):
	"""Setup the mana sprint effect on player"""
	player = target_player
	duration = buff_duration
	
	# Position at player's feet
	if player:
		global_position = player.global_position
		
		# Apply speed buff to walk state
		var state_machine = player.get_node_or_null("StateMachine")
		if state_machine:
			var walk_state = state_machine.get_node_or_null("Walk")
			if walk_state and "move_speed" in walk_state:
				original_speed = walk_state.move_speed
				walk_state.move_speed *= (1.0 + speed_bonus)
				print("[ManaSprint] Speed boosted: %.0f -> %.0f (+%.0f%%)" % [original_speed, walk_state.move_speed, speed_bonus * 100])
			else:
				print("[ManaSprint] WARNING: Walk state not found or no move_speed property")
		else:
			print("[ManaSprint] WARNING: StateMachine not found")
	
	print("[ManaSprint] Buff applied for %.1fs" % duration)

func _process(delta):
	# Follow player's feet
	if player and is_instance_valid(player):
		global_position = player.global_position + Vector2(0, 10)

func _remove_buff():
	"""Remove speed buff when effect ends"""
	if player and is_instance_valid(player):
		var state_machine = player.get_node_or_null("StateMachine")
		if state_machine:
			var walk_state = state_machine.get_node_or_null("Walk")
			if walk_state and "move_speed" in walk_state:
				walk_state.move_speed = original_speed
				print("[ManaSprint] Speed restored to %.0f" % original_speed)

func _on_timer_timeout():
	_remove_buff()
	queue_free()
