# God Selection Integration for Title Scene
# Add this to your title_scene.gd to integrate god selection

# Instructions:
# 1. Add these variables after your existing variables:
#    var selected_god: int = 0
#    var god_selection_panel: Control
#
# 2. In _ready(), after creating login UI, add:
#    _create_god_selection_panel()
#
# 3. In on_select_class(), change the flow to go to god selection instead of nickname:
#    Replace: nickname_panel.visible = true
#    With: show_god_selection_panel()
#
# 4. Add these functions:

func _create_god_selection_panel() -> void:
	"""Create the god selection panel"""
	var god_scene = load("res://GUI/god_selection/god_selection_panel.tscn")
	if god_scene:
		god_selection_panel = god_scene.instantiate()
		$CanvasLayer/Control.add_child(god_selection_panel)
		god_selection_panel.god_selected.connect(_on_god_selected)
		god_selection_panel.back_pressed.connect(_on_back_from_god)
		god_selection_panel.visible = false

func show_god_selection_panel() -> void:
	"""Show god selection panel"""
	character_panel.visible = false
	class_panel.visible = false
	nickname_panel.visible = false
	god_selection_panel.visible = true
	god_selection_panel.show_panel()

func _on_god_selected(god_id: int) -> void:
	"""Called when player selects a god"""
	selected_god = god_id
	
	# Show god info
	var god_data = GodManager.get_god_data(god_id)
	print("[TitleScene] Selected god: ", god_data.name)
	
	# Move to nickname panel
	god_selection_panel.visible = false
	nickname_panel.visible = true
	
	# Update class display to show god info
	class_display_label.text = "Class: " + selected_class + "\nGod: " + god_data.name
	nick_input.grab_focus()

func _on_back_from_god() -> void:
	"""Go back from god selection to class selection"""
	god_selection_panel.visible = false
	class_panel.visible = true
	swordsman_button.grab_focus()

# 5. In start_game_with_selection(), after setting class, add:
#    GodManager.select_god(selected_god)
#    
#    And when saving to database, include god_id:
#    player_data["god_id"] = selected_god

# 6. In save_character_slot(), add god_id to the save data:
#    slot_save.character_meta.god_id = selected_god

# 7. In get_character_slot_info(), add god info:
#    info["god_id"] = save_dict.character_meta.get("god_id", 0)
#    info["god_name"] = GodManager.get_god_name(info.god_id)
