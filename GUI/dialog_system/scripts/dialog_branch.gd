class_name DialogBranch
extends DialogItem

@export var condition_variable: String = ""
@export var condition_value: Variant
@export var true_dialog_id: String = ""
@export var false_dialog_id: String = ""

func _init():
	super._init()