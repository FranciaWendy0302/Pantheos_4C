class_name HurtBox
extends Area2D

@export var health_component: Node
@export var damage_multiplier: float = 1.0

signal damage_taken(amount: int)

func _init():
	pass

func take_damage(amount: int):
	var final_damage = int(amount * damage_multiplier)
	damage_taken.emit(final_damage)
	
	if health_component and health_component.has_method("take_damage"):
		health_component.take_damage(final_damage)