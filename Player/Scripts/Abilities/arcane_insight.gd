extends Node
class_name ArcaneInsight

# Arcane Insight triggered passive - Activates when Q skill is used
# Increases max mana by 10% and spell crit chance by 15% for 6 seconds

var player: Node2D = null
var ability_system: Node = null
var mana_bonus: float = 0.10  # 10% max mana increase
var crit_bonus: float = 0.15  # 15% spell crit chance increase
var duration: float = 6.0
var original_max_mana: int = 0
var is_active: bool = false
var buff_timer: Timer = null

func _ready():
	# Create timer for buff duration
	buff_timer = Timer.new()
	buff_timer.one_shot = true
	buff_timer.timeout.connect(_on_buff_timeout)
	add_child(buff_timer)

func setup(target_player: Node2D, target_ability_system: Node):
	"""Setup the triggered passive"""
	player = target_player
	ability_system = target_ability_system
	
	if not player or not ability_system:
		return
	
	# Connect to ability_used signal to detect Q skill usage
	if not ability_system.ability_used.is_connected(_on_ability_used):
		ability_system.ability_used.connect(_on_ability_used)
	
	print("[ArcaneInsight] Triggered passive ready - activates on Q skill use")

func _on_ability_used(slot: String, ability_name: String):
	"""Triggered when any ability is used"""
	# Only activate on Q skill
	if slot == "Q":
		activate_buff()

func activate_buff():
	"""Activate the Arcane Insight buff"""
	if is_active:
		# Refresh duration if already active
		buff_timer.start(duration)
		print("[ArcaneInsight] Buff refreshed!")
		return
	
	if not player:
		return
	
	# Increase max mana by 10%
	if "max_mana" in player:
		original_max_mana = player.max_mana
		var bonus_mana = int(original_max_mana * mana_bonus)
		player.max_mana += bonus_mana
		player.mana = min(player.mana + bonus_mana, player.max_mana)  # Also increase current mana
		print("[ArcaneInsight] Max mana increased: %d -> %d (+%d)" % [original_max_mana, player.max_mana, bonus_mana])
	
	# Increase spell crit chance by 15%
	if "spell_crit_chance" in player:
		player.spell_crit_chance += crit_bonus
		print("[ArcaneInsight] Spell crit chance increased by +%.0f%%" % (crit_bonus * 100))
	elif "crit_chance" in player:
		player.crit_chance += crit_bonus
		print("[ArcaneInsight] Crit chance increased by +%.0f%%" % (crit_bonus * 100))
	
	is_active = true
	buff_timer.start(duration)
	print("[ArcaneInsight] Buff activated for %.1fs!" % duration)

func _on_buff_timeout():
	"""Remove buff when duration expires"""
	remove_buff()

func remove_buff():
	"""Remove the Arcane Insight buff"""
	if not is_active or not player or not is_instance_valid(player):
		return
	
	# Restore max mana
	if "max_mana" in player:
		player.max_mana = original_max_mana
		player.mana = min(player.mana, player.max_mana)  # Cap current mana
		print("[ArcaneInsight] Max mana restored to %d" % original_max_mana)
	
	# Remove spell crit chance bonus
	if "spell_crit_chance" in player:
		player.spell_crit_chance -= crit_bonus
		print("[ArcaneInsight] Spell crit chance removed")
	elif "crit_chance" in player:
		player.crit_chance -= crit_bonus
		print("[ArcaneInsight] Crit chance removed")
	
	is_active = false
	print("[ArcaneInsight] Buff expired!")

func cleanup():
	"""Cleanup when helmet is unequipped"""
	if is_active:
		remove_buff()
	
	if ability_system and ability_system.ability_used.is_connected(_on_ability_used):
		ability_system.ability_used.disconnect(_on_ability_used)
