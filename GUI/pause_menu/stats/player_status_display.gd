extends RichTextLabel
class_name PlayerStatusDisplay

## Comprehensive player status display with all stats

func _ready() -> void:
	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	
	# Update when pause menu is shown
	if get_tree().root.has_node("PauseMenu"):
		var pause_menu = get_tree().root.get_node("PauseMenu")
		if pause_menu.has_signal("shown"):
			pause_menu.shown.connect(update_status)
	
	# Update when equipment changes
	if PlayerManager.INVENTORY_DATA:
		PlayerManager.INVENTORY_DATA.equipment_changed.connect(update_status)

func update_status() -> void:
	"""Generate and display comprehensive player status"""
	if not PlayerManager.player:
		text = "[center][color=red]No player data[/color][/center]"
		return
	
	var player = PlayerManager.player
	var inventory = PlayerManager.INVENTORY_DATA
	
	# Calculate total stats with equipment bonuses
	var total_attack = player.attack + inventory.get_attack_bonus()
	var total_defense = player.defense + inventory.get_defense_bonus()
	var total_max_hp = player.max_hp + inventory.get_health_bonus()
	var total_speed = player.speed + inventory.get_speed_bonus()
	
	# Build status text
	var status = ""
	
	# Header
	status += "[center][b][color=gold]═══ PLAYER STATUS ═══[/color][/b][/center]\n\n"
	
	# Basic Info
	status += "[color=cyan]Name:[/color] " + PlayerManager.nickname + "\n"
	status += "[color=cyan]Class:[/color] " + PlayerManager.character_class + "\n"
	status += "[color=cyan]Level:[/color] " + str(player.level) + "\n\n"
	
	# Health & Resources
	status += "[b][color=lime]═══ VITALS ═══[/color][/b]\n"
	status += "[color=red]HP:[/color] " + format_number(player.hp) + " / " + format_number(total_max_hp) + "\n"
	
	# Show HP bonus if any
	if inventory.get_health_bonus() > 0:
		status += "  [color=gray](Base: " + str(player.max_hp) + " + " + str(inventory.get_health_bonus()) + ")[/color]\n"
	
	# XP Progress
	if player.level < PlayerManager.level_requirements.size():
		var current_xp = player.xp
		var required_xp = PlayerManager.level_requirements[player.level]
		var xp_percent = int((float(current_xp) / float(required_xp)) * 100)
		status += "[color=yellow]XP:[/color] " + format_number(current_xp) + " / " + format_number(required_xp) + " (" + str(xp_percent) + "%)\n"
	else:
		status += "[color=yellow]XP:[/color] [color=gold]MAX LEVEL[/color]\n"
	
	status += "\n"
	
	# Combat Stats
	status += "[b][color=orange]═══ COMBAT STATS ═══[/color][/b]\n"
	
	# Attack
	status += "[color=red]Attack Power:[/color] " + str(total_attack)
	if inventory.get_attack_bonus() > 0:
		status += " [color=lime](+" + str(inventory.get_attack_bonus()) + ")[/color]"
	status += "\n"
	
	# Defense
	status += "[color=blue]Defense:[/color] " + str(total_defense)
	if inventory.get_defense_bonus() > 0:
		status += " [color=lime](+" + str(inventory.get_defense_bonus()) + ")[/color]"
	status += "\n"
	
	# Speed
	status += "[color=cyan]Movement Speed:[/color] " + str(total_speed) + "%"
	if inventory.get_speed_bonus() > 0:
		status += " [color=lime](+" + str(inventory.get_speed_bonus()) + "%)[/color]"
	status += "\n"
	
	# TODO: Add these when implemented
	# status += "[color=yellow]Critical Chance:[/color] 6%\n"
	# status += "[color=purple]Critical Damage:[/color] 150%\n"
	
	status += "\n"
	
	# Currency
	status += "[b][color=yellow]═══ CURRENCY ═══[/color][/b]\n"
	status += "[color=gold]Gold:[/color] " + format_number(player.currency) + "\n"
	if player.has("gems"):
		status += "[color=cyan]Gems:[/color] " + format_number(player.gems) + "\n"
	
	status += "\n"
	
	# Equipment
	status += "[b][color=purple]═══ EQUIPMENT ═══[/color][/b]\n"
	var equipment_slots = inventory.equipment_slots()
	var equipment_names = []
	
	for i in equipment_slots.size():
		if equipment_slots[i] != null and equipment_slots[i].item_data != null:
			var item_name = equipment_slots[i].item_data.name
			var slot_name = ""
			
			match i:
				0: slot_name = "Weapon"
				1: slot_name = "Helmet"
				2: slot_name = "Armor"
				3: slot_name = "Boots"
			
			status += "[color=gray]" + slot_name + ":[/color] " + item_name + "\n"
			equipment_names.append(item_name)
	
	if equipment_names.size() == 0:
		status += "[color=gray]No equipment equipped[/color]\n"
	
	# Set the text
	text = status

func format_number(num: int) -> String:
	"""Format number with comma separators"""
	var str_num = str(num)
	var result = ""
	var count = 0
	
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1
	
	return result
