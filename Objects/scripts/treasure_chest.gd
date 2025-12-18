class_name TreasureChest
extends StaticBody2D

@export var loot_items: Array[ItemData] = []
@export var is_opened: bool = false
@export var interaction_range: float = 50.0

signal chest_opened(chest: TreasureChest)
signal loot_obtained(items: Array[ItemData])

func _init():
	pass

func can_interact_with_player(player_position: Vector2) -> bool:
	return not is_opened and global_position.distance_to(player_position) <= interaction_range

func open_chest():
	if is_opened:
		return
		
	is_opened = true
	chest_opened.emit(self)
	loot_obtained.emit(loot_items)