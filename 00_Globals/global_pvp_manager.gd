extends Node

## Global PvP Manager - Handles all PvP rules, duels, and hostility

signal duel_requested(from_player_id: int, to_player_id: int, from_name: String)
signal duel_accepted(player1_id: int, player2_id: int)
signal duel_declined(player1_id: int, player2_id: int)
signal duel_ended(player1_id: int, player2_id: int, winner_id: int)

# Map types
enum MapType {
	SAFEZONE,    # No PvP allowed
	PVP_ZONE     # PvP enabled (map-01 to map-08)
}

# Current map type
var current_map_type: MapType = MapType.SAFEZONE

# Active duels: {player1_id: player2_id}
var active_duels: Dictionary = {}

# Party system reference (if exists)
var party_system = null

func _ready():
	# Try to get party system if it exists
	party_system = get_node_or_null("/root/PartySystem")

## ============================================
## MAP TYPE MANAGEMENT
## ============================================

func set_map_type(map_path: String):
	"""Determine map type based on path"""
	if "safezone" in map_path.to_lower():
		current_map_type = MapType.SAFEZONE
		print("[PvPManager] Entered SAFEZONE - PvP disabled")
	elif "map-" in map_path.to_lower():
		current_map_type = MapType.PVP_ZONE
		print("[PvPManager] Entered PVP ZONE - PvP enabled")
	else:
		# Default to safezone for unknown maps
		current_map_type = MapType.SAFEZONE
		print("[PvPManager] Unknown map type - defaulting to SAFEZONE")

func is_safezone() -> bool:
	return current_map_type == MapType.SAFEZONE

func is_pvp_zone() -> bool:
	return current_map_type == MapType.PVP_ZONE

## ============================================
## HOSTILITY CHECKS
## ============================================

func can_attack(attacker_id: int, target_id: int) -> bool:
	"""Check if attacker can damage target"""
	
	# Can't attack yourself
	if attacker_id == target_id:
		return false
	
	# SAFEZONE: Check if in active duel
	if is_safezone():
		return is_in_duel_with(attacker_id, target_id)
	
	# PVP ZONE: Check party membership
	if is_pvp_zone():
		# Can't attack party members
		if are_in_same_party(attacker_id, target_id):
			return false
		
		# Can attack anyone else
		return true
	
	return false

func are_in_same_party(player1_id: int, player2_id: int) -> bool:
	"""Check if two players are in the same party"""
	if not party_system:
		return false
	
	if not party_system.has_method("are_in_same_party"):
		return false
	
	return party_system.are_in_same_party(player1_id, player2_id)

## ============================================
## DUEL SYSTEM
## ============================================

func request_duel(from_player_id: int, to_player_id: int, from_name: String):
	"""Request a duel with another player"""
	
	# Can only duel in safezone
	if not is_safezone():
		print("[PvPManager] Duels only allowed in safezone!")
		return
	
	# Check if already in a duel
	if is_in_any_duel(from_player_id) or is_in_any_duel(to_player_id):
		print("[PvPManager] One or both players already in a duel!")
		return
	
	print("[PvPManager] Duel requested: %d → %d" % [from_player_id, to_player_id])
	duel_requested.emit(from_player_id, to_player_id, from_name)

func accept_duel(player1_id: int, player2_id: int):
	"""Accept a duel request"""
	
	# Store duel (bidirectional)
	active_duels[player1_id] = player2_id
	active_duels[player2_id] = player1_id
	
	print("[PvPManager] Duel started: %d vs %d" % [player1_id, player2_id])
	duel_accepted.emit(player1_id, player2_id)

func decline_duel(player1_id: int, player2_id: int):
	"""Decline a duel request"""
	print("[PvPManager] Duel declined: %d vs %d" % [player1_id, player2_id])
	duel_declined.emit(player1_id, player2_id)

func end_duel(player1_id: int, player2_id: int, winner_id: int = -1):
	"""End an active duel"""
	
	# Remove duel
	active_duels.erase(player1_id)
	active_duels.erase(player2_id)
	
	print("[PvPManager] Duel ended: %d vs %d (winner: %d)" % [player1_id, player2_id, winner_id])
	duel_ended.emit(player1_id, player2_id, winner_id)

func is_in_duel_with(player1_id: int, player2_id: int) -> bool:
	"""Check if two players are dueling each other"""
	return active_duels.get(player1_id) == player2_id

func is_in_any_duel(player_id: int) -> bool:
	"""Check if player is in any duel"""
	return active_duels.has(player_id)

func get_duel_opponent(player_id: int) -> int:
	"""Get the opponent player is dueling (-1 if not in duel)"""
	return active_duels.get(player_id, -1)

## ============================================
## PLAYER INTERACTION
## ============================================

func get_player_interaction_options(target_player_id: int) -> Array[String]:
	"""Get available interaction options for a player"""
	var options: Array[String] = []
	
	if is_safezone():
		# In safezone: Party invite and Duel
		options.append("Invite to Party")
		
		if not is_in_any_duel(PlayerManager.player_id) and not is_in_any_duel(target_player_id):
			options.append("Challenge to Duel")
	else:
		# In PvP zone: Only party invite
		if not are_in_same_party(PlayerManager.player_id, target_player_id):
			options.append("Invite to Party")
	
	return options

## ============================================
## CLEANUP
## ============================================

func cleanup_player_duels(player_id: int):
	"""Clean up duels when player leaves"""
	if is_in_any_duel(player_id):
		var opponent_id = get_duel_opponent(player_id)
		end_duel(player_id, opponent_id)
