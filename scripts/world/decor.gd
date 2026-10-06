extends Node2D
## Petits détails posés au sol (touffes d'herbe, fleurs, cailloux), purement décoratifs.
## Tout est dessiné une seule fois : le coût à l'affichage est quasi nul.

const FLOWER_COLORS := [Color("e8e2c8"), Color("e6c95a"), Color("b48ac9"), Color("d9786a")]

var _tufts: Array[Vector2] = []
var _flowers: Array[Array] = []
var _pebbles: Array[Vector2] = []


func populate(ground: IsoGround, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var half := Vector2(ground.TILE_SIZE) * 0.3
	for cell: Vector2i in ground.get_used_cells():
		var center := ground.map_to_local(cell)
		match ground.terrain_at(cell):
			IsoGround.Terrain.GRASS:
				for i in rng.randi_range(0, 3):
					_tufts.append(center + Vector2(rng.randf_range(-half.x, half.x), rng.randf_range(-half.y, half.y)))
				if rng.randf() < 0.1:
					var color: Color = FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()]
					for i in rng.randi_range(2, 5):
						_flowers.append([center + Vector2(rng.randf_range(-12, 12), rng.randf_range(-6, 6)), color])
			IsoGround.Terrain.STONE:
				for i in rng.randi_range(0, 2):
					_pebbles.append(center + Vector2(rng.randf_range(-half.x, half.x), rng.randf_range(-half.y, half.y)))
	queue_redraw()


func _draw() -> void:
	var blade_dark := Color("4a6230")
	var blade_light := Color("7d9645")
	for p in _tufts:
		draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 0), p + Vector2(-4, -7), p + Vector2(-1, 0)]), blade_light)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-1, 0), p + Vector2(0, -9), p + Vector2(1.5, 0)]), blade_dark)
		draw_colored_polygon(PackedVector2Array([p + Vector2(1, 0), p + Vector2(4, -6), p + Vector2(3, 0)]), blade_light)
	for flower: Array in _flowers:
		var p: Vector2 = flower[0]
		draw_line(p, p + Vector2(0, -4), blade_dark, 1.0)
		draw_circle(p + Vector2(0, -5), 1.8, flower[1])
	for p in _pebbles:
		draw_set_transform(p, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2(1, 1), 2.6, Color(0.1, 0.08, 0.06, 0.35))
		draw_circle(Vector2.ZERO, 2.4, Color("8a847a"))
		draw_circle(Vector2(-0.8, -0.8), 1.1, Color("b3ac9f"))
	draw_set_transform(Vector2.ZERO)
