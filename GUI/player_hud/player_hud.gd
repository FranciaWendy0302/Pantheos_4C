extends CanvasLayer

@export var button_focus_audio: AudioStream = preload("res://title_scene/audio/menu_focus.wav")
@export var button_select_audio: AudioStream = preload("res://title_scene/audio/menu_select.wav")

@onready var game_over: Control = $Control/GameOver
@onready var continue_button: Button = $Control/GameOver/VBoxContainer/ContinueButton
@onready var title_button: Button = $Control/GameOver/VBoxContainer/TitleButton
@onready var animation_player: AnimationPlayer = $Control/GameOver/AnimationPlayer
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

@onready var abilities: Control = $Control/Abilities
@onready var ability_items: HBoxContainer = $Control/Abilities/HBoxContainer
@onready var arrow_count_label: Label = %ArrowCountLabel
@onready var bomb_count_label: Label = %BombCountLabel

@onready var boss_ui: Control = $Control/BossUI
@onready var boss_hp_bar: TextureProgressBar = $Control/BossUI/TextureProgressBar
@onready var boss_label: Label = $Control/BossUI/Label

@onready var notification_ui: NotificationUI = $Control/Notification

@onready var minimap: Control = $Control/Minimap

# New comprehensive skill panel
var skill_panel: Control = null

# OLD: God skill button variables - removed with old skill system
#var god_skill_container: VBoxContainer = null
#var god_skill_button: Button = null
#var god_skill_cooldown_overlay: ColorRect = null
#var god_skill_cooldown_label: Label = null
#var god_skill_name_label: Label = null
#var god_skill_cooldown_timer: float = 0.0

@onready var wave_label: Label = %WaveLabel
@onready var kill_count_label: Label = %CountLabel
@onready var currency_label: Label = %CurrencyLabel

@onready var target_health_bar: Control = $Control/TargetHealthBar
@onready var target_name_label: Label = $Control/TargetHealthBar/VBoxContainer/NameLabel
@onready var target_hp_bar: ProgressBar = $Control/TargetHealthBar/VBoxContainer/HPBar
@onready var target_invite_button: Button = $Control/TargetHealthBar/VBoxContainer/InviteButton
@onready var target_inspect_button: Button = $Control/TargetHealthBar/VBoxContainer/InspectButton
@onready var target_add_friend_button: Button = $Control/TargetHealthBar/VBoxContainer/AddFriendButton

@onready var quest_tracker: Control = $Control/QuestTracker
@onready var quest_title_label: Label = $Control/QuestTracker/VBoxContainer/QuestTitle
@onready var quest_steps_container: VBoxContainer = $Control/QuestTracker/VBoxContainer/StepsContainer

@onready var player_hp_bar: TextureProgressBar = $Control/PlayerHealthBar/TextureProgressBar
@onready var player_health_bar_control: Control = $Control/PlayerHealthBar

# Artificial HP/Mana bars (created dynamically)
var hp_bar_container: VBoxContainer = null
var hp_progress_bar: ProgressBar = null
var mana_progress_bar: ProgressBar = null
var hp_label: Label = null
var mana_label: Label = null

# Friend system UI
var player_inspect_panel: Control = null
var friend_request_popup: Control = null
var friend_panel: Control = null
var duel_request_popup: Control = null

# Icon buttons work automatically - no variables needed

var wave_counter_active: bool = false
var currency_item: ItemData = preload("res://Items/gem.tres")

var dash_cooldown_timer: float = 0.0
var dash_cooldown_duration: float = 3.0
var charge_dash_cooldown_timer: float = 0.0
var charge_dash_cooldown_duration: float = 10.0
var spin_cooldown_timer: float = 0.0
var spin_cooldown_duration: float = 5.0


func _ready():
	hide_game_over_screen()
	continue_button.focus_entered.connect(play_audio.bind(button_focus_audio))
	continue_button.pressed.connect(load_game)
	title_button.focus_entered.connect(play_audio.bind(button_focus_audio))
	title_button.pressed.connect(title_screen)
	if not LevelManager.level_load_started.is_connected(hide_game_over_screen):
		LevelManager.level_load_started.connect(hide_game_over_screen)
	
	hide_boss_health()
	
	# Hide the old texture-based health bar
	if player_health_bar_control:
		player_health_bar_control.visible = false
	
	# OLD SKILL SYSTEM REMOVED - SkillsHUD node no longer exists
	# The new skill panel is created dynamically in _create_skill_panel()
	
	update_ability_ui(0)
	PauseMenu.shown.connect(_on_show_pause)
	PauseMenu.hidden.connect(_on_hide_pause)
	
	# Move minimap down slightly to avoid blocking currency
	if minimap:
		minimap.position.y += 40  # Move down 40 pixels
		print("[PlayerHud] Minimap moved down 40px")
	
	# Icon buttons work automatically - no setup needed!
	
	# Create the new comprehensive skill panel with HP/MP bars
	_create_skill_panel()
	
	# Setup other HUD elements
	_setup_hud()
	
	# Setup PvP UI
	call_deferred("_setup_pvp_ui")
	
	# Check if we should show tutorial dialogue
	call_deferred("_check_tutorial")

# OLD SKILL SYSTEM SETUP FUNCTIONS - COMMENTED OUT
#func _standardize_skill_button(button: Button):
#	pass
#
#func _setup_cooldown_label(button: Button, overlay: ColorRect, label: Label):
#	pass

# Setup functions that are still needed
func _setup_hud():
	"""Setup HUD elements"""
	# Hide quest tracker in HUD (now only in pause menu)
	if quest_tracker:
		quest_tracker.visible = false
	
	# Setup target health bar
	_setup_target_health_bar()
	
	# Update currency display
	update_currency_display()
	
	# Setup friend system UI
	_setup_friend_system_ui()
	
	pass

var previous_hp: int = 10
var hp_tween: Tween = null
var mana_tween: Tween = null
var player_hp_label: Label = null  # Old HP text label (deprecated)

func _setup_player_health_bar():
	"""Setup player health bar with text display (Phase 6.1)"""
	if not player_health_bar_control:
		print("[PlayerHud] ERROR: player_health_bar_control is null!")
		return
	
	if not player_hp_bar:
		print("[PlayerHud] ERROR: player_hp_bar is null!")
		return
	
	print("[PlayerHud] Setting up HP bar...")
	
	# Set initial HP bar value
	player_hp_bar.value = 100
	player_hp_bar.max_value = 100
	player_hp_bar.min_value = 0
	player_hp_bar.step = 0.1  # Smooth animation
	
	# Create HP text label next to the bar (not on top)
	if not player_hp_label:
		player_hp_label = Label.new()
		player_hp_label.name = "HPLabel"
		player_hp_label.add_theme_font_size_override("font_size", 16)
		player_hp_label.add_theme_color_override("font_color", Color.WHITE)
		player_hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
		player_hp_label.add_theme_constant_override("outline_size", 3)
		player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		player_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Position to the right of the HP bar
		player_hp_label.position = Vector2(60, 6)
		player_hp_label.size = Vector2(150, 20)
		player_hp_label.text = "100 / 100"
		player_health_bar_control.add_child(player_hp_label)
		print("[PlayerHud] HP label created and positioned next to HP bar")
	
	print("[PlayerHud] HP bar setup complete!")

func update_hp(_hp: int, _max_hp: int) -> void:
	# Update HP in the new skill panel
	if skill_panel and skill_panel.has_method("update_hp"):
		skill_panel.update_hp(_hp, _max_hp)
	
	previous_hp = _hp

func update_mana(_mana: int, _max_mana: int) -> void:
	"""Update mana bar in skill panel"""
	if skill_panel and skill_panel.has_method("update_mp"):
		skill_panel.update_mp(_mana, _max_mana)



func _flash_damage() -> void:
	if player_health_bar_control:
		var flash_tween = create_tween()
		flash_tween.set_parallel(true)
		# Flash red
		flash_tween.tween_property(player_health_bar_control, "modulate", Color(1.8, 0.3, 0.3, 1), 0.1)
		flash_tween.chain().tween_property(player_health_bar_control, "modulate", Color(1, 1, 1, 1), 0.3)
	pass

func _flash_heal() -> void:
	if player_health_bar_control:
		var flash_tween = create_tween()
		flash_tween.set_parallel(true)
		# Flash green
		flash_tween.tween_property(player_health_bar_control, "modulate", Color(0.3, 1.8, 0.3, 1), 0.1)
		flash_tween.chain().tween_property(player_health_bar_control, "modulate", Color(1, 1, 1, 1), 0.4)
	pass

func _shake_health_bar() -> void:
	if player_health_bar_control:
		var original_pos = player_health_bar_control.position
		var shake_tween = create_tween()
		shake_tween.set_parallel(false)
		# Quick shake effect
		shake_tween.tween_property(player_health_bar_control, "position", original_pos + Vector2(-3, 0), 0.05)
		shake_tween.tween_property(player_health_bar_control, "position", original_pos + Vector2(3, 0), 0.05)
		shake_tween.tween_property(player_health_bar_control, "position", original_pos + Vector2(-2, 0), 0.05)
		shake_tween.tween_property(player_health_bar_control, "position", original_pos + Vector2(2, 0), 0.05)
		shake_tween.tween_property(player_health_bar_control, "position", original_pos, 0.05)
	pass

func _pulse_health_bar() -> void:
	if player_health_bar_control:
		var original_scale = player_health_bar_control.scale
		var pulse_tween = create_tween()
		pulse_tween.set_parallel(false)
		# Gentle pulse effect
		pulse_tween.tween_property(player_health_bar_control, "scale", original_scale * 1.05, 0.15)
		pulse_tween.tween_property(player_health_bar_control, "scale", original_scale, 0.15)
	pass
	
func show_game_over_screen() -> void:
	game_over.visible = true
	game_over.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Hide minimap and skill panel when died
	if minimap:
		minimap.visible = false
	if skill_panel:
		skill_panel.visible = false
	
	var can_continue: bool = SaveManager.get_save_file() != null
	continue_button.visible = can_continue
	
	animation_player.play("show_game_over")
	await animation_player.animation_finished
	
	if can_continue == true:
		continue_button.grab_focus()
	else:
		title_button.grab_focus()
	
func hide_game_over_screen() -> void:
	game_over.visible = false
	game_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over.modulate = Color(1,1,1,0)
	
	# Show minimap and skill panel again after respawning
	if minimap:
		minimap.visible = true
	if skill_panel:
		skill_panel.visible = true
	
func load_game() -> void:
	play_audio(button_select_audio)
	await fade_to_black()
	
	# Save current progress before respawning (especially tutorial progress)
	SaveManager.save_game()
	
	# Check if we're in the tutorial - if so, respawn in tutorial
	var current_scene = get_tree().current_scene
	var was_in_tutorial = false
	if current_scene and is_instance_valid(current_scene):
		var scene_path = current_scene.get("scene_file_path")
		if scene_path == "res://Levels/Area01/tutorial.tscn":
			was_in_tutorial = true
	
	# If in tutorial, force load tutorial map instead of saved scene
	if was_in_tutorial:
		# Temporarily override scene_path to tutorial
		var original_scene_path = SaveManager.current_save.get("scene_path", "")
		SaveManager.current_save.scene_path = "res://Levels/Area01/tutorial.tscn"
		SaveManager.load_game()
		# Restore original scene path after loading
		SaveManager.current_save.scene_path = original_scene_path
	else:
		SaveManager.load_game()
	
func title_screen() -> void:
	play_audio(button_select_audio)
	await fade_to_black()
	LevelManager.load_new_level("res://title_scene/title_scene.tscn", "", Vector2.ZERO)
	
func fade_to_black() -> bool:
	animation_player.play("fade_to_black")
	await animation_player.animation_finished
	PlayerManager.player.revive_player()
	return true
	
func play_audio(_a: AudioStream) -> void:
	audio.stream = _a
	audio.play()

func show_boss_health(boss_name: String) -> void:
	boss_ui.visible = true
	boss_label.text = boss_name
	update_boss_health(1, 1)
	pass

func hide_boss_health() -> void:
	boss_ui.visible = false
	pass

func update_boss_health(hp: int, max_hp: int) -> void:
	boss_hp_bar.value = clampf(float(hp) / float(max_hp) * 100, 0, 100)
	pass

func queue_notificaiton(_title: String, _message: String) -> void:
	notification_ui.add_notification_to_queue(_title, _message)
	pass

func update_ability_items(items: Array[String]) -> void:
	var ability_item_nodes: Array[Node] = ability_items.get_children()
	for i in ability_item_nodes.size():
		if items[i] == "":
			ability_item_nodes[i].visible = false
		else:
			ability_item_nodes[i].visible = true
	pass

func update_ability_ui(ability_index: int) -> void:
	var _items: Array[Node] = ability_items.get_children()
	for a in _items:
		a.self_modulate = Color(1,1,1,0)
		a.modulate = Color(0.6,0.6,0.6,0.8)
	
	_items[ability_index].self_modulate = Color(1,1,1,1)
	_items[ability_index].modulate = Color(1,1,1,1)
	play_audio(button_focus_audio)
	pass

func update_arrow_count(count: int) -> void:
	arrow_count_label.text = str(count)
	pass
	
func update_bomb_count(count: int) -> void:
	bomb_count_label.text = str(count)
	pass

func _on_show_pause() -> void:
	# Hide the entire player HUD
	$Control.visible = false
	pass
	
func _on_hide_pause() -> void:
	# Show the entire player HUD
	$Control.visible = true
	pass



func _process(_delta: float) -> void:
	# OLD: update_skill_cooldowns(_delta) - removed with old skill system
	pass
	
	# OLD: God skill cooldown update - removed with old skill system
	#if god_skill_cooldown_timer > 0.0:
	#	god_skill_cooldown_timer -= _delta
	#	god_skill_cooldown_timer = max(0.0, god_skill_cooldown_timer)
	#	update_god_skill_cooldown(god_skill_cooldown_timer, 30.0)
	
	# Poll target HP every frame
	if current_target_id > 0 and target_health_bar and target_health_bar.visible:
		var target = PlayerManager.get_target()
		if target and is_instance_valid(target):
			if target.has_method("get_player_id") and target.get_player_id() == current_target_id:
				_update_target_hp(target.hp, target.max_hp)
	pass

#func _on_level_load_started() -> void:
#	# OLD: update_skill_labels - removed with old skill system
#	pass
	pass

# OLD SKILL SYSTEM FUNCTIONS - COMMENTED OUT (SkillsHUD removed)
# These functions were for the old Q/W/E skill buttons
# The new skill system uses the dynamically created skill_panel

#func update_skill_labels() -> void:
#	pass
#
#func show_skill_name(skill_key: String, skill_name: String) -> void:
#	pass
#
#func hide_skill_name(skill_key: String) -> void:
#	pass
#
#func update_charge_indicator(charge_progress: float, is_ready: bool) -> void:
#	pass

func show_kill_counter() -> void:
	wave_counter_active = true
	wave_label.text = "Wave 1"
	kill_count_label.text = "0 / 0"
	pass

func hide_kill_counter() -> void:
	wave_counter_active = false
	pass

func update_kill_counter(count: int) -> void:
	kill_count_label.text = str(count)
	pass

func update_wave_counter(wave_num: int, killed: int, total: int) -> void:
	wave_label.text = "Wave " + str(wave_num)
	kill_count_label.text = str(killed) + " / " + str(total)
	pass

# OLD SKILL SYSTEM COOLDOWN FUNCTIONS - COMMENTED OUT
# These were for the old Q/W/E skill buttons that have been removed
# The new skill system handles cooldowns in the skill_panel

#func update_skill_cooldowns(_delta: float) -> void:
#	pass
#
#func start_dash_cooldown() -> void:
#	pass
#
#func start_charge_dash_cooldown() -> void:
#	pass
#
#func start_spin_cooldown() -> void:
#	pass
#
#func is_dash_on_cooldown() -> bool:
#	return false
#
#func is_charge_dash_on_cooldown() -> bool:
#	return false
#
#func is_spin_on_cooldown() -> bool:
#	return false


# Quest tracker removed from HUD - now only in pause menu


func update_currency_display() -> void:
	if currency_label and currency_item:
		var amount = PlayerManager.INVENTORY_DATA.get_item_held_quantity(currency_item)
		currency_label.text = str(amount)
	pass


# ==================== TARGET HEALTH BAR ====================

var current_target_id: int = -1

func _setup_target_health_bar() -> void:
	"""Setup target health bar"""
	# Hide initially
	if target_health_bar:
		target_health_bar.visible = false
	
	# Connect invite button
	if target_invite_button and not target_invite_button.pressed.is_connected(_on_target_invite_pressed):
		target_invite_button.pressed.connect(_on_target_invite_pressed)
		print("[PlayerHud] Invite button signal connected")
	
	# Connect inspect button
	if target_inspect_button and not target_inspect_button.pressed.is_connected(_on_target_inspect_pressed):
		target_inspect_button.pressed.connect(_on_target_inspect_pressed)
		print("[PlayerHud] Inspect button signal connected")
	
	# Connect add friend button
	if target_add_friend_button and not target_add_friend_button.pressed.is_connected(_on_target_add_friend_pressed):
		target_add_friend_button.pressed.connect(_on_target_add_friend_pressed)
		print("[PlayerHud] Add Friend button signal connected")
	
	# Connect to PlayerManager target changed signal
	if not PlayerManager.target_changed.is_connected(_on_target_changed):
		PlayerManager.target_changed.connect(_on_target_changed)

func _on_target_changed(target: Node2D) -> void:
	"""Called when player target changes"""
	print("[PlayerHud] Target changed: ", target)
	
	if not target or not is_instance_valid(target):
		# No target - hide health bar
		print("[PlayerHud] No target - hiding health bar")
		if target_health_bar:
			target_health_bar.visible = false
		current_target_id = -1
		return
	
	# Check if target is a remote avatar (player)
	if not target.has_method("get_player_id"):
		# Not a player - hide health bar
		print("[PlayerHud] Target is not a player - hiding health bar")
		if target_health_bar:
			target_health_bar.visible = false
		current_target_id = -1
		return
	
	# Target is a player - show health bar
	current_target_id = target.get_player_id()
	var target_name = target.nickname if "nickname" in target else "Player"
	var target_hp = target.hp
	var target_max_hp = target.max_hp
	
	print("[PlayerHud] Target is player ID: ", current_target_id, " Name: ", target_name)
	_show_target_health_bar(target_name, target_hp, target_max_hp)

func _show_target_health_bar(player_name: String, hp: int, max_hp: int) -> void:
	"""Show target health bar at top of screen"""
	print("[PlayerHud] _show_target_health_bar() called for: ", player_name)
	if not target_health_bar:
		print("[PlayerHud] ERROR: target_health_bar is null!")
		return
	
	target_health_bar.visible = true
	
	# Update name
	if target_name_label:
		target_name_label.text = player_name
	
	# Update HP bar
	_update_target_hp(hp, max_hp)
	
	# Update invite button visibility
	print("[PlayerHud] About to call _update_target_invite_button()")
	_update_target_invite_button()
	print("[PlayerHud] _update_target_invite_button() completed")
	
	# Update add friend button visibility
	_update_target_add_friend_button()

func _update_target_hp(hp: int, max_hp: int) -> void:
	"""Update target HP bar"""
	if not target_hp_bar:
		return
	
	target_hp_bar.max_value = max_hp
	target_hp_bar.value = hp
	
	# Color based on HP percentage
	var hp_percent = float(hp) / float(max_hp)
	if hp_percent > 0.6:
		target_hp_bar.modulate = Color(0, 1, 0)  # Green
	elif hp_percent > 0.3:
		target_hp_bar.modulate = Color(1, 1, 0)  # Yellow
	else:
		target_hp_bar.modulate = Color(1, 0, 0)  # Red

func _update_target_invite_button() -> void:
	"""Update invite button visibility"""
	if not target_invite_button:
		print("[PlayerHud] ERROR: target_invite_button is null!")
		return
	
	# Show button if:
	# 1. We're NOT in a party (can invite to create new party)
	# 2. We're in a party AND we're the leader (can invite to existing party)
	# 3. Target is not already in our party
	var show_button = false
	
	var in_party = PartyManager.is_in_party()
	var is_leader = PartyManager.is_party_leader()
	
	print("[PlayerHud] Checking invite button visibility:")
	print("  - In party: ", in_party)
	print("  - Is leader: ", is_leader)
	print("  - Target player ID: ", current_target_id)
	
	if not in_party:
		# Not in party - can invite to create new party
		show_button = true
		print("  - Showing button: NOT in party (can create)")
	elif is_leader:
		# In party and leader - check if target is already in party
		var target_in_party = false
		for member in PartyManager.get_members():
			if member.get("id", -1) == current_target_id:
				target_in_party = true
				break
		
		show_button = not target_in_party
		print("  - Is leader, target in party: ", target_in_party)
		print("  - Showing button: ", show_button)
	else:
		print("  - Hiding button: Not leader")
	
	target_invite_button.visible = show_button
	print("[PlayerHud] Button visible: ", target_invite_button.visible)

func _on_target_invite_pressed() -> void:
	"""Invite button clicked"""
	print("[PlayerHud] Inviting player ID: ", current_target_id)
	
	# If not in party, create one first
	if not PartyManager.is_in_party():
		print("[PlayerHud] Creating party first...")
		PartyManager.create_party()
		# Wait a moment for party creation
		await get_tree().create_timer(0.5).timeout
	
	# Now invite the player
	PartyManager.invite_player(current_target_id)
	
	# Hide button after inviting
	target_invite_button.visible = false

func _update_target_add_friend_button() -> void:
	"""Update add friend button visibility"""
	if not target_add_friend_button:
		return
	
	# Default: hide button (safer - only show if we're SURE they're not a friend)
	# If friends list isn't loaded yet, hide the button to avoid confusion
	if GlobalFriendManager.friends.size() == 0:
		target_add_friend_button.visible = false
		return
	
	# Friends list is loaded - check if they're a friend
	if GlobalFriendManager.is_friend(current_target_id):
		target_add_friend_button.visible = false
	else:
		target_add_friend_button.visible = true

func update_target_hp_external(player_id: int, hp: int, max_hp: int) -> void:
	"""Called externally to update target HP (e.g., from network updates)"""
	if current_target_id == player_id and target_health_bar and target_health_bar.visible:
		_update_target_hp(hp, max_hp)


# ========================================
# FRIEND SYSTEM UI
# ========================================

func _setup_friend_system_ui() -> void:
	"""Setup friend system UI panels"""
	# Load and instantiate player inspect panel
	var inspect_scene = load("res://GUI/player_inspect/player_inspect_panel.tscn")
	if inspect_scene:
		player_inspect_panel = inspect_scene.instantiate()
		$Control.add_child(player_inspect_panel)
		print("[PlayerHud] Player inspect panel added")
	
	# Load and instantiate friend request popup
	var request_scene = load("res://GUI/friend_system/friend_request_popup.tscn")
	if request_scene:
		friend_request_popup = request_scene.instantiate()
		$Control.add_child(friend_request_popup)
		print("[PlayerHud] Friend request popup added")
	
	# Load and instantiate friend panel
	var friend_panel_scene = load("res://GUI/friend_system/friend_panel.tscn")
	if friend_panel_scene:
		friend_panel = friend_panel_scene.instantiate()
		$Control.add_child(friend_panel)
		print("[PlayerHud] Friend panel added")
	
	# Load and instantiate duel request popup
	var duel_popup_scene = load("res://GUI/duel_request_popup/duel_request_popup.tscn")
	if duel_popup_scene:
		duel_request_popup = duel_popup_scene.instantiate()
		if duel_request_popup:
			$Control.add_child(duel_request_popup)
			print("[PlayerHud] Duel request popup added - Type: ", duel_request_popup.get_class())
			if duel_request_popup.has_method("show_duel_request"):
				print("[PlayerHud] Duel popup has show_duel_request method")
			else:
				print("[PlayerHud] ERROR: Duel popup missing show_duel_request method!")
		else:
			print("[PlayerHud] ERROR: Failed to instantiate duel popup!")
	else:
		print("[PlayerHud] ERROR: Failed to load duel popup scene!")
	
	# Create friend button in top-right corner
	_create_friend_button()
	
	# Connect GlobalFriendManager signals
	if not GlobalFriendManager.friend_request_received.is_connected(_on_friend_request_received):
		GlobalFriendManager.friend_request_received.connect(_on_friend_request_received)
	if not GlobalFriendManager.friend_list_updated.is_connected(_on_friend_list_updated_hud):
		GlobalFriendManager.friend_list_updated.connect(_on_friend_list_updated_hud)
	
	# Connect NetworkManager duel signals
	if not NetworkManager.duel_request_received.is_connected(_on_duel_request_received):
		NetworkManager.duel_request_received.connect(_on_duel_request_received)
		print("[PlayerHud] Connected duel_request_received signal")
	if not NetworkManager.duel_accepted.is_connected(_on_duel_accepted):
		NetworkManager.duel_accepted.connect(_on_duel_accepted)
		print("[PlayerHud] Connected duel_accepted signal")
	if not NetworkManager.duel_declined.is_connected(_on_duel_declined):
		NetworkManager.duel_declined.connect(_on_duel_declined)
		print("[PlayerHud] Connected duel_declined signal")
	
	# Don't load here - GlobalFriendManager will load automatically when player_id is ready
	
	# Set panel references in target healthbar
	# Note: target_health_bar is the Control node, we need to wait for it to be ready
	# The panels will be accessed via the HUD's variables instead
	print("[PlayerHud] Friend system UI setup complete")

func _on_friend_request_received(requester_id: int, requester_name: String, expires_in: int):
	"""Show friend request popup"""
	if friend_request_popup:
		friend_request_popup.show_request(requester_id, requester_name, expires_in)

func _on_friend_list_updated_hud(_friends: Array):
	"""Friend list updated - refresh button visibility if target is shown"""
	if target_health_bar and target_health_bar.visible:
		_update_target_add_friend_button()


func _on_target_inspect_pressed() -> void:
	"""Inspect button clicked - show player info"""
	print("[PlayerHud] Inspecting player ID: ", current_target_id)
	
	# Request player info from server
	GlobalFriendManager.inspect_player(current_target_id, func(player_data):
		if player_data and player_inspect_panel:
			player_inspect_panel.show_player_info(player_data)
		else:
			print("[PlayerHud] Failed to get player data or panel not set")
	)

func _on_target_add_friend_pressed() -> void:
	"""Add Friend button clicked - send friend request"""
	print("[PlayerHud] Sending friend request to player ID: ", current_target_id)
	
	# Check if already friends
	if GlobalFriendManager.is_friend(current_target_id):
		print("[PlayerHud] Already friends with this player")
		return
	
	# Send friend request
	GlobalFriendManager.send_friend_request(current_target_id)
	
	# Hide button after sending
	if target_add_friend_button:
		target_add_friend_button.visible = false


# OLD SKILL SYSTEM FUNCTIONS - COMMENTED OUT
#func _remove_button_padding() -> void:
#	pass
#
#func _add_skill_icons() -> void:
#	pass
#
#func _create_god_skill_button() -> void:
#	pass
#
#func _update_god_skill_button() -> void:
#	pass
#
#func _on_god_skill_button_pressed() -> void:
#	pass
#
#func update_god_skill_cooldown(cooldown: float, max_cooldown: float) -> void:
#	pass
#
#func show_god_skill_unlocked(god_name: String, skill_name: String) -> void:
#	pass




# Icon buttons work automatically - no setup function needed


# ============================================
# SKILL PANEL SYSTEM
# ============================================

func _create_skill_panel() -> void:
	"""Create comprehensive skill panel with HP/MP bars"""
	var skill_panel_scene = load("res://GUI/skill_panel/skill_panel.tscn")
	if skill_panel_scene:
		skill_panel = skill_panel_scene.instantiate()
		$Control.add_child(skill_panel)
		print("[PlayerHud] Skill panel created successfully!")
	else:
		print("[PlayerHud] ERROR: Could not load skill panel scene!")


func _create_friend_button() -> void:
	"""Create friend list button in top-right corner"""
	var friend_button = TextureButton.new()
	friend_button.name = "FriendButton"
	
	# Load the friend icon
	var friend_icon = load("res://GUI/hud_icon_buttons/friends.png")
	if friend_icon:
		friend_button.texture_normal = friend_icon
		friend_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	# Position in top-right corner (next to other UI elements)
	friend_button.position = Vector2(1120, 10)  # Adjust as needed
	friend_button.custom_minimum_size = Vector2(48, 48)
	
	# Add tooltip
	friend_button.tooltip_text = "Friend List"
	
	# Connect button press
	friend_button.pressed.connect(_on_friend_button_pressed)
	
	# Add to Control node
	$Control.add_child(friend_button)
	print("[PlayerHud] Friend button created at position: ", friend_button.position)

func _on_friend_button_pressed() -> void:
	"""Friend button clicked - toggle friend panel"""
	if friend_panel:
		friend_panel.toggle_visibility()
		print("[PlayerHud] Friend panel toggled")


# ============================================
# TUTORIAL SYSTEM
# ============================================

func _check_tutorial():
	"""Check if we should show the tutorial dialogue"""
	if PlayerManager.get("show_tutorial") == true:
		print("[PlayerHud] Tutorial flag detected - showing tutorial dialogue")
		_show_tutorial_dialogue()
		# Clear the flag
		PlayerManager.set("show_tutorial", false)

func _show_tutorial_dialogue():
	"""Show the tutorial dialogue after character creation"""
	# Load tutorial dialogue scene
	var tutorial_scene = load("res://GUI/tutorial_dialogue.tscn")
	if not tutorial_scene:
		print("[PlayerHud] ERROR: Could not load tutorial_dialogue.tscn")
		return
	
	var tutorial_dialogue = tutorial_scene.instantiate()
	$Control.add_child(tutorial_dialogue)
	
	# Get god name and class
	var god_id = PlayerManager.get("tutorial_god_id")
	var player_class = PlayerManager.get("tutorial_class")
	var god_name = GodManager.get_god_name(god_id) if god_id else "Unknown God"
	
	print("[PlayerHud] Showing tutorial for %s - %s" % [god_name, player_class])
	
	# Show the dialogue
	tutorial_dialogue.show_tutorial_dialogue(god_name, player_class)
	
	# Connect completion signal
	tutorial_dialogue.dialogue_completed.connect(_on_tutorial_completed)

func _on_tutorial_completed():
	"""Called when tutorial dialogue is completed"""
	print("[PlayerHud] Tutorial dialogue completed")
	# Could add quest here or other post-tutorial actions

# ============================================
# PVP / DUEL SYSTEM UI
# ============================================

var player_interaction_menu: PlayerInteractionMenu = null

func _setup_pvp_ui():
	"""Setup PvP UI elements"""
	# Load and add player interaction menu
	var menu_scene = load("res://GUI/player_interaction_menu.tscn")
	if menu_scene:
		player_interaction_menu = menu_scene.instantiate()
		$Control.add_child(player_interaction_menu)
	
	# Duel request popup is already loaded in _setup_friend_system_ui()
	# No need to load it again here
	
	# Connect to PvPManager signals
	var pvp_manager = get_node_or_null("/root/PvPManager")
	if pvp_manager:
		pvp_manager.duel_requested.connect(_on_duel_requested)
		pvp_manager.duel_accepted.connect(_on_duel_started_notification)
		pvp_manager.duel_ended.connect(_on_duel_ended_notification)

func show_player_interaction_menu(player_id: int, player_name: String, position: Vector2):
	"""Show interaction menu for clicked player"""
	if player_interaction_menu:
		player_interaction_menu.show_menu(player_id, player_name, position)

func _on_duel_requested(from_player_id: int, to_player_id: int, from_name: String):
	"""Handle incoming duel request"""
	# Only show if request is for us
	if to_player_id == PlayerManager.player_id:
		if duel_request_popup:
			duel_request_popup.show_request(from_player_id, from_name)

func _on_pvp_duel_accepted(challenger_id: int):
	"""Handle PvP duel acceptance (old system)"""
	var pvp_manager = get_node_or_null("/root/PvPManager")
	if pvp_manager:
		pvp_manager.accept_duel(challenger_id, PlayerManager.player_id)

func _on_pvp_duel_declined(challenger_id: int):
	"""Handle PvP duel decline (old system)"""
	var pvp_manager = get_node_or_null("/root/PvPManager")
	if pvp_manager:
		pvp_manager.decline_duel(challenger_id, PlayerManager.player_id)

func _on_duel_started_notification(player1_id: int, player2_id: int):
	"""Show notification when duel starts"""
	if player1_id == PlayerManager.player_id or player2_id == PlayerManager.player_id:
		if notification_ui:
			notification_ui.show_notification("Duel Started! Fight!")

func _on_duel_ended_notification(player1_id: int, player2_id: int, winner_id: int):
	"""Show notification when duel ends"""
	if player1_id == PlayerManager.player_id or player2_id == PlayerManager.player_id:
		if notification_ui:
			if winner_id == PlayerManager.player_id:
				notification_ui.show_notification("Victory! You won the duel!")
			elif winner_id == -1:
				notification_ui.show_notification("Duel ended in a draw")
			else:
				notification_ui.show_notification("Defeat! You lost the duel")


# =========================
# DUEL SYSTEM HANDLERS
# =========================

func _on_duel_request_received(data: Dictionary):
	"""Handle incoming duel request"""
	var requester_id = data.get("requester_id", -1)
	var requester_name = data.get("requester_name", "Unknown")
	
	print("[PlayerHud] Duel request received from: ", requester_name, " (ID: ", requester_id, ")")
	print("[PlayerHud] Duel popup exists: ", duel_request_popup != null)
	print("[PlayerHud] Duel popup valid: ", is_instance_valid(duel_request_popup) if duel_request_popup else false)
	
	if duel_request_popup and is_instance_valid(duel_request_popup):
		print("[PlayerHud] Duel popup type: ", duel_request_popup.get_class())
		print("[PlayerHud] Duel popup script: ", duel_request_popup.get_script())
		
		# Try to call the method directly
		if duel_request_popup.has_method("show_duel_request"):
			print("[PlayerHud] Calling show_duel_request...")
			duel_request_popup.show_duel_request(requester_id, requester_name)
		else:
			print("[PlayerHud] ERROR: Method not found. Available methods:")
			for method in duel_request_popup.get_method_list():
				if not method.name.begins_with("_"):
					print("  - ", method.name)
	else:
		print("[PlayerHud] ERROR: Duel request popup not found or invalid!")

func _on_duel_accepted(data: Dictionary):
	"""Handle duel accepted"""
	var accepter_name = data.get("accepter_name", "Unknown")
	print("[PlayerHud] Duel accepted by: ", accepter_name)
	# Show notification
	_show_notification("Duel accepted! Prepare to fight!")

func _on_duel_declined(data: Dictionary):
	"""Handle duel declined"""
	var decliner_name = data.get("decliner_name", "Unknown")
	print("[PlayerHud] Duel declined by: ", decliner_name)
	# Show notification
	_show_notification("%s declined your duel request" % decliner_name)

func _show_notification(message: String):
	"""Show a temporary notification message"""
	# TODO: Create a proper notification system
	print("[Notification] ", message)
