class_name SkillData extends Resource

# Individual skill data that can be used by weapons or equipment

@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var mana_cost: int = 0
@export var cooldown: float = 0.0
@export var skill_type: String = ""  # "projectile", "dash", "area", "buff", etc.
@export var damage_multiplier: float = 1.0
@export var range: float = 100.0
@export var effect_scene: PackedScene  # Visual effect scene

func execute(player, target_position: Vector2) -> bool:
	# Override in specific skill implementations or handle in player script
	return false
