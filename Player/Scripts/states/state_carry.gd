class_name State_Carry extends State

@export var move_speed: float = 100.0
@export var throw_audio: AudioStream

var walking: bool = false
var throwable: Throwable

@onready var idle: State_Idle = $"../Idle"
@onready var stun: State_Stun = $"../Stun"


func init() -> void:
	
	pass
	
func Enter() -> void:
	player.UpdateAnimation("carry")
	walking = false
	pass

func Exit() -> void:
	if throwable:
		# Get direction to mouse cursor for throwing
		var throw_dir = player.get_direction_to_mouse()
		if throw_dir == Vector2.ZERO:
			if player.direction == Vector2.ZERO:
				throw_dir = player.cardinal_direction
			else:
				throw_dir = player.direction
		throwable.throw_direction = throw_dir
			
		if state_machine.next_state == stun:
			throwable.throw_direction = throwable.throw_direction.rotated(PI)
			throwable.drop()
			pass
		else:
			player.audio.stream = throw_audio
			player.audio.play()
			throwable.throw()
			pass
			
		pass
	pass
	pass
	
func Process(_delta: float) -> State:
	if player.direction == Vector2.ZERO:
		walking = false
		player.UpdateAnimation("carry")
	elif player.SetDirection() or walking == false:
		player.UpdateAnimation("carry_walk")
		walking = true
	player.velocity = player.direction * move_speed
	return null

func Physics(_delta: float) -> State:
	return null
	
func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("attack") or _event.is_action_pressed("interact"):
		return idle
	return null
