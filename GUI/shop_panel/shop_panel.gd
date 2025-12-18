extends Control

# Complete shop panel with item display
# Shows cosmetic items even without purchase functionality

# Shop items organized by 4 main categories
var shop_items = [
	# WEAPONS
	{
		"name": "Flaming Sword",
		"category": "Weapons",
		"price": 500,
		"description": "Legendary sword engulfed in eternal flames",
		"image": "res://icon.svg"
	},
	{
		"name": "Ice Bow",
		"category": "Weapons",
		"price": 450,
		"description": "Enchanted bow that shoots frozen arrows",
		"image": "res://icon.svg"
	},
	{
		"name": "Lightning Staff",
		"category": "Weapons",
		"price": 600,
		"description": "Ancient staff crackling with electricity",
		"image": "res://icon.svg"
	},
	{
		"name": "Shadow Dagger",
		"category": "Weapons",
		"price": 400,
		"description": "Silent blade forged in darkness",
		"image": "res://icon.svg"
	},
	{
		"name": "Holy Mace",
		"category": "Weapons",
		"price": 550,
		"description": "Divine weapon blessed by the gods",
		"image": "res://icon.svg"
	},
	
	# ARMOR
	{
		"name": "Knight Armor",
		"category": "Armor",
		"price": 800,
		"description": "Heavy plate armor with golden accents",
		"image": "res://icon.svg"
	},
	{
		"name": "Shadow Cloak",
		"category": "Armor",
		"price": 700,
		"description": "Dark stealth outfit for assassins",
		"image": "res://icon.svg"
	},
	{
		"name": "Mage Robes",
		"category": "Armor",
		"price": 650,
		"description": "Mystical robes with arcane symbols",
		"image": "res://icon.svg"
	},
	{
		"name": "Dragon Scale",
		"category": "Armor",
		"price": 1000,
		"description": "Armor crafted from dragon scales",
		"image": "res://icon.svg"
	},
	{
		"name": "Leather Vest",
		"category": "Armor",
		"price": 300,
		"description": "Light and flexible protection",
		"image": "res://icon.svg"
	},
	
	# POTIONS
	{
		"name": "Health Potion",
		"category": "Potions",
		"price": 50,
		"description": "Restores 100 HP instantly",
		"image": "res://icon.svg"
	},
	{
		"name": "Mana Potion",
		"category": "Potions",
		"price": 50,
		"description": "Restores 100 MP instantly",
		"image": "res://icon.svg"
	},
	{
		"name": "Strength Elixir",
		"category": "Potions",
		"price": 100,
		"description": "Increases attack by 50% for 60 seconds",
		"image": "res://icon.svg"
	},
	{
		"name": "Speed Potion",
		"category": "Potions",
		"price": 80,
		"description": "Increases movement speed by 30%",
		"image": "res://icon.svg"
	},
	{
		"name": "Invisibility Potion",
		"category": "Potions",
		"price": 150,
		"description": "Become invisible for 30 seconds",
		"image": "res://icon.svg"
	},
	{
		"name": "Antidote",
		"category": "Potions",
		"price": 40,
		"description": "Cures all poison effects",
		"image": "res://icon.svg"
	},
	
	# ACCESSORIES
	{
		"name": "Ring of Power",
		"category": "Accessories",
		"price": 350,
		"description": "Increases all stats by 10%",
		"image": "res://icon.svg"
	},
	{
		"name": "Amulet of Life",
		"category": "Accessories",
		"price": 400,
		"description": "Increases max HP by 200",
		"image": "res://icon.svg"
	},
	{
		"name": "Lucky Charm",
		"category": "Accessories",
		"price": 250,
		"description": "Increases critical hit chance by 15%",
		"image": "res://icon.svg"
	},
	{
		"name": "Speed Boots",
		"category": "Accessories",
		"price": 300,
		"description": "Permanently increases movement speed",
		"image": "res://icon.svg"
	},
	{
		"name": "Magic Cape",
		"category": "Accessories",
		"price": 450,
		"description": "Reduces magic damage taken by 25%",
		"image": "res://icon.svg"
	},
	{
		"name": "Golden Crown",
		"category": "Accessories",
		"price": 1200,
		"description": "Legendary accessory that boosts all abilities",
		"image": "res://icon.svg"
	}
]

var current_category = "All"

func _ready() -> void:
	# Set control to fill the screen
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Build UI
	_build_shop_ui()
	
	# Hide initially
	visible = false
	
	print("[ShopPanel] Complete shop panel initialized with ", shop_items.size(), " items")

func _build_shop_ui() -> void:
	"""Build the shop UI programmatically"""
	# Clear any existing children
	for child in get_children():
		child.queue_free()
	
	# Create main panel
	var panel = Panel.new()
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	add_child(panel)
	
	# Create margin container
	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	panel.add_child(margin)
	
	# Create main VBox
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Create top bar
	var top_bar = HBoxContainer.new()
	vbox.add_child(top_bar)
	
	# Title
	var title = Label.new()
	title.text = "Cosmetic Shop"
	title.add_theme_font_size_override("font_size", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(50, 50)
	close_btn.pressed.connect(_on_close_pressed)
	top_bar.add_child(close_btn)
	
	# Category filter
	var category_bar = HBoxContainer.new()
	category_bar.add_theme_constant_override("separation", 10)
	vbox.add_child(category_bar)
	
	var cat_label = Label.new()
	cat_label.text = "Category:"
	category_bar.add_child(cat_label)
	
	# Create tab buttons for 4 main categories
	for cat in ["All", "Weapons", "Armor", "Potions", "Accessories"]:
		var cat_btn = Button.new()
		cat_btn.text = cat
		cat_btn.custom_minimum_size = Vector2(120, 40)
		# Highlight current category
		if cat == current_category:
			cat_btn.modulate = Color(1.2, 1.2, 0.8)
		cat_btn.pressed.connect(_on_category_selected.bind(cat))
		category_bar.add_child(cat_btn)
	
	# Scroll container for items
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	# Grid for items
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)
	
	# Add items
	_populate_items(grid, current_category)

func _populate_items(grid: GridContainer, category: String) -> void:
	"""Populate grid with shop items"""
	# Clear existing items
	for child in grid.get_children():
		child.queue_free()
	
	# Filter items by category
	var filtered_items = shop_items
	if category != "All":
		filtered_items = shop_items.filter(func(item): return item.category == category)
	
	# Create item cards
	for item in filtered_items:
		var card = _create_item_card(item)
		grid.add_child(card)

func _create_item_card(item: Dictionary) -> PanelContainer:
	"""Create a card for a shop item"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 280)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)
	
	# Item image (placeholder)
	var image = TextureRect.new()
	image.custom_minimum_size = Vector2(180, 180)
	image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(item.image):
		image.texture = load(item.image)
	vbox.add_child(image)
	
	# Item name
	var name_label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Item category
	var cat_label = Label.new()
	cat_label.text = item.category
	cat_label.add_theme_font_size_override("font_size", 12)
	cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_label.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(cat_label)
	
	# Item price (using gems)
	var price_label = Label.new()
	price_label.text = "💎 %d" % item.price
	price_label.add_theme_font_size_override("font_size", 18)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.modulate = Color(0.2, 0.8, 0.2)
	vbox.add_child(price_label)
	
	# Buy button
	var buy_btn = Button.new()
	buy_btn.text = "Buy"
	buy_btn.pressed.connect(_on_item_clicked.bind(item))
	vbox.add_child(buy_btn)
	
	return card

func _on_close_pressed() -> void:
	"""Close the shop"""
	visible = false
	print("[ShopPanel] Shop closed")

func _on_category_selected(category: String) -> void:
	"""Filter items by category"""
	current_category = category
	_build_shop_ui()
	print("[ShopPanel] Category selected: ", category)

func _on_item_clicked(item: Dictionary) -> void:
	"""Handle item purchase"""
	print("[ShopPanel] Purchase requested: ", item.name, " for ", item.price, " gems")
	
	# Check if player has enough currency
	if PlayerManager.player:
		var player_currency = PlayerManager.player.currency
		if player_currency >= item.price:
			# Deduct currency
			PlayerManager.player.currency -= item.price
			print("[ShopPanel] Purchase successful! Remaining gems: ", PlayerManager.player.currency)
			
			# Show success message (you can add a popup here)
			_show_purchase_message("Purchased " + item.name + "!", Color.GREEN)
		else:
			print("[ShopPanel] Not enough gems! Need ", item.price, " but have ", player_currency)
			_show_purchase_message("Not enough gems!", Color.RED)
	else:
		print("[ShopPanel] Player not found")

func _show_purchase_message(message: String, color: Color) -> void:
	"""Show a temporary purchase message"""
	# Find or create message label
	var msg_label = get_node_or_null("MessageLabel")
	if not msg_label:
		msg_label = Label.new()
		msg_label.name = "MessageLabel"
		msg_label.add_theme_font_size_override("font_size", 24)
		msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		msg_label.anchor_left = 0.5
		msg_label.anchor_right = 0.5
		msg_label.anchor_top = 0.1
		msg_label.anchor_bottom = 0.1
		msg_label.offset_left = -200
		msg_label.offset_right = 200
		msg_label.offset_top = -20
		msg_label.offset_bottom = 20
		add_child(msg_label)
	
	msg_label.text = message
	msg_label.modulate = color
	msg_label.visible = true
	
	# Hide after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if msg_label:
		msg_label.visible = false

func show_shop() -> void:
	"""Show the shop"""
	visible = true
	print("[ShopPanel] Shop opened")
