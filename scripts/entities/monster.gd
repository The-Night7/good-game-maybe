class_name Monster
extends CharacterBody2D
## Monstre. Son IA tourne sur le serveur ; les clients reçoivent sa position et sa vie.

enum State { IDLE, CHASE, RETURN }

const AGGRO_RANGE := 150.0
## Au-delà de cette distance de son point d'apparition, le monstre abandonne et rentre.
const LEASH_RANGE := 320.0
const ATTACK_RANGE := 26.0
const ATTACK_COOLDOWN := 1.2
const WANDER_RADIUS := 60.0

var kind := "slime"
var spawn_index := -1
var home := Vector2.ZERO
var max_hp := 40
var hp := 40:
	set(value):
		if value < hp:
			_flash = 0.15
		hp = value
		queue_redraw()

var _data: Dictionary
var _anim := 0.0
var _flash := 0.0

# Serveur uniquement.
var _state := State.IDLE
var _target: Player = null
var _attack_ready_at := 0.0
var _stun_left := 0.0
var _wander_target := Vector2.ZERO
var _wander_left := 0.0


## À appeler avant l'ajout à l'arbre.
func setup(monster_kind: String, spawn_position: Vector2, index: int) -> void:
	kind = monster_kind
	_data = GameData.MONSTERS[kind]
	home = spawn_position
	position = spawn_position
	spawn_index = index
	max_hp = _data.hp
	hp = max_hp
	_wander_target = home
	_anim = randf() * TAU


func _ready() -> void:
	add_to_group("monsters")
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	$CollisionShape2D.shape.radius = body_radius() * 0.7


func is_alive() -> bool:
	return hp > 0


func body_radius() -> float:
	return 10.0 * _data.size


func world() -> Node:
	return get_tree().get_first_node_in_group("world")


func _process(delta: float) -> void:
	_anim += delta * 4.0
	_flash = maxf(0.0, _flash - delta)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or not is_alive():
		return
	if _stun_left > 0.0:
		_stun_left -= delta
		velocity = Vector2.ZERO
		return

	if _target and (not is_instance_valid(_target) or _target.dead):
		_target = null
	if global_position.distance_to(home) > LEASH_RANGE:
		_target = null
		_state = State.RETURN

	match _state:
		State.IDLE:
			_target = _find_target()
			if _target:
				_state = State.CHASE
			else:
				_wander(delta)
		State.CHASE:
			if _target == null:
				_state = State.RETURN
			else:
				_chase()
		State.RETURN:
			velocity = global_position.direction_to(home) * _data.speed * 1.5
			if global_position.distance_to(home) < 8.0:
				_state = State.IDLE
				hp = max_hp
	move_and_slide()


func _find_target() -> Player:
	var best: Player = null
	var best_distance := AGGRO_RANGE
	for player: Player in get_tree().get_nodes_in_group("players"):
		var distance := global_position.distance_to(player.global_position)
		if not player.dead and distance < best_distance:
			best = player
			best_distance = distance
	return best


func _chase() -> void:
	var distance := global_position.distance_to(_target.global_position)
	if distance > ATTACK_RANGE + body_radius() * 0.5:
		velocity = global_position.direction_to(_target.global_position) * _data.speed
		return
	velocity = Vector2.ZERO
	var now := Time.get_ticks_msec() / 1000.0
	if now >= _attack_ready_at:
		_attack_ready_at = now + ATTACK_COOLDOWN
		_target.take_damage(_data.damage)
		world().play_effect.rpc("bite", global_position, _target.global_position, 0.0, Color("ff6b6b"))


func _wander(delta: float) -> void:
	_wander_left -= delta
	if _wander_left <= 0.0:
		_wander_left = randf_range(2.0, 4.5)
		_wander_target = home + Vector2.from_angle(randf() * TAU) * randf() * WANDER_RADIUS
	if global_position.distance_to(_wander_target) > 4.0:
		velocity = global_position.direction_to(_wander_target) * _data.speed * 0.5
	else:
		velocity = Vector2.ZERO


## Serveur : encaisse des dégâts, se retourne contre l'attaquant, meurt et donne son butin.
func take_damage(amount: int, attacker_peer: int, stun := 0.0) -> void:
	if not is_alive():
		return
	hp = maxi(0, hp - amount)
	world().float_text.rpc(global_position + Vector2(0, -36 * _data.size), str(amount), Color("ffe08a"))
	_stun_left = maxf(_stun_left, stun)
	if _target == null:
		_target = world().find_player(attacker_peer)
		if _target:
			_state = State.CHASE
	if hp == 0:
		world().on_monster_killed(self, attacker_peer)
		queue_free()


func _draw() -> void:
	var size: float = _data.size
	var squish := 1.0 + sin(_anim) * 0.08
	var body: Color = _data.color
	if _stun_left > 0.0:
		body = body.lerp(Color("e6c95a"), 0.4)

	Art.soft_shadow(self, Vector2.ZERO, 13.0 * size, 0.45)
	draw_set_transform(Vector2(0, -10 * size), 0.0, Vector2(squish, 1.0 / squish))
	var r := 12.0 * size
	# Corps gélatineux : bas sombre, reflet en haut à gauche.
	draw_circle(Vector2(0, 1.5) * size, r, Art.shade(body, 0.35))
	draw_circle(Vector2.ZERO, r * 0.94, body)
	draw_circle(Vector2(-3, -3) * size, r * 0.55, Art.lit(body, 0.12))
	draw_circle(Vector2(-5, -6) * size, r * 0.18, Color(1, 1, 1, 0.55))
	if kind == "rock_slime":
		var rng := Art.rng_for(home)
		for plate: Vector2 in [Vector2(-5, -8), Vector2(4, -9), Vector2(0, -3)]:
			var points := Art.facet_polygon(plate * size, 4.5 * size, 5, rng.randf() * TAU, 0.2, rng, 0.8)
			draw_colored_polygon(points, Color("8f8b84"))
			draw_colored_polygon(Art.facet_polygon(plate * size + Vector2(-1, -1), 2.5 * size, 4, 0.0, 0.1, rng), Color("b7b2a8"))
	# Yeux.
	for eye_x in [-4.0, 4.0]:
		draw_circle(Vector2(eye_x, 0) * size, 2.4 * size, Color("1d1a18"))
		draw_circle(Vector2(eye_x - 0.7, -0.8) * size, 0.8 * size, Color(1, 1, 1, 0.9))
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, r, Color(1, 1, 1, _flash / 0.15 * 0.7))
	draw_set_transform(Vector2.ZERO)

	if hp < max_hp:
		var width := 26.0 * size
		var origin := Vector2(-width / 2.0, -30.0 * size)
		draw_rect(Rect2(origin - Vector2(1, 1), Vector2(width + 2, 6)), Color(0.08, 0.06, 0.04, 0.8))
		draw_rect(Rect2(origin, Vector2(width * float(hp) / max_hp, 4)), Color("c8443c"))
