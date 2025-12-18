extends CanvasLayer

signal shown
signal hidden
signal preview_stats_changed(item: ItemData)

@onready var audio_stream_player: AudioStreamPlayer = $Control/AudioStreamPlayer

@onready var tab_container: TabContainer = $Control/TabContainer

@onready var button_change_account: Button = $Control/TabContainer/System/VBoxContainer/Button_ChangeAccount
@onready var button_quit_to_title: Button = $Control/TabContainer/System/VBoxContainer/Button_QuitToTitle
@onready var button_quit: Button = $Control/TabContainer/System/VBoxContainer/Button_Quit
@onready var button_close: Button = $Control/TabContainer/System/VBoxContainer/Button_Close
@onready var button_close_inventory: Button = $Control/TabContainer/Inventory/Button_Close_Inventory
@onready var button_close_quest: Button = $Control/TabContainer/Quest/Button_Close_Quest

@onready var item_description: Label = get_node_or_null("Control/TabContainer/Inventory/ItemDescription")

# Item details panel (created dynamically)
var item_details_panel: PanelContainer = null
var consumable_details_panel: PanelContainer = null
var current_selected_slot: SlotData = null

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
	button_change_account.pressed.connect(_on_change_account)
	button_quit_to_title.pressed.connect(_on_quit_to_title)
	button_quit.pressed.connect(_on_quit_application)
	button_close.pressed.connect(_on_close_menu)
	button_close_inventory.pressed.connect(_on_close_menu)
	button_close_quest.pressed.connect(_on_close_menu)
	
	# Add opaque background to Character tab to prevent HUD showing through
	_add_character_tab_background()
	
	# Setup volume controls
	_setup_volume_controls()
	
	# Hide change account button if in offline mode
	if not SaveManager.online_mode:
		button_change_account.visible = false
	
	# Connect to LogoutManager signals if it exists
	var logout_mgr = get_node_or_null("/root/LogoutManager")
	if logout_mgr:
		logout_mgr.logout_cancelled.connect(_on_logout_cancelled)
	
	# CRITICAL: Connect inventory UI to the actual inventory data
	var inventory_ui = $Control/TabContainer/Inventory/PanelContainer/GridContainer
	if inventory_ui:
		# Disconnect from old data if it exists
		if inventory_ui.data:
			if inventory_ui.data.changed.is_connected(inventory_ui.on_inventory_changed):
				inventory_ui.data.changed.disconnect(inventory_ui.on_inventory_changed)
			if inventory_ui.data.equipment_changed.is_connected(inventory_ui.on_inventory_changed):
				inventory_ui.data.equipment_changed.disconnect(inventory_ui.on_inventory_changed)
		
		# Set new data
		inventory_ui.data = PlayerManager.INVENTORY_DATA
		
		# Connect to new data signals
		if not PlayerManager.INVENTORY_DATA.changed.is_connected(inventory_ui.on_inventory_changed):
			PlayerManager.INVENTORY_DATA.changed.connect(inventory_ui.on_inventory_changed)
		if not PlayerManager.INVENTORY_DATA.equipment_changed.is_connected(inventory_ui.on_inventory_changed):
			PlayerManager.INVENTORY_DATA.equipment_changed.connect(inventory_ui.on_inventory_changed)
		
		# Force update the inventory display
		inventory_ui.call_deferred("update_inventory", false)
		print("[PauseMenu] ✓ Connected InventoryUI to PlayerManager.INVENTORY_DATA")
		print("[PauseMenu] ✓ Inventory has ", PlayerManager.INVENTORY_DATA.slots.size(), " slots")
	else:
		print("[PauseMenu] ✗ ERROR: InventoryUI not found!")
	
	# Quick slot UI removed - consumable slot moved to Character tab
	# call_deferred("_create_quick_slot_ui")
	# PlayerManager.INVENTORY_DATA.quick_slot_changed.connect(_update_quick_slot_ui)

# DISABLED - Now using icon buttons instead of pause menu
# The panels (Inventory, Quest, Settings) are still used by the icon buttons
# but the ESC key no longer opens this pause menu
#func _unhandled_input(event: InputEvent) -> void:
#	if event.is_action_pressed("pause"):
#		if is_paused == false:
#			if DialogSystem.is_active:
#				return
#			show_pause_menu()
#		else:
#			hide_pause_menu()	
#		get_viewport().set_input_as_handled()

func show_pause_menu() -> void:
	# Don't pause in online mode - just show menu
	visible = true
	is_paused = true
	tab_container.current_tab = 0
	shown.emit()
	if PlayerManager.player:
		%ArrowCountLabel.text = str(PlayerManager.player.arrow_count)
		%BombCountLabel.text = str(PlayerManager.player.bomb_count)
	
func hide_pause_menu() -> void:
	# Don't unpause - game never paused
	visible = false
	is_paused = false
	hidden.emit()


func _on_close_menu() -> void:
	hide_pause_menu()

func _on_logout_cancelled() -> void:
	"""Called when logout is cancelled - don't reopen pause menu"""
	# Just log it, don't reopen pause menu
	print("[PauseMenu] Logout cancelled - player can continue playing")

func _on_change_account() -> void:
	# Confirm before changing account
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Save progress and change account?\nYou will return to the login screen."
	confirm_dialog.ok_button_text = "Change Account"
	confirm_dialog.cancel_button_text = "Cancel"
	add_child(confirm_dialog)
	confirm_dialog.confirmed.connect(_do_change_account)
	confirm_dialog.popup_centered()

func _do_change_account() -> void:
	# Save game before logout
	SaveManager.save_game()
	await get_tree().create_timer(0.5).timeout  # Wait for save to complete
	
	# Clear saved credentials
	const CREDENTIALS_FILE = "user://credentials.dat"
	if FileAccess.file_exists(CREDENTIALS_FILE):
		DirAccess.remove_absolute(CREDENTIALS_FILE)
		print("[PauseMenu] Credentials cleared for account change")
	
	# Stop auto-save
	SaveManager.stop_auto_save()
	
	# Reset online mode
	SaveManager.online_mode = false
	
	# Reset player data
	PlayerManager.player_id = 0
	PlayerManager.nickname = ""
	PlayerManager.selected_class = ""
	
	# Clear session state so title screen shows login
	var title_scene_script = load("res://title_scene/title_scene.gd")
	if title_scene_script:
		title_scene_script.is_session_active = false
	
	# Return to title screen
	hide_pause_menu()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title_scene/title_scene.tscn")

func _on_quit_to_title() -> void:
	# Return to character selection with 30-second countdown
	# This keeps the player logged into their account but returns to character selection
	hide_pause_menu()
	
	# Check if LogoutManager exists (it's optional)
	var logout_mgr = get_node_or_null("/root/LogoutManager")
	
	if SaveManager.online_mode and logout_mgr:
		# Online mode - use 30 second countdown with quit_to_title mode
		# This will keep the account logged in
		var can_logout = logout_mgr.start_logout(true) # true = quit to title mode
		if not can_logout:
			# In combat or already logging out
			show_pause_menu()
			return
		# LogoutManager will handle the rest (save, wait, return to title with account)
	else:
		# Offline mode or no LogoutManager - immediate return to title
		SaveManager.save_game()
		await get_tree().create_timer(0.5).timeout
		
		# Stop auto-save but keep online mode and account data
		SaveManager.stop_auto_save()
		
		# Clear only the current character's class
		PlayerManager.selected_class = ""
		
		# Mark session as active so it goes to character selection
		var title_scene_script = load("res://title_scene/title_scene.gd")
		if title_scene_script:
			title_scene_script.is_session_active = true
		
		# Return to title screen (will show character selection)
		get_tree().change_scene_to_file("res://title_scene/title_scene.tscn")

func _on_quit_application() -> void:
	# Use logout system for safe logout
	hide_pause_menu()
	
	# Check if LogoutManager exists (it's optional)
	var logout_mgr = get_node_or_null("/root/LogoutManager")
	
	if SaveManager.online_mode and logout_mgr:
		# Online mode - use 30 second logout countdown, then quit
		var can_logout = logout_mgr.start_logout()
		if not can_logout:
			# In combat or already logging out
			show_pause_menu()
			return
		# Wait for logout to complete, then quit
		await logout_mgr.logout_completed
		get_tree().quit()
	else:
		# Offline mode or no LogoutManager - immediate quit
		SaveManager.save_game()
		await get_tree().create_timer(0.5).timeout
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
			var description = ""
			
			# Use detailed description for equipable items
			if slot.item_data is EquipableItemData:
				var equipable = slot.item_data as EquipableItemData
				# Use plain text version (false) since item_description is a Label, not RichTextLabel
				description = equipable.get_detailed_description(false)
				
				# Check if player can equip it
				if not equipable.can_be_equipped_by_class(PlayerManager.character_class):
					description += "\n\n[Cannot Equip - Wrong Class]"
					set_item_description_color(Color(1.0, 0.5, 0.5))  # Red tint
				else:
					set_item_description_color(Color.WHITE)
			else:
				# Regular item description
				description = slot.item_data.description
				set_item_description_color(Color.WHITE)
			
			update_item_description(description)
			preview_stats(slot.item_data)
	else:
		update_item_description("")
		preview_stats(null)
		set_item_description_color(Color.WHITE)

func update_item_description(new_text: String) -> void:
	if item_description:
		item_description.text = new_text

func set_item_description_color(color: Color) -> void:
	if item_description:
		item_description.modulate = color

func play_audio(audio: AudioStream) -> void:
	audio_stream_player.stream = audio
	audio_stream_player.play()

func preview_stats(item: ItemData) -> void:
	preview_stats_changed.emit(item)
	pass

func update_ability_items(items: Array[String]) -> void:
	# AbilityGridContainer was removed - this function is no longer needed
	# Abilities are now managed through the ability system
	pass

func show_item_details_panel(slot: SlotData) -> void:
	"""Show detailed item panel with Equip/Unequip button"""
	if not slot or not slot.item_data:
		return
	
	# Clear old description first
	update_item_description("")
	set_item_description_color(Color.WHITE)
	
	current_selected_slot = slot
	var item = slot.item_data as EquipableItemData
	
	# Create panel if it doesn't exist
	if not item_details_panel:
		_create_item_details_panel()
	
	# Update panel content
	var title_label = item_details_panel.get_node("VBox/TitleLabel")
	var desc_label = item_details_panel.get_node("VBox/DescLabel")
	var class_label = item_details_panel.get_node("VBox/ClassLabel")
	var stats_label = item_details_panel.get_node("VBox/StatsLabel")
	var equip_button = item_details_panel.get_node("VBox/ButtonContainer/EquipButton")
	var close_button = item_details_panel.get_node("VBox/ButtonContainer/CloseButton")
	
	# Set item info
	title_label.text = item.name
	desc_label.text = item.description
	
	# Class requirement
	var required_class = item.get_class_requirement_name()
	var can_equip = item.can_be_equipped_by_class(PlayerManager.character_class)
	
	if required_class != "Any Class":
		class_label.text = "Required Class: " + required_class
		if not can_equip:
			class_label.modulate = Color.RED
		else:
			class_label.modulate = Color.YELLOW
		class_label.visible = true
	else:
		class_label.visible = false
	
	# Stats
	var stats_text = ""
	for modifier in item.modifiers:
		match modifier.type:
			0: # ATTACK
				stats_text += "Attack: +" + str(modifier.value) + "\n"
			1: # DEFENSE
				stats_text += "Defense: +" + str(modifier.value) + "\n"
			2: # SPEED
				stats_text += "Speed: +" + str(modifier.value) + "\n"
	stats_label.text = stats_text if stats_text != "" else "No stat bonuses"
	
	# Check if item is equipped
	var is_equipped = _is_item_equipped(slot)
	
	# Update button
	if is_equipped:
		equip_button.text = "Unequip"
		equip_button.disabled = false
	elif can_equip:
		equip_button.text = "Equip"
		equip_button.disabled = false
	else:
		equip_button.text = "Cannot Equip"
		equip_button.disabled = true
	
	# Move panel to current tab if needed
	_move_panel_to_current_tab(item_details_panel)
	
	# Show panel
	item_details_panel.visible = true
	item_details_panel.mouse_filter = Control.MOUSE_FILTER_STOP

func _create_item_details_panel() -> void:
	"""Create the item details panel UI"""
	item_details_panel = PanelContainer.new()
	item_details_panel.name = "ItemDetailsPanel"
	
	# Position in center of inventory tab
	item_details_panel.set_anchors_preset(Control.PRESET_CENTER)
	item_details_panel.custom_minimum_size = Vector2(280, 200)
	item_details_panel.offset_left = -140
	item_details_panel.offset_right = 140
	item_details_panel.offset_top = -100
	item_details_panel.offset_bottom = 100
	item_details_panel.z_index = 10
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = Color(0.6, 0.6, 0.7)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	item_details_panel.add_theme_stylebox_override("panel", style)
	
	# VBox container
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 8)
	item_details_panel.add_child(vbox)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	vbox.add_child(margin)
	margin.add_child(VBoxContainer.new())
	var content_vbox = margin.get_child(0)
	content_vbox.add_theme_constant_override("separation", 6)
	
	# Title
	var title = Label.new()
	title.name = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	vbox.add_child(title)
	
	# Description
	var desc = Label.new()
	desc.name = "DescLabel"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(250, 0)
	desc.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc)
	
	# Class requirement
	var class_req = Label.new()
	class_req.name = "ClassLabel"
	class_req.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_req.add_theme_font_size_override("font_size", 11)
	vbox.add_child(class_req)
	
	# Stats
	var stats = Label.new()
	stats.name = "StatsLabel"
	stats.add_theme_font_size_override("font_size", 11)
	stats.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
	vbox.add_child(stats)
	
	# Button container
	var button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 10)
	vbox.add_child(button_container)
	
	# Equip button
	var equip_btn = Button.new()
	equip_btn.name = "EquipButton"
	equip_btn.text = "Equip"
	equip_btn.custom_minimum_size = Vector2(100, 30)
	equip_btn.pressed.connect(_on_equip_button_pressed)
	button_container.add_child(equip_btn)
	
	# Close button
	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(100, 30)
	close_btn.pressed.connect(_on_item_details_close)
	button_container.add_child(close_btn)
	
	# Add to the currently active tab
	var current_tab = tab_container.get_current_tab_control()
	if current_tab:
		current_tab.add_child(item_details_panel)
	else:
		# Fallback to inventory tab
		var inventory_tab = $Control/TabContainer/Inventory
		inventory_tab.add_child(item_details_panel)
	item_details_panel.visible = false

func _on_equip_button_pressed() -> void:
	"""Handle equip/unequip button press"""
	if not current_selected_slot:
		return
	
	PlayerManager.INVENTORY_DATA.equip_item(current_selected_slot)
	
	# Close panel and refresh
	_on_item_details_close()

func _on_item_details_close() -> void:
	"""Close item details panel"""
	if item_details_panel:
		item_details_panel.visible = false
		item_details_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_selected_slot = null
	
	# Clear the old item description
	update_item_description("")
	set_item_description_color(Color.WHITE)

func _is_item_equipped(slot: SlotData) -> bool:
	"""Check if an item is currently equipped"""
	return PlayerManager.INVENTORY_DATA.is_item_equipped(slot)

func _move_panel_to_current_tab(panel: Control) -> void:
	"""Move a panel to the currently active tab"""
	if not panel:
		return
	
	var current_tab = tab_container.get_current_tab_control()
	if not current_tab:
		return
	
	# Check if panel is already in the correct tab
	if panel.get_parent() == current_tab:
		return
	
	# Remove from old parent
	if panel.get_parent():
		panel.get_parent().remove_child(panel)
	
	# Add to current tab
	current_tab.add_child(panel)

func show_consumable_details_panel(slot: SlotData) -> void:
	"""Show detailed consumable panel with Assign/Use buttons"""
	if not slot or not slot.item_data:
		return
	
	# Clear old description first
	update_item_description("")
	set_item_description_color(Color.WHITE)
	
	current_selected_slot = slot
	var item = slot.item_data
	
	# Create panel if it doesn't exist
	if not consumable_details_panel:
		_create_consumable_details_panel()
	
	# Update panel content
	var title_label = consumable_details_panel.get_node("VBox/TitleLabel")
	var desc_label = consumable_details_panel.get_node("VBox/DescLabel")
	var quantity_label = consumable_details_panel.get_node("VBox/QuantityLabel")
	var assign_button = consumable_details_panel.get_node("VBox/ButtonContainer/AssignButton")
	var use_button = consumable_details_panel.get_node("VBox/ButtonContainer/UseButton")
	var close_button = consumable_details_panel.get_node("VBox/ButtonContainer/CloseButton")
	
	# Set item info
	title_label.text = item.name
	desc_label.text = item.description
	quantity_label.text = "Quantity: " + str(slot.quantity)
	
	# Check if in quick slot
	var is_in_quick_slot = PlayerManager.INVENTORY_DATA.is_in_quick_slot(slot)
	
	if is_in_quick_slot:
		assign_button.text = "Unassign from [1]"
	else:
		assign_button.text = "Assign to [1]"
	
	# Move panel to current tab if needed
	_move_panel_to_current_tab(consumable_details_panel)
	
	# Show panel
	consumable_details_panel.visible = true
	consumable_details_panel.mouse_filter = Control.MOUSE_FILTER_STOP

func _create_consumable_details_panel() -> void:
	"""Create the consumable details panel UI"""
	consumable_details_panel = PanelContainer.new()
	consumable_details_panel.name = "ConsumableDetailsPanel"
	
	# Position in center of inventory tab
	consumable_details_panel.set_anchors_preset(Control.PRESET_CENTER)
	consumable_details_panel.custom_minimum_size = Vector2(280, 180)
	consumable_details_panel.offset_left = -140
	consumable_details_panel.offset_right = 140
	consumable_details_panel.offset_top = -90
	consumable_details_panel.offset_bottom = 90
	consumable_details_panel.z_index = 10
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = Color(0.6, 0.8, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	consumable_details_panel.add_theme_stylebox_override("panel", style)
	
	# VBox container
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 8)
	consumable_details_panel.add_child(vbox)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	vbox.add_child(margin)
	
	# Title
	var title = Label.new()
	title.name = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
	vbox.add_child(title)
	
	# Description
	var desc = Label.new()
	desc.name = "DescLabel"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(250, 0)
	desc.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc)
	
	# Quantity
	var quantity = Label.new()
	quantity.name = "QuantityLabel"
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity.add_theme_font_size_override("font_size", 12)
	quantity.add_theme_color_override("font_color", Color(1, 1, 0.7))
	vbox.add_child(quantity)
	
	# Button container
	var button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 8)
	vbox.add_child(button_container)
	
	# Assign button
	var assign_btn = Button.new()
	assign_btn.name = "AssignButton"
	assign_btn.text = "Assign to [1]"
	assign_btn.custom_minimum_size = Vector2(90, 28)
	assign_btn.pressed.connect(_on_assign_consumable_pressed)
	button_container.add_child(assign_btn)
	
	# Use button
	var use_btn = Button.new()
	use_btn.name = "UseButton"
	use_btn.text = "Use"
	use_btn.custom_minimum_size = Vector2(60, 28)
	use_btn.pressed.connect(_on_use_consumable_pressed)
	button_container.add_child(use_btn)
	
	# Close button
	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(60, 28)
	close_btn.pressed.connect(_on_consumable_details_close)
	button_container.add_child(close_btn)
	
	# Add to the currently active tab
	var current_tab = tab_container.get_current_tab_control()
	if current_tab:
		current_tab.add_child(consumable_details_panel)
	else:
		# Fallback to inventory tab
		var inventory_tab = $Control/TabContainer/Inventory
		inventory_tab.add_child(consumable_details_panel)
	consumable_details_panel.visible = false

func _on_assign_consumable_pressed() -> void:
	"""Handle assign/unassign consumable to quick slot"""
	if not current_selected_slot:
		return
	
	var is_assigned = PlayerManager.INVENTORY_DATA.is_in_quick_slot(current_selected_slot)
	
	if is_assigned:
		# Unassign
		PlayerManager.INVENTORY_DATA.quick_slot = null
		PlayerManager.INVENTORY_DATA.quick_slot_changed.emit()
		print("[PauseMenu] Unassigned from quick slot")
	else:
		# Assign
		PlayerManager.INVENTORY_DATA.assign_to_quick_slot(current_selected_slot)
	
	# Refresh panel
	show_consumable_details_panel(current_selected_slot)

func _on_use_consumable_pressed() -> void:
	"""Handle use consumable button"""
	if not current_selected_slot:
		return
	
	var was_used = current_selected_slot.item_data.use()
	if was_used:
		current_selected_slot.quantity -= 1
		
		if current_selected_slot.quantity <= 0:
			# Remove from inventory
			var slot_index = PlayerManager.INVENTORY_DATA.slots.find(current_selected_slot)
			if slot_index != -1:
				PlayerManager.INVENTORY_DATA.slots[slot_index] = null
			_on_consumable_details_close()
		else:
			# Refresh panel with new quantity
			show_consumable_details_panel(current_selected_slot)

func _on_consumable_details_close() -> void:
	"""Close consumable details panel"""
	if consumable_details_panel:
		consumable_details_panel.visible = false
		consumable_details_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_selected_slot = null
	
	# Clear the old item description
	update_item_description("")
	set_item_description_color(Color.WHITE)

# Quick Slot UI - REMOVED (consumable slot is now in Character tab)
#var quick_slot_panel: PanelContainer = null
#var quick_slot_texture: TextureRect = null
#var quick_slot_label: Label = null
#var quick_slot_key_label: Label = null
#
#func _create_quick_slot_ui() -> void:
#	pass
#
#func _update_quick_slot_ui() -> void:
#	pass

func _add_character_tab_background() -> void:
	"""Add an opaque background to Character tab to prevent HUD showing through"""
	var character_tab = $Control/TabContainer/Character
	if not character_tab:
		return
	
	# Create a ColorRect background
	var background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0.1, 0.1, 0.12, 1.0)  # Dark opaque background
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.z_index = -1  # Behind everything else in the tab
	
	# Add as first child so it's behind the CharacterStatus
	character_tab.add_child(background)
	character_tab.move_child(background, 0)
