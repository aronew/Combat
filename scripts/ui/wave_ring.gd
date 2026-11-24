@tool
class_name WaveRing
extends Control
## Top-centre ring (sciveg reference): arc shows how much of the wave is left.

@export var thickness := 7.0:
	set(v): thickness = v; queue_redraw()
@export var ring_color := Color("f2f6f8"):
	set(v): ring_color = v; queue_redraw()
@export var track_color := Color(1.0, 1.0, 1.0, 0.15):
	set(v): track_color = v; queue_redraw()
@export_range(0.0, 1.0) var ratio := 1.0:
	set(v): ratio = clampf(v, 0.0, 1.0); queue_redraw()

var _shown := 1.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_shown = lerpf(_shown, ratio, 1.0 - exp(-10.0 * delta))
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - thickness
	draw_arc(c, r, 0.0, TAU, 64, track_color, thickness, true)
	var shown := ratio if Engine.is_editor_hint() else _shown
	if shown > 0.001:
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * shown, 64, ring_color, thickness, true)
