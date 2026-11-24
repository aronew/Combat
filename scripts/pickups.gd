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
@export_group("Health orbs")
@export var orb_pool_size := 40
@export var orb_color := Color("3dff7a")
@export var orb_lifetime := 20.0

var _nodes: Array[MeshInstance3D] = []
var _vel: Array[Vector3] = []
var _age: Array[float] = []
var _value: Array[int] = []
var _active: Array[bool] = []
var _kind: Array[int] = []  # 0 = salvage shard, 1 = health orb (value = heal amount)
var _next := 0
var _next_orb := 0


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
		_add_node(mesh, mat, 0)
	var orb := SphereMesh.new()
	orb.radius = 0.2
	orb.height = 0.4
	orb.radial_segments = 10
	orb.rings = 5
	var orb_mat := StandardMaterial3D.new()
	orb_mat.albedo_color = Color(0.05, 0.25, 0.1)
	orb_mat.emission_enabled = true
	orb_mat.emission = orb_color
	orb_mat.emission_energy_multiplier = 3.0
	for i in orb_pool_size:
		_add_node(orb, orb_mat, 1)


func _add_node(mesh: Mesh, mat: Material, kind: int) -> void:
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
	_kind.append(kind)


## Green health orbs: only drawn to you while you're hurt, so you can leave
## them on the deck for later.
func drop_health(pos: Vector3, count: int, heal_each: int) -> void:
	for i in count:
		var idx := pool_size + _next_orb
		_next_orb = (_next_orb + 1) % orb_pool_size
		var ang := randf() * TAU
		_nodes[idx].global_position = pos + Vector3(0, 0.6, 0)
		_vel[idx] = Vector3(cos(ang) * randf_range(1.0, 2.5), randf_range(3.0, 5.0), sin(ang) * randf_range(1.0, 2.5))
		_age[idx] = 0.0
		_value[idx] = heal_each
		_active[idx] = true
		_nodes[idx].visible = true


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


## Drop an item on the deck as a loot beam.
func drop_item(pos: Vector3, item: Dictionary) -> void:
	var d := LootDrop.new()
	d.setup(item)
	var p := Game.level.clamp_to_walkable(pos, 0.6) if Game.level else pos
	d.position = Vector3(p.x, 0.0, p.z)
	add_child(d)
	Audio.play_at([&"loot_drop_common", &"loot_drop_rare", &"loot_drop_epic", &"loot_drop_legendary"][clampi(int(item.get("rarity", 0)), 0, 3)], d.position)


func _process(delta: float) -> void:
	var p := Game.player
	var target := p.global_position + Vector3.UP * 0.8 if p and p.alive else Vector3.INF
	var hurt := p != null and p.alive and p.health < p.max_health - 0.5
	for i in _nodes.size():
		if not _active[i]:
			continue
		var node := _nodes[i]
		_age[i] += delta
		if _age[i] > (orb_lifetime if _kind[i] == 1 else lifetime):
			_active[i] = false
			node.visible = false
			continue
		var pos := node.global_position
		var wants := _kind[i] == 0 or hurt
		if wants and target != Vector3.INF and _age[i] > 0.35 and pos.distance_to(target) < magnet_radius:
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
		if _age[i] > (orb_lifetime if _kind[i] == 1 else lifetime) - 3.0:
			node.visible = fmod(_age[i] * 8.0, 1.0) > 0.3


func _collect(i: int) -> void:
	_active[i] = false
	_nodes[i].visible = false
	if _kind[i] == 1:
		Audio.play(&"heal_orb")
		if Game.player:
			Game.player.heal(_value[i])
	elif Game.mission:
		Audio.play(&"salvage_pickup")
		Game.mission.add_haul(_value[i])
