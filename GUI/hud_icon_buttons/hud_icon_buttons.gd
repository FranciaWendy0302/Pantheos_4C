class_name HudIconButtons
extends Control

@export var inventory_button: Button
@export var character_button: Button
@export var shop_button: Button
@export var quest_button: Button
@export var settings_button: Button

signal inventory_pressed
signal character_pressed
signal shop_pressed
signal quest_pressed
signal settings_pressed

func _init():
	pass

func _ready():
	if inventory_button:
		inventory_button.pressed.connect(_on_inventory_pressed)
	if character_button:
		character_button.pressed.connect(_on_character_pressed)
	if shop_button:
		shop_button.pressed.connect(_on_shop_pressed)
	if quest_button:
		quest_button.pressed.connect(_on_quest_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

func _on_inventory_pressed():
	inventory_pressed.emit()

func _on_character_pressed():
	character_pressed.emit()

func _on_shop_pressed():
	shop_pressed.emit()

func _on_quest_pressed():
	quest_pressed.emit()

func _on_settings_pressed():
	settings_pressed.emit()