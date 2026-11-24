class_name DamageNumber
extends Label3D
## Floating damage number: pops in big, drifts up, fades. Pooled by FX.

@export var lifetime := 0.65
@export var rise := 1.3
@export var pop_scale := 1.8
@export var drift := 0.6

var _t := 0.0
var _start := Vector3.ZERO
var _drift := Vector3.ZERO
var _base_scale := 1.0
var _color := Color.WHITE


func _ready() -> void:
	visible = false
	set_process(false)


func play(pos: Vector3, value: String, tint: Color, scale_mult := 1.0) -> void:
	text = value
	_start = pos
	_drift = Vector3(randf_range(-drift, drift), 0.0, randf_range(-drift * 0.5, 0.0))
	_base_scale = scale_mult
	_color = tint
	_t = 0.0
	visible = true
	_apply(0.0)
	set_process(true)


## Merge another hit into this number: new total, re-pop, keep it up a bit longer.
func bump(value: String, scale_mult: float) -> void:
	text = value
	_base_scale = maxf(_base_scale, scale_mult)
	_t = minf(_t, lifetime * 0.15)
	_apply(_t / lifetime)


func is_showing() -> bool:
	return visible


func _process(delta: float) -> void:
	_t += delta
	var k := _t / lifetime
	if k >= 1.0:
		visible = false
		set_process(false)
		return
	_apply(k)


func _apply(k: float) -> void:
	var ease_up := 1.0 - pow(1.0 - k, 3.0)
	global_position = _start + Vector3.UP * rise * ease_up + _drift * ease_up
	var pop := lerpf(pop_scale, 1.0, clampf(k * 6.0, 0.0, 1.0))
	scale = Vector3.ONE * _base_scale * pop
	var a := 1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0)
	modulate = Color(_color.r, _color.g, _color.b, a)
	outline_modulate = Color(0.06, 0.02, 0.1, a)
