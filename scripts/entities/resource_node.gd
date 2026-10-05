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
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO)
	var depleted := is_depleted()
	match kind:
		"tree":
			draw_rect(Rect2(-4, -10 if depleted else -22, 8, 10 if depleted else 22), Color("6b4a2b"))
			if not depleted:
				draw_circle(Vector2(0, -40), 22.0, Color("2f6b34"))
				draw_circle(Vector2(-8, -48), 12.0, Color("3d8443"))
		"rock":
			var size := 0.5 if depleted else 1.0
			var shrink := Transform2D().scaled(Vector2(size, size))
			draw_colored_polygon(shrink * PackedVector2Array([
				Vector2(-16, 0), Vector2(-12, -16), Vector2(2, -24), Vector2(15, -12), Vector2(14, 0),
			]), Color("7d7a74"))
			draw_colored_polygon(shrink * PackedVector2Array([
				Vector2(-12, -16), Vector2(2, -24), Vector2(0, -10),
			]), Color("a39f97"))
			if not depleted:
				draw_circle(Vector2(6, -12), 2.5, Color("cfe3f0"))
				draw_circle(Vector2(-6, -8), 2.0, Color("cfe3f0"))
		"bush":
			if depleted:
				draw_line(Vector2(0, 0), Vector2(0, -6), Color("6f8f3a"), 2.0)
			else:
				draw_circle(Vector2(0, -10), 11.0, Color("6f9f3a"))
				for x in [-6, 0, 6]:
					draw_line(Vector2(x, -14), Vector2(x * 1.4, -24), Color("e1e88a"), 2.0)
