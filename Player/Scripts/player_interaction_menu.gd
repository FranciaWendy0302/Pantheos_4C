class_name PlayerInteractionMenu
extends Control

@export var interaction_buttons: Array[Button] = []

signal interaction_selected(interaction_type: String)

func _init():
	pass

func show_interactions(available_interactions: Array[String]):
	show()
	# Setup interaction buttons based on available interactions

func hide_interactions():
	hide()