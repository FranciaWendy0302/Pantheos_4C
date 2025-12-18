class_name EquipmentSkillData extends Resource

# Defines skills for different equipment types (armor, shoes, helmet)

@export var skill: SkillReference
@export var equipment_type: String = ""  # "armor", "shoes", "helmet"

# Swordsman Set Equipment Skills
static func create_knight_helmet_passive() -> EquipmentSkillData:
	var equipment_skill = EquipmentSkillData.new()
	equipment_skill.equipment_type = "helmet"
	
	equipment_skill.skill = SkillData.new()
	equipment_skill.skill.name = "Block Mastery"
	equipment_skill.skill.description = "40% damage reduction from blocked attacks"
	equipment_skill.skill.skill_type = "passive"
	equipment_skill.skill.effect_value = 0.4  # 40% block damage reduction
	
	return equipment_skill

static func create_knight_armor_skill() -> EquipmentSkillData:
	var equipment_skill = EquipmentSkillData.new()
	equipment_skill.equipment_type = "armor"
	
	equipment_skill.skill = SkillData.new()
	equipment_skill.skill.name = "Guardian Shield"
	equipment_skill.skill.description = "Create a protective shield for self and nearby party members"
	equipment_skill.skill.mana_cost = 30
	equipment_skill.skill.cooldown = 15.0
	equipment_skill.skill.skill_type = "shield"
	equipment_skill.skill.effect_value = 0.5  # 50% damage reduction
	equipment_skill.skill.duration = 8.0  # 8 seconds
	equipment_skill.skill.range = 150.0  # Party range
	
	return equipment_skill

static func create_knight_shoes_skill() -> EquipmentSkillData:
	var equipment_skill = EquipmentSkillData.new()
	equipment_skill.equipment_type = "shoes"
	
	equipment_skill.skill = SkillData.new()
	equipment_skill.skill.name = "Revitalize Sprint"
	equipment_skill.skill.description = "Sprint that recovers HP for 3 seconds"
	equipment_skill.skill.mana_cost = 20
	equipment_skill.skill.cooldown = 12.0
	equipment_skill.skill.skill_type = "heal"
	equipment_skill.skill.effect_value = 15.0  # HP per second
	equipment_skill.skill.duration = 3.0  # 3 seconds
	equipment_skill.skill.range = 0.0  # Self only
	
	return equipment_skill

# Generic equipment skill creators for other sets
static func create_armor_skill(name: String, description: String, skill_type: String, mana_cost: int, cooldown: float, effect_value: float, duration: float = 0.0) -> EquipmentSkillData:
	var equipment_skill = EquipmentSkillData.new()
	equipment_skill.equipment_type = "armor"
	
	equipment_skill.skill = SkillData.new()
	equipment_skill.skill.name = name
	equipment_skill.skill.description = description
	equipment_skill.skill.mana_cost = mana_cost
	equipment_skill.skill.cooldown = cooldown
	equipment_skill.skill.skill_type = skill_type
	equipment_skill.skill.effect_value = effect_value
	equipment_skill.skill.duration = duration
	
	return equipment_skill

static func create_shoes_skill(name: String, description: String, skill_type: String, mana_cost: int, cooldown: float, effect_value: float, duration: float = 0.0) -> EquipmentSkillData:
	var equipment_skill = EquipmentSkillData.new()
	equipment_skill.equipment_type = "shoes"
	
	equipment_skill.skill = SkillData.new()
	equipment_skill.skill.name = name
	equipment_skill.skill.description = description
	equipment_skill.skill.mana_cost = mana_cost
	equipment_skill.skill.cooldown = cooldown
	equipment_skill.skill.skill_type = skill_type
	equipment_skill.skill.effect_value = effect_value
	equipment_skill.skill.duration = duration
	
	return equipment_skill

static func create_helmet_passive(name: String, description: String, effect_type: String, effect_value: float) -> EquipmentSkillData:
	var equipment_skill = EquipmentSkillData.new()
	equipment_skill.equipment_type = "helmet"
	
	equipment_skill.skill = SkillData.new()
	equipment_skill.skill.name = name
	equipment_skill.skill.description = description
	equipment_skill.skill.skill_type = "passive"
	equipment_skill.skill.effect_value = effect_value
	
	return equipment_skill