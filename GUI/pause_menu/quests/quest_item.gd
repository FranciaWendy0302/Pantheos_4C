class_name QuestItem
extends Control

@export var quest: Quest
@onready var title_label: Label = $TitleLabel if has_node("TitleLabel") else null

func _init():
	pass

func set_quest(new_quest: Quest):
	quest = new_quest
	if title_label and quest:
		title_label.text = quest.title