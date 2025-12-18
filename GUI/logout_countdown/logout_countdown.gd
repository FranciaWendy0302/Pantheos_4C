extends CanvasLayer

## Simple on-screen logout countdown display

var countdown_label: Label

func _ready() -> void:
	# Hide by default
	visible = false
	
	# Create label (it won't exist when loaded as autoload)
	if true:
		countdown_label = Label.new()
		countdown_label.name = "CountdownLabel"
		add_child(countdown_label)
		
		# Style the label
		countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		countdown_label.anchor_left = 0.5
		countdown_label.anchor_right = 0.5
		countdown_label.anchor_top = 0.0
		countdown_label.offset_left = -200
		countdown_label.offset_right = 200
		countdown_label.offset_top = 100
		countdown_label.offset_bottom = 200
		
		# Add theme overrides for better visibility
		countdown_label.add_theme_font_size_override("font_size", 32)
		countdown_label.add_theme_color_override("font_color", Color.YELLOW)
		countdown_label.add_theme_color_override("font_outline_color", Color.BLACK)
		countdown_label.add_theme_constant_override("outline_size", 4)
	
	# Connect to LogoutManager signals
	var logout_mgr = get_node_or_null("/root/LogoutManager")
	if logout_mgr:
		logout_mgr.logout_started.connect(_on_logout_started)
		logout_mgr.logout_cancelled.connect(_on_logout_cancelled)
		logout_mgr.logout_completed.connect(_on_logout_completed)
	
	print("[LogoutCountdown] Ready")

func _process(_delta: float) -> void:
	if not visible:
		return
	
	# Update countdown display
	var logout_mgr = get_node_or_null("/root/LogoutManager")
	if logout_mgr and logout_mgr.is_logging_out():
		var time_left = logout_mgr.get_logout_time_remaining()
		var seconds = int(ceil(time_left))
		
		countdown_label.text = "Logging out in " + str(seconds) + " seconds...\n(Move to cancel)"
		
		# Change color as time runs out
		if time_left <= 5.0:
			countdown_label.add_theme_color_override("font_color", Color.RED)
		elif time_left <= 10.0:
			countdown_label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			countdown_label.add_theme_color_override("font_color", Color.YELLOW)

func _on_logout_started(_countdown_time: float) -> void:
	"""Show countdown when logout starts"""
	visible = true
	print("[LogoutCountdown] Showing countdown")

func _on_logout_cancelled() -> void:
	"""Hide countdown when logout cancelled"""
	visible = false
	print("[LogoutCountdown] Hiding countdown - cancelled")

func _on_logout_completed() -> void:
	"""Hide countdown when logout completed"""
	visible = false
	print("[LogoutCountdown] Hiding countdown - completed")
