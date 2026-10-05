extends SceneTree
## Tests sans affichage (partie solo) : godot --headless --path . -s res://tests/run_tests.gd

var _failures := 0
var _main: Node
var _player: Player


func _initialize() -> void:
	await process_frame
	var settings: Node = root.get_node("Settings")
	settings.save_enabled = false
	root.get_node("Network").mode = 0  # Solo

	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	await process_frame
	_player = _main.get_node_or_null("Entities/Player_1")

	_test_world()
	_test_dpad_directions()
	await _test_dpad_drives_player()
	await _test_water_blocks_player()
	_test_dpad_option()
	await _test_combat_and_loot()
	await _test_harvest()
	await _test_crafting_and_equipment()
	await _test_potion()
	await _test_death_and_respawn()

	print("FAILURES: %d" % _failures if _failures else "ALL TESTS PASSED")
	quit(1 if _failures else 0)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("ok   ", label)
	else:
		_failures += 1
		print("FAIL ", label)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _test_world() -> void:
	_check(_player != null, "le joueur local apparaît")
	_check(_player.item_count("sword_wood") == 1 and _player.item_count("potion") == 3, "équipement de départ")
	_check(get_nodes_in_group("monsters").size() == 22, "les monstres apparaissent")
	var kinds := {}
	for resource: ResourceNode in get_nodes_in_group("resources"):
		kinds[resource.kind] = true
	_check(kinds.has("tree") and kinds.has("rock") and kinds.has("bush"), "arbres, rochers et buissons à récolter")
	_check(_main.get_node("HUD/Actions").visible, "boutons d'action affichés")


func _test_dpad_directions() -> void:
	var dpad: DPad = _main.get_node("HUD/DPad")
	var center := dpad.get_global_transform_with_canvas() * (dpad.size / 2.0)
	var r := dpad.size.x / 2.0
	_check(dpad.direction_for(center) == Vector2.ZERO, "D-pad : zone morte au centre")
	_check(dpad.direction_for(center + Vector2(r * 0.8, 0)) == Vector2.RIGHT, "D-pad : droite")
	_check(dpad.direction_for(center + Vector2(0, -r * 0.8)) == Vector2.UP, "D-pad : haut")
	_check(dpad.direction_for(center + Vector2(-r * 0.6, r * 0.6)) == Vector2(-1, 1), "D-pad : diagonale bas-gauche")


func _test_dpad_drives_player() -> void:
	var dpad: DPad = _main.get_node("HUD/DPad")
	dpad.show()
	var center := dpad.get_global_transform_with_canvas() * (dpad.size / 2.0)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = center + Vector2(dpad.size.x * 0.4, 0)
	root.push_input(touch, true)
	await process_frame
	_check(Input.is_action_pressed("move_right"), "D-pad : le toucher presse move_right")

	# Deuxième doigt sur l'attaque pendant que le premier tient le D-pad.
	var attack: SkillButton = _main.get_node("HUD/Actions/AttackButton")
	var fired := [false]
	var on_fire := func() -> void: fired[0] = true
	attack.triggered.connect(on_fire)
	var second := InputEventScreenTouch.new()
	second.index = 1
	second.pressed = true
	second.position = attack.get_global_transform_with_canvas() * (attack.size / 2.0)
	root.push_input(second, true)
	await process_frame
	_check(fired[0], "multi-touch : attaque pendant le déplacement")
	second.pressed = false
	root.push_input(second, true)
	attack.triggered.disconnect(on_fire)

	var start := _player.position
	for i in 20:
		await physics_frame
	_check(_player.position.x > start.x + 10, "le joueur avance vers la droite")
	touch.pressed = false
	root.push_input(touch, true)
	await process_frame
	_check(not Input.is_action_pressed("move_right"), "relâcher arrête le mouvement")


func _test_water_blocks_player() -> void:
	var ground: IsoGround = _main.get_node("Ground")
	_player.position = ground.map_to_local(Vector2i(2, ground.map_size.y / 2))
	Input.action_press("move_left")
	for i in 120:
		await physics_frame
	Input.action_release("move_left")
	_check(ground.terrain_at(ground.local_to_map(_player.position)) != IsoGround.Terrain.WATER, "l'eau bloque le joueur")


func _test_dpad_option() -> void:
	var settings: Node = root.get_node("Settings")
	var dpad: DPad = _main.get_node("HUD/DPad")
	settings.set_dpad_enabled(true)
	_check(dpad.visible, "option D-pad activée -> visible")
	settings.set_dpad_enabled(false)
	_check(not dpad.visible, "option D-pad désactivée -> masqué")
	settings.set_dpad_enabled(true)
	_main.get_node("HUD/InventoryPanel").show()
	_check(not dpad.visible and not _main.get_node("HUD/Actions").visible, "sac ouvert -> commandes tactiles masquées")
	_main.get_node("HUD/InventoryPanel").hide()
	_check(dpad.visible and _main.get_node("HUD/Actions").visible, "sac fermé -> commandes tactiles de retour")


func _nearest_slime() -> Monster:
	var best: Monster = null
	for monster: Monster in get_nodes_in_group("monsters"):
		if monster.kind == "slime" and (best == null or monster.global_position.distance_to(_player.global_position) < best.global_position.distance_to(_player.global_position)):
			best = monster
	return best


func _test_combat_and_loot() -> void:
	var slime := _nearest_slime()
	var jelly_before := _player.item_count("jelly")
	var start_hp := slime.hp
	for i in 30:
		if not is_instance_valid(slime) or not slime.is_alive():
			break
		_player.global_position = slime.global_position + Vector2(20, 0)
		_player.use_skill(0)
		await _wait(0.55)
	_check(not is_instance_valid(slime) or not slime.is_alive(), "l'attaque de base tue un slime (%d PV)" % start_hp)
	await process_frame
	_check(_player.item_count("jelly") > jelly_before, "le slime donne de la gelée")
	_check(get_nodes_in_group("monsters").size() == 21, "le slime disparaît (réapparition plus tard)")

	# Une compétence en recharge est refusée par le serveur.
	var target := _nearest_slime()
	_player.global_position = target.global_position + Vector2(20, 0)
	_player.use_skill(1)
	var hp_after_first := target.hp
	_player.use_skill(1)
	_check(target.hp < target.max_hp, "Tourbillon touche le monstre")
	_check(target.hp == hp_after_first, "recharge respectée côté serveur")
	_player.global_position = _main.spawn_position()
	await _wait(0.3)


func _test_harvest() -> void:
	var tree: ResourceNode = null
	for resource: ResourceNode in get_nodes_in_group("resources"):
		if resource.kind == "tree" and (tree == null or resource.global_position.distance_to(_player.global_position) < tree.global_position.distance_to(_player.global_position)):
			tree = resource
	_player.global_position = tree.global_position + Vector2(0, 30)
	await physics_frame
	_check(_player.should_harvest() or _player.nearest_monster(90.0) != null, "le bouton d'action propose la récolte")
	var wood_before := _player.item_count("wood")
	for i in 3:
		_player.harvest_nearest()
		await _wait(0.65)
	_check(_player.item_count("wood") == wood_before + 3, "3 récoltes = 3 bois")
	_check(tree.is_depleted(), "l'arbre est épuisé après 3 récoltes")
	_player.harvest_nearest()
	await _wait(0.65)
	_check(_player.item_count("wood") == wood_before + 3, "un arbre épuisé ne donne plus rien")
	_player.global_position = _main.spawn_position()


func _test_crafting_and_equipment() -> void:
	_player.add_items({"wood": 10, "ore": 5, "fiber": 10, "jelly": 10})
	_player.craft("sword_iron")
	_check(_player.item_count("sword_iron") == 1, "fabriquer une épée de fer")
	_check(_player.item_count("ore") == 0, "les matériaux sont consommés")
	_player.craft("sword_iron")
	_check(_player.item_count("sword_iron") == 1, "impossible de fabriquer sans matériaux")

	_player.craft("bow_hunter")
	_player.equip("bow_hunter")
	_check(_player.weapon_id == "bow_hunter" and _player.skills()[1].name == "Pluie de flèches", "équiper l'arc change les compétences")
	var hud := _main.get_node("HUD")
	_check(hud.get_node("Actions/SkillButton1").label.begins_with("Pluie"), "le HUD affiche les compétences de l'arc")

	_player.craft("leather_vest")
	_player.equip("leather_vest")
	_check(_player.max_hp == Player.BASE_MAX_HP + 40, "la veste de cuir donne +40 PV max")
	_player.equip("sword_wood")
	_check(_player.weapon_id == "sword_wood", "rééquiper l'épée")
	_player.equip("staff_ember")
	_check(_player.weapon_id == "sword_wood", "impossible d'équiper une arme qu'on n'a pas")


func _test_potion() -> void:
	var potions := _player.item_count("potion")
	_player.hp = 50
	_player.use_item("potion")
	_check(_player.hp == 90, "la potion soigne 40 PV")
	_check(_player.item_count("potion") == potions - 1, "la potion est consommée")


func _test_death_and_respawn() -> void:
	_player.global_position = _main.spawn_position() + Vector2(200, 0)
	_player.take_damage(10000)
	_check(_player.dead and _player.hp == 0, "le joueur tombe K.O.")
	_check(_main.get_node("HUD/KnockoutLabel").visible, "le HUD affiche K.O.")
	await _wait(Player.RESPAWN_DELAY + 0.3)
	_check(not _player.dead and _player.hp == _player.max_hp, "réapparition avec toute sa vie")
	_check(_player.global_position.distance_to(_main.spawn_position()) < 60, "réapparition au camp")
