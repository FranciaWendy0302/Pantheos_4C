class_name HurtBox extends Area2D

signal did_damage

@export var damage: int = 1

func _ready():
	area_entered.connect(AreaEntered)
	pass
	
func _process(_delta):
	pass
	
func AreaEntered(a: Area2D) -> void:
	if a is HitBox:
		var parent_node = get_parent()
		
		# Check if this arrow was fired by an enemy and should ignore that enemy
		if parent_node and parent_node.has_method("get") and parent_node.has_meta("shooter"):
			var shooter = parent_node.get_meta("shooter")
			if shooter and is_instance_valid(shooter):
				# Check if the hitbox belongs to the shooter
				var shooter_hitbox_owner = a.get_parent()
				if shooter_hitbox_owner == shooter or (shooter_hitbox_owner.get_parent() == shooter if shooter_hitbox_owner.get_parent() else false):
					# This is the shooter's hitbox, ignore it
					return
		
		# Check if this is a big arrow and if we've already hit this enemy
		var is_big_arrow = false
		var hit_enemies = []
		if parent_node:
			if parent_node.has_meta("is_big_arrow"):
				is_big_arrow = parent_node.get_meta("is_big_arrow")
			if parent_node.has_meta("hit_enemies"):
				hit_enemies = parent_node.get_meta("hit_enemies")
		
		# Get the enemy owner of this hitbox
		var enemy_owner = null
		var hitbox_owner = a.get_parent()
		if hitbox_owner:
			# Check if parent is Enemy, or if parent's parent is Enemy
			if hitbox_owner.has_method("get") and hitbox_owner.has_method("_take_damage"):
				# Likely an Enemy
				enemy_owner = hitbox_owner
			elif hitbox_owner.get_parent():
				var grandparent = hitbox_owner.get_parent()
				if grandparent.has_method("get") and grandparent.has_method("_take_damage"):
					enemy_owner = grandparent
		
		# For big arrows, check if we've already hit this enemy
		if is_big_arrow and enemy_owner:
			# Check if enemy is already in hit list
			var already_hit = false
			for hit_enemy in hit_enemies:
				if hit_enemy == enemy_owner:
					already_hit = true
					break
			
			if already_hit:
				# Already hit this enemy, skip
				return
			
			# Add to hit list
			hit_enemies.append(enemy_owner)
			parent_node.set_meta("hit_enemies", hit_enemies)
		
		did_damage.emit()
		a.TakeDamage(self)
	pass
