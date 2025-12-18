extends Sprite2D

# Mage sprite controller with floating animation
# Frame 0 = Down, Frame 1 = Side, Frame 2 = Up

@onready var animation_player: AnimationPlayer = get_parent().get_node("AnimationPlayer")

var current_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	# Start floating animation
	if animation_player:
		animation_player.play("float")
	
	# Set initial frame
	frame = 0

func set_direction(direction: Vector2) -> void:
	"""Update sprite frame based on movement direction"""
	current_direction = direction
	
	if direction == Vector2.ZERO:
		return
	
	# Determine which frame to show based on direction
	var angle = direction.angle()
	
	# Down (frame 0): -45° to 45°
	if angle >= -PI/4 and angle < PI/4:
		frame = 1  # Side (right)
		flip_h = false
	# Up (frame 2): 135° to -135°
	elif angle >= 3*PI/4 or angle < -3*PI/4:
		frame = 2  # Up
		flip_h = false
	# Left (frame 1 flipped): 45° to 135°
	elif angle >= PI/4 and angle < 3*PI/4:
		frame = 0  # Down
		flip_h = false
	# Right (frame 1): -135° to -45°
	else:
		frame = 1  # Side (left)
		flip_h = true

func update_animation(velocity: Vector2) -> void:
	"""Called from player script to update sprite"""
	if velocity != Vector2.ZERO:
		set_direction(velocity.normalized())
