extends Level

const DARK_WIZARD_SCRIPT = preload("res://Levels/Dungeon1/dark_wizard/script/dark_wizard_boss.gd")

var boss_wave: int = 0
var boss_waves_hp: Array[int] = [8, 15, 25]
var boss_wave_names: Array[String] = ["Dark Wizard", "Enhanced Dark Wizard", "Dark Lord"]
var boss_wave_completing: bool = false
var boss_waves_completed: bool = false
var current_boss: DarkWizardBoss = null
var boss_damage_dealt: int = 0

func _ready() -> void:
	super._ready()
	
	# Wait a moment for everything to initialize
	await get_tree().create_timer(0.5).timeout
	
	# Start the first boss wave
	start_boss_wave()
	pass

func start_boss_wave() -> void:
	if boss_wave >= boss_waves_hp.size():
		# All waves complete
		boss_waves_completed = true
		complete_boss_waves()
		return
	
	# Get the existing DarkWizardBoss node from the scene
	# The boss already exists in 04.tscn with all beams positioned correctly
	var boss_node = get_node_or_null("DarkWizardBoss")
	if not boss_node or not is_instance_valid(boss_node):
		# Boss doesn't exist in scene, create it (shouldn't happen in 04.tscn)
		boss_node = DARK_WIZARD_SCRIPT.new()
		boss_node.name = "DarkWizardBoss"
		add_child(boss_node)
		
		# Set up the boss structure (minimal setup)
		_setup_boss_structure(boss_node)
	
	# Configure boss HP based on wave
	var boss_hp = boss_waves_hp[boss_wave]
	boss_node.max_hp = boss_hp
	boss_node.hp = boss_hp
	current_boss = boss_node
	
	# Make sure boss is visible and enabled
	boss_node.visible = true
	if boss_node.has_method("enable_hit_boxes"):
		boss_node.enable_hit_boxes()
	
	# Show and update boss health bar for this wave
	var boss_name = boss_wave_names[boss_wave]
	PlayerHud.show_boss_health(boss_name)
	PlayerHud.update_boss_health(boss_hp, boss_hp)
	
	# Show kill counter for boss waves
	PlayerHud.show_kill_counter()
	PlayerHud.update_wave_counter(boss_wave + 1, boss_damage_dealt, boss_hp)
	
	# Reset damage counter for this wave
	boss_damage_dealt = 0
	previous_boss_hp = boss_hp
	
	# Don't reposition boss - use its position from the scene file
	# The boss and its beams are already positioned correctly in 04.tscn
	# All beam positions are preserved as placed in the scene
	
	# Start monitoring boss HP
	_start_boss_monitoring(boss_node)
	pass

func _setup_boss_structure(boss: Node2D) -> void:
	# Create BossNode
	var boss_node = Node2D.new()
	boss_node.name = "BossNode"
	boss.add_child(boss_node)
	
	# Create PositionTargets (boss needs at least one position)
	var position_targets = Node2D.new()
	position_targets.name = "PositionTargets"
	position_targets.visible = false
	boss.add_child(position_targets)
	
	# Add a position marker
	var pos_marker = Sprite2D.new()
	position_targets.add_child(pos_marker)
	pos_marker.global_position = boss.global_position
	
	# Create BeamAttacks only if it doesn't exist
	# (In 04.tscn, BeamAttacks already exists with positioned beams, so don't recreate it)
	if not boss.has_node("BeamAttacks"):
		var beam_attacks = Node2D.new()
		beam_attacks.name = "BeamAttacks"
		boss.add_child(beam_attacks)
	
	# Create minimal required nodes (HurtBox, HitBox, AnimationPlayers, etc.)
	# These are required by the boss script
	var hit_box = preload("res://GeneralNodes/HitBox/hit_box.tscn").instantiate()
	boss_node.add_child(hit_box)
	
	var hurt_box = preload("res://GeneralNodes/HurtBox/hurt_box.tscn").instantiate()
	hurt_box.damage = 1
	boss_node.add_child(hurt_box)
	
	# Create minimal animation players with empty animations
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	boss_node.add_child(anim_player)
	
	# Create empty animations using AnimationLibrary
	var anim_library = AnimationLibrary.new()
	
	var idle_anim = Animation.new()
	idle_anim.length = 1.0
	idle_anim.loop_mode = Animation.LOOP_LINEAR
	anim_library.add_animation("idle", idle_anim)
	
	var appear_anim = Animation.new()
	appear_anim.length = 0.5
	anim_library.add_animation("appear", appear_anim)
	
	var disappear_anim = Animation.new()
	disappear_anim.length = 0.5
	anim_library.add_animation("disappear", disappear_anim)
	
	var cast_anim = Animation.new()
	cast_anim.length = 1.0
	anim_library.add_animation("cast_spell", cast_anim)
	
	var destroy_anim = Animation.new()
	destroy_anim.length = 1.0
	anim_library.add_animation("destroy", destroy_anim)
	
	anim_player.add_animation_library("", anim_library)
	
	var anim_damaged = AnimationPlayer.new()
	anim_damaged.name = "AnimationPlayer_Damaged"
	boss_node.add_child(anim_damaged)
	
	var damaged_anim_library = AnimationLibrary.new()
	var damaged_anim = Animation.new()
	damaged_anim.length = 0.3
	damaged_anim_library.add_animation("damaged", damaged_anim)
	
	var default_anim = Animation.new()
	default_anim.length = 0.1
	damaged_anim_library.add_animation("default", default_anim)
	
	anim_damaged.add_animation_library("", damaged_anim_library)
	
	# Create cloak sprite with animation player
	var cloak_sprite = Sprite2D.new()
	cloak_sprite.name = "CloakSprite"
	boss_node.add_child(cloak_sprite)
	
	var cloak_anim = AnimationPlayer.new()
	cloak_anim.name = "AnimationPlayer"
	cloak_sprite.add_child(cloak_anim)
	
	var cloak_anim_library = AnimationLibrary.new()
	var down_anim = Animation.new()
	down_anim.length = 1.0
	down_anim.loop_mode = Animation.LOOP_LINEAR
	cloak_anim_library.add_animation("down", down_anim)
	
	var up_anim = Animation.new()
	up_anim.length = 1.0
	up_anim.loop_mode = Animation.LOOP_LINEAR
	cloak_anim_library.add_animation("up", up_anim)
	
	var side_anim = Animation.new()
	side_anim.length = 1.0
	side_anim.loop_mode = Animation.LOOP_LINEAR
	cloak_anim_library.add_animation("side", side_anim)
	
	cloak_anim.add_animation_library("", cloak_anim_library)
	
	# Create audio player
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "AudioStreamPlayer2D"
	boss_node.add_child(audio_player)
	pass

var previous_boss_hp: int = 0

func _start_boss_monitoring(boss: DarkWizardBoss) -> void:
	# Initialize previous HP for tracking damage
	previous_boss_hp = boss.hp
	
	# Monitor boss HP to detect defeat and track damage
	var check_timer = Timer.new()
	check_timer.name = "BossMonitor"
	check_timer.wait_time = 0.1
	check_timer.one_shot = false
	check_timer.autostart = true
	boss.add_child(check_timer)
	
	check_timer.timeout.connect(func():
		if not is_instance_valid(boss):
			check_timer.queue_free()
			return
		
		# Track damage dealt
		if boss.hp < previous_boss_hp:
			var damage = previous_boss_hp - boss.hp
			boss_damage_dealt += damage
			previous_boss_hp = boss.hp
			
			# Update wave counter with damage dealt
			var boss_max_hp = boss_waves_hp[boss_wave]
			PlayerHud.update_wave_counter(boss_wave + 1, boss_damage_dealt, boss_max_hp)
		
		if boss.hp <= 0:
			# Boss defeated
			_on_boss_defeated()
			check_timer.queue_free()
	)
	pass

func _on_boss_defeated() -> void:
	if boss_waves_completed or boss_wave_completing:
		return
	
	boss_wave_completing = true
	
	# Wait a moment
	await get_tree().create_timer(2.0).timeout
	
	boss_wave += 1
	
	if boss_wave < boss_waves_hp.size():
		# Next wave - reset boss HP instead of destroying it
		# This preserves the beam positions from the scene file
		if is_instance_valid(current_boss):
			# Reset boss HP and make it visible again
			var boss_hp = boss_waves_hp[boss_wave]
			current_boss.max_hp = boss_hp
			current_boss.hp = boss_hp
			current_boss.visible = true
			if current_boss.has_method("enable_hit_boxes"):
				current_boss.enable_hit_boxes()
			
			# Show and update boss health bar for the new wave
			var boss_name = boss_wave_names[boss_wave]
			PlayerHud.show_boss_health(boss_name)
			PlayerHud.update_boss_health(boss_hp, boss_hp)
			
			# Reset damage counter and update wave counter
			boss_damage_dealt = 0
			previous_boss_hp = boss_hp
			PlayerHud.update_wave_counter(boss_wave + 1, boss_damage_dealt, boss_hp)
			
			# Restart monitoring for the new wave
			_start_boss_monitoring(current_boss)
		
		# Wait before starting next wave
		await get_tree().create_timer(2.0).timeout
		boss_wave_completing = false
		# Don't call start_boss_wave() again - we already reset the boss above
	else:
		# All waves complete
		boss_wave_completing = false
		boss_waves_completed = true
		complete_boss_waves()
	pass

func complete_boss_waves() -> void:
	# Hide boss health bar and kill counter
	PlayerHud.hide_boss_health()
	PlayerHud.hide_kill_counter()
	
	# Hide any UI elements if needed
	if is_instance_valid(current_boss):
		current_boss.queue_free()
		current_boss = null
	
	# Show completion dialog
	var complete_dialogs: Array[DialogItem] = []
	
	var dialog1: DialogText = DialogText.new()
	dialog1.npc_info = preload("res://npc/00_npcs/tutorial_narrator.tres")
	dialog1.text = "Incredible! You've defeated all the Dark Wizard bosses!"
	complete_dialogs.append(dialog1)
	
	var dialog2: DialogText = DialogText.new()
	dialog2.npc_info = preload("res://npc/00_npcs/tutorial_narrator.tres")
	dialog2.text = "You've completed the tutorial!"
	complete_dialogs.append(dialog2)
	
	DialogSystem.show_dialog(complete_dialogs)
	await DialogSystem.finished
	
	# Fade out the game
	await SceneTransition.fade_out()
	
	# Create and show thank you message
	_show_thank_you_message()
	
	# Wait a moment to show the message
	await get_tree().create_timer(3.0).timeout
	
	# Exit the game
	get_tree().quit()
	pass

func _show_thank_you_message() -> void:
	# Create a CanvasLayer for the thank you message
	var thank_you_layer = CanvasLayer.new()
	thank_you_layer.name = "ThankYouLayer"
	get_tree().root.add_child(thank_you_layer)
	
	# Create a Control node to hold the label
	var control = Control.new()
	control.name = "Control"
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	thank_you_layer.add_child(control)
	
	# Create the label
	var label = Label.new()
	label.name = "ThankYouLabel"
	label.text = "Thank you for playing Pantheos, Adventurer"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Set label to center of screen
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -200
	label.offset_top = -15
	label.offset_right = 200
	label.offset_bottom = 15
	
	# Style the label
	var font = preload("res://GUI/fonts/m5x7.ttf")
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 3)
	
	control.add_child(label)
	
	# Fade in the label
	var tween = get_tree().create_tween()
	label.modulate.a = 0.0
	tween.tween_property(label, "modulate:a", 1.0, 1.0)
	pass
