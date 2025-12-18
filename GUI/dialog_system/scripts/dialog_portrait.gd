class_name DialogPortrait
extends Control

@export var portrait_texture: Texture2D
@export var character_name: String = ""

func _init():
	pass

func set_portrait(texture: Texture2D, name: String = ""):
	portrait_texture = texture
	if name != "":
		character_name = name