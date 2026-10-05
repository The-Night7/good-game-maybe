extends Control
## Menu principal : jouer seul, héberger une partie pour ses amis, ou en rejoindre une.


func _ready() -> void:
	%NameEdit.text = Settings.player_name
	%AddressEdit.text = Settings.last_address
	%ErrorLabel.text = Network.last_error
	%SoloButton.pressed.connect(_start.bind(Network.Mode.SOLO))
	%HostButton.pressed.connect(_start.bind(Network.Mode.HOST))
	%JoinButton.pressed.connect(_start.bind(Network.Mode.CLIENT))


func _start(mode: Network.Mode) -> void:
	Settings.set_player_name(%NameEdit.text)
	if mode == Network.Mode.CLIENT:
		var address: String = %AddressEdit.text.strip_edges()
		if address.is_empty():
			%ErrorLabel.text = "Entre l'adresse IP de l'hôte (elle s'affiche en haut de son écran)."
			return
		Settings.set_last_address(address)
		Network.play(mode, address)
	else:
		Network.play(mode)
