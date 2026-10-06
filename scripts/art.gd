class_name Art
## Petits outils de dessin pour le style du jeu, inspiré d'Albion Online :
## formes « low-poly » à facettes, couleurs naturelles un peu désaturées,
## lumière venant d'en haut à gauche, ombres douces portées vers le bas à droite.

const LIGHT_DIRECTION := Vector2(-0.6, -0.8)
const SHADOW_COLOR := Color(0.05, 0.04, 0.02)


static func lit(color: Color, amount := 0.18) -> Color:
	return color.lightened(amount)


static func shade(color: Color, amount := 0.3) -> Color:
	return color.darkened(amount)


## Ombre douce et aplatie au sol, décalée à l'opposé de la lumière.
static func soft_shadow(canvas: CanvasItem, center: Vector2, radius: float, opacity := 0.35) -> void:
	var offset := -LIGHT_DIRECTION * radius * 0.25
	canvas.draw_set_transform(center + offset, 0.0, Vector2(1.0, 0.45))
	for i in 3:
		var t := float(i) / 3.0
		canvas.draw_circle(Vector2.ZERO, radius * (1.0 - t * 0.35), Color(SHADOW_COLOR, opacity * 0.4))
	canvas.draw_set_transform(Vector2.ZERO)


## Polygone régulier légèrement irrégulier : la brique de base du style « à facettes ».
static func facet_polygon(center: Vector2, radius: float, sides: int, rotation: float, jitter: float, rng: RandomNumberGenerator, squash := 1.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		var angle := rotation + TAU * i / sides
		var r := radius * (1.0 + rng.randf_range(-jitter, jitter))
		points.append(center + Vector2(cos(angle) * r, sin(angle) * r * squash))
	return points


## Masse ronde ombrée : partie sombre en bas à droite, éclairée en haut à gauche.
static func shaded_blob(canvas: CanvasItem, center: Vector2, radius: float, color: Color, rng: RandomNumberGenerator, sides := 8) -> void:
	var rotation := rng.randf() * TAU
	canvas.draw_colored_polygon(facet_polygon(center + Vector2(2, 3) * radius / 14.0, radius, sides, rotation, 0.08, rng), shade(color, 0.32))
	canvas.draw_colored_polygon(facet_polygon(center, radius * 0.92, sides, rotation, 0.08, rng), color)
	canvas.draw_colored_polygon(facet_polygon(center + LIGHT_DIRECTION * radius * 0.35, radius * 0.5, sides - 2, rotation, 0.1, rng), lit(color, 0.16))


## Générateur aléatoire stable pour une position : chaque arbre garde sa forme.
static func rng_for(position: Vector2) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(position.round()))
	return rng
