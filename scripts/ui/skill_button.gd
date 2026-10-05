class_name SkillButton
extends TouchControl
## Bouton rond de compétence, avec temps de recharge affiché (style Guardian Tales).

signal triggered

@export var label := ""
@export var color := Color("3a6ea5")
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
	label = value
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
	var fill := color.lightened(0.25) if is_pressed() else color
	if not enabled:
		fill = fill.darkened(0.5)

	draw_circle(center, radius, Color(0, 0, 0, 0.35))
	draw_circle(center, radius * 0.9, fill)
	draw_arc(center, radius * 0.9, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 2.0, true)

	if _cooldown_left > 0.0 and _cooldown_total > 0.0:
		var fraction := _cooldown_left / _cooldown_total
		var shade := Color(0, 0, 0, 0.55)
		if fraction > 0.99:
			draw_circle(center, radius * 0.9, shade)
		elif fraction > 0.01:
			var points := PackedVector2Array([center])
			var steps := 32
			for i in steps + 1:
				var angle := -PI / 2.0 + TAU * fraction * i / steps
				points.append(center + Vector2.from_angle(angle) * radius * 0.9)
			draw_colored_polygon(points, shade)

	var font := ThemeDB.fallback_font
	var font_size := int(clampf(radius * 0.36, 11.0, 22.0))
	var text := label
	if _cooldown_left > 0.0:
		text = "%.1f" % _cooldown_left if _cooldown_left < 10.0 else str(ceili(_cooldown_left))
	_draw_centered_text(font, text, center, radius * 1.7, font_size)

	if not badge.is_empty():
		var badge_center := center + Vector2(radius * 0.68, -radius * 0.68)
		draw_circle(badge_center, radius * 0.3, Color("20242c"))
		_draw_centered_text(font, badge, badge_center, radius * 0.6, int(font_size * 0.85))


func _draw_centered_text(font: Font, text: String, center: Vector2, width: float, font_size: int) -> void:
	var lines := text.split("\n")
	var line_height := font.get_height(font_size)
	var top := center.y - line_height * lines.size() / 2.0 + font.get_ascent(font_size)
	for i in lines.size():
		var origin := Vector2(center.x - width / 2.0, top + i * line_height)
		draw_string_outline(font, origin, lines[i], HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 4, Color(0, 0, 0, 0.6))
		draw_string(font, origin, lines[i], HORIZONTAL_ALIGNMENT_CENTER, width, font_size, Color.WHITE)
