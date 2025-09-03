class_name Pathfinder extends Node2D

var vectors: Array[Vector2] = [
	Vector2(0, -1),
	Vector2(1, -1),
	Vector2(1, 0),
	Vector2(1, 1),
	Vector2(0, 1),
	Vector2(-1, 1),
	Vector2(-1, 0),
	Vector2(-1, -1)
]

var interests: Array[float]
var obstacles: Array[float] = [0, 0, 0, 0, 0, 0, 0, 0]
var outcomes: Array[float] = [0, 0, 0, 0, 0, 0, 0, 0]
var rays: Array[RayCast2D]

var move_dir: Vector2 = Vector2.ZERO
var best_path: Vector2 = Vector2.ZERO

@onready var timer: Timer = $Timer

func _ready() -> void:
	
	for c in get_children():
		if c is RayCast2D:
			rays.append(c)
	
	for i in vectors.size():
		vectors[i] = vectors[i].normalized()
	pass
	
	set_path()
	
	timer.timeout.connect(set_path)	
	pass

func _process(delta: float) -> void:
	move_dir = lerp(move_dir, best_path, 10 * delta)
	pass

func set_path() -> void:
	var player_dir: Vector2 = global_position.direction_to(PlayerManager.player.global_position)
	
	for i in 8:
		obstacles[i] = 0
		outcomes[i] = 0
		
	for i in 8:
		if rays[i].is_colliding():
			obstacles[i] += 4
			obstacles[get_next_i(i)] += 1
			obstacles[get_prev_i(i)] += 1
	
	if obstacles.max() == 0:
		best_path = player_dir
		return
	
	interests.clear()
	for v in vectors:
		interests.append(v.dot(player_dir))
	
	for i in 8:
		outcomes[i] = interests[i] - obstacles[i]
		
	
	
	best_path = vectors[outcomes.find(outcomes.max())]
	pass
	
func get_next_i(i: int) -> int:
	var n_i: int = i + 1
	if n_i >= 8:
		return 0
	else:
		return n_i
		
func get_prev_i(i: int) -> int:
	var n_i: int = i - 1
	if n_i < 0:
		return 7
	else:
		return n_i
