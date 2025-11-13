class_name PersistentDataHandler extends Node

signal data_loaded
var value: bool = false

func _ready() -> void:
	get_value()
	pass
	
func set_value() -> void:
	SaveManager.add_persistent_value(_get_name())
	pass

func get_value() -> void:
	value = SaveManager.check_persistent_value(_get_name())
	data_loaded.emit()
	pass

func remove_value() -> void:
	SaveManager.remove_persistent_value(_get_name())
	pass

func _get_name() -> String:
	#"res://levels/area01/01.tscn"
	var current_scene = get_tree().current_scene
	if not current_scene or not is_instance_valid(current_scene):
		return ""
	
	var scene_path = current_scene.get("scene_file_path")
	if scene_path == null or not scene_path is String:
		return ""
	
	return scene_path + "/" + get_parent().name + "/" + name
