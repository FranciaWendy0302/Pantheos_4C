extends Node
class_name AbilitySystem

# Universal ability system for all classes
# Handles Q/W/E (equipment skills), R (class ultimate), and resource management

var player: CharacterBody2D

# Resource system (mana for mages, stamina for warriors, etc.)
var resource_type: String = "mana"  # "mana", "stamina", "energy"
var resource_regen_rate: float = 8.0

# Skill slots
var q_skill: Ability = null  # Weapon skill 1
var w_skill: Ability = null  # Weapon skill 2
var e_skill: Ability = null  # Weapon skill 3
var r_skill: Ability = null  # Class ultimate
var d_skill: Ability = null  # Armor skill
var f_skill: Ability = null  # Shoes skill
var helmet_passive: Ability = null  # Helmet passive

# Cooldowns
var q_cooldown: float = 0.0
var w_cooldown: float = 0.0
var e_cooldown: float = 0.0
var r_cooldown: float = 0.0
var d_cooldown: float = 0.0
var f_cooldown: float = 0.0

# God permanent buffs
var god_buffs: Array[GodBuff] = []

# Active effects
var active_buffs: Array[Buff] = []

signal ability_used(slot: String, ability_name: String)
signal resource_changed(current: int, max: int)
signal cooldown_updated(slot: String, remaining: float, max_time: float)

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	await get_tree().process_frame
	
	if player:
		# Initialize resource based on class
		_initialize_resource()
		resource_changed.emit(player.mana, player.max_mana)
		
		# Load and apply equipment passives
		call_deferred("load_equipment_passives")

func _initialize_resource() -> void:
	"""Initialize resource pool based on class"""
	if not player:
		return
	
	# Set resource type based on class
	match player.get_player_class():
		"Mage":
			resource_type = "mana"
			player.max_mana = 150
			player.mana = 150
		"Swordsman", "Warrior":
			resource_type = "stamina"
			player.max_mana = 100  # Using mana variable for stamina
			player.mana = 100
		_:
			resource_type = "mana"
			player.max_mana = 100
			player.mana = 100

func _process(delta: float) -> void:
	# Update cooldowns
	if q_cooldown > 0.0:
		q_cooldown -= delta
		cooldown_updated.emit("Q", q_cooldown, q_skill.cooldown if q_skill else 0.0)
	if w_cooldown > 0.0:
		w_cooldown -= delta
		cooldown_updated.emit("W", w_cooldown, w_skill.cooldown if w_skill else 0.0)
	if e_cooldown > 0.0:
		e_cooldown -= delta
		cooldown_updated.emit("E", e_cooldown, e_skill.cooldown if e_skill else 0.0)
	if r_cooldown > 0.0:
		r_cooldown -= delta
		cooldown_updated.emit("R", r_cooldown, r_skill.cooldown if r_skill else 0.0)
	if d_cooldown > 0.0:
		d_cooldown -= delta
		cooldown_updated.emit("D", d_cooldown, d_skill.cooldown if d_skill else 0.0)
	if f_cooldown > 0.0:
		f_cooldown -= delta
		cooldown_updated.emit("F", f_cooldown, f_skill.cooldown if f_skill else 0.0)
	
	# Regenerate resource
	_regenerate_resource(delta)
	
	# Update active buffs
	_update_buffs(delta)

func use_ability(slot: String) -> bool:
	"""Use ability in specified slot (Q/W/E/R/D/F)"""
	# NEW SYSTEM: Check if we have a skill reference first (Q/W/E/D/F)
	if slot in ["Q", "W", "E", "D", "F"]:
		var skill_ref: SkillReference = _get_skill_reference(slot)
		if skill_ref:
			return _use_skill_reference(slot, skill_ref)
	
	# R key: Class ultimate - use class abilities directly
	if slot == "R":
		return _use_class_ultimate()
	
	# OLD SYSTEM: Fall back to Ability objects for compatibility
	var ability: Ability = null
	var cooldown_ref: float = 0.0
	
	match slot:
		"Q":
			ability = q_skill
			cooldown_ref = q_cooldown
		"W":
			ability = w_skill
			cooldown_ref = w_cooldown
		"E":
			ability = e_skill
			cooldown_ref = e_cooldown
		"R":
			ability = r_skill
			cooldown_ref = r_cooldown
		"D":
			ability = d_skill
			cooldown_ref = d_cooldown
		"F":
			ability = f_skill
			cooldown_ref = f_cooldown
	
	if not ability:
		print("[AbilitySystem] No ability in slot %s" % slot)
		return false
	
	if cooldown_ref > 0.0:
		print("[AbilitySystem] %s on cooldown: %.1fs" % [ability.name, cooldown_ref])
		return false
	
	# Check resource cost
	if not _has_resource(ability.cost):
		print("[AbilitySystem] Not enough %s for %s (%d/%d)" % [resource_type, ability.name, player.mana, ability.cost])
		return false
	
	# Consume resource
	_consume_resource(ability.cost)
	
	# Execute ability
	var success = ability.execute(player)
	
	if success:
		# Set cooldown
		match slot:
			"Q":
				q_cooldown = ability.cooldown
			"W":
				w_cooldown = ability.cooldown
			"E":
				e_cooldown = ability.cooldown
			"R":
				r_cooldown = ability.cooldown
			"D":
				d_cooldown = ability.cooldown
			"F":
				f_cooldown = ability.cooldown
		
		ability_used.emit(slot, ability.name)
		print("[AbilitySystem] Used %s! (%s: %d/%d)" % [ability.name, resource_type, player.mana, player.max_mana])
	
	return success

func _get_skill_reference(slot: String) -> SkillReference:
	"""Get skill reference from equipped weapon/equipment"""
	# Check if player has equipped weapon with skill references
	if not player:
		print("[AbilitySystem] _get_skill_reference: No player")
		return null
	
	if not PlayerManager.INVENTORY_DATA:
		print("[AbilitySystem] _get_skill_reference: No INVENTORY_DATA")
		return null
	
	# Get equipment slots - [0]=weapon, [1]=helmet, [2]=armor, [3]=boots
	var equipment_slots = PlayerManager.INVENTORY_DATA.equipment_slots()
	print("[AbilitySystem] _get_skill_reference: Equipment slots count: ", equipment_slots.size())
	
	if equipment_slots.size() < 1:
		print("[AbilitySystem] _get_skill_reference: Not enough equipment slots")
		return null
	
	var skill_ref: SkillReference = null
	
	# Handle weapon skills (Q/W/E)
	if slot in ["Q", "W", "E"]:
		var weapon_slot = equipment_slots[0]
		if not weapon_slot or not weapon_slot.item_data:
			return null
		
		var weapon_item = weapon_slot.item_data
		if not "weapon_skills" in weapon_item or not weapon_item.weapon_skills:
			return null
		
		match slot:
			"Q":
				skill_ref = weapon_item.weapon_skills.q_skill
			"W":
				skill_ref = weapon_item.weapon_skills.w_skill
			"E":
				skill_ref = weapon_item.weapon_skills.e_skill
	
	# Handle armor skill (D)
	elif slot == "D":
		if equipment_slots.size() < 3:
			return null
		var armor_slot = equipment_slots[2]
		if not armor_slot or not armor_slot.item_data:
			return null
		
		var armor_item = armor_slot.item_data
		if not "equipment_skills" in armor_item or not armor_item.equipment_skills:
			return null
		
		if not "skill" in armor_item.equipment_skills or not armor_item.equipment_skills.skill:
			return null
		
		skill_ref = armor_item.equipment_skills.skill
	
	# Handle boots skill (F)
	elif slot == "F":
		if equipment_slots.size() < 4:
			return null
		var boots_slot = equipment_slots[3]
		if not boots_slot or not boots_slot.item_data:
			return null
		
		var boots_item = boots_slot.item_data
		if not "equipment_skills" in boots_item or not boots_item.equipment_skills:
			return null
		
		if not "skill" in boots_item.equipment_skills or not boots_item.equipment_skills.skill:
			return null
		
		skill_ref = boots_item.equipment_skills.skill
	
	if skill_ref:
		print("[AbilitySystem] _get_skill_reference: Found skill for slot %s: %s (id: %s)" % [slot, skill_ref.display_name, skill_ref.skill_id])
	else:
		print("[AbilitySystem] _get_skill_reference: No skill in slot %s" % slot)
	
	return skill_ref

func _use_skill_reference(slot: String, skill_ref: SkillReference) -> bool:
	"""Execute a skill using the new skill reference system"""
	print("[AbilitySystem] _use_skill_reference called for slot %s: %s (id: %s)" % [slot, skill_ref.display_name, skill_ref.skill_id])
	
	var cooldown_ref: float = 0.0
	
	match slot:
		"Q":
			cooldown_ref = q_cooldown
		"W":
			cooldown_ref = w_cooldown
		"E":
			cooldown_ref = e_cooldown
		"D":
			cooldown_ref = d_cooldown
		"F":
			cooldown_ref = f_cooldown
	
	if cooldown_ref > 0.0:
		print("[AbilitySystem] %s on cooldown: %.1fs" % [skill_ref.display_name, cooldown_ref])
		return false
	
	# Check resource cost (skill will consume it, we just check here)
	if not _has_resource(skill_ref.mana_cost):
		print("[AbilitySystem] Not enough %s for %s (%d/%d)" % [resource_type, skill_ref.display_name, player.mana, skill_ref.mana_cost])
		return false
	
	print("[AbilitySystem] Looking for class abilities node...")
	
	# Get the class abilities node - try both "MageAbilities" and "Abilities"
	var class_abilities = player.get_node_or_null("MageAbilities")
	if not class_abilities:
		class_abilities = player.get_node_or_null("Abilities")
	
	if not class_abilities:
		print("[AbilitySystem] ERROR: No class abilities node found!")
		print("[AbilitySystem] Player children: ", player.get_children())
		return false
	
	print("[AbilitySystem] Found class abilities node: ", class_abilities, " (type: ", class_abilities.get_class(), ")")
	
	if not class_abilities.has_method("execute_skill"):
		print("[AbilitySystem] ERROR: MageAbilities has no execute_skill method!")
		return false
	
	print("[AbilitySystem] Executing skill: %s" % skill_ref.skill_id)
	
	# Execute the skill via class abilities (skill handles mana consumption)
	var success = class_abilities.execute_skill(skill_ref.skill_id)
	
	print("[AbilitySystem] Skill execution result: ", success)
	
	if success:
		# Set cooldown
		match slot:
			"Q":
				q_cooldown = skill_ref.cooldown
			"W":
				w_cooldown = skill_ref.cooldown
			"E":
				e_cooldown = skill_ref.cooldown
			"D":
				d_cooldown = skill_ref.cooldown
			"F":
				f_cooldown = skill_ref.cooldown
		
		ability_used.emit(slot, skill_ref.display_name)
		print("[AbilitySystem] Used %s! (%s: %d/%d)" % [skill_ref.display_name, resource_type, player.mana, player.max_mana])
	else:
		print("[AbilitySystem] Skill execution failed!")
	
	return success

func equip_ability(slot: String, ability: Ability) -> void:
	"""Equip an ability to a slot"""
	match slot:
		"Q":
			q_skill = ability
		"W":
			w_skill = ability
		"E":
			e_skill = ability
		"R":
			r_skill = ability
		"D":
			d_skill = ability
		"F":
			f_skill = ability
		"HELMET_PASSIVE":
			helmet_passive = ability
			if ability:
				ability.apply_passive(player)
	
	print("[AbilitySystem] Equipped %s to slot %s" % [ability.name if ability else "None", slot])

func _has_resource(cost: int) -> bool:
	"""Check if player has enough resource"""
	return player and player.mana >= cost

func _consume_resource(cost: int) -> void:
	"""Consume resource"""
	if not player:
		return
	
	player.mana -= cost
	resource_changed.emit(player.mana, player.max_mana)
	_update_player_hud()

func _regenerate_resource(delta: float) -> void:
	"""Passive resource regeneration"""
	if not player or player.mana >= player.max_mana:
		return
	
	var old_resource = player.mana
	player.mana = min(player.mana + int(resource_regen_rate * delta), player.max_mana)
	
	if player.mana != old_resource:
		resource_changed.emit(player.mana, player.max_mana)
		_update_player_hud()

func add_buff(buff: Buff) -> void:
	"""Add a buff/debuff effect"""
	active_buffs.append(buff)
	buff.apply(player)
	print("[AbilitySystem] Buff applied: %s" % buff.name)

func _update_buffs(delta: float) -> void:
	"""Update active buffs"""
	for i in range(active_buffs.size() - 1, -1, -1):
		var buff = active_buffs[i]
		buff.duration -= delta
		
		if buff.duration <= 0:
			buff.remove(player)
			active_buffs.remove_at(i)
			print("[AbilitySystem] Buff expired: %s" % buff.name)

func _update_player_hud() -> void:
	"""Update PlayerHud resource display"""
	if not player:
		return
	
	var player_hud = get_tree().get_first_node_in_group("player_hud")
	if not player_hud:
		player_hud = get_node_or_null("/root/PlayerHud")
	
	if player_hud and player_hud.has_method("update_mana"):
		player_hud.update_mana(player.mana, player.max_mana)

# Base Ability class
class Ability:
	var name: String = ""
	var description: String = ""
	var cost: int = 0
	var cooldown: float = 0.0
	var ability_type: String = "active"  # "active", "passive", "toggle"
	var passive_effects: Dictionary = {}  # For passive abilities
	
	func execute(player: CharacterBody2D) -> bool:
		# Override in subclasses for active abilities
		return false
	
	func apply_passive(player: CharacterBody2D) -> void:
		"""Apply passive effects (for helmet passives)"""
		for stat in passive_effects:
			if stat in player:
				var current_value = player.get(stat)
				player.set(stat, current_value * passive_effects[stat])
		
		print("[Ability] Applied passive %s: %s" % [name, passive_effects])
	
	func remove_passive(player: CharacterBody2D) -> void:
		"""Remove passive effects"""
		for stat in passive_effects:
			if stat in player:
				var current_value = player.get(stat)
				player.set(stat, current_value / passive_effects[stat])

# Base Buff class
class Buff:
	var name: String = ""
	var duration: float = 0.0
	var stat_modifiers: Dictionary = {}  # {"speed": 1.3, "attack": 1.5}
	
	func apply(player: CharacterBody2D) -> void:
		# Apply stat modifications
		for stat in stat_modifiers:
			if stat in player:
				player.set(stat, player.get(stat) * stat_modifiers[stat])
	
	func remove(player: CharacterBody2D) -> void:
		# Remove stat modifications
		for stat in stat_modifiers:
			if stat in player:
				player.set(stat, player.get(stat) / stat_modifiers[stat])

# God Buff class - Permanent buffs that scale with level
class GodBuff:
	var god_name: String = ""
	var level: int = 1
	var base_stats: Dictionary = {}  # Base stat increases per level
	var applied_stats: Dictionary = {}  # Currently applied stats
	
	func _init(god: String, god_level: int = 1):
		god_name = god
		level = god_level
		_setup_base_stats()
	
	func _setup_base_stats():
		"""Setup base stat increases per level for each god"""
		match god_name:
			"Zeus":
				base_stats = {"lightning_damage": 0.10, "stun_chance": 0.05}
			"Athena":
				base_stats = {"defense": 0.15, "block_chance": 0.08}
			"Ares":
				base_stats = {"attack": 0.20, "lifesteal": 0.03}
			"Artemis":
				base_stats = {"crit_chance": 0.15, "movement_speed": 0.10}
			"Poseidon":
				base_stats = {"water_damage": 0.12, "mana_regen": 0.15}
			"Hades":
				base_stats = {"dark_damage": 0.14, "health": 0.10}
	
	func apply(player: CharacterBody2D) -> void:
		"""Apply permanent god buffs based on level"""
		applied_stats.clear()
		
		for stat in base_stats:
			var increase = base_stats[stat] * level
			applied_stats[stat] = increase
			
			# Apply to player if stat exists
			if stat in player:
				var current_value = player.get(stat)
				player.set(stat, current_value + increase)
		
		print("[GodBuff] Applied %s level %d buffs: %s" % [god_name, level, applied_stats])
	
	func update_level(new_level: int, player: CharacterBody2D) -> void:
		"""Update god level and reapply buffs"""
		# Remove current buffs
		remove(player)
		
		# Update level and reapply
		level = new_level
		apply(player)
	
	func remove(player: CharacterBody2D) -> void:
		"""Remove god buffs"""
		for stat in applied_stats:
			if stat in player:
				var current_value = player.get(stat)
				player.set(stat, current_value - applied_stats[stat])
		
		applied_stats.clear()

func set_god_buff(god_name: String, god_level: int = 1) -> void:
	"""Set or update god permanent buff"""
	# Remove existing god buff
	for i in range(god_buffs.size() - 1, -1, -1):
		god_buffs[i].remove(player)
		god_buffs.remove_at(i)
	
	# Add new god buff
	var god_buff = GodBuff.new(god_name, god_level)
	god_buffs.append(god_buff)
	god_buff.apply(player)

func update_god_level(new_level: int) -> void:
	"""Update god level for existing god buff"""
	if god_buffs.size() > 0:
		god_buffs[0].update_level(new_level, player)


func load_equipment_passives():
	"""Load and apply passive skills from equipped items"""
	if not player or not PlayerManager.INVENTORY_DATA:
		return
	
	var equipment_slots = PlayerManager.INVENTORY_DATA.equipment_slots()
	if equipment_slots.size() < 2:
		return
	
	# Load helmet passive (index 1)
	var helmet_slot = equipment_slots[1]
	if helmet_slot and helmet_slot.item_data:
		var helmet_item = helmet_slot.item_data
		if "equipment_skills" in helmet_item and helmet_item.equipment_skills:
			if "skill" in helmet_item.equipment_skills and helmet_item.equipment_skills.skill:
				var skill_ref: SkillReference = helmet_item.equipment_skills.skill
				_apply_helmet_passive(skill_ref)

func _apply_helmet_passive(skill_ref: SkillReference):
	"""Apply helmet passive from skill reference"""
	if not skill_ref or skill_ref.skill_id == "":
		return
	
	print("[AbilitySystem] Applying helmet passive: %s (id: %s)" % [skill_ref.display_name, skill_ref.skill_id])
	
	# Create passive instance based on skill_id
	match skill_ref.skill_id:
		"arcane_insight":
			var arcane_insight = ArcaneInsight.new()
			arcane_insight.name = "ArcaneInsight"
			player.add_child(arcane_insight)
			arcane_insight.setup(player, self)  # Pass ability_system reference
			print("[AbilitySystem] Arcane Insight triggered passive ready!")


func _use_class_ultimate() -> bool:
	"""Use class-specific ultimate skill (R key)"""
	print("[AbilitySystem] _use_class_ultimate called!")
	
	if r_cooldown > 0.0:
		print("[AbilitySystem] Ultimate on cooldown: %.1fs" % r_cooldown)
		return false
	
	if not player:
		print("[AbilitySystem] ERROR: No player!")
		return false
	
	print("[AbilitySystem] Player class: %s" % player.get_player_class())
	
	# Get the class abilities node
	var class_abilities = player.get_node_or_null("MageAbilities")
	if not class_abilities:
		class_abilities = player.get_node_or_null("Abilities")
	
	print("[AbilitySystem] Class abilities node: ", class_abilities)
	
	if not class_abilities:
		print("[AbilitySystem] ERROR: No class abilities node found!")
		return false
	
	if not class_abilities.has_method("execute_skill"):
		print("[AbilitySystem] ERROR: Class abilities has no execute_skill method!")
		return false
	
	# Execute class-specific ultimate based on abilities node type
	var ultimate_id = ""
	
	# Check if it's MageAbilities
	if class_abilities.get_script() and class_abilities.get_script().get_global_name() == "MageAbilities":
		ultimate_id = "flame_convergence"
	# Check player class as fallback
	elif player.get_player_class() == "Mage":
		ultimate_id = "flame_convergence"
	elif player.get_player_class() in ["Swordsman", "Warrior"]:
		ultimate_id = "berserker_rage"
	else:
		print("[AbilitySystem] No ultimate defined for class: %s" % player.get_player_class())
		return false
	
	print("[AbilitySystem] Executing ultimate: %s" % ultimate_id)
	var success = class_abilities.execute_skill(ultimate_id)
	
	print("[AbilitySystem] Ultimate execution result: ", success)
	
	if success:
		r_cooldown = 60.0  # 60 second cooldown for ultimate
		ability_used.emit("R", "Ultimate")
		print("[AbilitySystem] Ultimate used! Cooldown: 60s")
	else:
		print("[AbilitySystem] Ultimate execution failed!")
	
	return success
