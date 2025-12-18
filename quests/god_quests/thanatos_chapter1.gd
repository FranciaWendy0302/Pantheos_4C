extends Node

# Thanatos Chapter 1: Death's Embrace
# Assassin/Death quest for Thanatos followers

const QUEST_DATA = {
	"id": "thanatos_ch1_deaths_embrace",
	"title": "Thanatos's Trial: Death's Embrace",
	"description": "Thanatos, the God of Death, offers you mastery over mortality itself. To prove your worth, you must demonstrate precision, stealth, and the ability to deliver death swiftly. Show Thanatos that you can wield the power of death without fear.",
	"god_required": 7,  # GodManager.GodType.THANATOS
	"chapter": 1,
	"quest_giver": "Titan's Echo",
	"objectives": [
		{
			"id": "raw_power_kills",
			"description": "Defeat 50 enemies using raw power (no finesse)",
			"type": "kill",
			"method": "heavy",
			"required": 50,
			"current": 0
		},
		{
			"id": "destroy_structures",
			"description": "Destroy 20 structures or obstacles",
			"type": "destroy",
			"required": 20,
			"current": 0
		},
		{
			"id": "overwhelming_odds",
			"description": "Defeat 15 enemies while outnumbered 3-to-1",
			"type": "special",
			"required": 15,
			"current": 0,
			"min_enemy_ratio": 3
		}
	],
	"rewards": {
		"xp": 1000,
		"gold": 500,
		"items": [
			{"id": "titan_gauntlets", "name": "Titan's Primordial Gauntlets", "rarity": "epic"}
		],
		"skill_unlock": "Titanic Fury",
		"title": "Titan's Chosen"
	},
	"dialogue": {
		"start": [
			"You... seek the power of the Titans? The power that shook Olympus itself?",
			"We are not gods. We are older. Stronger. Primal.",
			"The gods fear us because we do not play by their rules.",
			"You will learn to embrace chaos, to wield power without restraint.",
			"Show us your fury. Show us you can handle the primordial force!"
		],
		"progress": [
			"YES! Unleash that power!",
			"Destruction! Chaos! This is what we want to see!",
			"You're beginning to understand the old ways..."
		],
		"complete": [
			"MAGNIFICENT! You have embraced the primordial fury!",
			"You fight like the ancient ones - raw, powerful, unstoppable!",
			"The gods may have imprisoned us, but our power lives on through you!",
			"We grant you Titanic Fury - let it shake the very foundations of the earth!",
			"Go forth, Titan's Chosen! Show the gods what true power looks like!"
		]
	},
	"next_chapter": "titan_ch2_fall_of_olympus"
}

func get_quest_data() -> Dictionary:
	return QUEST_DATA

func can_start_quest() -> bool:
	var god_manager = get_node_or_null("/root/GodManager")
	if not god_manager:
		return false
	
	return god_manager.get_selected_god() == 7  # Titan

func on_quest_complete() -> void:
	var god_manager = get_node_or_null("/root/GodManager")
	if god_manager:
		god_manager.unlock_god_skill()
	
	if PlayerManager.player and PlayerManager.player.has_node("PlayerAbilities"):
		PlayerManager.player.get_node("PlayerAbilities").add_ability("Titanic Fury")
	
	print("[Titan Quest] Chapter 1 complete! Titanic Fury unlocked!")
