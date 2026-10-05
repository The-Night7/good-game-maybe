class_name Combat
## Résolution des compétences, côté serveur.


static func use_skill(caster: Player, skill: Dictionary, aim: Vector2) -> void:
	var world := caster.world()
	var origin := caster.global_position
	var direction := aim.normalized() if aim.length() > 0.01 else caster.facing
	var power := GameData.weapon_power(caster.weapon_id)
	var damage := roundi(skill.get("damage", 0) * power)
	var color: Color = GameData.ITEMS[caster.weapon_id].color

	match skill.kind:
		"melee":
			for monster in monsters_within(caster, origin, skill.range):
				var offset := monster.global_position - origin
				if offset.length() < 16.0 or offset.normalized().dot(direction) > 0.2:
					monster.take_damage(damage, caster.peer_id, skill.get("stun", 0.0))
			world.play_effect.rpc("slash", origin, origin + direction * skill.range, skill.range, Color.WHITE)
		"circle":
			for monster in monsters_within(caster, origin, skill.radius):
				monster.take_damage(damage, caster.peer_id, skill.get("stun", 0.0))
			world.play_effect.rpc("ring", origin, origin, skill.radius, Color.WHITE)
		"shot":
			var target := pick_target(caster, origin, direction, skill.range)
			var end: Vector2 = target.global_position if target else origin + direction * skill.range
			if target:
				target.take_damage(damage, caster.peer_id, skill.get("stun", 0.0))
			world.play_effect.rpc("shot", origin, end, 0.0, color)
		"area":
			var target := pick_target(caster, origin, direction, skill.range)
			var center: Vector2 = target.global_position if target else origin + direction * skill.range * 0.5
			for monster in monsters_within(caster, center, skill.radius):
				monster.take_damage(damage, caster.peer_id, skill.get("stun", 0.0))
			world.play_effect.rpc("blast", center, center, skill.radius, color)
		"heal":
			var amount := roundi(skill.amount * power)
			for player: Player in caster.get_tree().get_nodes_in_group("players"):
				if player.global_position.distance_to(origin) <= skill.radius:
					player.heal(amount)
			world.play_effect.rpc("heal", origin, origin, skill.radius, Color("7ee081"))


static func monsters_within(caster: Node, center: Vector2, radius: float) -> Array[Monster]:
	var result: Array[Monster] = []
	for monster: Monster in caster.get_tree().get_nodes_in_group("monsters"):
		if monster.is_alive() and monster.global_position.distance_to(center) <= radius + monster.body_radius():
			result.append(monster)
	return result


## Cible la plus proche dans la direction visée, sinon la plus proche tout court.
static func pick_target(caster: Node, origin: Vector2, direction: Vector2, max_range: float) -> Monster:
	var best_ahead: Monster = null
	var best_any: Monster = null
	for monster in monsters_within(caster, origin, max_range):
		var offset := monster.global_position - origin
		if best_any == null or offset.length() < best_any.global_position.distance_to(origin):
			best_any = monster
		if offset.normalized().dot(direction) > 0.5:
			if best_ahead == null or offset.length() < best_ahead.global_position.distance_to(origin):
				best_ahead = monster
	return best_ahead if best_ahead else best_any
