extends Sprite2D

# Attach this script to god sprites in safezone.tscn
# Handles player interaction and quest giving

@export var god_type: GodManager.GodType = GodManager.GodType.ATHENA
@export var god_portrait_path: String = ""

var interaction_area: Area2D
var interaction_label: Label
var player_in_range: bool = false
var current_player: Node = null

func _ready():
	# Find existing interaction area (created in scene)
	interaction_area = _find_interaction_area()
	
	# Create interaction label if it doesn't exist
	if not has_node("InteractionPanel"):
		_create_interaction_label()
	else:
		var panel = get_node("InteractionPanel")
		interaction_label = panel.get_node("InteractionLabel")
	
	# Connect signals to existing interaction area
	if interaction_area:
		if not interaction_area.area_entered.is_connected(_on_area_entered):
			interaction_area.area_entered.connect(_on_area_entered)
		if not interaction_area.area_exited.is_connected(_on_area_exited):
			interaction_area.area_exited.connect(_on_area_exited)
		print("[GodNPC] ", _get_god_name(), " interaction ready")

func _find_interaction_area() -> Area2D:
	"""Find the interaction area child node"""
	for child in get_children():
		if child is Area2D:
			return child
	return null



func _create_interaction_label():
	"""Create 'G' popup label"""
	interaction_label = Label.new()
	interaction_label.name = "InteractionLabel"
	interaction_label.text = "G"
	interaction_label.position = Vector2(-15, -100)
	interaction_label.add_theme_font_size_override("font_size", 32)
	interaction_label.add_theme_color_override("font_color", Color.WHITE)
	interaction_label.add_theme_color_override("font_outline_color", Color.BLACK)
	interaction_label.add_theme_constant_override("outline_size", 5)
	interaction_label.visible = false
	
	# Add a background panel for better visibility
	var panel = PanelContainer.new()
	panel.name = "InteractionPanel"
	panel.position = Vector2(-25, -110)
	panel.custom_minimum_size = Vector2(50, 50)
	
	# Create a simple colored background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.WHITE
	panel.add_theme_stylebox_override("panel", style_box)
	
	add_child(panel)
	panel.add_child(interaction_label)
	interaction_label.position = Vector2(9, 5)
	panel.visible = false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		_interact()

func _on_area_entered(area: Area2D):
	# Check if it's the player's interaction area
	if area.get_parent() and (area.get_parent().name == "Interactions" or area.get_parent().is_in_group("player")):
		player_in_range = true
		current_player = area.get_parent()
		# Show both the label and panel
		if interaction_label:
			interaction_label.visible = true
		var panel = get_node_or_null("InteractionPanel")
		if panel:
			panel.visible = true
		print("[GodNPC] Player entered ", _get_god_name(), " area")

func _on_area_exited(area: Area2D):
	if area.get_parent() and (area.get_parent().name == "Interactions" or area.get_parent().is_in_group("player")):
		player_in_range = false
		current_player = null
		# Hide both the label and panel
		if interaction_label:
			interaction_label.visible = false
		var panel = get_node_or_null("InteractionPanel")
		if panel:
			panel.visible = false
		print("[GodNPC] Player exited ", _get_god_name(), " area")

func _interact():
	"""Handle player interaction"""
	if not current_player:
		return
	
	var player_god = GodManager.get_selected_god()
	var god_data = GodManager.get_god_data(god_type)
	
	# Debug logging
	print("[GodNPC] Player interacting with: ", _get_god_name(), " (type: ", god_type, ")")
	print("[GodNPC] Player's selected god: ", GodManager.get_god_name(player_god), " (type: ", player_god, ")")
	print("[GodNPC] Match: ", player_god == god_type)
	
	if player_god == god_type:
		# This is the player's god
		_show_god_dialogue()
	else:
		# Not the player's god
		_show_rejection_dialogue()

func _show_god_dialogue():
	"""Show dialogue for player's god"""
	var god_data = GodManager.get_god_data(god_type)
	var god_resource = _load_god_resource()
	
	if not god_resource:
		print("[GodNPC] ERROR: Could not load god resource")
		return
	
	var dialog_items: Array[DialogItem] = []
	
	# Greeting
	var dialog1 = DialogText.new()
	dialog1.npc_info = god_resource
	dialog1.text = "Greetings, my champion."
	dialog_items.append(dialog1)
	
	# Introduction
	var dialog2 = DialogText.new()
	dialog2.npc_info = god_resource
	dialog2.text = "I am " + str(god_data.get("name", "Unknown")) + ", " + str(god_data.get("title", "")) + ".\n\n" + str(god_data.get("description", ""))
	dialog_items.append(dialog2)
	
	# Skill info
	var dialog3 = DialogText.new()
	dialog3.npc_info = god_resource
	dialog3.text = "Your special skill: " + str(god_data.get("special_skill", "Unknown")) + "\n\n" + str(god_data.get("skill_description", ""))
	dialog_items.append(dialog3)
	
	# Check if skill is unlocked
	if GodManager.is_god_skill_unlocked():
		var dialog4 = DialogText.new()
		dialog4.npc_info = god_resource
		dialog4.text = "You have already proven yourself worthy.\n\nUse my power wisely, champion."
		dialog_items.append(dialog4)
	else:
		# Check if quest is active
		var quest_mgr = get_node_or_null("/root/GodQuestManager")
		if quest_mgr and quest_mgr.is_quest_active():
			var dialog4 = DialogText.new()
			dialog4.npc_info = god_resource
			var wave = quest_mgr.get_current_wave()
			var remaining = quest_mgr.get_monsters_remaining()
			dialog4.text = "You are currently on Wave " + str(wave) + ".\n\n" + str(remaining) + " monsters remain!"
			dialog_items.append(dialog4)
		else:
			var dialog4 = DialogText.new()
			dialog4.npc_info = god_resource
			dialog4.text = "To prove yourself worthy of my power, you must complete a trial.\n\nDefeat 3 waves of monsters to unlock your divine ability!"
			dialog_items.append(dialog4)
			
			var dialog5 = DialogText.new()
			dialog5.npc_info = god_resource
			dialog5.text = "The trial begins now. Prepare yourself!"
			dialog_items.append(dialog5)
	
	DialogSystem.show_dialog(dialog_items)
	
	# Start quest after showing dialogue (if not unlocked and not active)
	if not GodManager.is_god_skill_unlocked():
		var quest_mgr = get_node_or_null("/root/GodQuestManager")
		if quest_mgr and not quest_mgr.is_quest_active():
			# Start quest after a short delay
			await get_tree().create_timer(1.0).timeout
			_start_god_quest()

func _show_rejection_dialogue():
	"""Show dialogue when player talks to wrong god"""
	var god_data = GodManager.get_god_data(god_type)
	var player_god_data = GodManager.get_god_data(GodManager.get_selected_god())
	var god_resource = _load_god_resource()
	
	if not god_resource:
		print("[GodNPC] ERROR: Could not load god resource")
		return
	
	var dialog_items: Array[DialogItem] = []
	
	var dialog1 = DialogText.new()
	dialog1.npc_info = god_resource
	dialog1.text = "I am " + str(god_data.get("name", "Unknown")) + ", " + str(god_data.get("title", ""))  + "."
	dialog_items.append(dialog1)
	
	var dialog2 = DialogText.new()
	dialog2.npc_info = god_resource
	dialog2.text = "You serve " + str(player_god_data.get("name", "another god")) + ", not me.\n\nSeek your own god for guidance, mortal."
	dialog_items.append(dialog2)
	
	DialogSystem.show_dialog(dialog_items)

func _load_god_resource() -> NPCResource:
	"""Load the god's NPC resource"""
	var god_name = _get_god_name()
	var resource_path = "res://npc/00_npcs/god_" + god_name.to_lower() + ".tres"
	return load(resource_path)

func _get_god_name() -> String:
	"""Get god name from god_type"""
	match god_type:
		GodManager.GodType.ATHENA: return "Athena"
		GodManager.GodType.ZEUS: return "Zeus"
		GodManager.GodType.VENUS: return "Venus"
		GodManager.GodType.ASCLEPIUS: return "Asclepius"
		GodManager.GodType.HADES: return "Hades"
		GodManager.GodType.ARES: return "Ares"
		GodManager.GodType.NEMESIS: return "Nemesis"
		GodManager.GodType.THANATOS: return "Thanatos"
	return "Unknown"

func _save_after_unlock() -> void:
	"""Save game after unlocking god skill"""
	# Wait for dialog to finish
	await DialogSystem.finished

	# Save the game
	print("[GodNPC] Saving game after skill unlock...")
	print("[GodNPC] ✓ Progress Saved - God skill unlocked!")
	SaveManager.save_game()


func _start_god_quest():
	"""Start the god quest"""
	var quest_mgr = get_node_or_null("/root/GodQuestManager")
	if quest_mgr:
		quest_mgr.start_quest()
		
		# Show quest panel
		var player_hud = get_tree().get_first_node_in_group("player_hud")
		if player_hud and player_hud.has_node("GodQuestPanel"):
			var quest_panel = player_hud.get_node("GodQuestPanel")
			quest_panel.show()
		
		print("[GodNPC] Quest started!")
	else:
		print("[GodNPC] ERROR: GodQuestManager not found!")
