class_name DialogChoice
extends DialogItem

@export var choices: Array[String] = []
@export var choice_targets: Array[String] = []

func _init():
	super._init()