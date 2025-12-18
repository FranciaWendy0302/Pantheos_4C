class_name NotificationUI
extends Control

@export var notification_scene: PackedScene
var notifications: Array = []

func _init():
	pass

func show_notification(message: String, type: String = "info"):
	print("[Notification] ", message)
	# Basic notification system stub

func clear_notifications():
	notifications.clear()