class_name State_Walk extends State

@export var move_speed: float = 100.0

var idle: State = null
var attack: State = null
var bow: State_Bow = null
var dash: State = null

func _ready():
	idle = get_node_or_null("../Idle")
	attack = get_node_or_null("../Attack")
	bow = get_node_or_null("../Bow")
	dash = get_node_or_null("../Dash")

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
		return attack
	elif _event.is_action_pressed("interact"):
		PlayerManager.interact()
	elif _event.is_action_pressed("dash"):
		if not PlayerHud.is_dash_on_cooldown():
			return dash
	return null
