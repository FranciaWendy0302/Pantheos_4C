extends Node

# Athena Chapter 1: Shield of Wisdom
# Tank-focused quest for Athena followers

const QUEST_DATA = {
	"id": "athena_ch1_shield_of_wisdom",
	"title": "Athena's Trial: Shield of Wisdom",
	"description": "Athena, Goddess of Wisdom and War, has chosen you as her champion. To prove your worth, you must demonstrate your defensive prowess by protecting the village from waves of enemies. Show Athena that you can be the shield that protects the innocent.",
	"god_required": 1,  # GodManager.GodType.ATHENA
	"chapter": 1,
	"quest_giver": "Athena's Oracle",
	"objectives": [
		{
			"id": "defend_village",
			"description": "Defend the village from 10 enemy waves",
			"type": "defend",
			"target": "village",
			"waves_required": 10,
			"waves_completed": 0,
			"allow_villager_deaths": 0  # No villagers can die
		},
		{
			"id": "block_attacks",
			"description": "Successfully block 50 enemy attacks",
			"type": "block",
			"required": 50,
			"current": 0
		},
		{
			"id": "protect_allies",
			"description": "Take damage meant for allies 20 times",
			"type": "protect",
			"required": 20,
			"current": 0
		}
	],
	"rewards": {
		"xp": 1000,
		"gold": 500,
		"items": [
			{"id": "athena_shield", "name": "Athena's Blessed Shield", "rarity": "epic"}
		],
		"skill_unlock": "Aegis Shield",
		"title": "Champion of Athena"
	},
	"dialogue": {
		"start": [
			"Mortal, you have chosen to walk the path of Athena, Goddess of Wisdom and War.",
			"Unlike Ares, who revels in bloodshed, Athena values strategy and protection.",
			"Your role is not to seek glory in battle, but to be the shield that protects the weak.",
			"Prove your worth by defending the village from the coming darkness.",
			"Remember: A true warrior's strength is measured not by enemies slain, but by allies saved."
		],
		"progress": [
			"You fight well, champion. But remember - defense requires patience.",
			"Athena watches your progress. Do not let your guard down.",
			"The enemy grows stronger. Adapt your strategy."
		],
		"complete": [
			"Magnificent! You have proven yourself worthy of Athena's blessing.",
			"You did not seek glory or bloodshed - you protected those who could not protect themselves.",
			"As a reward, I bestow upon you the power of the Aegis Shield.",
			"Use it wisely, Champion of Athena. The goddess's eyes are upon you."
		]
	},
	"next_chapter": "athena_ch2_tactical_mind"
}

func get_quest_data() -> Dictionary:
	return QUEST_DATA

func can_start_quest() -> bool:
	# Check if player has Athena as their god
	var god_manager = get_node_or_null("/root/GodManager")
	if not god_manager:
		return false
	
	return god_manager.get_selected_god() == 1  # Athena

func on_quest_complete() -> void:
	# Unlock Athena's special skill
	var god_manager = get_node_or_null("/root/GodManager")
	if god_manager:
		god_manager.unlock_god_skill()
	
	# Add skill to player
	if PlayerManager.player and PlayerManager.player.has_node("PlayerAbilities"):
		PlayerManager.player.get_node("PlayerAbilities").add_ability("Aegis Shield")
	
	print("[Athena Quest] Chapter 1 complete! Aegis Shield unlocked!")
