extends Panel

# Friend Panel
# Main friend list UI

@onready var close_button = $MarginContainer/VBoxContainer/Header/CloseButton
@onready var friend_count_label = $MarginContainer/VBoxContainer/Header/FriendCount
@onready var friend_list_container = $MarginContainer/VBoxContainer/ScrollContainer/FriendListContainer
@onready var pending_requests_container = $MarginContainer/VBoxContainer/PendingRequests/ScrollContainer/RequestsContainer
@onready var pending_label = $MarginContainer/VBoxContainer/PendingRequests/PendingLabel

var friend_entry_scene = preload("res://GUI/friend_system/friend_entry.tscn")
var pending_requests: Array = []

var dragging = false
var drag_offset = Vector2.ZERO

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	
	# Connect to GlobalFriendManager signals
	GlobalFriendManager.friend_list_updated.connect(_on_friend_list_updated)
	GlobalFriendManager.friend_online.connect(_on_friend_online)
	GlobalFriendManager.friend_offline.connect(_on_friend_offline)
	GlobalFriendManager.friend_request_received.connect(_on_friend_request_received)
	GlobalFriendManager.friend_removed.connect(_on_friend_removed_signal)
	
	hide()

func _input(event):
	if not visible:
		return
	
	# Handle dragging
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

func toggle_visibility():
	"""Toggle friend panel visibility - can be called from button or other UI"""
	if visible:
		hide()
	else:
		show()
		# Refresh friend list and pending requests when opening
		print("[FriendPanel] Loading friend list and pending requests...")
		GlobalFriendManager.load_friend_list()
		GlobalFriendManager.load_pending_requests()

func open_panel():
	"""Open the friend panel"""
	if not visible:
		toggle_visibility()

func close_panel():
	"""Close the friend panel"""
	if visible:
		hide()

func _on_friend_list_updated(friends: Array):
	"""Update friend list display"""
	# Clear existing entries
	for child in friend_list_container.get_children():
		child.queue_free()
	
	# Update count
	friend_count_label.text = "Friends (%d/50)" % friends.size()
	
	# Add friend entries
	for friend in friends:
		var entry = friend_entry_scene.instantiate()
		friend_list_container.add_child(entry)
		entry.setup(friend)
		
		# Connect signals
		entry.whisper_requested.connect(_on_whisper_requested)
		entry.party_invite_requested.connect(_on_party_invite_requested)
		entry.remove_requested.connect(_on_remove_requested)
	
	print("[FriendPanel] Updated friend list: ", friends.size(), " friends")

func _on_friend_online(friend_id: int, friend_name: String):
	"""Update friend status to online"""
	for entry in friend_list_container.get_children():
		if entry.friend_id == friend_id:
			entry.update_online_status(true)
			break

func _on_friend_offline(friend_id: int):
	"""Update friend status to offline"""
	for entry in friend_list_container.get_children():
		if entry.friend_id == friend_id:
			entry.update_online_status(false)
			break

func _on_whisper_requested(friend_id: int, friend_name: String):
	"""Open chat with whisper to friend"""
	print("[FriendPanel] Whisper to: ", friend_name)
	# Open chat panel and set to whisper mode
	if has_node("/root/ChatPanel"):
		var chat_panel = get_node("/root/ChatPanel")
		chat_panel.show()
		chat_panel.set_whisper_target(friend_name)

func _on_party_invite_requested(friend_id: int):
	"""Send party invite to friend"""
	print("[FriendPanel] Invite to party: ", friend_id)
	GlobalPartyManager.send_party_invite(friend_id)

func _on_remove_requested(friend_id: int):
	"""Remove friend"""
	print("[FriendPanel] Remove friend: ", friend_id)
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	add_child(dialog)
	dialog.dialog_text = "Are you sure you want to remove this friend?"
	dialog.confirmed.connect(func():
		GlobalFriendManager.remove_friend(friend_id)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	dialog.popup_centered()

func _on_friend_request_received(requester_id: int, requester_name: String, _expires_in: int):
	"""Add pending friend request to list"""
	print("[FriendPanel] Received friend request from: ", requester_name, " (ID: ", requester_id, ")")
	
	# Check if already in list
	for req in pending_requests:
		if req.id == requester_id:
			return  # Already have this request
	
	# Add to pending requests
	pending_requests.append({
		"id": requester_id,
		"nickname": requester_name
	})
	
	_update_pending_requests_ui()

func _update_pending_requests_ui():
	"""Update pending requests display"""
	# Clear existing
	for child in pending_requests_container.get_children():
		child.queue_free()
	
	# Update label
	if pending_requests.size() > 0:
		pending_label.text = "Pending Requests (%d)" % pending_requests.size()
	else:
		pending_label.text = "Pending Requests"
	
	# Add request entries
	for request in pending_requests:
		var entry = HBoxContainer.new()
		pending_requests_container.add_child(entry)
		
		var name_label = Label.new()
		name_label.text = request.nickname
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.add_child(name_label)
		
		var accept_btn = Button.new()
		accept_btn.text = "Accept"
		accept_btn.pressed.connect(_on_accept_request.bind(request.id))
		entry.add_child(accept_btn)
		
		var decline_btn = Button.new()
		decline_btn.text = "Decline"
		decline_btn.pressed.connect(_on_decline_request.bind(request.id))
		entry.add_child(decline_btn)

func _on_accept_request(requester_id: int):
	"""Accept friend request"""
	print("[FriendPanel] Accepting request from ID: ", requester_id)
	GlobalFriendManager.accept_friend_request(requester_id)
	
	# Remove from pending list
	for i in range(pending_requests.size()):
		if pending_requests[i].id == requester_id:
			pending_requests.remove_at(i)
			break
	
	_update_pending_requests_ui()

func _on_decline_request(requester_id: int):
	"""Decline friend request"""
	print("[FriendPanel] Declining request from ID: ", requester_id)
	GlobalFriendManager.decline_friend_request(requester_id)
	
	# Remove from pending list
	for i in range(pending_requests.size()):
		if pending_requests[i].id == requester_id:
			pending_requests.remove_at(i)
			break
	
	_update_pending_requests_ui()

func _on_close_pressed():
	hide()

func _on_friend_removed_signal(friend_id: int):
	"""Handle friend removed signal - refresh inspect panel if showing that player"""
	print("[FriendPanel] Friend removed: ", friend_id)
	# If player inspect panel is showing this player, update the Add Friend button
	if has_node("/root/PlayerHud"):
		var hud = get_node("/root/PlayerHud")
		if hud.player_inspect_panel and hud.player_inspect_panel.visible:
			if hud.player_inspect_panel.current_player_id == friend_id:
				hud.player_inspect_panel._update_add_friend_button()
