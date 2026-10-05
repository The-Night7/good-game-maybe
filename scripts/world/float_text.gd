extends Node2D
## Texte flottant (dégâts, soins, butin) qui monte puis disparaît.

const DURATION := 0.9
const RISE := 32.0

var text := ""
var color := Color.WHITE

var _time := 0.0
var _start := Vector2.ZERO


func _ready() -> void:
	_start = position


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
		return
	position = _start + Vector2(0, -RISE * _time / DURATION)
	modulate.a = 1.0 - maxf(0.0, _time / DURATION - 0.5) * 2.0


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var origin := Vector2(-80, 0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, 160, 15, 4, Color(0, 0, 0, 0.75))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, 160, 15, color)
