class_name InventoryUI
extends Control

@export var inventory_data: InventoryData
@export var inventory_slot_scene: PackedScene

var inventory_slots: Array[InventorySlotUI] = []

func _init():
	pass

func set_inventory_data(new_inventory_data: InventoryData) -> void:
	inventory_data = new_inventory_data
	populate_item_grid()

func populate_item_grid() -> void:
	if not inventory_data:
		return
		
	# Basic inventory UI population stub
	print("[InventoryUI] Populating inventory grid")

func clear_inventory_slots() -> void:
	for slot in inventory_slots:
		if slot:
			slot.queue_free()
	inventory_slots.clear()