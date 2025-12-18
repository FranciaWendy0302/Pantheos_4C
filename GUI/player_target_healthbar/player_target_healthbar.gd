extends Control

# Player Target Health Bar
# Shows above a targeted player with their name and HP

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var invite_button: Button = $VBoxContainer/InviteButton
@onready var inspect_button: Button = $VBoxContainer/InspectButton
@onready var add_friend_button: Button = $VBoxContainer/AddFriendButton

# References to UI panels (will be set from HUD)
var player_inspect_panel: Control = null
var friend_request_popup: Control = null

var target_player_id: int = -1

func _ready() -> void:
	# Connect to party signals to update button visibility
	PartyManager.party_created.connect(_on_party_changed)
	PartyManager.party_disbanded.connect(_on_party_changed)
	PartyManager.member_joined.connect(_on_party_changed)
	PartyManager.member_left.connect(_on_party_changed)
	
	# Connect new buttons
	if inspect_button:
		inspect_button.pressed.connect(_on_inspect_pressed)
	if add_friend_button:
		add_friend_button.pressed.connect(_on_add_friend_pressed)

func _on_party_changed(_arg = null) -> void:
	"""Party state changed - update invite button"""
	_update_invite_button()

func setup(player_id: int, player_name: String, hp: int, max_hp: int) -> void:
	"""Setup the target health bar"""
	print("[PlayerTargetHealthBar] setup() called for player: ", player_name, " (ID: ", player_id, ")")
	
	if not name_label:
		push_error("[PlayerTargetHealthBar] name_label is null!")
		return
	if not hp_bar:
		push_error("[PlayerTargetHealthBar] hp_bar is null!")
		return
	if not invite_button:
		push_error("[PlayerTargetHealthBar] invite_button is null!")
		return
	
	target_player_id = player_id
	name_label.text = player_name
	update_hp(hp, max_hp)
	
	print("[PlayerTargetHealthBar] Nodes ready, updating invite button...")
	
	# Show invite button only if we're party leader and not in same party
	_update_invite_button()
	
	# Connect button
	if not invite_button.pressed.is_connected(_on_invite_pressed):
		invite_button.pressed.connect(_on_invite_pressed)
		print("[PlayerTargetHealthBar] Button signal connected")

func update_hp(hp: int, max_hp: int) -> void:
	"""Update the health bar"""
	if not hp_bar:
		return
	
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

func _update_invite_button() -> void:
	"""Update invite button visibility"""
	if not invite_button:
		print("[PlayerTargetHealthBar] ERROR: invite_button is null!")
		return
	
	var show_button = false
	
	# First check: Is target already in our party?
	var target_in_our_party = _is_target_in_our_party()
	
	print("[PlayerTargetHealthBar] Checking invite button visibility:")
	print("  - Target player ID: ", target_player_id)
	print("  - Target in our party: ", target_in_our_party)
	
	if target_in_our_party:
		# Target is already in our party - NEVER show button
		show_button = false
		print("  - Hiding button: Target already in our party")
	elif not PartyManager.is_in_party():
		# Not in party - can invite to create new party
		show_button = true
		print("  - Showing button: NOT in party (can create)")
	elif PartyManager.is_party_leader():
		# In party and leader - can invite others
		show_button = true
		print("  - Showing button: Is party leader (can invite)")
	else:
		# In party but not leader - can't invite
		show_button = false
		print("  - Hiding button: In party but not leader")
	
	invite_button.visible = show_button
	print("[PlayerTargetHealthBar] Button visible: ", invite_button.visible)

func _is_target_in_our_party() -> bool:
	"""Check if target player is in our party"""
	if not PartyManager.is_in_party():
		return false
	
	if target_player_id <= 0:
		return false
	
	for member in PartyManager.get_members():
		if member.get("id", -1) == target_player_id:
			return true
	
	return false

func _on_invite_pressed() -> void:
	"""Invite button clicked"""
	print("[PlayerTargetHealthBar] Inviting player ID: ", target_player_id)
	
	# If not in party, create one first
	if not PartyManager.is_in_party():
		print("[PlayerTargetHealthBar] Creating party first...")
		PartyManager.create_party()
		# Wait a moment for party creation
		await get_tree().create_timer(0.5).timeout
	
	# Now invite the player
	PartyManager.invite_player(target_player_id)
	
	# Hide button after inviting
	invite_button.visible = false


func _on_inspect_pressed() -> void:
	"""Inspect button clicked - show player info"""
	print("[PlayerTargetHealthBar] Inspecting player ID: ", target_player_id)
	
	# Request player info from server
	GlobalFriendManager.inspect_player(target_player_id, func(player_data):
		if player_data:
			# Get the inspect panel from PlayerHud
			var hud = get_node("/root/PlayerHud")
			if hud and hud.player_inspect_panel:
				hud.player_inspect_panel.show_player_info(player_data)
			else:
				print("[PlayerTargetHealthBar] Failed to get player inspect panel from HUD")
		else:
			print("[PlayerTargetHealthBar] Failed to get player data")
	)

func _on_add_friend_pressed() -> void:
	"""Add Friend button clicked - send friend request"""
	print("[PlayerTargetHealthBar] Sending friend request to player ID: ", target_player_id)
	
	# Check if already friends
	if GlobalFriendManager.is_friend(target_player_id):
		print("[PlayerTargetHealthBar] Already friends with this player")
		return
	
	# Send friend request
	GlobalFriendManager.send_friend_request(target_player_id)
	
	# Hide button after sending
	if add_friend_button:
		add_friend_button.visible = false
