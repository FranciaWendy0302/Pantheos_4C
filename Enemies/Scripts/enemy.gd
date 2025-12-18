class_name Enemy
extends CharacterBody2D

@export var max_health: int = 100
@export var current_health: int = 100
@export var attack_damage: int = 10
@export var defense: int = 5
@export var xp_reward: int = 25

signal enemy_died(enemy: Enemy)
signal health_changed(current: int, maximum: int)

func _init():
	pass

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()

func die():
	enemy_died.emit(self)
	queue_free()