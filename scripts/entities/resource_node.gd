class_name ResourceNode
extends StaticBody2D
## Point de récolte (arbre, rocher, buisson). Son état est géré par le serveur.

var kind := "tree"
var remaining := 3:
	set(value):
		remaining = value
		queue_redraw()

var _respawn_left := 0.0


## À appeler avant l'ajout à l'arbre.
func setup(resource_kind: String) -> void:
	kind = resource_kind
	remaining = GameData.RESOURCES[kind].hits
	# On traverse les buissons ; arbres et rochers bloquent.
	if kind == "bush":
		collision_layer = 0


func _ready() -> void:
	add_to_group("resources")


func is_depleted() -> bool:
	return remaining <= 0


## Serveur : retire une récolte et renvoie l'objet obtenu.
func harvest() -> String:
	var data: Dictionary = GameData.RESOURCES[kind]
	set_remaining.rpc(remaining - 1)
	if is_depleted():
		_respawn_left = data.respawn
	return data.item


@rpc("authority", "call_local", "reliable")
func set_remaining(value: int) -> void:
	remaining = value


func _process(delta: float) -> void:
	if not multiplayer.is_server() or not is_depleted():
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		set_remaining.rpc(GameData.RESOURCES[kind].hits)


func _draw() -> void:
	var rng := Art.rng_for(position)
	match kind:
		"tree":
			_draw_tree(rng)
		"rock":
			_draw_rock(rng)
		"bush":
			_draw_bush(rng)


func _draw_tree(rng: RandomNumberGenerator) -> void:
	var size := rng.randf_range(0.9, 1.2)
	var bark := Color("5b4330")
	if is_depleted():
		Art.soft_shadow(self, Vector2.ZERO, 14.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-7, 0), Vector2(7, 0), Vector2(6, -9), Vector2(-6, -9)]), bark)
		draw_set_transform(Vector2(0, -9), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 6.5, Color("c4a06a"))
		draw_arc(Vector2.ZERO, 3.5, 0.0, TAU, 12, Color("9a7a4c"), 1.0)
		draw_set_transform(Vector2.ZERO)
		return

	Art.soft_shadow(self, Vector2(8, 2), 24.0 * size, 0.26)
	# Tronc effilé, côté gauche éclairé, racines.
	var top := -30.0 * size
	draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(3, top), Vector2(-3, top)]), bark)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(-1, 0), Vector2(-1, top), Vector2(-3, top)]), Art.lit(bark, 0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(-10, 1), Vector2(-4, -1), Vector2(-4, -6)]), bark)
	draw_colored_polygon(PackedVector2Array([Vector2(10, 1), Vector2(4, -1), Vector2(4, -6)]), Art.shade(bark, 0.2))

	# Feuillage : grappes de masses à facettes, teinte propre à chaque arbre.
	var leaves := Color.from_hsv(rng.randf_range(0.22, 0.29), rng.randf_range(0.42, 0.55), rng.randf_range(0.38, 0.48))
	var crown := Vector2(0, top - 16.0 * size)
	var clusters := [
		[Vector2(0, 8), 17.0], [Vector2(-15, 4), 14.0], [Vector2(15, 5), 14.0],
		[Vector2(-8, -9), 15.0], [Vector2(9, -10), 14.0], [Vector2(0, -16), 12.0],
	]
	for cluster: Array in clusters:
		Art.shaded_blob(self, crown + cluster[0] * size, cluster[1] * size, leaves, rng)


func _draw_rock(rng: RandomNumberGenerator) -> void:
	var size := 0.55 if is_depleted() else rng.randf_range(0.95, 1.15)
	var stone := Color("7f7a72")
	Art.soft_shadow(self, Vector2(3, 0), 20.0 * size, 0.4)
	var base := PackedVector2Array([
		Vector2(-18, 0), Vector2(-15, -14), Vector2(-4, -24), Vector2(10, -21), Vector2(18, -9), Vector2(16, 1),
	])
	var scaled := Transform2D().scaled(Vector2(size, size))
	draw_colored_polygon(scaled * base, Art.shade(stone, 0.35))
	# Facettes : face gauche éclairée, dessus clair, face droite dans l'ombre.
	draw_colored_polygon(scaled * PackedVector2Array([Vector2(-18, 0), Vector2(-15, -14), Vector2(-4, -24), Vector2(-1, -10), Vector2(-4, 0)]), stone)
	draw_colored_polygon(scaled * PackedVector2Array([Vector2(-15, -14), Vector2(-4, -24), Vector2(10, -21), Vector2(2, -13)]), Art.lit(stone, 0.22))
	if is_depleted():
		return
	# Filons de minerai qui brillent.
	for vein: Vector2 in [Vector2(-9, -9), Vector2(5, -8), Vector2(-2, -17)]:
		var p := vein * size
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -3), p + Vector2(2.5, 0), p + Vector2(0, 3), p + Vector2(-2.5, 0)]), Color("9fc4d8"))
		draw_circle(p + Vector2(-0.8, -1.2), 0.9, Color("eef6fb"))


func _draw_bush(rng: RandomNumberGenerator) -> void:
	var stem := Color("71813e")
	Art.soft_shadow(self, Vector2(2, 0), 13.0, 0.3)
	if is_depleted():
		for x in [-4, -1, 2, 5]:
			draw_line(Vector2(x, 0), Vector2(x * 1.2, -5), Art.shade(stem, 0.2), 2.0)
		return
	# Touffe de longues feuilles en éventail, fibres claires au bout.
	for i in 9:
		var angle := lerpf(-2.4, -0.75, float(i) / 8.0) + rng.randf_range(-0.1, 0.1)
		var length := rng.randf_range(16.0, 24.0)
		var tip := Vector2.from_angle(angle) * length
		var side := Vector2.from_angle(angle).orthogonal() * 2.5
		var color := Art.lit(stem, 0.12) if tip.x < 0 else Art.shade(stem, 0.08)
		draw_colored_polygon(PackedVector2Array([side, tip, -side]), color)
		if i % 2 == 0:
			draw_circle(tip, 2.6, Color("e8e0b0"))
			draw_circle(tip + Vector2(-0.8, -0.8), 1.2, Color("fbf6dc"))
