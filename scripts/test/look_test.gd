extends Node3D
## Look test: one station hall built from the room kit (assets/models/kit, made by
## art_src/blender/build_station_kit.py), lit in the magenta-neon station style, played with the
## closer camera from the level design doc. No enemies: this is for judging the look.
##   godot --path . res://scenes/test/look_test.tscn
##
## Layout (metres, the camera looks north-west, so the tall walls stand on the far edges):
##   upper hall  x -12..12, z -10..10, floor at 0: windows and curved neon walls north and west,
##               four light pillars, cargo and a chest at the edges, corruption creeping in
##   east        wide stairs down one deck to a platform out over the void
##   south, east open rims with railings over a glowing, fogged void

const KIT := "res://assets/models/kit/%s.glb"
## Camera framing for this test (the doc's 13-14 m at 45-50 degrees).
@export var camera_distance := 13.5
@export var camera_pitch := 48.0

var _scenes := {}
var _space_glass: ShaderMaterial
var _solid: StaticBody3D


func _enter_tree() -> void:
	Game.reset_run()


func _ready() -> void:
	_solid = StaticBody3D.new()
	_solid.collision_layer = 1
	add_child(_solid)
	_build_hall()
	_build_lower_deck()
	_build_void()
	_build_lights()
	if Game.camera_rig:
		Game.camera_rig.distance = camera_distance
		Game.camera_rig.pitch_degrees = camera_pitch
		Game.camera_rig.apply_framing()
	if Game.player:
		Game.player.grant_invulnerability(1e9)
		Game.player.global_position = Vector3(0, 0, 4)


# --------------------------------------------------------------------------
# Rooms
# --------------------------------------------------------------------------

func _build_hall() -> void:
	# floor: 6 x 5 plates, the middle row lit
	for ix in 6:
		for iz in 5:
			var x := -10.0 + ix * 4.0
			var z := -8.0 + iz * 4.0
			_place("floor_plate", Vector3(x, 0, z), 0.0)
	_collide_box(Vector3(24, 1, 20), Vector3(0, -0.5, 0))

	# north wall (faces south): windows in the middle, curved walls, a door at the east end
	var north := ["wall_curved", "wall_window", "wall_window", "wall_window", "wall_curved", "door_frame"]
	for i in north.size():
		_place(north[i], Vector3(-10.0 + i * 4.0, 0, -10), PI)
	_collide_box(Vector3(24, 5, 1), Vector3(0, 2.5, -10.6))
	# west wall (faces east)
	var west := ["wall_curved", "door_frame", "wall_curved", "wall_curved", "wall_curved"]
	for i in west.size():
		_place(west[i], Vector3(-12, 0, -8.0 + i * 4.0), -PI / 2)
	_collide_box(Vector3(1, 5, 20), Vector3(-12.6, 2.5, 0))
	_place("wall_corner", Vector3(-12, 0, -10), PI)

	# four light pillars: cover and light
	for p in [Vector3(-5, 0, -3.5), Vector3(5, 0, -3.5), Vector3(-5, 0, 3.5), Vector3(5, 0, 3.5)]:
		_place("light_pillar", p, 0.0)
		_collide_cyl(0.75, 3.4, p)

	# cargo kept to the edges, a chest in the north-east corner
	_place("cargo_stack", Vector3(-10.2, 0, -8.2), PI * 0.5)
	_place("cargo_stack", Vector3(-7.0, 0, -8.6), PI)
	_place("cargo_stack", Vector3(-10.4, 0, 6.5), PI * 0.5)
	for c in [Vector3(-10.2, 0.9, -8.2), Vector3(-7.0, 0.9, -8.6), Vector3(-10.4, 0.9, 6.5)]:
		_collide_box(Vector3(2.4, 1.8, 2.2), c)
	_place("chest", Vector3(8.5, 0, -7.8), PI + 0.4)
	_collide_box(Vector3(1.4, 0.8, 1.0), Vector3(8.5, 0.4, -7.8))

	# the corruption creeps in from the south-east rim
	_place("corruption_patch", Vector3(8.5, 0, 7.2), 0.3)
	_place("corruption_patch", Vector3(10.6, 0, 3.0), 1.9, Vector3(0.8, 1.0, 0.8))
	_place("corruption_patch", Vector3(-8.0, 0, 8.4), 2.6, Vector3(0.7, 1.0, 0.7))

	# open rims: south (x -12..12) and east (z -10..-2 and 2..10, the stairs between)
	for i in 6:
		var x := -10.0 + i * 4.0
		_place("railing", Vector3(x, 0, 10), 0.0)
		_place("platform_edge", Vector3(x, 0, 10), PI)
	_collide_box(Vector3(24, 2, 0.4), Vector3(0, 1, 10.2))
	for z in [-8.0, -4.0, 4.0, 8.0]:
		_place("railing", Vector3(12, 0, z), PI / 2)
		_place("platform_edge", Vector3(12, 0, z), -PI / 2)
	_collide_box(Vector3(0.4, 2, 8), Vector3(12.2, 1, -6))
	_collide_box(Vector3(0.4, 2, 8), Vector3(12.2, 1, 6))
	# stairs down to the east deck (the player stays on one floor for now: blocked at the top)
	_place("stairs", Vector3(12, 0, 0), -PI / 2)
	_collide_box(Vector3(0.4, 2, 4), Vector3(12.4, 1, 0))


func _build_lower_deck() -> void:
	var y := -3.0
	for ix in 3:
		for iz in 3:
			_place("floor_plate", Vector3(20.0 + ix * 4.0, y, -4.0 + iz * 4.0), 0.0)
	for i in 3:
		_place("railing", Vector3(20.0 + i * 4.0, y, 6), 0.0)
		_place("platform_edge", Vector3(20.0 + i * 4.0, y, 6), PI)
		_place("railing", Vector3(20.0 + i * 4.0, y, -6), PI)
		_place("platform_edge", Vector3(20.0 + i * 4.0, y, -6), 0.0)
		_place("railing", Vector3(30, y, -4.0 + i * 4.0), PI / 2)
		_place("platform_edge", Vector3(30, y, -4.0 + i * 4.0), -PI / 2)
	_place("light_pillar", Vector3(26, y, 0), 0.0)
	_place("corruption_patch", Vector3(22, y, 3), 0.9)


## The void under the platforms: dark depths with warm furnace glow and girders in the fog.
func _build_void() -> void:
	var deep := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(160, 160)
	deep.mesh = plane
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.02, 0.012, 0.02)
	m.emission_enabled = true
	m.emission = Color(0.3, 0.07, 0.05)
	m.emission_energy_multiplier = 0.12
	deep.material_override = m
	deep.position = Vector3(10, -26, 10)
	add_child(deep)
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.05, 0.05, 0.06)
	steel.metallic = 0.6
	for g in [Vector3(-4, -14, 22), Vector3(14, -14, 20), Vector3(34, -14, 12), Vector3(26, -14, -14), Vector3(22, -16, 28)]:
		_mesh_box(Vector3(1.2, 24, 1.2), g, steel)
	for g in [Vector3(4, -8, 22), Vector3(30, -9, 0)]:
		_mesh_box(Vector3(20, 0.8, 0.8), g, steel, PI / 2 if g.x > 20 else 0.0)


func _build_lights() -> void:
	# magenta-pink from each pillar, a white wash overhead, amber at the doors, cold window light
	for p in [Vector3(-5, 2.2, -3.5), Vector3(5, 2.2, -3.5), Vector3(-5, 2.2, 3.5), Vector3(5, 2.2, 3.5), Vector3(26, -0.8, 0)]:
		_omni(p, Color(1.0, 0.45, 0.75), 1.0, 7.0)
	for p in [Vector3(-6, 4.5, -2), Vector3(6, 4.5, -2), Vector3(0, 4.5, 6)]:
		_omni(p, Color(0.85, 0.9, 1.0), 0.9, 12.0)
	_omni(Vector3(10, 2.5, -8.6), Color(1.0, 0.6, 0.25), 1.4, 5.0)
	_omni(Vector3(-10.8, 2.5, -4), Color(1.0, 0.6, 0.25), 1.4, 5.0)
	for x in [-6.0, -2.0, 2.0]:
		_omni(Vector3(x, 3.0, -9.0), Color(0.45, 0.6, 1.0), 0.8, 6.0)
	# warm furnace glow rising out of the void past the rims
	_omni(Vector3(4, -7, 16), Color(1.0, 0.42, 0.15), 6.0, 18.0)
	_omni(Vector3(22, -9, 10), Color(1.0, 0.42, 0.15), 6.0, 18.0)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, -160, 0)
	moon.light_color = Color(0.6, 0.72, 1.0)
	moon.light_energy = 0.35
	moon.shadow_enabled = true
	add_child(moon)


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

func _place(piece: String, pos: Vector3, yaw: float, scale := Vector3.ONE) -> Node3D:
	if not _scenes.has(piece):
		_scenes[piece] = load(KIT % piece)
	var n: Node3D = (_scenes[piece] as PackedScene).instantiate()
	n.position = pos
	n.rotation.y = yaw
	n.scale = scale
	add_child(n)
	if piece == "wall_window":
		_glass(n)
	return n


## The window glass shows the animated star field (as on the starship's hull windows).
func _glass(n: Node) -> void:
	if _space_glass == null:
		_space_glass = ShaderMaterial.new()
		_space_glass.shader = load("res://scripts/shaders/space_glass.gdshader")
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(s)
			if mat and mat.resource_name == "SpaceGlass":
				m.set_surface_override_material(s, _space_glass)


func _omni(pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_m
	l.omni_attenuation = 1.2
	add_child(l)


func _collide_box(size: Vector3, center: Vector3) -> void:
	var s := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	s.shape = b
	s.position = center
	_solid.add_child(s)


func _collide_cyl(radius: float, height: float, base: Vector3) -> void:
	var s := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = height
	s.shape = c
	s.position = base + Vector3(0, height / 2, 0)
	_solid.add_child(s)


func _mesh_box(size: Vector3, pos: Vector3, mat: Material, yaw := 0.0) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = yaw
	add_child(mi)
