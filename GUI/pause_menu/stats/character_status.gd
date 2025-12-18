class_name CharacterStatus extends PanelContainer

## Comprehensive character status screen showing all stats from equipment

var inventory: InventoryData
var player: Player

# Equipment Slots
@onready var slot_weapon: InventorySlotUI = %InventorySlot_Weapon
@onready var slot_armor: InventorySlotUI = %InventorySlot_Armor
@onready var slot_amulet: InventorySlotUI = %InventorySlot_Amulet
@onready var slot_ring: InventorySlotUI = %InventorySlot_Ring
@onready var slot_consumable: InventorySlotUI = %InventorySlot_Consumable

# Basic Info
@onready var label_level: Label = %Label_Level
@onready var label_xp: Label = %Label_XP
@onready var label_class: Label = %Label_Class

# Primary Stats
@onready var label_hp: Label = %Label_HP
@onready var label_mana: Label = %Label_Mana
@onready var label_attack: Label = %Label_Attack
@onready var label_defense: Label = %Label_Defense

# Combat Stats
@onready var label_crit_chance: Label = %Label_CritChance
@onready var label_crit_damage: Label = %Label_CritDamage
@onready var label_attack_speed: Label = %Label_AttackSpeed
@onready var label_move_speed: Label = %Label_MoveSpeed

# Attribute Stats
@onready var label_strength: Label = %Label_Strength
@onready var label_dexterity: Label = %Label_Dexterity
@onready var label_intelligence: Label = %Label_Intelligence
@onready var label_vitality: Label = %Label_Vitality

# Defensive Stats
@onready var label_magic_res: Label = %Label_MagicRes
@onready var label_evasion: Label = %Label_Evasion
@onready var label_block: Label = %Label_Block

# Utility Stats
@onready var label_life_steal: Label = %Label_LifeSteal
@onready var label_mana_regen: Label = %Label_ManaRegen
@onready var label_health_regen: Label = %Label_HealthRegen

func _ready() -> void:
	if PauseMenu:
		PauseMenu.shown.connect(update_stats)
	
	inventory = PlayerManager.INVENTORY_DATA
	if inventory:
		inventory.equipment_changed.connect(update_stats)
		inventory.quick_slot_changed.connect(_update_consumable_slot)
	
	# Update stats and equipment when ready
	call_deferred("update_stats")
	call_deferred("_update_equipment_slots")

func update_stats() -> void:
	player = PlayerManager.player
	if not player:
		return
	
	# Basic Info
	if label_level:
		label_level.text = str(player.level)
	
	if label_xp:
		if player.level < PlayerManager.level_requirements.size():
			label_xp.text = str(player.xp) + "/" + str(PlayerManager.level_requirements[player.level])
		else:
			label_xp.text = "MAX"
	
	if label_class:
		label_class.text = PlayerManager.character_class
	
	# Primary Stats
	if label_hp:
		var max_hp = player.calculate_max_health()
		var hp_bonus = player.get_total_health_bonus()
		if hp_bonus > 0:
			label_hp.text = "%d (+%d)" % [max_hp, hp_bonus]
		else:
			label_hp.text = str(max_hp)
	
	if label_mana:
		var max_mana = player.calculate_max_mana()
		var mana_bonus = player.get_total_mana_bonus()
		if mana_bonus > 0:
			label_mana.text = "%d (+%d)" % [max_mana, mana_bonus]
		else:
			label_mana.text = str(max_mana)
	
	if label_attack:
		var attack = player.calculate_attack_damage()
		var attack_bonus = player.get_total_attack_bonus()
		if attack_bonus > 0:
			label_attack.text = "%d (+%d)" % [attack, attack_bonus]
		else:
			label_attack.text = str(attack)
	
	if label_defense:
		var defense = player.calculate_defense()
		var defense_bonus = player.get_total_defense_bonus()
		if defense_bonus > 0:
			label_defense.text = "%d (+%d)" % [defense, defense_bonus]
		else:
			label_defense.text = str(defense)
	
	# Combat Stats
	if label_crit_chance:
		var crit = player.get_total_critical_chance_bonus()
		if crit > 0:
			label_crit_chance.text = "%.1f%%" % crit
		else:
			label_crit_chance.text = "0%"
	
	if label_crit_damage:
		var crit_dmg = player.get_total_critical_damage_bonus()
		if crit_dmg > 0:
			label_crit_damage.text = "+%.0f%%" % crit_dmg
		else:
			label_crit_damage.text = "0%"
	
	if label_attack_speed:
		var atk_spd = player.get_total_attack_speed_bonus()
		if atk_spd > 0:
			label_attack_speed.text = "+%.0f%%" % atk_spd
		else:
			label_attack_speed.text = "0%"
	
	if label_move_speed:
		var move_spd = player.get_total_movement_speed_bonus()
		if move_spd > 0:
			label_move_speed.text = "+%.0f%%" % move_spd
		else:
			label_move_speed.text = "0%"
	
	# Attribute Stats
	if label_strength:
		var str_bonus = player.get_total_strength_bonus()
		if str_bonus > 0:
			label_strength.text = str(str_bonus)
		else:
			label_strength.text = "0"
	
	if label_dexterity:
		var dex_bonus = player.get_total_dexterity_bonus()
		if dex_bonus > 0:
			label_dexterity.text = str(dex_bonus)
		else:
			label_dexterity.text = "0"
	
	if label_intelligence:
		var int_bonus = player.get_total_intelligence_bonus()
		if int_bonus > 0:
			label_intelligence.text = str(int_bonus)
		else:
			label_intelligence.text = "0"
	
	if label_vitality:
		var vit_bonus = player.get_total_vitality_bonus()
		if vit_bonus > 0:
			label_vitality.text = str(vit_bonus)
		else:
			label_vitality.text = "0"
	
	# Defensive Stats
	if label_magic_res:
		var magic_res = player.get_total_magic_resistance_bonus()
		if magic_res > 0:
			label_magic_res.text = str(magic_res)
		else:
			label_magic_res.text = "0"
	
	if label_evasion:
		var evasion = player.get_total_evasion_bonus()
		if evasion > 0:
			label_evasion.text = "%.1f%%" % evasion
		else:
			label_evasion.text = "0%"
	
	if label_block:
		var block = player.get_total_block_chance_bonus()
		if block > 0:
			label_block.text = "%.1f%%" % block
		else:
			label_block.text = "0%"
	
	# Utility Stats
	if label_life_steal:
		var life_steal = player.get_total_life_steal_bonus()
		if life_steal > 0:
			label_life_steal.text = "%.1f%%" % life_steal
		else:
			label_life_steal.text = "0%"
	
	if label_mana_regen:
		var mana_regen = player.get_total_mana_regen_bonus()
		if mana_regen > 0:
			label_mana_regen.text = "%.1f/s" % mana_regen
		else:
			label_mana_regen.text = "0/s"
	
	if label_health_regen:
		var health_regen = player.get_total_health_regen_bonus()
		if health_regen > 0:
			label_health_regen.text = "%.1f/s" % health_regen
		else:
			label_health_regen.text = "0/s"
	
	# Update equipment slots
	_update_equipment_slots()

func _update_equipment_slots() -> void:
	"""Update equipment slot displays"""
	if not PlayerManager.INVENTORY_DATA:
		return
	
	var equipment_slots = PlayerManager.INVENTORY_DATA.equipment_slots()
	
	# Update equipment slots - Order: [0]=Weapon, [1]=Helmet, [2]=Armor, [3]=Boots
	# UI slots are named: weapon, armor (helmet), amulet (armor), ring (boots)
	if slot_weapon and equipment_slots.size() > 0:
		slot_weapon.set_slot_data(equipment_slots[0])  # Weapon
	
	if slot_armor and equipment_slots.size() > 1:
		slot_armor.set_slot_data(equipment_slots[1])  # Helmet (displayed in "armor" slot)
	
	if slot_amulet and equipment_slots.size() > 2:
		slot_amulet.set_slot_data(equipment_slots[2])  # Armor (displayed in "amulet" slot)
	
	if slot_ring and equipment_slots.size() > 3:
		slot_ring.set_slot_data(equipment_slots[3])  # Boots (displayed in "ring" slot)
	
	# Update consumable slot (quick slot)
	_update_consumable_slot()

func _update_consumable_slot() -> void:
	"""Update the consumable/potion slot"""
	if slot_consumable and PlayerManager.INVENTORY_DATA:
		slot_consumable.set_slot_data(PlayerManager.INVENTORY_DATA.quick_slot)
