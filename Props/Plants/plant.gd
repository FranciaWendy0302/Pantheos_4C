class_name Plant extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	$HitBox.Damaged.connect(TakeDamage)
	pass
	
func TakeDamage(_damage: HurtBox) -> void:
	animation_player.play("destroy")
	await animation_player.animation_finished
	queue_free()
	pass
	
