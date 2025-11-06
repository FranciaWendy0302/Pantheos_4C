class_name State_ArrowBarrage extends State

const ARROW = preload("res://Interactables/arrow/arrow.tscn")

@export var arrow_count: int = 5
@export var spread_angle: float = 30.0  # Total spread angle in degrees
@export var barrage_delay: float = 0.1  # Delay between arrows

@onready var idle: State = $"../Idle"

var _direction: Vector2 = Vector2.ZERO
var _arrows_fired: int = 0
var _next_state: State = null

func _ready():
	pass

func Enter() -> void:
	_arrows_fired = 0
	_direction = player.get_direction_to_mouse()
	if _direction == Vector2.ZERO:
		_direction = player.cardinal_direction
	
	# Update player facing
	_update_player_facing()
	
	player.UpdateAnimation("bow")
	
	# Show skill name label
	if PlayerManager.selected_class == "Archer":
		PlayerHud.show_skill_name("W", "Arrow Barrage")
	
	# Start firing arrows (async)
	_fire_barrage()  # This will fire arrows asynchronously
	pass

func Exit() -> void:
	# Hide skill name label
	if PlayerManager.selected_class == "Archer":
		PlayerHud.hide_skill_name("W")
	
	_next_state = null
	pass
	
func Process(_delta: float) -> State:
	player.velocity = Vector2.ZERO
	return _next_state

func Physics(_delta: float) -> State:
	return null
	
func HandleInput(_event: InputEvent) -> State:
	return null

func _fire_barrage() -> void:
	# Calculate spread per arrow
	var angle_step = deg_to_rad(spread_angle) / (arrow_count - 1) if arrow_count > 1 else 0.0
	var start_angle = -deg_to_rad(spread_angle) * 0.5
	
	# Fire arrows with spread
	for i in arrow_count:
		if player.arrow_count <= 0:
			break
		
		# Calculate angle for this arrow
		var angle = start_angle + (angle_step * i)
		var arrow_dir = _direction.rotated(angle)
		
		# Create arrow
		var arrow: Arrow = ARROW.instantiate()
		arrow.is_big_arrow = false
		player.add_sibling(arrow)
		arrow.global_position = player.global_position + (arrow_dir * 32)
		arrow.fire(arrow_dir)
		
		# Consume arrow
		player.arrow_count -= 1
		PlayerHud.update_arrow_count(player.arrow_count)
		
		# Small delay between arrows
		if i < arrow_count - 1:
			await get_tree().create_timer(barrage_delay).timeout
	
	# Start cooldown
	PlayerHud.start_charge_dash_cooldown()  # Reuse W skill cooldown
	
	# Return to idle after a short delay
	await get_tree().create_timer(0.1).timeout
	_next_state = idle
	pass

func _update_player_facing() -> void:
	# Update player direction to face mouse cursor
	var mouse_dir = player.get_direction_to_mouse()
	if mouse_dir != Vector2.ZERO:
		# Update cardinal direction based on mouse position
		if abs(mouse_dir.x) > abs(mouse_dir.y):
			player.cardinal_direction = Vector2.RIGHT if mouse_dir.x > 0 else Vector2.LEFT
		else:
			player.cardinal_direction = Vector2.DOWN if mouse_dir.y > 0 else Vector2.UP
		player.SetDirection()
	pass
