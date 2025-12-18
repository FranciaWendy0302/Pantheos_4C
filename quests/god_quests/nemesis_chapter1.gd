extends Node

# Nemesis Chapter 1: Divine Retribution
# Vengeance/Balance quest for Nemesis followers

const QUEST_DATA = {
	"id": "nemesis_ch1_divine_retribution",
	"title": "Nemesis's Trial: Divine Retribution",
	"description": "Nemesis, the Goddess of Retribution, offers you the power to balance the scales of justice. To prove your worth, you must demonstrate your ability to punish the wicked and protect the innocent. Show Nemesis that you can wield vengeance with righteousness.",
	"god_required": 8,  # GodManager.GodType.NEMESIS
	"chapter": 1,
	"quest_giver": "Gigantes's Spirit",
	"objectives": [
		{
			"id": "boss_succession",
			"description": "Defeat 3 bosses in succession without resting",
			"type": "boss_rush",
			"required": 3,
			"current": 0
		},
		{
			"id": "massive_damage",
			"description": "Deal 50,000 total damage in a single battle",
			"type": "damage",
			"required": 50000,
			"current": 0
		},
		{
			"id": "heavy_attacks",
			"description": "Crush 30 enemies with heavy attacks",
			"type": "kill",
			"method": "heavy",
			"required": 30,
			"current": 0
		}
	],
	"rewards": {
		"xp": 1000,
		"gold": 500,
		"items": [
			{"id": "gigantes_hammer", "name": "Gigantes's Colossal Hammer", "rarity": "epic"}
		],
		"skill_unlock": "Giant's Wrath",
		"title": "Giant's Heir"
	},
	"dialogue": {
		"start": [
			"You... tiny mortal... seek the power of the Gigantes?",
			"We were born to overthrow the gods. We were GIANTS among insects.",
			"The gods feared our size, our strength, our unstoppable might.",
			"You will learn to fight like a giant - every blow devastating, every step earth-shaking.",
			"Prove you can wield the power of the colossal! Crush all who stand before you!"
		],
		"progress": [
			"GOOD! Crush them like the insects they are!",
			"Your blows shake the earth! This is giant's might!",
			"You're growing stronger... bigger... more powerful!"
		],
		"complete": [
			"INCREDIBLE! You fight with the fury of a true giant!",
			"You have proven that size and strength can overcome any obstacle!",
			"The gods may have defeated us, but our legacy lives through you!",
			"We grant you Giant's Wrath - grow to our size and crush your enemies!",
			"Go forth, Giant's Heir! Show the world what it means to be COLOSSAL!"
		]
	},
	"next_chapter": "gigantes_ch2_rise_of_giants"
}

func get_quest_data() -> Dictionary:
	return QUEST_DATA

func can_start_quest() -> bool:
	var god_manager = get_node_or_null("/root/GodManager")
	if not god_manager:
		return false
	
	return god_manager.get_selected_god() == 8  # Gigantes

func on_quest_complete() -> void:
	var god_manager = get_node_or_null("/root/GodManager")
	if god_manager:
		god_manager.unlock_god_skill()
	
	if PlayerManager.player and PlayerManager.player.has_node("PlayerAbilities"):
		PlayerManager.player.get_node("PlayerAbilities").add_ability("Giant's Wrath")
	
	print("[Gigantes Quest] Chapter 1 complete! Giant's Wrath unlocked!")
