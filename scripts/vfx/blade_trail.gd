class_name BladeTrail
extends MeshInstance3D
## A ribbon behind a moving blade. Each point is the blade's base and tip in world space; the
## ribbon between points is smoothed with Catmull-Rom splines, so a few samples across a fast
## swing still make a round arc. Points age on game time (they freeze in hitstop) and die
## after `life` seconds. Points with different `seg` ids are separate ribbons (one per cut),
## so a new swing never joins up with the last one.
##
## Look: blade_trail.gdshader. UV.x is the point's age (0 new .. 1 gone), UV.y runs from the
## base (0) to the tip (1).

@export var life := 0.13
## Spline points inserted between two samples.
@export var subdivisions := 4
## Safety cap on stored points.
@export var max_points := 96

var _pts: Array[Dictionary] = []
var _im := ImmediateMesh.new()
var _mat := ShaderMaterial.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = _im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat.shader = preload("res://scripts/shaders/vfx/blade_trail.gdshader")
	material_override = _mat
	# the ribbon is rebuilt in world space every frame; never cull it on a stale box
	custom_aabb = AABB(Vector3(-1.0e5, -1.0e5, -1.0e5), Vector3(2.0e5, 2.0e5, 2.0e5))


## colour, brightness, and width scale of the hot core (bigger for finishers)
func set_look(color: Color, energy: float, core := 1.0) -> void:
	_mat.set_shader_parameter("tint", color)
	_mat.set_shader_parameter("energy", energy)
	_mat.set_shader_parameter("core_width", 0.22 * core)


## age: how old the point already is (sub-frame samples are a little older than the frame).
func add_point(base: Vector3, tip: Vector3, seg: int, age := 0.0) -> void:
	_pts.append({"base": base, "tip": tip, "seg": seg, "age": age})
	if _pts.size() > max_points:
		_pts.pop_front()


func clear() -> void:
	_pts.clear()
	_im.clear_surfaces()


func _process(delta: float) -> void:
	if _pts.is_empty():
		if _im.get_surface_count() > 0:
			_im.clear_surfaces()
		return
	for p in _pts:
		p.age += delta
	while not _pts.is_empty() and _pts[0].age >= life:
		_pts.pop_front()
	_rebuild()


func _rebuild() -> void:
	_im.clear_surfaces()
	var i := 0
	while i < _pts.size():
		var j := i
		while j + 1 < _pts.size() and _pts[j + 1].seg == _pts[i].seg:
			j += 1
		if j > i:
			_strip(i, j)
		i = j + 1


## One ribbon through points first..last (oldest first).
func _strip(first: int, last: int) -> void:
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _mat)
	for k in range(first, last):
		var p0 := _pts[maxi(k - 1, first)]
		var p1 := _pts[k]
		var p2 := _pts[k + 1]
		var p3 := _pts[mini(k + 2, last)]
		for s in subdivisions:
			var t := float(s) / subdivisions
			_vert(_cr(p0.base, p1.base, p2.base, p3.base, t), _cr(p0.tip, p1.tip, p2.tip, p3.tip, t),
				lerpf(p1.age, p2.age, t))
	var e := _pts[last]
	_vert(e.base, e.tip, e.age)
	_im.surface_end()


func _vert(base: Vector3, tip: Vector3, age: float) -> void:
	var a := clampf(age / life, 0.0, 1.0)
	_im.surface_set_uv(Vector2(a, 0.0))
	_im.surface_add_vertex(base)
	_im.surface_set_uv(Vector2(a, 1.0))
	_im.surface_add_vertex(tip)


## Catmull-Rom between p1 and p2.
static func _cr(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3)
