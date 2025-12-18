class_name InventorySlotUI
extends Control

@export var slot_data: SlotData : set = set_slot_data
@onready var texture_rect: TextureRect = $TextureRect
@onready var quantity_label: Label = $QuantityLabel

func _init():
	pass

func set_slot_data(value: SlotData) -> void:
	slot_data = value
	
	if not slot_data:
		return
		
	if texture_rect and slot_data.item_data:
		texture_rect.texture = slot_data.item_data.icon
		
	if quantity_label:
		if slot_data.quantity > 1:
			quantity_label.text = str(slot_data.quantity)
			quantity_label.show()
		else:
			quantity_label.hide()