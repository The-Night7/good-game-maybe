class_name TouchControl
extends Control
## Base des commandes tactiles (D-pad, boutons de compétence).
##
## Les événements sont lus dans _input pour gérer le multi-touch : on peut garder un
## doigt sur le D-pad et appuyer sur une compétence avec l'autre (les boutons Godot
## classiques ne voient que le premier doigt). La souris marche aussi, pour tester sur PC.

const NO_POINTER := -2
const MOUSE_POINTER := -1

var _pointer := NO_POINTER


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_EXIT_TREE:
			_cancel()


func is_pressed() -> bool:
	return _pointer != NO_POINTER


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		if event.pressed and _pointer == NO_POINTER and _hit(event.position):
			_pointer = event.index
			_on_press(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _pointer:
			_cancel()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == _pointer:
			_on_drag(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouse:
		_handle_mouse(event)


func _handle_mouse(event: InputEventMouse) -> void:
	# Souris émulée depuis le toucher : déjà traitée via les événements tactiles,
	# on l'absorbe seulement pour qu'elle ne déclenche pas un déplacement au toucher.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		if _pointer != NO_POINTER or _hit(event.position):
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _pointer == NO_POINTER and _hit(event.position):
			_pointer = MOUSE_POINTER
			_on_press(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and _pointer == MOUSE_POINTER:
			_cancel()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _pointer == MOUSE_POINTER:
		_on_drag(event.position)
		get_viewport().set_input_as_handled()


func _cancel() -> void:
	_pointer = NO_POINTER
	_on_release()


## Zone sensible : le disque inscrit dans le contrôle.
func _hit(screen_position: Vector2) -> bool:
	return screen_position.distance_to(_screen_center()) <= _screen_radius()


func _screen_center() -> Vector2:
	return get_global_transform_with_canvas() * (size / 2.0)


func _screen_radius() -> float:
	return minf(size.x, size.y) / 2.0 * get_global_transform_with_canvas().get_scale().x


func _on_press(_screen_position: Vector2) -> void:
	pass


func _on_drag(_screen_position: Vector2) -> void:
	pass


func _on_release() -> void:
	pass
