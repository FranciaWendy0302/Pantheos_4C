extends PanelContainer
class_name PlayerInteractionMenu

## Menu that appears when clicking on another player

signal option_selected(option: String)

var target_player_id: int = -1
var target_player_name: String = ""

@onready var player_name_label: Label = $VBoxContainer/PlayerNameLabel
@onready var options_container: VBoxContainer = $VBoxContainer/OptionsContainer

func _ready():
	visible = false

func show_menu(player_id: int, player_name: String, click_position: Vector2):
	"""Show interaction menu for a player"""
	target_player_id = player_id
	target_player_name = player_name
	
	# Set player name
	if player_name_label:
		player_name_label.text = player_name
	
	# Clear existing options
	if options_container:
		for child in options_container.get_children():
			child.queue_free()
	
	# Get available options from PvPManager
	var pvp_manager = get_node_or_null("/root/PvPManager")
	if not pvp_manager:
		return
	
	var options = pvp_manager.get_player_interaction_options(player_id)
	
	# Create buttons for each option
	for option in options:
		var button = Button.new()
		button.text = option
		button.pressed.connect(_on_option_pressed.bind(option))
		options_container.add_child(button)
	
	# Add close button
	var close_button = Button.new()
	close_button.text = "Cancel"
	close_button.pressed.connect(_on_close_pressed)
	options_container.add_child(close_button)
	
	# Position menu at click location
	global_position = click_position
	
	# Show menu
	visible = true

func _on_option_pressed(option: String):
	"""Handle option selection"""
	print("[PlayerInteractionMenu] Selected: %s for player %d" % [option, target_player_id])
	
	match option:
		"Invite to Party":
			_invite_to_party()
		"Challenge to Duel":
			_challenge_to_duel()
	
	option_selected.emit(option)
	hide_menu()

func _invite_to_party():
	"""Send party invitation"""
	var party_system = get_node_or_null("/root/PartySystem")
	if party_system and party_system.has_method("invite_player"):
		party_system.invite_player(target_player_id, target_player_name)
		print("[PlayerInteractionMenu] Party invite sent to %s" % target_player_name)
	else:
		print("[PlayerInteractionMenu] Party system not available")

func _challenge_to_duel():
	"""Send duel challenge"""
	var pvp_manager = get_node_or_null("/root/PvPManager")
	if pvp_manager:
		pvp_manager.request_duel(PlayerManager.player_id, target_player_id, PlayerManager.nickname)
		print("[PlayerInteractionMenu] Duel challenge sent to %s" % target_player_name)

func _on_close_pressed():
	hide_menu()

func hide_menu():
	visible = false
	target_player_id = -1
	target_player_name = ""

func _input(event):
	"""Close menu when clicking outside"""
	if not visible:
		return
	
	if event is InputEventMouseButton and event.pressed:
		# Check if click is outside menu
		var mouse_pos = get_global_mouse_position()
		var menu_rect = Rect2(global_position, size)
		
		if not menu_rect.has_point(mouse_pos):
			hide_menu()
