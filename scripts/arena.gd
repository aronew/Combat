@tool
class_name Arena
extends Node3D
## Greybox industrial platform suspended over a teal void (built from primitives).
## Runs in the editor too, so you can see the layout; generated nodes are not saved
## into the scene. Use the "Rebuild arena" button in the inspector after edits.
##
## Also answers gameplay questions for other systems: spawn points along the
## railings / hive, and a cheap "which way to the bridge" steering target.

@export_tool_button("Rebuild arena") var rebuild_action := _rebuild

@export_group("Platform")
@export var half_size := Vector2(16.0, 11.0)
@export var deck_thickness := 1.0
@export var tile_size := 3.0

@export_group("Railings")
@export var rail_height := 1.05
@export var rail_post_spacing := 1.8
@export var rail_collision_height := 1.3

@export_group("Lamps")
@export var lamp_spacing := 8.0
@export var lamp_color := Color("ffae45")
@export var lamp_energy := 3.2
@export var lamp_range := 7.0
@export var lamp_emission := 6.0
@export var lamp_shadows := false

@export_group("Hive")
@export var hive_center := Vector3(13.4, 0.0, -8.3)
@export var hive_glow := 1.1
@export var hive_light_energy := 1.6
@export var hive_light_range := 11.0

@export_group("Crates")
## x, z = position, y = rotation in degrees, w = stack height (1-3).
@export var crate_layout := PackedVector4Array([
	Vector4(-9.6, -5.6, 0, 2), Vector4(-7.9, -5.6, 0, 1), Vector4(-9.6, -3.9, 90, 1),
	Vector4(8.4, 0.6, 0, 1), Vector4(8.4, 2.3, 0, 2), Vector4(8.4, 4.0, 0, 1),
	Vector4(-3.6, 7.4, 0, 1), Vector4(-1.9, 7.4, 0, 2),
	Vector4(2.2, -7.6, 8, 2), Vector4(3.9, -7.4, 0, 1),
	Vector4(-12.6, 7.6, 0, 1), Vector4(-12.6, 5.9, 90, 1),
	Vector4(-31.4, -3.0, 0, 2), Vector4(-31.4, 3.1, 0, 1),
	Vector4(28.6, 6.3, 0, 1), Vector4(28.6, 1.6, 0, 2),
])

@export_group("Void")
@export var void_fog_density := 0.04
@export var void_fog_top := -2.5
@export var void_fog_albedo := Color("b4dcd8")
@export var void_fog_emission := Color("127078")
@export var pillar_strip_energy := 3.5

## Side platforms reached by narrow catwalk bridges.
## side: -1 west / +1 east, z: bridge centre line, width/length of bridge, platform size.
const BRIDGES := [
	{"side": -1, "z": 0.0, "width": 2.8, "length": 8.0, "platform": Vector2(10.0, 10.0)},
	{"side": 1, "z": 4.0, "width": 2.6, "length": 7.0, "platform": Vector2(8.0, 8.0)},
]

var _root: Node3D
var _static: StaticBody3D
var _mats := {}
var _mesh_cache := {}

# Gameplay data gathered while building.
var _spawn_edges: Array[Dictionary] = []
var _spawn_edge_total := 0.0
var _hive_spawns: Array[Vector3] = []
var _bridge_nav: Array[Dictionary] = []
var _blockers: Array[Vector3] = []  # x, z, radius
var _walkable: Array[Rect2] = []  # XZ rectangles of deck you can stand on


func _ready() -> void:
	_rebuild()
	if not Engine.is_editor_hint():
		Game.arena = self


# --------------------------------------------------------------------------
# Gameplay queries
# --------------------------------------------------------------------------

## 0 = main platform, 1.. = side region (bridge + platform) in BRIDGES order.
func region_of(p: Vector3) -> int:
	if absf(p.x) <= half_size.x + 0.05:
		return 0
	for i in BRIDGES.size():
		if signf(p.x) == BRIDGES[i].side:
			return i + 1
	return 0


## Next point an enemy at `from` should run toward to reach `to`,
## routing through bridge mouths so swarms don't pile up on railings.
func get_nav_target(from: Vector3, to: Vector3) -> Vector3:
	var rf := region_of(from)
	var rt := region_of(to)
	if rf == 0 and rt == 0:
		return to
	if rf == 0:
		var nav: Dictionary = _bridge_nav[rt - 1]
		if not _lined_up(from, nav, nav.a_in):
			return nav.a_in
		return to if _on_bridge(to, nav) else nav.b_in
	var here: Dictionary = _bridge_nav[rf - 1]
	if _on_bridge(from, here):
		if rt == rf:
			return to if _on_bridge(to, here) else here.b_in
		return here.a_in
	if rt == rf:
		return to
	return here.a_in if _lined_up(from, here, here.b_in) else here.b_in


## True when `p` is close to a bridge mouth AND centred on the bridge, so a
## straight run along the catwalk won't snag the railing ends.
func _lined_up(p: Vector3, nav: Dictionary, mouth: Vector3) -> bool:
	return _flat_dist(p, mouth) < 2.2 and absf(p.z - nav.z) < nav.half_w - 0.55


## Returns [start_in_void, landing_point] for a bug leaping over the railing.
func get_edge_spawn(avoid: Vector3, min_distance: float) -> Array[Vector3]:
	for attempt in 16:
		var edge := _pick_edge()
		var p: Vector3 = edge.a.lerp(edge.b, randf_range(0.04, 0.96))
		var land: Vector3 = p + edge.inward * randf_range(1.3, 2.2)
		if _flat_dist(land, hive_center) < 5.0:
			continue
		if _flat_dist(land, avoid) < min_distance and attempt < 12:
			continue
		if _is_blocked(land, 0.6):
			continue
		var start: Vector3 = p - edge.inward * 2.4 + Vector3(0.0, -3.2, 0.0)
		return [start, land]
	return [Vector3(0, -3, -half_size.y - 2.0), Vector3(0, 0, -half_size.y + 2.0)]


func get_hive_spawn() -> Vector3:
	if _hive_spawns.is_empty():
		return hive_center
	var p: Vector3 = _hive_spawns.pick_random()
	return clamp_to_walkable(p + Vector3(randf_range(-0.6, 0.6), 0.0, randf_range(-0.6, 0.6)))


func is_walkable(p: Vector3) -> bool:
	for r in _walkable:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return false


## Pulls a point onto the deck, at least `margin` from any railing.
func clamp_to_walkable(p: Vector3, margin := 0.8) -> Vector3:
	var best := p
	var best_d := INF
	for r in _walkable:
		var inner := r.grow(-margin)
		var q := Vector2(clampf(p.x, inner.position.x, inner.end.x), clampf(p.z, inner.position.y, inner.end.y))
		var d := q.distance_squared_to(Vector2(p.x, p.z))
		if d < best_d:
			best_d = d
			best = Vector3(q.x, p.y, q.y)
	return best


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _on_bridge(p: Vector3, nav: Dictionary) -> bool:
	return p.x >= nav.x_min and p.x <= nav.x_max and absf(p.z - nav.z) <= nav.half_w + 0.6


func _pick_edge() -> Dictionary:
	var r := randf() * _spawn_edge_total
	for e in _spawn_edges:
		r -= e.length
		if r <= 0.0:
			return e
	return _spawn_edges.back()


func _is_blocked(p: Vector3, radius: float) -> bool:
	for b in _blockers:
		if Vector2(p.x - b.x, p.z - b.y).length() < b.z + radius:
			return true
	return false


# --------------------------------------------------------------------------
# Building
# --------------------------------------------------------------------------

func _rebuild() -> void:
	var old := get_node_or_null("Generated")
	if old:
		remove_child(old)
		old.free()
	_mats.clear()
	_mesh_cache.clear()
	_spawn_edges.clear()
	_spawn_edge_total = 0.0
	_hive_spawns.clear()
	_bridge_nav.clear()
	_blockers.clear()
	_walkable.clear()

	_root = Node3D.new()
	_root.name = "Generated"
	add_child(_root)
	_static = StaticBody3D.new()
	_static.name = "Collision"
	_static.collision_layer = 1
	_static.collision_mask = 0
	_root.add_child(_static)

	_make_materials()
	_build_main_platform()
	_build_bridges()
	_build_crates()
	_build_hive()
	_build_background_machinery()
	_build_void()


func _make_materials() -> void:
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = preload("res://scripts/shaders/floor.gdshader")
	floor_mat.set_shader_parameter("tile_size", tile_size)
	floor_mat.set_shader_parameter("hive_center", hive_center)
	_mats.floor = floor_mat

	var grate := ShaderMaterial.new()
	grate.shader = preload("res://scripts/shaders/grate.gdshader")
	_mats.grate = grate

	var hazard := ShaderMaterial.new()
	hazard.shader = preload("res://scripts/shaders/hazard.gdshader")
	_mats.hazard = hazard

	_mats.beam = _std(Color("181c20"), 0.6, 0.6)
	_mats.pillar = _std(Color("1a2023"), 0.4, 0.7)
	_mats.rail = _std(Color("6b737a"), 0.8, 0.35)
	_mats.rail_dark = _std(Color("3a4047"), 0.7, 0.5)
	_mats.guide = _std(Color("e8731e"), 0.1, 0.5, Color("e8731e"), 0.5)
	_mats.lamp_post = _std(Color("2c3136"), 0.7, 0.45)
	_mats.lamp_head = _std(Color("201a10"), 0.0, 0.5, lamp_color, lamp_emission)
	_mats.crate = _std(Color("9aa2a8"), 0.25, 0.55)
	_mats.crate_dark = _std(Color("40474e"), 0.5, 0.5)
	_mats.crate_orange = _std(Color("d9662a"), 0.1, 0.6)
	_mats.hive_flesh = _std(Color("1a2410"), 0.0, 0.35, Color("8dff2e"), 0.12)
	_mats.hive_pod = _std(Color("4f9a12"), 0.0, 0.25, Color("8dff2e"), hive_glow)
	_mats.hive_root = _std(Color("10160a"), 0.0, 0.6, Color("4d8f16"), 0.4)
	_mats.machine = _std(Color("8a9297"), 0.35, 0.5)
	_mats.teal_strip = _std(Color("0a1514"), 0.0, 0.5, Color("7ff5e8"), pillar_strip_energy)


func _std(albedo: Color, metallic: float, roughness: float, emission := Color.BLACK, emission_energy := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emission_energy
	return m


func _box_mesh(size: Vector3) -> BoxMesh:
	var key := "b%s" % size
	if not _mesh_cache.has(key):
		var bm := BoxMesh.new()
		bm.size = size
		_mesh_cache[key] = bm
	return _mesh_cache[key]


func _box(size: Vector3, pos: Vector3, mat: Material, collide := false, rot_y := 0.0, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _box_mesh(size)
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = rot_y
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(mi)
	if collide:
		_collider(size, pos, rot_y)
	return mi


func _collider(size: Vector3, pos: Vector3, rot_y := 0.0) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	cs.rotation.y = rot_y
	_static.add_child(cs)


func _sphere(radius: float, pos: Vector3, mat: Material, squash := Vector3.ONE) -> MeshInstance3D:
	var key := "s%.2f" % radius
	if not _mesh_cache.has(key):
		var sm := SphereMesh.new()
		sm.radius = radius
		sm.height = radius * 2.0
		sm.radial_segments = 16
		sm.rings = 8
		_mesh_cache[key] = sm
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh_cache[key]
	mi.material_override = mat
	mi.position = pos
	mi.scale = squash
	_root.add_child(mi)
	return mi


func _plane(size: Vector2, pos: Vector3, mat: Material, rot_y := 0.0) -> MeshInstance3D:
	var pm := PlaneMesh.new()
	pm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(mi)
	return mi


## Thin glowing orange guide stripe painted on the deck between two points.
func _guide_line(a: Vector3, b: Vector3, width := 0.16) -> void:
	var d := b - a
	var length := d.length()
	_box(Vector3(length, 0.02, width), (a + b) * 0.5 + Vector3(0, 0.011, 0), _mats.guide, false, atan2(-d.z, d.x), false)


func _deck(center: Vector3, half: Vector2, pillars := true) -> void:
	_box(Vector3(half.x * 2.0, deck_thickness, half.y * 2.0), center + Vector3(0, -deck_thickness * 0.5, 0), _mats.floor)
	# Darker lip under the deck edge gives the platform visible thickness from above.
	_box(Vector3(half.x * 2.0 + 0.4, 0.45, half.y * 2.0 + 0.4), center + Vector3(0, -deck_thickness - 0.15, 0), _mats.beam)
	# Underside girders.
	var n := int(half.x * 2.0 / 4.0)
	for i in n + 1:
		var x := center.x - half.x + i * (half.x * 2.0 / n)
		_box(Vector3(0.45, 1.4, half.y * 2.0 - 0.6), Vector3(x, -deck_thickness - 1.0, center.z), _mats.beam, false, 0.0, false)
	if pillars:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var p := center + Vector3(sx * (half.x - 2.5), 0, sz * (half.y - 2.5))
				_box(Vector3(1.8, 90.0, 1.8), p + Vector3(0, -deck_thickness - 45.0, 0), _mats.pillar, false, 0.0, false)


func _build_main_platform() -> void:
	var hx := half_size.x
	var hz := half_size.y
	_deck(Vector3.ZERO, half_size)
	_walkable.append(Rect2(-hx, -hz, hx * 2.0, hz * 2.0))

	# Railings with gaps where the bridges join.
	var west: Dictionary = BRIDGES[0]
	var east: Dictionary = BRIDGES[1]
	var ww: float = west.width * 0.5
	var ew: float = east.width * 0.5
	_rail_run(Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3.BACK, true)
	_rail_run(Vector3(-hx, 0, hz), Vector3(hx, 0, hz), Vector3.FORWARD, true)
	_rail_run(Vector3(-hx, 0, -hz), Vector3(-hx, 0, west.z - ww), Vector3.RIGHT, true)
	_rail_run(Vector3(-hx, 0, west.z + ww), Vector3(-hx, 0, hz), Vector3.RIGHT, true)
	_rail_run(Vector3(hx, 0, -hz), Vector3(hx, 0, east.z - ew), Vector3.LEFT, true)
	_rail_run(Vector3(hx, 0, east.z + ew), Vector3(hx, 0, hz), Vector3.LEFT, true)

	# Orange guide lines (Coolant Pumping Station / Freight Lift concepts).
	_guide_line(Vector3(-hx + 1.0, 0, hz - 2.2), Vector3(hx - 1.0, 0, hz - 2.2))
	_guide_line(Vector3(-hx + 1.0, 0, -hz + 2.2), Vector3(7.0, 0, -hz + 2.2))
	_guide_line(Vector3(-hx, 0, west.z), Vector3(-6.0, 0, west.z))
	_guide_line(Vector3(-6.0, 0, west.z - 0.08), Vector3(-6.0, 0, hz - 2.2))
	_guide_line(Vector3(hx, 0, east.z), Vector3(11.5, 0, east.z))
	_guide_line(Vector3(11.5, 0, east.z + 0.08), Vector3(11.5, 0, hz - 2.2))

	# Hazard-stripe panels.
	_plane(Vector2(3.0, 3.0), Vector3(-12.0, 0.012, -7.6), _mats.hazard)
	_plane(Vector2(3.0, 3.0), Vector3(5.5, 0.012, 7.4), _mats.hazard)
	_plane(Vector2(2.4, 2.4), Vector3(-1.5, 0.012, -4.0), _mats.hazard, PI * 0.5)
	_plane(Vector2(2.4, 4.0), Vector3(13.5, 0.012, 8.3), _mats.hazard)


func _build_bridges() -> void:
	for i in BRIDGES.size():
		var b: Dictionary = BRIDGES[i]
		var side: float = b.side
		var z: float = b.z
		var hw: float = b.width * 0.5
		var length: float = b.length
		var x0 := side * half_size.x
		var x1 := side * (half_size.x + length)
		var mid := Vector3((x0 + x1) * 0.5, 0, z)

		# Grated catwalk deck with solid side girders.
		var deck := _box(Vector3(length, 0.08, b.width), mid + Vector3(0, -0.04, 0), _mats.grate)
		var grate_mat: ShaderMaterial = _mats.grate.duplicate()
		grate_mat.set_shader_parameter("frame_half_extents", Vector2(length * 0.5, hw))
		deck.material_override = grate_mat
		for s in [-1.0, 1.0]:
			_box(Vector3(length, 0.5, 0.18), mid + Vector3(0, -0.3, s * (hw + 0.05)), _mats.beam)
		_box(Vector3(length, 0.18, 0.4), mid + Vector3(0, -1.2, 0), _mats.beam, false, 0.0, false)
		_rail_run(Vector3(x0, 0, z - hw), Vector3(x1, 0, z - hw), Vector3.BACK, false, i == 0)
		_rail_run(Vector3(x0, 0, z + hw), Vector3(x1, 0, z + hw), Vector3.FORWARD, false, i == 1)

		# Side platform.
		var p: Vector2 = b.platform
		var pc := Vector3(x1 + side * p.x * 0.5, 0, z)
		_deck(pc, p * 0.5)
		var px0 := pc.x - p.x * 0.5
		var px1 := pc.x + p.x * 0.5
		var pz0 := pc.z - p.y * 0.5
		var pz1 := pc.z + p.y * 0.5
		_rail_run(Vector3(px0, 0, pz0), Vector3(px1, 0, pz0), Vector3.BACK, true)
		_rail_run(Vector3(px0, 0, pz1), Vector3(px1, 0, pz1), Vector3.FORWARD, true)
		var outer_x := px0 if side < 0 else px1
		var inner_x := px1 if side < 0 else px0
		var inward_outer := Vector3.RIGHT if side < 0 else Vector3.LEFT
		_rail_run(Vector3(outer_x, 0, pz0), Vector3(outer_x, 0, pz1), inward_outer, true)
		_rail_run(Vector3(inner_x, 0, pz0), Vector3(inner_x, 0, z - hw), -inward_outer, false, false)
		_rail_run(Vector3(inner_x, 0, z + hw), Vector3(inner_x, 0, pz1), -inward_outer, false, false)
		_plane(Vector2(4.0, 4.0), pc + Vector3(0, 0.012, 0), _mats.hazard)
		_guide_line(Vector3(inner_x, 0, z), Vector3(pc.x - side * 2.2, 0, z))
		_walkable.append(Rect2(minf(x0, x1), z - hw, length, b.width))
		_walkable.append(Rect2(px0, pz0, p.x, p.y))

		_bridge_nav.append({
			"z": z,
			"half_w": hw,
			"x_min": minf(x0, x1),
			"x_max": maxf(x0, x1),
			"a_in": Vector3(x0 - side * 1.2, 0, z),
			"b_in": Vector3(x1 + side * 1.2, 0, z),
		})


## A straight railing: posts, two rails, kick plate, one collision box, optional lamps.
func _rail_run(a: Vector3, b: Vector3, inward: Vector3, spawn_edge: bool, lamps := true) -> void:
	var d := b - a
	var length := d.length()
	if length < 0.05:
		return
	var dir := d / length
	var rot := atan2(-dir.z, dir.x)
	var mid := (a + b) * 0.5
	_box(Vector3(length, 0.08, 0.08), mid + Vector3(0, rail_height, 0), _mats.rail, false, rot)
	_box(Vector3(length, 0.05, 0.05), mid + Vector3(0, rail_height * 0.55, 0), _mats.rail, false, rot, false)
	_box(Vector3(length, 0.2, 0.05), mid + Vector3(0, 0.1, 0), _mats.rail_dark, false, rot, false)
	var posts := maxi(1, ceili(length / rail_post_spacing))
	for i in posts + 1:
		var p := a + dir * (length * i / posts)
		_box(Vector3(0.1, rail_height, 0.1), p + Vector3(0, rail_height * 0.5, 0), _mats.rail, false, rot, false)
	_collider(Vector3(length, rail_collision_height, 0.3), mid + Vector3(0, rail_collision_height * 0.5, 0), rot)

	if lamps and length >= lamp_spacing * 0.6:
		var count := maxi(1, roundi(length / lamp_spacing))
		for i in count:
			_lamp(a + dir * (length * (i + 0.5) / count) + inward * 0.22, inward)

	if spawn_edge:
		_spawn_edges.append({"a": a, "b": b, "inward": inward, "length": length})
		_spawn_edge_total += length


func _lamp(pos: Vector3, inward: Vector3) -> void:
	_box(Vector3(0.1, 1.6, 0.1), pos + Vector3(0, 0.8, 0), _mats.lamp_post, false, 0.0, false)
	_box(Vector3(0.2, 0.34, 0.2), pos + Vector3(0, 1.66, 0), _mats.lamp_head, false, 0.0, false)
	_box(Vector3(0.24, 0.05, 0.24), pos + Vector3(0, 1.85, 0), _mats.lamp_post, false, 0.0, false)
	var light := OmniLight3D.new()
	light.light_color = lamp_color
	light.light_energy = lamp_energy
	light.omni_range = lamp_range
	light.omni_attenuation = 1.3
	light.light_volumetric_fog_energy = 1.5
	light.shadow_enabled = lamp_shadows
	light.position = pos + inward * 0.35 + Vector3(0, 1.7, 0)
	_root.add_child(light)


func _build_crates() -> void:
	for c in crate_layout:
		var stack := clampi(int(c.w), 1, 3)
		var rot := deg_to_rad(c.z)
		var base := Vector3(c.x, 0, c.y)
		var size := Vector3(1.55, 1.2, 1.25)
		var h := 0.0
		for s in stack:
			var sz := size if s == 0 else size * Vector3(0.94, 0.95, 0.94)
			var center := base + Vector3(0, h + sz.y * 0.5, 0)
			_box(sz, center, _mats.crate, false, rot)
			# Dark reinforcing bands and an orange ID stripe (crate concepts).
			_box(Vector3(sz.x + 0.04, 0.12, sz.z + 0.04), center + Vector3(0, sz.y * 0.32, 0), _mats.crate_dark, false, rot, false)
			_box(Vector3(sz.x + 0.04, 0.12, sz.z + 0.04), center + Vector3(0, -sz.y * 0.32, 0), _mats.crate_dark, false, rot, false)
			_box(Vector3(sz.x * 0.82, 0.03, sz.z * 0.78), center + Vector3(0, sz.y * 0.5 + 0.01, 0), _mats.crate_dark, false, rot, false)
			var face := Vector3(0, 0, sz.z * 0.5 + 0.015).rotated(Vector3.UP, rot)
			_box(Vector3(sz.x * 0.45, 0.14, 0.03), center + face + Vector3(0, 0.05, 0), _mats.crate_orange, false, rot, false)
			h += sz.y
		_collider(Vector3(size.x, h + 0.1, size.z), base + Vector3(0, (h + 0.1) * 0.5, 0), rot)
		_blockers.append(Vector3(c.x, c.y, 1.15))


func _build_hive() -> void:
	var c := hive_center
	var rng := RandomNumberGenerator.new()
	rng.seed = 7331

	# Fleshy root mass hugging the corner.
	var masses := [
		[Vector3(0.0, 0.0, 0.0), 1.7], [Vector3(1.4, 0.0, -1.2), 1.3], [Vector3(-1.2, 0.0, -1.5), 1.1],
		[Vector3(1.6, 0.0, 0.9), 1.0], [Vector3(-0.6, 0.0, 1.1), 0.8],
	]
	for m in masses:
		_sphere(m[1], c + m[0], _mats.hive_flesh, Vector3(1.0, 0.45, 1.0))
	# Root tendrils creeping across the deck.
	for i in 9:
		var ang := rng.randf_range(PI * 0.35, PI * 1.25)
		var length := rng.randf_range(2.5, 5.0)
		var dir := Vector3(cos(ang), 0, sin(ang))
		_box(Vector3(length, 0.08, 0.14), c + dir * (length * 0.5 + 0.8) + Vector3(0, 0.04, 0), _mats.hive_root, false, -ang, false)
	# Glowing egg pods.
	for i in 16:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(0.4, 2.4)
		var size := rng.randf_range(0.22, 0.55)
		var pos := c + Vector3(cos(ang) * r, 0.35 + size * 0.5, sin(ang) * r * 0.85)
		_sphere(size, pos, _mats.hive_pod, Vector3(1.0, 1.3, 1.0))
	_sphere(0.6, c + Vector3(0.4, 0.8, -0.6), _mats.hive_pod, Vector3(1.0, 1.35, 1.0))

	var light := OmniLight3D.new()
	light.light_color = Color("8dff2e")
	light.light_energy = hive_light_energy
	light.omni_range = hive_light_range
	light.light_volumetric_fog_energy = 0.6
	light.position = c + Vector3(-1.0, 2.0, 1.0)
	_root.add_child(light)

	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.9
	cyl.height = 2.0
	cs.shape = cyl
	cs.position = c + Vector3(0, 1.0, 0)
	_static.add_child(cs)
	_blockers.append(Vector3(c.x, c.z, 2.2))

	# Spawn mouths fan out from the hive toward the arena.
	var toward := Vector3(-c.x, 0, -c.z).normalized()
	var base_ang := atan2(toward.z, toward.x)
	for i in 7:
		var a := base_ang + deg_to_rad(lerpf(-75.0, 75.0, i / 6.0))
		_hive_spawns.append(c + Vector3(cos(a), 0, sin(a)) * 3.2)


## Pump housings behind the north rail (Coolant Pumping Station concept).
func _build_background_machinery() -> void:
	var z := -half_size.y - 2.4
	for x in [-9.0, -3.0]:
		_box(Vector3(4.6, 4.2, 3.4), Vector3(x, 1.4, z - 0.6), _mats.machine)
		_box(Vector3(3.6, 0.18, 0.05), Vector3(x, 3.2, z + 1.13), _mats.teal_strip, false, 0.0, false)
		for k in 2:
			_box(Vector3(0.5, 0.14, 0.04), Vector3(x - 1.3 + k * 0.6, 2.4, z + 1.13), _mats.crate_orange, false, 0.0, false)
	_box(Vector3(14.0, 0.8, 1.2), Vector3(-6.0, -0.6, z + 0.3), _mats.beam)
	_box(Vector3(16.0, 0.35, 0.35), Vector3(-5.0, 2.8, z - 2.2), _mats.rail_dark)
	_box(Vector3(16.0, 0.35, 0.35), Vector3(-5.0, 2.2, z - 2.5), _mats.rail_dark)


func _build_void() -> void:
	# Giant columns disappearing into the fog, with teal window strips.
	var columns := [
		Vector4(-44, -24, 6, 10), Vector4(-26, -42, 4.5, 14), Vector4(8, -48, 7, 16), Vector4(36, -34, 5, 12),
		Vector4(54, -6, 6, 4), Vector4(-58, 10, 7, -4), Vector4(46, 20, 5, -10), Vector4(-36, 28, 5, -12),
	]
	for col in columns:
		var top: float = col.w
		var height := top + 150.0
		var pos := Vector3(col.x, top - height * 0.5, col.y)
		_box(Vector3(col.z, height, col.z), pos, _mats.pillar, false, 0.0, false)
		for k in 6:
			var y := top - 6.0 - k * 9.0
			_box(Vector3(col.z * 0.35, 0.5, 0.06), Vector3(col.x, y, col.y + col.z * 0.5 + 0.04), _mats.teal_strip, false, 0.0, false)
			_box(Vector3(0.06, 0.5, col.z * 0.35), Vector3(col.x + col.z * 0.5 * signf(-col.x) + 0.04 * signf(-col.x), y - 3.0, col.y), _mats.teal_strip, false, 0.0, false)
		# Little caged maintenance platforms hanging off the columns.
		var cage := Vector3(col.x + signf(-col.x) * (col.z * 0.5 + 1.5), top - 14.0, col.y)
		var cage_deck := _box(Vector3(3.0, 0.1, 3.0), cage, _mats.grate.duplicate(), false, 0.0, false)
		(cage_deck.material_override as ShaderMaterial).set_shader_parameter("frame_half_extents", Vector2(1.5, 1.5))
		_box(Vector3(3.0, 0.06, 0.06), cage + Vector3(0, 1.0, 1.47), _mats.rail_dark, false, 0.0, false)
		_box(Vector3(3.0, 0.06, 0.06), cage + Vector3(0, 1.0, -1.47), _mats.rail_dark, false, 0.0, false)
		_box(Vector3(0.4, 0.12, 0.05), cage + Vector3(0, 1.4, 1.5), _mats.teal_strip, false, 0.0, false)

	# Thick volumetric fog filling the void below the deck.
	var fog := FogVolume.new()
	fog.name = "VoidFog"
	fog.size = Vector3(500.0, 160.0, 500.0)
	fog.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	fog.position = Vector3(0, void_fog_top - 80.0, 0)
	var fm := FogMaterial.new()
	fm.density = void_fog_density
	fm.albedo = void_fog_albedo
	fm.emission = void_fog_emission
	fm.edge_fade = 0.02
	fog.material = fm
	_root.add_child(fog)
