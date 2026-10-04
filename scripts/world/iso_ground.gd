class_name IsoGround
extends TileMapLayer
## Sol isométrique généré procéduralement.
## Les textures sont dessinées par code en attendant les vrais assets.

enum Terrain { GRASS, WATER, STONE }

const TILE_SIZE := Vector2i(64, 32)
const COLORS := {
	Terrain.GRASS: Color("5a9e4b"),
	Terrain.WATER: Color("3a78c2"),
	Terrain.STONE: Color("8d8a83"),
}
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


func _build_tile_set() -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tiles.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tiles.tile_size = TILE_SIZE
	tiles.add_physics_layer()

	var image := Image.create(TILE_SIZE.x * Terrain.size(), TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	for terrain: int in Terrain.values():
		_paint_tile(image, terrain)

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


func _paint_tile(image: Image, terrain: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = terrain
	var base: Color = COLORS[terrain]
	var half := Vector2(TILE_SIZE) / 2.0
	for px in TILE_SIZE.x:
		for py in TILE_SIZE.y:
			var d := absf(px + 0.5 - half.x) / half.x + absf(py + 0.5 - half.y) / half.y
			if d > 1.02:
				continue
			var color := base.lightened(rng.randf_range(0.0, 0.06))
			if d > 0.9:
				color = base.darkened(0.15)
			image.set_pixel(terrain * TILE_SIZE.x + px, py, color)
