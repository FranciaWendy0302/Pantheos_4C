class_name State_Walk extends State

@export var move_speed: float = 100.0

@onready var idle: State = $"../Idle"
@onready var attack: State = $"../Attack"
@onready var bow: State_Bow = $"../Bow"
@onready var dash: State = $"../Dash"


func Enter() -> void:
	player.UpdateAnimation("walk")
	pass

func Exit() -> void:
	pass
	
func Process(_delta: float) -> State:
	if player.direction == Vector2.ZERO:
		return idle
		
	player.velocity = player.direction * move_speed
	if player.SetDirection():
		player.UpdateAnimation("walk")
	return null

func Physics(_delta: float) -> State:
	
	return null
	
func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("attack"):
		# Check basic attack cooldown only for Archer
		if PlayerManager.selected_class == "Archer" and player.basic_attack_cooldown > 0.0:
			return null  # Attack is on cooldown, ignore input
		
		# Archer always uses bow, Warrior uses sword
		if PlayerManager.selected_class == "Archer":
			# Check if Archer can attack (cooldown check is in bow state)
			return bow
		else:
			return attack
	elif _event.is_action_pressed("interact"):
		PlayerManager.interact()
	elif _event.is_action_pressed("dash"):
		# Dash is only for Warrior class, not Archer
		if PlayerManager.selected_class != "Archer" and not PlayerHud.is_dash_on_cooldown():
			return dash
	return null
