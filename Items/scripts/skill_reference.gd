class_name SkillReference extends Resource

# Skill Reference - Points to a skill implementation in the player's class abilities
# The weapon/equipment only stores this reference, not the actual skill logic

@export var skill_id: String = ""  # e.g., "fireball", "fire_wheel", "teleport"
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var mana_cost: int = 0
@export var cooldown: float = 0.0

# The actual skill execution is handled by the player's class abilities
# This just tells the UI what to show and what skill to call
