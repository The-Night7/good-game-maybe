extends Node
## Préférences du joueur, sauvegardées dans user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"

## D-pad virtuel à l'écran. Activé par défaut sur les appareils tactiles.
var dpad_enabled := false


func _ready() -> void:
	dpad_enabled = DisplayServer.is_touchscreen_available()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		dpad_enabled = cfg.get_value("controls", "dpad_enabled", dpad_enabled)


func set_dpad_enabled(value: bool) -> void:
	if value == dpad_enabled:
		return
	dpad_enabled = value
	_save()
	changed.emit()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "dpad_enabled", dpad_enabled)
	cfg.save(PATH)
