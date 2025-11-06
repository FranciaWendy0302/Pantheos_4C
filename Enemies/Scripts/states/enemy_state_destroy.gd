class_name EnemyStateDestroy extends EnemyState

const PICKUP = preload("res://Items/item_pickup/item_pickup.tscn")

@export var anim_name: String = "destroy"
@export var knockback_speed: float = 200.0
@export var decelerate_speed: float = 10.0

@export_category("AI")

@export_category("Item Drops")
@export var drops: Array[DropData]

var _damage_position: Vector2
var _direction: Vector2
var _respawn_timer: float = 0.0
var _is_respawning: bool = false

func init() -> void:
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)
	pass
	
func enter() -> void:
	enemy.invulnerable = true
	_direction = enemy.global_position.direction_to(_damage_position)
	
	enemy.set_direction(_direction)
	enemy.velocity = _direction * -knockback_speed
	
	enemy.update_animation(anim_name)
	enemy.animation_player.animation_finished.connect(_on_enemy_finished)
	
	# Immediately disable attack area and vision area to prevent chasing/damaging
	disable_hurt_box()
	disable_attack_area()
	disable_vision_area()
	
	drop_items()
	PlayerManager.reward_xp(enemy.xp_reward)
	_respawn_timer = 0.0
	_is_respawning = false
	pass
	
func exit() -> void:
	# Disconnect the animation finished signal to prevent it from firing when leaving this state
	if enemy.animation_player and enemy.animation_player.animation_finished.is_connected(_on_enemy_finished):
		enemy.animation_player.animation_finished.disconnect(_on_enemy_finished)
	pass
	
func process(_delta: float) -> EnemyState:
	if _is_respawning:
		_respawn_timer -= _delta
		if _respawn_timer <= 0:
			_respawn_enemy()
			# Don't return null here - let _respawn_enemy handle state change
			return null
	
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	return null
	
func physics(_delta: float) -> EnemyState:
	return null

func _on_enemy_destroyed(hurt_box: HurtBox) -> void:
	_damage_position = hurt_box.global_position
	state_machine.change_state(self)

func _on_enemy_finished(_a: String ) -> void:
	# Instead of queue_free(), hide the enemy and start respawn timer
	enemy.visible = false
	enemy.set_physics_process(false)
	
	# Hide the sprite explicitly
	if enemy.sprite:
		enemy.sprite.visible = false
	
	# Disable vision area
	var vision_area = enemy.get_node_or_null("VisionArea")
	if vision_area:
		vision_area.monitoring = false
	
	# Disable collision shapes so enemy doesn't interfere while hidden
	var collision_shapes = enemy.get_children()
	for child in collision_shapes:
		if child is CollisionShape2D:
			child.disabled = true
		# Also check children recursively
		for grandchild in child.get_children():
			if grandchild is CollisionShape2D:
				grandchild.disabled = true
	
	# Keep process enabled so the timer can count down
	_is_respawning = true
	_respawn_timer = enemy.respawn_time
	pass

func _respawn_enemy() -> void:
	# Disconnect animation_finished signal first to prevent interference
	if enemy.animation_player and enemy.animation_player.animation_finished.is_connected(_on_enemy_finished):
		enemy.animation_player.animation_finished.disconnect(_on_enemy_finished)
	
	# Reset the respawn flag first
	_is_respawning = false
	
	# Reset enemy state
	enemy.hp = enemy.max_hp
	enemy.invulnerable = false
	enemy.global_position = enemy.spawn_position
	enemy.velocity = Vector2.ZERO
	enemy.visible = true
	enemy.set_physics_process(true)
	
	# Make sure all sprites are visible - recursively
	_set_all_sprites_visible(enemy, true)
	
	# Check for DestroyEffectSprite and hide it
	var destroy_effect = enemy.get_node_or_null("DestroyEffectSprite")
	if destroy_effect:
		destroy_effect.visible = false
	
	# Re-enable collision shapes (false means not disabled = enabled)
	_set_all_collision_shapes_enabled(enemy, false)
	
	# Re-enable hurt box
	var hurt_box: HurtBox = enemy.get_node_or_null("HurtBox")
	if hurt_box:
		hurt_box.monitoring = true
	
	# Re-enable vision area
	var vision_area = enemy.get_node_or_null("VisionArea")
	if vision_area:
		vision_area.monitoring = true
	
	# Reset cardinal direction BEFORE changing state
	enemy.cardinal_direction = Vector2.DOWN
	enemy.direction = Vector2.ZERO
	
	# Reset animation player - stop any current animation
	if enemy.animation_player:
		enemy.animation_player.stop()
		enemy.animation_player.seek(0.0)
	
	# Change to idle state - this will call enter() which plays the idle animation
	# Use call_deferred to ensure it happens after current frame
	call_deferred("_change_to_idle_state")

func _change_to_idle_state() -> void:
	# Find the idle state (first state is usually Idle)
	if state_machine.states.size() > 0:
		var idle_state = state_machine.states[0]
		state_machine.change_state(idle_state)

func _set_all_sprites_visible(node: Node, visible: bool) -> void:
	if node is Sprite2D or node is AnimatedSprite2D:
		node.visible = visible
		if node is Sprite2D:
			(node as Sprite2D).modulate = Color.WHITE
	
	for child in node.get_children():
		_set_all_sprites_visible(child, visible)

func _set_all_collision_shapes_enabled(node: Node, disabled: bool) -> void:
	if node is CollisionShape2D:
		(node as CollisionShape2D).disabled = disabled
	
	for child in node.get_children():
		_set_all_collision_shapes_enabled(child, disabled)

func disable_hurt_box() -> void:
	var hurt_box: HurtBox = enemy.get_node_or_null("HurtBox")
	if hurt_box:
		hurt_box.monitoring = false

func disable_attack_area() -> void:
	# Disable attack area (usually in Sprite2D/AttackHurtBox)
	var attack_area = enemy.get_node_or_null("Sprite2D/AttackHurtBox")
	if attack_area:
		attack_area.monitoring = false
	# Also check for other possible attack areas
	var attack_hurt_box = enemy.get_node_or_null("AttackHurtBox")
	if attack_hurt_box:
		attack_hurt_box.monitoring = false

func disable_vision_area() -> void:
	var vision_area = enemy.get_node_or_null("VisionArea")
	if vision_area:
		vision_area.monitoring = false

func drop_items() -> void:
	if drops.size() == 0:
		return
	
	for i in drops.size():
		if drops[i] == null or drops[i].item == null:
			continue
		var drop_count: int = drops[i].get_drop_count()
		for j in drop_count:
			var drop: ItemPickup = PICKUP.instantiate() as ItemPickup
			drop.item_data = drops[i].item
			drop.auto_collect = true  # Enable auto-collect (fade out then add to inventory)
			enemy.get_parent().call_deferred("add_child", drop)
			drop.global_position = enemy.global_position
			drop.velocity = enemy.velocity.rotated(randf_range(-1.5, 1.5)) * randf_range(0.9, 1.5)
	pass
	
	
	
	
	
	
	
	
