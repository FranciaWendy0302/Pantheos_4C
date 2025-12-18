extends Node

# Hades Chapter 1: Shadow's Embrace
# Off-Tank / Control quest for Hades followers

const QUEST_DATA = {
	"id": "hades_ch1_shadows_embrace",
	"title": "Hades's Trial: Shadow's Embrace",
	"description": "Hades, God of the Underworld, has granted you dominion over death and shadows. To prove your worth, you must demonstrate your ability to control the battlefield through fear and darkness. Show Hades that you can make your enemies helpless before you.",
	"god_required": 5,  # GodManager.GodType.HADES
	"chapter": 1,
	"quest_giver": "Hades's Shade",
	"objectives": [
		{
			"id": "crowd_control",
			"description": "Control 50 enemies with crowd control effects",
			"type": "cc",
			"required": 50,
			"current": 0,
			"note": "Stun, root, slow, or fear"
		},
		{
			"id": "survive_surrounded",
			"description": "Survive 5 minutes while surrounded by 10+ enemies",
			"type": "survival",
			"required": 300,  # seconds
			"current": 0,
			"min_enemies": 10
		},
		{
			"id": "dot_kills",
			"description": "Defeat 30 enemies using damage-over-time effects",
			"type": "kill",
			"method": "dot",
			"required": 30,
			"current": 0
		}
	],
	"rewards": {
		"xp": 1000,
		"gold": 500,
		"items": [
			{"id": "hades_helm", "name": "Hades's Helm of Darkness", "rarity": "epic"}
		],
		"skill_unlock": "Shadow Grasp",
		"title": "Shadow of Hades"
	},
	"dialogue": {
		"start": [
			"You dare enter my domain? You seek the power of Hades, Lord of the Underworld?",
			"Death is not about brute force. It is about inevitability, control, despair.",
			"You will learn to make your enemies fear the shadows themselves.",
			"Control them. Weaken them. Let them know that escape is impossible.",
			"Prove to me that you understand: death comes not with a roar, but with a whisper."
		],
		"progress": [
			"Good. They cannot escape your grasp.",
			"Yes... let them feel the cold embrace of the underworld.",
			"You're learning. Control is power."
		],
		"complete": [
			"Impressive. You have mastered the art of control and despair.",
			"Your enemies fell not to your blade, but to their own helplessness.",
			"You understand that true power is making others powerless.",
			"I grant you Shadow Grasp - let it bind your enemies in darkness.",
			"Go forth, Shadow! Let all who face you know the inevitability of defeat!"
		]
	},
	"next_chapter": "hades_ch2_lord_of_death"
}

func get_quest_data() -> Dictionary:
	return QUEST_DATA

func can_start_quest() -> bool:
	var god_manager = get_node_or_null("/root/GodManager")
	if not god_manager:
		return false
	
	return god_manager.get_selected_god() == 5  # Hades

func on_quest_complete() -> void:
	var god_manager = get_node_or_null("/root/GodManager")
	if god_manager:
		god_manager.unlock_god_skill()
	
	if PlayerManager.player and PlayerManager.player.has_node("PlayerAbilities"):
		PlayerManager.player.get_node("PlayerAbilities").add_ability("Shadow Grasp")
	
	print("[Hades Quest] Chapter 1 complete! Shadow Grasp unlocked!")
