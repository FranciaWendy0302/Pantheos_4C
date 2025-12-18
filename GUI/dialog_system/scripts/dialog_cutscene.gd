class_name DialogCutscene
extends DialogItem

@export var cutscene_path: String = ""
@export var wait_for_completion: bool = true

func _init():
	super._init()