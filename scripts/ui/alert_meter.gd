@tool
class_name AlertMeter
extends Control
## Hive alert bar: four coloured zones (dormant / stirring / hunting / alarm)
## with a fill and a pulse when the station is in full alarm.

@export var colors: Array[Color] = [Color("2fd1c4"), Color("ffd23d"), Color("ff8a1e"), Color("ff2b4b")]
@export var track_color := Color(1, 1, 1, 0.1)
@export var skew := 6.0
@export var thresholds := Vector2(25.0, 60.0)
@export_range(0.0, 100.0) var value := 0.0:
	set(v): value = clampf(v, 0.0, 100.0); queue_redraw()
@export_range(0, 3) var level := 0:
	set(v): level = v; queue_redraw()

var _t := 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if level == 3:
		queue_redraw()


func _draw() -> void:
	var h := size.y
	var w := size.x - skew
	_quad(0.0, w, h, track_color)
	# Threshold ticks.
	for t in [thresholds.x, thresholds.y]:
		var x: float = w * t / 100.0
		draw_line(Vector2(x + skew, -3), Vector2(x, h + 3), Color(1, 1, 1, 0.35), 1.5)
	var c: Color = colors[level]
	if level == 3:
		c = c.lerp(Color.WHITE, 0.25 + 0.25 * sin(_t * 9.0))
	_quad(0.0, w * value / 100.0, h, c)


func _quad(x: float, w: float, h: float, c: Color) -> void:
	if w <= 0.5:
		return
	draw_colored_polygon(PackedVector2Array([
		Vector2(x + skew, 0), Vector2(x + skew + w, 0), Vector2(x + w, h), Vector2(x, h)]), c)
