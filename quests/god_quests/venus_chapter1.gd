extends Node

# Venus Chapter 1: Divine Charm
# Support Buffer/Debuffer quest for Venus followers

const QUEST_DATA = {
	"id": "venus_ch1_divine_charm",
	"title": "Venus's Trial: Divine Charm",
	"description": "Venus, Goddess of Love and Beauty, has granted you the power to charm and influence. To master this gift, you must prove your ability to enhance your allies and weaken your foes. Show Venus that you can turn the tide of battle through support.",
	"god_required": 3,  # GodManager.GodType.VENUS
	"chapter": 1,
	"quest_giver": "Venus's Priestess",
	"objectives": [
		{
			"id": "buff_allies",
			"description": "Buff allies 100 times",
			"type": "buff",
			"required": 100,
			"current": 0
		},
		{
			"id": "debuff_enemies",
			"description": "Debuff enemies 50 times",
			"type": "debuff",
			"required": 50,
			"current": 0
		},
		{
			"id": "win_without_damage",
			"description": "Win a battle using only support abilities (no direct damage)",
			"type": "special",
			"required": 1,
			"current": 0
		}
	],
	"rewards": {
		"xp": 1000,
		"gold": 500,
		"items": [
			{"id": "venus_charm", "name": "Venus's Enchanted Charm", "rarity": "epic"}
		],
		"skill_unlock": "Divine Charm",
		"title": "Charmer of Venus"
	},
	"dialogue": {
		"start": [
			"Welcome, dear one. You have chosen to walk the path of Venus, Goddess of Love and Beauty.",
			"True power lies not in brute force, but in the ability to influence and inspire.",
			"You will learn to enhance your allies, making them stronger, faster, more resilient.",
			"And you will learn to weaken your enemies, turning their strength into weakness.",
			"Prove to me that you understand: the greatest victories are won without bloodshed."
		],
		"progress": [
			"Excellent! Your allies grow stronger with your presence.",
			"See how your enemies falter under your influence?",
			"You're learning the art of support beautifully."
		],
		"complete": [
			"Magnificent! You have mastered the art of charm and influence!",
			"You understand that true power comes from lifting others up.",
			"Your enemies fall not to your blade, but to your cunning.",
			"I bestow upon you the Divine Charm - use it to turn any battle in your favor.",
			"Go forth, Charmer! Make your allies invincible and your enemies helpless!"
		]
	},
	"next_chapter": "venus_ch2_hearts_desire"
}

func get_quest_data() -> Dictionary:
	return QUEST_DATA

func can_start_quest() -> bool:
	var god_manager = get_node_or_null("/root/GodManager")
	if not god_manager:
		return false
	
	return god_manager.get_selected_god() == 3  # Venus

func on_quest_complete() -> void:
	var god_manager = get_node_or_null("/root/GodManager")
	if god_manager:
		god_manager.unlock_god_skill()
	
	if PlayerManager.player and PlayerManager.player.has_node("PlayerAbilities"):
		PlayerManager.player.get_node("PlayerAbilities").add_ability("Divine Charm")
	
	print("[Venus Quest] Chapter 1 complete! Divine Charm unlocked!")
