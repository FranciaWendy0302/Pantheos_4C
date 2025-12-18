class_name AbilitySystem
extends Node

@export var abilities: Array[AbilityItemData] = []
@export var cooldowns: Dictionary = {}

signal ability_used(ability: AbilityItemData)
signal ability_cooldown_started(ability_id: String, duration: float)

func _init():
	pass

func can_use_ability(ability_id: String) -> bool:
	return not cooldowns.has(ability_id) or cooldowns[ability_id] <= 0.0

func use_ability(ability_id: String) -> bool:
	if not can_use_ability(ability_id):
		return false
		
	var ability = get_ability_by_id(ability_id)
	if not ability:
		return false
		
	cooldowns[ability_id] = ability.cooldown
	ability_used.emit(ability)
	ability_cooldown_started.emit(ability_id, ability.cooldown)
	return true

func get_ability_by_id(ability_id: String) -> AbilityItemData:
	for ability in abilities:
		if ability.ability_id == ability_id:
			return ability
	return null

func _process(delta):
	for ability_id in cooldowns.keys():
		cooldowns[ability_id] -= delta
		if cooldowns[ability_id] <= 0.0:
			cooldowns.erase(ability_id)