extends Node

# Global Duel Manager
# Manages active duels, combat rules, and duel state

signal duel_started(player1_id: int, player2_id: int)
signal duel_ended(winner_id: int, loser_id: int)

enum DuelState {
	NONE,
	REQUESTED,
	ACCEPTED,
	COUNTDOWN,
	ACTIVE,
	ENDED
}

# Active duel data
var current_duel: Dictionary = {}
var duel_state: DuelState = DuelState.NONE
var countdown_timer: float = 0.0
var duel_countdown: int = 3

# Duel settings
var restore_hp_on_start: bool = true
var restore_mana_on_start: bool = true
var teleport_to_arena: bool = false  # Future: teleport to arena
var duel_arena_scene: String = ""  # Future: arena scene path

func _ready():
	# Connect to NetworkManager signals
	if NetworkManager:
		if not NetworkManager.duel_started.is_connected(_on_network_duel_started):
			NetworkManager.duel_started.connect(_on_network_duel_started)
		if not NetworkManager.duel_ended.is_connected(_on_network_duel_ended):
			NetworkManager.duel_ended.connect(_on_network_duel_ended)

func _process(delta: float):
	if duel_state == DuelState.COUNTDOWN:
		countdown_timer -= delta
		if countdown_timer <= 0:
			_start_duel_combat()

func start_duel(player1_id: int, player2_id: int, player1_name: String, player2_name: String):
	"""Start a duel between two players"""
	print("[DuelManager] Starting duel: ", player1_name, " vs ", player2_name)
	
	current_duel = {
		"player1_id": player1_id,
		"player2_id": player2_id,
		"player1_name": player1_name,
		"player2_name": player2_name,
		"start_time": Time.get_ticks_msec()
	}
	
	duel_state = DuelState.COUNTDOWN
	countdown_timer = float(duel_countdown)
	
	# Restore HP/Mana if enabled
	if restore_hp_on_start or restore_mana_on_start:
		_restore_player_stats()
	
	# Show countdown
	_show_countdown()

func _start_duel_combat():
	"""Actually start the duel combat"""
	duel_state = DuelState.ACTIVE
	print("[DuelManager] Duel combat started!")
	duel_started.emit(current_duel.player1_id, current_duel.player2_id)

func end_duel(winner_id: int, loser_id: int):
	"""End the current duel"""
	if duel_state == DuelState.NONE:
		return
	
	print("[DuelManager] Duel ended - Winner: ", winner_id, " Loser: ", loser_id)
	
	duel_state = DuelState.ENDED
	duel_ended.emit(winner_id, loser_id)
	
	# Clear duel data after a delay
	await get_tree().create_timer(3.0).timeout
	current_duel.clear()
	duel_state = DuelState.NONE

func is_in_duel(player_id: int) -> bool:
	"""Check if a player is in an active duel"""
	if duel_state == DuelState.NONE or duel_state == DuelState.ENDED:
		return false
	
	return player_id == current_duel.get("player1_id") or player_id == current_duel.get("player2_id")

func can_attack(attacker_id: int, target_id: int) -> bool:
	"""Check if attacker can damage target in duel"""
	if not is_in_duel(attacker_id) or not is_in_duel(target_id):
		return false
	
	# Can only attack during active duel
	if duel_state != DuelState.ACTIVE:
		return false
	
	# Can only attack the opponent
	if attacker_id == current_duel.player1_id and target_id == current_duel.player2_id:
		return true
	if attacker_id == current_duel.player2_id and target_id == current_duel.player1_id:
		return true
	
	return false

func get_opponent_id(player_id: int) -> int:
	"""Get the opponent's ID in the current duel"""
	if not is_in_duel(player_id):
		return -1
	
	if player_id == current_duel.player1_id:
		return current_duel.player2_id
	elif player_id == current_duel.player2_id:
		return current_duel.player1_id
	
	return -1

func _restore_player_stats():
	"""Restore HP/Mana for both players"""
	var player = PlayerManager.player
	if not player:
		return
	
	var my_id = PlayerManager.player_id
	if not is_in_duel(my_id):
		return
	
	if restore_hp_on_start:
		player.hp = player.max_hp
		print("[DuelManager] HP restored to full")
	
	if restore_mana_on_start:
		player.mana = player.max_mana
		print("[DuelManager] Mana restored to full")
	
	# Update HUD
	if player.has_method("_update_player_hud"):
		player._update_player_hud()

func _show_countdown():
	"""Show countdown overlay"""
	var player_hud = get_tree().get_first_node_in_group("player_hud")
	if player_hud and player_hud.has_method("show_duel_countdown"):
		player_hud.show_duel_countdown(duel_countdown)
	
	# Countdown timer
	for i in range(duel_countdown, 0, -1):
		print("[DuelManager] Duel starting in ", i, "...")
		await get_tree().create_timer(1.0).timeout

func _on_network_duel_started(data: Dictionary):
	"""Handle duel started from network"""
	var player1_id = data.get("player1_id", -1)
	var player2_id = data.get("player2_id", -1)
	var player1_name = data.get("player1_name", "Unknown")
	var player2_name = data.get("player2_name", "Unknown")
	
	start_duel(player1_id, player2_id, player1_name, player2_name)

func _on_network_duel_ended(data: Dictionary):
	"""Handle duel ended from network"""
	var winner_id = data.get("winner_id", -1)
	var loser_id = data.get("loser_id", -1)
	
	end_duel(winner_id, loser_id)

func check_duel_winner():
	"""Check if someone won the duel (called when player dies)"""
	if duel_state != DuelState.ACTIVE:
		return
	
	var player = PlayerManager.player
	if not player:
		return
	
	var my_id = PlayerManager.player_id
	if not is_in_duel(my_id):
		return
	
	# If I died, I lost
	if player.hp <= 0:
		var opponent_id = get_opponent_id(my_id)
		if opponent_id > 0:
			# Notify server of duel end
			_notify_duel_end(opponent_id, my_id)

func _notify_duel_end(winner_id: int, loser_id: int):
	"""Notify server that duel ended"""
	if NetworkManager and NetworkManager._websocket:
		var message = {
			"type": "duel_end",
			"winner_id": winner_id,
			"loser_id": loser_id
		}
		var json_string = JSON.stringify(message)
		NetworkManager._websocket.send_text(json_string)
		print("[DuelManager] Notified server of duel end")
