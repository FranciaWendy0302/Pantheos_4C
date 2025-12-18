extends Control

# Simple working shop with 4 tabs

var current_tab = "Weapons"
var tab_buttons = []

var shop_data = {
	"Weapons": [
		{"name": "Flaming Sword", "price": 500, "desc": "Legendary sword with flames"},
		{"name": "Ice Bow", "price": 450, "desc": "Frozen arrows"},
		{"name": "Lightning Staff", "price": 600, "desc": "Electric power"},
		{"name": "Shadow Dagger", "price": 400, "desc": "Silent blade"},
		{"name": "Holy Mace", "price": 550, "desc": "Divine weapon"}
	],
	"Armor": [
		{"name": "Knight Armor", "price": 800, "desc": "Heavy plate armor"},
		{"name": "Shadow Cloak", "price": 700, "desc": "Stealth outfit"},
		{"name": "Mage Robes", "price": 650, "desc": "Mystical robes"},
		{"name": "Dragon Scale", "price": 1000, "desc": "Dragon armor"},
		{"name": "Leather Vest", "price": 300, "desc": "Light protection"}
	],
	"Potions": [
		{"name": "Health Potion", "price": 50, "desc": "Restores 100 HP"},
		{"name": "Mana Potion", "price": 50, "desc": "Restores 100 MP"},
		{"name": "Strength Elixir", "price": 100, "desc": "+50% attack"},
		{"name": "Speed Potion", "price": 80, "desc": "+30% speed"},
		{"name": "Invisibility", "price": 150, "desc": "30s invisible"},
		{"name": "Antidote", "price": 40, "desc": "Cure poison"}
	],
	"Accessories": [
		{"name": "Ring of Power", "price": 350, "desc": "+10% all stats"},
		{"name": "Amulet of Life", "price": 400, "desc": "+200 max HP"},
		{"name": "Lucky Charm", "price": 250, "desc": "+15% crit"},
		{"name": "Speed Boots", "price": 300, "desc": "Faster movement"},
		{"name": "Magic Cape", "price": 450, "desc": "-25% magic dmg"},
		{"name": "Golden Crown", "price": 1200, "desc": "Legendary item"}
	]
}

@onready var title_label: Label = $Panel/MarginContainer/VBox/TopBar/Title
@onready var close_button: Button = $Panel/MarginContainer/VBox/TopBar/CloseButton
@onready var tab_container: HBoxContainer = $Panel/MarginContainer/VBox/TabBar
@onready var item_grid: GridContainer = $Panel/MarginContainer/VBox/ScrollContainer/ItemGrid

func _ready():
	# Make shop fill screen with proper z-index (same as PauseMenu)
	z_index = 100
	
	# Add background overlay matching PauseMenu style
	var overlay = ColorRect.new()
	overlay.color = Color(0.141176, 0.141176, 0.141176, 0.815686)  # Same as PauseMenu
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.z_index = -1
	add_child(overlay)
	move_child(overlay, 0)
	
	# Make panel fill screen like PauseMenu (no centering, full screen)
	var panel = get_node("Panel")
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	
	# Remove panel background (transparent like PauseMenu)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0)  # Transparent
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Adjust margins - smaller to fit more content
	var margin = get_node("Panel/MarginContainer")
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	
	# Style the title - smaller
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Style close button
	close_button.custom_minimum_size = Vector2(45, 35)
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.pressed.connect(_on_close_pressed)
	
	# Adjust grid spacing - tighter
	item_grid.add_theme_constant_override("h_separation", 12)
	item_grid.add_theme_constant_override("v_separation", 12)
	
	# Adjust VBox spacing
	var vbox = get_node("Panel/MarginContainer/VBox")
	vbox.add_theme_constant_override("separation", 10)
	
	# Create tab buttons
	_create_tabs()
	
	# Show initial items
	_refresh_items()
	
	print("[SimpleShop] Shop initialized with PauseMenu style")

func _create_tabs():
	# Clear existing tabs
	for child in tab_container.get_children():
		child.queue_free()
	tab_buttons.clear()
	
	for tab_name in ["Weapons", "Armor", "Potions", "Accessories"]:
		var btn = Button.new()
		btn.text = tab_name
		btn.custom_minimum_size = Vector2(110, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_tab_pressed.bind(tab_name))
		
		# Style tab buttons - simpler, cleaner
		_style_tab_button(btn, tab_name == current_tab)
		btn.add_theme_font_size_override("font_size", 14)
		
		tab_container.add_child(btn)
		tab_buttons.append(btn)

func _style_tab_button(btn: Button, is_active: bool):
	# Simple flat style matching PauseMenu aesthetic
	var tab_style = StyleBoxFlat.new()
	if is_active:
		tab_style.bg_color = Color(0.3, 0.3, 0.4, 0.9)
	else:
		tab_style.bg_color = Color(0.2, 0.2, 0.25, 0.7)
	btn.add_theme_stylebox_override("normal", tab_style)
	
	var tab_hover = StyleBoxFlat.new()
	tab_hover.bg_color = Color(0.35, 0.35, 0.45, 0.9)
	btn.add_theme_stylebox_override("hover", tab_hover)

func _on_tab_pressed(tab_name: String):
	current_tab = tab_name
	
	# Update tab button styles
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i]
		var is_active = btn.text == current_tab
		_style_tab_button(btn, is_active)
	
	_refresh_items()
	print("[SimpleShop] Tab changed to: ", tab_name)

func _refresh_items():
	# Clear existing items
	for child in item_grid.get_children():
		child.queue_free()
	
	# Add items for current tab
	var items = shop_data.get(current_tab, [])
	for item in items:
		var card = _create_item_card(item)
		item_grid.add_child(card)

func _create_item_card(item: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(140, 170)
	
	# Style the card background - matching PauseMenu panel style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.85)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	card.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	
	# Item icon placeholder
	var icon_panel = Panel.new()
	icon_panel.custom_minimum_size = Vector2(124, 60)
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.15, 0.15, 0.2)
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	vbox.add_child(icon_panel)
	
	# Item name
	var name_label = Label.new()
	name_label.text = item.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = item.desc
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(124, 24)
	vbox.add_child(desc_label)
	
	# Price
	var price_label = Label.new()
	price_label.text = "💎 %d" % item.price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 13)
	price_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	vbox.add_child(price_label)
	
	# Buy button
	var buy_btn = Button.new()
	buy_btn.text = "BUY"
	buy_btn.custom_minimum_size = Vector2(0, 26)
	buy_btn.add_theme_font_size_override("font_size", 11)
	buy_btn.pressed.connect(_on_buy_pressed.bind(item))
	vbox.add_child(buy_btn)
	
	return card

func _on_buy_pressed(item: Dictionary):
	print("[SimpleShop] Attempting to buy: ", item.name, " for ", item.price, " gems")
	
	if PlayerManager.player:
		if PlayerManager.player.currency >= item.price:
			PlayerManager.player.currency -= item.price
			print("[SimpleShop] Purchase successful! Remaining: ", PlayerManager.player.currency)
		else:
			print("[SimpleShop] Not enough gems!")
	else:
		print("[SimpleShop] Player not found")

func _on_close_pressed():
	visible = false
	
	# Close any open pause menu
	if PauseMenu and PauseMenu.visible:
		PauseMenu.hide_pause_menu()
	
	# Notify icon buttons to restore HUD
	var icon_buttons = get_tree().get_first_node_in_group("hud_icon_buttons")
	if icon_buttons and icon_buttons.has_method("_show_hud_elements"):
		icon_buttons._show_hud_elements()
	
	print("[SimpleShop] Shop closed")
