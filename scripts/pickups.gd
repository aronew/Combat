class_name Pickups
extends Node3D
## Pooled salvage shards dropped by kills, nests and the uplink. They pop out,
## settle, then get pulled to the player when close. Collected salvage is your
## dive "haul": banked on extraction, lost on death.

@export var pool_size := 160
@export var max_shards_per_drop := 6
@export var magnet_radius := 4.5
@export var magnet_speed := 24.0
@export var collect_radius := 0.9
@export var lifetime := 30.0
@export var shard_color := Color("ffd23d")

var _nodes: Array[MeshInstance3D] = []
var _vel: Array[Vector3] = []
var _age: Array[float] = []
var _value: Array[int] = []
var _active: Array[bool] = []
var _next := 0


func _ready() -> void:
	Game.pickups = self
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.22, 0.3, 0.22)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.22, 0.05)
	mat.emission_enabled = true
	mat.emission = shard_color
	mat.emission_energy_multiplier = 3.0
	for i in pool_size:
		var m := MeshInstance3D.new()
		m.mesh = mesh
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.visible = false
		m.top_level = true
		add_child(m)
		_nodes.append(m)
		_vel.append(Vector3.ZERO)
		_age.append(0.0)
		_value.append(0)
		_active.append(false)


## Scatter `amount` salvage as up to max_shards_per_drop shards.
func drop_salvage(pos: Vector3, amount: int) -> void:
	if amount <= 0:
		return
	var shards := clampi(amount, 1, max_shards_per_drop)
	var per := amount / shards
	var extra := amount - per * shards
	for i in shards:
		var idx := _next
		_next = (_next + 1) % pool_size
		var ang := randf() * TAU
		_nodes[idx].global_position = pos + Vector3(0, 0.6, 0)
		_vel[idx] = Vector3(cos(ang) * randf_range(1.5, 3.5), randf_range(3.0, 5.5), sin(ang) * randf_range(1.5, 3.5))
		_age[idx] = 0.0
		_value[idx] = per + (1 if i < extra else 0)
		_active[idx] = true
		_nodes[idx].visible = true


func _process(delta: float) -> void:
	var p := Game.player
	var target := p.global_position + Vector3.UP * 0.8 if p and p.alive else Vector3.INF
	for i in pool_size:
		if not _active[i]:
			continue
		var node := _nodes[i]
		_age[i] += delta
		if _age[i] > lifetime:
			_active[i] = false
			node.visible = false
			continue
		var pos := node.global_position
		if target != Vector3.INF and _age[i] > 0.35 and pos.distance_to(target) < magnet_radius:
			var to := target - pos
			if to.length() < collect_radius:
				_collect(i)
				continue
			_vel[i] = _vel[i].lerp(to.normalized() * magnet_speed, clampf(8.0 * delta, 0.0, 1.0))
		else:
			_vel[i].y -= 18.0 * delta
			_vel[i].x *= exp(-2.5 * delta)
			_vel[i].z *= exp(-2.5 * delta)
		pos += _vel[i] * delta
		if pos.y < 0.25 and _vel[i].y < 0.0:
			pos.y = 0.25
			_vel[i].y = -_vel[i].y * 0.35
		node.global_position = pos
		node.rotation.y += delta * 4.0
		if _age[i] > lifetime - 3.0:
			node.visible = fmod(_age[i] * 8.0, 1.0) > 0.3


func _collect(i: int) -> void:
	_active[i] = false
	_nodes[i].visible = false
	if Game.mission:
		Game.mission.add_haul(_value[i])
