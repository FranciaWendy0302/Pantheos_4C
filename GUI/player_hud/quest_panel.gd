extends Control

const QUEST_ITEM: PackedScene = preload("res://GUI/pause_menu/quests/quest_item.tscn")

@onready var quest_container: VBoxContainer = $Panel/ScrollContainer/MarginContainer/VBoxContainer
@onready var scroll_container: ScrollContainer = $Panel/ScrollContainer
@onready var panel: PanelContainer = $Panel

var quest_items: Array[QuestItem] = []

func _ready() -> void:
	visible = true
	# Connect to quest manager updates
	QuestManager.quest_updated.connect(_on_quest_updated)
	update_quest_list()
	pass

func _on_quest_updated(_quest: Dictionary) -> void:
	update_quest_list()
	pass

func update_quest_list() -> void:
	# Clear existing quest items
	for item in quest_items:
		if is_instance_valid(item):
			item.queue_free()
	quest_items.clear()
	
	# Add current quests
	QuestManager.sort_quests()
	for q in QuestManager.current_quests:
		var quest_data: Quest = QuestManager.find_quest_by_title(q.title)
		if quest_data == null:
			continue
		
		var new_q_item: QuestItem = QUEST_ITEM.instantiate()
		quest_container.add_child(new_q_item)
		new_q_item.initialize(quest_data, q)
		quest_items.append(new_q_item)
	pass

func toggle_visibility() -> void:
	visible = !visible
	pass

