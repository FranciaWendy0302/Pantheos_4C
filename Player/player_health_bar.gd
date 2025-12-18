extends Control

@onready var progress_bar: ProgressBar = $ProgressBar

var max_hp: int = 100
var current_hp: int = 100
var shield_bar: ProgressBar = null
var player: CharacterBody2D = null

func _ready():
	# Get player reference
	player = get_parent() as CharacterBody2D
	
	# Create shield bar overlay
	_create_shield_bar()
	
	update_health(current_hp, max_hp)

func _create_shield_bar() -> void:
	"""Create a white/blue overlay bar for shield"""
	shield_bar = ProgressBar.new()
	shield_bar.name = "ShieldBar"
	shield_bar.show_percentage = false
	shield_bar.size = progress_bar.size
	shield_bar.position = progress_bar.position
	shield_bar.z_index = progress_bar.z_index + 1
	
	# Style the shield bar
	var shield_style = StyleBoxFlat.new()
	shield_style.bg_color = Color(0.8, 0.9, 1.0, 0.7)  # Light blue/white
	shield_style.border_color = Color(1.0, 1.0, 1.0, 0.9)
	shield_style.border_width_left = 1
	shield_style.border_width_right = 1
	shield_style.border_width_top = 1
	shield_style.border_width_bottom = 1
	shield_bar.add_theme_stylebox_override("fill", shield_style)
	
	# Start hidden
	shield_bar.visible = false
	add_child(shield_bar)

func update_health(hp: int, max_hp_value: int) -> void:
	current_hp = hp
	max_hp = max_hp_value
	
	if progress_bar:
		progress_bar.max_value = max_hp
		progress_bar.value = current_hp
		
		# Color coding based on HP percentage (only if no shield)
		if not player or not player.shield_active:
			var hp_percent = float(current_hp) / float(max_hp)
			if hp_percent > 0.6:
				progress_bar.modulate = Color(0, 1, 0)  # Green
			elif hp_percent > 0.3:
				progress_bar.modulate = Color(1, 1, 0)  # Yellow
			else:
				progress_bar.modulate = Color(1, 0, 0)  # Red
	
	# Always visible for player
	visible = true

func _process(_delta):
	# Always face camera (billboard effect)
	rotation = 0
	
	# Update shield bar
	if player and shield_bar:
		if player.shield_active and player.shield_amount > 0:
			shield_bar.visible = true
			shield_bar.max_value = max_hp
			shield_bar.value = current_hp + player.shield_amount
			
			# Make HP bar white/light when shielded
			progress_bar.modulate = Color(0.9, 0.95, 1.0)  # Light blue tint
		else:
			shield_bar.visible = false
			# Restore normal color coding
			update_health(current_hp, max_hp)
