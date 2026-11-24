@tool
class_name LevelKit
extends RefCounted
## Greybox building blocks for level rooms: decks, railings, lamps, crates, walls,
## machinery, bridges and void dressing. Visuals go under `root`, all collision
## into one StaticBody3D (layer 1 "world"). Gameplay data gathered while building
## (void edges bugs can leap from, spawn blockers) is read back by the Level.
## Rects are XZ: Rect2(x, z, width, depth). -Z is "north" (top of the screen).

var root: Node3D
var static_body: StaticBody3D
var mats := {}
var _mesh_cache := {}

var _smoke_quad: QuadMesh
var _smoke_pm: ParticleProcessMaterial
var spawn_edges: Array[Dictionary] = []  # {a, b, inward, length, from_shaft}
var blockers: Array[Vector3] = []  # x, z, radius
## Repeated static parts (rail posts, trusses, pipes...) are batched into one
## MultiMesh per mesh+material (see batch / flush_batches): far fewer nodes.
var _batches := {}
## Top rail material (null = same as the posts). Themes use red, like the mockups.
var rail_top_mat: Material
## Paint yellow edge lines just inside room railings.
var edge_lines := true

# Tunables (copied from the Level's exports before building).
var deck_thickness := 1.0
var rail_height := 1.05
var rail_post_spacing := 1.8
var rail_collision_height := 1.3
var lamp_spacing := 8.0
var lamp_energy := 6.0
var lamp_range := 9.0
var lamp_emission := 6.0
var lamp_fog_energy := 1.5
var pillar_strip_energy := 3.5


func _init(parent: Node3D) -> void:
	root = Node3D.new()
	root.name = "Generated"
	parent.add_child(root)
	static_body = StaticBody3D.new()
	static_body.name = "Collision"
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	root.add_child(static_body)


func make_materials(hive_center: Vector3, hive_radius: float, tile_size: float) -> void:
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = preload("res://scripts/shaders/floor.gdshader")
	floor_mat.set_shader_parameter("tile_size", tile_size)
	floor_mat.set_shader_parameter("hive_center", hive_center)
	floor_mat.set_shader_parameter("hive_radius", hive_radius)
	mats.floor = floor_mat
	var grate := ShaderMaterial.new()
	grate.shader = preload("res://scripts/shaders/grate.gdshader")
	mats.grate = grate
	var hazard := ShaderMaterial.new()
	hazard.shader = preload("res://scripts/shaders/hazard.gdshader")
	mats.hazard = hazard

	mats.beam = std(Color("181c20"), 0.6, 0.6)
	mats.pillar = std(Color("1a2023"), 0.4, 0.7)
	mats.rail = std(Color("6b737a"), 0.8, 0.35)
	mats.rail_red = std(Color("7a2a26"), 0.6, 0.45)
	mats.rail_dark = std(Color("3a4047"), 0.7, 0.5)
	mats.guide = std(Color("e8731e"), 0.1, 0.5, Color("e8731e"), 0.5)
	mats.guide_white = std(Color("8a9197"), 0.1, 0.6)
	mats.lamp_post = std(Color("2c3136"), 0.7, 0.45)
	mats.crate = std(Color("9aa2a8"), 0.25, 0.55)
	mats.crate_dark = std(Color("40474e"), 0.5, 0.5)
	mats.crate_orange = std(Color("d9662a"), 0.1, 0.6)
	mats.machine = std(Color("8a9297"), 0.35, 0.5)
	mats.machine_dark = std(Color("2a3036"), 0.5, 0.5)
	mats.bulkhead = std(Color("b9bfc4"), 0.2, 0.55)
	mats.teal_strip = std(Color("0a1514"), 0.0, 0.5, Color("7ff5e8"), pillar_strip_energy)
	mats.cobalt_strip = std(Color("0a0f18"), 0.0, 0.5, Color("6fa8ff"), 4.0)
	mats.red_light = std(Color("200606"), 0.0, 0.5, Color("ff2a2a"), 5.0)
	mats.amber_strip = std(Color("201a10"), 0.0, 0.5, Color("ffae45"), 4.0)
	mats.paint_yellow = std(Color("b8952a"), 0.0, 0.75)
	mats.rail_light = std(Color("1a1d20"), 0.0, 0.5, Color("e9f2ff"), 3.0)
	mats.pipe = std(Color("5d646b"), 0.7, 0.4)
	mats.pipe_dark = std(Color("3b4147"), 0.6, 0.5)
	mats.truss = std(Color("1c2226"), 0.6, 0.55)
	mats.abyss_glow = std(Color(0.0, 0.05, 0.06), 0.0, 0.4, Color("2fd8e8"), 1.6)


func std(albedo: Color, metallic: float, roughness: float, emission := Color.BLACK, emission_energy := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emission_energy
	return m


## Emissive lamp-head material per colour (cached).
func lamp_mat(color: Color) -> StandardMaterial3D:
	var key := "lamp_%s" % color.to_html()
	if not mats.has(key):
		mats[key] = std(Color("201a10"), 0.0, 0.5, color, lamp_emission)
	return mats[key]


# --------------------------------------------------------------------------
# Primitives
# --------------------------------------------------------------------------

func box(size: Vector3, pos: Vector3, mat: Material, collide := false, rot_y := 0.0, shadows := true) -> MeshInstance3D:
	var key := "b%s" % size
	if not _mesh_cache.has(key):
		var bm := BoxMesh.new()
		bm.size = size
		_mesh_cache[key] = bm
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh_cache[key]
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = rot_y
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	if collide:
		collider(size, pos, rot_y)
	return mi


## Queue a box for batching (one MultiMesh per material+shadow flag).
func batch_box(size: Vector3, pos: Vector3, mat: Material, basis := Basis(), shadows := true) -> void:
	_batch("box", Transform3D(basis.scaled_local(size), pos), mat, shadows)


## Queue a horizontal pipe from a to b (radius r) for batching.
func batch_pipe(a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var d := b - a
	var length := d.length()
	if length < 0.05:
		return
	var y := d / length
	var x := y.cross(Vector3.UP)
	if x.length_squared() < 0.001:
		x = Vector3.RIGHT
	x = x.normalized()
	var z := x.cross(y)
	var basis := Basis(x * r * 2.0, y * length, z * r * 2.0)
	_batch("pipe", Transform3D(basis, (a + b) * 0.5), mat, true)


func _batch(kind: String, xf: Transform3D, mat: Material, shadows: bool) -> void:
	var key := "%s|%d|%s" % [kind, mat.get_instance_id(), shadows]
	if not _batches.has(key):
		_batches[key] = {"kind": kind, "mat": mat, "shadows": shadows, "xforms": []}
	_batches[key].xforms.append(xf)


## Build the MultiMeshes. Call once after building.
func flush_batches() -> void:
	var unit_box := BoxMesh.new()
	var unit_pipe := CylinderMesh.new()
	unit_pipe.top_radius = 0.5
	unit_pipe.bottom_radius = 0.5
	unit_pipe.height = 1.0
	unit_pipe.radial_segments = 8
	unit_pipe.rings = 1
	for key in _batches:
		var b: Dictionary = _batches[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = unit_box if b.kind == "box" else unit_pipe
		mm.instance_count = b.xforms.size()
		for i in b.xforms.size():
			mm.set_instance_transform(i, b.xforms[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = b.mat
		if not b.shadows:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mmi)
	_batches.clear()


func collider(size: Vector3, pos: Vector3, rot_y := 0.0) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	cs.rotation.y = rot_y
	static_body.add_child(cs)


func sphere(radius: float, pos: Vector3, mat: Material, squash := Vector3.ONE) -> MeshInstance3D:
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
	root.add_child(mi)
	return mi


func plane(size: Vector2, pos: Vector3, mat: Material, rot_y := 0.0) -> MeshInstance3D:
	var pm := PlaneMesh.new()
	pm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return mi


func torus(inner: float, outer: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var tm := TorusMesh.new()
	tm.inner_radius = inner
	tm.outer_radius = outer
	tm.rings = 48
	tm.ring_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return mi


func omni(pos: Vector3, color: Color, energy: float, range_m: float, fog_energy := 1.0) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.omni_attenuation = 1.3
	light.light_volumetric_fog_energy = fog_energy
	light.position = pos
	# Lamps far from the camera fade out (big generated floors have hundreds).
	light.distance_fade_enabled = true
	light.distance_fade_begin = 48.0
	light.distance_fade_length = 10.0
	root.add_child(light)
	return light


func add_blocker(x: float, z: float, radius: float) -> void:
	blockers.append(Vector3(x, z, radius))


# --------------------------------------------------------------------------
# Structures
# --------------------------------------------------------------------------

## Floor slab for an XZ rect, with a darker lip, underside girders and support pillars.
func deck(r: Rect2, floor_mat: Material = null, pillars := true) -> void:
	var c := Vector3(r.get_center().x, 0.0, r.get_center().y)
	box(Vector3(r.size.x, deck_thickness, r.size.y), c + Vector3(0, -deck_thickness * 0.5, 0), floor_mat if floor_mat else mats.floor)
	box(Vector3(r.size.x + 0.4, 0.45, r.size.y + 0.4), c + Vector3(0, -deck_thickness - 0.15, 0), mats.beam)
	var n := maxi(1, int(r.size.x / 4.0))
	for i in n + 1:
		var x := r.position.x + i * (r.size.x / n)
		batch_box(Vector3(0.45, 1.4, maxf(r.size.y - 0.6, 0.5)), Vector3(x, -deck_thickness - 1.0, c.z), mats.beam, Basis(), false)
	# Service pipes running along the slab's sides.
	var y1 := -deck_thickness * 0.45
	var y2 := -deck_thickness * 0.8
	for side in [[Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y), Vector3(0, 0, -0.32)],
			[Vector3(r.position.x, 0, r.end.y), Vector3(r.end.x, 0, r.end.y), Vector3(0, 0, 0.32)],
			[Vector3(r.position.x, 0, r.position.y), Vector3(r.position.x, 0, r.end.y), Vector3(-0.32, 0, 0)],
			[Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y), Vector3(0.32, 0, 0)]]:
		var a: Vector3 = side[0]
		var b: Vector3 = side[1]
		var off: Vector3 = side[2]
		batch_pipe(a + off + Vector3(0, y1, 0), b + off + Vector3(0, y1, 0), 0.11, mats.pipe)
		batch_pipe(a + off * 1.5 + Vector3(0, y2, 0), b + off * 1.5 + Vector3(0, y2, 0), 0.08, mats.pipe_dark)
	if pillars and r.size.x > 6.0 and r.size.y > 6.0:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var p := c + Vector3(sx * (r.size.x * 0.5 - 2.0), 0, sz * (r.size.y * 0.5 - 2.0))
				truss(p, 1.6, -deck_thickness - 0.2, 30.0)


## Floor material with a different base tint (cached), for room purposes.
func floor_variant(tint: Color) -> ShaderMaterial:
	var key := "floor_%s" % tint.to_html()
	if not mats.has(key):
		var m: ShaderMaterial = mats.floor.duplicate()
		m.set_shader_parameter("base_color", tint)
		mats[key] = m
	return mats[key]


## Painted floor guide line loop around a rect with cut corners (mockups).
func guide_loop(r: Rect2, chamfer: float, width := 0.16, mat: Material = null) -> void:
	var m: Material = mat if mat else mats.guide_white
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	var pts := [Vector3(x0 + chamfer, 0, z0), Vector3(x1 - chamfer, 0, z0), Vector3(x1, 0, z0 + chamfer), Vector3(x1, 0, z1 - chamfer),
		Vector3(x1 - chamfer, 0, z1), Vector3(x0 + chamfer, 0, z1), Vector3(x0, 0, z1 - chamfer), Vector3(x0, 0, z0 + chamfer)]
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		var d := b - a
		batch_box(Vector3(d.length() + width * 0.5, 0.02, width), (a + b) * 0.5 + Vector3(0, 0.012, 0), m, Basis(Vector3.UP, atan2(-d.z, d.x)), false)


## Steel lattice column dropping into the void: four posts with X bracing.
func truss(top: Vector3, width: float, y_top: float, depth: float) -> void:
	var h := width * 0.5
	var corners := [Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h)]
	for cpos in corners:
		batch_box(Vector3(0.2, depth, 0.2), top + cpos + Vector3(0, y_top - depth * 0.5, 0), mats.truss, Basis(), false)
	var step := 3.2
	var levels := int(depth / step)
	var diag := sqrt(width * width + step * step)
	var ang := atan2(step, width)
	for lv in levels:
		var y := y_top - (lv + 0.5) * step
		for f in 4:
			var a: Vector3 = corners[f]
			var b: Vector3 = corners[(f + 1) % 4]
			var mid := top + (a + b) * 0.5 + Vector3(0, y, 0)
			var along := (b - a).normalized()
			var face := Basis(Vector3.UP, atan2(-along.z, along.x))
			for s in [-1.0, 1.0]:
				batch_box(Vector3(diag, 0.12, 0.12), mid, mats.truss, face * Basis(Vector3.BACK, s * ang), false)
		batch_box(Vector3(width, 0.14, 0.14), top + Vector3(0, y - step * 0.5, -h), mats.truss, Basis(), false)


## Narrow grated catwalk over the void (rect is the walkable area).
func bridge(r: Rect2, along_x: bool, solid := false) -> void:
	var c := Vector3(r.get_center().x, 0.0, r.get_center().y)
	var length := r.size.x if along_x else r.size.y
	var width := r.size.y if along_x else r.size.x
	var size := Vector3(r.size.x, 0.08, r.size.y)
	if solid:
		box(Vector3(r.size.x, deck_thickness, r.size.y), c + Vector3(0, -deck_thickness * 0.5, 0), mats.floor)
	else:
		var deck_mi := box(size, c + Vector3(0, -0.04, 0), mats.grate)
		var g: ShaderMaterial = mats.grate.duplicate()
		g.set_shader_parameter("frame_half_extents", Vector2(r.size.x * 0.5, r.size.y * 0.5))
		deck_mi.material_override = g
	for s in [-1.0, 1.0]:
		var off := Vector3(0, -0.3, s * (width * 0.5 + 0.05)) if along_x else Vector3(s * (width * 0.5 + 0.05), -0.3, 0)
		var gs := Vector3(length, 0.5, 0.18) if along_x else Vector3(0.18, 0.5, length)
		box(gs, c + off, mats.beam)
	box(Vector3(length, 0.18, 0.4) if along_x else Vector3(0.4, 0.18, length), c + Vector3(0, -1.2, 0), mats.beam, false, 0.0, false)


## Straight railing: posts, rails, kick plate, collision, optional lamps and a
## void edge that bugs can leap over.
func rail_run(a: Vector3, b: Vector3, inward: Vector3, lamp_color := Color("ffae45"), lamps := true,
		spawn_edge := false, from_shaft := false, rail_mat: Material = null) -> void:
	var d := b - a
	var length := d.length()
	if length < 0.3:
		return
	var dir := d / length
	var rot := atan2(-dir.z, dir.x)
	var mid := (a + b) * 0.5
	var rm: Material = rail_mat if rail_mat else mats.rail
	var top_m: Material = rail_mat if rail_mat else (rail_top_mat if rail_top_mat else rm)
	var rb := Basis(Vector3.UP, rot)
	batch_box(Vector3(length, 0.09, 0.09), mid + Vector3(0, rail_height, 0), top_m, rb)
	batch_box(Vector3(length, 0.05, 0.05), mid + Vector3(0, rail_height * 0.55, 0), rm, rb, false)
	batch_box(Vector3(length, 0.2, 0.05), mid + Vector3(0, 0.1, 0), mats.rail_dark, rb, false)
	var posts := maxi(1, ceili(length / rail_post_spacing))
	for i in posts + 1:
		var p := a + dir * (length * i / posts)
		batch_box(Vector3(0.1, rail_height, 0.1), p + Vector3(0, rail_height * 0.5, 0), rm, rb, false)
		if i % 3 == 1:
			batch_box(Vector3(0.05, 0.22, 0.12), p + Vector3(0, rail_height * 0.62, 0) + inward * 0.06, mats.rail_light, rb, false)
	collider(Vector3(length, rail_collision_height, 0.3), mid + Vector3(0, rail_collision_height * 0.5, 0), rot)
	if lamps and length >= lamp_spacing * 0.6:
		var count := maxi(1, roundi(length / lamp_spacing))
		for i in count:
			lamp(a + dir * (length * (i + 0.5) / count) + inward * 0.22, inward, lamp_color)
	if spawn_edge:
		spawn_edges.append({"a": a, "b": b, "inward": inward, "length": length, "from_shaft": from_shaft})


## Tall lamp post at the railing with an arm leaning over the deck and a light
## bar head: lights a pool of deck (and casts long shadows on HIGH).
func lamp(pos: Vector3, inward: Vector3, color: Color) -> void:
	var h := 3.1
	var rb := Basis(Vector3.UP, atan2(-inward.z, inward.x))
	batch_box(Vector3(0.14, h, 0.14), pos + Vector3(0, h * 0.5, 0), mats.lamp_post)
	batch_box(Vector3(0.24, 0.3, 0.24), pos + Vector3(0, 0.15, 0), mats.lamp_post, Basis(), false)
	batch_box(Vector3(0.85, 0.1, 0.1), pos + inward * 0.38 + Vector3(0, h - 0.05, 0), mats.lamp_post, rb)
	batch_box(Vector3(0.55, 0.1, 0.24), pos + inward * 0.78 + Vector3(0, h - 0.13, 0), mats.lamp_post, rb)
	batch_box(Vector3(0.48, 0.03, 0.18), pos + inward * 0.78 + Vector3(0, h - 0.19, 0), lamp_mat(color), rb, false)
	var l := omni(pos + inward * 0.78 + Vector3(0, h - 0.45, 0), color, lamp_energy, lamp_range, lamp_fog_energy)
	l.set_meta("lamp", true)


## Railings around a rect, leaving gaps for `openings` ({side, lo, hi}).
func rails_around(r: Rect2, openings: Array, lamp_color: Color, spawn_edges_on := true, rail_mat: Material = null) -> void:
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	_side_rails(&"n", Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3.BACK, openings, lamp_color, spawn_edges_on, rail_mat)
	_side_rails(&"s", Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3.FORWARD, openings, lamp_color, spawn_edges_on, rail_mat)
	_side_rails(&"w", Vector3(x0, 0, z0), Vector3(x0, 0, z1), Vector3.RIGHT, openings, lamp_color, spawn_edges_on, rail_mat)
	_side_rails(&"e", Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3.LEFT, openings, lamp_color, spawn_edges_on, rail_mat)


func _side_rails(side: StringName, a: Vector3, b: Vector3, inward: Vector3, openings: Array, lamp_color: Color, spawn_on: bool, rail_mat: Material) -> void:
	var along_x := absf(b.x - a.x) > absf(b.z - a.z)
	var lo := a.x if along_x else a.z
	var hi := b.x if along_x else b.z
	var gaps: Array = []
	for o in openings:
		if o.side == side:
			gaps.append(Vector2(o.lo, o.hi))
	gaps.sort_custom(func(p, q): return p.x < q.x)
	var cursor := lo
	for g in gaps:
		if g.x > cursor + 0.05:
			_rail_segment(along_x, a, cursor, g.x, inward, lamp_color, spawn_on, rail_mat)
		cursor = maxf(cursor, g.y)
	if hi > cursor + 0.05:
		_rail_segment(along_x, a, cursor, hi, inward, lamp_color, spawn_on, rail_mat)


func _rail_segment(along_x: bool, origin: Vector3, s0: float, s1: float, inward: Vector3, lamp_color: Color, spawn_on: bool, rail_mat: Material) -> void:
	var p0 := Vector3(s0, 0, origin.z) if along_x else Vector3(origin.x, 0, s0)
	var p1 := Vector3(s1, 0, origin.z) if along_x else Vector3(origin.x, 0, s1)
	rail_run(p0, p1, inward, lamp_color, true, spawn_on, false, rail_mat)
	# Worn yellow safety line painted just inside the railing.
	if edge_lines and s1 - s0 > 1.2:
		var d := p1 - p0
		var lm := (p0 + p1) * 0.5 + inward * 0.55 + Vector3(0, 0.012, 0)
		batch_box(Vector3(d.length() - 0.6, 0.02, 0.14), lm, mats.paint_yellow, Basis(Vector3.UP, atan2(-d.z, d.x)), false)


func guide_line(a: Vector3, b: Vector3, width := 0.16, mat: Material = null) -> void:
	var d := b - a
	box(Vector3(d.length(), 0.02, width), (a + b) * 0.5 + Vector3(0, 0.011, 0), mat if mat else mats.guide, false, atan2(-d.z, d.x), false)


func hazard_panel(size: Vector2, pos: Vector3, rot_y := 0.0) -> void:
	plane(size, Vector3(pos.x, 0.012, pos.z), mats.hazard, rot_y)


func crate(x: float, z: float, rot_deg: float, stack: int) -> void:
	stack = clampi(stack, 1, 3)
	var rot := deg_to_rad(rot_deg)
	var base := Vector3(x, 0, z)
	var size := Vector3(1.55, 1.2, 1.25)
	var h := 0.0
	for s in stack:
		var sz := size if s == 0 else size * Vector3(0.94, 0.95, 0.94)
		var center := base + Vector3(0, h + sz.y * 0.5, 0)
		box(sz, center, mats.crate, false, rot)
		box(Vector3(sz.x + 0.04, 0.12, sz.z + 0.04), center + Vector3(0, sz.y * 0.32, 0), mats.crate_dark, false, rot, false)
		box(Vector3(sz.x + 0.04, 0.12, sz.z + 0.04), center + Vector3(0, -sz.y * 0.32, 0), mats.crate_dark, false, rot, false)
		box(Vector3(sz.x * 0.82, 0.03, sz.z * 0.78), center + Vector3(0, sz.y * 0.5 + 0.01, 0), mats.crate_dark, false, rot, false)
		var face := Vector3(0, 0, sz.z * 0.5 + 0.015).rotated(Vector3.UP, rot)
		box(Vector3(sz.x * 0.45, 0.14, 0.03), center + face + Vector3(0, 0.05, 0), mats.crate_orange, false, rot, false)
		h += sz.y
	collider(Vector3(size.x, h + 0.1, size.z), base + Vector3(0, (h + 0.1) * 0.5, 0), rot)
	add_blocker(x, z, 1.15)


## A dead creature for feeding bugs to crowd round: a split carapace, curled
## legs and a pool of glowing ichor. Visual only.
func carcass(pos: Vector3, rot_y: float, size := 1.0) -> void:
	if not mats.has("carcass"):
		mats.carcass = std(Color("2b2a22"), 0.2, 0.6)
		mats.carcass_flesh = std(Color("3d1f1a"), 0.0, 0.8)
		mats.ichor = std(Color(0.05, 0.08, 0.02), 0.0, 0.15, Color("6fd12a"), 0.35)
	var basis := Basis(Vector3.UP, rot_y)
	# Irregular puddle: a few overlapping flat blobs.
	for k in 4:
		var blob := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var r := randf_range(0.45, 0.85) * size
		cm.top_radius = r
		cm.bottom_radius = r
		cm.height = 0.012
		cm.radial_segments = 14
		blob.mesh = cm
		blob.material_override = mats.ichor
		blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		blob.position = pos + basis * Vector3(randf_range(-0.7, 0.7), 0.012 + k * 0.001, randf_range(-0.5, 0.5)) * size
		blob.scale = Vector3(randf_range(1.0, 1.6), 1.0, randf_range(0.7, 1.0))
		blob.rotation.y = randf() * TAU
		root.add_child(blob)
	var body := sphere(0.55 * size, pos + Vector3(0, 0.2, 0) * size, mats.carcass, Vector3(1.5, 0.55, 0.9))
	body.rotation.y = rot_y
	var torn := sphere(0.32 * size, pos + basis * Vector3(0.35, 0.3, 0.1) * size, mats.carcass_flesh, Vector3(1.0, 0.6, 0.8))
	torn.rotation.y = rot_y
	for i in 6:
		var side := -1.0 if i < 3 else 1.0
		var k := float(i % 3) - 1.0
		var root := pos + basis * Vector3(k * 0.45, 0.15, side * 0.35) * size
		var tip := pos + basis * Vector3(k * 0.7 + randf_range(-0.2, 0.2), 0.05, side * 1.05) * size
		var d := tip - root
		var leg := box(Vector3(d.length(), 0.07, 0.07) * Vector3(1, size, size), (root + tip) * 0.5, mats.carcass, false, atan2(-d.z, d.x), false)
		leg.rotation.z = 0.3 * side


## Solid bulkhead wall between two points (with collision), e.g. the pressure lock.
func wall(a: Vector3, b: Vector3, height := 3.2, thickness := 0.6) -> void:
	var d := b - a
	var length := d.length()
	if length < 0.1:
		return
	var rot := atan2(-d.z, d.x)
	var mid := (a + b) * 0.5
	box(Vector3(length, height, thickness), mid + Vector3(0, height * 0.5, 0), mats.bulkhead, true, rot)
	box(Vector3(length, 0.25, thickness + 0.08), mid + Vector3(0, height, 0), mats.machine_dark, false, rot)
	box(Vector3(length, 0.12, thickness + 0.04), mid + Vector3(0, 0.9, 0), mats.machine_dark, false, rot, false)
	var n := int(length)
	for i in n:
		var p := a + d.normalized() * (i + 0.5)
		add_blocker(p.x, p.z, 0.7)


## Solid structure between the rooms of an interior section: a dark slab whose
## top sits at `height`, running down into the void like a building's mass,
## with roof vents and a lit trim so it doesn't read as a black hole.
func structure_fill(r: Rect2, height: float, mat: Material = null, trim: Material = null) -> void:
	var c := Vector3(r.get_center().x, 0.0, r.get_center().y)
	var depth := 14.0
	box(Vector3(r.size.x, depth, r.size.y), c + Vector3(0, height - depth * 0.5, 0), mat if mat else mats.machine_dark, false, 0.0, false)
	if trim:
		# A lit seam round the slab's top edge (starship hull plating).
		for side in [[Vector3(0, 0, -r.size.y * 0.5), Vector3(r.size.x, 0.06, 0.08)], [Vector3(0, 0, r.size.y * 0.5), Vector3(r.size.x, 0.06, 0.08)],
				[Vector3(-r.size.x * 0.5, 0, 0), Vector3(0.08, 0.06, r.size.y)], [Vector3(r.size.x * 0.5, 0, 0), Vector3(0.08, 0.06, r.size.y)]]:
			batch_box(side[1], c + side[0] + Vector3(0, height - 0.35, 0), trim, Basis(), false)
	batch_box(Vector3(r.size.x + 0.06, 0.08, r.size.y + 0.06), c + Vector3(0, height + 0.04, 0), mats.beam)
	# Roof clutter on the bigger slabs: vents and ducts.
	if r.size.x > 3.0 and r.size.y > 3.0:
		var n := mini(int(r.get_area() / 30.0) + 1, 4)
		for i in n:
			var t := (i + 0.5) / n
			var p := Vector3(lerpf(r.position.x + 1.2, r.end.x - 1.2, t), height, lerpf(r.end.y - 1.2, r.position.y + 1.2, t))
			batch_box(Vector3(1.1, 0.35, 0.9), p + Vector3(0, 0.17, 0), mats.machine, Basis(), false)
	elif r.size.x > 6.0 or r.size.y > 6.0:
		var along_x := r.size.x > r.size.y
		var a := Vector3(r.position.x + 0.5, height + 0.18, c.z) if along_x else Vector3(c.x, height + 0.18, r.position.y + 0.5)
		var b := Vector3(r.end.x - 0.5, height + 0.18, c.z) if along_x else Vector3(c.x, height + 0.18, r.end.y - 0.5)
		batch_pipe(a, b, 0.16, mats.pipe)


## Row of switchgear cabinets filling a rect (Cobalt Switchgear Gallery concept).
func machinery_block(r: Rect2, height := 2.4) -> void:
	var c := Vector3(r.get_center().x, 0.0, r.get_center().y)
	box(Vector3(r.size.x, height, r.size.y), c + Vector3(0, height * 0.5, 0), mats.machine, true)
	box(Vector3(r.size.x + 0.1, 0.2, r.size.y + 0.1), c + Vector3(0, height + 0.1, 0), mats.machine_dark)
	var cabinets := int(r.size.x / 1.6)
	for i in cabinets:
		var x := r.position.x + (i + 0.5) * (r.size.x / cabinets)
		for s in [-1.0, 1.0]:
			var z: float = c.z + s * (r.size.y * 0.5 + 0.02)
			box(Vector3(0.05, height * 0.85, 0.04), Vector3(x + 0.78, height * 0.45, z), mats.machine_dark, false, 0.0, false)
			if i % 2 == 0:
				box(Vector3(0.35, 0.08, 0.04), Vector3(x, height * 0.72, z), mats.cobalt_strip, false, 0.0, false)
	# Roof-top vents and cable bundles.
	for i in 3:
		box(Vector3(1.6, 0.35, r.size.y * 0.5), c + Vector3((i - 1) * r.size.x * 0.3, height + 0.35, 0), mats.machine_dark)
	var steps := int(r.size.x / 2.0)
	for i in steps + 1:
		var x := r.position.x + i * (r.size.x / steps)
		for s in [-1.0, 1.0]:
			add_blocker(x, c.z + s * r.size.y * 0.25, r.size.y * 0.5 + 0.4)


## Giant columns, hanging cages and the volumetric fog volume filling the void.
func void_dressing(bounds: Rect2, fog_top: float, fog_density: float, fog_albedo: Color, fog_emission: Color) -> void:
	var c := bounds.get_center()
	var margin := 16.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var spots: Array[Vector3] = []
	for i in 14:
		var ang := TAU * i / 14.0 + rng.randf_range(-0.15, 0.15)
		var rx := bounds.size.x * 0.5 + margin + rng.randf_range(4.0, 22.0)
		var rz := bounds.size.y * 0.5 + margin + rng.randf_range(4.0, 22.0)
		var top := rng.randf_range(-8.0, 12.0) if sin(ang) < 0.0 else rng.randf_range(-14.0, -4.0)
		spots.append(Vector3(c.x + cos(ang) * rx, top, c.y + sin(ang) * rz))
	for s in spots:
		var w := rng.randf_range(4.0, 7.5)
		var height := s.y + 150.0
		box(Vector3(w, height, w), Vector3(s.x, s.y - height * 0.5, s.z), mats.pillar, false, 0.0, false)
		for k in 5:
			var y := s.y - 6.0 - k * 9.0
			box(Vector3(w * 0.35, 0.5, 0.06), Vector3(s.x, y, s.z + w * 0.5 + 0.04), mats.teal_strip, false, 0.0, false)
		var cage := Vector3(s.x + signf(c.x - s.x) * (w * 0.5 + 1.5), s.y - 14.0, s.z)
		var cage_deck := box(Vector3(3.0, 0.1, 3.0), cage, mats.grate.duplicate(), false, 0.0, false)
		(cage_deck.material_override as ShaderMaterial).set_shader_parameter("frame_half_extents", Vector2(1.5, 1.5))
		box(Vector3(3.0, 0.06, 0.06), cage + Vector3(0, 1.0, 1.47), mats.rail_dark, false, 0.0, false)
		box(Vector3(0.4, 0.12, 0.05), cage + Vector3(0, 1.4, 1.5), mats.teal_strip, false, 0.0, false)

	# Glow from the depths: cyan pools and lit machinery far below the decks
	# (emissive only, no lights, so it costs next to nothing).
	var cells_x := int(ceil((bounds.size.x + 60.0) / 30.0))
	var cells_z := int(ceil((bounds.size.y + 60.0) / 30.0))
	for ix in cells_x:
		for iz in cells_z:
			if rng.randf() > 0.4:
				continue
			var gp := Vector3(bounds.position.x - 30.0 + (ix + 0.5) * 30.0 + rng.randf_range(-8.0, 8.0),
				rng.randf_range(-44.0, -32.0), bounds.position.y - 30.0 + (iz + 0.5) * 30.0 + rng.randf_range(-8.0, 8.0))
			batch_box(Vector3(rng.randf_range(10.0, 26.0), 0.6, rng.randf_range(8.0, 22.0)), gp, mats.abyss_glow, Basis(Vector3.UP, rng.randf_range(0.0, 0.4)), false)
			if rng.randf() < 0.5:
				truss(gp + Vector3(rng.randf_range(-4.0, 4.0), 0, rng.randf_range(-4.0, 4.0)), 2.2, 30.0, 30.0)

	# Fog volumes need Forward+; the Compatibility renderer can't draw them.
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return
	var fog := FogVolume.new()
	fog.name = "VoidFog"
	fog.size = Vector3(bounds.size.x + 400.0, 160.0, bounds.size.y + 400.0)
	fog.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	fog.position = Vector3(c.x, fog_top - 80.0, c.y)
	var fm := FogMaterial.new()
	fm.density = fog_density
	fm.albedo = fog_albedo
	fm.emission = fog_emission
	fm.edge_fade = 0.02
	fog.material = fm
	root.add_child(fog)


# ==========================================================================
# Destinations: what lies under and around the floors
# ==========================================================================

## Open space under a derelict hauler: the ship's lower hull and engine
## glow just below the decks, a gas giant far beneath, stars and nebula.
func space_dressing(bounds: Rect2) -> void:
	var c := bounds.get_center()
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	mats.hull = std(Color("2e333b"), 0.55, 0.45)
	mats.hull_dark = std(Color("12151a"), 0.6, 0.5)
	mats.hull_red = std(Color("200404"), 0.0, 0.5, Color("ff3a2e"), 5.0)
	mats.engine = std(Color("0a1a20"), 0.0, 0.4, Color("5ff2e8"), 6.0)
	# Stars far below, wide enough to fill every gap the camera can see through.
	var stars := ShaderMaterial.new()
	stars.shader = preload("res://scripts/shaders/starfield.gdshader")
	plane(Vector2(bounds.size.x + 1400.0, bounds.size.y + 1400.0), Vector3(c.x, -320.0, c.y), stars)
	# A gas giant hanging off one side.
	var planet := ShaderMaterial.new()
	planet.shader = preload("res://scripts/shaders/planet.gdshader")
	var pm := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 260.0
	sm.height = 520.0
	sm.radial_segments = 64
	sm.rings = 32
	pm.mesh = sm
	pm.material_override = planet
	pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pm.position = Vector3(c.x - bounds.size.x * 0.3 - 120.0, -480.0, c.y + bounds.size.y * 0.2 + 60.0)
	root.add_child(pm)
	# The hauler's lower hull: long plated slabs and ribs under the play area,
	# with red running lights and teal engine vents.
	var hull_y := -18.0
	var n := int(bounds.size.x / 22.0) + 2
	for i in n:
		var x := bounds.position.x - 10.0 + i * (bounds.size.x + 20.0) / maxf(n - 1, 1)
		var w := rng.randf_range(10.0, 16.0)
		var top := hull_y - rng.randf_range(0.0, 10.0)
		box(Vector3(w, 6.0, bounds.size.y + 40.0), Vector3(x, top - 3.0, c.y), mats.hull, false, 0.0, false)
		batch_box(Vector3(w * 0.7, 0.3, bounds.size.y + 30.0), Vector3(x, top + 0.15, c.y), mats.hull_dark, Basis(), false)
		for k in int((bounds.size.y + 40.0) / 9.0):
			var z := bounds.position.y - 20.0 + k * 9.0 + 4.0
			batch_box(Vector3(w + 0.2, 0.25, 0.25), Vector3(x, top + 0.05, z), mats.hull_red if k % 3 == 0 else mats.hull_dark, Basis(), false)
		if rng.randf() < 0.45:
			var ez := c.y + rng.randf_range(-bounds.size.y * 0.4, bounds.size.y * 0.4)
			var e := torus(1.6, 2.4, Vector3(x, top + 0.1, ez), mats.engine)
			e.scale = Vector3(1.0, 0.4, 1.0)
	# Ribs running across, catching the light between decks.
	for k in int(bounds.size.y / 30.0) + 2:
		var z := bounds.position.y - 10.0 + k * 30.0
		box(Vector3(bounds.size.x + 40.0, 3.0, 2.2), Vector3(c.x, hull_y - 1.5, z), mats.hull_dark, false, 0.0, false)
	# Drifting debris off the hull.
	for i in 40:
		var p := Vector3(c.x + rng.randf_range(-1.0, 1.0) * (bounds.size.x * 0.5 + 60.0), rng.randf_range(-90.0, -30.0),
			c.y + rng.randf_range(-1.0, 1.0) * (bounds.size.y * 0.5 + 60.0))
		var s := rng.randf_range(0.6, 3.5)
		batch_box(Vector3(s, s * 0.4, s * 0.8), p, mats.hull, Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0.0)), false)


## The Furnace Chasm: a molten lake far below, iron towers rising out of it,
## orange light from beneath, rising embers.
func lava_dressing(bounds: Rect2, fog_top: float) -> void:
	var c := bounds.get_center()
	var rng := RandomNumberGenerator.new()
	rng.seed = 911
	mats.molten_strip = std(Color("301005"), 0.0, 0.5, Color("ff7a1e"), 5.0)
	mats.iron = std(Color("1f1a17"), 0.7, 0.55)
	var lava := ShaderMaterial.new()
	lava.shader = preload("res://scripts/shaders/lava.gdshader")
	plane(Vector2(bounds.size.x + 900.0, bounds.size.y + 900.0), Vector3(c.x, -30.0, c.y), lava)
	# Iron towers out of the lake, some carrying glowing slits.
	for i in 18:
		var ang := TAU * i / 18.0 + rng.randf_range(-0.15, 0.15)
		var rx := bounds.size.x * 0.5 + rng.randf_range(10.0, 40.0)
		var rz := bounds.size.y * 0.5 + rng.randf_range(10.0, 40.0)
		var top := rng.randf_range(-12.0, 10.0) if sin(ang) < 0.0 else rng.randf_range(-18.0, -6.0)
		var p := Vector3(c.x + cos(ang) * rx, top, c.y + sin(ang) * rz)
		var w := rng.randf_range(4.0, 9.0)
		box(Vector3(w, top + 31.0, w), Vector3(p.x, (top - 30.0) * 0.5, p.z), mats.iron, false, 0.0, false)
		for k in 3:
			batch_box(Vector3(w * 0.25, 1.6, 0.1), Vector3(p.x, top - 4.0 - k * 6.0, p.z + w * 0.5 + 0.05), mats.molten_strip, Basis(), false)
	# Trusses dropping from the deck clusters into the glow.
	var cells_x := int(ceil((bounds.size.x + 40.0) / 36.0))
	var cells_z := int(ceil((bounds.size.y + 40.0) / 36.0))
	for ix in cells_x:
		for iz in cells_z:
			if rng.randf() < 0.5:
				var gp := Vector3(bounds.position.x - 20.0 + (ix + 0.5) * 36.0, -29.5, bounds.position.y - 20.0 + (iz + 0.5) * 36.0)
				batch_box(Vector3(rng.randf_range(6.0, 12.0), 2.0, rng.randf_range(6.0, 12.0)), gp, mats.iron, Basis(Vector3.UP, rng.randf()), false)
	# Uplight from the lake (hidden on LOW like every point light).
	var lights := 0
	for ix in range(0, cells_x, 2):
		for iz in range(0, cells_z, 2):
			var lp := Vector3(bounds.position.x + (ix + 0.5) * 36.0, -14.0, bounds.position.y + (iz + 0.5) * 36.0)
			var l := omni(lp, Color("ff6a1c"), 2.5, 34.0, 1.5)
			l.shadow_enabled = false
			lights += 1
	# Heat haze: orange fog over the lake (Forward+ only).
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		var fog := FogVolume.new()
		fog.name = "VoidFog"
		fog.size = Vector3(bounds.size.x + 400.0, 40.0, bounds.size.y + 400.0)
		fog.position = Vector3(c.x, -20.0, c.y)
		var fm := FogMaterial.new()
		fm.density = 0.035
		fm.albedo = Color("ffb070")
		fm.emission = Color("ff5a10")
		fm.edge_fade = 0.1
		fog.material = fm
		root.add_child(fog)
	embers(bounds)


## Sparks and embers rising out of the chasm over the whole floor.
func embers(bounds: Rect2) -> void:
	var c := bounds.get_center()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(bounds.size.x * 0.5 + 20.0, 4.0, bounds.size.y * 0.5 + 20.0)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 25.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3(0.6, 0.4, 0.2)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.5
	pm.scale_min = 0.5
	pm.scale_max = 1.4
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.75, 0.3, 1.0))
	fade.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(2.5, 1.4, 0.6)
	quad.material = m
	var gp := GPUParticles3D.new()
	gp.name = "Embers"
	gp.amount = 900
	gp.lifetime = 9.0
	gp.preprocess = 9.0
	gp.process_material = pm
	gp.draw_pass_1 = quad
	gp.position = Vector3(c.x, -16.0, c.y)
	gp.visibility_aabb = AABB(Vector3(-bounds.size.x * 0.5 - 40.0, -10.0, -bounds.size.y * 0.5 - 40.0),
		Vector3(bounds.size.x + 80.0, 70.0, bounds.size.y + 80.0))
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(gp)


## A plume of smoke lit orange from below, at a stack or crucible.
func smoke(pos: Vector3) -> void:
	if _smoke_quad == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 64
		tex.height = 64
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = tex
		_smoke_quad = QuadMesh.new()
		_smoke_quad.size = Vector2(1.6, 1.6)
		_smoke_quad.material = m
		_smoke_pm = ParticleProcessMaterial.new()
		_smoke_pm.direction = Vector3(0, 1, 0)
		_smoke_pm.spread = 12.0
		_smoke_pm.initial_velocity_min = 1.2
		_smoke_pm.initial_velocity_max = 2.0
		_smoke_pm.gravity = Vector3(0.5, 0.3, 0.2)
		_smoke_pm.scale_min = 0.6
		_smoke_pm.scale_max = 1.0
		var curve := Curve.new()
		curve.add_point(Vector2(0, 0.5))
		curve.add_point(Vector2(1, 2.4))
		var ct := CurveTexture.new()
		ct.curve = curve
		_smoke_pm.scale_curve = ct
		var fade := Gradient.new()
		fade.set_color(0, Color(0.9, 0.45, 0.2, 0.0))
		fade.add_point(0.15, Color(0.55, 0.32, 0.22, 0.55))
		fade.set_color(fade.get_point_count() - 1, Color(0.18, 0.16, 0.16, 0.0))
		var ramp := GradientTexture1D.new()
		ramp.gradient = fade
		_smoke_pm.color_ramp = ramp
	var gp := GPUParticles3D.new()
	gp.amount = 18
	gp.lifetime = 4.0
	gp.preprocess = 4.0
	gp.process_material = _smoke_pm
	gp.draw_pass_1 = _smoke_quad
	gp.position = pos
	gp.visibility_aabb = AABB(Vector3(-6, -1, -6), Vector3(12, 14, 12))
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(gp)
