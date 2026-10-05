extends Node
## Préférences du joueur, sauvegardées dans user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"

const LAYOUT_QWERTY := "qwerty"
const LAYOUT_AZERTY := "azerty"
## Touches de déplacement de chaque disposition (les flèches marchent toujours).
const KEY_PRESETS := {
	LAYOUT_QWERTY: {"move_up": KEY_W, "move_left": KEY_A, "move_down": KEY_S, "move_right": KEY_D},
	LAYOUT_AZERTY: {"move_up": KEY_Z, "move_left": KEY_Q, "move_down": KEY_S, "move_right": KEY_D},
}

## D-pad virtuel à l'écran. Activé par défaut sur les appareils tactiles.
var dpad_enabled := false
## Disposition clavier choisie, vide tant que le joueur n'a pas choisi.
var keyboard_layout := ""
## Désactivé par les tests pour ne pas écraser les préférences réelles.
var save_enabled := true

var _preset_events: Array[Dictionary] = []


func _ready() -> void:
	dpad_enabled = DisplayServer.is_touchscreen_available()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		dpad_enabled = cfg.get_value("controls", "dpad_enabled", dpad_enabled)
		keyboard_layout = cfg.get_value("controls", "keyboard_layout", keyboard_layout)
	if keyboard_layout not in KEY_PRESETS:
		keyboard_layout = ""
	_apply_keyboard_layout()


## Vrai au premier lancement sur PC : il faut proposer le choix du clavier.
func needs_keyboard_setup() -> bool:
	return keyboard_layout.is_empty() and not OS.has_feature("mobile")


## Disposition en vigueur : le choix du joueur, sinon une supposition d'après la langue.
func effective_keyboard_layout() -> String:
	if not keyboard_layout.is_empty():
		return keyboard_layout
	return LAYOUT_AZERTY if OS.get_locale_language() == "fr" else LAYOUT_QWERTY


func set_dpad_enabled(value: bool) -> void:
	if value == dpad_enabled:
		return
	dpad_enabled = value
	_save()
	changed.emit()


func set_keyboard_layout(layout: String) -> void:
	assert(layout in KEY_PRESETS, "Disposition inconnue : %s" % layout)
	if layout == keyboard_layout:
		return
	keyboard_layout = layout
	_apply_keyboard_layout()
	_save()
	changed.emit()


func _apply_keyboard_layout() -> void:
	for entry in _preset_events:
		InputMap.action_erase_event(entry.action, entry.event)
	_preset_events.clear()

	var keys: Dictionary = KEY_PRESETS[effective_keyboard_layout()]
	for action: String in keys:
		var event := InputEventKey.new()
		event.keycode = keys[action]
		InputMap.action_add_event(action, event)
		_preset_events.append({"action": action, "event": event})


func _save() -> void:
	if not save_enabled:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "dpad_enabled", dpad_enabled)
	cfg.set_value("controls", "keyboard_layout", keyboard_layout)
	cfg.save(PATH)
