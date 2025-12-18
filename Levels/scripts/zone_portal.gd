extends Area2D
class_name ZonePortal

## Zone Portal - Teleports player to another map/zone
## Use this for the 5 exits from safe zone to black zones

@export var target_scene_path: String = ""
@export var spawn_position: Vector2 = Vector2.ZERO
@export var portal_name: String = "Portal"
@export var requires_confirmation: bool = true
@export var warning_message: String = "Enter dangerous zone?"

var player_in_range: bool = false
var current_player: Node2D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	collision_layer = 0
	collision_mask = 1
	
	print("[ZonePortal] Portal ready: ", portal_name, " -> ", target_scene_path)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = true
		current_player = body
		_show_portal_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = false
		current_player = null
		_hide_portal_prompt()

func _input(event: InputEvent) -> void:
	if not player_in_range or not current_player:
		return
	
	# Press E to use portal
	if event.is_action_pressed("interact"):
		_use_portal()

func _use_portal() -> void:
	"""Teleport player through portal"""
	if target_scene_path.is_empty():
		print("[ZonePortal] ERROR: No target scene set!")
		return
	
	if requires_confirmation:
		# TODO: Show confirmation dialog
		print("[ZonePortal] Confirmation required for: ", portal_name)
		_teleport_player()
	else:
		_teleport_player()

func _teleport_player() -> void:
	"""Actually teleport the player"""
	print("[ZonePortal] Teleporting to: ", target_scene_path)
	
	# Use LevelManager to load the new zone
	if LevelManager:
		LevelManager.load_new_level(target_scene_path, "", spawn_position)
	else:
		# Fallback: direct scene change
		get_tree().change_scene_to_file(target_scene_path)

func _show_portal_prompt() -> void:
	"""Show 'Press E to enter' prompt"""
	if PlayerHud:
		PlayerHud.queue_notificaiton("🚪 " + portal_name, "Press E to enter")

func _hide_portal_prompt() -> void:
	"""Hide portal prompt"""
	pass
