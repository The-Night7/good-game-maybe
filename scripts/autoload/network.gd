extends Node
## Mode de jeu et connexion réseau.
##
## Le serveur fait autorité sur tout ce qui compte (vie, combat, butin, sac).
## En solo, le jeu tourne avec un OfflineMultiplayerPeer : le joueur est son propre
## serveur, donc le même code sert pour le solo, l'hôte et le serveur dédié.

enum Mode { SOLO, HOST, CLIENT, DEDICATED }

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 16
const MENU_SCENE := "res://scenes/main_menu.tscn"
const WORLD_SCENE := "res://scenes/main.tscn"

var mode := Mode.SOLO
var address := "127.0.0.1"
var port := DEFAULT_PORT
## Message affiché au retour au menu (connexion perdue, échec…).
var last_error := ""


func _ready() -> void:
	# Serveur dédié : godot --headless --path . -- --server [--port=7777]
	var args := OS.get_cmdline_user_args()
	if "--server" in args:
		mode = Mode.DEDICATED
		for arg in args:
			if arg.begins_with("--port="):
				port = arg.trim_prefix("--port=").to_int()
		get_tree().change_scene_to_file.call_deferred(WORLD_SCENE)


func play(new_mode: Mode, new_address := "") -> void:
	mode = new_mode
	if not new_address.is_empty():
		address = new_address
	last_error = ""
	get_tree().change_scene_to_file(WORLD_SCENE)


## Crée la connexion. Appelé par le monde une fois la carte prête,
## pour que les entités envoyées par le serveur trouvent leur place.
func start_peer() -> Error:
	match mode:
		Mode.SOLO:
			multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		Mode.HOST, Mode.DEDICATED:
			var peer := ENetMultiplayerPeer.new()
			var err := peer.create_server(port, MAX_PLAYERS)
			if err != OK:
				return err
			multiplayer.multiplayer_peer = peer
		Mode.CLIENT:
			var peer := ENetMultiplayerPeer.new()
			var err := peer.create_client(address, port)
			if err != OK:
				return err
			multiplayer.multiplayer_peer = peer
	return OK


func has_local_player() -> bool:
	return mode != Mode.DEDICATED


func leave(message := "") -> void:
	last_error = message
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if mode == Mode.DEDICATED:
		get_tree().quit()
	else:
		get_tree().change_scene_to_file(MENU_SCENE)


## Adresses IPv4 locales à donner aux amis pour qu'ils rejoignent.
func local_addresses() -> PackedStringArray:
	var result := PackedStringArray()
	for ip in IP.get_local_addresses():
		if ip.count(".") == 3 and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			result.append(ip)
	return result
