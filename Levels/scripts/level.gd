class_name Level
extends Node2D

@export var level_name: String = ""
@export var level_id: int = 0
@export var spawn_points: Array[Vector2] = []

signal level_loaded(level: Level)
signal level_unloaded(level: Level)

func _init():
	pass

func load_level():
	level_loaded.emit(self)

func unload_level():
	level_unloaded.emit(self)