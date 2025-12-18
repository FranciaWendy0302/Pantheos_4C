extends Node

# Global Party Manager
# Handles all party-related functionality and state

signal party_created(party_id: int)
signal party_disbanded()
signal member_joined(player_id: int)
signal member_left(player_id: int)
signal invite_received(invite_data: Dictionary)
signal hp_updated(player_id: int, hp: int, max_hp: int)
signal leadership_changed(new_leader_id: int)

var current_party_id: int = -1
var is_leader: bool = false
var party_members: Array = []
var pending_invite_id: int = -1

func _ready() -> void:
	print("[PartyManager] Initialized")

# ==================== PARTY ACTIONS ====================

func create_party() -> void:
	"""Create a new party"""
	print("[PartyManager] Creating party...")
	
	var message = {
		"type": "party_create",
		"data": {}
	}
	NetworkManager.send_websocket_message(message)

func invite_player(target_player_id: int) -> void:
	"""Invite a player to the party"""
	print("[PartyManager] Inviting player: ", target_player_id)
	
	# Note: Server will validate if we're in a party
	# The caller (PlayerHud) should create party first if needed
	
	var message = {
		"type": "party_invite",
		"data": {
			"target_player_id": target_player_id
		}
	}
	NetworkManager.send_websocket_message(message)

func accept_invite() -> void:
	"""Accept a pending party invite"""
	if pending_invite_id <= 0:
		push_error("[PartyManager] No pending invite!")
		return
	
	print("[PartyManager] Accepting invite: ", pending_invite_id)
	
	var message = {
		"type": "party_accept",
		"data": {
			"invite_id": pending_invite_id
		}
	}
	NetworkManager.send_websocket_message(message)
	pending_invite_id = -1

func decline_invite() -> void:
	"""Decline a pending party invite"""
	if pending_invite_id <= 0:
		push_error("[PartyManager] No pending invite!")
		return
	
	print("[PartyManager] Declining invite: ", pending_invite_id)
	
	var message = {
		"type": "party_decline",
		"data": {
			"invite_id": pending_invite_id
		}
	}
	NetworkManager.send_websocket_message(message)
	pending_invite_id = -1

func leave_party() -> void:
	"""Leave the current party"""
	if not is_in_party():
		push_error("[PartyManager] Not in a party!")
		return
	
	print("[PartyManager] Leaving party...")
	
	var message = {
		"type": "party_leave",
		"data": {}
	}
	NetworkManager.send_websocket_message(message)

func kick_member(target_player_id: int) -> void:
	"""Kick a member from the party (leader only)"""
	if not is_party_leader():
		push_error("[PartyManager] Only the leader can kick members!")
		return
	
	print("[PartyManager] Kicking player: ", target_player_id)
	
	var message = {
		"type": "party_kick",
		"data": {
			"target_player_id": target_player_id
		}
	}
	NetworkManager.send_websocket_message(message)

func transfer_leadership(target_player_id: int) -> void:
	"""Transfer leadership to another member (leader only)"""
	if not is_party_leader():
		push_error("[PartyManager] Only the leader can transfer leadership!")
		return
	
	print("[PartyManager] Transferring leadership to: ", target_player_id)
	
	var message = {
		"type": "party_transfer_leadership",
		"data": {
			"target_player_id": target_player_id
		}
	}
	NetworkManager.send_websocket_message(message)

func update_hp(hp: int, max_hp: int) -> void:
	"""Send HP update to party members"""
	if not is_in_party():
		return
	
	print("[PartyManager] Sending HP update: ", hp, "/", max_hp)
	
	var message = {
		"type": "party_hp_update",
		"data": {
			"hp": hp,
			"max_hp": max_hp
		}
	}
	NetworkManager.send_websocket_message(message)

# ==================== SERVER MESSAGE HANDLERS ====================

func handle_party_created(data: Dictionary) -> void:
	"""Handle party_created message from server"""
	current_party_id = data.get("party_id", -1)
	is_leader = true
	
	# Request full member list from server instead of assuming
	# The server will send party_member_joined with full member data
	party_members = []
	
	print("[PartyManager] Party created: ", current_party_id, " - waiting for member list")
	party_created.emit(current_party_id)

func handle_party_invite_received(data: Dictionary) -> void:
	"""Handle party_invite_received message from server"""
	pending_invite_id = data.get("invite_id", -1)
	var inviter_name = data.get("inviter_name", "Unknown")
	
	print("[PartyManager] Invite received from: ", inviter_name)
	invite_received.emit(data)

func handle_party_member_joined(data: Dictionary) -> void:
	"""Handle party_member_joined message from server"""
	current_party_id = data.get("party_id", -1)
	party_members = data.get("members", [])
	
	# Debug: Print member data
	print("[PartyManager] Received members data:")
	for member in party_members:
		print("  - ID:", member.get("id"), " Name:", member.get("username"), " Role:", member.get("role"))
	
	# Check if we're the leader
	for member in party_members:
		if member.get("id") == PlayerManager.player_id:
			is_leader = (member.get("role", "") == "leader")
			break
	
	print("[PartyManager] Member joined. Party size: ", party_members.size())
	member_joined.emit(data.get("player_id", -1))

func handle_party_member_left(data: Dictionary) -> void:
	"""Handle party_member_left message from server"""
	party_members = data.get("members", [])
	var reason = data.get("reason", "")
	
	# Check if we're the leader
	for member in party_members:
		if member.get("id") == PlayerManager.player_id:
			is_leader = (member.get("role", "") == "leader")
			break
	
	var left_msg = "Member left"
	if reason == "disconnected":
		left_msg = "Member disconnected"
	
	print("[PartyManager] ", left_msg, ". Party size: ", party_members.size())
	member_left.emit(data.get("player_id", -1))

func handle_party_left(_data: Dictionary) -> void:
	"""Handle party_left message from server (we left)"""
	_clear_party_state()
	print("[PartyManager] You left the party")

func handle_party_disbanded(data: Dictionary) -> void:
	"""Handle party_disbanded message from server"""
	var reason = data.get("reason", "")
	_clear_party_state()
	
	if reason:
		print("[PartyManager] Party disbanded: ", reason)
	else:
		print("[PartyManager] Party disbanded")
	
	party_disbanded.emit()

func handle_party_kicked(_data: Dictionary) -> void:
	"""Handle party_kicked message from server (we were kicked)"""
	_clear_party_state()
	print("[PartyManager] You were kicked from the party")
	party_disbanded.emit()

func handle_party_leadership_changed(data: Dictionary) -> void:
	"""Handle party_leadership_changed message from server"""
	var new_leader_id = data.get("new_leader_id", -1)
	is_leader = (new_leader_id == PlayerManager.player_id)
	
	# Update member roles
	for member in party_members:
		if member.get("id") == new_leader_id:
			member["role"] = "leader"
		else:
			member["role"] = "member"
	
	print("[PartyManager] Leadership changed. New leader: ", new_leader_id)
	leadership_changed.emit(new_leader_id)

func handle_party_member_hp_update(data: Dictionary) -> void:
	"""Handle party_member_hp_update message from server"""
	var player_id = data.get("player_id", -1)
	var hp = data.get("hp", 0)
	var max_hp = data.get("max_hp", 100)
	
	# Only process if we're in a party
	if not is_in_party():
		return
	
	# Check if this player is in our party
	var is_party_member = false
	for member in party_members:
		if member.get("id") == player_id:
			member["hp"] = hp
			member["max_hp"] = max_hp
			is_party_member = true
			break
	
	# Only emit signal if player is actually in our party
	if is_party_member:
		hp_updated.emit(player_id, hp, max_hp)

func handle_party_error(data: Dictionary) -> void:
	"""Handle party_error message from server"""
	var error = data.get("error", "Unknown error")
	push_error("[PartyManager] Server error: " + error)
	
	# If error is "not in party", clear our state
	if "not in a party" in error.to_lower() or "not in party" in error.to_lower():
		print("[PartyManager] Clearing party state due to 'not in party' error")
		_clear_party_state()
		party_disbanded.emit()

# ==================== HELPER FUNCTIONS ====================

func is_in_party() -> bool:
	"""Check if we're in a party"""
	return current_party_id > 0

func is_party_leader() -> bool:
	"""Check if we're the party leader"""
	return is_in_party() and is_leader

func get_members() -> Array:
	"""Get list of party members"""
	return party_members

func get_member_count() -> int:
	"""Get number of party members"""
	return party_members.size()

func get_party_id() -> int:
	"""Get current party ID"""
	return current_party_id

func _clear_party_state() -> void:
	"""Clear all party state"""
	current_party_id = -1
	is_leader = false
	party_members.clear()
	pending_invite_id = -1
