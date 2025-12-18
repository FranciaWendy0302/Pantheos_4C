extends Node

## Trading system for MMORPG
## Handles trade requests, offers, and execution

signal trade_requested(from_peer_id: int, from_username: String)
signal trade_offer_received(item_id: String, quantity: int, gold: int)
signal trade_completed(success: bool, message: String)
signal trade_cancelled()

var _active_trade: Dictionary = {}  # Current trade state
var _trade_partner_peer_id: int = -1

# =========================
# CLIENT: Initiate Trade
# =========================

func request_trade_with_player(target_peer_id: int) -> void:
	"""Request to trade with another player"""
	if multiplayer.is_server():
		return
	
	_rpc_request_trade.rpc_id(1, target_peer_id)
	print("[Trade] Requested trade with peer %d" % target_peer_id)


func offer_trade(item_id: String, quantity: int, gold_amount: int) -> void:
	"""Offer items/gold in current trade"""
	if multiplayer.is_server() or _trade_partner_peer_id == -1:
		return
	
	_rpc_trade_offer.rpc_id(1, _trade_partner_peer_id, item_id, quantity, gold_amount)
	print("[Trade] Offered %dx %s for %d gold" % [quantity, item_id, gold_amount])


func accept_trade() -> void:
	"""Accept the current trade offer"""
	if multiplayer.is_server() or _trade_partner_peer_id == -1:
		return
	
	_rpc_accept_trade.rpc_id(1, _trade_partner_peer_id)
	print("[Trade] Accepted trade")


func cancel_trade() -> void:
	"""Cancel current trade"""
	if _trade_partner_peer_id != -1:
		_rpc_cancel_trade.rpc_id(1, _trade_partner_peer_id)
	
	_reset_trade()
	trade_cancelled.emit()
	print("[Trade] Cancelled trade")


func _reset_trade() -> void:
	"""Reset trade state"""
	_active_trade.clear()
	_trade_partner_peer_id = -1


# =========================
# SERVER: Trade Management
# =========================

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_trade(target_peer_id: int) -> void:
	"""SERVER: Handle trade request"""
	if not multiplayer.is_server():
		return
	
	var requester_id = multiplayer.get_remote_sender_id()
	
	# Validate both players are logged in
	if not DatabaseManager.is_player_logged_in(requester_id):
		_rpc_trade_error.rpc_id(requester_id, "You must be logged in to trade")
		return
	
	if not DatabaseManager.is_player_logged_in(target_peer_id):
		_rpc_trade_error.rpc_id(requester_id, "Target player not found")
		return
	
	# Get usernames
	var requester_data = DatabaseManager.get_player_data(requester_id)
	var requester_username = requester_data.get("username", "Unknown")
	
	# Notify target player
	_rpc_trade_request_received.rpc_id(target_peer_id, requester_id, requester_username)
	
	print("[Server] Trade request: %s (peer %d) → peer %d" % [requester_username, requester_id, target_peer_id])


@rpc("any_peer", "call_remote", "reliable")
func _rpc_trade_offer(target_peer_id: int, item_id: String, quantity: int, gold_amount: int) -> void:
	"""SERVER: Handle trade offer"""
	if not multiplayer.is_server():
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	
	# Forward offer to target
	_rpc_trade_offer_received.rpc_id(target_peer_id, item_id, quantity, gold_amount)
	
	print("[Server] Trade offer: peer %d → peer %d (%dx %s for %d gold)" % [
		sender_id, target_peer_id, quantity, item_id, gold_amount
	])


@rpc("any_peer", "call_remote", "reliable")
func _rpc_accept_trade(partner_peer_id: int) -> void:
	"""SERVER: Execute trade"""
	if not multiplayer.is_server():
		return
	
	var accepter_id = multiplayer.get_remote_sender_id()
	
	# Get the last offer (in real implementation, store offers properly)
	# For now, this is a simplified example
	
	# Example: Execute a simple trade
	# In production, you'd store the full trade offer details
	var result = DatabaseManager.execute_trade(
		partner_peer_id,  # Sender
		accepter_id,      # Receiver
		"health_potion",  # Example item
		1,                # Quantity
		10                # Gold amount
	)
	
	if result["success"]:
		_rpc_trade_completed.rpc_id(partner_peer_id, true, "Trade completed!")
		_rpc_trade_completed.rpc_id(accepter_id, true, "Trade completed!")
		print("[Server] Trade executed successfully")
	else:
		_rpc_trade_completed.rpc_id(partner_peer_id, false, result["error"])
		_rpc_trade_completed.rpc_id(accepter_id, false, result["error"])
		print("[Server] Trade failed: %s" % result["error"])


@rpc("any_peer", "call_remote", "reliable")
func _rpc_cancel_trade(partner_peer_id: int) -> void:
	"""SERVER: Cancel trade"""
	if not multiplayer.is_server():
		return
	
	var canceller_id = multiplayer.get_remote_sender_id()
	
	_rpc_trade_cancelled.rpc_id(partner_peer_id)
	_rpc_trade_cancelled.rpc_id(canceller_id)
	
	print("[Server] Trade cancelled by peer %d" % canceller_id)


# =========================
# CLIENT: Receive Trade Events
# =========================

@rpc("authority", "call_remote", "reliable")
func _rpc_trade_request_received(from_peer_id: int, from_username: String) -> void:
	"""CLIENT: Receive trade request"""
	_trade_partner_peer_id = from_peer_id
	trade_requested.emit(from_peer_id, from_username)
	print("[Trade] Received trade request from %s (peer %d)" % [from_username, from_peer_id])


@rpc("authority", "call_remote", "reliable")
func _rpc_trade_offer_received(item_id: String, quantity: int, gold: int) -> void:
	"""CLIENT: Receive trade offer"""
	trade_offer_received.emit(item_id, quantity, gold)
	print("[Trade] Received offer: %dx %s for %d gold" % [quantity, item_id, gold])


@rpc("authority", "call_remote", "reliable")
func _rpc_trade_completed(success: bool, message: String) -> void:
	"""CLIENT: Trade completed"""
	trade_completed.emit(success, message)
	_reset_trade()
	print("[Trade] %s" % message)


@rpc("authority", "call_remote", "reliable")
func _rpc_trade_cancelled() -> void:
	"""CLIENT: Trade cancelled"""
	_reset_trade()
	trade_cancelled.emit()
	print("[Trade] Trade was cancelled")


@rpc("authority", "call_remote", "reliable")
func _rpc_trade_error(error_message: String) -> void:
	"""CLIENT: Trade error"""
	trade_completed.emit(false, error_message)
	_reset_trade()
	print("[Trade] Error: %s" % error_message)
