extends Panel

# Duel Request Popup
# Shows when another player requests a duel

@onready var message_label = $MarginContainer/VBoxContainer/Message
@onready var accept_button = $MarginContainer/VBoxContainer/Buttons/AcceptButton
@onready var decline_button = $MarginContainer/VBoxContainer/Buttons/DeclineButton

var requester_id: int = -1
var requester_name: String = ""

func _ready():
	print("[DuelPopup] _ready() called")
	
	if not message_label:
		print("[DuelPopup] ERROR: message_label not found!")
	if not accept_button:
		print("[DuelPopup] ERROR: accept_button not found!")
	if not decline_button:
		print("[DuelPopup] ERROR: decline_button not found!")
	
	if accept_button:
		accept_button.pressed.connect(_on_accept_pressed)
	if decline_button:
		decline_button.pressed.connect(_on_decline_pressed)
	
	hide()
	print("[DuelPopup] Ready complete")

func show_duel_request(from_player_id: int, from_player_name: String):
	"""Show duel request from another player"""
	requester_id = from_player_id
	requester_name = from_player_name
	
	message_label.text = "%s has challenged you to a duel!" % requester_name
	
	# Center on screen
	var viewport_size = get_viewport().get_visible_rect().size
	position = (viewport_size - size) / 2
	
	show()
	print("[DuelPopup] Showing duel request from: ", requester_name, " (ID: ", requester_id, ")")

func _on_accept_pressed():
	"""Accept the duel request"""
	print("[DuelPopup] Accepting duel from: ", requester_name)
	NetworkManager.accept_duel_request(requester_id)
	hide()

func _on_decline_pressed():
	"""Decline the duel request"""
	print("[DuelPopup] Declining duel from: ", requester_name)
	NetworkManager.decline_duel_request(requester_id)
	hide()
