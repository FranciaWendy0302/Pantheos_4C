extends CanvasLayer

@export var button_focus_audio: AudioStream = preload("res://title_scene/audio/menu_focus.wav")
@export var button_select_audio: AudioStream = preload("res://title_scene/audio/menu_select.wav")

var hearts: Array[HeartGUI] = []

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

@onready var skills_hud: Control = $Control/SkillsHUD
@onready var minimap: Control = $Control/Minimap

@onready var dash_skill_button: Button = $Control/SkillsHUD/HBoxContainer/DashSkill/SkillButton
@onready var dash_cooldown_overlay: ColorRect = $Control/SkillsHUD/HBoxContainer/DashSkill/SkillButton/CooldownOverlay
@onready var dash_cooldown_label: Label = $Control/SkillsHUD/HBoxContainer/DashSkill/SkillButton/CooldownLabel

@onready var charge_dash_skill_button: Button = $Control/SkillsHUD/HBoxContainer/ChargeDashSkill/SkillButton
@onready var charge_dash_cooldown_overlay: ColorRect = $Control/SkillsHUD/HBoxContainer/ChargeDashSkill/SkillButton/CooldownOverlay
@onready var charge_dash_cooldown_label: Label = $Control/SkillsHUD/HBoxContainer/ChargeDashSkill/SkillButton/CooldownLabel

@onready var spin_skill_button: Button = $Control/SkillsHUD/HBoxContainer/SpinSkill/SkillButton
@onready var spin_cooldown_overlay: ColorRect = $Control/SkillsHUD/HBoxContainer/SpinSkill/SkillButton/CooldownOverlay
@onready var spin_cooldown_label: Label = $Control/SkillsHUD/HBoxContainer/SpinSkill/SkillButton/CooldownLabel

@onready var dash_skill_name_label: Label = $Control/SkillsHUD/HBoxContainer/DashSkill/SkillNameLabel
@onready var charge_dash_skill_name_label: Label = $Control/SkillsHUD/HBoxContainer/ChargeDashSkill/SkillNameLabel
@onready var spin_skill_name_label: Label = $Control/SkillsHUD/HBoxContainer/SpinSkill/SkillNameLabel
@onready var charge_indicator: ProgressBar = $Control/SkillsHUD/HBoxContainer/SpinSkill/SkillButton/ChargeIndicator

@onready var kill_counter: Control = $Control/KillCounter
@onready var kill_counter_toggle_arrow: Button = $Control/KillCounter/ToggleArrow
@onready var wave_label: Label = %WaveLabel
@onready var kill_count_label: Label = %CountLabel

var dash_cooldown_timer: float = 0.0
var dash_cooldown_duration: float = 3.0
var charge_dash_cooldown_timer: float = 0.0
var charge_dash_cooldown_duration: float = 10.0
var spin_cooldown_timer: float = 0.0
var spin_cooldown_duration: float = 5.0


func _ready():
	for child in $Control/HFlowContainer.get_children():
		if child is HeartGUI:
			hearts.append(child)
			child.visible = false
	
	hide_game_over_screen()
	continue_button.focus_entered.connect(play_audio.bind(button_focus_audio))
	continue_button.pressed.connect(load_game)
	title_button.focus_entered.connect(play_audio.bind(button_focus_audio))
	title_button.pressed.connect(title_screen)
	LevelManager.level_load_started.connect(hide_game_over_screen)
	
	hide_boss_health()
	
	update_ability_ui(0)
	PauseMenu.shown.connect(_on_show_pause)
	PauseMenu.hidden.connect(_on_hide_pause)
	
	# Initialize skill cooldown UI
	dash_cooldown_overlay.visible = false
	dash_cooldown_label.visible = false
	dash_skill_button.disabled = false
	
	charge_dash_cooldown_overlay.visible = false
	charge_dash_cooldown_label.visible = false
	charge_dash_skill_button.disabled = false
	
	spin_cooldown_overlay.visible = false
	spin_cooldown_label.visible = false
	spin_skill_button.disabled = false
	
	# Update skill labels when level loads (after class is selected)
	LevelManager.level_load_started.connect(_on_level_load_started)
	
	# Update skill labels based on class
	call_deferred("update_skill_labels")
	
	# Connect kill counter toggle arrow button
	if kill_counter_toggle_arrow:
		kill_counter_toggle_arrow.pressed.connect(_on_kill_counter_toggle_arrow_pressed)
	
	pass
	
func update_hp(_hp: int, _max_hp: int) -> void:
	update_max_hp(_max_hp)
	for i in _max_hp:
		update_heart(i, _hp)
		pass
	pass

func update_heart(_index: int, _hp: int) -> void:
	var _value: int = clampi(_hp - _index * 2, 0, 2)
	hearts[_index].value = _value
	pass
	
func update_max_hp(_max_hp: int) -> void:
	var _heart_count: int = roundi(_max_hp * 0.5)
	for i in hearts.size():
		if i < _heart_count:
			hearts[i].visible = true
		else: 
			hearts[i].visible = false
	pass
	
func show_game_over_screen() -> void:
	game_over.visible = true
	game_over.mouse_filter = Control.MOUSE_FILTER_STOP
	
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
	
func load_game() -> void:
	play_audio(button_select_audio)
	await fade_to_black()
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
	abilities.visible = false
	skills_hud.visible = false
	minimap.visible = false
	pass
	
func _on_hide_pause() -> void:
	abilities.visible = true
	skills_hud.visible = true
	minimap.visible = true
	pass

func _on_kill_counter_toggle_arrow_pressed() -> void:
	# Toggle panel visibility (arrow stays visible)
	var panel = kill_counter.get_node_or_null("Panel")
	if panel:
		panel.visible = !panel.visible
		# Update arrow text and position based on panel visibility
		if panel.visible:
			kill_counter_toggle_arrow.text = "<"
			# Move arrow to right side of panel
			kill_counter_toggle_arrow.anchors_preset = Control.PRESET_RIGHT_WIDE
			kill_counter_toggle_arrow.offset_left = -30.0
			kill_counter_toggle_arrow.offset_right = -10.0
		else:
			kill_counter_toggle_arrow.text = ">"
			# Move arrow to very left side
			kill_counter_toggle_arrow.anchors_preset = Control.PRESET_LEFT_WIDE
			kill_counter_toggle_arrow.offset_left = 0.0
			kill_counter_toggle_arrow.offset_right = 20.0
	pass

func _process(_delta: float) -> void:
	update_skill_cooldowns(_delta)
	pass

func _on_level_load_started() -> void:
	# Update skill labels when level loads (class should be set by now)
	call_deferred("update_skill_labels")
	pass

func update_skill_labels() -> void:
	# Remove skill names - buttons only show Q, W, E labels
	dash_skill_button.text = ""
	charge_dash_skill_button.text = ""
	spin_skill_button.text = ""
	
	# Hide skill name labels initially
	dash_skill_name_label.visible = false
	charge_dash_skill_name_label.visible = false
	spin_skill_name_label.visible = false
	charge_indicator.visible = false
	
	# Hide kill counter initially
	kill_counter.visible = false
	pass

func show_skill_name(skill_key: String, skill_name: String) -> void:
	# Show skill name label when skill is activated
	match skill_key:
		"Q":
			dash_skill_name_label.text = skill_name
			dash_skill_name_label.visible = true
		"W":
			charge_dash_skill_name_label.text = skill_name
			charge_dash_skill_name_label.visible = true
		"E":
			spin_skill_name_label.text = skill_name
			spin_skill_name_label.visible = true
	pass

func hide_skill_name(skill_key: String) -> void:
	# Hide skill name label when skill ends
	match skill_key:
		"Q":
			dash_skill_name_label.visible = false
		"W":
			charge_dash_skill_name_label.visible = false
		"E":
			spin_skill_name_label.visible = false
			charge_indicator.visible = false
	pass

func update_charge_indicator(charge_progress: float, is_ready: bool) -> void:
	# Update charge indicator for E skill (big arrow)
	if PlayerManager.selected_class == "Archer":
		charge_indicator.value = charge_progress
		charge_indicator.visible = true
		
		# Change color to green when ready, orange when charging
		var fill_style = charge_indicator.get_theme_stylebox("fill")
		if fill_style:
			if is_ready:
				fill_style.bg_color = Color(0, 1, 0, 0.8)  # Green when ready
			else:
				fill_style.bg_color = Color(1, 0.5, 0, 0.8)  # Orange when charging
	pass

func show_kill_counter() -> void:
	kill_counter.visible = true
	var panel = kill_counter.get_node_or_null("Panel")
	if panel:
		panel.visible = true
	wave_label.visible = true
	kill_count_label.text = "0 / 0"
	# Update arrow to show "<" and position on right side when visible
	if kill_counter_toggle_arrow:
		kill_counter_toggle_arrow.text = "<"
		kill_counter_toggle_arrow.anchors_preset = Control.PRESET_RIGHT_WIDE
		kill_counter_toggle_arrow.offset_left = -30.0
		kill_counter_toggle_arrow.offset_right = -10.0
	pass

func hide_kill_counter() -> void:
	var panel = kill_counter.get_node_or_null("Panel")
	if panel:
		panel.visible = false
	# Update arrow to show ">" and move to very left side when hidden
	if kill_counter_toggle_arrow:
		kill_counter_toggle_arrow.text = ">"
		kill_counter_toggle_arrow.anchors_preset = Control.PRESET_LEFT_WIDE
		kill_counter_toggle_arrow.offset_left = 0.0
		kill_counter_toggle_arrow.offset_right = 20.0
	# Keep kill_counter visible so the arrow stays visible
	pass

func update_kill_counter(count: int) -> void:
	kill_count_label.text = str(count)
	pass

func update_wave_counter(wave_num: int, killed: int, total: int) -> void:
	wave_label.text = "Wave " + str(wave_num)
	kill_count_label.text = str(killed) + " / " + str(total)
	pass

func update_skill_cooldowns(_delta: float) -> void:
	# Update dash cooldown (Q)
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= _delta
		dash_cooldown_timer = max(0.0, dash_cooldown_timer)
		
		if dash_cooldown_timer > 0.0:
			dash_cooldown_overlay.visible = true
			dash_cooldown_label.visible = true
			dash_cooldown_label.text = "%.1f" % dash_cooldown_timer
			dash_skill_button.disabled = true
			
			# Update overlay alpha based on cooldown progress
			var progress: float = dash_cooldown_timer / dash_cooldown_duration
			dash_cooldown_overlay.color.a = 0.3 + (0.3 * progress)
		else:
			dash_cooldown_overlay.visible = false
			dash_cooldown_label.visible = false
			dash_skill_button.disabled = false
	
	# Update charge dash cooldown (W)
	charge_dash_cooldown_timer -= _delta
	charge_dash_cooldown_timer = max(0.0, charge_dash_cooldown_timer)
	
	if charge_dash_cooldown_timer > 0.0:
		charge_dash_cooldown_overlay.visible = true
		charge_dash_cooldown_label.visible = true
		charge_dash_cooldown_label.text = "%.1f" % charge_dash_cooldown_timer
		charge_dash_skill_button.disabled = true
		
		# Update overlay alpha based on cooldown progress
		var progress: float = charge_dash_cooldown_timer / charge_dash_cooldown_duration
		charge_dash_cooldown_overlay.color.a = 0.3 + (0.3 * progress)
	else:
		charge_dash_cooldown_overlay.visible = false
		charge_dash_cooldown_label.visible = false
		charge_dash_skill_button.disabled = false
	
	# Update spin cooldown (E)
	if spin_cooldown_timer > 0.0:
		spin_cooldown_timer -= _delta
		spin_cooldown_timer = max(0.0, spin_cooldown_timer)
		
		if spin_cooldown_timer > 0.0:
			spin_cooldown_overlay.visible = true
			spin_cooldown_label.visible = true
			spin_cooldown_label.text = "%.1f" % spin_cooldown_timer
			spin_skill_button.disabled = true
			
			# Update overlay alpha based on cooldown progress
			var progress: float = spin_cooldown_timer / spin_cooldown_duration
			spin_cooldown_overlay.color.a = 0.3 + (0.3 * progress)
		else:
			spin_cooldown_overlay.visible = false
			spin_cooldown_label.visible = false
			spin_skill_button.disabled = false
	
	pass

func start_dash_cooldown() -> void:
	dash_cooldown_timer = dash_cooldown_duration
	dash_cooldown_overlay.visible = true
	dash_cooldown_label.visible = true
	dash_skill_button.disabled = true
	pass

func start_charge_dash_cooldown() -> void:
	charge_dash_cooldown_timer = charge_dash_cooldown_duration
	charge_dash_cooldown_overlay.visible = true
	charge_dash_cooldown_label.visible = true
	charge_dash_skill_button.disabled = true
	pass

func start_spin_cooldown() -> void:
	spin_cooldown_timer = spin_cooldown_duration
	spin_cooldown_overlay.visible = true
	spin_cooldown_label.visible = true
	spin_skill_button.disabled = true
	pass

func is_dash_on_cooldown() -> bool:
	return dash_cooldown_timer > 0.0

func is_charge_dash_on_cooldown() -> bool:
	return charge_dash_cooldown_timer > 0.0

func is_spin_on_cooldown() -> bool:
	return spin_cooldown_timer > 0.0
