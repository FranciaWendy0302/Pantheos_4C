extends Node

# Zone types
enum ZoneType {
	SAFE_ZONE,      # No PvP, safe area
	BLACK_ZONE      # PvP enabled, hostile area
}

# Current zone info
var current_zone_name: String = "Safe Zone"
var current_zone_type: ZoneType = ZoneType.SAFE_ZONE

# Signals
signal zone_changed(zone_name: String, zone_type: ZoneType)
signal entered_safe_zone()
signal entered_black_zone()

func _ready():
	print("[ZoneManager] Initialized")

func set_zone(zone_name: String, zone_type: ZoneType) -> void:
	"""Change the current zone"""
	var old_zone = current_zone_name
	var old_type = current_zone_type
	
	current_zone_name = zone_name
	current_zone_type = zone_type
	
	print("[ZoneManager] Zone changed: ", old_zone, " -> ", zone_name, " (", _zone_type_to_string(zone_type), ")")
	
	# Emit signals
	zone_changed.emit(zone_name, zone_type)
	
	if zone_type == ZoneType.SAFE_ZONE and old_type != ZoneType.SAFE_ZONE:
		entered_safe_zone.emit()
	elif zone_type == ZoneType.BLACK_ZONE and old_type != ZoneType.BLACK_ZONE:
		entered_black_zone.emit()

func is_safe_zone() -> bool:
	"""Check if current zone is safe"""
	return current_zone_type == ZoneType.SAFE_ZONE

func is_black_zone() -> bool:
	"""Check if current zone is a black zone (PvP enabled)"""
	return current_zone_type == ZoneType.BLACK_ZONE

func can_pvp() -> bool:
	"""Check if PvP is allowed in current zone"""
	return current_zone_type == ZoneType.BLACK_ZONE

func get_zone_name() -> String:
	"""Get current zone name"""
	return current_zone_name

func get_zone_type() -> ZoneType:
	"""Get current zone type"""
	return current_zone_type

func _zone_type_to_string(zone_type: ZoneType) -> String:
	"""Convert zone type to string for debugging"""
	match zone_type:
		ZoneType.SAFE_ZONE:
			return "Safe Zone"
		ZoneType.BLACK_ZONE:
			return "Black Zone"
		_:
			return "Unknown"
