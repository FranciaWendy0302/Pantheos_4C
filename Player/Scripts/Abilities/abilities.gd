class_name PlayerAbilities extends Node

const BOOMERANG = preload("res://Player/boomerang.tscn")

var abilities :Array[String] = [
	"", "", "", ""
]

var selected_ability: int = 0
var player: Player
var boomerang_instance: Boomerang = null
var god_skills: GodSkills = null  # God-bestowed skills

@onready var state_machine: PlayerStateMachine = $"../StateMachine"
@onready var lift: State_Lift = $"../StateMachine/Lift"
@onready var idle: State_Idle = $"../StateMachine/Idle"
@onready var walk: State_Walk = $"../StateMachine/Walk"
@onready var bow: State_Bow = $"../StateMachine/Bow"
@onready var grapple: State_Grapple = $"../StateMachine/Grapple"


func _ready() -> void:
	player = PlayerManager.player
	PlayerHud.update_arrow_count(player.arrow_count)
	setup_abilities()
	SaveManager.game_loaded.connect(_on_game_loaded)
	PlayerManager.INVENTORY_DATA.ability_acquired.connect(_on_ability_acquired)
	
	# Setup god skills
	god_skills = get_node_or_null("../GodSkills")
	if god_skills == null:
		print("[Abilities] Warning: GodSkills node not found")
	
func setup_abilities(select_index: int = 0) -> void:
	PauseMenu.update_ability_items(abilities)
	PlayerHud.update_ability_items(abilities)
	selected_ability = select_index - 1
	toggle_ability()
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ability"):
		match selected_ability:
			0:
				boomerang_ability()
			1:
				grapple_ability()
			2:
				bow_ability()
	# Removed switch_ability - not used in current system
	# elif event.is_action_pressed("switch_ability"):
	#	toggle_ability()
	elif event.is_action_pressed("god_skill"):
		# Use god-bestowed special skill (G key)
		if god_skills:
			god_skills.use_god_skill()
	pass
	
func toggle_ability() -> void:
	if abilities.count("") == abilities.size():
		return
	selected_ability = wrapi(selected_ability + 1, 0, 4)
	while abilities[selected_ability] == "":
		selected_ability = wrapi(selected_ability + 1, 0, 4)
	PlayerHud.update_ability_ui(selected_ability)
	pass

func boomerang_ability() -> void:
	if boomerang_instance != null:
		return
	var _b = BOOMERANG.instantiate() as Boomerang
	player.add_sibling(_b)
	_b.global_position = player.global_position
	
	# Get direction to mouse cursor
	var throw_direction = player.get_direction_to_mouse()
	if throw_direction == Vector2.ZERO:
		throw_direction = player.cardinal_direction
		
	_b.throw(throw_direction)
	boomerang_instance = _b
	pass

func bow_ability() -> void:
	if player.arrow_count <= 0:
		return
	elif state_machine.current_state == idle or state_machine.current_state == walk:
		player.arrow_count -= 1
		player.state_machine.ChangeState(bow)
		pass
	pass

func grapple_ability() -> void:
	# Grapple hook ability - DISABLED for all classes
	# Grapple has been removed from Swordsman and Mage
	return
	# if state_machine.current_state == idle or state_machine.current_state == walk:
	#	player.state_machine.ChangeState(grapple)
	#	pass
	# pass

func _on_game_loaded() -> void:
	var new_abilities = SaveManager.current_save.get("abilities", ["", "", "", ""])
	if new_abilities is Array:
		abilities.clear()
		for i in new_abilities:
			abilities.append(i)
	else:
		abilities = ["", "", "", ""]
	setup_abilities()
	pass

func _on_ability_acquired(_ability: AbilityItemData) -> void:
	match _ability.type:
		_ability.Type.BOOMERANG:
			abilities[0] = "BOOMERANG"
		_ability.Type.GRAPPLE:
			abilities[1] = "GRAPPLE"
		_ability.Type.ARROW:
			abilities[2] = "ARROW"
	setup_abilities(selected_ability)
	pass
