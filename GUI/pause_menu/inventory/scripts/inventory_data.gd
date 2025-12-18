class_name InventoryData
extends Resource

@export var slot_datas: Array[SlotData] = []

signal inventory_updated(inventory_data: InventoryData)
signal inventory_interact(inventory_data: InventoryData, index: int, button: int)

func _init():
	pass

func grab_slot_data(index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if slot_data:
		slot_datas[index] = null
		inventory_updated.emit(self)
		return slot_data
	else:
		return null

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	var return_slot_data: SlotData
	if slot_data and slot_data.can_fully_merge_with(grabbed_slot_data):
		slot_data.quantity += grabbed_slot_data.quantity
	elif slot_data and slot_data.can_merge_with(grabbed_slot_data):
		grabbed_slot_data.quantity += slot_data.quantity - slot_data.item_data.max_stack
		slot_data.quantity = slot_data.item_data.max_stack
		return_slot_data = grabbed_slot_data
	else:
		slot_datas[index] = grabbed_slot_data
		return_slot_data = slot_data
	
	inventory_updated.emit(self)
	return return_slot_data