extends Node

const TUTORIAL_NPC: NPCResource = preload("res://npc/00_npcs/tutorial_narrator.tres")

var tutorial_shown: bool = false

func _ready() -> void:
	LevelManager.level_loaded.connect(_on_level_loaded)

func _on_level_loaded() -> void:
	# Only show tutorial on the first level if it hasn't been shown yet
	if tutorial_shown:
		return
	
	var current_scene_path = get_tree().current_scene.scene_file_path
	if current_scene_path == "res://Levels/Area01/01.tscn":
		await get_tree().create_timer(0.5).timeout  # Wait for level to fully load
		show_tutorial_dialog()

func show_tutorial_dialog() -> void:
	var tutorial_dialogs: Array[DialogItem] = []
	
	# Create DialogText nodes
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = TUTORIAL_NPC
	dialog1.text = "Welcome, " + PlayerManager.nickname + "! Welcome to Pantheos."
	add_child(dialog1)
	
	var dialog2: DialogText = DialogText.new()
	dialog2.npc_info = TUTORIAL_NPC
	dialog2.text = "This is a multipath adventure. Your journey will be different based on the class you chose and the choices you make."
	add_child(dialog2)
	
	var dialog3: DialogText = DialogText.new()
	dialog3.npc_info = TUTORIAL_NPC
	dialog3.text = "There are five classes available: Swordsman, Archer, Mage, Assassin, and Support. Each class has unique quests tailored to their playstyle and abilities."
	add_child(dialog3)
	
	var dialog4: DialogText = DialogText.new()
	dialog4.npc_info = TUTORIAL_NPC
	dialog4.text = "If you choose a different class, you'll receive different quests that match your class's strengths. Swordsmen protect kingdoms, Archers hunt from afar, Mages unlock ancient mysteries, Assassins work in the shadows, and Support classes aid their allies."
	add_child(dialog4)
	
	var dialog5: DialogText = DialogText.new()
	dialog5.npc_info = TUTORIAL_NPC
	dialog5.text = "Many items can help you clear quests and fight other players. Every piece of equipment has unique skills and abilities. Experiment with different gear combinations to unlock powerful synergies."
	add_child(dialog5)
	
	var dialog6: DialogText = DialogText.new()
	dialog6.npc_info = TUTORIAL_NPC
	dialog6.text = "Your path is yours to forge. Good luck, adventurer!"
	add_child(dialog6)
	
	tutorial_dialogs.append_array([dialog1, dialog2, dialog3, dialog4, dialog5, dialog6])
	
	DialogSystem.show_dialog(tutorial_dialogs)
	
	# Clean up after dialog finishes
	await DialogSystem.finished
	tutorial_shown = true
	for dialog in tutorial_dialogs:
		dialog.queue_free()

