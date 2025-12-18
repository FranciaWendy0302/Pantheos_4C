extends Node

# Zeus Chapter 1: Storm's Fury
# Ranged Magic DPS quest for Zeus followers

const QUEST_DATA = {
	"id": "zeus_ch1_storms_fury",
	"title": "Zeus's Trial: Storm's Fury",
	"description": "Zeus, King of the Gods, has granted you dominion over lightning. To master this power, you must prove your ability to strike down enemies from afar with devastating magical force. Show Zeus that you can wield the storm itself.",
	"god_required": 2,  # GodManager.GodType.ZEUS
	"chapter": 1,
	"quest_giver": "Zeus's Herald",
	"objectives": [
		{
			"id": "lightning_kills",
			"description": "Defeat 50 enemies using magic attacks",
			"type": "kill",
			"method": "magic",
			"required": 50,
			"current": 0
		},
		{
			"id": "ranged_precision",
			"description": "Hit enemies from long range 30 times without missing",
			"type": "precision",
			"required": 30,
			"current": 0,
			"min_distance": 15.0  # meters
		},
		{
			"id": "chain_lightning",
			"description": "Hit multiple enemies with a single spell 10 times",
			"type": "multi_hit",
			"required": 10,
			"current": 0,
			"min_targets": 3
		}
	],
	"rewards": {
		"xp": 1000,
		"gold": 500,
		"items": [
			{"id": "zeus_staff", "name": "Zeus's Thunderbolt Staff", "rarity": "epic"}
		],
		"skill_unlock": "Lightning Bolt",
		"title": "Stormbringer"
	},
	"dialogue": {
		"start": [
			"Mortal! You dare seek the power of Zeus, King of Olympus?",
			"The storm is not for the weak-willed. Lightning does not discriminate.",
			"You must prove you can harness this raw power without being consumed by it.",
			"Strike down your enemies from afar. Let them fear the sky itself.",
			"Show me the fury of the storm, and I shall grant you my blessing!"
		],
		"progress": [
			"Good! The lightning answers your call!",
			"Your aim improves, mortal. But can you maintain this precision?",
			"The storm grows within you. Do not let it falter!"
		],
		"complete": [
			"MAGNIFICENT! You have mastered the storm!",
			"Few mortals can wield lightning without being destroyed by it.",
			"You have earned the right to call upon my power.",
			"I bestow upon you the Lightning Bolt - use it to smite those who oppose you!",
			"Go forth, Stormbringer! Let your enemies tremble at the sound of thunder!"
		]
	},
	"next_chapter": "zeus_ch2_olympian_wrath"
}

func get_quest_data() -> Dictionary:
	return QUEST_DATA

func can_start_quest() -> bool:
	var god_manager = get_node_or_null("/root/GodManager")
	if not god_manager:
		return false
	
	return god_manager.get_selected_god() == 2  # Zeus

func on_quest_complete() -> void:
	var god_manager = get_node_or_null("/root/GodManager")
	if god_manager:
		god_manager.unlock_god_skill()
	
	if PlayerManager.player and PlayerManager.player.has_node("PlayerAbilities"):
		PlayerManager.player.get_node("PlayerAbilities").add_ability("Lightning Bolt")
	
	print("[Zeus Quest] Chapter 1 complete! Lightning Bolt unlocked!")
