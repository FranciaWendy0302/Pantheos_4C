class_name EquipableItemModifier
extends Resource

enum ModifierType {
	ATTACK,
	DEFENSE,
	HEALTH,
	MANA,
	SPEED,
	CRITICAL_CHANCE,
	CRITICAL_DAMAGE
}

@export var modifier_type: ModifierType = ModifierType.ATTACK
@export var value: float = 0.0
@export var is_percentage: bool = false

func _init():
	pass

func apply_modifier(base_value: float) -> float:
	if is_percentage:
		return base_value * (1.0 + value)
	else:
		return base_value + value