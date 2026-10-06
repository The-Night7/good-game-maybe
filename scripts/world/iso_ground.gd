class_name IsoGround
extends TileMapLayer
## Sol isométrique généré procéduralement.
##
## Les tuiles servent à la logique (type de terrain, collisions de l'eau) et restent
## invisibles. Le rendu est fait par un shader « peint » (voir shaders/ground.gdshader),
## sans quadrillage, dans l'esprit d'Albion Online.

enum Terrain { GRASS, WATER, STONE }

const TILE_SIZE := Vector2i(64, 32)
const GROUND_SHADER := preload("res://shaders/ground.gdshader")
## Marge d'eau dessinée autour de la carte, pour que la caméra ne voie jamais le vide.
const OCEAN_MARGIN := 24.0
## Rayon (en tuiles) gardé dégagé autour du point d'apparition.
const SPAWN_CLEARING := 4.0

@export var map_size := Vector2i(48, 48)


func generate(seed_value: int) -> void:
	tile_set = _build_tile_set()
	clear()
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.08
	for x in map_size.x:
		for y in map_size.y:
			var cell := Vector2i(x, y)
			set_cell(cell, 0, Vector2i(_terrain_for(cell, noise), 0))
	_build_painted_ground()


func terrain_at(cell: Vector2i) -> int:
	return get_cell_atlas_coords(cell).x


func spawn_cell() -> Vector2i:
	return map_size / 2


func is_near_spawn(cell: Vector2i) -> bool:
	return Vector2(cell).distance_to(Vector2(spawn_cell())) < SPAWN_CLEARING


func _terrain_for(cell: Vector2i, noise: FastNoiseLite) -> int:
	# Bordure d'eau : limite naturelle de la carte.
	if cell.x == 0 or cell.y == 0 or cell.x == map_size.x - 1 or cell.y == map_size.y - 1:
		return Terrain.WATER
	if is_near_spawn(cell):
		return Terrain.GRASS
	var value := noise.get_noise_2d(cell.x, cell.y)
	if value < -0.3:
		return Terrain.WATER
	if value > 0.35:
		return Terrain.STONE
	return Terrain.GRASS


## Polygone couvrant la carte (et un océan autour), peint par le shader du sol.
func _build_painted_ground() -> void:
	var terrain_map := Image.create(map_size.x, map_size.y, false, Image.FORMAT_RGB8)
	var channels := {Terrain.GRASS: Color.RED, Terrain.STONE: Color.GREEN, Terrain.WATER: Color.BLUE}
	for x in map_size.x:
		for y in map_size.y:
			terrain_map.set_pixel(x, y, channels[terrain_at(Vector2i(x, y))])

	var origin := map_to_local(Vector2i.ZERO)
	var axis_x := map_to_local(Vector2i(1, 0)) - origin
	var axis_y := map_to_local(Vector2i(0, 1)) - origin
	var inverse := Transform2D(axis_x, axis_y, Vector2.ZERO).affine_inverse()

	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("terrain_map", ImageTexture.create_from_image(terrain_map))
	material.set_shader_parameter("map_size", Vector2(map_size))
	material.set_shader_parameter("origin", origin)
	material.set_shader_parameter("inv_x", inverse.x)
	material.set_shader_parameter("inv_y", inverse.y)

	var low := -0.5 - OCEAN_MARGIN
	var high_x := map_size.x - 0.5 + OCEAN_MARGIN
	var high_y := map_size.y - 0.5 + OCEAN_MARGIN
	var corners := PackedVector2Array()
	for corner: Vector2 in [Vector2(low, low), Vector2(high_x, low), Vector2(high_x, high_y), Vector2(low, high_y)]:
		corners.append(origin + axis_x * corner.x + axis_y * corner.y)

	var painted := Polygon2D.new()
	painted.name = "Painted"
	painted.polygon = corners
	painted.material = material
	painted.show_behind_parent = true
	add_child(painted)


func _build_tile_set() -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tiles.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tiles.tile_size = TILE_SIZE
	tiles.add_physics_layer()

	# Tuiles transparentes : seul le shader dessine le sol.
	var image := Image.create(TILE_SIZE.x * Terrain.size(), TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = TILE_SIZE
	tiles.add_source(source, 0)

	var half := Vector2(TILE_SIZE) / 2.0
	var diamond := PackedVector2Array([
		Vector2(-half.x, 0), Vector2(0, -half.y), Vector2(half.x, 0), Vector2(0, half.y),
	])
	for terrain: int in Terrain.values():
		var coords := Vector2i(terrain, 0)
		source.create_tile(coords)
		if terrain == Terrain.WATER:
			var data := source.get_tile_data(coords, 0)
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, diamond)
	return tiles
