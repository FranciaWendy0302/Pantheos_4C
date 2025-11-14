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

@onready var wave_label: Label = %WaveLabel
@onready var kill_count_label: Label = %CountLabel
@onready var currency_label: Label = %CurrencyLabel

@onready var quest_tracker: Control = $Control/QuestTracker
@onready var quest_title_label: Label = $Control/QuestTracker/VBoxContainer/QuestTitle
@onready var quest_steps_container: VBoxContainer = $Control/QuestTracker/VBoxContainer/StepsContainer

@onready var player_hp_bar: TextureProgressBar = $Control/PlayerHealthBar/TextureProgressBar
@onready var player_health_bar_control: Control = $Control/PlayerHealthBar

var wave_counter_active: bool = false
var currency_item: ItemData = preload("res://Items/gem.tres")

var dash_cooldown_timer: float = 0.0
var quest_update_delay: float = 0.0
var pending_quest_update: bool = false
var last_completed_step: String = ""
var show_completed_step: bool = false
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
	
	# Connect to quest updates
	if not QuestManager.quest_updated.is_connected(_on_quest_updated):
		QuestManager.quest_updated.connect(_on_quest_updated)
	
	# Initialize quest tracker
	call_deferred("update_quest_tracker")
	
	# Update currency display
	update_currency_display()
	
	pass

var previous_hp: int = 10
var hp_tween: Tween = null

func update_hp(_hp: int, _max_hp: int) -> void:
	# Update the new health bar
	if player_hp_bar:
		var hp_percent = clampf(float(_hp) / float(_max_hp) * 100, 0, 100)
		
		print("HP Updated: ", _hp, "/", _max_hp, " = ", hp_percent, "%")
		
		# Kill existing tween if running
		if hp_tween:
			hp_tween.kill()
		
		# Determine if taking damage or healing
		var is_damage = _hp < previous_hp
		var is_heal = _hp > previous_hp
		
		# Animate the health bar value change
		hp_tween = create_tween()
		hp_tween.set_ease(Tween.EASE_OUT)
		hp_tween.set_trans(Tween.TRANS_CUBIC)
		
		# Faster animation for damage, slower for healing
		var duration = 0.15 if is_damage else 0.3
		hp_tween.tween_property(player_hp_bar, "value", hp_percent, duration)
		
		# Visual feedback for damage or healing
		if is_damage:
			_flash_damage()
			_shake_health_bar()
		elif is_heal:
			_flash_heal()
			_pulse_health_bar()
		
		previous_hp = _hp
	else:
		print("ERROR: player_hp_bar is null!")
	pass

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
	
	# Hide minimap and skills HUD when died
	if minimap:
		minimap.visible = false
	if skills_hud:
		skills_hud.visible = false
	
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
	
	# Show minimap and skills HUD again after respawning
	if minimap:
		minimap.visible = true
	if skills_hud:
		skills_hud.visible = true
	
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
	update_skill_cooldowns(_delta)
	
	# Handle quest update delay (for showing completed step)
	if pending_quest_update:
		quest_update_delay -= _delta
		if quest_update_delay <= 0.0:
			pending_quest_update = false
			show_completed_step = false
			last_completed_step = ""
			update_quest_tracker()  # Now show the next step
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
	# Update charge indicator for E skill (spin attack)
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
	wave_counter_active = true
	wave_label.text = "Wave 1"
	kill_count_label.text = "0 / 0"
	update_quest_tracker()  # Refresh quest tracker to show wave counter
	pass

func hide_kill_counter() -> void:
	wave_counter_active = false
	update_quest_tracker()  # Refresh quest tracker to hide wave counter
	pass

func update_kill_counter(count: int) -> void:
	kill_count_label.text = str(count)
	pass

func update_wave_counter(wave_num: int, killed: int, total: int) -> void:
	wave_label.text = "Wave " + str(wave_num)
	kill_count_label.text = str(killed) + " / " + str(total)
	update_quest_tracker()  # Refresh quest tracker to update wave counter
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
			# Cooldown finished - re-enable button
			dash_cooldown_overlay.visible = false
			dash_cooldown_label.visible = false
			dash_skill_button.disabled = false
	else:
		# Ensure button is enabled when not on cooldown
		if dash_skill_button.disabled:
			dash_cooldown_overlay.visible = false
			dash_cooldown_label.visible = false
			dash_skill_button.disabled = false
	
	# Update charge dash cooldown (W)
	if charge_dash_cooldown_timer > 0.0:
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
			# Cooldown finished - re-enable button
			charge_dash_cooldown_overlay.visible = false
			charge_dash_cooldown_label.visible = false
			charge_dash_skill_button.disabled = false
	else:
		# Ensure button is enabled when not on cooldown
		if charge_dash_skill_button.disabled:
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
			# Cooldown finished - re-enable button
			spin_cooldown_overlay.visible = false
			spin_cooldown_label.visible = false
			spin_skill_button.disabled = false
	else:
		# Ensure button is enabled when not on cooldown
		if spin_skill_button.disabled:
			spin_cooldown_overlay.visible = false
			spin_cooldown_label.visible = false
			spin_skill_button.disabled = false

func start_dash_cooldown() -> void:
	dash_cooldown_timer = dash_cooldown_duration
	if dash_cooldown_overlay:
		dash_cooldown_overlay.visible = true
	if dash_cooldown_label:
		dash_cooldown_label.visible = true
	if dash_skill_button:
		dash_skill_button.disabled = true
	pass

func start_charge_dash_cooldown() -> void:
	charge_dash_cooldown_timer = charge_dash_cooldown_duration
	if charge_dash_cooldown_overlay:
		charge_dash_cooldown_overlay.visible = true
	if charge_dash_cooldown_label:
		charge_dash_cooldown_label.visible = true
	if charge_dash_skill_button:
		charge_dash_skill_button.disabled = true
	pass

func start_spin_cooldown() -> void:
	spin_cooldown_timer = spin_cooldown_duration
	if spin_cooldown_overlay:
		spin_cooldown_overlay.visible = true
	if spin_cooldown_label:
		spin_cooldown_label.visible = true
	if spin_skill_button:
		spin_skill_button.disabled = true
	pass

func is_dash_on_cooldown() -> bool:
	# Ensure timer is never negative
	dash_cooldown_timer = max(0.0, dash_cooldown_timer)
	return dash_cooldown_timer > 0.0

func is_charge_dash_on_cooldown() -> bool:
	# Ensure timer is never negative
	charge_dash_cooldown_timer = max(0.0, charge_dash_cooldown_timer)
	return charge_dash_cooldown_timer > 0.0

func is_spin_on_cooldown() -> bool:
	# Ensure timer is never negative
	spin_cooldown_timer = max(0.0, spin_cooldown_timer)
	return spin_cooldown_timer > 0.0


func _on_quest_updated(quest: Dictionary) -> void:
	# Check if a step was just completed
	var quest_data: Quest = QuestManager.find_quest_by_title(quest.title)
	if quest_data and quest.completed_steps.size() > 0:
		var latest_step = quest.completed_steps[quest.completed_steps.size() - 1]
		
		# Find the step name from quest data
		for step in quest_data.steps:
			if step.to_lower() == latest_step:
				# A step was just completed - show it with checkmark for 2 seconds
				last_completed_step = step.capitalize()
				show_completed_step = true
				quest_update_delay = 2.0
				pending_quest_update = true
				update_quest_tracker()  # Show the completed step immediately
				return
	
	# No step completed, just update normally
	update_quest_tracker()
	pass

func update_quest_tracker() -> void:
	if not quest_tracker:
		return
	
	# Clear existing steps
	for child in quest_steps_container.get_children():
		child.queue_free()
	
	# Find the first active (incomplete) quest
	var active_quest: Dictionary = {}
	var quest_data: Quest = null
	
	for q in QuestManager.current_quests:
		if not q.is_complete:
			active_quest = q
			quest_data = QuestManager.find_quest_by_title(q.title)
			break
	
	# If no active quest, hide tracker
	if active_quest.is_empty() or quest_data == null:
		quest_tracker.visible = false
		return
	
	# Show tracker and update content
	quest_tracker.visible = true
	quest_title_label.text = quest_data.title
	
	# Determine what to display
	var current_step_text = ""
	var is_showing_completed = false
	
	# If we're showing a completed step (with delay)
	if show_completed_step and last_completed_step != "":
		current_step_text = last_completed_step
		is_showing_completed = true
	else:
		# Find the current (first incomplete) step
		var found_current = false
		
		for step in quest_data.steps:
			var is_complete = active_quest.completed_steps.has(step.to_lower())
			if not is_complete and not found_current:
				# This is the current step to complete
				current_step_text = step.capitalize()
				found_current = true
				break
		
		# If all steps are complete but quest isn't marked complete yet
		if not found_current:
			current_step_text = "Complete!"
			is_showing_completed = true
	
	# Display the step
	if current_step_text != "":
		var step_label = Label.new()
		step_label.add_theme_font_override("font", load("res://GUI/fonts/m5x7.ttf"))
		step_label.add_theme_color_override("font_outline_color", Color.BLACK)
		step_label.add_theme_constant_override("outline_size", 2)
		
		if is_showing_completed:
			step_label.text = "[✓] " + current_step_text
			step_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))  # Green
		else:
			step_label.text = "[ ] " + current_step_text
			step_label.add_theme_color_override("font_color", Color(1, 1, 1))  # White
		
		quest_steps_container.add_child(step_label)
		
		# Add wave counter if active (for wave-based quests)
		if wave_counter_active:
			var wave_counter_label = Label.new()
			wave_counter_label.add_theme_font_override("font", load("res://GUI/fonts/m5x7.ttf"))
			wave_counter_label.add_theme_color_override("font_outline_color", Color.BLACK)
			wave_counter_label.add_theme_constant_override("outline_size", 2)
			wave_counter_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))
			wave_counter_label.text = "    " + wave_label.text + ": " + kill_count_label.text
			quest_steps_container.add_child(wave_counter_label)
	pass


func update_currency_display() -> void:
	if currency_label and currency_item:
		var amount = PlayerManager.INVENTORY_DATA.get_item_held_quantity(currency_item)
		currency_label.text = str(amount)
	pass
