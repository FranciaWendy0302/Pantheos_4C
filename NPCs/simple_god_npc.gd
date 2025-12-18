extends Area2D

# Simple God NPC - Just shows dialogue when player presses G
# Attach this to an Area2D node that's a child of your god sprite

@export var god_type: GodManager.GodType = GodManager.GodType.ATHENA
@export var god_portrait_path: String = ""  # Path to god PNG for dialogue

var player_in_range: bool = false
var interaction_label: Label = null

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create interaction label
	_create_interaction_label()

func _create_interaction_label():
	"""Create 'Press G' label"""
	interaction_label = Label.new()
	interaction_label.text = "Press G to talk"
	interaction_label.position = Vector2(-40, -60)
	interaction_label.add_theme_font_size_override("font_size", 12)
	interaction_label.add_theme_color_override("font_color", Color.WHITE)
	interaction_label.add_theme_color_override("font_outline_color", Color.BLACK)
	interaction_label.add_theme_constant_override("outline_size", 2)
	interaction_label.visible = false
	add_child(interaction_label)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		_show_dialogue()

func _on_body_entered(body):
	if body is Player:
		player_in_range = true
		if interaction_label:
			interaction_label.visible = true

func _on_body_exited(body):
	if body is Player:
		player_in_range = false
		if interaction_label:
			interaction_label.visible = false

func _show_dialogue():
	"""Show simple dialogue"""
	var god_data = GodManager.get_god_data(god_type)
	var player_god = GodManager.get_selected_god()
	
	var dialogue_lines = []
	
	# Check if this is player's god
	if player_god == god_type:
		# Player's god - welcoming dialogue
		dialogue_lines = [
			"Greetings, my champion.",
			"I am " + god_data.name + ", " + god_data.title + ".",
			god_data.description,
			"",
			"Your special skill: " + god_data.special_skill,
			god_data.skill_description
		]
	else:
		# Not player's god - brief dialogue
		var player_god_data = GodManager.get_god_data(player_god)
		dialogue_lines = [
			"I am " + god_data.name + ", " + god_data.title + ".",
			"You serve " + player_god_data.name + ", not me.",
			"Seek your own god for guidance."
		]
	
	# Show dialogue with god portrait
	if DialogSystem:
		var dialogue_data = {
			"speaker": god_data.name,
			"lines": dialogue_lines,
			"portrait": god_portrait_path
		}
		DialogSystem.start_dialog(dialogue_data)
