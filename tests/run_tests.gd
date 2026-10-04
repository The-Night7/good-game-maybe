extends SceneTree
## Tests sans affichage : godot --headless --path . -s res://tests/run_tests.gd

var _failures := 0


func _initialize() -> void:
	await process_frame
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	await _test_dpad_directions(main)
	await _test_dpad_drives_player(main)
	await _test_water_blocks_player(main)
	_test_dpad_option(main)

	print("FAILURES: %d" % _failures if _failures else "ALL TESTS PASSED")
	quit(1 if _failures else 0)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("ok   ", label)
	else:
		_failures += 1
		print("FAIL ", label)


func _test_dpad_directions(main: Node) -> void:
	var dpad: DPad = main.get_node("HUD/DPad")
	var center := dpad.get_global_transform_with_canvas() * (dpad.size / 2.0)
	var r := dpad.size.x / 2.0
	_check(dpad.direction_for(center) == Vector2.ZERO, "zone morte au centre")
	_check(dpad.direction_for(center + Vector2(r * 0.8, 0)) == Vector2.RIGHT, "droite")
	_check(dpad.direction_for(center + Vector2(0, -r * 0.8)) == Vector2.UP, "haut")
	_check(dpad.direction_for(center + Vector2(-r * 0.6, r * 0.6)) == Vector2(-1, 1), "diagonale bas-gauche")


func _test_dpad_drives_player(main: Node) -> void:
	var dpad: DPad = main.get_node("HUD/DPad")
	var player: CharacterBody2D = main.get_node("Entities/Player")
	dpad.show()
	var center := dpad.get_global_transform_with_canvas() * (dpad.size / 2.0)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = center + Vector2(dpad.size.x * 0.4, 0)
	root.push_input(touch, true)
	await process_frame
	_check(Input.is_action_pressed("move_right"), "le toucher presse move_right")
	var start := player.position
	for i in 20:
		await physics_frame
	_check(player.position.x > start.x + 10, "le joueur avance vers la droite")
	touch.pressed = false
	root.push_input(touch, true)
	await process_frame
	_check(not Input.is_action_pressed("move_right"), "relâcher arrête le mouvement")


func _test_water_blocks_player(main: Node) -> void:
	var ground: IsoGround = main.get_node("Ground")
	var player: CharacterBody2D = main.get_node("Entities/Player")
	# On place le joueur au bord de la carte (eau) et on pousse vers l'extérieur.
	player.position = ground.map_to_local(Vector2i(2, ground.map_size.y / 2))
	Input.action_press("move_left")
	for i in 120:
		await physics_frame
	Input.action_release("move_left")
	var cell := ground.local_to_map(player.position)
	_check(ground.terrain_at(cell) != IsoGround.Terrain.WATER, "l'eau bloque le joueur")


func _test_dpad_option(main: Node) -> void:
	var settings: Node = root.get_node("Settings")
	var dpad: DPad = main.get_node("HUD/DPad")
	settings.set_dpad_enabled(true)
	_check(dpad.visible, "option D-pad activée -> visible")
	settings.set_dpad_enabled(false)
	_check(not dpad.visible, "option D-pad désactivée -> masqué")
