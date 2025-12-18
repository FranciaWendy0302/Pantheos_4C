extends Node2D

const SAFEZONE_LEVEL: String = "res://Levels/final map/scene/safezone.tscn"
const WEBSITE_URL: String = "http://localhost/pantheos/pantheos-optimized.html"

# Session tracking - persists across scene changes
static var is_session_active: bool = false
static var session_player_data: Dictionary = {}

@export var music: AudioStream
@export var button_focus_audio: AudioStream
@export var button_press_audio: AudioStream

# Removed old buttons - using new login flow
var button_new: Button
var button_continue: Button
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var title_sprite: Sprite2D = $CanvasLayer/Control/Sprite2D
@onready var background_overlay: ColorRect = $CanvasLayer/Control/ColorRect
@onready var press_enter_button: Button = $CanvasLayer/Control/PressEnterButton

# Offline mode button on main menu
var offline_mode_button: Button

# MMORPG Login UI (will be added to scene)
var login_panel: PanelContainer
var username_input: LineEdit
var password_input: LineEdit
var login_button: Button
var create_account_button: Button
var login_status_label: Label
var http_request: HTTPRequest
var logged_in_player_data: Dictionary = {}

# Mode selection UI
@onready var mode_selection_backdrop: ColorRect = $CanvasLayer/Control/ModeSelectionBackdrop
@onready var mode_selection_panel: PanelContainer = $CanvasLayer/Control/ModeSelectionPanel
@onready var online_button: Button = $CanvasLayer/Control/ModeSelectionPanel/VBox/OnlineButton
@onready var back_from_mode_button: Button = $CanvasLayer/Control/ModeSelectionPanel/VBox/BackFromMode

# Character flow UI
@onready var character_panel: PanelContainer = $CanvasLayer/Control/CharacterPanel
@onready var slot1_button: Button = $CanvasLayer/Control/CharacterPanel/VBox/HBox/Slot1Button
@onready var slot2_button: Button = $CanvasLayer/Control/CharacterPanel/VBox/HBox/Slot2Button
@onready var slot1_delete_button: Button = $CanvasLayer/Control/CharacterPanel/VBox/HBox/Slot1DeleteButton
@onready var slot2_delete_button: Button = $CanvasLayer/Control/CharacterPanel/VBox/HBox/Slot2DeleteButton
@onready var confirm_button: Button = $CanvasLayer/Control/CharacterPanel/VBox/ConfirmButton
@onready var back_from_character: Button = $CanvasLayer/Control/CharacterPanel/VBox/BackFromCharacter

@onready var class_panel: PanelContainer = $CanvasLayer/Control/ClassPanel
@onready var swordsman_button: Button = $CanvasLayer/Control/ClassPanel/MarginContainer/VBox/ClassGrid/SwordsmanButton
@onready var archer_button: Button = $CanvasLayer/Control/ClassPanel/MarginContainer/VBox/ClassGrid/ArcherButton
@onready var mage_button: Button = $CanvasLayer/Control/ClassPanel/MarginContainer/VBox/ClassGrid/MageButton
@onready var assassin_button: Button = $CanvasLayer/Control/ClassPanel/MarginContainer/VBox/ClassGrid/AssassinButton
@onready var support_button: Button = $CanvasLayer/Control/ClassPanel/MarginContainer/VBox/ClassGrid/SupportButton
@onready var back_from_class: Button = $CanvasLayer/Control/ClassPanel/MarginContainer/VBox/BackFromClass

@onready var nickname_panel: PanelContainer = $CanvasLayer/Control/NicknamePanel
@onready var nick_input: LineEdit = $CanvasLayer/Control/NicknamePanel/VBox/NickInput
@onready var class_display_label: Label = $CanvasLayer/Control/NicknamePanel/VBox/ClassDisplayLabel
@onready var start_button: Button = $CanvasLayer/Control/NicknamePanel/VBox/StartButton
@onready var back_from_nickname: Button = $CanvasLayer/Control/NicknamePanel/VBox/BackFromNickname
@onready var locked_message_label: Label = $CanvasLayer/Control/ClassPanel/MarginContainer/VBox/LockedMessageLabel

# Network connect UI
@onready var server_backdrop: ColorRect = $CanvasLayer/Control/ServerPanelBackdrop
@onready var server_panel: PanelContainer = $CanvasLayer/Control/ServerPanel
@onready var server_addr_input: LineEdit = $CanvasLayer/Control/ServerPanel/VBox/AddressInput
@onready var server_port_input: LineEdit = $CanvasLayer/Control/ServerPanel/VBox/PortInput
@onready var server_nickname_input: LineEdit = $CanvasLayer/Control/ServerPanel/VBox/NicknameInput
@onready var server_mode_label: Label = $CanvasLayer/Control/ServerPanel/VBox/ModeLabel
@onready var connect_party_button: Button = $CanvasLayer/Control/ServerPanel/VBox/Buttons/ConnectPartyButton
@onready var connect_duel_button: Button = $CanvasLayer/Control/ServerPanel/VBox/Buttons/ConnectDuelButton
@onready var cancel_connect_button: Button = $CanvasLayer/Control/ServerPanel/VBox/CancelButton

var selected_slot: int = -1
var selected_class: String = ""
var selected_god: int = 0  # GodManager.GodType
var pending_mode: String = "party"

# God selection panel
var god_selection_panel: Control


func _ready() -> void:
	get_tree().paused = true
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		PlayerManager.player.visible = false
	
	PlayerHud.visible = false
	PauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Setup HTTP Request for MySQL login
	http_request = HTTPRequest.new()
	http_request.process_mode = Node.PROCESS_MODE_ALWAYS  # Allow HTTP requests when paused
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)
	
	# Create MMORPG login UI
	_create_login_ui()
	
	# Create offline mode button on main menu
	_create_offline_mode_button()
	
	# Create god selection panel
	_create_god_selection_panel()
	
	# Old buttons removed - using new login flow
	
	setup_title_screen()
	update_slot_buttons()
	
	LevelManager.level_load_started.connect(exit_title_screen)
	
	# Check if returning from game (session active)
	await get_tree().create_timer(0.1).timeout  # Wait for UI to be ready
	
	if is_session_active:
		# Returning from game - go directly to character selection
		show_character_panel()
	else:
		# Fresh start - check for saved credentials and pre-fill login form
		var saved_creds = load_saved_credentials()
		if saved_creds.has("username") and saved_creds.has("password"):
			username_input.text = saved_creds.username
			password_input.text = saved_creds.password
			login_status_label.text = "Welcome back! Click Login to continue."
			login_status_label.modulate = Color(0.5, 1.0, 0.5)  # Light green
		
		# Show main menu with login/offline buttons
		_show_main_login_menu()
	
	pass
	
func setup_title_screen() -> void:
	AudioManager.play_music(music)
	
	# Mode selection UI wiring (tutorial removed)
	online_button.pressed.connect(on_select_online_mode)
	back_from_mode_button.pressed.connect(show_main_menu)
	
	# Flow wiring
	slot1_button.pressed.connect(on_select_slot.bind(1))
	slot2_button.pressed.connect(on_select_slot.bind(2))
	slot1_delete_button.pressed.connect(on_delete_slot.bind(1))
	slot2_delete_button.pressed.connect(on_delete_slot.bind(2))
	confirm_button.pressed.connect(on_confirm_slot)
	back_from_character.pressed.connect(_on_logout_button_pressed)
	
	# Update button text to "Logout"
	back_from_character.text = "Logout"
	
	# Connect all class buttons - all classes available
	swordsman_button.pressed.connect(on_select_class.bind("Swordsman"))
	archer_button.pressed.connect(on_select_class.bind("Archer"))
	mage_button.pressed.connect(on_select_class.bind("Mage"))
	assassin_button.pressed.connect(on_select_class.bind("Assassin"))
	support_button.pressed.connect(on_select_class.bind("Support"))
	back_from_class.pressed.connect(show_character_panel)
	start_button.pressed.connect(start_game_with_selection)
	back_from_nickname.pressed.connect(on_back_from_nickname)

	# Network connect UI wiring
	connect_party_button.pressed.connect(_on_connect_party)
	connect_duel_button.pressed.connect(_on_connect_duel)
	cancel_connect_button.pressed.connect(_on_cancel_connect)
	
	# Connect to NetworkManager signals
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm:
		if nm.has_signal("connected"):
			nm.connected.connect(_on_network_connected)
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).physical_keycode
		
		# F5 for Party, F6 for Duel
		if key == KEY_F5:
			_show_server_panel("party")
		elif key == KEY_F6:
			_show_server_panel("duel")
	pass



func _show_server_panel(mode: String = "") -> void:
	if mode != "":
		pending_mode = mode
		server_mode_label.text = "ONLINE MODE - Multiplayer Connection"
	else:
		server_mode_label.text = "ONLINE MODE - Enter Server Details"
	
	# Auto-fill localhost as default server address
	if server_addr_input.text == "":
		server_addr_input.text = "localhost"
	
	# Set nickname from PlayerManager (from logged-in account)
	if PlayerManager.nickname != "":
		server_nickname_input.text = PlayerManager.nickname
		# Make nickname read-only if coming from account login
		server_nickname_input.editable = false
		server_nickname_input.placeholder_text = "Account: " + PlayerManager.nickname
	else:
		# This shouldn't happen in the new flow, but keep as fallback
		server_nickname_input.editable = true
		server_nickname_input.placeholder_text = "Enter nickname"
		if server_nickname_input.text == "":
			server_nickname_input.text = "Player"
	
	# Update address placeholder
	server_addr_input.placeholder_text = "localhost (or server IP address)"
	
	server_backdrop.visible = true
	server_panel.visible = true
	login_panel.visible = false
	character_panel.visible = false
	mode_selection_backdrop.visible = false
	mode_selection_panel.visible = false
	title_sprite.visible = false
	background_overlay.visible = false
	server_addr_input.grab_focus()
	pass

func _on_connect_party() -> void:
	_do_connect("party")
	pass

func _on_connect_duel() -> void:
	_do_connect("duel")
	pass

func _on_cancel_connect() -> void:
	server_backdrop.visible = false
	server_panel.visible = false
	show_mode_selection_panel()  # Return to mode selection
	pass

func _do_connect(mode: String) -> void:
	var address := server_addr_input.text.strip_edges()
	if address == "":
		return
	var port: int = 9000
	if server_port_input.text.is_valid_int():
		port = int(server_port_input.text)
	var nickname := server_nickname_input.text.strip_edges()
	if nickname == "":
		nickname = PlayerManager.nickname if PlayerManager.nickname != "" else "Player"
	
	# Set player nickname and default class for multiplayer
	PlayerManager.nickname = nickname
	if PlayerManager.selected_class == "":
		PlayerManager.selected_class = "Swordsman"
	
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm and nm.has_method("connect_to_server"):
		nm.connect_to_server(address, port, nickname, mode)
	server_panel.visible = false
	pass

func _on_network_connected(_mode: String) -> void:
	# Connection successful - transition to safezone (online mode spawns in safezone)
	# Unpause the game before loading (title screen pauses it)
	get_tree().paused = false
	LevelManager.load_new_level(SAFEZONE_LEVEL, "PlayerSpawn", Vector2.ZERO)
	pass

func on_new_game() -> void:
	play_audio(button_press_audio)
	# In offline mode, skip mode selection and go directly to character creation
	# Mode selection is only for online (account) mode
	show_character_panel()
	pass

func show_mode_selection_panel() -> void:
	mode_selection_backdrop.visible = true
	mode_selection_panel.visible = true
	login_panel.visible = false
	character_panel.visible = false
	class_panel.visible = false
	nickname_panel.visible = false
	server_backdrop.visible = false
	server_panel.visible = false
	title_sprite.visible = false
	background_overlay.visible = false
	online_button.grab_focus()
	pass

func on_select_online_mode() -> void:
	play_audio(button_press_audio)
	mode_selection_backdrop.visible = false
	mode_selection_panel.visible = false
	_show_server_panel("")  # Show panel without pre-selecting mode
	pass

func on_exit_game() -> void:
	play_audio(button_press_audio)
	# Show character selection to choose which slot to load
	show_character_panel()
	pass

func show_main_menu() -> void:
	login_panel.visible = false
	mode_selection_backdrop.visible = false
	mode_selection_panel.visible = false
	character_panel.visible = false
	class_panel.visible = false
	nickname_panel.visible = false
	server_backdrop.visible = false
	server_panel.visible = false
	title_sprite.visible = true
	background_overlay.visible = false
	pass

func show_character_panel() -> void:
	# Hide all other panels
	login_panel.visible = false
	mode_selection_backdrop.visible = false
	mode_selection_panel.visible = false
	class_panel.visible = false
	nickname_panel.visible = false
	server_backdrop.visible = false
	server_panel.visible = false
	title_sprite.visible = false
	background_overlay.visible = false
	press_enter_button.visible = false
	
	# Show character panel
	character_panel.visible = true
	selected_slot = -1
	
	# TEMPORARY FIX: Disable Slot 2 in online mode until multi-slot database is implemented
	if SaveManager.online_mode:
		slot2_button.disabled = true
		slot2_delete_button.visible = false
		# Check if slot 2 has data
		var slot2_info = SaveManager.get_character_slot_info(2)
		if slot2_info.has("nickname") and slot2_info.nickname != "":
			slot2_button.text = "Slot 2\n(Temporarily Disabled)"
		else:
			slot2_button.text = "Slot 2\n(Coming Soon)"
	else:
		slot2_button.disabled = false
	
	update_slot_buttons()
	update_confirm_button()
	slot1_button.grab_focus()
	pass

func update_slot_buttons() -> void:
	# Update slot 1 button
	var slot1_info = SaveManager.get_character_slot_info(1)
	var slot1_has_character = slot1_info.has("nickname") and slot1_info.nickname != ""
	if slot1_has_character:
		var level = slot1_info.get("level", 1)
		var player_class = slot1_info.get("character_class", "")
		slot1_button.text = slot1_info.nickname + "\n" + player_class + " - Lv." + str(level)
		slot1_delete_button.visible = true
	else:
		slot1_button.text = "Create Character 1"
		slot1_delete_button.visible = false
	
	# Update slot 2 button
	var slot2_info = SaveManager.get_character_slot_info(2)
	var slot2_has_character = slot2_info.has("nickname") and slot2_info.nickname != ""
	if slot2_has_character:
		var level = slot2_info.get("level", 1)
		var player_class = slot2_info.get("character_class", "")
		slot2_button.text = slot2_info.nickname + "\n" + player_class + " - Lv." + str(level)
		slot2_delete_button.visible = true
	else:
		slot2_button.text = "Create Character 2"
		slot2_delete_button.visible = false
	
	# Update button styles to show selection
	if selected_slot == 1:
		slot1_button.modulate = Color(1.2, 1.2, 1.2, 1.0)  # Highlight selected
		slot2_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		slot1_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if selected_slot == 2:
			slot2_button.modulate = Color(1.2, 1.2, 1.2, 1.0)  # Highlight selected
		else:
			slot2_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	pass

func update_confirm_button() -> void:
	# Show confirm button only if a slot is selected
	if selected_slot > 0:
		confirm_button.visible = true
		var slot_info = SaveManager.get_character_slot_info(selected_slot)
		var slot_has_character = slot_info.has("nickname") and slot_info.nickname != ""
		if slot_has_character:
			confirm_button.text = "Continue"
		else:
			confirm_button.text = "Create Character"
	else:
		confirm_button.visible = false
	pass

func on_delete_slot(slot: int) -> void:
	play_audio(button_press_audio)
	
	# Get character info for confirmation
	var slot_info = SaveManager.get_character_slot_info(slot)
	if not slot_info.has("nickname"):
		return
	
	var character_nickname = slot_info.nickname
	
	# Show confirmation dialog
	show_delete_confirmation(slot, character_nickname)
	pass

func show_delete_confirmation(slot: int, nickname: String) -> void:
	# Create confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.title = "Delete Character"
	dialog.dialog_text = ""  # Clear default text to avoid overlap
	dialog.get_cancel_button().text = "Cancel"
	dialog.get_ok_button().visible = false  # Hide default OK button
	dialog.min_size = Vector2(400, 250)
	
	# IMPORTANT: Allow dialog to process when game is paused
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create custom content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	var warning_label = Label.new()
	warning_label.text = "⚠ WARNING: This action cannot be undone!"
	warning_label.modulate = Color(1.0, 0.8, 0.0)
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warning_label)
	
	var info_label = Label.new()
	info_label.text = "Type the character's nickname to confirm deletion:"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_label)
	
	var nickname_display = Label.new()
	nickname_display.text = "\"" + nickname + "\""
	nickname_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nickname_display.add_theme_font_size_override("font_size", 20)
	nickname_display.modulate = Color(1.0, 0.8, 0.0)
	vbox.add_child(nickname_display)
	
	var input = LineEdit.new()
	input.placeholder_text = "Enter: " + nickname
	input.custom_minimum_size = Vector2(300, 40)
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.process_mode = Node.PROCESS_MODE_ALWAYS  # Allow input when paused
	input.editable = true
	input.context_menu_enabled = true
	input.selecting_enabled = true
	vbox.add_child(input)
	
	var error_label = Label.new()
	error_label.text = ""
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.modulate = Color(1.0, 0.3, 0.3)
	error_label.visible = false
	vbox.add_child(error_label)
	
	var confirm_btn = Button.new()
	confirm_btn.text = "DELETE CHARACTER"
	confirm_btn.modulate = Color(1.0, 0.3, 0.3)
	confirm_btn.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(confirm_btn)
	
	dialog.add_child(vbox)
	add_child(dialog)
	
	# Function to handle deletion
	var do_delete = func():
		if input.text.strip_edges() == nickname:
			# Correct nickname entered - delete character
			if SaveManager.delete_character_slot(slot):
				# If deleted slot was selected, clear selection
				if selected_slot == slot:
					selected_slot = -1
				# Update UI after deletion
				update_slot_buttons()
				update_confirm_button()
				dialog.hide()
				dialog.queue_free()
			else:
				push_error("Failed to delete character slot " + str(slot))
				error_label.text = "❌ Failed to delete character"
				error_label.visible = true
		else:
			# Wrong nickname - show error
			error_label.text = "❌ Incorrect nickname! Type: " + nickname
			error_label.visible = true
	
	# Connect signals
	confirm_btn.pressed.connect(do_delete)
	input.text_submitted.connect(func(_text): do_delete.call())  # Enter key support
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	# Show dialog and grab focus on input
	dialog.popup_centered()
	
	# Wait for dialog to be visible, then grab focus
	await get_tree().process_frame
	input.grab_focus()
	input.grab_focus()
	pass

func on_select_slot(slot: int) -> void:
	selected_slot = slot
	update_slot_buttons()
	update_confirm_button()
	confirm_button.grab_focus()
	pass

func on_confirm_slot() -> void:
	if selected_slot <= 0:
		return
	
	play_audio(button_press_audio)
	
	# Check if slot already has a character - if so, load it
	if SaveManager.slot_exists(selected_slot):
		var slot_info = SaveManager.get_character_slot_info(selected_slot)
		if slot_info.has("nickname") and slot_info.nickname != "":
			# Load existing character
			SaveManager.current_slot = selected_slot
			
			# For online mode, character data is already loaded from login
			# Just start the game directly
			if SaveManager.online_mode:
				print("[TitleScene] Loading existing character in online mode...")
				
				# Set PlayerManager data from slot info
				PlayerManager.nickname = slot_info.nickname
				PlayerManager.selected_class = slot_info.character_class
				
				# Restore god selection from save data
				if SaveManager.current_save.has("character_meta"):
					var god_id = SaveManager.current_save.character_meta.get("god_id", 0)
					if god_id > 0:
						GodManager.select_god(god_id)
						print("[TitleScene] Restored god: ", GodManager.get_god_name(god_id))
				
				# Load the saved map and position
				var saved_map = SaveManager.current_save.scene_path
				var saved_pos = Vector2(SaveManager.current_save.player.pos_x, SaveManager.current_save.player.pos_y)
				
				# Validate the saved map exists
				if saved_map == "" or not ResourceLoader.exists(saved_map):
					saved_map = SAFEZONE_LEVEL
					saved_pos = Vector2.ZERO
				
				# Set flag for SaveManager to restore position after level loads
				SaveManager.should_restore_position = true
				SaveManager.position_to_restore = saved_pos
				
				# IMPORTANT: Re-apply inventory data before loading level
				print("[TitleScene] Re-applying inventory data...")
				print("[TitleScene] Items in current_save: ", SaveManager.current_save.items.size())
				PlayerManager.INVENTORY_DATA.parse_save_data(SaveManager.current_save.items)
				print("[TitleScene] ✓ Inventory applied to INVENTORY_DATA")
				
				# IMPORTANT: Connect to multiplayer server!
				print("[TitleScene] Connecting existing character to multiplayer...")
				var nm = get_node_or_null("/root/NetworkManager")
				if nm and nm.has_method("connect_to_nodejs_server"):
					nm.connect_to_nodejs_server(PlayerManager.player_id, slot_info.nickname, slot_info.character_class)
				
				# Load the game
				LevelManager.load_new_level(saved_map, "", Vector2.ZERO)
			else:
				# Offline mode - load from save file
				SaveManager.load_game(selected_slot)
			return
	
	# Otherwise, create new character
	character_panel.visible = false
	class_panel.visible = true
	swordsman_button.grab_focus()
	pass

func on_select_class(_class: String) -> void:
	# All classes are now available
	selected_class = _class
	class_panel.visible = false
	
	print("[TitleScene] Class selected: ", _class)
	
	# Show god selection panel
	show_god_selection_panel()
	pass

func on_class_locked() -> void:
	locked_message_label.visible = true
	play_audio(button_press_audio)
	await get_tree().create_timer(2.0).timeout
	locked_message_label.visible = false
	pass

func on_back_from_nickname() -> void:
	# Go back to god selection
	play_audio(button_press_audio)
	nickname_panel.visible = false
	show_god_selection_panel()
	pass

# ============================================
# GOD SELECTION SYSTEM
# ============================================

func _create_god_selection_panel() -> void:
	"""Create the god selection panel"""
	var god_scene = load("res://GUI/god_selection/god_selection_panel.tscn")
	if not god_scene:
		push_error("[TitleScene] Failed to load god selection panel scene!")
		return
	
	god_selection_panel = god_scene.instantiate()
	if not god_selection_panel:
		push_error("[TitleScene] Failed to instantiate god selection panel!")
		return
	
	# Add to scene tree first
	$CanvasLayer/Control.add_child(god_selection_panel)
	
	# Connect signals (they should be available immediately after instantiation)
	god_selection_panel.god_selected.connect(_on_god_selected)
	god_selection_panel.back_pressed.connect(_on_back_from_god)
	
	god_selection_panel.visible = false
	print("[TitleScene] God selection panel created successfully")

func show_god_selection_panel() -> void:
	"""Show god selection panel"""
	if not god_selection_panel or not is_instance_valid(god_selection_panel):
		push_error("[TitleScene] God selection panel not created or invalid!")
		# Fallback to nickname panel
		nickname_panel.visible = true
		class_display_label.text = "Class: " + selected_class + "\nGod: (Not selected)"
		nick_input.text = ""
		nick_input.grab_focus()
		return
	
	character_panel.visible = false
	class_panel.visible = false
	nickname_panel.visible = false
	server_backdrop.visible = false
	server_panel.visible = false
	title_sprite.visible = false
	background_overlay.visible = false
	mode_selection_backdrop.visible = false
	mode_selection_panel.visible = false
	
	god_selection_panel.visible = true
	god_selection_panel.show_panel()
	print("[TitleScene] God selection panel shown")

func _on_god_selected(god_id: int) -> void:
	"""Called when player selects a god"""
	selected_god = god_id
	var god_data = GodManager.get_god_data(god_id)
	print("[TitleScene] Selected god: ", god_data.name, " (ID: ", god_id, ")")
	
	# Set god in GodManager
	GodManager.select_god(god_id)
	
	# Move to nickname panel
	god_selection_panel.visible = false
	nickname_panel.visible = true
	class_display_label.text = "Class: " + selected_class + "\nGod: " + god_data.name
	nick_input.text = ""
	nick_input.grab_focus()

func _on_back_from_god() -> void:
	"""Go back from god selection to class selection"""
	play_audio(button_press_audio)
	god_selection_panel.visible = false
	class_panel.visible = true
	swordsman_button.grab_focus()

# ============================================

func start_game_with_account_nickname() -> void:
	# For online accounts - use account nickname directly
	var nickname = PlayerManager.nickname
	
	# Set the current slot
	SaveManager.current_slot = selected_slot
	
	# Save character data to the selected slot
	SaveManager.save_character_slot(selected_slot, nickname, selected_class, selected_god)
	
	# Set player manager data (already set from login, but ensure class is set)
	if selected_class != "":
		PlayerManager.selected_class = selected_class
	
	
	play_audio(button_press_audio)
	# Always spawn in safezone
	LevelManager.load_new_level(SAFEZONE_LEVEL, "PlayerSpawn", Vector2.ZERO)
	pass

func start_game_with_selection() -> void:
	var nickname := nick_input.text.strip_edges()
	if nickname == "":
		nickname = "Adventurer"
	
	# Set the current slot
	SaveManager.current_slot = selected_slot
	
	# IMPORTANT: Clear inventory for new character
	print("[TitleScene] Creating new character - clearing inventory...")
	PlayerManager.INVENTORY_DATA.clear_inventory()
	SaveManager.current_save.items = []
	print("[TitleScene] ✓ Inventory cleared")
	
	# Set player manager data FIRST
	PlayerManager.nickname = nickname
	if selected_class != "":
		PlayerManager.selected_class = selected_class
	
	# Save character to database if in online mode
	if SaveManager.online_mode:
		
		# Update character class in database
		var nm = get_node_or_null("/root/NetworkManager")
		if nm and nm.has_method("update_player_character_class"):
			await nm.update_player_character_class(PlayerManager.player_id, selected_class, selected_god, selected_slot)
		
		# Also save full player data with nickname AND GOD
		if nm and nm.has_method("save_player_data"):
			var player_data = {
				"player_id": PlayerManager.player_id,
				"character_slot": selected_slot,
				"nickname": nickname,
				"character_class": selected_class,
				"god_id": selected_god,  # Save selected god
				"god_skill_unlocked": false,
				"level": 1,
				"xp": 0,
				"gold": 100,
				"hp": 100,
				"max_hp": 100,
				"position_x": 0,
				"position_y": 0,
				"current_map": SAFEZONE_LEVEL
			}
			var result = await nm.save_player_data(player_data)
			if result and result.has("success") and result.success:
				print("[TitleScene] ✓ Character saved with god: ", GodManager.get_god_name(selected_god))
			else:
				push_error("[TitleScene] ✗ Failed to save character to database")
	
	# Save character data to the selected slot (for offline mode or local cache)
	SaveManager.save_character_slot(selected_slot, nickname, selected_class, selected_god)
	
	# Mark that we have an active game session
	is_session_active = true
	
	# Auto-connect to multiplayer if in online mode
	if SaveManager.online_mode:
		print("[TitleScene] Online mode detected, connecting to multiplayer...")
		var nm = get_node_or_null("/root/NetworkManager")
		if nm and nm.has_method("connect_to_nodejs_server"):
			# Auto-connect to WebSocket server so all players see each other
			print("[TitleScene] Calling connect_to_nodejs_server with player_id: ", PlayerManager.player_id)
			nm.connect_to_nodejs_server(PlayerManager.player_id, nickname, selected_class)
	
	play_audio(button_press_audio)
	
	# Store tutorial flag - show tutorial after level loads
	PlayerManager.set("show_tutorial", true)
	PlayerManager.set("tutorial_god_id", selected_god)
	PlayerManager.set("tutorial_class", selected_class)
	print("[TitleScene] Tutorial flags set - will show after level loads")
	
	# Always spawn in safezone
	LevelManager.load_new_level(SAFEZONE_LEVEL, "PlayerSpawn", Vector2.ZERO)
	pass

func exit_title_screen() -> void:
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		PlayerManager.player.visible = true
	PlayerHud.visible = true
	PauseMenu.process_mode = Node.PROCESS_MODE_ALWAYS
	self.queue_free()
	pass

func play_audio(_a: AudioStream) -> void:
	audio_stream_player.stream = _a
	audio_stream_player.play()


# =========================
# MMORPG Login System
# =========================

func _create_offline_mode_button() -> void:
	# This function is kept for compatibility but buttons are now created in _create_main_login_buttons
	pass


func _create_login_ui() -> void:
	# Use the login panel from the scene instead of creating dynamically
	login_panel = $CanvasLayer/Control/LoginPanel
	username_input = $CanvasLayer/Control/LoginPanel/MarginContainer/VBox/UsernameInput
	password_input = $CanvasLayer/Control/LoginPanel/MarginContainer/VBox/PasswordInput
	login_button = $CanvasLayer/Control/LoginPanel/MarginContainer/VBox/LoginButton
	create_account_button = $CanvasLayer/Control/LoginPanel/MarginContainer/VBox/CreateAccountButton
	login_status_label = $CanvasLayer/Control/LoginPanel/MarginContainer/VBox/StatusLabel
	offline_mode_button = $CanvasLayer/Control/OfflineModeButton
	var quit_button = $CanvasLayer/Control/QuitButton
	
	# Buttons are configured in the scene file - just connect signals
	offline_mode_button.pressed.connect(_on_offline_mode_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Connect button signals for login form
	login_button.pressed.connect(_on_login_button_pressed)
	create_account_button.pressed.connect(_on_create_account_button_pressed)
	
	# Connect Enter key to login
	username_input.text_submitted.connect(_on_username_submitted)
	password_input.text_submitted.connect(_on_password_submitted)



func _show_main_login_menu() -> void:
	# Show login panel immediately with Offline and Quit buttons on the side
	login_panel.visible = true
	offline_mode_button.visible = true
	
	var quit_button = $CanvasLayer/Control/QuitButton
	quit_button.visible = true
	
	title_sprite.visible = true
	background_overlay.visible = false
	press_enter_button.visible = false
	mode_selection_backdrop.visible = false
	mode_selection_panel.visible = false
	character_panel.visible = false
	server_backdrop.visible = false
	server_panel.visible = false
	
	username_input.grab_focus()

func _show_login_panel() -> void:
	# Show the actual login form
	login_panel.visible = true
	offline_mode_button.visible = false
	
	var quit_button = $CanvasLayer/Control/QuitButton
	quit_button.visible = false
	
	username_input.grab_focus()

func _on_login_button_pressed() -> void:
	var username = username_input.text.strip_edges()
	var password = password_input.text
	
	if username == "" or password == "":
		login_status_label.text = "Please enter username and password"
		return
	
	login_status_label.text = "Logging in..."
	login_button.disabled = true
	
	# IMPORTANT: Unpause the game temporarily to allow HTTPRequest to work
	var was_paused = get_tree().paused
	get_tree().paused = false
	
	var test_http = HTTPRequest.new()
	test_http.process_mode = Node.PROCESS_MODE_ALWAYS
	test_http.timeout = 10.0  # 10 second timeout
	add_child(test_http)
	test_http.request("http://100.92.219.104:3000/health")
	var test_response = await test_http.request_completed
	test_http.queue_free()
	
	if test_response[0] != HTTPRequest.RESULT_SUCCESS:
		login_status_label.text = "Cannot connect to server!"
		login_button.disabled = false
		get_tree().paused = was_paused  # Restore pause state
		return
	
	
	# Call Node.js API
	await _login_to_nodejs(username, password)
	
	# Restore pause state
	get_tree().paused = was_paused

func _on_create_account_button_pressed() -> void:
	var username = username_input.text.strip_edges()
	var password = password_input.text
	
	if username == "" or password == "":
		login_status_label.text = "Please enter username and password"
		return
	
	if username.length() < 3:
		login_status_label.text = "Username must be at least 3 characters"
		return
	
	if password.length() < 6:
		login_status_label.text = "Password must be at least 6 characters"
		return
	
	login_status_label.text = "Creating account..."
	create_account_button.disabled = true
	
	# Call Node.js API
	_register_to_nodejs(username, password)

func _on_main_login_button_pressed() -> void:
	# Show the login panel when player clicks "Login" from main menu
	_show_login_panel()

func _on_offline_mode_button_pressed() -> void:
	# This function is kept for compatibility but main login now uses _on_main_login_button_pressed
	# Disable online mode
	SaveManager.disable_online_mode()
	
	# Clear any online account data
	PlayerManager.player_id = 0
	PlayerManager.nickname = ""
	PlayerManager.character_class = ""
	PlayerManager.selected_class = ""
	
	# Clear SaveManager character data (so no pre-built character shows)
	SaveManager.current_save.character_meta.nickname = ""
	SaveManager.current_save.character_meta.character_class = ""
	
	# Hide login panel and show character selection
	var login_backdrop = get_node_or_null("CanvasLayer/Control/LoginBackdrop")
	if login_backdrop:
		login_backdrop.visible = false
	login_panel.visible = false
	show_character_panel()

func _on_username_submitted(_text: String) -> void:
	password_input.grab_focus()

func _on_password_submitted(_text: String) -> void:
	_on_login_button_pressed()


func _login_to_nodejs(username: String, password: String) -> void:
	# Use NetworkManager to login
	
	# Add timeout protection
	var timeout_timer = get_tree().create_timer(15.0)  # 15 second timeout
	var result = await NetworkManager.login(username, password)
	
	# Check if we timed out
	if timeout_timer.time_left <= 0:
		login_status_label.text = "Connection timeout - check server"
		login_button.disabled = false
		return
	
	login_button.disabled = false
	
	if result.has("success") and result.success:
		logged_in_player_data = result.player_data
		
		# Get nickname safely (might not exist for fresh accounts)
		var player_nickname = logged_in_player_data.get("nickname", logged_in_player_data.get("username", "Player"))
		login_status_label.text = "Welcome, " + player_nickname + "!"
		
		# Enable online mode
		SaveManager.enable_online_mode()
		
		# Store player data (convert player_id to int)
		PlayerManager.player_id = int(logged_in_player_data.player_id)
		PlayerManager.nickname = player_nickname
		
		# IMPORTANT: Only set character_class if it exists and is not empty
		# Fresh accounts should NOT have a character class yet
		var db_class = logged_in_player_data.get("character_class", "")
		if db_class != null and db_class != "":
			PlayerManager.character_class = str(db_class)
			PlayerManager.selected_class = str(db_class)
			
			# Load ALL player data into SaveManager
			SaveManager.current_save.player.level = int(logged_in_player_data.get("level", 1))
			SaveManager.current_save.player.xp = int(logged_in_player_data.get("xp", 0))
			SaveManager.current_save.player.hp = int(logged_in_player_data.get("hp", 100))
			SaveManager.current_save.player.max_hp = int(logged_in_player_data.get("max_hp", 100))
			SaveManager.current_save.player.pos_x = float(logged_in_player_data.get("position_x", 0))
			SaveManager.current_save.player.pos_y = float(logged_in_player_data.get("position_y", 0))
			
			# Load character metadata
			SaveManager.current_save.character_meta.nickname = player_nickname
			SaveManager.current_save.character_meta.character_class = str(db_class)
			SaveManager.current_save.character_meta.god_id = int(logged_in_player_data.get("god_id", 0))
			
			# Load inventory if available
			print("[TitleScene] ========== LOADING INVENTORY FROM LOGIN ==========")
			var inv_data = logged_in_player_data.get("inventory", null)
			print("[TitleScene] Inventory data type: ", typeof(inv_data))
			print("[TitleScene] Inventory data: ", inv_data)
			
			if inv_data is String and inv_data != "" and inv_data != "null":
				print("[TitleScene] Parsing inventory JSON...")
				var json_inv = JSON.new()
				if json_inv.parse(inv_data) == OK:
					SaveManager.current_save.items = json_inv.data
					print("[TitleScene] ✓ Loaded ", SaveManager.current_save.items.size(), " inventory items into SaveManager")
					
					# CRITICAL: Load the inventory into the actual InventoryData resource
					if PlayerManager.INVENTORY_DATA:
						print("[TitleScene] Loading inventory into InventoryData...")
						PlayerManager.INVENTORY_DATA.parse_save_data(SaveManager.current_save.items)
						print("[TitleScene] ✓ Inventory loaded into InventoryData")
					else:
						print("[TitleScene] ✗ ERROR: PlayerManager.INVENTORY_DATA is null!")
				else:
					print("[TitleScene] ✗ Failed to parse inventory JSON")
					SaveManager.current_save.items = []
			else:
				print("[TitleScene] No inventory data or empty")
				SaveManager.current_save.items = []
			
			# Load quests if available
			var qst_data = logged_in_player_data.get("quests", null)
			if qst_data is String and qst_data != "" and qst_data != "null":
				var json_qst = JSON.new()
				if json_qst.parse(qst_data) == OK:
					SaveManager.current_save.quests = json_qst.data
			
			# Load persistence if available
			var persist_data = logged_in_player_data.get("persistence", null)
			if persist_data is String and persist_data != "" and persist_data != "null":
				var json_persist = JSON.new()
				if json_persist.parse(persist_data) == OK:
					SaveManager.current_save.persistence = json_persist.data
			
			# Set scene path
			var saved_map = logged_in_player_data.get("current_map", "")
			if saved_map != "" and ResourceLoader.exists(saved_map):
				SaveManager.current_save.scene_path = saved_map
			else:
				SaveManager.current_save.scene_path = "res://Levels/final map/scene/safezone.tscn"
			
			# Restore god selection immediately
			var god_id = SaveManager.current_save.character_meta.god_id
			if god_id > 0:
				GodManager.select_god(god_id)
				print("[TitleScene] Restored god from login: ", GodManager.get_god_name(god_id))
				
				# Also restore god skill unlock status
				if logged_in_player_data.get("god_skill_unlocked", false):
					GodManager.unlock_god_skill()
					print("[TitleScene] Restored god skill unlock status")
			
		else:
			# Fresh account - clear any existing character class
			PlayerManager.character_class = ""
			SaveManager.current_save.player.level = 1
		
		
		# Save credentials for auto-login
		save_credentials(username, password)
		
		# Wait a moment then go directly to character selection
		await get_tree().create_timer(1.0).timeout
		
		# Hide login panel
		if has_node("CanvasLayer/Control/LoginBackdrop"):
			var login_backdrop = $CanvasLayer/Control/LoginBackdrop
			login_backdrop.visible = false
		login_panel.visible = false
		
		# Skip mode selection and go straight to character creation (Tutorial mode)
		show_character_panel()
	else:
		var error_msg = result.get("error", "Login failed - no response")
		login_status_label.text = error_msg

func _register_to_nodejs(username: String, password: String) -> void:
	# Use NetworkManager to register
	var nickname = username  # Use username as default nickname
	var result = await NetworkManager.register(username, password, nickname)
	
	create_account_button.disabled = false
	
	if result.success:
		login_status_label.text = "Account created! Logging in..."
		
		# Auto-login after registration
		await get_tree().create_timer(1.0).timeout
		_login_to_nodejs(username, password)
	else:
		login_status_label.text = result.get("error", "Registration failed")


func _on_http_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	login_button.disabled = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		login_status_label.text = "Connection failed"
		login_status_label.modulate = Color.RED
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		login_status_label.text = "Invalid response"
		login_status_label.modulate = Color.RED
		return
	
	var response = json.data
	
	if response.get("success", false):
		# Login successful
		logged_in_player_data = response.get("player_data", {})
		login_status_label.text = "Login successful! Welcome, " + logged_in_player_data.get("nickname", "Player")
		login_status_label.modulate = Color.GREEN
		
		# Save credentials for auto-login next time
		save_credentials(username_input.text, password_input.text)
		
		# Enable online mode
		SaveManager.enable_online_mode()
		
		# Load player data from database
		SaveManager.load_from_database(logged_in_player_data)
		
		# Set player manager data
		PlayerManager.nickname = logged_in_player_data.get("nickname", "Player")
		
		# Set character class if available
		var player_class = logged_in_player_data.get("character_class", "")
		if player_class != "" and player_class != null:
			PlayerManager.selected_class = player_class
		else:
			# Default to Swordsman if no class set
			PlayerManager.selected_class = "Swordsman"
		
		# Wait a moment to show success message
		await get_tree().create_timer(1.0).timeout
		login_panel.visible = false
		
		# After login with account, go directly to server connection
		# The nickname is already set from the account
		_show_server_panel("party")
	else:
		login_status_label.text = response.get("error", "Login failed")
		login_status_label.modulate = Color.RED


func _on_create_account_pressed() -> void:
	# Open website in browser for registration
	OS.shell_open(WEBSITE_URL)
	login_status_label.text = "Opening registration page..."
	login_status_label.modulate = Color.CYAN





func _on_main_menu_offline_pressed() -> void:
	# Offline mode from main menu
	SaveManager.disable_online_mode()
	show_mode_selection_panel()


func _on_quit_button_pressed() -> void:
	# Quit the application
	get_tree().quit()

func _on_logout_button_pressed() -> void:
	"""Logout from character selection - return to login screen"""
	play_audio(button_press_audio)
	
	# Clear session state
	is_session_active = false
	
	# Clear saved credentials (optional - user can choose to save or not)
	# Uncomment the next line if you want to clear credentials on logout
	# clear_saved_credentials()
	
	# Reset player data
	PlayerManager.selected_class = ""
	
	# Stop auto-save if running
	SaveManager.stop_auto_save()
	
	# Show login screen
	_show_main_login_menu()
	


# ============================================
# SAVED CREDENTIALS SYSTEM
# ============================================

const CREDENTIALS_FILE = "user://credentials.dat"
const ENCRYPTION_KEY = "pantheos_mmorpg_secret_key_2024"

func save_credentials(username: String, password: String) -> void:
	"""Save login credentials encrypted"""
	var file = FileAccess.open_encrypted_with_pass(CREDENTIALS_FILE, FileAccess.WRITE, ENCRYPTION_KEY)
	if file:
		var data = {
			"username": username,
			"password": password,
			"saved_at": Time.get_unix_time_from_system()
		}
		file.store_var(data)
		file.close()
	else:
		push_error("[TitleScene] Failed to save credentials")

func load_saved_credentials() -> Dictionary:
	"""Load saved login credentials"""
	if FileAccess.file_exists(CREDENTIALS_FILE):
		var file = FileAccess.open_encrypted_with_pass(CREDENTIALS_FILE, FileAccess.READ, ENCRYPTION_KEY)
		if file:
			var data = file.get_var()
			file.close()
			if data is Dictionary:
				return data
	return {}

func clear_saved_credentials() -> void:
	"""Clear saved login credentials"""
	if FileAccess.file_exists(CREDENTIALS_FILE):
		DirAccess.remove_absolute(CREDENTIALS_FILE)


func _create_corner_buttons() -> void:
	"""Create icon buttons in corners for offline mode and quit"""
	var control = $CanvasLayer/Control
	
	# Create Offline Mode button (bottom-left corner)
	var offline_icon_button = Button.new()
	offline_icon_button.name = "OfflineIconButton"
	offline_icon_button.text = "📴 Offline"
	offline_icon_button.custom_minimum_size = Vector2(120, 40)
	# Use anchors for bottom-left positioning
	offline_icon_button.anchor_left = 0.0
	offline_icon_button.anchor_top = 1.0
	offline_icon_button.anchor_right = 0.0
	offline_icon_button.anchor_bottom = 1.0
	offline_icon_button.offset_left = 20
	offline_icon_button.offset_top = -50  # 50px from bottom
	offline_icon_button.offset_right = 140  # 20 + 120
	offline_icon_button.offset_bottom = -10  # 10px from bottom
	offline_icon_button.grow_vertical = 0  # Grow upward
	offline_icon_button.pressed.connect(_on_offline_mode_button_pressed)
	control.add_child(offline_icon_button)
	
	# Create Quit button (bottom-right corner)
	var quit_icon_button = Button.new()
	quit_icon_button.name = "QuitIconButton"
	quit_icon_button.text = "❌ Quit"
	quit_icon_button.custom_minimum_size = Vector2(120, 40)
	# Use anchors for bottom-right positioning
	quit_icon_button.anchor_left = 1.0
	quit_icon_button.anchor_top = 1.0
	quit_icon_button.anchor_right = 1.0
	quit_icon_button.anchor_bottom = 1.0
	quit_icon_button.offset_left = -140  # 120 + 20 from right
	quit_icon_button.offset_top = -50  # 50px from bottom
	quit_icon_button.offset_right = -20  # 20px from right
	quit_icon_button.offset_bottom = -10  # 10px from bottom
	quit_icon_button.grow_vertical = 0  # Grow upward
	quit_icon_button.pressed.connect(_on_quit_button_pressed)
	control.add_child(quit_icon_button)
