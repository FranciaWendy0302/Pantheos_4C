class_name State_Invisibility extends State

@export var invisibility_duration: float = 2.0
@export var invisibility_alpha: float = 0.3  # Transparency level (0.3 = 30% visible)

@onready var idle: State = $"../Idle"

var _timer: float = 0.0
var _original_collision_layer: int = 0
var _next_state: State = null

func _ready():
	pass

func Enter() -> void:
	_timer = invisibility_duration
	_original_collision_layer = player.collision_layer
	
	# Make player transparent but visible
	player.modulate = Color(1, 1, 1, invisibility_alpha)
	
	# Make player undetectable by enemies (remove from collision layer 4)
	player.collision_layer = 0
	
	# Make player invulnerable
	player.invulnerable = true
	
	# Disable vision area detection by temporarily removing player from collision
	# Enemies detect player via collision_layer 4, so removing it makes them undetectable
	
	player.UpdateAnimation("idle")
	
	# Show skill name label
	if PlayerManager.selected_class == "Archer":
		PlayerHud.show_skill_name("Q", "Invisibility")
	pass

func Exit() -> void:
	# Restore normal visibility
	player.modulate = Color(1, 1, 1, 1.0)
	
	# Restore collision layer (player is on layer 4)
	player.collision_layer = 4
	
	# Restore vulnerability
	player.invulnerable = false
	
	# Hide skill name label
	if PlayerManager.selected_class == "Archer":
		PlayerHud.hide_skill_name("Q")
	
	_next_state = null
	pass
	
func Process(_delta: float) -> State:
	_timer -= _delta
	
	if _timer <= 0.0:
		return idle
	
	# Player can still move during invisibility
	if player.direction != Vector2.ZERO:
		player.velocity = player.direction * 100.0  # Normal walk speed
		player.UpdateAnimation("walk")
		player.SetDirection()
	else:
		player.velocity = Vector2.ZERO
		player.UpdateAnimation("idle")
	
	return _next_state

func Physics(_delta: float) -> State:
	return null
	
func HandleInput(_event: InputEvent) -> State:
	return null
