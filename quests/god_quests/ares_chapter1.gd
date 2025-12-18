extends Node

# Ares Chapter 1: Bloodlust
# Melee DPS quest for Ares followers

const QUEST_DATA = {
	"id": "ares_ch1_bloodlust",
	"title": "Ares's Trial: Bloodlust",
	"description": "Ares, God of War, has chosen you to embody pure combat fury. To prove your worth, you must demonstrate your ability to dominate the battlefield through relentless melee combat. Show Ares that you hunger for battle and victory.",
	"god_required": 6,  # GodManager.GodType.ARES
	"chapter": 1,
	"quest_giver": "Ares's Champion",
	"objectives": [
		{
			"id": "melee_kills",
			"description": "Defeat 100 enemies in melee combat",
			"type": "kill",
			"method": "melee",
			"required": 100,
			"current": 0
		},
		{
			"id": "kill_streaks",
			"description": "Achieve 10 kill streaks (5+ kills without taking damage)",
			"type": "streak",
			"required": 10,
			"current": 0,
			"streak_size": 5
		},
		{
			"id": "perfect_duel",
			"description": "Win a duel without taking any damage",
			"type": "special",
			"required": 1,
			"current": 0
		}
	],
	"rewards": {
		"xp": 1000,
		"gold": 500,
		"items": [
			{"id": "ares_blade", "name": "Ares's Bloodthirsty Blade", "rarity": "epic"}
		],
		"skill_unlock": "Berserker Rage",
		"title": "Warrior of Ares"
	},
	"dialogue": {
		"start": [
			"So, you dare to seek the favor of Ares, God of War?",
			"I care not for strategy, defense, or mercy. Only VICTORY!",
			"You will prove yourself through blood and steel!",
			"Crush your enemies in melee combat. Show no hesitation, no fear!",
			"Let your blade sing the song of war, and I shall grant you power beyond measure!"
		],
		"progress": [
			"YES! More blood! More glory!",
			"Your enemies fall like wheat before the scythe!",
			"This is what I want to see - pure, unbridled fury!"
		],
		"complete": [
			"MAGNIFICENT! You are a true warrior of Ares!",
			"You have bathed your blade in the blood of your enemies!",
			"You fight with the fury I demand - relentless, merciless, victorious!",
			"I grant you Berserker Rage - let it fuel your bloodlust!",
			"Go forth and DOMINATE! Let all who face you know FEAR!"
		]
	},
	"next_chapter": "ares_ch2_god_of_war"
}

func get_quest_data() -> Dictionary:
	return QUEST_DATA

func can_start_quest() -> bool:
	var god_manager = get_node_or_null("/root/GodManager")
	if not god_manager:
		return false
	
	return god_manager.get_selected_god() == 6  # Ares

func on_quest_complete() -> void:
	var god_manager = get_node_or_null("/root/GodManager")
	if god_manager:
		god_manager.unlock_god_skill()
	
	if PlayerManager.player and PlayerManager.player.has_node("PlayerAbilities"):
		PlayerManager.player.get_node("PlayerAbilities").add_ability("Berserker Rage")
	
	print("[Ares Quest] Chapter 1 complete! Berserker Rage unlocked!")
