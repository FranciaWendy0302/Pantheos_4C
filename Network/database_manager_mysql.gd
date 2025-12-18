extends Node

## MySQL database manager via REST API
## Requires PHP backend running on server

@export var api_url: String = "http://localhost:8080/api"  # Your PHP API URL
@export var api_key: String = "your_secret_api_key_here"  # For security

var _player_sessions: Dictionary = {}  # peer_id -> player_data
var _http_requests: Dictionary = {}  # Track pending requests

signal login_completed(peer_id: int, success: bool, player_data: Dictionary)
signal account_created(success: bool, message: String)

func _ready() -> void:
	if not multiplayer.is_server():
		print("[DatabaseMySQL] Client mode - database disabled")
		return
	
	print("[DatabaseMySQL] Server mode - MySQL backend at: %s" % api_url)


# =========================
# HTTP Request Helper
# =========================

func _make_request(endpoint: String, data: Dictionary, callback: Callable) -> void:
	"""Make HTTP request to PHP API"""
	var http = HTTPRequest.new()
	add_child(http)
	
	var request_id = http.get_instance_id()
	_http_requests[request_id] = callback
	
	http.request_completed.connect(_on_request_completed.bind(request_id))
	
	var url = api_url + endpoint
	var headers = [
		"Content-Type: application/json",
		"X-API-Key: " + api_key
	]
	var json_data = JSON.stringify(data)
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		push_error("HTTP request failed: %s" % error)
		http.queue_free()


func _on_request_completed(result: int, response_code: int, headers: Array, body: PackedByteArray, request_id: int) -> void:
	"""Handle HTTP response"""
	var http = instance_from_id(request_id) as HTTPRequest
	
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("HTTP request failed with result: %s" % result)
		if _http_requests.has(request_id):
			_http_requests.erase(request_id)
		http.queue_free()
		return
	
	if response_code != 200:
		push_error("HTTP response code: %s" % response_code)
		if _http_requests.has(request_id):
			_http_requests.erase(request_id)
		http.queue_free()
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		push_error("Failed to parse JSON response")
		if _http_requests.has(request_id):
			_http_requests.erase(request_id)
		http.queue_free()
		return
	
	var response_data = json.data
	
	# Call the callback
	if _http_requests.has(request_id):
		var callback = _http_requests[request_id]
		callback.call(response_data)
		_http_requests.erase(request_id)
	
	http.queue_free()


# =========================
# Player Account Management
# =========================

func create_account(username: String, password: String, nickname: String) -> void:
	"""Create a new player account"""
	if not multiplayer.is_server():
		return
	
	var data = {
		"action": "create_account",
		"username": username,
		"password": password,
		"nickname": nickname
	}
	
	_make_request("/account.php", data, func(response):
		account_created.emit(response.get("success", false), response.get("message", ""))
		print("[MySQL] Account creation: %s" % response.get("message", ""))
	)


func login(username: String, password: String, peer_id: int) -> void:
	"""Login player"""
	if not multiplayer.is_server():
		return
	
	var data = {
		"action": "login",
		"username": username,
		"password": password
	}
	
	_make_request("/account.php", data, func(response):
		var success = response.get("success", false)
		var player_data = response.get("player_data", {})
		
		if success:
			_player_sessions[peer_id] = player_data
			print("[MySQL] Player logged in: %s (ID: %d, Peer: %d)" % [username, player_data.get("player_id", -1), peer_id])
		
		login_completed.emit(peer_id, success, player_data)
	)


func logout(peer_id: int) -> void:
	"""Logout player and save their data"""
	if not _player_sessions.has(peer_id):
		return
	
	save_player_data(peer_id)
	var username = _player_sessions[peer_id].get("username", "Unknown")
	_player_sessions.erase(peer_id)
	
	print("[MySQL] Player logged out: %s" % username)


# =========================
# Player Data Management
# =========================

func save_player_data(peer_id: int) -> void:
	"""Save player's current state to MySQL"""
	if not _player_sessions.has(peer_id):
		return
	
	var player_data = _player_sessions[peer_id]
	
	var data = {
		"action": "save_player",
		"player_id": player_data.get("player_id"),
		"level": player_data.get("level", 1),
		"xp": player_data.get("xp", 0),
		"gold": player_data.get("gold", 0),
		"hp": player_data.get("hp", 100),
		"max_hp": player_data.get("max_hp", 100),
		"last_map": player_data.get("last_map", ""),
		"last_position_x": player_data.get("last_position_x", 0.0),
		"last_position_y": player_data.get("last_position_y", 0.0),
		"inventory": JSON.stringify(player_data.get("inventory", [])),
		"quests": JSON.stringify(player_data.get("quests", []))
	}
	
	_make_request("/player.php", data, func(response):
		if response.get("success", false):
			print("[MySQL] Saved player data for ID: %d" % player_data.get("player_id"))
	)


func update_player_position(peer_id: int, map_path: String, position: Vector2) -> void:
	"""Update player's last known position"""
	if not _player_sessions.has(peer_id):
		return
	
	var player_data = _player_sessions[peer_id]
	player_data["last_map"] = map_path
	player_data["last_position_x"] = position.x
	player_data["last_position_y"] = position.y


func update_player_stats(peer_id: int, level: int = -1, xp: int = -1, gold: int = -1, hp: int = -1) -> void:
	"""Update player stats"""
	if not _player_sessions.has(peer_id):
		return
	
	var player_data = _player_sessions[peer_id]
	
	if level >= 0:
		player_data["level"] = level
	if xp >= 0:
		player_data["xp"] = xp
	if gold >= 0:
		player_data["gold"] = gold
	if hp >= 0:
		player_data["hp"] = hp


# =========================
# Inventory Management
# =========================

func add_item_to_player(peer_id: int, item_id: String, quantity: int) -> bool:
	"""Add item to player's inventory"""
	if not _player_sessions.has(peer_id):
		return false
	
	var player_data = _player_sessions[peer_id]
	var inventory = player_data.get("inventory", [])
	
	for item in inventory:
		if item["item_id"] == item_id:
			item["quantity"] += quantity
			return true
	
	inventory.append({"item_id": item_id, "quantity": quantity})
	player_data["inventory"] = inventory
	return true


func remove_item_from_player(peer_id: int, item_id: String, quantity: int) -> bool:
	"""Remove item from player's inventory"""
	if not _player_sessions.has(peer_id):
		return false
	
	var player_data = _player_sessions[peer_id]
	var inventory = player_data.get("inventory", [])
	
	for i in range(inventory.size()):
		if inventory[i]["item_id"] == item_id:
			if inventory[i]["quantity"] >= quantity:
				inventory[i]["quantity"] -= quantity
				if inventory[i]["quantity"] <= 0:
					inventory.remove_at(i)
				return true
			else:
				return false
	
	return false


# =========================
# Trading System
# =========================

func execute_trade(from_peer_id: int, to_peer_id: int, item_id: String, quantity: int, gold_amount: int) -> void:
	"""Execute a trade between two players"""
	if not multiplayer.is_server():
		return
	
	if not _player_sessions.has(from_peer_id) or not _player_sessions.has(to_peer_id):
		return
	
	var from_player = _player_sessions[from_peer_id]
	var to_player = _player_sessions[to_peer_id]
	
	# Validate locally first
	if not remove_item_from_player(from_peer_id, item_id, quantity):
		print("[MySQL] Trade failed: Sender doesn't have items")
		return
	
	if gold_amount > 0 and to_player.get("gold", 0) < gold_amount:
		add_item_to_player(from_peer_id, item_id, quantity)  # Rollback
		print("[MySQL] Trade failed: Receiver doesn't have gold")
		return
	
	# Execute trade
	if gold_amount > 0:
		to_player["gold"] -= gold_amount
		from_player["gold"] += gold_amount
	
	add_item_to_player(to_peer_id, item_id, quantity)
	
	# Log to MySQL
	var data = {
		"action": "log_trade",
		"from_player_id": from_player.get("player_id"),
		"to_player_id": to_player.get("player_id"),
		"item_id": item_id,
		"quantity": quantity,
		"gold_amount": gold_amount
	}
	
	_make_request("/trade.php", data, func(response):
		if response.get("success", false):
			print("[MySQL] Trade logged successfully")
	)
	
	# Save both players
	save_player_data(from_peer_id)
	save_player_data(to_peer_id)


# =========================
# Quest Management
# =========================

func update_player_quest(peer_id: int, quest_id: String, is_complete: bool, completed_steps: Array) -> void:
	"""Update player's quest progress"""
	if not _player_sessions.has(peer_id):
		return
	
	var player_data = _player_sessions[peer_id]
	var quests = player_data.get("quests", [])
	
	var found = false
	for quest in quests:
		if quest["quest_id"] == quest_id:
			quest["is_complete"] = is_complete
			quest["completed_steps"] = completed_steps
			found = true
			break
	
	if not found:
		quests.append({
			"quest_id": quest_id,
			"is_complete": is_complete,
			"completed_steps": completed_steps
		})
	
	player_data["quests"] = quests


# =========================
# Utility
# =========================

func get_player_data(peer_id: int) -> Dictionary:
	"""Get player data for a connected peer"""
	return _player_sessions.get(peer_id, {})


func is_player_logged_in(peer_id: int) -> bool:
	"""Check if player is logged in"""
	return _player_sessions.has(peer_id)


func _exit_tree() -> void:
	"""Save all player data on shutdown"""
	if multiplayer.is_server():
		for peer_id in _player_sessions.keys():
			save_player_data(peer_id)
		
		print("[MySQL] Saved all player data")
