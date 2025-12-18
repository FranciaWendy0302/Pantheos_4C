class_name SlotData
extends Resource

@export var item_data: ItemData
@export var quantity: int = 0

func _init():
	pass

func can_merge_with(other_slot_data: SlotData) -> bool:
	return item_data == other_slot_data.item_data and item_data.stackable

func can_fully_merge_with(other_slot_data: SlotData) -> bool:
	return can_merge_with(other_slot_data) and quantity + other_slot_data.quantity <= item_data.max_stack