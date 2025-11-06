extends Node2D

const TUTORIAL_LEVEL: String = "res://Levels/Area01/tutorial.tscn"

@export var music: AudioStream
@export var button_focus_audio: AudioStream
@export var button_press_audio: AudioStream

@onready var button_new: Button = $CanvasLayer/Control/ButtonNew
@onready var button_continue: Button = $CanvasLayer/Control/ButtonContinue
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

# Character flow UI
@onready var character_panel: PanelContainer = $CanvasLayer/Control/CharacterPanel
@onready var slot1_button: Button = $CanvasLayer/Control/CharacterPanel/VBox/HBox/Slot1Button
@onready var slot2_button: Button = $CanvasLayer/Control/CharacterPanel/VBox/HBox/Slot2Button
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

var selected_slot: int = -1
var selected_class: String = ""


func _ready() -> void:
	get_tree().paused = true
	PlayerManager.player.visible = false
	
	PlayerHud.visible = false
	PauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
	
	if SaveManager.get_save_file() == null:
		button_continue.disabled = true
		button_continue.visible = false
	
	setup_title_screen()
	
	LevelManager.level_load_started.connect(exit_title_screen)
	
	pass
	
func setup_title_screen() -> void:
	AudioManager.play_music(music)
	button_new.pressed.connect(on_enter_game)
	button_continue.pressed.connect(on_exit_game)
	button_new.grab_focus()
	
	button_new.focus_entered.connect(play_audio.bind(button_focus_audio))
	button_continue.focus_entered.connect(play_audio.bind(button_focus_audio))
	# Flow wiring
	slot1_button.pressed.connect(on_select_slot.bind(1))
	slot2_button.pressed.connect(on_select_slot.bind(2))
	back_from_character.pressed.connect(show_main_menu)
	swordsman_button.pressed.connect(on_select_class.bind("Swordsman"))
	archer_button.pressed.connect(on_select_class.bind("Archer"))
	mage_button.pressed.connect(on_select_class.bind("Mage"))
	assassin_button.pressed.connect(on_select_class.bind("Assassin"))
	support_button.pressed.connect(on_select_class.bind("Support"))
	back_from_class.pressed.connect(show_character_panel)
	start_button.pressed.connect(start_game_with_selection)
	pass
	
func on_enter_game() -> void:
	play_audio(button_press_audio)
	show_character_panel()
	pass

func on_exit_game() -> void:
	play_audio(button_press_audio)
	get_tree().quit()
	pass

func show_main_menu() -> void:
	character_panel.visible = false
	class_panel.visible = false
	nickname_panel.visible = false
	button_new.grab_focus()
	pass

func show_character_panel() -> void:
	character_panel.visible = true
	class_panel.visible = false
	nickname_panel.visible = false
	slot1_button.grab_focus()
	pass

func on_select_slot(slot: int) -> void:
	selected_slot = slot
	character_panel.visible = false
	class_panel.visible = true
	swordsman_button.grab_focus()
	pass

func on_select_class(_class: String) -> void:
	# Check if class is locked (Swordsman and Archer are unlocked)
	if _class != "Swordsman" and _class != "Archer":
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
	# Optionally persist selection here via SaveManager if desired
	PlayerManager.nickname = nickname
	if selected_class != "":
		PlayerManager.selected_class = selected_class
	play_audio(button_press_audio)
	LevelManager.load_new_level(TUTORIAL_LEVEL, "", Vector2.ZERO)
	pass

func exit_title_screen() -> void:
	PlayerManager.player.visible = true
	PlayerHud.visible = true
	PauseMenu.process_mode = Node.PROCESS_MODE_ALWAYS
	self.queue_free()
	pass

func play_audio(_a: AudioStream) -> void:
	audio_stream_player.stream = _a
	audio_stream_player.play()
