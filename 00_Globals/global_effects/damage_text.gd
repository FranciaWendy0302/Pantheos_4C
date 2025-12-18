class_name DamageText
extends Label

@export var damage_amount: int = 0
@export var float_speed: float = 50.0
@export var fade_duration: float = 1.0

func _init():
	pass

func setup_damage_text(damage: int, position: Vector2):
	damage_amount = damage
	text = str(damage)
	global_position = position
	
	# Create tween for floating and fading effect
	var tween = create_tween()
	tween.parallel().tween_property(self, "global_position", global_position + Vector2(0, -50), fade_duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(queue_free)