extends PanelContainer
class_name TutorialDialogue

## Tutorial dialogue system that appears after character creation

signal dialogue_completed

@onready var npc_name_label: Label = $MarginContainer/VBoxContainer/NPCName
@onready var dialogue_label: Label = $MarginContainer/VBoxContainer/DialogueText
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton

var current_dialogue_index: int = 0
var dialogue_sequence: Array[Dictionary] = []
var is_active: bool = false

func _ready():
	visible = false
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

func show_tutorial_dialogue(god_name: String, player_class: String):
	"""Show the initial tutorial dialogue based on chosen god and class"""
	is_active = true
	current_dialogue_index = 0
	
	# Build dialogue sequence based on class
	dialogue_sequence = _build_dialogue_sequence(god_name, player_class)
	
	# Show first dialogue
	_show_current_dialogue()
	visible = true

func _build_dialogue_sequence(god_name: String, player_class: String) -> Array[Dictionary]:
	"""Build the tutorial dialogue sequence"""
	var sequence: Array[Dictionary] = []
	
	# Opening dialogue from the god
	sequence.append({
		"speaker": god_name,
		"text": "Welcome, chosen one. I am %s, and you have pledged yourself to my cause." % god_name
	})
	
	sequence.append({
		"speaker": god_name,
		"text": "Before you begin your journey, you must understand the path of the %s." % player_class
	})
	
	# Class-specific explanation
	match player_class:
		"Mage":
			sequence.append({
				"speaker": god_name,
				"text": "As a Mage, your power comes from your equipment. Each staff, robe, and artifact grants you unique magical abilities."
			})
			sequence.append({
				"speaker": god_name,
				"text": "Your skills are bound to your equipment:\n• Q, W, E - Weapon Skills (Staff)\n• D - Armor Skill (Robes)\n• F - Boots Skill\n• R - Your Ultimate Power"
			})
			sequence.append({
				"speaker": god_name,
				"text": "Mages can specialize in different elements:\n• Fire Mage - High damage, area attacks\n• Ice Mage - Control and crowd control\n• Lightning Mage - Fast, chain attacks"
			})
		
		"Swordsman":
			sequence.append({
				"speaker": god_name,
				"text": "As a Swordsman, your strength lies in your blade and armor. Each weapon defines your combat style."
			})
			sequence.append({
				"speaker": god_name,
				"text": "Your skills are bound to your equipment:\n• Q, W, E - Weapon Skills (Sword)\n• D - Armor Skill\n• F - Boots Skill\n• R - Your Ultimate Power"
			})
			sequence.append({
				"speaker": god_name,
				"text": "Swordsmen can specialize:\n• Knight - Heavy armor, defensive\n• Berserker - High damage, aggressive\n• Duelist - Balanced, skillful"
			})
		
		"Archer":
			sequence.append({
				"speaker": god_name,
				"text": "As an Archer, precision and mobility are your weapons. Your bow determines your attack style."
			})
			sequence.append({
				"speaker": god_name,
				"text": "Your skills are bound to your equipment:\n• Q, W, E - Weapon Skills (Bow)\n• D - Armor Skill\n• F - Boots Skill\n• R - Your Ultimate Power"
			})
			sequence.append({
				"speaker": god_name,
				"text": "Archers can specialize:\n• Sniper - Long range, high damage\n• Ranger - Balanced, versatile\n• Hunter - Traps and mobility"
			})
	
	# Equipment system explanation
	sequence.append({
		"speaker": god_name,
		"text": "Remember: Your equipment IS your build. Change your weapon to change your playstyle completely."
	})
	
	sequence.append({
		"speaker": god_name,
		"text": "Each piece of equipment has unique skills. Experiment with different combinations to find your perfect build!"
	})
	
	# Quest introduction
	sequence.append({
		"speaker": god_name,
		"text": "Now, seek me out in the Safezone. I have a trial for you - survive 3 waves of enemies to prove your worth."
	})
	
	sequence.append({
		"speaker": "System",
		"text": "Quest Added: 'Trial of the Gods'\nObjective: Survive 3 waves of enemies\nReward: 500 XP + Equipment"
	})
	
	return sequence

func _show_current_dialogue():
	"""Display the current dialogue"""
	if current_dialogue_index >= dialogue_sequence.size():
		_finish_dialogue()
		return
	
	var dialogue = dialogue_sequence[current_dialogue_index]
	
	if npc_name_label:
		npc_name_label.text = dialogue.speaker
		# Color code based on speaker
		if dialogue.speaker == "System":
			npc_name_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			npc_name_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	
	if dialogue_label:
		dialogue_label.text = dialogue.text
	
	if continue_button:
		if current_dialogue_index == dialogue_sequence.size() - 1:
			continue_button.text = "Begin Journey"
		else:
			continue_button.text = "Continue"

func _on_continue_pressed():
	current_dialogue_index += 1
	_show_current_dialogue()

func _finish_dialogue():
	"""Complete the dialogue sequence"""
	visible = false
	is_active = false
	dialogue_completed.emit()
	print("[TutorialDialogue] Tutorial dialogue completed")

func _input(event):
	"""Allow space or enter to continue dialogue"""
	if not is_active or not visible:
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_continue_pressed()
