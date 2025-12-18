class_name NPC
extends CharacterBody2D

@export var npc_name: String = "NPC"
@export var dialogue_resource: Resource
@export var interaction_range: float = 50.0

signal interaction_started(npc: NPC)
signal interaction_ended(npc: NPC)

func _init():
	pass

func can_interact_with_player(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_range

func start_interaction():
	interaction_started.emit(self)

func end_interaction():
	interaction_ended.emit(self)