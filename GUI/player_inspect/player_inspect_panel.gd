extends Panel

# Player Inspection Panel
# Shows detailed info about a player

@onready var close_button = $MarginContainer/VBoxContainer/Header/CloseButton
@onready var player_name_label = $MarginContainer/VBoxContainer/Content/PlayerName
@onready var level_label = $MarginContainer/VBoxContainer/Content/Level
@onready var class_label = $MarginContainer/VBoxContainer/Content/Class
@onready var hp_label = $MarginContainer/VBoxContainer/Content/HP
@onready var mana_label = $MarginContainer/VBoxContainer/Content/Mana
@onready var vbox_container = $MarginContainer/VBoxContainer

var dragging = false
var drag_offset = Vector2.ZERO
var current_player_id: int = -1
var add_friend_button: Button = null
var duel_button: Button = null

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	
	# Create action buttons dynamically if they don't exist
	_create_action_buttons()
	
	hide()

func _create_action_buttons():
	"""Create the action buttons (Add Friend, Duel) dynamically"""
	# Check if Actions container exists
	var actions_container = vbox_container.get_node_or_null("Actions")
	
	if not actions_container:
		# Create separator
		var separator = HSeparator.new()
		separator.name = "HSeparator2"
		vbox_container.add_child(separator)
		
		# Create Actions container
		actions_container = HBoxContainer.new()
		actions_container.name = "Actions"
		actions_container.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox_container.add_child(actions_container)
		print("[PlayerInspect] Created Actions container")
	
	# Create Add Friend button
	add_friend_button = actions_container.get_node_or_null("AddFriendButton")
	if not add_friend_button:
		add_friend_button = Button.new()
		add_friend_button.name = "AddFriendButton"
		add_friend_button.text = "Add Friend"
		actions_container.add_child(add_friend_button)
		print("[PlayerInspect] Created Add Friend button")
	
	# Connect Add Friend signal
	if add_friend_button and not add_friend_button.pressed.is_connected(_on_add_friend_pressed):
		add_friend_button.pressed.connect(_on_add_friend_pressed)
		print("[PlayerInspect] Add Friend button connected successfully")
	
	# Create Duel button
	duel_button = actions_container.get_node_or_null("DuelButton")
	if not duel_button:
		duel_button = Button.new()
		duel_button.name = "DuelButton"
		duel_button.text = "Request Duel"
		actions_container.add_child(duel_button)
		print("[PlayerInspect] Created Duel button")
	
	# Connect Duel signal
	if duel_button and not duel_button.pressed.is_connected(_on_duel_pressed):
		duel_button.pressed.connect(_on_duel_pressed)
		print("[PlayerInspect] Duel button connected successfully")

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check if clicking on header
				var header = $MarginContainer/VBoxContainer/Header
				var header_rect = Rect2(header.global_position, header.size)
				if header_rect.has_point(event.position):
					dragging = true
					drag_offset = position - event.position
			else:
				dragging = false
	
	elif event is InputEventMouseMotion and dragging:
		position = event.position + drag_offset

func show_player_info(player_data: Dictionary):
	"""Display player information"""
	if not player_data:
		print("[PlayerInspect] No player data provided")
		return
	
	current_player_id = player_data.get("id", -1)
	
	player_name_label.text = "Name: " + str(player_data.get("nickname", "Unknown"))
	level_label.text = "Level: " + str(player_data.get("level", 1))
	class_label.text = "Class: " + str(player_data.get("class", "Warrior"))
	
	# Get real-time HP/MP from remote avatar instead of database
	var hp = player_data.get("hp", 100)
	var max_hp = player_data.get("max_hp", 100)
	var mana = player_data.get("mana", 100)
	var max_mana = player_data.get("max_mana", 100)
	
	# Try to get live stats from remote avatar
	var remote_avatar = _get_remote_avatar_by_id(current_player_id)
	if remote_avatar:
		hp = remote_avatar.hp
		max_hp = remote_avatar.max_hp
		mana = remote_avatar.mana
		max_mana = remote_avatar.max_mana
		print("[PlayerInspect] Using live stats from remote avatar: HP ", hp, "/", max_hp, " MP ", mana, "/", max_mana)
	else:
		print("[PlayerInspect] Remote avatar not found, using database stats")
	
	hp_label.text = "HP: %d / %d" % [hp, max_hp]
	mana_label.text = "Mana: %d / %d" % [mana, max_mana]
	
	# Update action button visibility
	_update_action_buttons()
	
	# Center on screen
	var viewport_size = get_viewport().get_visible_rect().size
	position = (viewport_size - size) / 2
	
	show()
	print("[PlayerInspect] Showing info for: ", player_data.get("nickname", "Unknown"))

func _update_action_buttons():
	"""Update action button visibility based on context"""
	print("[PlayerInspect] Updating action buttons for player ID: ", current_player_id)
	
	if not add_friend_button or not duel_button:
		print("[PlayerInspect] ERROR: Action buttons are null!")
		return
	
	if current_player_id <= 0:
		print("[PlayerInspect] Invalid player ID, hiding buttons")
		add_friend_button.visible = false
		duel_button.visible = false
		return
	
	# Check if player is self
	var is_self = false
	if has_node("/root/PlayerManager"):
		var player_mgr = get_node("/root/PlayerManager")
		print("[PlayerInspect] My player ID: ", player_mgr.player_id, " Target ID: ", current_player_id)
		if player_mgr.player_id == current_player_id:
			is_self = true
			print("[PlayerInspect] Target is self, hiding buttons")
	
	if is_self:
		add_friend_button.visible = false
		duel_button.visible = false
		return
	
	# Update Add Friend button
	var is_already_friend = GlobalFriendManager.is_friend(current_player_id)
	print("[PlayerInspect] Is already friend: ", is_already_friend)
	
	if is_already_friend:
		print("[PlayerInspect] Already friends, hiding Add Friend button")
		add_friend_button.visible = false
	else:
		print("[PlayerInspect] Not friends, showing Add Friend button")
		add_friend_button.visible = true
	
	# Update Duel button - always show for other players (not self)
	duel_button.visible = true
	print("[PlayerInspect] Showing Duel button")

func _on_add_friend_pressed():
	"""Send friend request to the inspected player"""
	if current_player_id > 0:
		print("[PlayerInspect] Sending friend request to player ID: ", current_player_id)
		GlobalFriendManager.send_friend_request(current_player_id)
		add_friend_button.visible = false  # Hide button after sending request

func _on_duel_pressed():
	"""Send duel request to the inspected player"""
	if current_player_id > 0:
		print("[PlayerInspect] Sending duel request to player ID: ", current_player_id)
		NetworkManager.send_duel_request(current_player_id)
		# Hide the panel after sending request
		hide()

func _on_close_pressed():
	hide()


func _get_remote_avatar_by_id(player_id: int) -> Node2D:
	"""Find remote avatar by player ID"""
	var remote_avatars = get_tree().get_nodes_in_group("remote_avatars")
	for avatar in remote_avatars:
		if avatar.has_method("get_player_id") and avatar.get_player_id() == player_id:
			return avatar
		# Fallback: check peer_id property
		if avatar.get("peer_id") == player_id:
			return avatar
	return null
