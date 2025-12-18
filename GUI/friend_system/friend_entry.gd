extends HBoxContainer

# Friend Entry
# Individual friend row in the friend list

signal whisper_requested(friend_id: int, friend_name: String)
signal party_invite_requested(friend_id: int)
signal remove_requested(friend_id: int)

@onready var status_indicator = $StatusIndicator
@onready var friend_name_label = $FriendName
@onready var level_label = $Level

var friend_id: int = -1
var friend_name: String = ""
var is_online: bool = false

var context_menu: PopupMenu

func _ready():
	# Create context menu
	context_menu = PopupMenu.new()
	add_child(context_menu)
	context_menu.add_item("Whisper", 0)
	context_menu.add_item("Invite to Party", 1)
	context_menu.add_separator()
	context_menu.add_item("Remove Friend", 2)
	context_menu.id_pressed.connect(_on_context_menu_selected)
	
	# Left-click to show context menu (right-click is for walking)
	gui_input.connect(_on_gui_input)

func setup(data: Dictionary):
	"""Setup friend entry with data"""
	friend_id = data.get("id", -1)
	friend_name = data.get("nickname", "Unknown")
	is_online = data.get("online", false)
	var level = data.get("level", 1)
	
	friend_name_label.text = friend_name
	level_label.text = "Lv." + str(level)
	
	# Update status indicator
	if is_online:
		status_indicator.modulate = Color(0, 1, 0)  # Green
	else:
		status_indicator.modulate = Color(0.5, 0.5, 0.5)  # Gray

func update_online_status(online: bool):
	"""Update online status"""
	is_online = online
	if is_online:
		status_indicator.modulate = Color(0, 1, 0)  # Green
	else:
		status_indicator.modulate = Color(0.5, 0.5, 0.5)  # Gray

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			context_menu.position = get_global_mouse_position()
			context_menu.popup()

func _on_context_menu_selected(id: int):
	match id:
		0:  # Whisper
			whisper_requested.emit(friend_id, friend_name)
		1:  # Invite to Party
			party_invite_requested.emit(friend_id)
		2:  # Remove Friend
			remove_requested.emit(friend_id)
