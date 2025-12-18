class_name DarkWizardBoss extends Node2D

const ENERGY_EXPLOSION_SCENE: PackedScene = preload("res://Levels/Dungeon1/dark_wizard/energy_explosion.tscn")
const ENERGY_BALL_SCENE: PackedScene = preload("res://Levels/Dungeon1/dark_wizard/dark_orb.tscn")

@export var max_hp: int = 10
var hp: int = 10

var audio_hurt: AudioStream = preload("res://Levels/Dungeon1/dark_wizard/audio/boss_hurt.wav")
var audio_shoot: AudioStream = preload("res://Levels/Dungeon1/dark_wizard/audio/boss_fireball.wav")

var current_position: int = 0
var positions: Array[Vector2]
var beam_attacks: Array[BeamAttack]

var damage_count: int = 0

var animation_player: AnimationPlayer
var animation_player_damaged: AnimationPlayer
var cloak_animation_player: AnimationPlayer

var audio: AudioStreamPlayer2D
var boss_node: Node2D
var persistent_data_handler: PersistentDataHandler
var hurt_box: HurtBox
var hit_box: HitBox

var hand_01: Sprite2D
var hand_02: Sprite2D
var hand_01_up: Sprite2D
var hand_02_up: Sprite2D
var hand_01_side: Sprite2D
var hand_02_side: Sprite2D
var door_block: TileMapLayer

func _ready() -> void:
	# Initialize node references safely
	boss_node = get_node_or_null("BossNode")
	animation_player = boss_node.get_node_or_null("AnimationPlayer") if boss_node else null
	animation_player_damaged = boss_node.get_node_or_null("AnimationPlayer_Damaged") if boss_node else null
	cloak_animation_player = boss_node.get_node_or_null("CloakSprite/AnimationPlayer") if boss_node else null
	audio = boss_node.get_node_or_null("AudioStreamPlayer2D") if boss_node else null
	hurt_box = boss_node.get_node_or_null("HurtBox") if boss_node else null
	hit_box = boss_node.get_node_or_null("HitBox") if boss_node else null
	
	hand_01 = boss_node.get_node_or_null("CloakSprite/Hand01") if boss_node else null
	hand_02 = boss_node.get_node_or_null("CloakSprite/Hand02") if boss_node else null
	hand_01_up = boss_node.get_node_or_null("CloakSprite/Hand01_UP") if boss_node else null
	hand_02_up = boss_node.get_node_or_null("CloakSprite/Hand02_UP") if boss_node else null
	hand_01_side = boss_node.get_node_or_null("CloakSprite/Hand01_SIDE") if boss_node else null
	hand_02_side = boss_node.get_node_or_null("CloakSprite/Hand02_SIDE") if boss_node else null
	
	persistent_data_handler = get_node_or_null("PersistentDataHandler")
	door_block = get_node_or_null("../DoorBlock")
	
	# Check if in tutorial mode (no persistent data handler or door_block)
	if persistent_data_handler:
		persistent_data_handler.get_value()
		if persistent_data_handler.value == true:
			if door_block:
				door_block.enabled = false
			queue_free()
			return
		
	randomize()
	hp = max_hp
	
	# Only show boss health if we're NOT in a boss wave system (wave system handles it)
	# Check if parent level has a boss wave system
	var level = get_tree().current_scene
	if not level or not level.has_method("start_boss_wave"):
		# Not in a boss wave system, show the health bar ourselves
		PlayerHud.show_boss_health("Dark Wizard")
	
	if hit_box:
		hit_box.Damaged.connect(damage_taken)
	
	# Initialize positions
	if has_node("PositionTargets"):
		for c in $PositionTargets.get_children():
			positions.append(c.global_position)
		$PositionTargets.visible = false
	
	# If no positions set, create a default one at current position
	if positions.is_empty():
		positions.append(global_position)
	
	# Initialize beam attacks
	if has_node("BeamAttacks"):
		for b in $BeamAttacks.get_children():
			beam_attacks.append(b)
	
	teleport(0)
	
func _process(_delta: float) -> void:
	# Update hand positions if they exist
	if hand_01_up and hand_01:
		hand_01_up.position = hand_01.position
		hand_01_up.frame = hand_01.frame + 4
	if hand_02_up and hand_02:
		hand_02_up.position = hand_02.position
		hand_02_up.frame = hand_02.frame + 4
	if hand_01_side and hand_01:
		hand_01_side.position = hand_01.position
		hand_01_side.frame = hand_01.frame + 8
	if hand_02_side and hand_02:
		hand_02_side.position = hand_02.position
		hand_02_side.frame = hand_02.frame + 12
	pass
	
func teleport(_location: int) -> void:
	if animation_player:
		animation_player.play("disappear")
	enable_hit_boxes(false)
	damage_count = 0
	
	# Check if tutorial mode allows orb shooting
	var can_shoot_orb = true
	if has_meta("can_shoot_orb"):
		can_shoot_orb = get_meta("can_shoot_orb")
	
	if hp < max_hp and can_shoot_orb:
		shoot_orb()
	
	await get_tree().create_timer(1).timeout
	
	if boss_node and _location < positions.size():
		boss_node.global_position = positions[_location]
	current_position = _location
	update_animation()
	if animation_player:
		animation_player.play("appear")
		if animation_player.has_animation("appear"):
			await animation_player.animation_finished
	idle()
	pass

func idle() -> void:
	enable_hit_boxes(true)
	
	if animation_player and randf() <= float(hp) / float(max_hp):
		if animation_player.has_animation("idle"):
			animation_player.play("idle")  # assume this loops; do not await finished
		await get_tree().create_timer(0.8).timeout  # small delay before next teleport
		if hp < 1:
			return
		
	# Check if tutorial mode allows beam attacks
	var can_use_beam = true
	if has_meta("can_use_beam"):
		can_use_beam = get_meta("can_use_beam")
	
	if damage_count < 1 and can_use_beam and beam_attacks.size() > 0:
		energy_beam_attack()
		if animation_player and animation_player.has_animation("cast_spell"):
			animation_player.play("cast_spell")
			await animation_player.animation_finished
	
	if hp < 1:
			return
	
	var _t: int = current_position
	if positions.size() > 1:
		while _t == current_position:
			_t = randi_range(0, positions.size() - 1)
	else:
		_t = current_position
	teleport(_t)
	pass
	
func update_animation() -> void:
	if boss_node:
		boss_node.scale = Vector2(1, 1)
	
	if hand_01:
		hand_01.visible = false
	if hand_02:
		hand_02.visible = false
	if hand_01_up:
		hand_01_up.visible = false
	if hand_02_up:
		hand_02_up.visible = false
	if hand_01_side:
		hand_01_side.visible = false
	if hand_02_side:
		hand_02_side.visible = false
	
	if cloak_animation_player:
		if current_position == 0:
			if cloak_animation_player.has_animation("down"):
				cloak_animation_player.play("down")
			if hand_01:
				hand_01.visible = true
			if hand_02:
				hand_02.visible = true
		elif current_position == 2:
			if cloak_animation_player.has_animation("up"):
				cloak_animation_player.play("up")
			if hand_01_up:
				hand_01_up.visible = true
			if hand_02_up:
				hand_02_up.visible = true
		else:
			if cloak_animation_player.has_animation("side"):
				cloak_animation_player.play("side")
			if hand_01_side:
				hand_01_side.visible = true
			if hand_02_side:
				hand_02_side.visible = true
			if current_position == 1 and boss_node:
				boss_node.scale = Vector2(-1, 1)
	pass

func energy_beam_attack() -> void:
	var _b: Array[int]
	match current_position:
		0, 2:
			if current_position == 0:
				_b.append(0)
				_b.append(randi_range(1, 2))
			else:
				_b.append(2)
				_b.append(randi_range(0, 1))
			if hp < 5:
				_b.append(randi_range(3, 5))
		1, 3:
			if current_position == 3:
				_b.append(5)
				_b.append(randi_range(3, 4))
			else:
				_b.append(3)
				_b.append(randi_range(4, 5))
			if hp < 5:
				_b.append(randi_range(3, 5))
	for b in _b:
		beam_attacks[b].attack()
		
func shoot_orb() -> void:
	var eb: Node2D = ENERGY_BALL_SCENE.instantiate()
	eb.global_position = boss_node.global_position + Vector2(0, -34)
	get_parent().add_child.call_deferred(eb)
	play_audio(audio_shoot)

func damage_taken(_hurt_box: HurtBox) -> void:
	if animation_player_damaged and animation_player_damaged.current_animation == "damaged":
		return
	if _hurt_box.damage == 0:
		return
	if audio:
		play_audio(audio_hurt)
	hp = clampi(hp - _hurt_box.damage, 0, max_hp)
	damage_count += 1
	PlayerHud.update_boss_health(hp, max_hp)
	if animation_player_damaged:
		if animation_player_damaged.has_animation("damaged"):
			animation_player_damaged.play("damaged")
			animation_player_damaged.seek(0)
			animation_player_damaged.queue("default")
	if hp < 1:
		defeat()
	pass

func play_audio(_a: AudioStream) -> void:
	if audio:
		audio.stream = _a
		audio.play()

func defeat() -> void:
	if animation_player and animation_player.has_animation("destroy"):
		animation_player.play("destroy")
		await animation_player.animation_finished
	enable_hit_boxes(false)
	
	# Only hide boss health if this is the final defeat (check if we're in a boss wave system)
	# If we're in dungeon04_boss_waves, the wave system will handle showing/hiding
	var level = get_tree().current_scene
	if not level or not level.has_method("_on_boss_defeated"):
		# Not in a boss wave system, hide the health bar
		PlayerHud.hide_boss_health()
	
	if has_node("ItemDropper") and boss_node:
		$ItemDropper.position = boss_node.position
		$ItemDropper.drop_item()
		if $ItemDropper.has_signal("drop_collected"):
			$ItemDropper.drop_collected.connect(open_dungeon)
	
func open_dungeon() -> void:
	if persistent_data_handler:
		persistent_data_handler.set_value()
	if door_block:
		door_block.enabled = false
	
func enable_hit_boxes(_v: bool = true) -> void:
	if hit_box:
		hit_box.set_deferred("monitorable", _v)
	if hurt_box:
		hurt_box.set_deferred("monitoring", _v)
	
func explosion(_p: Vector2 = Vector2.ZERO) -> void:
	var e: Node2D = ENERGY_EXPLOSION_SCENE.instantiate()
	e.global_position = boss_node.global_position + _p
	get_parent().add_child.call_deferred(e)
	pass
