extends Node2D
## Le monde : carte, entités et règles côté serveur (apparitions, butin, sauvegarde).
##
## Tous les joueurs génèrent la même carte à partir de la même graine. Le serveur fait
## apparaître joueurs et monstres via le MultiplayerSpawner, qui les recrée chez chacun.

signal local_player_spawned(player: Player)

const PlayerScene := preload("res://scenes/player.tscn")
const MonsterScene := preload("res://scenes/monster.tscn")
const ResourceScene := preload("res://scenes/resource_node.tscn")
const Effect := preload("res://scripts/world/effect.gd")
const FloatText := preload("res://scripts/world/float_text.gd")

const WORLD_SEED := 1337
const SAVE_PATH := "user://world_save.json"
const SAVE_DELAY := 5.0
const MONSTER_RESPAWN_DELAY := 20.0
## Distance minimale (en tuiles) entre le camp de départ et les monstres.
const MONSTER_SAFE_DISTANCE := 7.0
const MONSTER_COUNTS := {"slime": 16, "rock_slime": 6}
## Chance d'avoir un point de récolte sur une tuile, selon le terrain.
const RESOURCE_CHANCES := {
	IsoGround.Terrain.GRASS: {"tree": 0.05, "bush": 0.03},
	IsoGround.Terrain.STONE: {"rock": 0.18},
}

@onready var _ground: IsoGround = $Ground
@onready var _entities: Node2D = $Entities
@onready var _effects: Node2D = $Effects
@onready var _spawner: MultiplayerSpawner = $Spawner

# Serveur uniquement.
var _monster_spawns: Array[Dictionary] = []
var _next_monster_id := 0
var _save := {"players": {}}
var _save_left := -1.0


func _ready() -> void:
	add_to_group("world")
	_ground.generate(WORLD_SEED)
	_place_resources()
	_spawner.spawn_function = _spawn_entity

	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	var err := Network.start_peer()
	if err != OK:
		Network.leave.call_deferred("Impossible de lancer la partie (port %d déjà utilisé ?)." % Network.port)
		return

	if multiplayer.is_server():
		_load_save()
		_plan_monsters()
		for index in _monster_spawns.size():
			_spawn_monster(index)
		if Network.has_local_player():
			_register(multiplayer.get_unique_id(), Settings.player_name)


func spawn_position() -> Vector2:
	var offset := Vector2(randf_range(-24, 24), randf_range(-12, 12))
	return _ground.map_to_local(_ground.spawn_cell()) + offset


func find_player(peer: int) -> Player:
	return _entities.get_node_or_null("Player_%d" % peer) as Player


func get_resource(resource_name: String) -> ResourceNode:
	return _entities.get_node_or_null(resource_name) as ResourceNode


func mark_dirty() -> void:
	if _save_left < 0.0:
		_save_left = SAVE_DELAY


# --- Connexion -------------------------------------------------------------------

func _on_connected_to_server() -> void:
	register_player.rpc_id(1, Settings.player_name)


func _on_connection_failed() -> void:
	Network.leave("Impossible de rejoindre %s." % Network.address)


func _on_server_disconnected() -> void:
	Network.leave("La connexion avec l'hôte a été perdue.")


func _on_peer_disconnected(peer: int) -> void:
	if not multiplayer.is_server():
		return
	var player := find_player(peer)
	if player:
		_save.players[player.display_name] = player.to_save()
		_write_save()
		player.queue_free()


@rpc("any_peer", "call_remote", "reliable")
func register_player(player_name: String) -> void:
	if multiplayer.is_server():
		_register(multiplayer.get_remote_sender_id(), player_name)


func _register(peer: int, player_name: String) -> void:
	if find_player(peer):
		return
	player_name = player_name.strip_edges().left(16)
	if player_name.is_empty():
		player_name = "Aventurier %d" % peer
	var saved: Dictionary = _save.players.get(player_name, {})
	_spawner.spawn({"type": "player", "peer": peer, "name": player_name, "position": spawn_position(), "save": saved})
	if peer != multiplayer.get_unique_id():
		_sync_resources.rpc_id(peer, _resource_states())


## Appelé chez tout le monde par le MultiplayerSpawner.
func _spawn_entity(data: Dictionary) -> Node:
	match data.type:
		"player":
			var player: Player = PlayerScene.instantiate()
			player.name = "Player_%d" % data.peer
			player.position = data.position
			player.display_name = data.name
			player.apply_save(data.save)
			return player
		"monster":
			var monster: Monster = MonsterScene.instantiate()
			monster.name = "Monster_%d" % data.id
			monster.setup(data.kind, data.position, data.index)
			return monster
	return null


# --- Monstres --------------------------------------------------------------------

func _plan_monsters() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = WORLD_SEED
	var by_terrain := {IsoGround.Terrain.GRASS: [], IsoGround.Terrain.STONE: []}
	var spawn := Vector2(_ground.spawn_cell())
	for cell: Vector2i in _ground.get_used_cells():
		var terrain := _ground.terrain_at(cell)
		if terrain in by_terrain and Vector2(cell).distance_to(spawn) > MONSTER_SAFE_DISTANCE and not _has_resource(cell):
			by_terrain[terrain].append(cell)
	var habitat := {"slime": IsoGround.Terrain.GRASS, "rock_slime": IsoGround.Terrain.STONE}
	for kind: String in MONSTER_COUNTS:
		var cells: Array = by_terrain[habitat[kind]]
		for i in mini(MONSTER_COUNTS[kind], cells.size()):
			var cell: Vector2i = cells.pop_at(rng.randi_range(0, cells.size() - 1))
			_monster_spawns.append({"kind": kind, "position": _ground.map_to_local(cell)})


func _spawn_monster(index: int) -> void:
	var spawn: Dictionary = _monster_spawns[index]
	_next_monster_id += 1
	_spawner.spawn({"type": "monster", "id": _next_monster_id, "kind": spawn.kind, "position": spawn.position, "index": index})


## Serveur : butin pour celui qui a donné le coup final, puis réapparition plus tard.
func on_monster_killed(monster: Monster, killer_peer: int) -> void:
	var killer := find_player(killer_peer)
	if killer:
		var loot := {}
		var loot_table: Dictionary = GameData.MONSTERS[monster.kind].loot
		for item: String in loot_table:
			var amount := randi_range(loot_table[item][0], loot_table[item][1])
			if amount > 0:
				loot[item] = amount
		killer.add_items(loot)
		var lines := PackedStringArray()
		for item: String in loot:
			lines.append("+%d %s" % [loot[item], GameData.item_name(item)])
		float_text.rpc_id(killer_peer, monster.global_position + Vector2(0, -60), "  ".join(lines), Color("8ef0c0"))
	get_tree().create_timer(MONSTER_RESPAWN_DELAY).timeout.connect(_spawn_monster.bind(monster.spawn_index))


# --- Points de récolte -----------------------------------------------------------

func _place_resources() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = WORLD_SEED + 1
	var index := 0
	for cell: Vector2i in _ground.get_used_cells():
		var chances: Dictionary = RESOURCE_CHANCES.get(_ground.terrain_at(cell), {})
		if chances.is_empty() or _ground.is_near_spawn(cell):
			continue
		var roll := rng.randf()
		for kind: String in chances:
			if roll < chances[kind]:
				var resource: ResourceNode = ResourceScene.instantiate()
				resource.name = "Resource_%d" % index
				resource.setup(kind)
				resource.position = _ground.map_to_local(cell)
				resource.set_meta("cell", cell)
				_entities.add_child(resource)
				index += 1
				break
			roll -= chances[kind]


func _has_resource(cell: Vector2i) -> bool:
	for resource: ResourceNode in get_tree().get_nodes_in_group("resources"):
		if resource.get_meta("cell") == cell:
			return true
	return false


func _resource_states() -> Dictionary:
	var states := {}
	for resource: ResourceNode in get_tree().get_nodes_in_group("resources"):
		if resource.remaining != GameData.RESOURCES[resource.kind].hits:
			states[String(resource.name)] = resource.remaining
	return states


@rpc("authority", "call_remote", "reliable")
func _sync_resources(states: Dictionary) -> void:
	for resource_name: String in states:
		var resource := get_resource(resource_name)
		if resource:
			resource.remaining = states[resource_name]


# --- Effets (envoyés par le serveur à tout le monde) ------------------------------

@rpc("authority", "call_local", "unreliable")
func play_effect(kind: String, from: Vector2, to: Vector2, radius: float, color: Color) -> void:
	var effect := Effect.new()
	effect.kind = kind
	effect.from = from
	effect.to = to
	effect.radius = radius
	effect.color = color
	_effects.add_child(effect)


@rpc("authority", "call_local", "reliable")
func float_text(at: Vector2, text: String, color: Color) -> void:
	var label := FloatText.new()
	label.position = at
	label.text = text
	label.color = color
	_effects.add_child(label)


# --- Sauvegarde (serveur) --------------------------------------------------------

func _process(delta: float) -> void:
	if _save_left >= 0.0:
		_save_left -= delta
		if _save_left < 0.0:
			_write_save()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		if Network.mode != Network.Mode.CLIENT:
			_write_save()


func _load_save() -> void:
	if not Settings.save_enabled or not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary and parsed.get("players") is Dictionary:
		_save = parsed


func _write_save() -> void:
	_save_left = -1.0
	if not Settings.save_enabled:
		return
	for player: Player in get_tree().get_nodes_in_group("players"):
		_save.players[player.display_name] = player.to_save()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_save, "\t"))
