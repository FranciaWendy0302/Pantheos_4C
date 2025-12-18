extends Node2D
class_name ArcaneWeave

# Arcane Weave buff effect - enhances spell power

var duration: float = 5.0
var spell_power_bonus: float = 0.25  # 25% spell power increase
var player: Node2D = null

func _ready():
	# Auto-cleanup after duration
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self):
		queue_free()

func setup(target_player: Node2D, buff_duration: float = 5.0):
	"""Setup the arcane weave effect on player"""
	player = target_player
	duration = buff_duration
	
	# Position at player
	if player:
		global_position = player.global_position
	
	print("[ArcaneWeave] Buff applied for %.1fs - Spell power +%.0f%%" % [duration, spell_power_bonus * 100])

func _process(delta):
	# Follow player
	if player and is_instance_valid(player):
		global_position = player.global_position

func _on_timer_timeout():
	queue_free()
