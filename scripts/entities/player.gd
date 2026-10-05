class_name Player
extends CharacterBody2D
## Personnage joueur.
##
## Réseau : la position est envoyée par le joueur qui contrôle ce personnage (fluide sur
## mobile) ; la vie, l'équipement et le sac sont gérés par le serveur. Les actions
## (compétences, récolte, artisanat, équipement) sont des demandes envoyées au serveur.

signal stats_changed
signal equipment_changed
signal inventory_changed

const SPEED := 140.0
const ARRIVE_DISTANCE := 4.0
## Ratio vertical des tuiles isométriques (2:1) : une diagonale suit les bords des tuiles.
const ISO_RATIO := 0.5
const BASE_MAX_HP := 100
const RESPAWN_DELAY := 4.0
## Régénération hors combat (comme Albion), en PV par seconde.
const REGEN_PER_SECOND := 3.0
const REGEN_DELAY := 5.0
const INTERACT_RANGE := 60.0
const HARVEST_COOLDOWN := 0.6
## Portée de la visée automatique des compétences.
const AUTO_AIM_RANGE := 280.0
## Tolérance sur les recharges, pour absorber la latence réseau.
const COOLDOWN_TOLERANCE := 0.15

var peer_id := 1
var display_name := "":
	set(value):
		display_name = value
		queue_redraw()
var hp := BASE_MAX_HP:
	set(value):
		hp = value
		queue_redraw()
		stats_changed.emit()
var max_hp := BASE_MAX_HP:
	set(value):
		max_hp = value
		queue_redraw()
		stats_changed.emit()
var dead := false:
	set(value):
		dead = value
		queue_redraw()
		stats_changed.emit()
var weapon_id := GameData.STARTING_WEAPON:
	set(value):
		weapon_id = value
		queue_redraw()
		equipment_changed.emit()
var armor_id := "":
	set(value):
		armor_id = value
		queue_redraw()
		equipment_changed.emit()
var facing := Vector2.DOWN
## Sac : la vérité est sur le serveur, le joueur concerné en reçoit une copie.
var inventory := {}

var _has_target := false
var _target := Vector2.ZERO

# Serveur uniquement.
var _ready_at := [0.0, 0.0, 0.0]
var _harvest_ready_at := 0.0
var _respawn_left := 0.0
var _last_hurt_at := -100.0
var _regen_buffer := 0.0


func _enter_tree() -> void:
	# Le nom porte l'identifiant réseau du joueur : "Player_<peer>".
	peer_id = String(name).get_slice("_", 1).to_int()
	set_multiplayer_authority(peer_id)
	$ServerSync.set_multiplayer_authority(1)


func _ready() -> void:
	add_to_group("players")
	$Camera2D.enabled = is_local()
	if is_local():
		$Camera2D.make_current()
		world().local_player_spawned.emit(self)


func world() -> Node:
	return get_tree().get_first_node_in_group("world")


func is_local() -> bool:
	return is_multiplayer_authority()


func skills() -> Array:
	return GameData.skills_for(weapon_id)


func item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)


# --- Déplacement (joueur local) -------------------------------------------------

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_server_tick(delta)
	if not is_local():
		return
	if dead:
		velocity = Vector2.ZERO
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		_has_target = false
		velocity = Vector2(input.x, input.y * ISO_RATIO).normalized() * SPEED * input.length()
	elif _has_target and global_position.distance_to(_target) > ARRIVE_DISTANCE:
		velocity = global_position.direction_to(_target) * SPEED
	else:
		_has_target = false
		velocity = Vector2.ZERO

	if velocity.length() > 1.0:
		facing = velocity.normalized()
	move_and_slide()

	# Bloqué contre un obstacle : on abandonne la destination.
	if _has_target and get_slide_collision_count() > 0 and get_real_velocity().length() < SPEED * 0.1:
		_has_target = false


func _unhandled_input(event: InputEvent) -> void:
	if not is_local() or dead:
		return
	# Le toucher arrive ici sous forme de souris émulée.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_move_to_screen_point(event.position)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_move_to_screen_point(event.position)


func _move_to_screen_point(screen_position: Vector2) -> void:
	_target = get_viewport().get_canvas_transform().affine_inverse() * screen_position
	_has_target = true


# --- Actions du joueur local (appelées par le HUD) ------------------------------

## Lance une compétence et renvoie sa recharge, pour l'affichage.
func use_skill(slot: int) -> float:
	if dead:
		return 0.0
	var aim := aim_direction()
	facing = aim
	request_skill.rpc_id(1, slot, aim)
	return skills()[slot].cooldown


## Vise automatiquement le monstre le plus proche, sinon droit devant.
func aim_direction() -> Vector2:
	var target := nearest_monster(AUTO_AIM_RANGE)
	if target:
		return global_position.direction_to(target.global_position)
	return facing


## Vrai si le bouton d'action doit récolter plutôt qu'attaquer.
func should_harvest() -> bool:
	return nearest_resource(INTERACT_RANGE) != null and nearest_monster(90.0) == null


func harvest_nearest() -> void:
	var resource := nearest_resource(INTERACT_RANGE)
	if resource and not dead:
		facing = global_position.direction_to(resource.global_position)
		request_harvest.rpc_id(1, String(resource.name))


func craft(item_id: String) -> void:
	request_craft.rpc_id(1, item_id)


func equip(item_id: String) -> void:
	request_equip.rpc_id(1, item_id)


func use_item(item_id: String) -> void:
	request_use_item.rpc_id(1, item_id)


func nearest_monster(max_range: float) -> Monster:
	var best: Monster = null
	var best_distance := max_range
	for monster: Monster in get_tree().get_nodes_in_group("monsters"):
		var distance := global_position.distance_to(monster.global_position)
		if monster.is_alive() and distance <= best_distance:
			best = monster
			best_distance = distance
	return best


func nearest_resource(max_range: float) -> ResourceNode:
	var best: ResourceNode = null
	var best_distance := max_range
	for resource: ResourceNode in get_tree().get_nodes_in_group("resources"):
		var distance := global_position.distance_to(resource.global_position)
		if not resource.is_depleted() and distance <= best_distance:
			best = resource
			best_distance = distance
	return best


# --- Demandes au serveur ---------------------------------------------------------

@rpc("any_peer", "call_local", "reliable")
func request_skill(slot: int, aim: Vector2) -> void:
	if not _sent_by_owner() or dead or slot < 0 or slot >= skills().size():
		return
	var skill: Dictionary = skills()[slot]
	var now := _now()
	if now < _ready_at[slot] - COOLDOWN_TOLERANCE:
		return
	_ready_at[slot] = now + skill.cooldown
	Combat.use_skill(self, skill, aim)


@rpc("any_peer", "call_local", "reliable")
func request_harvest(resource_name: String) -> void:
	if not _sent_by_owner() or dead or _now() < _harvest_ready_at - COOLDOWN_TOLERANCE:
		return
	var resource: ResourceNode = world().get_resource(resource_name)
	if resource == null or resource.is_depleted():
		return
	if resource.global_position.distance_to(global_position) > INTERACT_RANGE + 24.0:
		return
	_harvest_ready_at = _now() + HARVEST_COOLDOWN
	var item := resource.harvest()
	add_items({item: 1})
	world().play_effect.rpc("hit", resource.global_position, resource.global_position, 0.0, GameData.ITEMS[item].color)
	world().float_text.rpc_id(peer_id, resource.global_position + Vector2(0, -48), "+1 %s" % GameData.item_name(item), GameData.ITEMS[item].color)


@rpc("any_peer", "call_local", "reliable")
func request_craft(item_id: String) -> void:
	if not _sent_by_owner():
		return
	var recipe := GameData.recipe_for(item_id)
	if recipe.is_empty() or not GameData.can_afford(inventory, recipe.cost):
		return
	remove_items(recipe.cost)
	add_items({item_id: 1})
	world().float_text.rpc_id(peer_id, global_position + Vector2(0, -56), "Fabriqué : %s" % GameData.item_name(item_id), Color("ffe08a"))


@rpc("any_peer", "call_local", "reliable")
func request_equip(item_id: String) -> void:
	if not _sent_by_owner() or item_count(item_id) <= 0:
		return
	match GameData.ITEMS[item_id].get("slot", ""):
		"weapon":
			weapon_id = item_id
			_ready_at = [0.0, 0.0, 0.0]
		"armor":
			# Toucher l'armure portée l'enlève.
			armor_id = "" if armor_id == item_id else item_id
			_update_max_hp()
		_:
			return
	world().mark_dirty()


@rpc("any_peer", "call_local", "reliable")
func request_use_item(item_id: String) -> void:
	if not _sent_by_owner() or dead or item_count(item_id) <= 0:
		return
	var heal_amount: int = GameData.ITEMS[item_id].get("heal", 0)
	if heal_amount <= 0 or hp >= max_hp:
		return
	remove_items({item_id: 1})
	heal(heal_amount)


# --- Côté serveur ----------------------------------------------------------------

func take_damage(amount: int) -> void:
	if dead:
		return
	hp = maxi(0, hp - amount)
	_last_hurt_at = _now()
	world().float_text.rpc(global_position + Vector2(0, -48), str(amount), Color("ff6b6b"))
	if hp == 0:
		dead = true
		_respawn_left = RESPAWN_DELAY


func heal(amount: int) -> void:
	if dead:
		return
	var healed := mini(amount, max_hp - hp)
	hp += healed
	if healed > 0:
		world().float_text.rpc(global_position + Vector2(0, -48), "+%d" % healed, Color("7ee081"))


func add_items(items: Dictionary) -> void:
	for item: String in items:
		inventory[item] = item_count(item) + int(items[item])
	_inventory_updated()


func remove_items(items: Dictionary) -> void:
	for item: String in items:
		inventory[item] = item_count(item) - int(items[item])
		if inventory[item] <= 0:
			inventory.erase(item)
	_inventory_updated()


func to_save() -> Dictionary:
	return {"inventory": inventory.duplicate(), "weapon": weapon_id, "armor": armor_id}


## Applique une sauvegarde (ou l'équipement de départ). Appelé à l'apparition.
func apply_save(saved: Dictionary) -> void:
	inventory = {}
	var saved_inventory: Dictionary = saved.get("inventory", GameData.STARTING_INVENTORY)
	for item: String in saved_inventory:
		if item in GameData.ITEMS and int(saved_inventory[item]) > 0:
			inventory[item] = int(saved_inventory[item])
	var weapon: String = saved.get("weapon", GameData.STARTING_WEAPON)
	weapon_id = weapon if GameData.ITEMS.get(weapon, {}).get("slot") == "weapon" else GameData.STARTING_WEAPON
	var armor: String = saved.get("armor", "")
	armor_id = armor if GameData.ITEMS.get(armor, {}).get("slot") == "armor" else ""
	_update_max_hp()
	hp = max_hp


func _update_max_hp() -> void:
	max_hp = BASE_MAX_HP + GameData.armor_bonus(armor_id)
	hp = mini(hp, max_hp)


func _server_tick(delta: float) -> void:
	if dead:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			dead = false
			hp = max_hp
			_respawn_at.rpc_id(peer_id, world().spawn_position())
		return
	if hp < max_hp and _now() - _last_hurt_at > REGEN_DELAY:
		_regen_buffer += REGEN_PER_SECOND * delta
		if _regen_buffer >= 1.0:
			var amount := int(_regen_buffer)
			_regen_buffer -= amount
			hp = mini(max_hp, hp + amount)


func _inventory_updated() -> void:
	world().mark_dirty()
	_set_inventory.rpc_id(peer_id, inventory)


@rpc("any_peer", "call_local", "reliable")
func _set_inventory(value: Dictionary) -> void:
	if not _sent_by_server():
		return
	inventory = value
	inventory_changed.emit()


@rpc("any_peer", "call_local", "reliable")
func _respawn_at(spawn: Vector2) -> void:
	if not _sent_by_server():
		return
	global_position = spawn
	_has_target = false


func _sent_by_owner() -> bool:
	return multiplayer.is_server() and _sender() == peer_id


func _sent_by_server() -> bool:
	return _sender() == 1


func _sender() -> int:
	var sender := multiplayer.get_remote_sender_id()
	return sender if sender != 0 else multiplayer.get_unique_id()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# --- Affichage (placeholder en attendant les sprites) ---------------------------

func _draw() -> void:
	var alpha := 0.45 if dead else 1.0
	var tunic := Color.from_hsv(fmod(peer_id * 0.618, 1.0), 0.55, 0.85)
	if armor_id == "leather_vest":
		tunic = Color("7a4e2d")

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3 * alpha))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-7, -26, 14, 22), Color(tunic, alpha))
	draw_circle(Vector2(0, -32), 7.0, Color(Color("f2d6b3"), alpha))
	_draw_weapon(alpha)

	var font := ThemeDB.fallback_font
	var label := "%s (K.O.)" % display_name if dead else display_name
	var origin := Vector2(-60, -50)
	draw_string_outline(font, origin, label, HORIZONTAL_ALIGNMENT_CENTER, 120, 12, 3, Color(0, 0, 0, 0.7))
	draw_string(font, origin, label, HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color(1, 1, 1, alpha))
	if not is_local() and not dead:
		_draw_bar(Vector2(-14, -47), 28.0, float(hp) / max_hp, Color("7ee081"))


func _draw_weapon(alpha: float) -> void:
	var item: Dictionary = GameData.ITEMS[weapon_id]
	var color := Color(item.color, alpha)
	var hand := Vector2(10, -16)
	match item.weapon:
		"sword":
			draw_line(hand, hand + Vector2(6, -18), color, 3.0)
			draw_line(hand + Vector2(-3, -1), hand + Vector2(4, 1), Color(0.3, 0.2, 0.1, alpha), 3.0)
		"bow":
			draw_arc(hand + Vector2(-2, -6), 12.0, -PI / 2.5, PI / 2.5, 12, color, 2.0)
		"staff":
			draw_line(hand + Vector2(0, 8), hand + Vector2(2, -22), Color(0.45, 0.3, 0.15, alpha), 2.5)
			draw_circle(hand + Vector2(2, -24), 4.0, color)


func _draw_bar(origin: Vector2, width: float, fraction: float, color: Color) -> void:
	draw_rect(Rect2(origin, Vector2(width, 4)), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(origin, Vector2(width * clampf(fraction, 0.0, 1.0), 4)), color)
