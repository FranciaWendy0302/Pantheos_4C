extends Node

## Server-side database manager for MMORPG persistent storage
## Handles player accounts, inventory, trading, quests, etc.

const DB_PATH = "user://mmorpg_server.db"

var _db: SQLite = null
var _player_sessions: Dictionary = {}  # peer_id -> player_data

class_name DatabaseManager

func _ready() -> void:
	if not multiplayer.is_server():
		print("[DatabaseManager] Client mode - database disabled")
		return
	
	_initialize_database()
	print("[DatabaseManager] Server database initialized at: %s" % DB_PATH)


func _initialize_database() -> void:
	"""Initialize SQLite database with tables"""
	_db = SQLite.new()
	_db.path = DB_PATH
	_db.open_db()
	
	# Create tables
	_create_tables()


func _create_tables() -> void:
	"""Create all necessary database tables"""
	
	# Players table
	var create_players = """
	CREATE TABLE IF NOT EXISTS players (
		player_id INTEGER PRIMARY KEY AUTOINCREMENT,
		username TEXT UNIQUE NOT NULL,
		password_hash TEXT NOT NULL,
		nickname TEXT NOT NULL,
		level INTEGER DEFAULT 1,
		xp INTEGER DEFAULT 0,
		gold INTEGER DEFAULT 0,
		hp INTEGER DEFAULT 100,
		max_hp INTEGER DEFAULT 100,
		last_map TEXT DEFAULT '',
		last_position_x REAL DEFAULT 0,
		last_position_y REAL DEFAULT 0,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		last_login DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	"""
	_db.query(create_players)
	
	# Inventory table
	var create_inventory = """
	CREATE TABLE IF NOT EXISTS inventory (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		player_id INTEGER NOT NULL,
		item_id TEXT NOT NULL,
		quantity INTEGER DEFAULT 1,
		slot_index INTEGER DEFAULT -1,
		FOREIGN KEY (player_id) REFERENCES players(player_id)
	);
	"""
	_db.query(create_inventory)
	
	# Quests table
	var create_quests = """
	CREATE TABLE IF NOT EXISTS player_quests (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		player_id INTEGER NOT NULL,
		quest_id TEXT NOT NULL,
		is_complete BOOLEAN DEFAULT 0,
		completed_steps TEXT DEFAULT '[]',
		started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (player_id) REFERENCES players(player_id)
	);
	"""
	_db.query(create_quests)
	
	# Trade history table
	var create_trades = """
	CREATE TABLE IF NOT EXISTS trades (
		trade_id INTEGER PRIMARY KEY AUTOINCREMENT,
		from_player_id INTEGER NOT NULL,
		to_player_id INTEGER NOT NULL,
		item_id TEXT NOT NULL,
		quantity INTEGER NOT NULL,
		gold_amount INTEGER DEFAULT 0,
		trade_date DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (from_player_id) REFERENCES players(player_id),
		FOREIGN KEY (to_player_id) REFERENCES players(player_id)
	);
	"""
	_db.query(create_trades)
	
	print("[Database] Tables created successfully")


# =========================
# Player Account Management
# =========================

func create_account(username: String, password: String, nickname: String) -> Dictionary:
	"""Create a new player account. Returns {success: bool, player_id: int, error: String}"""
	if not multiplayer.is_server():
		return {"success": false, "error": "Not server"}
	
	# Hash password (simple hash - use proper crypto in production)
	var password_hash = password.sha256_text()
	
	# Check if username exists
	var check_query = "SELECT player_id FROM players WHERE username = '%s';" % username
	var result = _db.query(check_query)
	
	if result.size() > 0:
		return {"success": false, "error": "Username already exists"}
	
	# Create account
	var insert_query = """
	INSERT INTO players (username, password_hash, nickname)
	VALUES ('%s', '%s', '%s');
	""" % [username, password_hash, nickname]
	
	_db.query(insert_query)
	
	# Get the new player_id
	var get_id = "SELECT player_id FROM players WHERE username = '%s';" % username
	var id_result = _db.query(get_id)
	
	if id_result.size() > 0:
		var player_id = id_result[0]["player_id"]
		print("[Database] Created account: %s (ID: %d)" % [username, player_id])
		return {"success": true, "player_id": player_id}
	
	return {"success": false, "error": "Failed to create account"}


func login(username: String, password: String, peer_id: int) -> Dictionary:
	"""Login player. Returns {success: bool, player_data: Dictionary, error: String}"""
	if not multiplayer.is_server():
		return {"success": false, "error": "Not server"}
	
	var password_hash = password.sha256_text()
	
	var query = """
	SELECT * FROM players 
	WHERE username = '%s' AND password_hash = '%s';
	""" % [username, password_hash]
	
	var result = _db.query(query)
	
	if result.size() == 0:
		return {"success": false, "error": "Invalid username or password"}
	
	var player_data = result[0]
	
	# Update last login
	var update_login = """
	UPDATE players 
	SET last_login = CURRENT_TIMESTAMP 
	WHERE player_id = %d;
	""" % player_data["player_id"]
	_db.query(update_login)
	
	# Load inventory
	player_data["inventory"] = _load_player_inventory(player_data["player_id"])
	
	# Load quests
	player_data["quests"] = _load_player_quests(player_data["player_id"])
	
	# Store session
	_player_sessions[peer_id] = player_data
	
	print("[Database] Player logged in: %s (ID: %d, Peer: %d)" % [username, player_data["player_id"], peer_id])
	
	return {"success": true, "player_data": player_data}


func logout(peer_id: int) -> void:
	"""Logout player and save their data"""
	if not _player_sessions.has(peer_id):
		return
	
	var player_data = _player_sessions[peer_id]
	save_player_data(peer_id)
	_player_sessions.erase(peer_id)
	
	print("[Database] Player logged out: %s" % player_data.get("username", "Unknown"))


# =========================
# Player Data Management
# =========================

func save_player_data(peer_id: int) -> void:
	"""Save player's current state to database"""
	if not _player_sessions.has(peer_id):
		return
	
	var player_data = _player_sessions[peer_id]
	var player_id = player_data["player_id"]
	
	var update_query = """
	UPDATE players 
	SET level = %d, xp = %d, gold = %d, hp = %d, max_hp = %d,
	    last_map = '%s', last_position_x = %f, last_position_y = %f
	WHERE player_id = %d;
	""" % [
		player_data.get("level", 1),
		player_data.get("xp", 0),
		player_data.get("gold", 0),
		player_data.get("hp", 100),
		player_data.get("max_hp", 100),
		player_data.get("last_map", ""),
		player_data.get("last_position_x", 0.0),
		player_data.get("last_position_y", 0.0),
		player_id
	]
	
	_db.query(update_query)
	
	# Save inventory
	_save_player_inventory(player_id, player_data.get("inventory", []))


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

func _load_player_inventory(player_id: int) -> Array:
	"""Load player's inventory from database"""
	var query = "SELECT * FROM inventory WHERE player_id = %d;" % player_id
	var result = _db.query(query)
	return result if result else []


func _save_player_inventory(player_id: int, inventory: Array) -> void:
	"""Save player's inventory to database"""
	# Clear existing inventory
	var delete_query = "DELETE FROM inventory WHERE player_id = %d;" % player_id
	_db.query(delete_query)
	
	# Insert current inventory
	for item in inventory:
		var insert_query = """
		INSERT INTO inventory (player_id, item_id, quantity, slot_index)
		VALUES (%d, '%s', %d, %d);
		""" % [player_id, item.get("item_id", ""), item.get("quantity", 1), item.get("slot_index", -1)]
		_db.query(insert_query)


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
		"quantity": quantity,
		"slot_index": -1
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
				return false  # Not enough items
	
	return false  # Item not found


# =========================
# Trading System
# =========================

func execute_trade(from_peer_id: int, to_peer_id: int, item_id: String, quantity: int, gold_amount: int) -> Dictionary:
	"""Execute a trade between two players. Returns {success: bool, error: String}"""
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
			# Rollback item removal
			add_item_to_player(from_peer_id, item_id, quantity)
			return {"success": false, "error": "Receiver doesn't have enough gold"}
		
		# Transfer gold
		to_player["gold"] -= gold_amount
		from_player["gold"] += gold_amount
	
	# Give item to receiver
	add_item_to_player(to_peer_id, item_id, quantity)
	
	# Log trade in database
	var trade_query = """
	INSERT INTO trades (from_player_id, to_player_id, item_id, quantity, gold_amount)
	VALUES (%d, %d, '%s', %d, %d);
	""" % [from_player["player_id"], to_player["player_id"], item_id, quantity, gold_amount]
	_db.query(trade_query)
	
	print("[Database] Trade executed: %s gave %dx %s to %s for %d gold" % [
		from_player["username"], quantity, item_id, to_player["username"], gold_amount
	])
	
	return {"success": true}


# =========================
# Quest Management
# =========================

func _load_player_quests(player_id: int) -> Array:
	"""Load player's quests from database"""
	var query = "SELECT * FROM player_quests WHERE player_id = %d;" % player_id
	var result = _db.query(query)
	return result if result else []


func update_player_quest(peer_id: int, quest_id: String, is_complete: bool, completed_steps: Array) -> void:
	"""Update player's quest progress"""
	if not _player_sessions.has(peer_id):
		return
	
	var player_data = _player_sessions[peer_id]
	var player_id = player_data["player_id"]
	
	var steps_json = JSON.stringify(completed_steps)
	
	# Check if quest exists
	var check_query = "SELECT id FROM player_quests WHERE player_id = %d AND quest_id = '%s';" % [player_id, quest_id]
	var result = _db.query(check_query)
	
	if result.size() > 0:
		# Update existing quest
		var update_query = """
		UPDATE player_quests 
		SET is_complete = %d, completed_steps = '%s'
		WHERE player_id = %d AND quest_id = '%s';
		""" % [1 if is_complete else 0, steps_json, player_id, quest_id]
		_db.query(update_query)
	else:
		# Insert new quest
		var insert_query = """
		INSERT INTO player_quests (player_id, quest_id, is_complete, completed_steps)
		VALUES (%d, '%s', %d, '%s');
		""" % [player_id, quest_id, 1 if is_complete else 0, steps_json]
		_db.query(insert_query)


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
		
		if _db:
			_db.close_db()
		
		print("[Database] Saved all player data and closed database")
