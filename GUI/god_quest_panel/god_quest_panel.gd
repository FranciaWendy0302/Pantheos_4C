extends PanelContainer

# God Quest Panel
# Shows current wave progress and monster count

@onready var wave_label = $MarginContainer/VBoxContainer/WaveLabel
@onready var progress_label = $MarginContainer/VBoxContainer/ProgressLabel
@onready var start_button = $MarginContainer/VBoxContainer/StartButton

func _ready():
	# Connect to GodQuestManager signals
	if has_node("/root/GodQuestManager"):
		var quest_mgr = get_node("/root/GodQuestManager")
		quest_mgr.wave_started.connect(_on_wave_started)
		quest_mgr.wave_completed.connect(_on_wave_completed)
		quest_mgr.monster_killed.connect(_on_monster_killed)
		quest_mgr.quest_completed.connect(_on_quest_completed)
	
	# Connect start button
	start_button.pressed.connect(_on_start_pressed)
	
	# Hide initially
	hide()

func show_quest_panel():
	"""Show the quest panel"""
	wave_label.text = "God Quest"
	progress_label.text = "Click Start to begin"
	start_button.visible = true
	show()

func _on_start_pressed():
	"""Start the quest"""
	var quest_mgr = get_node_or_null("/root/GodQuestManager")
	if quest_mgr:
		quest_mgr.start_quest()
		start_button.visible = false

func _on_wave_started(wave_number: int):
	"""Called when a wave starts"""
	wave_label.text = "Wave " + str(wave_number) + " / 3"
	
	var quest_mgr = get_node_or_null("/root/GodQuestManager")
	if quest_mgr:
		var total = quest_mgr.monsters_to_spawn
		progress_label.text = "Defeat " + str(total) + " monsters!"

func _on_monster_killed(remaining: int):
	"""Called when a monster is killed"""
	progress_label.text = str(remaining) + " monsters remaining"

func _on_wave_completed(wave_number: int):
	"""Called when a wave is completed"""
	progress_label.text = "Wave " + str(wave_number) + " Complete!"

func _on_quest_completed(_god_id: int):
	"""Called when quest is completed"""
	wave_label.text = "Quest Complete!"
	progress_label.text = "God skill unlocked!"
	
	# Hide after a delay
	await get_tree().create_timer(5.0).timeout
	hide()
