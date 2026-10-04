extends Node2D
## Scène de jeu : génère la carte, place le joueur et les arbres.

const TreeScene := preload("res://scenes/tree.tscn")
const TREE_CHANCE := 0.06

@export var world_seed := 1337

@onready var _ground: IsoGround = $Ground
@onready var _entities: Node2D = $Entities
@onready var _player: CharacterBody2D = $Entities/Player


func _ready() -> void:
	_ground.generate(world_seed)
	_player.position = _ground.map_to_local(_ground.spawn_cell())
	_spawn_trees()


func _spawn_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	for cell: Vector2i in _ground.get_used_cells():
		if _ground.terrain_at(cell) != IsoGround.Terrain.GRASS or _ground.is_near_spawn(cell):
			continue
		if rng.randf() < TREE_CHANCE:
			var tree := TreeScene.instantiate()
			tree.position = _ground.map_to_local(cell)
			_entities.add_child(tree)
