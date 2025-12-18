class_name QuestStepItem
extends Control

@export var step_text: String = ""
@export var is_completed: bool = false

func _init():
	pass

func set_step_completed(completed: bool):
	is_completed = completed