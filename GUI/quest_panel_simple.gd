extends PanelContainer

## SIMPLE QUEST PANEL FOR PRESENTATION
## Shows active quests in a clean UI

@onready var quest_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/QuestList
@onready var close_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CloseButton

func _ready():
	visible = false
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Update quest list every second
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_quest_list)
	add_child(timer)
	timer.start()
	
	_update_quest_list()

func _on_close_pressed():
	visible = false

func _update_quest_list():
	if not quest_list:
		return
	
	# Clear existing
	for child in quest_list.get_children():
		child.queue_free()
	
	# Get quests from QuestManager
	var quest_manager = get_node_or_null("/root/QuestManager")
	if not quest_manager:
		_add_quest_label("Quest system loading...")
		return
	
	# Check if has active quests
	if quest_manager.has_method("get_active_quests"):
		var active_quests = quest_manager.get_active_quests()
		
		if active_quests.size() == 0:
			_add_quest_label("No active quests")
			_add_quest_label("\nTalk to NPCs to get quests!")
		else:
			for quest in active_quests:
				_add_quest_item(quest)
	else:
		_add_quest_label("Quest Manager ready!")
		_add_quest_label("\nDemo quests available:")
		_add_quest_label("• Short Quest")
		_add_quest_label("• Recover Lost Flute")
		_add_quest_label("\nTalk to NPCs to start!")

func _add_quest_label(text: String):
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_list.add_child(label)

func _add_quest_item(quest):
	var quest_container = VBoxContainer.new()
	quest_container.add_theme_constant_override("separation", 5)
	
	# Quest title
	var title = Label.new()
	title.text = quest.get("title", "Quest")
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	quest_container.add_child(title)
	
	# Quest description
	var desc = Label.new()
	desc.text = quest.get("description", "Complete the quest")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	quest_container.add_child(desc)
	
	# Quest progress
	var progress = Label.new()
	var current = quest.get("progress", 0)
	var total = quest.get("goal", 1)
	progress.text = "Progress: %d/%d" % [current, total]
	progress.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	quest_container.add_child(progress)
	
	# Separator
	var separator = HSeparator.new()
	quest_container.add_child(separator)
	
	quest_list.add_child(quest_container)

func toggle():
	visible = !visible
