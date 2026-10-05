extends CanvasLayer
## Interface en jeu : D-pad tactile, menu d'options et choix du clavier.

var _layouts: Array[String] = [Settings.LAYOUT_QWERTY, Settings.LAYOUT_AZERTY]

@onready var _dpad: DPad = $DPad
@onready var _options_panel: PanelContainer = $OptionsPanel
@onready var _dpad_toggle: CheckButton = %DPadToggle
@onready var _keyboard_row: Control = %KeyboardRow
@onready var _keyboard_select: OptionButton = %KeyboardSelect
@onready var _keyboard_setup: Control = $KeyboardSetup


func _ready() -> void:
	_dpad_toggle.toggled.connect(Settings.set_dpad_enabled)
	_keyboard_select.item_selected.connect(func(index: int) -> void: Settings.set_keyboard_layout(_layouts[index]))
	_keyboard_row.visible = not OS.has_feature("mobile")
	$OptionsButton.pressed.connect(func() -> void: _options_panel.visible = not _options_panel.visible)
	%CloseButton.pressed.connect(_options_panel.hide)
	Settings.changed.connect(_apply_settings)
	_apply_settings()

	if Settings.needs_keyboard_setup():
		_keyboard_setup.open()


func _apply_settings() -> void:
	_dpad.visible = Settings.dpad_enabled
	_dpad_toggle.set_pressed_no_signal(Settings.dpad_enabled)
	_keyboard_select.select(_layouts.find(Settings.effective_keyboard_layout()))
