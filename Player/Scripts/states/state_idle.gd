class_name State_Idle extends State

var walk: Node = null
var attack: State_Attack = null
var bow: State_Bow = null
var dash: State = null

func _ready():
	walk = get_node_or_null("../Walk")
	attack = get_node_or_null("../Attack")
	bow = get_node_or_null("../Bow")
	dash = get_node_or_null("../Dash")
	
func Enter() -> void:
	player.UpdateAnimation("idle")
	pass

func Exit() -> void:
	pass
	
func Process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	player.velocity = Vector2.ZERO
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
