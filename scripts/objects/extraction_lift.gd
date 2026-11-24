class_name ExtractionLift
extends Node3D
## The freight lift you dropped in on, and your way out. Purely visual: the
## Mission decides when it's "called" and how long you must hold the pad.

@export var pad_size := Vector2(6.0, 5.0)
@export var radius := 3.0

var _beacons: Array[OmniLight3D] = []
var _beacon_mat: StandardMaterial3D
var _state := &"idle"
var _t := 0.0


func _ready() -> void:
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color("3a4047")
	frame_mat.metallic = 0.7
	frame_mat.roughness = 0.4
	_beacon_mat = StandardMaterial3D.new()
	_beacon_mat.albedo_color = Color(0.1, 0.06, 0.02)
	_beacon_mat.emission_enabled = true
	_beacon_mat.emission = Color("ffae45")
	_beacon_mat.emission_energy_multiplier = 3.0
	var hx := pad_size.x * 0.5
	var hz := pad_size.y * 0.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * hx, 0, sz * hz)
			_box(Vector3(0.3, 3.4, 0.3), p + Vector3(0, 1.7, 0), frame_mat)
			_box(Vector3(0.34, 0.4, 0.34), p + Vector3(0, 3.0, 0), _beacon_mat)
			var l := OmniLight3D.new()
			l.light_color = Color("ffae45")
			l.light_energy = 1.0
			l.omni_range = 5.0
			l.position = p * 0.85 + Vector3(0, 2.8, 0)
			add_child(l)
			_beacons.append(l)
	_box(Vector3(pad_size.x + 0.3, 0.3, 0.3), Vector3(0, 3.5, -hz), frame_mat)
	_box(Vector3(pad_size.x + 0.3, 0.3, 0.3), Vector3(0, 3.5, hz), frame_mat)
	_box(Vector3(0.3, 0.3, pad_size.y), Vector3(-hx, 3.5, 0), frame_mat)
	_box(Vector3(0.3, 0.3, pad_size.y), Vector3(hx, 3.5, 0), frame_mat)


## &"idle" | &"called" (pulsing, lift on the way) | &"ready".
func set_state(s: StringName) -> void:
	_state = s
	_t = 0.0


func _process(delta: float) -> void:
	_t += delta
	var energy := 1.0
	var color := Color("ffae45")
	if _state == &"called":
		energy = 1.0 + 2.0 * absf(sin(_t * 6.0))
		color = Color("ff5a3d")
	elif _state == &"ready":
		energy = 3.0
		color = Color("3dff9a")
	_beacon_mat.emission = color
	for l in _beacons:
		l.light_color = color
		l.light_energy = energy


func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi
