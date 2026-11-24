@tool
class_name BossBar
extends Control
## Health bar for purple elites (top centre), with a trailing damage ghost.

@export var fill_color := Color("b04dff")
@export var ghost_color := Color(1, 1, 1, 0.8)
@export var track_color := Color(1, 1, 1, 0.12)
@export_range(0.0, 1.0) var ratio := 1.0:
	set(v): ratio = clampf(v, 0.0, 1.0); queue_redraw()

var _ghost := 1.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_ghost = maxf(ratio, _ghost - delta * 0.5) if _ghost > ratio else ratio
	queue_redraw()


func reset() -> void:
	_ghost = 1.0
	ratio = 1.0


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, track_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _ghost, size.y)), ghost_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y)), fill_color)
	draw_rect(r, Color(1, 1, 1, 0.3), false, 1.0)
