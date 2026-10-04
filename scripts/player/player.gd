extends CharacterBody2D
## Personnage joueur.
##
## Deux façons de bouger :
## - directions (clavier ZQSD/WASD, flèches ou D-pad tactile) via les actions move_* ;
## - clic / toucher maintenu sur la carte, à la Albion Online.

const SPEED := 140.0
const ARRIVE_DISTANCE := 4.0
## Ratio vertical des tuiles isométriques (2:1) : une diagonale suit les bords des tuiles.
const ISO_RATIO := 0.5

var _has_target := false
var _target := Vector2.ZERO


func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		_has_target = false
		velocity = Vector2(input.x, input.y * ISO_RATIO).normalized() * SPEED * input.length()
	elif _has_target and global_position.distance_to(_target) > ARRIVE_DISTANCE:
		velocity = global_position.direction_to(_target) * SPEED
	else:
		_has_target = false
		velocity = Vector2.ZERO

	move_and_slide()

	# Bloqué contre un obstacle : on abandonne la destination.
	if _has_target and get_slide_collision_count() > 0 and get_real_velocity().length() < SPEED * 0.1:
		_has_target = false


func _unhandled_input(event: InputEvent) -> void:
	# Le toucher arrive ici sous forme de souris émulée.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_move_to_screen_point(event.position)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_move_to_screen_point(event.position)


func _move_to_screen_point(screen_position: Vector2) -> void:
	_target = get_viewport().get_canvas_transform().affine_inverse() * screen_position
	_has_target = true


func _draw() -> void:
	# Placeholder en attendant les sprites : ombre, corps, tête.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-7, -26, 14, 22), Color("e8c170"))
	draw_circle(Vector2(0, -32), 7.0, Color("f2d6b3"))
