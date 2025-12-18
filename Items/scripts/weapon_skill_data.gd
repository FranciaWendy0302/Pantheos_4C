class_name WeaponSkillData extends Resource

# Defines the Q/W/E skill references for a weapon
# These are just references - the actual skills are implemented in the player's class abilities

@export var q_skill: SkillReference
@export var w_skill: SkillReference  
@export var e_skill: SkillReference

# Predefined skill sets for different weapon types
static func create_sword_skills() -> WeaponSkillData:
	var skills = WeaponSkillData.new()
	
	# Q - Consecutive Slash
	skills.q_skill = SkillData.new()
	skills.q_skill.name = "Consecutive Slash"
	skills.q_skill.description = "Perform multiple quick slashes in succession"
	skills.q_skill.mana_cost = 15
	skills.q_skill.cooldown = 3.0
	skills.q_skill.skill_type = "combo"
	skills.q_skill.damage_multiplier = 0.6  # Lower per hit but multiple hits
	skills.q_skill.range = 50.0
	
	# W - Whirlwind
	skills.w_skill = SkillData.new()
	skills.w_skill.name = "Whirlwind"
	skills.w_skill.description = "Spin attack hitting all nearby enemies"
	skills.w_skill.mana_cost = 20
	skills.w_skill.cooldown = 5.0
	skills.w_skill.skill_type = "area"
	skills.w_skill.damage_multiplier = 0.8
	skills.w_skill.range = 60.0
	
	# E - Charge Slash
	skills.e_skill = SkillData.new()
	skills.e_skill.name = "Charge Slash"
	skills.e_skill.description = "Powerful charged attack"
	skills.e_skill.mana_cost = 25
	skills.e_skill.cooldown = 8.0
	skills.e_skill.skill_type = "charge"
	skills.e_skill.damage_multiplier = 2.0
	skills.e_skill.range = 50.0
	
	return skills

static func create_staff_skills() -> WeaponSkillData:
	var skills = WeaponSkillData.new()
	
	# Q - Fireball
	skills.q_skill = SkillData.new()
	skills.q_skill.name = "Fireball"
	skills.q_skill.description = "Launch a burning projectile"
	skills.q_skill.mana_cost = 20
	skills.q_skill.cooldown = 2.0
	skills.q_skill.skill_type = "projectile"
	skills.q_skill.damage_multiplier = 1.5
	skills.q_skill.range = 200.0
	
	# W - Ice Shard
	skills.w_skill = SkillData.new()
	skills.w_skill.name = "Ice Shard"
	skills.w_skill.description = "Freezing projectile that slows enemies"
	skills.w_skill.mana_cost = 18
	skills.w_skill.cooldown = 3.0
	skills.w_skill.skill_type = "projectile"
	skills.w_skill.damage_multiplier = 1.2
	skills.w_skill.range = 180.0
	
	# E - Lightning Bolt
	skills.e_skill = SkillData.new()
	skills.e_skill.name = "Lightning Bolt"
	skills.e_skill.description = "Instant lightning strike"
	skills.e_skill.mana_cost = 30
	skills.e_skill.cooldown = 6.0
	skills.e_skill.skill_type = "instant"
	skills.e_skill.damage_multiplier = 2.2
	skills.e_skill.range = 250.0
	
	return skills

static func create_bow_skills() -> WeaponSkillData:
	var skills = WeaponSkillData.new()
	
	# Q - Multi-shot
	skills.q_skill = SkillData.new()
	skills.q_skill.name = "Multi-shot"
	skills.q_skill.description = "Fire multiple arrows in a spread"
	skills.q_skill.mana_cost = 15
	skills.q_skill.cooldown = 4.0
	skills.q_skill.skill_type = "projectile"
	skills.q_skill.damage_multiplier = 0.7
	skills.q_skill.range = 150.0
	
	# W - Piercing Arrow
	skills.w_skill = SkillData.new()
	skills.w_skill.name = "Piercing Arrow"
	skills.w_skill.description = "Arrow that pierces through enemies"
	skills.w_skill.mana_cost = 20
	skills.w_skill.cooldown = 5.0
	skills.w_skill.skill_type = "projectile"
	skills.w_skill.damage_multiplier = 1.8
	skills.w_skill.range = 200.0
	
	# E - Rain of Arrows
	skills.e_skill = SkillData.new()
	skills.e_skill.name = "Rain of Arrows"
	skills.e_skill.description = "Arrows fall from the sky in target area"
	skills.e_skill.mana_cost = 35
	skills.e_skill.cooldown = 10.0
	skills.e_skill.skill_type = "area"
	skills.e_skill.damage_multiplier = 1.0
	skills.e_skill.range = 300.0
	
	return skills

static func create_dagger_skills() -> WeaponSkillData:
	var skills = WeaponSkillData.new()
	
	# Q - Shadow Step
	skills.q_skill = SkillData.new()
	skills.q_skill.name = "Shadow Step"
	skills.q_skill.description = "Teleport behind target and strike"
	skills.q_skill.mana_cost = 20
	skills.q_skill.cooldown = 6.0
	skills.q_skill.skill_type = "teleport"
	skills.q_skill.damage_multiplier = 1.5
	skills.q_skill.range = 120.0
	
	# W - Poison Strike
	skills.w_skill = SkillData.new()
	skills.w_skill.name = "Poison Strike"
	skills.w_skill.description = "Attack that applies poison damage over time"
	skills.w_skill.mana_cost = 18
	skills.w_skill.cooldown = 4.0
	skills.w_skill.skill_type = "debuff"
	skills.w_skill.damage_multiplier = 1.0
	skills.w_skill.range = 40.0
	
	# E - Backstab
	skills.e_skill = SkillData.new()
	skills.e_skill.name = "Backstab"
	skills.e_skill.description = "Critical strike from behind"
	skills.e_skill.mana_cost = 25
	skills.e_skill.cooldown = 8.0
	skills.e_skill.skill_type = "critical"
	skills.e_skill.damage_multiplier = 3.0
	skills.e_skill.range = 30.0
	
	return skills
