extends CanvasLayer

## Logout Panel - Shows logout countdown and allows cancellation

@onready var panel: PanelContainer = $Panel
@onready var countdown_label: Label = $Panel/VBox/CountdownLabel
@onready var message_label: Label = $Panel/VBox/MessageLabel
@onready var cancel_button: Button = $Panel/VBox/CancelButton

var is_showing: bool = false

func _ready() -> void:
	# Hide by default
	visible = false
	
	# Connect to LogoutManager signals
	if LogoutManager:
		LogoutManager.logout_started.connect(_on_logout_started)
		LogoutManager.logout_cancelled.connect(_on_logout_cancelled)
		LogoutManager.logout_completed.connect(_on_logout_completed)
		LogoutManager.disconnect_detected.connect(_on_disconnect_detected)
	
	# Connect cancel button
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	
	print("[LogoutPanel] Ready")

func _process(_delta: float) -> void:
	if not is_showing:
		return
	
	# Update countdown display
	if LogoutManager and LogoutManager.is_logging_out():
		var time_left = LogoutManager.get_logout_time_remaining()
		countdown_label.text = str(int(ceil(time_left)))
		
		# Change color as time runs out
		if time_left <= 5.0:
			countdown_label.modulate = Color.RED
		elif time_left <= 10.0:
			countdown_label.modulate = Color.YELLOW
		else:
			countdown_label.modulate = Color.WHITE

func _on_logout_started(countdown_time: float) -> void:
	"""Show logout countdown"""
	visible = true
	is_showing = true
	
	message_label.text = "Logging out in..."
	countdown_label.text = str(int(countdown_time))
	countdown_label.modulate = Color.WHITE
	
	if cancel_button:
		cancel_button.visible = true
		cancel_button.text = "Cancel Logout"
	
	print("[LogoutPanel] Showing logout countdown")

func _on_logout_cancelled() -> void:
	"""Hide panel when logout cancelled"""
	visible = false
	is_showing = false
	print("[LogoutPanel] Logout cancelled - hiding panel")

func _on_logout_completed() -> void:
	"""Logout completed"""
	visible = false
	is_showing = false
	print("[LogoutPanel] Logout completed")

func _on_disconnect_detected() -> void:
	"""Show disconnect message"""
	visible = true
	is_showing = false  # Don't update countdown
	
	message_label.text = "Connection Lost!"
	countdown_label.text = "Reconnecting..."
	countdown_label.modulate = Color.ORANGE
	
	if cancel_button:
		cancel_button.visible = false
	
	print("[LogoutPanel] Showing disconnect message")

func _on_cancel_pressed() -> void:
	"""Cancel logout"""
	if LogoutManager:
		LogoutManager.cancel_logout()
