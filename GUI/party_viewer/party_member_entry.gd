extends HBoxContainer

# Party Member Entry
# Shows a single party member's name and HP bar

@onready var name_label: Label = $NameLabel
@onready var hp_bar: ProgressBar = $HPBar
@onready var leader_icon: Label = $LeaderIcon
@onready var click_button: Button = $ClickButton

var player_id: int = -1
var is_leader: bool = false
var context_menu: PopupMenu = null

func _ready() -> void:
	# Create context menu
	context_menu = PopupMenu.new()
	add_child(context_menu)
	context_menu.id_pressed.connect(_on_context_menu_selected)
	
	# Connect click button
	if click_button:
		click_button.pressed.connect(_on_name_clicked)

func setup(member_data: Dictionary) -> void:
	"""Setup the member entry with data"""
	player_id = member_data.get("id", -1)
	var username = member_data.get("username", "Unknown")
	var hp = member_data.get("hp", 100)
	var max_hp = member_data.get("max_hp", 100)
	var role = member_data.get("role", "member")
	
	is_leader = (role == "leader")
	
	# Update UI
	if click_button:
		click_button.text = username
	if name_label:
		name_label.text = username
	
	if leader_icon:
		leader_icon.visible = is_leader
	
	# Highlight if this is the local player
	if player_id == PlayerManager.player_id:
		if click_button:
			click_button.modulate = Color(0, 1, 0)  # Green for you
		if name_label:
			name_label.modulate = Color(0, 1, 0)
	
	update_hp(hp, max_hp)

func update_hp(hp: int, max_hp: int) -> void:
	"""Update the health bar"""
	if not hp_bar:
		return
	
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	
	# Color based on HP percentage
	var hp_percent = float(hp) / float(max_hp) if max_hp > 0 else 0.0
	if hp_percent > 0.6:
		hp_bar.modulate = Color(0, 1, 0)  # Green
	elif hp_percent > 0.3:
		hp_bar.modulate = Color(1, 1, 0)  # Yellow
	else:
		hp_bar.modulate = Color(1, 0, 0)  # Red

func get_player_id() -> int:
	"""Get the player ID for this entry"""
	return player_id

func _on_name_clicked() -> void:
	"""Name was clicked - show context menu"""
	if not context_menu:
		return
	
	context_menu.clear()
	
	var am_i_leader = PartyManager.is_party_leader()
	var is_me = (player_id == PlayerManager.player_id)
	
	if is_me:
		# Clicking on yourself
		context_menu.add_item("Leave Party", 0)
	elif am_i_leader:
		# Leader clicking on another member
		context_menu.add_item("Kick from Party", 1)
		context_menu.add_item("Send PM", 2)
		context_menu.add_item("Transfer Leadership", 3)
	else:
		# Regular member clicking on another member
		context_menu.add_item("Send PM", 2)
	
	# Show menu at mouse position
	context_menu.position = get_global_mouse_position()
	context_menu.popup()

func _on_context_menu_selected(id: int) -> void:
	"""Context menu item selected"""
	match id:
		0:  # Leave Party
			print("[PartyMemberEntry] Leave party selected")
			PartyManager.leave_party()
		1:  # Kick
			print("[PartyMemberEntry] Kick player: ", player_id)
			PartyManager.kick_member(player_id)
		2:  # Send PM
			print("[PartyMemberEntry] Send PM to: ", player_id, " (", name_label.text, ")")
			# Open chat and set whisper target
			var chat_panel = get_tree().get_first_node_in_group("chat_panel")
			if chat_panel and chat_panel.has_method("set_whisper_target"):
				chat_panel.set_whisper_target(player_id, name_label.text)
				print("[PartyMemberEntry] Chat opened in whisper mode to ", name_label.text)
			else:
				print("[PartyMemberEntry] ERROR: Chat panel not found!")
		3:  # Transfer Leadership
			print("[PartyMemberEntry] Transfer leadership to: ", player_id)
			PartyManager.transfer_leadership(player_id)
