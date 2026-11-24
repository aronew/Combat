class_name Crosshair
extends Control
## Cyan reticle drawn at the mouse position (OS cursor is hidden during play).

@export var color := Color("19f4ff")
@export var radius := 11.0
@export var gap := 5.0
@export var tick := 7.0
@export var width := 2.0

var _kick := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func kick() -> void:
	_kick = 1.0


func _process(delta: float) -> void:
	_kick = maxf(_kick - delta * 10.0, 0.0)
	queue_redraw()


func _draw() -> void:
	var p := get_local_mouse_position()
	var r := radius + _kick * 4.0
	draw_arc(p, r, 0.0, TAU, 32, Color(color, 0.85), width, true)
	for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(p + d * (r + gap * 0.4), p + d * (r + gap * 0.4 + tick), color, width, true)
	draw_circle(p, 2.0, color)
