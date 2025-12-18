extends Node

## Logout Manager - Handles safe logout and disconnect protection
## 
## Features:
## - 30 second logout countdown for intentional logout
## - 60 second ghost mode for accidental disconnects
## - Reconnect protection
## - Combat logout prevention

signal logout_started(countdown_time: float)
signal logout_cancelled
signal logout_completed
signal disconnect_detected

enum LogoutState {
	NONE,           # Normal gameplay
	LOGGING_OUT,    # Intentional logout countdown
	DISCONNECTED,   # Accidental disconnect - ghost mode
	LOGGED_OUT      # Fully logged out
}

const LOGOUT_COUNTDOWN_TIME = 30.0  # 30 seconds to logout
const DISCONNECT_GRACE_PERIOD = 60.0  # 60 seconds to reconnect

var current_state: LogoutState = LogoutState.NONE
var logout_timer: Timer
var disconnect_timer: Timer
var is_in_combat: bool = false
var last_player_position: Vector2 = Vector2.ZERO
var is_quit_to_title_mode: bool = false  # If true, keeps account logged in
var movement_check_enabled: bool = false

func _ready() -> void:
	# Setup logout countdown timer
	logout_timer = Timer.new()
	logout_timer.one_shot = true
	logout_timer.timeout.connect(_on_logout_timer_timeout)
	add_child(logout_timer)
	
	# Setup disconnect grace period timer
	disconnect_timer = Timer.new()
	disconnect_timer.one_shot = true
	disconnect_timer.timeout.connect(_on_disconnect_timer_timeout)
	add_child(disconnect_timer)
	
	print("[LogoutManager] Initialized - Logout: 30s, Reconnect: 60s")

func _process(_delta: float) -> void:
	# Check for player movement during logout
	if movement_check_enabled and current_state == LogoutState.LOGGING_OUT:
		_check_player_movement()

## ============================================
## INTENTIONAL LOGOUT (30 second countdown)
## ============================================

func start_logout(quit_to_title: bool = false) -> bool:
	"""Start intentional logout countdown
	
	Args:
		quit_to_title: If true, returns to character selection keeping account logged in.
					  If false, full logout to login screen.
	"""
	
	# Check if already logging out
	if current_state == LogoutState.LOGGING_OUT:
		print("[LogoutManager] Already logging out")
		return false
	
	# Check if in combat
	if is_in_combat:
		print("[LogoutManager] Cannot logout while in combat!")
		push_error("Cannot logout while in combat!")
		return false
	
	# Set mode
	is_quit_to_title_mode = quit_to_title
	
	# Start logout countdown
	current_state = LogoutState.LOGGING_OUT
	logout_timer.start(LOGOUT_COUNTDOWN_TIME)
	logout_started.emit(LOGOUT_COUNTDOWN_TIME)
	
	if quit_to_title:
		print("[LogoutManager] Quit to Title started - 30 second countdown")
		print("[LogoutManager] Returning to character selection (staying logged in)")
	else:
		print("[LogoutManager] Logout started - 30 second countdown")
		print("[LogoutManager] Player can cancel or will auto-logout")
	print("[LogoutManager] Movement will cancel logout")
	
	# Store current position for movement detection
	var player = PlayerManager.player
	if player and is_instance_valid(player):
		last_player_position = player.global_position
		movement_check_enabled = true
	
	# Make player invulnerable during logout
	_set_player_logout_state(true)
	
	return true

func cancel_logout() -> void:
	"""Cancel logout countdown"""
	
	if current_state != LogoutState.LOGGING_OUT:
		return
	
	logout_timer.stop()
	current_state = LogoutState.NONE
	movement_check_enabled = false
	logout_cancelled.emit()
	
	print("[LogoutManager] Logout cancelled")
	
	# Remove invulnerability
	_set_player_logout_state(false)

func get_logout_time_remaining() -> float:
	"""Get remaining time on logout countdown"""
	if current_state == LogoutState.LOGGING_OUT:
		return logout_timer.time_left
	return 0.0

func _on_logout_timer_timeout() -> void:
	"""Logout countdown completed"""
	print("[LogoutManager] Logout countdown complete - saving and exiting")
	
	# Save game
	SaveManager.save_game()
	await get_tree().create_timer(0.5).timeout  # Wait for save
	
	# Complete logout
	current_state = LogoutState.LOGGED_OUT
	logout_completed.emit()
	
	# Stop auto-save
	SaveManager.stop_auto_save()
	
	var title_scene_script = load("res://title_scene/title_scene.gd")
	
	if is_quit_to_title_mode:
		# Quit to Title mode - keep account logged in
		print("[LogoutManager] Returning to character selection (staying logged in)")
		
		# Clear only character data, keep account data
		PlayerManager.selected_class = ""
		# Keep PlayerManager.player_id and PlayerManager.nickname
		
		# Set session active so "Press Enter" screen shows
		if title_scene_script:
			title_scene_script.is_session_active = true
		
		# Reset flag
		is_quit_to_title_mode = false
	else:
		# Full logout mode - clear everything
		print("[LogoutManager] Full logout - returning to login screen")
		
		# Clear session state so title screen shows login
		if title_scene_script:
			title_scene_script.is_session_active = false
	
	# Return to title screen
	get_tree().change_scene_to_file("res://title_scene/title_scene.tscn")

## ============================================
## ACCIDENTAL DISCONNECT (60 second ghost mode)
## ============================================

func handle_disconnect() -> void:
	"""Handle accidental disconnect - start ghost mode"""
	
	# If already disconnected, ignore
	if current_state == LogoutState.DISCONNECTED:
		return
	
	# Cancel any logout in progress
	if current_state == LogoutState.LOGGING_OUT:
		logout_timer.stop()
	
	current_state = LogoutState.DISCONNECTED
	disconnect_timer.start(DISCONNECT_GRACE_PERIOD)
	disconnect_detected.emit()
	
	print("[LogoutManager] ========================================")
	print("[LogoutManager] DISCONNECT DETECTED!")
	print("[LogoutManager] Character will remain in-game for 60 seconds")
	print("[LogoutManager] Reconnect within 60 seconds to resume")
	print("[LogoutManager] ========================================")
	
	# Save current state immediately
	SaveManager.save_game()
	
	# Make player invulnerable and invisible (ghost mode)
	_set_player_ghost_mode(true)

func attempt_reconnect() -> bool:
	"""Attempt to reconnect within grace period"""
	
	if current_state != LogoutState.DISCONNECTED:
		print("[LogoutManager] No reconnect needed - not disconnected")
		return false
	
	if disconnect_timer.is_stopped():
		print("[LogoutManager] Reconnect window expired")
		return false
	
	# Successful reconnect!
	disconnect_timer.stop()
	current_state = LogoutState.NONE
	
	print("[LogoutManager] ========================================")
	print("[LogoutManager] RECONNECT SUCCESSFUL!")
	print("[LogoutManager] Resuming from last position")
	print("[LogoutManager] ========================================")
	
	# Restore player to normal state
	_set_player_ghost_mode(false)
	
	return true

func get_reconnect_time_remaining() -> float:
	"""Get remaining time to reconnect"""
	if current_state == LogoutState.DISCONNECTED:
		return disconnect_timer.time_left
	return 0.0

func _on_disconnect_timer_timeout() -> void:
	"""Disconnect grace period expired"""
	print("[LogoutManager] Reconnect window expired - forcing logout")
	
	# Save final state
	SaveManager.save_game()
	await get_tree().create_timer(0.5).timeout
	
	# Force logout
	current_state = LogoutState.LOGGED_OUT
	logout_completed.emit()
	
	# Clear session state so title screen shows "Press Enter"
	var title_scene_script = load("res://title_scene/title_scene.gd")
	if title_scene_script:
		title_scene_script.is_session_active = false
	
	# Return to title screen
	get_tree().change_scene_to_file("res://title_scene/title_scene.tscn")

## ============================================
## COMBAT STATE MANAGEMENT
## ============================================

func set_combat_state(in_combat: bool) -> void:
	"""Update combat state - prevents logout during combat"""
	is_in_combat = in_combat
	
	if in_combat:
		print("[LogoutManager] Entered combat - logout disabled")
		# If trying to logout during combat, cancel it
		if current_state == LogoutState.LOGGING_OUT:
			cancel_logout()
			push_error("Logout cancelled - entered combat!")
	else:
		print("[LogoutManager] Left combat - logout enabled")

## ============================================
## MOVEMENT DETECTION
## ============================================

func _check_player_movement() -> void:
	"""Check if player has moved and cancel logout if so"""
	var player = PlayerManager.player
	if not player or not is_instance_valid(player):
		return
	
	var current_position = player.global_position
	var distance_moved = last_player_position.distance_to(current_position)
	
	# If player moved more than 1 pixel, cancel logout
	if distance_moved > 1.0:
		print("[LogoutManager] Player moved - cancelling logout!")
		cancel_logout()

## ============================================
## PLAYER STATE HELPERS
## ============================================

func _set_player_logout_state(logging_out: bool) -> void:
	"""Set player state during logout countdown"""
	var player = PlayerManager.player
	if not player or not is_instance_valid(player):
		return
	
	if logging_out:
		# Make player invulnerable during logout
		if "is_invulnerable" in player:
			player.is_invulnerable = true
		# Optionally: Disable movement, show logout animation
		print("[LogoutManager] Player is now invulnerable (logging out)")
	else:
		# Restore normal state
		if "is_invulnerable" in player:
			player.is_invulnerable = false
		print("[LogoutManager] Player vulnerability restored")

func _set_player_ghost_mode(ghost: bool) -> void:
	"""Set player to ghost mode during disconnect"""
	var player = PlayerManager.player
	if not player or not is_instance_valid(player):
		return
	
	if ghost:
		# Make player invulnerable and invisible
		if "is_invulnerable" in player:
			player.is_invulnerable = true
		if "visible" in player:
			player.modulate = Color(1, 1, 1, 0.3)  # Semi-transparent
		print("[LogoutManager] Player in ghost mode (disconnected)")
	else:
		# Restore normal state
		if "is_invulnerable" in player:
			player.is_invulnerable = false
		if "visible" in player:
			player.modulate = Color(1, 1, 1, 1)  # Fully visible
		print("[LogoutManager] Player restored from ghost mode")

## ============================================
## UTILITY FUNCTIONS
## ============================================

func is_logging_out() -> bool:
	"""Check if player is currently logging out"""
	return current_state == LogoutState.LOGGING_OUT

func is_disconnected() -> bool:
	"""Check if player is disconnected"""
	return current_state == LogoutState.DISCONNECTED

func can_logout() -> bool:
	"""Check if player can logout"""
	return not is_in_combat and current_state == LogoutState.NONE

func get_state_string() -> String:
	"""Get current state as string for debugging"""
	match current_state:
		LogoutState.NONE:
			return "Normal"
		LogoutState.LOGGING_OUT:
			return "Logging Out (" + str(int(get_logout_time_remaining())) + "s)"
		LogoutState.DISCONNECTED:
			return "Disconnected (" + str(int(get_reconnect_time_remaining())) + "s)"
		LogoutState.LOGGED_OUT:
			return "Logged Out"
	return "Unknown"
