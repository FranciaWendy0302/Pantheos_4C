class_name Player
extends CharacterBody2D

@export var max_health: int = 100
@export var current_health: int = 100
@export var max_mana: int = 50
@export var current_mana: int = 50
@export var level: int = 1
@export var experience: int = 0
@export var move_speed: float = 200.0

signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal level_changed(new_level: int)
signal experience_changed(current: int, required: int)

func _init():
	pass

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func consume_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana, max_mana)
		return true
	return false

func restore_mana(amount: int):
	current_mana = min(max_mana, current_mana + amount)
	mana_changed.emit(current_mana, max_mana)