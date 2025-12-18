extends Panel

# Friend Request Popup
# Shows incoming friend requests with accept/decline options

@onready var requester_label = $MarginContainer/VBoxContainer/RequesterLabel
@onready var timer_label = $MarginContainer/VBoxContainer/TimerLabel
@onready var accept_button = $MarginContainer/VBoxContainer/Buttons/AcceptButton
@onready var decline_button = $MarginContainer/VBoxContainer/Buttons/DeclineButton

var requester_id: int = -1
var requester_name: String = ""
var time_remaining: int = 30

func _ready():
	accept_button.pressed.connect(_on_accept_pressed)
	decline_button.pressed.connect(_on_decline_pressed)
	hide()

func show_request(req_id: int, req_name: String, expires_in: int):
	"""Show friend request popup"""
	requester_id = req_id
	requester_name = req_name
	time_remaining = expires_in
	
	requester_label.text = req_name + " wants to be friends!"
	timer_label.text = "Expires in: " + str(time_remaining) + "s"
	
	show()
	
	# Start countdown timer
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timer_tick.bind(timer))
	timer.start()
	
	print("[FriendRequest] Showing request from: ", req_name)

func _on_timer_tick(timer: Timer):
	time_remaining -= 1
	timer_label.text = "Expires in: " + str(time_remaining) + "s"
	
	if time_remaining <= 0:
		timer.stop()
		timer.queue_free()
		_on_expired()

func _on_accept_pressed():
	print("[FriendRequest] Accepting request from: ", requester_name)
	GlobalFriendManager.accept_friend_request(requester_id)
	_close()

func _on_decline_pressed():
	print("[FriendRequest] Declining request from: ", requester_name)
	GlobalFriendManager.decline_friend_request(requester_id)
	_close()

func _on_expired():
	print("[FriendRequest] Request expired from: ", requester_name)
	_close()

func _close():
	# Stop all timers
	for child in get_children():
		if child is Timer:
			child.stop()
			child.queue_free()
	hide()
