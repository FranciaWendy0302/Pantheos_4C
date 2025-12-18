extends Sprite2D

const FRAME_COUNT: int = 128

var weapon_below: Sprite2D = null
var weapon_above: Sprite2D = null

func _ready() -> void:
	weapon_below = get_node_or_null("Sprite2D_Weapon_Below")
	weapon_above = get_node_or_null("Sprite2D_Weapon_Above")
	PlayerManager.INVENTORY_DATA.equipment_changed.connect(_on_equipment_changed)
	pass
	
func _process(_delta: float) -> void:
	if weapon_below:
		weapon_below.frame = frame
	if weapon_above:
		weapon_above.frame = frame + FRAME_COUNT
	pass
	
func _on_equipment_changed() -> void:
	var equipment: Array[SlotData] = PlayerManager.INVENTORY_DATA.equipment_slots()
	
	# Don't change player body sprite - keep original character appearance
	# texture = equipment[0].item_data.sprite_texture  # DISABLED
	
	# Update weapon sprites only
	# equipment[0] = Armor (don't use for sprite)
	# equipment[1] = Weapon (use for weapon sprites)
	if equipment[1] and equipment[1].item_data and equipment[1].item_data.sprite_texture:
		weapon_below.texture = equipment[1].item_data.sprite_texture
		weapon_above.texture = equipment[1].item_data.sprite_texture
	else:
		# No weapon equipped - clear weapon sprites
		if weapon_below:
			weapon_below.texture = null
		if weapon_above:
			weapon_above.texture = null
	pass
