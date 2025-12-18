extends Node
class_name StatSystem

# MMORPG Stat System
# Handles all character stats, scaling, buffs, and calculations

var player: Node2D = null

# Base Stats (without equipment)
var base_max_hp: int = 1200
var base_max_mp: int = 200
var base_attack: int = 50
var base_defense: int = 20
var base_magic_power: int = 30
var base_crit_chance: float = 0.05  # 5%
var base_crit_damage: float = 1.5  # 150%

# Current Stats (with equipment and buffs)
var max_hp: int = 1200
var current_hp: int = 1200
var max_mp: int = 200
var current_mp: int = 200
var attack: int = 50
var defense: int = 20
var magic_power: int = 30
var crit_chance: float = 0.05
var crit_damage: float = 1.5

# Regeneration
var hp_regen_per_second: float = 10.0  # 10 HP/s
var mp_regen_per_second: float = 5.0   # 5 MP/s
var combat_regen_multiplier: float = 0.5  # 50% regen in combat

# Equipment Bonuses (flat values from equipment)
var equipment_hp: int = 0
var equipment_mp: int = 0
var equipment_attack: int = 0
var equipment_defense: int = 0
var equipment_magic_power: int = 0
var equipment_crit_chance: float = 0.0
var equipment_crit_damage: float = 0.0

# Buff Multipliers (percentage bonuses)
var buff_hp_multiplier: float = 1.0
var buff_mp_multiplier: float = 1.0
var buff_attack_multiplier: float = 1.0
var buff_defense_multiplier: float = 1.0
var buff_magic_multiplier: float = 1.0
var buff_crit_chance_bonus: float = 0.0
var buff_crit_damage_bonus: float = 0.0

# Combat State
var in_combat: bool = false
var last_damage_time: float = 0.0
var combat_timeout: float = 5.0  # Exit combat after 5s without damage

signal stats_changed
signal hp_changed(current: int, max: int)
signal mp_changed(current: int, max: int)
signal entered_combat
signal exited_combat

func _ready():
	player = get_parent()
	_initialize_stats()

func _process(delta):
	# Regeneration
	_regenerate_resources(delta)
	
	# Combat state check
	_update_combat_state(delta)

func _initialize_stats():
	"""Initialize base stats based on player class"""
	if not player:
		return
	
	var player_class = player.get_player_class() if player.has_method("get_player_class") else "Mage"
	
	match player_class:
		"Mage":
			base_max_hp = 1000
			base_max_mp = 300
			base_attack = 40
			base_defense = 15
			base_magic_power = 60
			hp_regen_per_second = 8.0
			mp_regen_per_second = 8.0
		"Swordsman", "Warrior":
			base_max_hp = 1500
			base_max_mp = 150
			base_attack = 70
			base_defense = 30
			base_magic_power = 20
			hp_regen_per_second = 15.0
			mp_regen_per_second = 4.0
		"Archer", "Ranger":
			base_max_hp = 1200
			base_max_mp = 200
			base_attack = 60
			base_defense = 20
			base_magic_power = 30
			hp_regen_per_second = 10.0
			mp_regen_per_second = 5.0
		_:
			# Default values already set
			pass
	
	# Calculate initial stats
	recalculate_all_stats()
	
	# Set current to max
	current_hp = max_hp
	current_mp = max_mp
	
	print("[StatSystem] Initialized - HP: %d/%d, MP: %d/%d, ATK: %d, DEF: %d, MAG: %d" % 
		[current_hp, max_hp, current_mp, max_mp, attack, defense, magic_power])

func recalculate_all_stats():
	"""Recalculate all stats from base + equipment + buffs"""
	# HP = (Base + Equipment) * Buff Multiplier
	max_hp = int((base_max_hp + equipment_hp) * buff_hp_multiplier)
	
	# MP = (Base + Equipment) * Buff Multiplier
	max_mp = int((base_max_mp + equipment_mp) * buff_mp_multiplier)
	
	# Attack = (Base + Equipment) * Buff Multiplier
	attack = int((base_attack + equipment_attack) * buff_attack_multiplier)
	
	# Defense = (Base + Equipment) * Buff Multiplier
	defense = int((base_defense + equipment_defense) * buff_defense_multiplier)
	
	# Magic Power = (Base + Equipment) * Buff Multiplier
	magic_power = int((base_magic_power + equipment_magic_power) * buff_magic_multiplier)
	
	# Crit Chance = Base + Equipment + Buffs (capped at 100%)
	crit_chance = min(base_crit_chance + equipment_crit_chance + buff_crit_chance_bonus, 1.0)
	
	# Crit Damage = Base + Equipment + Buffs
	crit_damage = base_crit_damage + equipment_crit_damage + buff_crit_damage_bonus
	
	# Cap current values to new max
	current_hp = min(current_hp, max_hp)
	current_mp = min(current_mp, max_mp)
	
	# Update player stats (for compatibility with old system)
	_sync_to_player()
	
	stats_changed.emit()
	hp_changed.emit(current_hp, max_hp)
	mp_changed.emit(current_mp, max_mp)
	
	print("[StatSystem] Stats recalculated - HP: %d/%d, MP: %d/%d, ATK: %d, DEF: %d, MAG: %d" % 
		[current_hp, max_hp, current_mp, max_mp, attack, defense, magic_power])

func _sync_to_player():
	"""Sync stats to player node for compatibility"""
	if not player:
		return
	
	if "max_hp" in player:
		player.max_hp = max_hp
	if "hp" in player:
		player.hp = current_hp
	if "max_mana" in player:
		player.max_mana = max_mp
	if "mana" in player:
		player.mana = current_mp
	if "attack" in player:
		player.attack = attack
	if "defense" in player:
		player.defense = defense

func load_equipment_stats():
	"""Load stat bonuses from equipped items"""
	equipment_hp = 0
	equipment_mp = 0
	equipment_attack = 0
	equipment_defense = 0
	equipment_magic_power = 0
	equipment_crit_chance = 0.0
	equipment_crit_damage = 0.0
	
	if not PlayerManager.INVENTORY_DATA:
		return
	
	var equipment_slots = PlayerManager.INVENTORY_DATA.equipment_slots()
	
	for slot in equipment_slots:
		if not slot or not slot.item_data:
			continue
		
		var item = slot.item_data
		
		# Check if item has modifiers
		if not "modifiers" in item or not item.modifiers:
			continue
		
		# Sum up all modifiers
		for modifier in item.modifiers:
			if not modifier:
				continue
			
			match modifier.type:
				0:  # HP
					equipment_hp += modifier.value
				1:  # Attack
					equipment_attack += modifier.value
				2:  # Defense
					equipment_defense += modifier.value
				3:  # Speed (not used in stat system)
					pass
				4:  # Crit Chance
					equipment_crit_chance += modifier.value / 100.0  # Convert to decimal
				5:  # Crit Damage
					equipment_crit_damage += modifier.value / 100.0
				10:  # Intelligence/Magic Power
					equipment_magic_power += modifier.value
				11:  # MP
					equipment_mp += modifier.value
	
	print("[StatSystem] Equipment loaded - HP: +%d, MP: +%d, ATK: +%d, DEF: +%d, MAG: +%d" % 
		[equipment_hp, equipment_mp, equipment_attack, equipment_defense, equipment_magic_power])
	
	recalculate_all_stats()

func apply_buff(stat_type: String, multiplier: float, duration: float = 0.0):
	"""Apply a percentage buff to a stat"""
	match stat_type:
		"hp":
			buff_hp_multiplier *= multiplier
		"mp":
			buff_mp_multiplier *= multiplier
		"attack":
			buff_attack_multiplier *= multiplier
		"defense":
			buff_defense_multiplier *= multiplier
		"magic":
			buff_magic_multiplier *= multiplier
		"crit_chance":
			buff_crit_chance_bonus += multiplier
		"crit_damage":
			buff_crit_damage_bonus += multiplier
	
	recalculate_all_stats()
	
	# Auto-remove buff after duration
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
		remove_buff(stat_type, multiplier)

func remove_buff(stat_type: String, multiplier: float):
	"""Remove a percentage buff from a stat"""
	match stat_type:
		"hp":
			buff_hp_multiplier /= multiplier
		"mp":
			buff_mp_multiplier /= multiplier
		"attack":
			buff_attack_multiplier /= multiplier
		"defense":
			buff_defense_multiplier /= multiplier
		"magic":
			buff_magic_multiplier /= multiplier
		"crit_chance":
			buff_crit_chance_bonus -= multiplier
		"crit_damage":
			buff_crit_damage_bonus -= multiplier
	
	recalculate_all_stats()

func _regenerate_resources(delta: float):
	"""Regenerate HP and MP over time"""
	var regen_mult = combat_regen_multiplier if in_combat else 1.0
	
	# HP Regeneration
	if current_hp < max_hp:
		var hp_gain = hp_regen_per_second * regen_mult * delta
		current_hp = min(current_hp + int(hp_gain), max_hp)
		hp_changed.emit(current_hp, max_hp)
		_sync_to_player()
	
	# MP Regeneration
	if current_mp < max_mp:
		var mp_gain = mp_regen_per_second * regen_mult * delta
		current_mp = min(current_mp + int(mp_gain), max_mp)
		mp_changed.emit(current_mp, max_mp)
		_sync_to_player()

func _update_combat_state(delta: float):
	"""Update combat state based on time since last damage"""
	if in_combat:
		if Time.get_ticks_msec() / 1000.0 - last_damage_time > combat_timeout:
			in_combat = false
			exited_combat.emit()
			print("[StatSystem] Exited combat")

func take_damage(damage: int) -> int:
	"""Take damage with defense calculation"""
	# Damage Reduction = Defense / (Defense + 100)
	var damage_reduction = float(defense) / (float(defense) + 100.0)
	var actual_damage = int(damage * (1.0 - damage_reduction))
	
	current_hp = max(0, current_hp - actual_damage)
	hp_changed.emit(current_hp, max_hp)
	_sync_to_player()
	
	# Enter combat
	if not in_combat:
		in_combat = true
		entered_combat.emit()
		print("[StatSystem] Entered combat")
	
	last_damage_time = Time.get_ticks_msec() / 1000.0
	
	print("[StatSystem] Took %d damage (reduced from %d by %.1f%% defense)" % 
		[actual_damage, damage, damage_reduction * 100])
	
	return actual_damage

func deal_damage(base_damage: int, is_magic: bool = false) -> int:
	"""Calculate outgoing damage with crit chance"""
	var damage_stat = magic_power if is_magic else attack
	var final_damage = base_damage + damage_stat
	
	# Check for critical hit
	if randf() < crit_chance:
		final_damage = int(final_damage * crit_damage)
		print("[StatSystem] CRITICAL HIT! Damage: %d (%.1fx)" % [final_damage, crit_damage])
	
	return final_damage

func consume_mp(amount: int) -> bool:
	"""Consume MP, returns false if not enough"""
	if current_mp < amount:
		return false
	
	current_mp -= amount
	mp_changed.emit(current_mp, max_mp)
	_sync_to_player()
	return true

func heal(amount: int):
	"""Heal HP"""
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)
	_sync_to_player()

func restore_mp(amount: int):
	"""Restore MP"""
	current_mp = min(current_mp + amount, max_mp)
	mp_changed.emit(current_mp, max_mp)
	_sync_to_player()
