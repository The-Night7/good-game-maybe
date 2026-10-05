extends Control
## Choix de la disposition clavier, proposé au premier lancement sur PC.


func _ready() -> void:
	%QwertyButton.pressed.connect(_choose.bind(Settings.LAYOUT_QWERTY))
	%AzertyButton.pressed.connect(_choose.bind(Settings.LAYOUT_AZERTY))


## Affiche la fenêtre en mettant en avant la disposition supposée.
func open() -> void:
	show()
	if Settings.effective_keyboard_layout() == Settings.LAYOUT_AZERTY:
		%AzertyButton.grab_focus()
	else:
		%QwertyButton.grab_focus()


func _choose(layout: String) -> void:
	Settings.set_keyboard_layout(layout)
	hide()
