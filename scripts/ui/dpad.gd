class_name DPad
extends Control
## D-pad virtuel 8 directions pour écrans tactiles.
##
## Il presse les actions move_* comme le ferait un clavier : le joueur n'a pas
## besoin de savoir d'où vient l'entrée. Fonctionne aussi à la souris (tests sur PC).

const ACTIONS := {
	"move_left": Vector2.LEFT,
	"move_right": Vector2.RIGHT,
	"move_up": Vector2.UP,
	"move_down": Vector2.DOWN,
}
const NO_POINTER := -2
const MOUSE_POINTER := -1

## Zone morte au centre, en fraction du rayon.
@export_range(0.0, 0.9) var dead_zone := 0.25

var direction := Vector2.ZERO

var _pointer := NO_POINTER


func _ready() -> void:
	# Les événements sont lus dans _input pour gérer le multi-touch.
	mouse_filter = MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_EXIT_TREE:
			_release()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		if event.pressed and _pointer == NO_POINTER and _contains(event.position):
			_pointer = event.index
			_update(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _pointer:
			_release()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == _pointer:
			_update(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouse:
		_handle_mouse(event)


func _handle_mouse(event: InputEventMouse) -> void:
	# Souris émulée depuis le toucher : déjà traitée via les événements tactiles,
	# on l'absorbe seulement pour qu'elle ne déclenche pas un déplacement au clic.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		if _pointer != NO_POINTER or _contains(event.position):
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _pointer == NO_POINTER and _contains(event.position):
			_pointer = MOUSE_POINTER
			_update(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and _pointer == MOUSE_POINTER:
			_release()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _pointer == MOUSE_POINTER:
		_update(event.position)
		get_viewport().set_input_as_handled()


## Convertit une position à l'écran en direction 8 voies (ou zéro dans la zone morte).
func direction_for(screen_position: Vector2) -> Vector2:
	var offset := screen_position - _center()
	if offset.length() < dead_zone * _radius():
		return Vector2.ZERO
	var step := roundi(offset.angle() / (PI / 4.0))
	var snapped := Vector2.from_angle(step * PI / 4.0)
	return Vector2(signf(roundf(snapped.x)), signf(roundf(snapped.y)))


func _update(screen_position: Vector2) -> void:
	_set_direction(direction_for(screen_position))


func _release() -> void:
	_pointer = NO_POINTER
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


func _contains(screen_position: Vector2) -> bool:
	return screen_position.distance_to(_center()) <= _radius()


func _center() -> Vector2:
	return get_global_transform_with_canvas() * (size / 2.0)


func _radius() -> float:
	return minf(size.x, size.y) / 2.0 * get_global_transform_with_canvas().get_scale().x


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	var arm := radius * 0.36
	var idle := Color(1, 1, 1, 0.35)
	var active := Color(1, 0.85, 0.4, 0.85)

	draw_circle(center, radius, Color(0, 0, 0, 0.25))
	draw_rect(Rect2(center - Vector2(arm, radius * 0.9), Vector2(arm * 2, radius * 1.8)), idle)
	draw_rect(Rect2(center - Vector2(radius * 0.9, arm), Vector2(radius * 1.8, arm * 2)), idle)

	for action: String in ACTIONS:
		var axis: Vector2 = ACTIONS[action]
		var tip := center + axis * radius * 0.78
		var side := axis.orthogonal() * arm * 0.6
		var base := tip - axis * arm * 0.8
		var color := active if direction.dot(axis) > 0.0 else Color(1, 1, 1, 0.8)
		draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), color)

	if direction != Vector2.ZERO:
		draw_circle(center + direction.normalized() * radius * 0.45, arm * 0.7, active)
