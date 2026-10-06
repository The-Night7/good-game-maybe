class_name Icons
## Pictogrammes vectoriels des compétences et actions, dessinés à la volée.
## « s » est le demi-côté de l'icône : les coordonnées vont de -1 à 1.

const FIRE := Color("ff8a3d")
const FIRE_CORE := Color("ffd27a")
const POTION := Color("c8443c")


static func draw(canvas: CanvasItem, kind: String, c: Vector2, s: float, color: Color) -> void:
	var w := maxf(2.0, s * 0.13)
	match kind:
		"sword":
			_sword(canvas, c + Vector2(-0.45, 0.45) * s, c + Vector2(0.75, -0.75) * s, s, color)
		"smash":
			_sword(canvas, c + Vector2(0, -0.55) * s, c + Vector2(0, 0.55) * s, s, color)
			for angle in [-2.6, -PI / 2.0, -0.55]:
				var from := c + Vector2(0, 0.75) * s + Vector2.from_angle(angle) * 0.3 * s
				canvas.draw_line(from, from + Vector2.from_angle(angle) * 0.35 * s, color, w * 0.8)
		"whirl":
			for start in [0.3, PI + 0.3]:
				canvas.draw_arc(c, 0.6 * s, start, start + 2.2, 16, color, w, true)
				var end := c + Vector2.from_angle(start + 2.2) * 0.6 * s
				var tangent := Vector2.from_angle(start + 2.2 + PI / 2.0)
				canvas.draw_colored_polygon(PackedVector2Array([
					end + tangent * 0.28 * s, end + tangent.orthogonal() * 0.18 * s, end - tangent.orthogonal() * 0.18 * s,
				]), color)
		"arrow":
			_arrow(canvas, c + Vector2(-0.7, 0.7) * s, c + Vector2(0.7, -0.7) * s, s, color)
		"pierce":
			_arrow(canvas, c + Vector2(-0.5, 0.0) * s, c + Vector2(0.85, 0.0) * s, s, color)
			for y in [-0.4, 0.4]:
				canvas.draw_line(c + Vector2(-0.9, y) * s, c + Vector2(-0.2, y) * s, Color(color, 0.6), w * 0.6)
		"arrow_rain":
			for i in 3:
				var x := (i - 1) * 0.5
				var top := -0.8 + (i % 2) * 0.3
				_arrow(canvas, c + Vector2(x, top) * s, c + Vector2(x, top + 1.1) * s, s * 0.75, color)
		"fireball":
			var ball := c + Vector2(0.2, -0.2) * s
			canvas.draw_colored_polygon(PackedVector2Array([
				ball + Vector2(-0.3, -0.25) * s, c + Vector2(-0.85, 0.85) * s, ball + Vector2(0.25, 0.3) * s,
			]), Color(FIRE, 0.7))
			canvas.draw_circle(ball, 0.42 * s, FIRE)
			canvas.draw_circle(ball + Vector2(-0.08, -0.08) * s, 0.22 * s, FIRE_CORE)
		"burst":
			var points := PackedVector2Array()
			for i in 16:
				var radius := 0.85 if i % 2 == 0 else 0.35
				points.append(c + Vector2.from_angle(i * TAU / 16.0 - PI / 2.0) * radius * s)
			canvas.draw_colored_polygon(points, FIRE)
			canvas.draw_circle(c, 0.25 * s, FIRE_CORE)
		"heal":
			var arm := 0.22 * s
			canvas.draw_rect(Rect2(c - Vector2(arm, 0.75 * s), Vector2(arm * 2, 1.5 * s)), Color("8fd88a"))
			canvas.draw_rect(Rect2(c - Vector2(0.75 * s, arm), Vector2(1.5 * s, arm * 2)), Color("8fd88a"))
		"harvest":
			canvas.draw_line(c + Vector2(-0.6, 0.75) * s, c + Vector2(0.35, -0.6) * s, Color("b0895a"), w)
			canvas.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0.1, -0.85) * s, c + Vector2(0.75, -0.35) * s, c + Vector2(0.55, 0.0) * s, c + Vector2(0.15, -0.35) * s,
			]), color)
		"potion":
			var body := c + Vector2(0, 0.25) * s
			canvas.draw_circle(body, 0.5 * s, Color(color, 0.35))
			canvas.draw_circle(body + Vector2(0, 0.08) * s, 0.4 * s, POTION)
			canvas.draw_rect(Rect2(c + Vector2(-0.15, -0.65) * s, Vector2(0.3, 0.45) * s), Color(color, 0.5))
			canvas.draw_rect(Rect2(c + Vector2(-0.2, -0.85) * s, Vector2(0.4, 0.22) * s), Color("8a6a44"))
			canvas.draw_circle(body + Vector2(-0.18, -0.05) * s, 0.1 * s, Color(1, 1, 1, 0.7))


static func _sword(canvas: CanvasItem, base: Vector2, tip: Vector2, s: float, color: Color) -> void:
	var direction := base.direction_to(tip)
	var normal := direction.orthogonal()
	var half_width := 0.12 * s
	canvas.draw_colored_polygon(PackedVector2Array([base + normal * half_width, tip, base - normal * half_width]), color)
	canvas.draw_line(base + normal * 0.32 * s, base - normal * 0.32 * s, Color("c9a35a"), maxf(2.0, s * 0.12))
	canvas.draw_line(base, base - direction * 0.3 * s, Color("7a5a2e"), maxf(2.0, s * 0.12))
	canvas.draw_circle(base - direction * 0.36 * s, 0.09 * s, Color("c9a35a"))


static func _arrow(canvas: CanvasItem, tail: Vector2, tip: Vector2, s: float, color: Color) -> void:
	var direction := tail.direction_to(tip)
	var normal := direction.orthogonal()
	canvas.draw_line(tail, tip - direction * 0.2 * s, color, maxf(1.5, s * 0.09))
	canvas.draw_colored_polygon(PackedVector2Array([tip, tip - direction * 0.35 * s + normal * 0.2 * s, tip - direction * 0.35 * s - normal * 0.2 * s]), color)
	for side in [-1.0, 1.0]:
		canvas.draw_line(tail, tail - direction * 0.15 * s + normal * side * 0.2 * s, Color("c9a35a"), maxf(1.5, s * 0.08))
