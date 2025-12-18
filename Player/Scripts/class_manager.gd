class_name ClassManager
extends Node

enum PlayerClass {
	WARRIOR,
	MAGE,
	ARCHER,
	ROGUE
}

var current_class: PlayerClass = PlayerClass.WARRIOR

func _init():
	pass

func set_player_class(new_class: PlayerClass):
	current_class = new_class

func get_class_name() -> String:
	match current_class:
		PlayerClass.WARRIOR:
			return "Warrior"
		PlayerClass.MAGE:
			return "Mage"
		PlayerClass.ARCHER:
			return "Archer"
		PlayerClass.ROGUE:
			return "Rogue"
		_:
			return "Unknown"