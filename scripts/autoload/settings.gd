extends Node
## Préférences du joueur, sauvegardées dans user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"

## D-pad virtuel à l'écran. Activé par défaut sur les appareils tactiles.
var dpad_enabled := false
var player_name := "Aventurier"
## Dernière adresse utilisée pour rejoindre une partie.
var last_address := ""
## Désactivé par les tests pour ne pas écraser les préférences réelles.
var save_enabled := true


func _ready() -> void:
	dpad_enabled = DisplayServer.is_touchscreen_available()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		dpad_enabled = cfg.get_value("controls", "dpad_enabled", dpad_enabled)
		player_name = cfg.get_value("player", "name", player_name)
		last_address = cfg.get_value("network", "last_address", last_address)


func set_dpad_enabled(value: bool) -> void:
	if value == dpad_enabled:
		return
	dpad_enabled = value
	_save()
	changed.emit()


func set_player_name(value: String) -> void:
	value = value.strip_edges().left(16)
	if value.is_empty() or value == player_name:
		return
	player_name = value
	_save()


func set_last_address(value: String) -> void:
	last_address = value.strip_edges()
	_save()


func _save() -> void:
	if not save_enabled:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "dpad_enabled", dpad_enabled)
	cfg.set_value("player", "name", player_name)
	cfg.set_value("network", "last_address", last_address)
	cfg.save(PATH)
