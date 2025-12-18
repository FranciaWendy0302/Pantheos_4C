extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var background: ColorRect = $Background

var max_hp: int = 100
var current_hp: int = 100
var target_hp: int = 100  # For smooth animation

func _ready():
	update_health(current_hp, max_hp)

func update_health(hp: int, max_hp_value: int) -> void:
	current_hp = hp
	max_hp = max_hp_value
	target_hp = hp
	
	if progress_bar:
		progress_bar.max_value = max_hp
		
		# Smooth HP bar animation
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", current_hp, 0.2)
		
		# Color coding based on HP percentage
		var hp_percent = float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
		var target_color: Color
		
		if hp_percent > 0.6:
			target_color = Color(0, 1, 0)  # Green
		elif hp_percent > 0.3:
			target_color = Color(1, 1, 0)  # Yellow
		else:
			target_color = Color(1, 0, 0)  # Red
		
		# Smooth color transition
		tween.parallel().tween_property(progress_bar, "modulate", target_color, 0.2)
	
	# Hide when at full HP, show when damaged
	visible = current_hp < max_hp

func _process(_delta):
	# Always face camera (billboard effect)
	if get_parent():
		rotation = 0
		
	# Auto-hide after 3 seconds at full HP
	if current_hp >= max_hp and visible:
		visible = false
