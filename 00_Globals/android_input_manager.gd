extends Node

# Android-specific input management
# Handles touch controls, gestures, and mobile-specific input

signal touch_started(position: Vector2)
signal touch_ended(position: Vector2)
signal touch_moved(position: Vector2, relative: Vector2)
signal gesture_detected(gesture_type: String, data: Dictionary)

var touch_points: Dictionary = {}
var gesture_threshold: float = 50.0
var swipe_threshold: float = 100.0
var pinch_threshold: float = 20.0

var is_swiping: bool = false
var is_pinching: bool = false
var swipe_start_pos: Vector2
var initial_pinch_distance: float = 0.0

func _ready():
	if not PlatformManager.is_platform_android():
		print("Android Input Manager: Not on Android platform, disabling...")
		set_process_input(false)
		return
	
	print("Android Input Manager: Initialized for Android platform")
	setup_android_input()

func setup_android_input():
	# Configure input settings for Android
	Input.set_use_accumulated_input(false)  # Better for touch
	
	# Enable touch screen if available
	if DisplayServer.is_touchscreen_available():
		print("Touch screen detected and enabled")

func _input(event):
	if not PlatformManager.is_platform_android():
		return
	
	handle_touch_input(event)

func handle_touch_input(event):
	if event is InputEventScreenTouch:
		handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		handle_screen_drag(event)

func handle_screen_touch(event: InputEventScreenTouch):
	var touch_id = event.index
	var position = event.position
	
	if event.pressed:
		# Touch started
		touch_points[touch_id] = {
			"start_pos": position,
			"current_pos": position,
			"start_time": Time.get_time_dict_from_system()
		}
		
		touch_started.emit(position)
		
		# Check for multi-touch gestures
		if touch_points.size() == 2:
			start_pinch_gesture()
	else:
		# Touch ended
		if touch_id in touch_points:
			var touch_data = touch_points[touch_id]
			var swipe_distance = position.distance_to(touch_data.start_pos)
			
			# Detect swipe gesture
			if swipe_distance > swipe_threshold:
				detect_swipe_gesture(touch_data.start_pos, position)
			
			touch_points.erase(touch_id)
			touch_ended.emit(position)
		
		# End gestures when no touches remain
		if touch_points.size() == 0:
			end_all_gestures()

func handle_screen_drag(event: InputEventScreenDrag):
	var touch_id = event.index
	var position = event.position
	var relative = event.relative
	
	if touch_id in touch_points:
		touch_points[touch_id].current_pos = position
		touch_moved.emit(position, relative)
		
		# Handle pinch gesture
		if touch_points.size() == 2 and is_pinching:
			update_pinch_gesture()

func start_pinch_gesture():
	if touch_points.size() != 2:
		return
	
	var positions = []
	for touch_data in touch_points.values():
		positions.append(touch_data.current_pos)
	
	initial_pinch_distance = positions[0].distance_to(positions[1])
	is_pinching = true
	
	gesture_detected.emit("pinch_start", {
		"distance": initial_pinch_distance,
		"center": (positions[0] + positions[1]) / 2
	})

func update_pinch_gesture():
	if touch_points.size() != 2 or not is_pinching:
		return
	
	var positions = []
	for touch_data in touch_points.values():
		positions.append(touch_data.current_pos)
	
	var current_distance = positions[0].distance_to(positions[1])
	var scale_factor = current_distance / initial_pinch_distance
	var center = (positions[0] + positions[1]) / 2
	
	gesture_detected.emit("pinch_update", {
		"scale": scale_factor,
		"distance": current_distance,
		"center": center
	})

func detect_swipe_gesture(start_pos: Vector2, end_pos: Vector2):
	var swipe_vector = end_pos - start_pos
	var swipe_distance = swipe_vector.length()
	
	if swipe_distance < swipe_threshold:
		return
	
	var swipe_direction = swipe_vector.normalized()
	var direction_name = get_swipe_direction_name(swipe_direction)
	
	gesture_detected.emit("swipe", {
		"direction": direction_name,
		"vector": swipe_vector,
		"distance": swipe_distance,
		"start_pos": start_pos,
		"end_pos": end_pos
	})

func get_swipe_direction_name(direction: Vector2) -> String:
	var angle = direction.angle()
	var degrees = rad_to_deg(angle)
	
	# Normalize to 0-360
	if degrees < 0:
		degrees += 360
	
	# Determine direction based on angle
	if degrees >= 315 or degrees < 45:
		return "right"
	elif degrees >= 45 and degrees < 135:
		return "down"
	elif degrees >= 135 and degrees < 225:
		return "left"
	else:
		return "up"

func end_all_gestures():
	if is_pinching:
		is_pinching = false
		gesture_detected.emit("pinch_end", {})
	
	if is_swiping:
		is_swiping = false

# Utility functions for game integration
func is_touch_available() -> bool:
	return DisplayServer.is_touchscreen_available()

func get_touch_count() -> int:
	return touch_points.size()

func get_primary_touch_position() -> Vector2:
	if touch_points.size() > 0:
		return touch_points.values()[0].current_pos
	return Vector2.ZERO

func vibrate_device(duration_ms: int = 100):
	if PlatformManager.is_platform_android():
		Input.start_joy_vibration(0, 0.5, 0.5, duration_ms / 1000.0)

# Virtual joystick support
func create_virtual_joystick(position: Vector2, radius: float = 100.0) -> Control:
	var joystick = Control.new()
	joystick.position = position
	joystick.size = Vector2(radius * 2, radius * 2)
	
	# Add visual representation
	var background = ColorRect.new()
	background.color = Color(0.2, 0.2, 0.2, 0.5)
	background.size = joystick.size
	joystick.add_child(background)
	
	var knob = ColorRect.new()
	knob.color = Color(0.8, 0.8, 0.8, 0.8)
	knob.size = Vector2(radius * 0.6, radius * 0.6)
	knob.position = Vector2(radius * 0.2, radius * 0.2)
	joystick.add_child(knob)
	
	return joystick