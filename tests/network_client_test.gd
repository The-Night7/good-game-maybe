extends SceneTree
## Test réseau, côté client. Lancer d'abord un serveur :
##   godot --headless --path . -- --server --port=7791
## puis un ou plusieurs clients :
##   godot --headless --path . -s res://tests/network_client_test.gd -- --port=7791 --name=A --expect-players=2
## Options : --expect-item=ore:1 vérifie que la sauvegarde du joueur a été rechargée.

var _failures := 0


func _initialize() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=")
		args[parts[0]] = parts[1] if parts.size() > 1 else ""
	var expected_players := int(args.get("expect-players", "1"))

	await process_frame
	var settings: Node = root.get_node("Settings")
	settings.save_enabled = false
	settings.player_name = args.get("name", "Testeur")
	var network: Node = root.get_node("Network")
	network.mode = 2  # Client
	network.address = "127.0.0.1"
	network.port = int(args.get("port", "7791"))

	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

	var player: Player = null
	for i in 300:
		await process_frame
		player = main.get_node_or_null("Entities/Player_%d" % root.multiplayer.get_unique_id())
		if player and player.is_inside_tree():
			break
	_check(player != null, "[%s] connecté, personnage reçu" % settings.player_name)
	if player == null:
		quit(1)
		return
	await create_timer(0.5).timeout
	_check(get_nodes_in_group("monsters").size() == 22, "[%s] monstres répliqués" % settings.player_name)
	_check(player.item_count("sword_wood") == 1, "[%s] sac reçu du serveur" % settings.player_name)
	# --expect-item=ore:1 : vérifie qu'une sauvegarde précédente a été rechargée.
	if args.has("expect-item"):
		var expected: PackedStringArray = args["expect-item"].split(":")
		_check(player.item_count(expected[0]) >= int(expected[1]), "[%s] progression retrouvée (%s)" % [settings.player_name, args["expect-item"]])

	for i in 100:
		if get_nodes_in_group("players").size() >= expected_players:
			break
		await create_timer(0.1).timeout
	_check(get_nodes_in_group("players").size() == expected_players, "[%s] voit %d joueur(s)" % [settings.player_name, expected_players])

	# Combat : la position vient du client, les dégâts du serveur.
	var slime: Monster = null
	for monster: Monster in get_nodes_in_group("monsters"):
		if monster.kind == "slime":
			slime = monster
			break
	var damaged := false
	for i in 12:
		if not is_instance_valid(slime):
			damaged = true
			break
		player.global_position = slime.global_position + Vector2(20, 0)
		await create_timer(0.15).timeout
		player.use_skill(0)
		await create_timer(0.45).timeout
		if not is_instance_valid(slime) or slime.hp < slime.max_hp:
			damaged = true
			break
	_check(damaged, "[%s] le serveur applique les dégâts" % settings.player_name)

	# Récolte : le sac est mis à jour par le serveur.
	var target: ResourceNode = null
	for resource: ResourceNode in get_nodes_in_group("resources"):
		if not resource.is_depleted():
			target = resource
			break
	player.global_position = target.global_position + Vector2(0, 12)
	await create_timer(0.3).timeout
	var item: String = GameData.RESOURCES[player.nearest_resource(Player.INTERACT_RANGE).kind].item
	var count_before := player.item_count(item)
	player.harvest_nearest()
	await create_timer(0.5).timeout
	_check(player.item_count(item) == count_before + 1, "[%s] récolte validée par le serveur" % settings.player_name)

	await create_timer(1.0).timeout
	print("[%s] %s" % [settings.player_name, "FAILURES: %d" % _failures if _failures else "ALL NETWORK TESTS PASSED"])
	quit(1 if _failures else 0)


func _check(condition: bool, label: String) -> void:
	print(("ok   " if condition else "FAIL ") + label)
	if not condition:
		_failures += 1
