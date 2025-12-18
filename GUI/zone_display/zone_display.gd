extends Control

## Zone Display - Shows current zone name on HUD

@onready var zone_label: Label = $ZoneLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_zone_name: String = ""

func _ready():
	# Connect to zone manager signals
	if ZoneManager:
		ZoneManager.zone_changed.connect(_on_zone_changed)
	
	# Set initial zone
	_update_zone_display(ZoneManager.get_zone_name(), ZoneManager.get_zone_type())

func _on_zone_changed(zone_name: String, zone_type: int) -> void:
	"""Update display when zone changes"""
	_update_zone_display(zone_name, zone_type)
	
	# Play animation
	if animation_player and animation_player.has_animation("zone_change"):
		animation_player.play("zone_change")

func _update_zone_display(zone_name: String, zone_type: int) -> void:
	"""Update the zone label"""
	current_zone_name = zone_name
	
	if not zone_label:
		return
	
	zone_label.text = zone_name
	
	# Color based on zone type
	if zone_type == ZoneManager.ZoneType.SAFE_ZONE:
		zone_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1.0))  # Green
	else:
		zone_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1.0))  # Red
