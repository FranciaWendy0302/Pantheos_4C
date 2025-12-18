class_name Quest
extends Resource

@export var quest_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var is_complete: bool = false
@export var progress: int = 0
@export var required: int = 0
@export var reward_xp: int = 0
@export var reward_gold: int = 0

signal quest_updated(quest: Quest)
signal quest_completed(quest: Quest)

func _init():
	pass

func update_progress(amount: int):
	progress = min(progress + amount, required)
	quest_updated.emit(self)
	
	if progress >= required and not is_complete:
		complete_quest()

func complete_quest():
	is_complete = true
	quest_completed.emit(self)