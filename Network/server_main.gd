extends Node

@export var port: int = 9000

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Start ENet server via NetworkManager singleton
	if not Engine.is_editor_hint():
		if not has_node("/root/NetworkManager"):
			var nm: Node = load("res://Network/network_manager.gd").new()
			nm.name = "NetworkManager"
			get_tree().root.add_child(nm)
		var manager: Node = get_node("/root/NetworkManager")
		if manager and manager.has_method("start_server"):
			manager.start_server(port)
		else:
			push_error("NetworkManager not available; cannot start server.")
	pass


