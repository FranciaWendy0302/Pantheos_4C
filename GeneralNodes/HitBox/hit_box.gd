class_name HitBox extends Area2D

signal Damaged(hurt_box: HurtBox)

func _ready():
	# Enable mouse input for clicking on enemies
	input_pickable = true
	
func TakeDamage(hurt_box: HurtBox) -> void:
	Damaged.emit(hurt_box)
