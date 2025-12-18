extends Node

# Asclepius Chapter 1: Sacred Healing
# Healer quest for Asclepius followers

const QUEST_DATA = {
	"id": "asclepius_ch1_sacred_healing",
	"title": "Asclepius's Trial: Sacred Healing",
	"description": "Asclepius, God of Medicine and Healing, has chosen you to learn the sacred arts of restoration. To prove your worth, you must demonstrate your ability to preserve life and prevent death. Show Asclepius that you can be a beacon of hope in the darkest battles.",
	"god_required": 4,  # GodManager.GodType.ASCLEPIUS
	"chapter": 1,
	"quest_giver": "Asclepius's Disciple",
	"objectives": [
		{
			"id": "heal_total",
			"description": "Heal 10,000 HP total across all allies",
			"type": "heal",
			"required": 10000,
			"current": 0
		},
		{
			"id": "save_from_death",
			"description": "Save an ally from fatal damage 10 times",
			"type": "save",
			"required": 10,
			"current": 0,
			"note": "Heal ally when HP is below 20%"
		},
		{
			"id": "perfect_dungeon",
			"description": "Complete a dungeon without anyone dying",
			"type": "special",
			"required": 1,
			"current": 0
		}
	],
	"rewards": {
		"xp": 1000,
		"gold": 500,
		"items": [
			{"id": "asclepius_staff", "name": "Asclepius's Healing Staff", "rarity": "epic"}
		],
		"skill_unlock": "Divine Restoration",
		"title": "Healer of Asclepius"
	},
	"dialogue": {
		"start": [
			"Greetings, chosen one. You seek to follow Asclepius, God of Medicine and Healing.",
			"The path of a healer is noble, but demanding. You will bear the weight of others' lives.",
			"Your duty is not to slay enemies, but to ensure no ally falls.",
			"You must be vigilant, quick to act, and selfless in your devotion.",
			"Prove to me that you can preserve life, even in the face of overwhelming danger."
		],
		"progress": [
			"Well done! Your healing touch grows stronger.",
			"You saved them! That is the mark of a true healer.",
			"Asclepius watches your progress with approval."
		],
		"complete": [
			"Extraordinary! You have proven yourself a master of the healing arts!",
			"You did not let a single soul perish under your care.",
			"Your dedication to preserving life is truly admirable.",
			"I grant you the Divine Restoration - the most powerful healing gift of Asclepius.",
			"Go forth, Healer! Be the light that guides others through darkness!"
		]
	},
	"next_chapter": "asclepius_ch2_life_and_death"
}

func get_quest_data() -> Dictionary:
	return QUEST_DATA

func can_start_quest() -> bool:
	var god_manager = get_node_or_null("/root/GodManager")
	if not god_manager:
		return false
	
	return god_manager.get_selected_god() == 4  # Asclepius

func on_quest_complete() -> void:
	var god_manager = get_node_or_null("/root/GodManager")
	if god_manager:
		god_manager.unlock_god_skill()
	
	if PlayerManager.player and PlayerManager.player.has_node("PlayerAbilities"):
		PlayerManager.player.get_node("PlayerAbilities").add_ability("Divine Restoration")
	
	print("[Asclepius Quest] Chapter 1 complete! Divine Restoration unlocked!")
