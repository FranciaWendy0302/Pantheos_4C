extends Node

# Global Party UI Manager
# Handles showing the party invite popup and party viewer

var popup_scene = preload("res://GUI/party_invite/party_invite.tscn")
var viewer_scene = preload("res://GUI/party_viewer/party_viewer.tscn")
var popup_instance = null
var viewer_instance = null

func _ready() -> void:
	# Wait for scene tree to be ready
	await get_tree().process_frame
	
	# Instantiate the popup
	popup_instance = popup_scene.instantiate()
	
	# Instantiate the party viewer
	viewer_instance = viewer_scene.instantiate()
	
	# Add to PlayerHud (which is a CanvasLayer autoload)
	if PlayerHud:
		PlayerHud.add_child(popup_instance)
		PlayerHud.add_child(viewer_instance)
		print("[GlobalPartyUI] Popup and viewer added to PlayerHud")
	else:
		# Fallback: add to root
		get_tree().root.add_child(popup_instance)
		get_tree().root.add_child(viewer_instance)
		print("[GlobalPartyUI] Popup and viewer added to root (fallback)")
	
	print("[GlobalPartyUI] Party UI instantiated and added to scene tree")
