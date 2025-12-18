class_name Shopkeeper
extends NPC

@export var shop_items: Array[ItemData] = []
@export var shop_name: String = "General Store"

func _init():
	super._init()
	npc_name = "Shopkeeper"

func get_shop_items() -> Array[ItemData]:
	return shop_items

func can_sell_item(item: ItemData) -> bool:
	return item in shop_items