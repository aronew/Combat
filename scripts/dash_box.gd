@tool
class_name AbilityBox
extends Control
## Top-right ability square (sciveg reference). Fills from the bottom while
## cooling down, turns solid white when ready and flashes on use.

@export var ready_color := Color("f2f6f8")
@export var cooling_color := Color(1.0, 1.0, 1.0, 0.35)
@export var frame_color := Color(1.0, 1.0, 1.0, 0.25)
@export var used_flash_color := Color("19f4ff")
@export_range(0.0, 1.0) var ratio := 1.0:
	set(v):
		if v < ratio - 0.5:
			_flash = 1.0
		ratio = clampf(v, 0.0, 1.0)
		queue_redraw()

var _flash := 0.0


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 4.0, 0.0)
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0, 0, 0, 0.25), true)
	if ratio >= 1.0:
		draw_rect(r, ready_color, true)
	else:
		var h := size.y * ratio
		draw_rect(Rect2(0.0, size.y - h, size.x, h), cooling_color, true)
	draw_rect(r, frame_color, false, 2.0)
	if _flash > 0.0:
		var c := used_flash_color
		c.a = _flash
		draw_rect(r.grow(4.0 * _flash), c, false, 3.0)
