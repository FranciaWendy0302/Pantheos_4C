extends CanvasLayer

signal shown
signal hidden
signal preview_stats_changed(item: ItemData)

@onready var audio_stream_player: AudioStreamPlayer = $Control/AudioStreamPlayer

@onready var tab_container: TabContainer = $Control/TabContainer

@onready var button_quit: Button = $Control/TabContainer/System/VBoxContainer/Button_Quit
@onready var button_close: Button = $Control/TabContainer/System/VBoxContainer/Button_Close
@onready var button_close_inventory: Button = $Control/TabContainer/Inventory/Button_Close_Inventory
@onready var button_close_quest: Button = $Control/TabContainer/Quest/Button_Close_Quest

@onready var item_description: Label = $Control/TabContainer/Inventory/ItemDescription

# Volume controls
@onready var master_volume_slider: HSlider = $Control/TabContainer/System/VBoxContainer/MasterVolumeContainer/MasterVolumeSlider
@onready var music_volume_slider: HSlider = $Control/TabContainer/System/VBoxContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $Control/TabContainer/System/VBoxContainer/SFXVolumeContainer/SFXVolumeSlider
@onready var mute_button: Button = $Control/TabContainer/System/VBoxContainer/Button_Mute


var is_paused: bool = false
var is_muted: bool = false
var saved_volumes: Dictionary = {}

func _ready() -> void:
	hide_pause_menu()	
	button_quit.pressed.connect(_on_quit_menu)
	button_close.pressed.connect(_on_close_menu)
	button_close_inventory.pressed.connect(_on_close_menu)
	button_close_quest.pressed.connect(_on_close_menu)
	
	# Setup volume controls
	_setup_volume_controls()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_paused == false:
			if DialogSystem.is_active:
				return
			show_pause_menu()
		else:
			hide_pause_menu()	
		get_viewport().set_input_as_handled()

func show_pause_menu() -> void:
	get_tree().paused = true
	visible = true
	is_paused = true
	tab_container.current_tab = 0
	shown.emit()
	if PlayerManager.player:
		%ArrowCountLabel.text = str(PlayerManager.player.arrow_count)
		%BombCountLabel.text = str(PlayerManager.player.bomb_count)
	
func hide_pause_menu() -> void:
	get_tree().paused = false
	visible = false
	is_paused = false
	hidden.emit()


func _on_close_menu() -> void:
	hide_pause_menu()

func _on_quit_menu() -> void:
	# Save game before quitting
	SaveManager.save_game()
	get_tree().quit()

func _setup_volume_controls() -> void:
	# Get current bus indices
	var master_bus_index = AudioServer.get_bus_index("Master")
	var music_bus_index = AudioServer.get_bus_index("Music")
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	# Initialize sliders with current volumes (convert dB to linear 0-1 range)
	if master_volume_slider:
		var master_db = AudioServer.get_bus_volume_db(master_bus_index)
		master_volume_slider.value = db_to_linear(master_db)
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	
	if music_volume_slider:
		var music_db = AudioServer.get_bus_volume_db(music_bus_index)
		music_volume_slider.value = db_to_linear(music_db)
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
	
	if sfx_volume_slider:
		var sfx_db = AudioServer.get_bus_volume_db(sfx_bus_index)
		sfx_volume_slider.value = db_to_linear(sfx_db)
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Setup mute button
	if mute_button:
		is_muted = AudioServer.is_bus_mute(master_bus_index)
		_update_mute_button_text()
		mute_button.pressed.connect(_on_mute_button_pressed)

func _on_master_volume_changed(value: float) -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	
	# Update saved volumes if not muted
	if not is_muted:
		saved_volumes["Master"] = value

func _on_music_volume_changed(value: float) -> void:
	var music_bus_index = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value))
	
	# Update saved volumes if not muted
	if not is_muted:
		saved_volumes["Music"] = value

func _on_sfx_volume_changed(value: float) -> void:
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
	
	# Update saved volumes if not muted
	if not is_muted:
		saved_volumes["SFX"] = value

func _on_mute_button_pressed() -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	var music_bus_index = AudioServer.get_bus_index("Music")
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	is_muted = !is_muted
	
	if is_muted:
		# Save current volumes before muting
		saved_volumes["Master"] = master_volume_slider.value if master_volume_slider else 1.0
		saved_volumes["Music"] = music_volume_slider.value if music_volume_slider else 1.0
		saved_volumes["SFX"] = sfx_volume_slider.value if sfx_volume_slider else 1.0
		
		# Mute all buses
		AudioServer.set_bus_mute(master_bus_index, true)
		AudioServer.set_bus_mute(music_bus_index, true)
		AudioServer.set_bus_mute(sfx_bus_index, true)
	else:
		# Restore volumes from saved values
		AudioServer.set_bus_mute(master_bus_index, false)
		AudioServer.set_bus_mute(music_bus_index, false)
		AudioServer.set_bus_mute(sfx_bus_index, false)
		
		# Restore slider values
		if master_volume_slider and saved_volumes.has("Master"):
			master_volume_slider.value = saved_volumes["Master"]
		if music_volume_slider and saved_volumes.has("Music"):
			music_volume_slider.value = saved_volumes["Music"]
		if sfx_volume_slider and saved_volumes.has("SFX"):
			sfx_volume_slider.value = saved_volumes["SFX"]
	
	_update_mute_button_text()

func _update_mute_button_text() -> void:
	if mute_button:
		mute_button.text = "Unmute" if is_muted else "Mute"
	
func focused_item_changed(slot: SlotData) -> void:
	if slot:
		if slot.item_data:
			update_item_description(slot.item_data.description)
			preview_stats(slot.item_data)
	else:
		update_item_description("")
		preview_stats(null)

func update_item_description(new_text: String) -> void:
	item_description.text = new_text

func play_audio(audio: AudioStream) -> void:
	audio_stream_player.stream = audio
	audio_stream_player.play()

func preview_stats(item: ItemData) -> void:
	preview_stats_changed.emit(item)
	pass

func update_ability_items(items: Array[String]) -> void:
	var item_buttons: Array[Node] = %AbilityGridContainer.get_children()
	for i in item_buttons.size():
		if items[i] == "":
			item_buttons[i].visible = false
		else:
			item_buttons[i].visible = true
	pass
