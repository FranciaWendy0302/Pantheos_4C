class_name EquipableItemData
extends ItemData

enum EquipmentSlot {
	WEAPON,
	HELMET,
	ARMOR,
	BOOTS,
	ACCESSORY
}

@export var equipment_slot: EquipmentSlot = EquipmentSlot.WEAPON
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var health_bonus: int = 0
@export var mana_bonus: int = 0

func _init():
	super._init()
	stackable = false
	max_stack = 1