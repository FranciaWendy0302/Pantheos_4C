extends CanvasLayer

# Party Finder UI
# Browse and join public parties

@onready var party_list: VBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/ScrollContainer/PartyList
@ontml:parameter name="text">@onready var refresh_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/RefreshButton
@onready var close_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var filter_level_min: SpinBox = $Control/Panel/MarginContainer/VBoxContainer/Filters/LevelMinSpinBox
@onready var filter_level_max: SpinBox = $Control/Panel/MarginContainer/VBoxContainer/Filters/LevelMaxSpinBox
@onready var no_parties_label: Label = $Control/Panel/MarginContainer/VBoxContainer/NoPartiesLabel

var party_entry_scene = preload("res://GUI/party_system/party_finder_entry.tscn")

func _ready() -> void:
	refresh_button.pressed.connect(_on_refresh_pressed)
	close_button.pressed.connect(_on_close_pressed)
	hide()

func show_finder() -> void:
	show()
	_refresh_party_list()

func _on_refresh_pressed() -> void:
	_refresh_party_list()

func _on_close_pressed() -> void:
	hide()

func _refresh_party_list() -> void:
	"""Fetch and display available parties"""
	_clear_party_list()
	
	# Request party list from server
	var min_level = int(filter_level_min.value)
	var max_level = int(filter_level_max.value)
	
	NetworkManager.send_websocket_message({
		"type": "party_finder_list",
		"data": {
			"min_level": min_level,
			"max_level": max_level
		}
	})

func on_party_list_received(parties: Array) -> void:
	"""Called when server sends party list"""
	_clear_party_list()
	
	if parties.size() == 0:
		no_parties_label.visible = true
		return
	
	no_parties_label.visible = false
	
	for party_data in parties:
		var entry = party_entry_scene.instantiate()
		party_list.add_child(entry)
		entry.setup(party_data)
		entry.join_requested.connect(_on_join_party_requested.bind(party_data.party_id))

func _clear_party_list() -> void:
	for child in party_list.get_children():
		child.queue_free()
	no_parties_label.visible = false

func _on_join_party_requested(party_id: int) -> void:
	"""Request to join a public party"""
	NetworkManager.send_websocket_message({
		"type": "party_join_public",
		"data": {
			"party_id": party_id
		}
	})
	hide()
