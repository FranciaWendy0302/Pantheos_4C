extends Control

# Party Viewer Panel
# Shows all party members with names and HP bars on the left side

@onready var panel: Panel = $Panel
@onready var toggle_button: Button = $ToggleButton
@onready var members_container: VBoxContainer = $Panel/VBoxContainer/MembersContainer
@onready var leave_button: Button = $Panel/VBoxContainer/LeaveButton
@onready var count_label: Label = $Panel/VBoxContainer/HeaderContainer/CountLabel

var member_entry_scene = preload("res://GUI/party_viewer/party_member_entry.tscn")
var member_entries: Dictionary = {} # player_id -> entry node
var is_collapsed: bool = false

func _ready() -> void:
	# Hide initially (only show when in party)
	visible = false
	
	# Connect buttons
	if leave_button:
		leave_button.pressed.connect(_on_leave_pressed)
	
	if toggle_button:
		toggle_button.pressed.connect(_on_toggle_pressed)
	
	# Connect to PartyManager signals
	PartyManager.party_created.connect(_on_party_created)
	PartyManager.member_joined.connect(_on_member_joined)
	PartyManager.member_left.connect(_on_member_left)
	PartyManager.party_disbanded.connect(_on_party_disbanded)
	PartyManager.hp_updated.connect(_on_hp_updated)
	
	print("[PartyViewer] Ready and listening for party events")

func _on_party_created(party_id: int) -> void:
	"""Party was created"""
	print("[PartyViewer] Party created: ", party_id)
	_refresh_party_list()

func _on_member_joined(player_id: int) -> void:
	"""Member joined party"""
	print("[PartyViewer] Member joined: ", player_id)
	_refresh_party_list()

func _on_member_left(player_id: int) -> void:
	"""Member left party"""
	print("[PartyViewer] Member left: ", player_id)
	_refresh_party_list()

func _on_party_disbanded() -> void:
	"""Party was disbanded"""
	print("[PartyViewer] Party disbanded")
	_clear_members()
	visible = false

func _process(_delta: float) -> void:
	"""Poll HP from remote avatars and local player every frame"""
	if not visible or member_entries.is_empty():
		return
	
	# Get all remote avatars
	var avatars = get_tree().get_nodes_in_group("remote_avatars")
	
	# Update HP for each party member
	for player_id in member_entries.keys():
		# Check if this is the local player
		if player_id == PlayerManager.player_id:
			# Update from local player
			if PlayerManager.player and member_entries.has(player_id):
				member_entries[player_id].update_hp(PlayerManager.player.hp, PlayerManager.player.max_hp)
		else:
			# Find the remote avatar for this player
			for avatar in avatars:
				if avatar.has_method("get_player_id") and avatar.get_player_id() == player_id:
					# Update HP from avatar
					if member_entries.has(player_id):
						member_entries[player_id].update_hp(avatar.hp, avatar.max_hp)
					break

func _on_hp_updated(player_id: int, hp: int, max_hp: int) -> void:
	"""Member HP updated"""
	if member_entries.has(player_id):
		member_entries[player_id].update_hp(hp, max_hp)

func _refresh_party_list() -> void:
	"""Refresh the entire party member list"""
	# Clear existing entries
	_clear_members()
	
	# Get current party members
	var members = PartyManager.get_members()
	
	if members.size() == 0:
		visible = false
		return
	
	# Show viewer if we have members
	visible = true
	
	# Update count label
	if count_label:
		count_label.text = "(%d/5)" % members.size()
	
	# Create entry for each member
	for member in members:
		_add_member_entry(member)
	
	print("[PartyViewer] Showing ", members.size(), " members")

func _add_member_entry(member_data: Dictionary) -> void:
	"""Add a member entry to the list"""
	var player_id = member_data.get("id", -1)
	if player_id == -1:
		return
	
	# Create entry
	var entry = member_entry_scene.instantiate()
	members_container.add_child(entry)
	
	# Setup entry
	entry.setup(member_data)
	
	# Store reference
	member_entries[player_id] = entry

func _clear_members() -> void:
	"""Clear all member entries"""
	for entry in member_entries.values():
		if is_instance_valid(entry):
			entry.queue_free()
	
	member_entries.clear()

func _on_leave_pressed() -> void:
	"""Leave button clicked"""
	print("[PartyViewer] Leave button pressed")
	PartyManager.leave_party()

func _on_toggle_pressed() -> void:
	"""Toggle button clicked - collapse/expand panel"""
	is_collapsed = !is_collapsed
	
	if panel:
		panel.visible = !is_collapsed
	
	if toggle_button:
		toggle_button.text = "►" if is_collapsed else "◄"
	
	print("[PartyViewer] Panel ", "collapsed" if is_collapsed else "expanded")
