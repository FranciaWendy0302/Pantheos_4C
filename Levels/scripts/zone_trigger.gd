extends Area2D
class_name ZoneTrigger

## Zone Trigger - Detects when player enters a zone
## Place this in your map to define zone boundaries

@export var zone_name: String = "Safe Zone"
@export_enum("Safe Zone", "Black Zone") var zone_type: String = "Safe Zone"
@export var show_notification: bool = true

func _ready():
	# Connect to body entered signal
	body_entered.connect(_on_body_entered)
	
	# Set collision layer/mask
	collision_layer = 0
	collision_mask = 1  # Detect player layer
	
	print("[ZoneTrigger] Zone trigger ready: ", zone_name, " (", zone_type, ")")

func _on_body_entered(body: Node2D) -> void:
	# Check if it's the player
	if body.name == "Player" or body.is_in_group("player"):
		_trigger_zone_change(body)

func _trigger_zone_change(player: Node2D) -> void:
	"""Change the zone when player enters"""
	var zone_type_enum = ZoneManager.ZoneType.SAFE_ZONE
	
	if zone_type == "Black Zone":
		zone_type_enum = ZoneManager.ZoneType.BLACK_ZONE
	
	# Update zone manager
	ZoneManager.set_zone(zone_name, zone_type_enum)
	
	# Show notification
	if show_notification and PlayerHud:
		var zone_color = "[color=green]" if zone_type == "Safe Zone" else "[color=red]"
		var zone_msg = "Entered: " + zone_color + zone_name + "[/color]"
		
		if zone_type == "Black Zone":
			PlayerHud.queue_notificaiton("⚔️ PvP Zone", "You entered a hostile area! Players can attack you here.")
		else:
			PlayerHud.queue_notificaiton("🛡️ Safe Zone", "You are now safe from PvP.")
	
	print("[ZoneTrigger] Player entered zone: ", zone_name)
