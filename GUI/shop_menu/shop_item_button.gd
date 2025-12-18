class_name ShopItemButton
extends Button

@export var item_data: ItemData
@export var price: int = 0

signal item_selected(item: ItemData, price: int)

func _init():
	pass

func set_item_data(new_item_data: ItemData, item_price: int = 0):
	item_data = new_item_data
	price = item_price
	
	if item_data:
		text = item_data.name + " - " + str(price) + " gold"

func _on_pressed():
	if item_data:
		item_selected.emit(item_data, price)