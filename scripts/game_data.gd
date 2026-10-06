class_name GameData
## Données du jeu : objets, armes et compétences, recettes, ressources, monstres.
## Tout l'équilibrage se règle ici.

## L'arme équipée définit les compétences (comme Albion Online).
## Ordre des compétences : [attaque de base, compétence 1, compétence 2].
## Types : melee (cône devant), circle (autour de soi), shot (cible unique à distance),
## area (zone autour de la cible), heal (soigne les alliés autour).
## « icon » choisit le pictogramme dessiné sur le bouton (voir SkillButton).
const WEAPON_SKILLS := {
	"sword": [
		{"name": "Taillade", "icon": "sword", "kind": "melee", "damage": 12, "range": 52.0, "cooldown": 0.5},
		{"name": "Tourbillon", "icon": "whirl", "kind": "circle", "damage": 18, "radius": 76.0, "cooldown": 5.0},
		{"name": "Fracas", "icon": "smash", "kind": "melee", "damage": 40, "range": 58.0, "cooldown": 8.0, "stun": 1.5},
	],
	"bow": [
		{"name": "Tir", "icon": "arrow", "kind": "shot", "damage": 10, "range": 240.0, "cooldown": 0.6},
		{"name": "Pluie de flèches", "icon": "arrow_rain", "kind": "area", "damage": 16, "range": 240.0, "radius": 64.0, "cooldown": 6.0},
		{"name": "Tir perçant", "icon": "pierce", "kind": "shot", "damage": 38, "range": 280.0, "cooldown": 7.0},
	],
	"staff": [
		{"name": "Boule de feu", "icon": "fireball", "kind": "shot", "damage": 12, "range": 200.0, "cooldown": 0.8},
		{"name": "Explosion", "icon": "burst", "kind": "area", "damage": 26, "range": 200.0, "radius": 72.0, "cooldown": 7.0},
		{"name": "Soin", "icon": "heal", "kind": "heal", "amount": 35, "radius": 110.0, "cooldown": 10.0},
	],
}

const ITEMS := {
	"wood": {"name": "Bois", "color": Color("a0703c")},
	"ore": {"name": "Minerai", "color": Color("9aa3ad")},
	"fiber": {"name": "Fibre", "color": Color("c9d46a")},
	"jelly": {"name": "Gelée", "color": Color("6fd3a0")},
	"potion": {"name": "Potion de soin", "color": Color("e0505a"), "heal": 40},
	"sword_wood": {"name": "Épée en bois", "color": Color("c89a5a"), "slot": "weapon", "weapon": "sword", "power": 1.0},
	"sword_iron": {"name": "Épée de fer", "color": Color("d0d6dc"), "slot": "weapon", "weapon": "sword", "power": 1.6},
	"bow_hunter": {"name": "Arc de chasseur", "color": Color("8a5a2b"), "slot": "weapon", "weapon": "bow", "power": 1.2},
	"staff_ember": {"name": "Bâton de braise", "color": Color("ff8a3d"), "slot": "weapon", "weapon": "staff", "power": 1.2},
	"leather_vest": {"name": "Veste de cuir", "color": Color("7a4e2d"), "slot": "armor", "max_hp": 40},
}

## Recettes d'artisanat, dans l'ordre d'affichage.
const RECIPES := [
	{"item": "potion", "cost": {"jelly": 2, "fiber": 1}},
	{"item": "sword_iron", "cost": {"wood": 3, "ore": 5}},
	{"item": "bow_hunter", "cost": {"wood": 6, "fiber": 4}},
	{"item": "staff_ember", "cost": {"wood": 4, "ore": 2, "jelly": 3}},
	{"item": "leather_vest", "cost": {"fiber": 6, "jelly": 4}},
]

## Points de récolte : ce qu'ils donnent et combien de coups avant épuisement.
const RESOURCES := {
	"tree": {"item": "wood", "hits": 3, "respawn": 30.0},
	"rock": {"item": "ore", "hits": 3, "respawn": 40.0},
	"bush": {"item": "fiber", "hits": 2, "respawn": 25.0},
}

const MONSTERS := {
	"slime": {
		"name": "Slime", "hp": 40, "damage": 6, "speed": 55.0, "color": Color("6fa35a"),
		"size": 1.0, "loot": {"jelly": [1, 2]},
	},
	"rock_slime": {
		"name": "Slime de roche", "hp": 110, "damage": 12, "speed": 45.0, "color": Color("7d8a8c"),
		"size": 1.35, "loot": {"jelly": [1, 2], "ore": [1, 3]},
	},
}

## Équipement et sac d'un nouveau personnage.
const STARTING_WEAPON := "sword_wood"
const STARTING_INVENTORY := {"sword_wood": 1, "potion": 3}


static func item_name(item_id: String) -> String:
	return ITEMS[item_id].name if item_id in ITEMS else item_id


static func skills_for(weapon_item: String) -> Array:
	return WEAPON_SKILLS[ITEMS[weapon_item].weapon]


static func weapon_power(weapon_item: String) -> float:
	return ITEMS[weapon_item].get("power", 1.0)


static func armor_bonus(armor_item: String) -> int:
	return ITEMS[armor_item].get("max_hp", 0) if armor_item in ITEMS else 0


static func recipe_for(item_id: String) -> Dictionary:
	for recipe: Dictionary in RECIPES:
		if recipe.item == item_id:
			return recipe
	return {}


static func can_afford(inventory: Dictionary, cost: Dictionary) -> bool:
	for item: String in cost:
		if inventory.get(item, 0) < cost[item]:
			return false
	return true
