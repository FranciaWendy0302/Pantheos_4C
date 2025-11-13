extends Node2D

const TUTORIAL_LEVEL: String = "res://Levels/Area01/tutorial.tscn"

@export var music: AudioStream
@export var button_focus_audio: AudioStream
@export var button_press_audio: AudioStream

@onready var button_new: Button = $CanvasLayer/Control/ButtonNew
@onready var button_continue: Button = $CanvasLayer/Control/ButtonContinue
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var title_sprite: Sprite2D = $CanvasLayer/Control/Sprite2D
@onready var background_overlay: ColorRect = $CanvasLayer/Control/ColorRect

# Mode selection UI
@onready var mode_selection_backdrop: ColorRect = $CanvasLayer/Control/ModeSelectionBackdrop
@onready var mode_selection_panel: PanelContainer = $CanvasLayer/Control/ModeSelectionPanel
@onready var tutorial_button: Button = $CanvasLayer/Control/ModeSelectionPanel/VBox/TutorialButton
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
var pending_mode: String = "party"


func _ready() -> void:
	get_tree().paused = true
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		PlayerManager.player.visible = false
	
	PlayerHud.visible = false
	PauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Check if any slot has a save file
	var has_save = SaveManager.slot_exists(1) or SaveManager.slot_exists(2)
	if not has_save:
		button_continue.disabled = true
		button_continue.visible = false
	
	setup_title_screen()
	update_slot_buttons()
	
	LevelManager.level_load_started.connect(exit_title_screen)
	
	pass
	
func setup_title_screen() -> void:
	AudioManager.play_music(music)
	button_new.pressed.connect(on_new_game)
	button_continue.pressed.connect(on_exit_game)
	button_new.grab_focus()
	
	button_new.focus_entered.connect(play_audio.bind(button_focus_audio))
	button_continue.focus_entered.connect(play_audio.bind(button_focus_audio))
	
	# Mode selection UI wiring
	tutorial_button.pressed.connect(on_select_tutorial_mode)
	online_button.pressed.connect(on_select_online_mode)
	back_from_mode_button.pressed.connect(show_main_menu)
	
	# Flow wiring
	slot1_button.pressed.connect(on_select_slot.bind(1))
	slot2_button.pressed.connect(on_select_slot.bind(2))
	slot1_delete_button.pressed.connect(on_delete_slot.bind(1))
	slot2_delete_button.pressed.connect(on_delete_slot.bind(2))
	confirm_button.pressed.connect(on_confirm_slot)
	back_from_character.pressed.connect(show_main_menu)
	swordsman_button.pressed.connect(on_select_class.bind("Swordsman"))
	# Lock Archer button
	archer_button.disabled = true
	archer_button.pressed.connect(on_class_locked)
	mage_button.pressed.connect(on_select_class.bind("Mage"))
	assassin_button.pressed.connect(on_select_class.bind("Assassin"))
	support_button.pressed.connect(on_select_class.bind("Support"))
	back_from_class.pressed.connect(show_character_panel)
	start_button.pressed.connect(start_game_with_selection)

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
		server_mode_label.text = "Mode: " + mode
	else:
		server_mode_label.text = "Select Mode: Party or Duel"
	# Set default nickname if available
	if server_nickname_input.text == "":
		server_nickname_input.text = PlayerManager.nickname if PlayerManager.nickname != "" else ""
	server_backdrop.visible = true
	server_panel.visible = true
	mode_selection_backdrop.visible = false
	mode_selection_panel.visible = false
	button_new.visible = false
	button_continue.visible = false
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

func _on_network_connected(mode: String) -> void:
	# Connection successful - transition to tutorial scene
	print("Connected to server in %s mode, loading tutorial..." % mode)
	# Unpause the game before loading (title screen pauses it)
	get_tree().paused = false
	LevelManager.load_new_level("res://Levels/Area01/tutorial.tscn", "PlayerSpawn", Vector2.ZERO)
	pass

func on_new_game() -> void:
	play_audio(button_press_audio)
	show_mode_selection_panel()
	pass

func show_mode_selection_panel() -> void:
	mode_selection_backdrop.visible = true
	mode_selection_panel.visible = true
	character_panel.visible = false
	class_panel.visible = false
	nickname_panel.visible = false
	server_backdrop.visible = false
	server_panel.visible = false
	button_new.visible = false
	button_continue.visible = false
	title_sprite.visible = false
	background_overlay.visible = false
	tutorial_button.grab_focus()
	pass

func on_select_tutorial_mode() -> void:
	play_audio(button_press_audio)
	mode_selection_backdrop.visible = false
	mode_selection_panel.visible = false
	show_character_panel()
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
	mode_selection_backdrop.visible = false
	mode_selection_panel.visible = false
	character_panel.visible = false
	class_panel.visible = false
	nickname_panel.visible = false
	server_backdrop.visible = false
	server_panel.visible = false
	button_new.visible = true
	button_continue.visible = true
	title_sprite.visible = true
	background_overlay.visible = true
	button_new.grab_focus()
	pass

func show_character_panel() -> void:
	mode_selection_backdrop.visible = false
	mode_selection_panel.visible = false
	character_panel.visible = true
	class_panel.visible = false
	nickname_panel.visible = false
	server_backdrop.visible = false
	server_panel.visible = false
	button_new.visible = false
	button_continue.visible = false
	title_sprite.visible = false
	background_overlay.visible = false
	selected_slot = -1
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
	
	# Delete the character slot
	if SaveManager.delete_character_slot(slot):
		# If deleted slot was selected, clear selection
		if selected_slot == slot:
			selected_slot = -1
		# Update UI after deletion
		update_slot_buttons()
		update_confirm_button()
		# Check if continue button should be disabled
		var has_save = SaveManager.slot_exists(1) or SaveManager.slot_exists(2)
		if not has_save:
			button_continue.disabled = true
			button_continue.visible = false
	else:
		push_error("Failed to delete character slot " + str(slot))
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
			SaveManager.load_game(selected_slot)
			return
	
	# Otherwise, create new character
	character_panel.visible = false
	class_panel.visible = true
	swordsman_button.grab_focus()
	pass

func on_select_class(_class: String) -> void:
	# Check if class is locked (only Swordsman is unlocked)
	if _class != "Swordsman":
		on_class_locked()
		return
	
	selected_class = _class
	class_panel.visible = false
	nickname_panel.visible = true
	class_display_label.text = "Class: " + _class
	nick_input.grab_focus()
	pass

func on_class_locked() -> void:
	locked_message_label.visible = true
	play_audio(button_press_audio)
	await get_tree().create_timer(2.0).timeout
	locked_message_label.visible = false
	pass

func start_game_with_selection() -> void:
	var nickname := nick_input.text.strip_edges()
	if nickname == "":
		nickname = "Adventurer"
	
	# Set the current slot
	SaveManager.current_slot = selected_slot
	
	# Save character data to the selected slot
	SaveManager.save_character_slot(selected_slot, nickname, selected_class)
	
	# Set player manager data
	PlayerManager.nickname = nickname
	if selected_class != "":
		PlayerManager.selected_class = selected_class
	
	play_audio(button_press_audio)
	LevelManager.load_new_level(TUTORIAL_LEVEL, "", Vector2.ZERO)
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
