class_name InventoryPanel
extends PanelContainer
## Sac et artisanat, pensés pour le tactile (gros boutons).
## Toucher un équipement l'équipe, toucher une potion la boit.

var _player: Player
var _equipment_label: Label
var _grid: GridContainer
var _recipes: VBoxContainer


func _ready() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := Label.new()
	title.text = "Sac & artisanat"
	title.add_theme_font_size_override("font_size", 26)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "Fermer"
	close.custom_minimum_size = Vector2(130, 52)
	close.pressed.connect(hide)
	header.add_child(close)

	_equipment_label = Label.new()
	_equipment_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	layout.add_child(_equipment_label)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = SIZE_EXPAND_FILL
	layout.add_child(tabs)

	var bag := ScrollContainer.new()
	bag.name = "Sac"
	bag.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(bag)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	bag.add_child(_grid)

	var crafting := ScrollContainer.new()
	crafting.name = "Artisanat"
	crafting.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(crafting)
	_recipes = VBoxContainer.new()
	_recipes.size_flags_horizontal = SIZE_EXPAND_FILL
	_recipes.add_theme_constant_override("separation", 10)
	crafting.add_child(_recipes)


func bind(player: Player) -> void:
	_player = player
	player.inventory_changed.connect(refresh)
	player.equipment_changed.connect(refresh)
	refresh()


func refresh() -> void:
	if _player == null:
		return
	var armor := GameData.item_name(_player.armor_id) if not _player.armor_id.is_empty() else "aucune"
	_equipment_label.text = "Arme : %s     Armure : %s" % [GameData.item_name(_player.weapon_id), armor]
	_fill_bag()
	_fill_recipes()


func _fill_bag() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for item_id: String in GameData.ITEMS:
		var count := _player.item_count(item_id)
		if count <= 0:
			continue
		var item: Dictionary = GameData.ITEMS[item_id]
		var equipped := item_id == _player.weapon_id or item_id == _player.armor_id
		var button := Button.new()
		button.custom_minimum_size = Vector2(176, 80)
		button.text = "%s\nx%d%s" % [item.name, count, "  · équipé" if equipped else ""]
		button.add_theme_color_override("font_color", item.color.lightened(0.35))
		button.add_theme_font_size_override("font_size", 17)
		if item.has("slot"):
			button.pressed.connect(_player.equip.bind(item_id))
		elif item.has("heal"):
			button.pressed.connect(_player.use_item.bind(item_id))
		else:
			button.focus_mode = Control.FOCUS_NONE
		_grid.add_child(button)
	if _grid.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "Ton sac est vide."
		_grid.add_child(empty)


func _fill_recipes() -> void:
	for child in _recipes.get_children():
		child.queue_free()
	for recipe: Dictionary in GameData.RECIPES:
		var affordable := GameData.can_afford(_player.inventory, recipe.cost)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		var name_label := Label.new()
		name_label.text = GameData.item_name(recipe.item)
		info.add_child(name_label)
		var cost_label := Label.new()
		var parts := PackedStringArray()
		for item: String in recipe.cost:
			parts.append("%s %d/%d" % [GameData.item_name(item), _player.item_count(item), recipe.cost[item]])
		cost_label.text = "   ".join(parts)
		cost_label.add_theme_font_size_override("font_size", 16)
		cost_label.add_theme_color_override("font_color", Color("9be29b") if affordable else Color("ff8a8a"))
		info.add_child(cost_label)
		row.add_child(info)

		var craft := Button.new()
		craft.text = "Fabriquer"
		craft.custom_minimum_size = Vector2(150, 56)
		craft.disabled = not affordable
		craft.pressed.connect(_player.craft.bind(recipe.item))
		row.add_child(craft)
		_recipes.add_child(row)
