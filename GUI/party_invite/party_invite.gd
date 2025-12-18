extends Control

# Party Invite Popup
# Shows when you receive a party invitation

@onready var inviter_label: Label = $Panel/VBoxContainer/InviterLabel
@onready var countdown_label: Label = $Panel/VBoxContainer/CountdownLabel
@onready var accept_button: Button = $Panel/VBoxContainer/HBoxContainer/AcceptButton
@onready var decline_button: Button = $Panel/VBoxContainer/HBoxContainer/DeclineButton

var current_invite_id: int = -1
var inviter_name: String = ""
var time_remaining: float = 10.0
var is_counting: bool = false

func _ready() -> void:
	# Make sure we're added to the scene tree
	if not is_inside_tree():
		push_error("[PartyInvite] Not in scene tree!")
		return
	
	# Hide initially
	visible = false
	
	# Connect buttons if they exist
	if accept_button:
		accept_button.pressed.connect(_on_accept_pressed)
	else:
		push_error("[PartyInvite] accept_button is null!")
	
	if decline_button:
		decline_button.pressed.connect(_on_decline_pressed)
	else:
		push_error("[PartyInvite] decline_button is null!")
	
	# Connect to PartyManager signal
	if PartyManager:
		PartyManager.invite_received.connect(_on_invite_received)
		print("[PartyInvite] Ready and listening for invites")
	else:
		push_error("[PartyInvite] PartyManager is null!")

func _process(delta: float) -> void:
	"""Update countdown timer"""
	if is_counting and visible:
		time_remaining -= delta
		
		if time_remaining <= 0:
			# Time's up - auto-decline
			_on_timeout()
		else:
			# Update countdown label
			if countdown_label:
				countdown_label.text = "Expires in: %d seconds" % int(ceil(time_remaining))

func _on_invite_received(invite_data: Dictionary) -> void:
	"""Show invite popup when invitation is received"""
	current_invite_id = invite_data.get("invite_id", -1)
	inviter_name = invite_data.get("inviter_name", "Unknown")
	
	print("[PartyInvite] Received invite from: ", inviter_name, " (ID: ", current_invite_id, ")")
	
	# Check if we're in the scene tree
	if not is_inside_tree():
		push_error("[PartyInvite] Cannot show popup - not in scene tree!")
		return
	
	# Update UI
	if inviter_label:
		inviter_label.text = inviter_name + " invited you to their party!"
	else:
		push_error("[PartyInvite] inviter_label is null!")
		return
	
	# Start countdown
	time_remaining = 10.0
	is_counting = true
	
	# Show popup
	visible = true
	print("[PartyInvite] Popup shown with 10 second countdown")

func _on_accept_pressed() -> void:
	"""Accept button clicked"""
	print("[PartyInvite] Accepting invite: ", current_invite_id)
	PartyManager.accept_invite()
	_close()

func _on_decline_pressed() -> void:
	"""Decline button clicked"""
	print("[PartyInvite] Declining invite: ", current_invite_id)
	PartyManager.decline_invite()
	_close()

func _on_timeout() -> void:
	"""Auto-decline after timeout"""
	if visible:
		print("[PartyInvite] Invite timed out")
		PartyManager.decline_invite()
		_close()

func _close() -> void:
	"""Close the popup"""
	visible = false
	is_counting = false
	current_invite_id = -1
	inviter_name = ""
	time_remaining = 10.0
