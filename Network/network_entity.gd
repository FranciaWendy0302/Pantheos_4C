extends Node
class_name NetworkEntity

## Handles network visibility for entities (monsters, NPCs, quest objects)
## Attach this to any entity that should have network visibility rules

enum VisibilityMode {
	GLOBAL,        # Everyone can see (normal monsters)
	OWNER_ONLY,    # Only the owner can see (quest-specific monsters)
	PARTY_ONLY     # Only party members can see
}

@export var visibility_mode: VisibilityMode = VisibilityMode.GLOBAL
@export var owner_peer_id: int = -1  # -1 means no specific owner

func _ready() -> void:
	# Check if this entity should be visible to the local player
	if not should_be_visible():
		# Hide or remove the entity
		get_parent().visible = false
		# Optionally disable collision/processing
		get_parent().set_process(false)
		get_parent().set_physics_process(false)
	pass


func should_be_visible() -> bool:
	match visibility_mode:
		VisibilityMode.GLOBAL:
			return true
		
		VisibilityMode.OWNER_ONLY:
			# Only visible if we're the owner or if we're the server
			if multiplayer.is_server():
				return true
			return multiplayer.get_unique_id() == owner_peer_id
		
		VisibilityMode.PARTY_ONLY:
			# Check if local player is in the same party as owner
			# You'll need to implement party checking logic
			return true
	
	return true


func set_owner(peer_id: int) -> void:
	"""Set the owner of this entity"""
	owner_peer_id = peer_id
	
	# Re-check visibility
	if not should_be_visible():
		get_parent().visible = false
		get_parent().set_process(false)
		get_parent().set_physics_process(false)
	else:
		get_parent().visible = true
		get_parent().set_process(true)
		get_parent().set_physics_process(true)
	pass
