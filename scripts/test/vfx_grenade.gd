class_name VfxGrenade
extends Node3D
## A thrown grenade for the VFX arena: arcs from the hand to a target, ticks,
## then detonates through Game.explode (real damage, the framework's effect).

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0
var _flight := 0.6
var _fuse := 0.12
var _mesh: MeshInstance3D


func throw(from: Vector3, to: Vector3) -> void:
	_from = from
	_to = Vector3(to.x, 0.12, to.z)
	_flight = clampf(from.distance_to(to) / 18.0, 0.35, 0.8)
	_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.24
	_mesh.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.1, 0.1, 0.12)
	m.emission_enabled = true
	m.emission = Color(1, 0.25, 0.1)
	m.emission_energy_multiplier = 3.0
	_mesh.material_override = m
	add_child(_mesh)
	global_position = from


func _process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / _flight, 0.0, 1.0)
	var p := _from.lerp(_to, k)
	p.y = lerpf(_from.y, _to.y, k) + sin(k * PI) * 2.2
	global_position = p
	_mesh.rotation += Vector3(9.0, 5.0, 0.0) * delta
	if k >= 1.0:
		_fuse -= delta
		_mesh.scale = Vector3.ONE * (1.0 + 0.4 * sin(_t * 60.0))
		if _fuse <= 0.0:
			Game.explode(_to, 3.6, 90.0, 0.0, 12.0, null, 2.4)
			queue_free()
