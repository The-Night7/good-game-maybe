class_name SkillButton
extends TouchControl
## Bouton rond de compétence (style Guardian Tales, habillage Albion) :
## anneau de bronze à liseré doré, pictogramme, temps de recharge affiché.

signal triggered

const RIM := Color("c9a35a")
const RING := Color("1b1612")
const INK := Color("f3e6c8")

@export var label := ""
## Pictogramme dessiné au centre (voir Icons). Sans pictogramme, le nom est écrit.
@export var icon := ""
@export var color := Color("3a5a78")
## Maintenir le bouton relance l'action dès que la recharge est finie (attaque de base).
@export var repeat_while_held := false

## Petit texte en haut à droite (ex. nombre de potions).
var badge := "":
	set(value):
		badge = value
		queue_redraw()
var enabled := true:
	set(value):
		enabled = value
		queue_redraw()

var _cooldown_total := 0.0
var _cooldown_left := 0.0


func start_cooldown(seconds: float) -> void:
	_cooldown_total = seconds
	_cooldown_left = seconds
	queue_redraw()


func is_ready() -> bool:
	return enabled and _cooldown_left <= 0.0


func set_label(value: String) -> void:
	if value != label:
		label = value
		queue_redraw()


func set_icon(value: String) -> void:
	if value != icon:
		icon = value
		queue_redraw()


func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)
		queue_redraw()
	elif repeat_while_held and is_pressed() and enabled:
		triggered.emit()


func _on_press(_screen_position: Vector2) -> void:
	if is_ready():
		triggered.emit()
	queue_redraw()


func _on_release() -> void:
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	var inner := radius * 0.84
	var fill := color.lightened(0.2) if is_pressed() else color
	if not enabled:
		fill = fill.darkened(0.55)

	draw_circle(center + Vector2(0, 3), radius, Color(0, 0, 0, 0.35))
	draw_circle(center, radius, Color(RING, 0.92))
	draw_arc(center, radius * 0.95, 0.0, TAU, 48, Color(RIM, 0.9 if enabled else 0.4), maxf(2.0, radius * 0.05), true)
	draw_circle(center, inner, fill.darkened(0.25))
	draw_circle(center + Vector2(0, -inner * 0.18), inner * 0.82, fill)
	draw_arc(center, inner, PI * 1.1, PI * 1.9, 24, Color(1, 1, 1, 0.12), maxf(2.0, radius * 0.06), true)

	var font := ThemeDB.fallback_font
	var show_name := not label.is_empty() and (icon.is_empty() or radius >= 60.0)
	var icon_center := center + (Vector2(0, -radius * 0.12) if show_name and not icon.is_empty() else Vector2.ZERO)
	var ink := INK if enabled else Color(INK, 0.4)
	if not icon.is_empty():
		Icons.draw(self, icon, icon_center, radius * (0.36 if show_name else 0.45), ink)
	if show_name:
		var name_size := int(clampf(radius * 0.22, 11.0, 18.0))
		var name_center := center + Vector2(0, radius * 0.48) if not icon.is_empty() else center
		_draw_centered_text(font, label, name_center, radius * 1.6, name_size, ink)

	if _cooldown_left > 0.0 and _cooldown_total > 0.0:
		var fraction := _cooldown_left / _cooldown_total
		var cover := Color(0.05, 0.04, 0.03, 0.62)
		if fraction > 0.99:
			draw_circle(center, inner, cover)
		elif fraction > 0.01:
			var points := PackedVector2Array([center])
			var steps := 32
			for i in steps + 1:
				var angle := -PI / 2.0 + TAU * fraction * i / steps
				points.append(center + Vector2.from_angle(angle) * inner)
			draw_colored_polygon(points, cover)
		var seconds := "%.1f" % _cooldown_left if _cooldown_left < 10.0 else str(ceili(_cooldown_left))
		_draw_centered_text(font, seconds, center, radius * 1.6, int(clampf(radius * 0.4, 14.0, 30.0)), Color.WHITE)

	if not badge.is_empty():
		var badge_center := center + Vector2(radius * 0.7, -radius * 0.7)
		draw_circle(badge_center, radius * 0.3, RING)
		draw_arc(badge_center, radius * 0.3, 0.0, TAU, 24, RIM, 1.5, true)
		_draw_centered_text(font, badge, badge_center, radius * 0.6, int(clampf(radius * 0.28, 11.0, 16.0)), INK)


func _draw_centered_text(font: Font, text: String, center: Vector2, width: float, font_size: int, ink: Color) -> void:
	var lines := text.split("\n")
	var line_height := font.get_height(font_size)
	var top := center.y - line_height * lines.size() / 2.0 + font.get_ascent(font_size)
	for i in lines.size():
		var origin := Vector2(center.x - width / 2.0, top + i * line_height)
		draw_string_outline(font, origin, lines[i], HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 4, Color(0, 0, 0, 0.7))
		draw_string(font, origin, lines[i], HORIZONTAL_ALIGNMENT_CENTER, width, font_size, ink)
