extends Node

## Manages switching between offline (local save) and online (MySQL) modes

func _ready() -> void:
	# Connect to network events
	if NetworkManager:
		NetworkManager.connected.connect(_on_connected_to_server)
		NetworkManager.disconnected_signal.connect(_on_disconnected_from_server)


func _on_connected_to_server(_mode: String) -> void:
	"""When connected to server, enable online mode"""
	print("[OnlineMode] Connected to server - enabling online mode")
	SaveManager.enable_online_mode()
	
	# Disable local auto-save
	print("[OnlineMode] Local save/load disabled - using MySQL database")


func _on_disconnected_from_server() -> void:
	"""When disconnected from server, disable online mode"""
	print("[OnlineMode] Disconnected from server - disabling online mode")
	SaveManager.disable_online_mode()
	
	# Re-enable local save/load
	print("[OnlineMode] Local save/load re-enabled")


func force_enable_online_mode() -> void:
	"""Manually enable online mode (for testing)"""
	SaveManager.enable_online_mode()


func force_disable_online_mode() -> void:
	"""Manually disable online mode (for testing)"""
	SaveManager.disable_online_mode()
