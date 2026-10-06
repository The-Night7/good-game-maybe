extends CanvasLayer
## Interface en jeu, pensée pour le mobile : D-pad à gauche, actions à droite
## (style Guardian Tales), état du personnage, sac / artisanat et options.

var _player: Player

@onready var _dpad: DPad = $DPad
@onready var _attack: SkillButton = %AttackButton
@onready var _skill_buttons: Array[SkillButton] = [%SkillButton1, %SkillButton2]
@onready var _potion: SkillButton = %PotionButton
@onready var _actions: Control = $Actions
@onready var _name_label: Label = %NameLabel
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_label: Label = %HpLabel
@onready var _info_label: Label = %InfoLabel
@onready var _knockout_label: Label = $KnockoutLabel
@onready var _options_panel: PanelContainer = $OptionsPanel
@onready var _inventory_panel: InventoryPanel = $InventoryPanel
@onready var _dpad_toggle: CheckButton = %DPadToggle


func _ready() -> void:
	_dpad_toggle.toggled.connect(Settings.set_dpad_enabled)
	%OptionsButton.pressed.connect(_toggle_panel.bind(_options_panel))
	%BagButton.pressed.connect(_toggle_panel.bind(_inventory_panel))
	%CloseButton.pressed.connect(_options_panel.hide)
	%LeaveButton.pressed.connect(func() -> void: Network.leave())
	_attack.triggered.connect(_on_attack)
	for i in _skill_buttons.size():
		_skill_buttons[i].triggered.connect(_on_skill.bind(i + 1))
	_potion.triggered.connect(_on_potion)
	Settings.changed.connect(_apply_settings)
	_options_panel.visibility_changed.connect(_update_controls)
	_inventory_panel.visibility_changed.connect(_update_controls)
	get_parent().local_player_spawned.connect(_bind_player)
	multiplayer.connected_to_server.connect(_update_info)

	_actions.hide()
	%BagButton.hide()
	_knockout_label.hide()
	_apply_settings()
	_update_info()


func _process(_delta: float) -> void:
	if _player == null:
		return
	if _player.should_harvest():
		_attack.set_label("Récolter")
		_attack.set_icon("harvest")
		_attack.color = Color("4a6b34")
	else:
		var skill: Dictionary = _player.skills()[0]
		_attack.set_label(skill.name)
		_attack.set_icon(skill.icon)
		_attack.color = Color("8a2f28")


func _bind_player(player: Player) -> void:
	_player = player
	player.stats_changed.connect(_update_stats)
	player.equipment_changed.connect(_update_equipment)
	player.inventory_changed.connect(_update_inventory)
	_inventory_panel.bind(player)
	%BagButton.show()
	_name_label.text = player.display_name
	_update_controls()
	_update_stats()
	_update_equipment()
	_update_inventory()
	_update_info()


func _on_attack() -> void:
	if _player == null or _player.dead:
		_attack.start_cooldown(0.3)
	elif _player.should_harvest():
		_player.harvest_nearest()
		_attack.start_cooldown(Player.HARVEST_COOLDOWN)
	else:
		_attack.start_cooldown(_player.use_skill(0))


func _on_skill(slot: int) -> void:
	if _player and not _player.dead:
		_skill_buttons[slot - 1].start_cooldown(_player.use_skill(slot))


func _on_potion() -> void:
	if _player and not _player.dead and _player.hp < _player.max_hp and _player.item_count("potion") > 0:
		_player.use_item("potion")
		_potion.start_cooldown(1.0)


func _update_stats() -> void:
	_hp_bar.max_value = _player.max_hp
	_hp_bar.value = _player.hp
	_hp_label.text = "%d / %d" % [_player.hp, _player.max_hp]
	_knockout_label.visible = _player.dead
	_actions.modulate.a = 0.4 if _player.dead else 1.0


func _update_equipment() -> void:
	var skills := _player.skills()
	var weapon: String = GameData.ITEMS[_player.weapon_id].weapon
	var colors := {"sword": Color("33506e"), "bow": Color("4d5f2a"), "staff": Color("5e3a6e")}
	for i in _skill_buttons.size():
		_skill_buttons[i].set_label(skills[i + 1].name)
		_skill_buttons[i].set_icon(skills[i + 1].icon)
		_skill_buttons[i].color = colors[weapon]


func _update_inventory() -> void:
	var potions := _player.item_count("potion")
	_potion.badge = str(potions)
	_potion.enabled = potions > 0


func _update_info() -> void:
	match Network.mode:
		Network.Mode.SOLO:
			_info_label.text = "Partie solo"
		Network.Mode.HOST:
			var addresses := Network.local_addresses()
			var address := addresses[0] if not addresses.is_empty() else "?"
			_info_label.text = "Hôte — tes amis rejoignent : %s" % address
		Network.Mode.CLIENT:
			if _player:
				_info_label.text = "En ligne sur %s" % Network.address
			else:
				_info_label.text = "Connexion à %s…" % Network.address
		Network.Mode.DEDICATED:
			_info_label.text = "Serveur dédié"


func _toggle_panel(panel: Control) -> void:
	var opening := not panel.visible
	_options_panel.hide()
	_inventory_panel.hide()
	panel.visible = opening


func _apply_settings() -> void:
	_dpad_toggle.set_pressed_no_signal(Settings.dpad_enabled)
	_update_controls()


## Les commandes tactiles sont masquées quand un panneau est ouvert,
## pour qu'un appui sur un bouton du panneau ne déclenche pas une compétence.
func _update_controls() -> void:
	var panel_open := _options_panel.visible or _inventory_panel.visible
	_dpad.visible = Settings.dpad_enabled and not panel_open
	_actions.visible = _player != null and not panel_open


