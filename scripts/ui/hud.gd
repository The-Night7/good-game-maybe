extends CanvasLayer
## Interface en jeu : D-pad tactile et menu d'options.

@onready var _dpad: DPad = $DPad
@onready var _options_panel: PanelContainer = $OptionsPanel
@onready var _dpad_toggle: CheckButton = %DPadToggle


func _ready() -> void:
	_dpad_toggle.button_pressed = Settings.dpad_enabled
	_dpad_toggle.toggled.connect(Settings.set_dpad_enabled)
	$OptionsButton.pressed.connect(func() -> void: _options_panel.visible = not _options_panel.visible)
	%CloseButton.pressed.connect(_options_panel.hide)
	Settings.changed.connect(_apply_settings)
	_apply_settings()


func _apply_settings() -> void:
	_dpad.visible = Settings.dpad_enabled
