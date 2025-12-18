extends Control

# Chat system for multiplayer communication
# Supports Global, Party, and Whisper channels

signal chat_opened()
signal chat_closed()

@onready var channel_tabs: TabBar = $VBoxContainer/ChannelTabs
@onready var message_container: VBoxContainer = $VBoxContainer/ScrollContainer/MessageContainer
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var input_field: LineEdit = $VBoxContainer/InputContainer/InputField
@onready var send_button: Button = $VBoxContainer/InputContainer/SendButton

const MAX_MESSAGES = 100
const PLAYER_COLORS = [
	Color(0.3, 0.7, 1.0),  # Blue
	Color(1.0, 0.5, 0.3),  # Orange
	Color(0.5, 1.0, 0.5),  # Green
	Color(1.0, 0.3, 0.7),  # Pink
	Color(0.8, 0.8, 0.3),  # Yellow
	Color(0.7, 0.3, 1.0),  # Purple
	Color(0.3, 1.0, 1.0),  # Cyan
	Color(1.0, 0.7, 0.3),  # Gold
]

var current_channel: String = "global"
var message_history: Array = []
var player_color_map: Dictionary = {}
var is_chat_open: bool = false
var whisper_target_id: int = -1

func _ready() -> void:
	# Tabs are already set up in the scene file
	# Just make sure they're visible
	channel_tabs.visible = true
	
	# Connect signals
	channel_tabs.tab_changed.connect(_on_channel_changed)
	send_button.pressed.connect(_on_send_pressed)
	input_field.text_submitted.connect(_on_text_submitted)
	
	# Hide initially
	visible = false
	is_chat_open = false
	
	# Disable party tab if not in party
	_update_party_tab()
	
	# Connect to party manager signals
	if PartyManager:
		PartyManager.member_joined.connect(_on_party_joined)
		PartyManager.member_left.connect(_on_party_left)
		PartyManager.party_disbanded.connect(_on_party_disbanded)
	
	print("[Chat] Chat system initialized")

func _process(_delta: float) -> void:
	# Toggle chat with Enter/Return key ONLY (not Spacebar)
	if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER):
		if not is_chat_open and Input.is_action_just_pressed("ui_accept"):
			open_chat()
	
	if Input.is_action_just_pressed("ui_cancel") and is_chat_open:
		close_chat()
	
	# Switch channels with Tab key (when chat is open)
	if Input.is_action_just_pressed("ui_focus_next") and is_chat_open:
		var next_tab = (channel_tabs.current_tab + 1) % channel_tabs.tab_count
		channel_tabs.current_tab = next_tab
		_on_channel_changed(next_tab)

func open_chat() -> void:
	"""Open chat and focus input field"""
	visible = true
	is_chat_open = true
	input_field.grab_focus()
	chat_opened.emit()
	print("[Chat] Chat opened")

func close_chat() -> void:
	"""Close chat and clear input"""
	visible = false
	is_chat_open = false
	input_field.text = ""
	input_field.release_focus()
	chat_closed.emit()
	print("[Chat] Chat closed")

func _on_channel_changed(tab_index: int) -> void:
	"""Handle channel tab change"""
	match tab_index:
		0:
			current_channel = "global"
		1:
			current_channel = "party"
		2:
			current_channel = "whisper"
	
	print("[Chat] Switched to channel: ", current_channel)
	
	# Update placeholder text
	match current_channel:
		"global":
			input_field.placeholder_text = "Type message (Global)..."
		"party":
			input_field.placeholder_text = "Type message (Party)..."
		"whisper":
			if whisper_target_id > 0:
				input_field.placeholder_text = "Whisper to player..."
			else:
				input_field.placeholder_text = "Click a player to whisper..."

func _on_send_pressed() -> void:
	"""Send button clicked"""
	_send_message()

func _on_text_submitted(_text: String) -> void:
	"""Enter key pressed in input field"""
	_send_message()

func _send_message() -> void:
	"""Send chat message to server"""
	var message_text = input_field.text.strip_edges()
	
	if message_text.length() == 0:
		return
	
	# Validate channel
	if current_channel == "party" and not PartyManager.is_in_party():
		add_system_message("You are not in a party!")
		input_field.text = ""
		return
	
	if current_channel == "whisper" and whisper_target_id <= 0:
		add_system_message("Click a player to whisper!")
		input_field.text = ""
		return
	
	# Send to server via NetworkManager
	if NetworkManager:
		NetworkManager.send_chat_message(current_channel, message_text, whisper_target_id)
		print("[Chat] Sent message: [", current_channel, "] ", message_text)
		# Server will echo the message back to all players (including us)
	
	# Clear input
	input_field.text = ""
	input_field.grab_focus()

func add_message(channel: String, player_id: int, nickname: String, message: String, timestamp: String = "") -> void:
	"""Add a chat message to the display"""
	# Create message label
	var message_label = RichTextLabel.new()
	message_label.bbcode_enabled = true
	message_label.fit_content = true
	message_label.scroll_active = false
	message_label.custom_minimum_size = Vector2(0, 20)
	
	# Get player color
	var player_color = _get_player_color(player_id)
	
	# Format timestamp
	var time_str = ""
	if timestamp:
		var time = Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_system())
		time_str = "[%02d:%02d] " % [time.hour, time.minute]
	
	# Format message with color
	var formatted_message = ""
	
	# Add channel prefix
	match channel:
		"party":
			formatted_message += "[color=#00FF00][Party][/color] "
		"whisper":
			formatted_message += "[color=#FF00FF][Whisper][/color] "
	
	# Add timestamp
	formatted_message += "[color=#888888]" + time_str + "[/color]"
	
	# Add player name with color
	formatted_message += "[color=#" + player_color.to_html(false) + "]" + nickname + "[/color]: "
	
	# Add message
	formatted_message += message
	
	message_label.text = formatted_message
	
	# Add to container
	message_container.add_child(message_label)
	
	# Limit message history
	message_history.append(message_label)
	if message_history.size() > MAX_MESSAGES:
		var old_message = message_history.pop_front()
		if is_instance_valid(old_message):
			old_message.queue_free()
	
	# Auto-scroll to bottom
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)

func add_system_message(message: String) -> void:
	"""Add a system message (no player name)"""
	var message_label = RichTextLabel.new()
	message_label.bbcode_enabled = true
	message_label.fit_content = true
	message_label.scroll_active = false
	message_label.custom_minimum_size = Vector2(0, 20)
	
	var time = Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_system())
	var time_str = "[%02d:%02d] " % [time.hour, time.minute]
	
	message_label.text = "[color=#888888]" + time_str + "[/color][color=#FFFF00][System][/color] " + message
	
	message_container.add_child(message_label)
	message_history.append(message_label)
	
	if message_history.size() > MAX_MESSAGES:
		var old_message = message_history.pop_front()
		if is_instance_valid(old_message):
			old_message.queue_free()
	
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)

func _get_player_color(player_id: int) -> Color:
	"""Get consistent color for a player"""
	if not player_color_map.has(player_id):
		var color_index = player_color_map.size() % PLAYER_COLORS.size()
		player_color_map[player_id] = PLAYER_COLORS[color_index]
	
	return player_color_map[player_id]

func set_whisper_target(player_id: int, player_name: String) -> void:
	"""Set whisper target player"""
	whisper_target_id = player_id
	
	# Switch to whisper channel
	channel_tabs.current_tab = 2
	_on_channel_changed(2)
	
	# Update placeholder
	input_field.placeholder_text = "Whisper to " + player_name + "..."
	
	# Open chat
	open_chat()
	
	print("[Chat] Whisper target set: ", player_name, " (ID: ", player_id, ")")

func clear_messages() -> void:
	"""Clear all chat messages"""
	for message in message_history:
		if is_instance_valid(message):
			message.queue_free()
	message_history.clear()
	print("[Chat] Messages cleared")

func _update_party_tab() -> void:
	"""Enable/disable party tab based on party status"""
	if PartyManager and PartyManager.is_in_party():
		channel_tabs.set_tab_disabled(1, false)
	else:
		channel_tabs.set_tab_disabled(1, true)
		# Switch to global if currently on party
		if current_channel == "party":
			channel_tabs.current_tab = 0
			_on_channel_changed(0)

func _on_party_joined(_player_id: int) -> void:
	"""Called when a member joins the party"""
	_update_party_tab()
	# Only show message if it's us joining
	if _player_id == PlayerManager.player_id:
		add_system_message("You joined a party!")

func _on_party_left(_player_id: int) -> void:
	"""Called when a member leaves the party"""
	# Only show message if it's us leaving
	if _player_id == PlayerManager.player_id:
		_update_party_tab()
		add_system_message("You left the party.")

func _on_party_disbanded() -> void:
	"""Called when party is disbanded"""
	_update_party_tab()
	add_system_message("Party disbanded.")
