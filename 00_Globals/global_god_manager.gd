extends Node

# God selection system for Pantheos MMORPG
# Each god provides unique storyline quests and special skills

enum GodType {
	NONE = 0,
	# The Pantheon - 8 Greek Gods
	ATHENA = 1,      # Tank - Goddess of Wisdom & War
	ZEUS = 2,        # Ranged DPS (Magic) - King of the Gods
	VENUS = 3,       # Support Buffer/Debuffer - Goddess of Love & Beauty
	ASCLEPIUS = 4,   # Healer - God of Medicine & Healing
	HADES = 5,       # Off-Tank / Control - God of the Underworld
	ARES = 6,        # Melee DPS - God of War
	THANATOS = 7,    # Assassin / Death - God of Death
	NEMESIS = 8      # Vengeance / Balance - Goddess of Retribution
}

# God metadata - The Pantheon
const GOD_DATA = {
	GodType.ATHENA: {
		"name": "Athena",
		"title": "Goddess of Wisdom & War",
		"role": "Tank",
		"pantheon": "Olympian",
		"description": "Athena grants you divine protection and tactical wisdom. As her champion, you'll master defensive strategies and shield your allies.",
		"special_skill": "Aegis Shield",
		"skill_description": "Summon Athena's legendary shield for massive damage reduction",
		"recommended_class": "Swordsman",
		"chapter_1_quest": "Prove your wisdom in battle and earn Athena's blessing"
	},
	GodType.ZEUS: {
		"name": "Zeus",
		"title": "King of the Gods",
		"role": "Ranged DPS (Magic)",
		"pantheon": "Olympian",
		"description": "Zeus bestows upon you the power of lightning. Command the storms and strike down enemies from afar.",
		"special_skill": "Lightning Bolt",
		"skill_description": "Call down Zeus's thunderbolt to devastate enemies",
		"recommended_class": "Mage",
		"chapter_1_quest": "Harness the power of storms and prove your might to Zeus"
	},
	GodType.VENUS: {
		"name": "Venus",
		"title": "Goddess of Love & Beauty",
		"role": "Support Buffer/Debuffer",
		"pantheon": "Olympian",
		"description": "Venus grants you the power to charm and influence. Enhance your allies and weaken your foes.",
		"special_skill": "Divine Charm",
		"skill_description": "Enchant allies with buffs or enemies with debuffs",
		"recommended_class": "Support",
		"chapter_1_quest": "Spread beauty and harmony to earn Venus's favor"
	},
	GodType.ASCLEPIUS: {
		"name": "Asclepius",
		"title": "God of Medicine & Healing",
		"role": "Healer",
		"pantheon": "Olympian",
		"description": "Asclepius teaches you the sacred arts of healing. Restore life and cure ailments.",
		"special_skill": "Divine Restoration",
		"skill_description": "Channel healing energy to restore HP to allies",
		"recommended_class": "Support",
		"chapter_1_quest": "Master the healing arts and save those in need"
	},
	GodType.HADES: {
		"name": "Hades",
		"title": "God of the Underworld",
		"role": "Off-Tank / Control",
		"pantheon": "Chthonic",
		"description": "Hades offers you dominion over death and shadows. Control the battlefield with fear and darkness.",
		"special_skill": "Shadow Grasp",
		"skill_description": "Summon shadowy tendrils to immobilize enemies",
		"recommended_class": "Swordsman",
		"chapter_1_quest": "Journey to the underworld and prove your worth to Hades"
	},
	GodType.ARES: {
		"name": "Ares",
		"title": "God of War",
		"role": "Melee DPS",
		"pantheon": "Olympian",
		"description": "Ares fuels your bloodlust and combat prowess. Unleash devastating melee attacks.",
		"special_skill": "Berserker Rage",
		"skill_description": "Enter a rage state for increased damage and attack speed",
		"recommended_class": "Assassin",
		"chapter_1_quest": "Prove your strength in combat and earn Ares's respect"
	},
	GodType.THANATOS: {
		"name": "Thanatos",
		"title": "God of Death",
		"role": "Assassin / Death",
		"pantheon": "Chthonic",
		"description": "Thanatos grants you mastery over death itself. Strike from the shadows and reap souls with precision.",
		"special_skill": "Death's Touch",
		"skill_description": "Deal massive damage with a touch of death, ignoring armor",
		"recommended_class": "Assassin",
		"chapter_1_quest": "Embrace death and prove you can wield its power"
	},
	GodType.NEMESIS: {
		"name": "Nemesis",
		"title": "Goddess of Retribution",
		"role": "Vengeance / Balance",
		"pantheon": "Chthonic",
		"description": "Nemesis empowers you to balance the scales. Punish the wicked and protect the innocent with divine vengeance.",
		"special_skill": "Divine Vengeance",
		"skill_description": "Return damage dealt to you back to your enemies",
		"recommended_class": "Swordsman",
		"chapter_1_quest": "Bring justice to the unjust and earn Nemesis's blessing"
	}
}

# Current player's selected god
var selected_god: GodType = GodType.NONE
var god_skill_unlocked: bool = false

# God buff system - passive bonuses granted by each god
const GOD_BUFFS = {
	GodType.ATHENA: {
		"max_hp": 20,           # +20 HP
		"defense": 5,           # +5 Defense
		"block_chance": 0.10,   # +10% Block Chance
		"description": "Athena's Protection: +20 HP, +5 Defense, +10% Block Chance"
	},
	GodType.ZEUS: {
		"attack": 8,            # +8 Attack
		"crit_damage": 0.25,    # +25% Crit Damage
		"magic_damage": 0.15,   # +15% Magic Damage
		"description": "Zeus's Power: +8 Attack, +25% Crit Damage, +15% Magic Damage"
	},
	GodType.VENUS: {
		"max_mana": 30,         # +30 Mana
		"mana_regen": 3.0,      # +3 Mana/sec
		"move_speed": 0.10,     # +10% Move Speed
		"description": "Venus's Grace: +30 Mana, +3 Mana Regen, +10% Move Speed"
	},
	GodType.ASCLEPIUS: {
		"max_hp": 15,           # +15 HP
		"health_regen": 2.0,    # +2 HP/sec
		"healing_power": 0.20,  # +20% Healing Power
		"description": "Asclepius's Blessing: +15 HP, +2 HP Regen, +20% Healing Power"
	},
	GodType.HADES: {
		"max_hp": 15,           # +15 HP
		"defense": 3,           # +3 Defense
		"life_steal": 0.10,     # +10% Life Steal
		"description": "Hades's Dominion: +15 HP, +3 Defense, +10% Life Steal"
	},
	GodType.ARES: {
		"attack": 10,           # +10 Attack
		"attack_speed": 0.15,   # +15% Attack Speed
		"crit_chance": 0.10,    # +10% Crit Chance
		"description": "Ares's Fury: +10 Attack, +15% Attack Speed, +10% Crit Chance"
	},
	GodType.THANATOS: {
		"attack": 7,            # +7 Attack
		"crit_chance": 0.15,    # +15% Crit Chance
		"evasion": 0.10,        # +10% Evasion
		"description": "Thanatos's Touch: +7 Attack, +15% Crit Chance, +10% Evasion"
	},
	GodType.NEMESIS: {
		"attack": 5,            # +5 Attack
		"defense": 5,           # +5 Defense
		"counter_damage": 0.20, # +20% Counter Damage (reflects damage)
		"description": "Nemesis's Justice: +5 Attack, +5 Defense, +20% Counter Damage"
	}
}

func _ready() -> void:
	pass

func select_god(god: GodType) -> void:
	"""Select a god for the player"""
	selected_god = god
	print("[GodManager] Selected god: ", get_god_name(god))

func get_selected_god() -> GodType:
	"""Get currently selected god"""
	return selected_god

func get_god_name(god: GodType) -> String:
	"""Get god's name"""
	if GOD_DATA.has(god):
		return GOD_DATA[god].name
	return "None"

func get_god_data(god: GodType) -> Dictionary:
	"""Get all data for a god"""
	if GOD_DATA.has(god):
		return GOD_DATA[god]
	return {}

func get_god_special_skill(god: GodType) -> String:
	"""Get god's special skill name"""
	if GOD_DATA.has(god):
		return GOD_DATA[god].special_skill
	return ""

func unlock_god_skill() -> void:
	"""Unlock the god's special skill (called when player completes god quest)"""
	god_skill_unlocked = true
	print("[GodManager] God skill unlocked: ", get_god_special_skill(selected_god))

func is_god_skill_unlocked() -> bool:
	"""Check if god skill is unlocked"""
	return god_skill_unlocked

func get_god_pantheon(god: GodType) -> String:
	"""Get god's pantheon (Olympian/Chthonic)"""
	if GOD_DATA.has(god):
		return GOD_DATA[god].pantheon
	return "None"

func get_god_chapter_1_quest(god: GodType) -> String:
	"""Get god's chapter 1 quest description"""
	if GOD_DATA.has(god):
		return GOD_DATA[god].chapter_1_quest
	return ""

func get_recommended_class(god: GodType) -> String:
	"""Get recommended class for this god"""
	if GOD_DATA.has(god):
		return GOD_DATA[god].recommended_class
	return ""

func get_god_buffs(god: GodType) -> Dictionary:
	"""Get all buffs provided by a god"""
	if GOD_BUFFS.has(god):
		return GOD_BUFFS[god]
	return {}

func get_active_god_buffs() -> Dictionary:
	"""Get buffs from currently selected god"""
	return get_god_buffs(selected_god)

func get_buff_value(buff_name: String) -> float:
	"""Get a specific buff value from selected god (returns 0 if not found)"""
	var buffs = get_active_god_buffs()
	if buffs.has(buff_name):
		return buffs[buff_name]
	return 0.0

func get_god_buff_description(god: GodType) -> String:
	"""Get description of god's buffs"""
	var buffs = get_god_buffs(god)
	if buffs.has("description"):
		return buffs["description"]
	return "No buffs"

func apply_god_buffs_to_player(player: Node) -> void:
	"""Apply god buffs to player stats"""
	if selected_god == GodType.NONE:
		return
	
	var buffs = get_active_god_buffs()
	
	# Apply flat stat bonuses
	if buffs.has("max_hp"):
		player.max_hp += buffs["max_hp"]
		player.hp = min(player.hp, player.max_hp)  # Don't exceed new max
	
	if buffs.has("max_mana"):
		player.max_mana += buffs["max_mana"]
		player.mana = min(player.mana, player.max_mana)
	
	if buffs.has("attack"):
		player.attack += buffs["attack"]
	
	if buffs.has("defense"):
		player.defense += buffs["defense"]
	
	# Store percentage buffs for later use (player needs to check these)
	if not player.has_meta("god_buffs"):
		player.set_meta("god_buffs", buffs)
	
	print("[GodManager] Applied buffs from ", get_god_name(selected_god), " to player")
	print("[GodManager] Buffs: ", get_god_buff_description(selected_god))

func save_god_selection() -> Dictionary:
	"""Save god selection data"""
	return {
		"selected_god": selected_god,
		"god_skill_unlocked": god_skill_unlocked
	}

func load_god_selection(data: Dictionary) -> void:
	"""Load god selection data"""
	selected_god = data.get("selected_god", GodType.NONE)
	god_skill_unlocked = data.get("god_skill_unlocked", false)
