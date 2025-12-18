extends Node

## JSON-based database manager (works without SQLite addon)
## For production, use database_manager.gd with SQLite

const SAVE_DIR = "user://server_data/"
const PLAYERS_FILE = "players.json"
const TRADES_FILE = "trades.json"

var _player_sessions: Dictionary = {}  # peer_id -> player_data
var _all_players: Dictionary = {}  # username -> player_data
var _trades_log: Array = []

func _ready() -> void:
	if not multiplayer.is_server():
		print("[DatabaseJSON] Client mode - database disabled")
		return
	
	_initialize_storage()
	_load_all_data()
	print("[DatabaseJSON] Server storage initialized")


func _initialize_storage() -> void:
	"""Create save directory if it doesn't exist"""
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("server_data"):
		dir.make_dir("server_data")


func _load_all_data() -> void:
	"""Load all player data from JSON files"""
	var players_path = SAVE_DIR + PLAYERS_FILE
	
	if FileAccess.file_exists(players_path):
		var file = FileAccess.open(players_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			_all_players = json.data
			print("[DatabaseJSON] Loaded %d player accounts" % _all_players.size())
	
	# Load trades log
	var trades_path = SAVE_DIR + TRADES_FILE
	if FileAccess.file_exists(trades_path):
		var file = FileAccess.open(trades_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			_trades_log = json.data


func _save_all_data() -> void:
	"""Save all player data to JSON files"""
	# Save players
	var players_path = SAVE_DIR + PLAYERS_FILE
	var file = FileAccess.open(players_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_all_players, "\t"))
	file.close()
	
	# Save trades
	var trades_path = SAVE_DIR + TRADES_FILE
	file = FileAccess.open(trades_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_trades_log, "\t"))
	file.close()


# =========================
# Player Account Management
# =========================

func create_account(username: String, password: String, nickname: String) -> Dictionary:
	"""Create a new player account"""
	if not multiplayer.is_server():
		return {"success": false, "error": "Not server"}
	
	if _all_players.has(username):
		return {"success": false, "error": "Username already exists"}
	
	var password_hash = password.sha256_text()
	var player_id = _all_players.size() + 1
	
	var player_data = {
		"player_id": player_id,
		"username": username,
		"password_hash": password_hash,
		"nickname": nickname,
		"level": 1,
		"xp": 0,
		"gold": 100,  # Starting gold
		"hp": 100,
		"max_hp": 100,
		"last_map": "",
		"last_position": {"x": 0, "y": 0},
		"inventory": [],
		"quests": [],
		"created_at": Time.get_datetime_string_from_system(),
		"last_login": Time.get_datetime_string_from_system()
	}
	
	_all_players[username] = player_data
	_save_all_data()
	
	print("[DatabaseJSON] Created account: %s (ID: %d)" % [username, player_id])
	return {"success": true, "player_id": player_id}


func login(username: String, password: String, peer_id: int) -> Dictionary:
	"""Login player"""
	if not multiplayer.is_server():
		return {"success": false, "error": "Not server"}
	
	if not _all_players.has(username):
		return {"success": false, "error": "Invalid username or password"}
	
	var player_data = _all_players[username]
	var password_hash = password.sha256_text()
	
	if player_data["password_hash"] != password_hash:
		return {"success": false, "error": "Invalid username or password"}
	
	# Update last login
	player_data["last_login"] = Time.get_datetime_string_from_system()
	
	# Store session
	_player_sessions[peer_id] = player_data
	
	print("[DatabaseJSON] Player logged in: %s (ID: %d, Peer: %d)" % [username, player_data["player_id"], peer_id])
	
	return {"success": true, "player_data": player_data}


func logout(peer_id: int) -> void:
	"""Logout player and save their data"""
	if not _player_sessions.has(peer_id):
		return
	
	save_player_data(peer_id)
	var username = _player_sessions[peer_id].get("username", "Unknown")
	_player_sessions.erase(peer_id)
	
	print("[DatabaseJSON] Player logged out: %s" % username)


# =========================
# Player Data Management
# =========================

func save_player_data(peer_id: int) -> void:
	"""Save player's current state"""
	if not _player_sessions.has(peer_id):
		return
	
	var player_data = _player_sessions[peer_id]
	var username = player_data["username"]
	
	# Update in main storage
	_all_players[username] = player_data
	_save_all_data()


func update_player_position(peer_id: int, map_path: String, position: Vector2) -> void:
	"""Update player's last known position"""
	if not _player_sessions.has(peer_id):
		return
	
	var player_data = _player_sessions[peer_id]
	player_data["last_map"] = map_path
	player_data["last_position"] = {"x": position.x, "y": position.y}


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
	
	# Check if item already exists
	for item in inventory:
		if item["item_id"] == item_id:
			item["quantity"] += quantity
			return true
	
	# Add new item
	inventory.append({
		"item_id": item_id,
		"quantity": quantity
	})
	
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


func get_player_inventory(peer_id: int) -> Array:
	"""Get player's inventory"""
	if not _player_sessions.has(peer_id):
		return []
	
	return _player_sessions[peer_id].get("inventory", [])


# =========================
# Trading System
# =========================

func execute_trade(from_peer_id: int, to_peer_id: int, item_id: String, quantity: int, gold_amount: int) -> Dictionary:
	"""Execute a trade between two players"""
	if not multiplayer.is_server():
		return {"success": false, "error": "Not server"}
	
	if not _player_sessions.has(from_peer_id) or not _player_sessions.has(to_peer_id):
		return {"success": false, "error": "One or both players not logged in"}
	
	var from_player = _player_sessions[from_peer_id]
	var to_player = _player_sessions[to_peer_id]
	
	# Validate sender has the item
	if not remove_item_from_player(from_peer_id, item_id, quantity):
		return {"success": false, "error": "Sender doesn't have enough items"}
	
	# Validate receiver has enough gold (if trading for gold)
	if gold_amount > 0:
		if to_player.get("gold", 0) < gold_amount:
			# Rollback
			add_item_to_player(from_peer_id, item_id, quantity)
			return {"success": false, "error": "Receiver doesn't have enough gold"}
		
		# Transfer gold
		to_player["gold"] -= gold_amount
		from_player["gold"] += gold_amount
	
	# Give item to receiver
	add_item_to_player(to_peer_id, item_id, quantity)
	
	# Log trade
	var trade_log = {
		"from_username": from_player["username"],
		"to_username": to_player["username"],
		"item_id": item_id,
		"quantity": quantity,
		"gold_amount": gold_amount,
		"timestamp": Time.get_datetime_string_from_system()
	}
	_trades_log.append(trade_log)
	
	# Save immediately
	save_player_data(from_peer_id)
	save_player_data(to_peer_id)
	
	print("[DatabaseJSON] Trade: %s gave %dx %s to %s for %d gold" % [
		from_player["username"], quantity, item_id, to_player["username"], gold_amount
	])
	
	return {"success": true}


# =========================
# Quest Management
# =========================

func update_player_quest(peer_id: int, quest_id: String, is_complete: bool, completed_steps: Array) -> void:
	"""Update player's quest progress"""
	if not _player_sessions.has(peer_id):
		return
	
	var player_data = _player_sessions[peer_id]
	var quests = player_data.get("quests", [])
	
	# Find existing quest
	var found = false
	for quest in quests:
		if quest["quest_id"] == quest_id:
			quest["is_complete"] = is_complete
			quest["completed_steps"] = completed_steps
			found = true
			break
	
	# Add new quest if not found
	if not found:
		quests.append({
			"quest_id": quest_id,
			"is_complete": is_complete,
			"completed_steps": completed_steps,
			"started_at": Time.get_datetime_string_from_system()
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


func get_trade_history(username: String, limit: int = 10) -> Array:
	"""Get recent trades for a player"""
	var trades = []
	for trade in _trades_log:
		if trade["from_username"] == username or trade["to_username"] == username:
			trades.append(trade)
			if trades.size() >= limit:
				break
	return trades


func _exit_tree() -> void:
	"""Save all player data on shutdown"""
	if multiplayer.is_server():
		for peer_id in _player_sessions.keys():
			save_player_data(peer_id)
		
		_save_all_data()
		print("[DatabaseJSON] Saved all player data")
