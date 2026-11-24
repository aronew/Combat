class_name VfxPulse
extends Node
## Animates its parent (a mesh or a light) once per effect play: a delay, then
## over `life` seconds the scale eases from `scale_from` to `scale_to` and the
## brightness fades from `fade_from` to `fade_to`. Meshes drive the VFX shader's
## `anim` uniform (fade, spin, age) on their own material copy; lights scale
## their energy.

@export var delay := 0.0
@export var life := 0.1
@export var scale_from := Vector3.ONE
@export var scale_to := Vector3.ONE
## Ease exponent: 1 linear, >1 fast start then slow (explosive growth).
@export var ease_power := 2.5
@export var fade_from := 1.0
@export var fade_to := 0.0
## Random spin per play (billboards: flashes never look the same twice).
@export var random_spin := false
## Snap to the floor (y = 0.04) on play: shockwaves and ground flashes.
@export var ground_snap := false
## Lights: peak energy (the effect's profile can scale it).
@export var light_energy := 0.0

var _t := -1.0
var _target: Node3D
var _energy_mult := 1.0
var _spin := 0.0


func _ready() -> void:
	_target = get_parent() as Node3D
	_hide()


func start(energy_mult := 1.0) -> void:
	_energy_mult = energy_mult
	_t = -delay
	if _target == null:
		return
	if ground_snap:
		var p := _target.global_position
		_target.global_position = Vector3(p.x, 0.04, p.z)
	_spin = randf() * TAU if random_spin else 0.0
	_apply(0.0)
	_target.visible = delay <= 0.0 and _allowed()


func is_running() -> bool:
	return _t >= -delay and _t <= life and _t > -999.0


func tick(delta: float) -> void:
	if _target == null or _t < -900.0:
		return
	_t += delta
	if _t < 0.0:
		return
	if _t > life:
		_hide()
		return
	_target.visible = _allowed()
	_apply(_t / maxf(life, 0.001))


func _apply(k: float) -> void:
	var e := 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), ease_power)
	var f := lerpf(fade_from, fade_to, clampf(k, 0.0, 1.0))
	if _target is OmniLight3D:
		(_target as OmniLight3D).light_energy = light_energy * _energy_mult * f
		return
	_target.scale = scale_from.lerp(scale_to, e)
	if _target is GeometryInstance3D:
		var m := (_target as GeometryInstance3D).material_override as ShaderMaterial
		if m:
			m.set_shader_parameter("anim", Vector4(f, _spin, k, 0.0))


func _hide() -> void:
	_t = -999.0
	if _target:
		_target.visible = false


## Lights stay off on LOW graphics (point lights are the expensive part).
func _allowed() -> bool:
	if not (_target is OmniLight3D):
		return true
	var gfx: Node = get_node_or_null("/root/Graphics")
	return gfx == null or not gfx.is_low()
