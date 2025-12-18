class_name AbilityItemData
extends ItemData

@export var ability_id: String = ""
@export var cooldown: float = 0.0
@export var mana_cost: int = 0

func _init():
	super._init()
	stackable = false
	max_stack = 1