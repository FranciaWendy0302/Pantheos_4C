extends HBoxContainer

# Single party member health entry
# Minimal display: name + health bar

@onready var name_label: Label = $NameLabel
@onready var hp_bar: ProgressBar = $HPBar

var player_id: int = -1

func setup(member_data: Dictionary) -> void:
	"""Setup the member entry with data"""
	player_id = member_data.get("id", -1)
	var username = member_data.get("username", "Unknown")
	var hp = member_data.get("hp", 100)
	var max_hp = member_data.get("max_hp", 100)
	
	# Update UI
	name_label.text = username
	update_hp(hp, max_hp)

func update_hp(hp: int, max_hp: int) -> void:
	"""Update the health bar"""
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	
	# Color based on HP percentage
	var hp_percent = float(hp) / float(max_hp)
	if hp_percent > 0.6:
		hp_bar.modulate = Color(0, 1, 0)  # Green
	elif hp_percent > 0.3:
		hp_bar.modulate = Color(1, 1, 0)  # Yellow
	else:
		hp_bar.modulate = Color(1, 0, 0)  # Red

func get_player_id() -> int:
	"""Get the player ID for this entry"""
	return player_id
