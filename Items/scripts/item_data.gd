class_name ItemData extends Resource

@export var name: String = ""
@export_multiline var description: String = ""
@export var texture: Texture2D
@export var cost: int = 10
@export var hide_in_inventory: bool = false

@export_category("Item Use Effects")
@export var effect: Array[ItemEffect]

func use() -> bool:
	if effect.size() == 0:
		return false
		
	for e in effect:
		if e: 
			e.use()
	return true
