class_name DPad
extends TouchControl
## D-pad virtuel 8 directions pour écrans tactiles.
##
## Il presse les actions move_* comme le ferait un clavier : le joueur n'a pas
## besoin de savoir d'où vient l'entrée.

const ACTIONS := {
	"move_left": Vector2.LEFT,
	"move_right": Vector2.RIGHT,
	"move_up": Vector2.UP,
	"move_down": Vector2.DOWN,
}

## Zone morte au centre, en fraction du rayon.
@export_range(0.0, 0.9) var dead_zone := 0.25

var direction := Vector2.ZERO


## Convertit une position à l'écran en direction 8 voies (ou zéro dans la zone morte).
func direction_for(screen_position: Vector2) -> Vector2:
	var offset := screen_position - _screen_center()
	if offset.length() < dead_zone * _screen_radius():
		return Vector2.ZERO
	var step := roundi(offset.angle() / (PI / 4.0))
	var snapped := Vector2.from_angle(step * PI / 4.0)
	return Vector2(signf(roundf(snapped.x)), signf(roundf(snapped.y)))


func _on_press(screen_position: Vector2) -> void:
	_set_direction(direction_for(screen_position))


func _on_drag(screen_position: Vector2) -> void:
	_set_direction(direction_for(screen_position))


func _on_release() -> void:
	_set_direction(Vector2.ZERO)


func _set_direction(value: Vector2) -> void:
	if value == direction:
		return
	direction = value
	for action: String in ACTIONS:
		var axis: Vector2 = ACTIONS[action]
		if direction.dot(axis) > 0.0:
			Input.action_press(action)
		else:
			Input.action_release(action)
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	var arm := radius * 0.34
	var leather := Color(0.17, 0.14, 0.11, 0.8)
	var active := Color("e6c35a")

	draw_circle(center, radius, Color(0.08, 0.06, 0.05, 0.45))
	draw_arc(center, radius * 0.97, 0.0, TAU, 64, Color(SkillButton.RIM, 0.6), 2.0, true)
	draw_rect(Rect2(center - Vector2(arm, radius * 0.86), Vector2(arm * 2, radius * 1.72)), leather)
	draw_rect(Rect2(center - Vector2(radius * 0.86, arm), Vector2(radius * 1.72, arm * 2)), leather)
	draw_circle(center, arm * 0.55, Color(SkillButton.RIM, 0.35))

	for action: String in ACTIONS:
		var axis: Vector2 = ACTIONS[action]
		var tip := center + axis * radius * 0.76
		var side := axis.orthogonal() * arm * 0.55
		var base := tip - axis * arm * 0.75
		var color := active if direction.dot(axis) > 0.0 else Color(SkillButton.INK, 0.8)
		draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), color)

	if direction != Vector2.ZERO:
		draw_circle(center + direction.normalized() * radius * 0.45, arm * 0.6, Color(active, 0.8))
