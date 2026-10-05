extends Node2D
## Effet visuel bref (coup, tir, explosion, soin). Purement local, rien n'est synchronisé.

const DURATION := 0.35
## Hauteur du torse : les effets partent du corps, pas des pieds.
const BODY_OFFSET := Vector2(0, -16)

var kind := ""
var from := Vector2.ZERO
var to := Vector2.ZERO
var radius := 0.0
var color := Color.WHITE

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var progress := _time / DURATION
	var faded := Color(color, 1.0 - progress)
	match kind:
		"slash":
			var direction := from.direction_to(to)
			var angle := direction.angle()
			draw_arc(from + BODY_OFFSET, radius * 0.8, angle - 0.9, angle + 0.9, 16, faded, 6.0 * (1.0 - progress) + 1.0, true)
		"ring":
			_draw_ground_ring(from, radius * (0.4 + 0.6 * progress), faded, 5.0)
		"shot":
			var head := from.lerp(to, minf(1.0, progress * 2.5))
			var tail := from.lerp(to, maxf(0.0, progress * 2.5 - 0.5))
			draw_line(tail + BODY_OFFSET, head + BODY_OFFSET, faded, 3.0, true)
			draw_circle(head + BODY_OFFSET, 4.0, faded)
		"blast":
			draw_set_transform(from, 0.0, Vector2(1.0, 0.5))
			draw_circle(Vector2.ZERO, radius * (0.6 + 0.4 * progress), Color(color, 0.45 * (1.0 - progress)))
			draw_set_transform(Vector2.ZERO)
			_draw_ground_ring(from, radius, faded, 3.0)
		"heal":
			_draw_ground_ring(from, radius * progress, faded, 4.0)
			for i in 5:
				var p := from + Vector2.from_angle(i * TAU / 5.0) * 18.0 + Vector2(0, -20 - 30 * progress)
				draw_line(p - Vector2(4, 0), p + Vector2(4, 0), faded, 2.0)
				draw_line(p - Vector2(0, 4), p + Vector2(0, 4), faded, 2.0)
		"bite", "hit":
			for i in 6:
				var spark := Vector2.from_angle(i * TAU / 6.0 + 0.3) * (6.0 + 14.0 * progress)
				draw_line(to + BODY_OFFSET + spark * 0.5, to + BODY_OFFSET + spark, faded, 2.0)


func _draw_ground_ring(center: Vector2, ring_radius: float, ring_color: Color, width: float) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, ring_color, width, true)
	draw_set_transform(Vector2.ZERO)
