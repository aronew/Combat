@tool
class_name SegmentedBar
extends Control
## Skewed segmented bar like the sciveg HUD. A white "lag" ghost drains after
## damage so hits read clearly.

@export var segments := 10:
	set(v): segments = maxi(v, 1); queue_redraw()
@export var gap := 5.0:
	set(v): gap = v; queue_redraw()
@export var skew := 7.0:
	set(v): skew = v; queue_redraw()
@export var fill_color := Color("43e8f0"):
	set(v): fill_color = v; queue_redraw()
@export var low_color := Color("ff3b6b")
@export_range(0.0, 1.0) var low_threshold := 0.3
@export var lag_color := Color(1.0, 1.0, 1.0, 0.95)
@export var empty_color := Color(1.0, 1.0, 1.0, 0.13):
	set(v): empty_color = v; queue_redraw()
@export var lag_delay := 0.35
@export var lag_speed := 0.8
@export_range(0.0, 1.0) var ratio := 1.0:
	set(v): ratio = clampf(v, 0.0, 1.0); queue_redraw()

var _lag := 1.0
var _lag_wait := 0.0
var _pulse := 0.0


func set_value(new_ratio: float) -> void:
	if new_ratio < ratio:
		_lag = maxf(_lag, ratio)
		_lag_wait = lag_delay
	else:
		_lag = new_ratio
	ratio = new_ratio


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_pulse += delta
	if _lag > ratio:
		if _lag_wait > 0.0:
			_lag_wait -= delta
		else:
			_lag = maxf(ratio, _lag - lag_speed * delta)
	queue_redraw()


func _draw() -> void:
	var w := (size.x - gap * (segments - 1) - skew) / segments
	var h := size.y
	var col := fill_color
	if ratio <= low_threshold and not Engine.is_editor_hint():
		col = fill_color.lerp(low_color, 0.5 + 0.5 * sin(_pulse * 10.0))
	for i in segments:
		var x := i * (w + gap)
		var lo := float(i) / segments
		_seg(x, w, h, 1.0, empty_color)
		var lag_fill := clampf((_lag - lo) * segments, 0.0, 1.0)
		if lag_fill > 0.0:
			_seg(x, w, h, lag_fill, lag_color)
		var fill := clampf((ratio - lo) * segments, 0.0, 1.0)
		if fill > 0.0:
			_seg(x, w, h, fill, col)


func _seg(x: float, w: float, h: float, amount: float, c: Color) -> void:
	var fw := w * amount
	draw_colored_polygon(PackedVector2Array([
		Vector2(x + skew, 0.0), Vector2(x + skew + fw, 0.0),
		Vector2(x + fw, h), Vector2(x, h),
	]), c)
