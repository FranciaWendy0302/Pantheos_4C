extends Node

# Global Friend Manager
# Handles friend list, friend requests, and friend-related UI

signal friend_list_updated(friends: Array)
signal friend_request_received(requester_id: int, requester_name: String, expires_in: int)
signal friend_request_expired(requester_id: int)
signal friend_accepted(friend_id: int, friend_name: String)
signal friend_removed(friend_id: int)
signal friend_online(friend_id: int, friend_name: String)
signal friend_offline(friend_id: int)

var friends: Array = []  # Array of friend dictionaries
var pending_requests: Array = []  # Array of pending friend request dictionaries

# API Configuration
var api_url: String = "http://100.92.219.104:3000/api/friends"
var api_key: String = "pantheos_dev_key_12345"  # Must match server/.env

func _ready():
	# Wait a frame for other autoloads to be ready
	await get_tree().process_frame
	
	print("[FriendManager] ========== INITIALIZING ==========")
	
	# Connect to network manager signals
	if has_node("/root/GlobalNetworkManager"):
		print("[FriendManager] Found GlobalNetworkManager")
		var net_mgr = get_node("/root/GlobalNetworkManager")
		if net_mgr.has_signal("connected_to_server"):
			net_mgr.connected_to_server.connect(_on_connected_to_server)
			print("[FriendManager] ✓ Connected to connected_to_server signal")
		if net_mgr.has_signal("friend_request"):
			net_mgr.friend_request.connect(_on_friend_request_received)
			print("[FriendManager] ✓ Connected to friend_request signal")
		else:
			print("[FriendManager] ✗ friend_request signal NOT FOUND!")
		if net_mgr.has_signal("friend_accepted"):
			net_mgr.friend_accepted.connect(_on_friend_accepted)
		if net_mgr.has_signal("friend_removed"):
			net_mgr.friend_removed.connect(_on_friend_removed)
		if net_mgr.has_signal("friend_online"):
			net_mgr.friend_online.connect(_on_friend_online)
		if net_mgr.has_signal("friend_offline"):
			net_mgr.friend_offline.connect(_on_friend_offline)
		if net_mgr.has_signal("friend_request_expired"):
			net_mgr.friend_request_expired.connect(_on_friend_request_expired)
	else:
		print("[FriendManager] ✗ GlobalNetworkManager NOT FOUND!")
	
	# Also try to load immediately after a delay (fallback)
	_try_load_friends_delayed()

func _try_load_friends_delayed():
	"""Try to load friends after a delay (fallback if signal doesn't fire)"""
	print("[FriendManager] Starting delayed friend list load...")
	# Wait for PlayerManager to be ready with player_id
	for i in range(50):  # Try for 5 seconds (50 * 0.1s)
		await get_tree().create_timer(0.1).timeout
		if has_node("/root/PlayerManager"):
			var player_mgr = get_node("/root/PlayerManager")
			if player_mgr.player_id and player_mgr.player_id > 0:
				print("[FriendManager] Player ID ready (", player_mgr.player_id, "), loading friend list...")
				load_friend_list()
				load_pending_requests()
				return
		if i % 10 == 0:
			print("[FriendManager] Still waiting for player_id... (", i/10, "s)")
	print("[FriendManager] Timeout waiting for player_id")

func _on_connected_to_server():
	# Load friend list and pending requests when connected
	print("[FriendManager] Connected to server, loading friend list in 1 second...")
	await get_tree().create_timer(1.0).timeout  # Wait for player data to load
	print("[FriendManager] Loading friend list now...")
	load_friend_list()
	load_pending_requests()

# Load friend list from server
func load_friend_list():
	if not has_node("/root/PlayerManager"):
		return
	var player_mgr = get_node("/root/PlayerManager")
	if not player_mgr.player_id or player_mgr.player_id == 0:
		return
	
	var url = api_url + "/list/" + str(player_mgr.player_id)
	var headers = ["Content-Type: application/json", "x-api-key: " + api_key]
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, response_code, headers_resp, body):
		_on_friend_list_loaded(result, response_code, headers_resp, body, http)
	)
	http.request(url, headers, HTTPClient.METHOD_GET)

func _on_friend_list_loaded(_result, response_code, _headers, body, http):
	http.queue_free()
	
	if response_code != 200:
		print("[FriendManager] Failed to load friend list: ", response_code)
		return
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("[FriendManager] Failed to parse friend list response")
		return
	
	var response = json.data
	if response.success:
		friends = response.friends
		friend_list_updated.emit(friends)
		print("[FriendManager] Loaded ", friends.size(), " friends")

# Load pending friend requests
func load_pending_requests():
	if not has_node("/root/PlayerManager"):
		return
	var player_mgr = get_node("/root/PlayerManager")
	if not player_mgr.player_id or player_mgr.player_id == 0:
		return
	
	var url = api_url + "/pending/" + str(player_mgr.player_id)
	var headers = ["Content-Type: application/json", "x-api-key: " + api_key]
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, response_code, headers_resp, body):
		_on_pending_requests_loaded(result, response_code, headers_resp, body, http)
	)
	http.request(url, headers, HTTPClient.METHOD_GET)

func _on_pending_requests_loaded(_result, response_code, _headers, body, http):
	http.queue_free()
	
	if response_code != 200:
		print("[FriendManager] Failed to load pending requests: ", response_code)
		return
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("[FriendManager] Failed to parse pending requests response")
		return
	
	var response = json.data
	if response.success:
		pending_requests = response.requests
		print("[FriendManager] Loaded ", pending_requests.size(), " pending requests")
		# Emit signal to update UI
		for request in pending_requests:
			friend_request_received.emit(request.id, request.nickname, 0)  # 0 = no expiration

# Send friend request
func send_friend_request(target_id: int):
	if not has_node("/root/PlayerManager"):
		return
	var player_mgr = get_node("/root/PlayerManager")
	if not player_mgr.player_id or player_mgr.player_id == 0:
		return
	
	var url = api_url + "/request"
	var headers = ["Content-Type: application/json", "x-api-key: " + api_key]
	var data = {
		"requesterId": player_mgr.player_id,
		"targetId": target_id
	}
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, response_code, headers_resp, body):
		_on_friend_request_sent(result, response_code, headers_resp, body, http)
	)
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(data))

func _on_friend_request_sent(_result, response_code, _headers, body, http):
	http.queue_free()
	
	if response_code != 200:
		print("[FriendManager] Failed to send friend request: ", response_code)
		return
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("[FriendManager] Failed to parse friend request response")
		return
	
	var response = json.data
	if response.success:
		print("[FriendManager] Friend request sent successfully")
	else:
		print("[FriendManager] Friend request failed: ", response.error)

# Accept friend request
func accept_friend_request(requester_id: int):
	if not has_node("/root/PlayerManager"):
		return
	var player_mgr = get_node("/root/PlayerManager")
	if not player_mgr.player_id or player_mgr.player_id == 0:
		return
	
	var url = api_url + "/accept"
	var headers = ["Content-Type: application/json", "x-api-key: " + api_key]
	var data = {
		"playerId": player_mgr.player_id,
		"requesterId": requester_id
	}
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, response_code, headers_resp, body):
		_on_friend_request_accepted(result, response_code, headers_resp, body, http)
	)
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(data))

func _on_friend_request_accepted(_result, response_code, _headers, body, http):
	http.queue_free()
	
	if response_code != 200:
		print("[FriendManager] Failed to accept friend request: ", response_code)
		return
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("[FriendManager] Failed to parse accept response")
		return
	
	var response = json.data
	if response.success:
		print("[FriendManager] Friend request accepted")
		load_friend_list()  # Reload friend list

# Decline friend request
func decline_friend_request(requester_id: int):
	if not has_node("/root/PlayerManager"):
		return
	var player_mgr = get_node("/root/PlayerManager")
	if not player_mgr.player_id or player_mgr.player_id == 0:
		return
	
	var url = api_url + "/decline"
	var headers = ["Content-Type: application/json", "x-api-key: " + api_key]
	var data = {
		"playerId": player_mgr.player_id,
		"requesterId": requester_id
	}
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, response_code, headers_resp, body):
		_on_friend_request_declined(result, response_code, headers_resp, body, http)
	)
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(data))

func _on_friend_request_declined(_result, _response_code, _headers, _body, http):
	http.queue_free()
	print("[FriendManager] Friend request declined")

# Remove friend
func remove_friend(friend_id: int):
	if not has_node("/root/PlayerManager"):
		return
	var player_mgr = get_node("/root/PlayerManager")
	if not player_mgr.player_id or player_mgr.player_id == 0:
		return
	
	var url = api_url + "/remove"
	var headers = ["Content-Type: application/json", "x-api-key: " + api_key]
	var data = {
		"playerId": player_mgr.player_id,
		"friendId": friend_id
	}
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, response_code, headers_resp, body):
		_on_friend_removed_response(result, response_code, headers_resp, body, http)
	)
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(data))

func _on_friend_removed_response(_result, response_code, _headers, _body, http):
	http.queue_free()
	
	if response_code != 200:
		print("[FriendManager] Failed to remove friend: ", response_code)
		return
	
	print("[FriendManager] Friend removed")
	load_friend_list()  # Reload friend list

# Get player info for inspection
func inspect_player(player_id: int, callback: Callable):
	var url = api_url + "/inspect/" + str(player_id)
	var headers = ["Content-Type: application/json", "x-api-key: " + api_key]
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, response_code, headers_resp, body):
		http.queue_free()
		
		if response_code != 200:
			print("[FriendManager] Failed to inspect player: ", response_code)
			callback.call(null)
			return
		
		var json = JSON.new()
		var error = json.parse(body.get_string_from_utf8())
		if error != OK:
			print("[FriendManager] Failed to parse inspect response")
			callback.call(null)
			return
		
		var response = json.data
		if response.success:
			callback.call(response.player)
		else:
			callback.call(null)
	)
	http.request(url, headers, HTTPClient.METHOD_GET)

# WebSocket event handlers
func _on_friend_request_received(data: Dictionary):
	print("[FriendManager] ========== FRIEND REQUEST HANDLER ==========")
	print("[FriendManager] Data received: ", data)
	var req_id = int(data.get("requesterId", -1))
	var req_name = str(data.get("requesterName", "Unknown"))
	print("[FriendManager] Emitting signal with ID:", req_id, " Name:", req_name)
	friend_request_received.emit(req_id, req_name, 0)  # 0 = no expiration
	print("[FriendManager] Signal emitted!")

func _on_friend_accepted(data: Dictionary):
	print("[FriendManager] Friend accepted: ", data.friendName)
	friend_accepted.emit(data.friendId, data.friendName)
	load_friend_list()  # Reload friend list

func _on_friend_removed(data: Dictionary):
	print("[FriendManager] Friend removed: ", data.friendId)
	friend_removed.emit(data.friendId)
	load_friend_list()  # Reload friend list

func _on_friend_online(data: Dictionary):
	print("[FriendManager] Friend online: ", data.friendName)
	friend_online.emit(data.friendId, data.friendName)
	# Update friend status in list
	for friend in friends:
		if friend.id == data.friendId:
			friend.online = true
			break
	friend_list_updated.emit(friends)

func _on_friend_offline(data: Dictionary):
	print("[FriendManager] Friend offline: ", data.friendId)
	friend_offline.emit(data.friendId)
	# Update friend status in list
	for friend in friends:
		if friend.id == data.friendId:
			friend.online = false
			break
	friend_list_updated.emit(friends)

func _on_friend_request_expired(data: Dictionary):
	print("[FriendManager] Friend request expired from: ", data.requesterId)
	friend_request_expired.emit(data.requesterId)

# Helper functions
func is_friend(player_id: int) -> bool:
	for friend in friends:
		if friend.id == player_id:
			return true
	return false

func get_friend_by_id(friend_id: int) -> Dictionary:
	for friend in friends:
		if friend.id == friend_id:
			return friend
	return {}
