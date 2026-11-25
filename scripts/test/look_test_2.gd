@tool
extends Node3D
## Look test 2: an ore-processing hall cut into the rock of the Smile Mine. Judges the enclosed
## look (rock on every side, beams overhead), the cutaway (whatever stands between the camera and
## the player drops to waist height with a black top; the camera-side rim is always low), CC0
## textured floors with variety, and the first AI-made props. No enemies.
##   godot --path . res://scenes/test/look_test_2.tscn
##
## Layout (metres; the camera looks north-west, so the tall rock stands on the far edges):
##   north   the ore line: a conveyor carries ore west into the crusher, over glowing grates
##   NE      the shift boss's control booth, amber lit, set into a steel wall in the rock
##   middle  open grey concrete floor, two magenta light pillars, a steel walkway north-south
##   SE      the breach: the rock caved in and the Smile corruption is growing through
##   south   a low rock rim (always cut) with the exit door in the east wall

const KIT := "res://assets/models/kit/%s.glb"
const ENV := "res://assets/models/env/%s.glb"
const TEX := "res://assets/textures/cc0/%s_%s.jpg"
const CUTAWAY := preload("res://scripts/shaders/cutaway.gdshader")
const HAZARD := preload("res://scripts/shaders/hazard_stripe.gdshader")

@export var camera_distance := 13.5
@export var camera_pitch := 48.0

var _scenes := {}
var _mats := {}  # source material -> cutaway material
var _solid: StaticBody3D
var _steel: ShaderMaterial


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		Game.reset_run()


func _ready() -> void:
	_solid = StaticBody3D.new()
	_solid.collision_layer = 1
	add_child(_solid)
	_steel = _surface("metal_plate", Color(0.32, 0.31, 0.34), 0.5)
	_build_floor()
	_build_rock()
	_build_ore_line()
	_build_booth()
	_build_breach()
	_build_middle()
	_build_overhead()
	_build_lights()
	# the hall is built in the editor too (tool script), so it can be looked at without playing;
	# nothing built here is saved into the scene file
	if Engine.is_editor_hint():
		return
	if Game.camera_rig:
		Game.camera_rig.distance = camera_distance
		Game.camera_rig.pitch_degrees = camera_pitch
		Game.camera_rig.apply_framing()
	if Game.player:
		Game.player.grant_invulnerability(1e9)
		Game.player.global_position = Vector3(0, 0, 3)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		_update_cutaway()


## Tell the cutaway shader where the player is and which way the camera looks at her.
func _update_cutaway() -> void:
	var cam := get_viewport().get_camera_3d()
	if Game.player == null or cam == null:
		return
	var p: Vector3 = Game.player.global_position
	var v := cam.global_position - p
	v.y = 0.0
	RenderingServer.global_shader_parameter_set("cutaway_player", p)
	RenderingServer.global_shader_parameter_set("cutaway_view", v.normalized())


# --------------------------------------------------------------------------
# Floor: grey concrete, a steel walkway, grates over glowing ore, painted hazard bands
# --------------------------------------------------------------------------

func _build_floor() -> void:
	var concrete := _surface("hangar_concrete_floor", Color(1.7, 1.65, 1.7), 0.5, 0.15)
	concrete.set_shader_parameter("macro_var", 0.7)
	concrete.set_shader_parameter("cut_enabled", false)
	_plane(Vector2(38, 28), Vector3(0, 0, -1), concrete)
	_collide_box(Vector3(40, 1, 32), Vector3(-1, -0.5, -1))

	# the steel walkway from the exit door to the booth
	var plate := _surface("metal_plate_02", Color(0.8, 0.8, 0.85), 0.5, 0.5)
	plate.set_shader_parameter("macro_var", 0.4)
	plate.set_shader_parameter("cut_enabled", false)
	_plane(Vector2(3.2, 10), Vector3(8.4, 0.012, -0.2), plate)
	_plane(Vector2(11, 3.2), Vector3(13.5, 0.011, 4), plate)

	# grates along the ore line: the ore spill below glows through them
	var grate := _surface("metal_grate_rusty", Color(0.9, 0.85, 0.85), 0.5, 0.7)
	grate.set_shader_parameter("cut_enabled", false)
	grate.set_shader_parameter("gap_glow", Vector3(1.6, 0.5, 0.12))
	_plane(Vector2(16, 3.6), Vector3(-6, 0.014, -6.5), grate)

	# hazard bands frame the ore line and the walkway crossing
	for z in [-8.55, -4.45]:
		_stripe(Vector3(-6, 0.016, z), Vector2(16, 0.5))
	_stripe(Vector3(8.4, 0.016, -5.0), Vector2(3.2, 0.5))
	_stripe(Vector3(-14.25, 0.016, -6.5), Vector2(0.5, 4.6))


# --------------------------------------------------------------------------
# Rock: the hall is cut into it on every side
# --------------------------------------------------------------------------

func _build_rock() -> void:
	# far walls (north and west): tall rock, overlapping chunks, never cut
	var north := [-16.0, -12.0, -8.0, -4.0, 0.0, 3.5]
	for i in north.size():
		_rock(Vector3(north[i], 0, -13.2 + (i % 2) * 0.5), PI + (i * 1.7), 1.15 + (i % 3) * 0.12, false)
	var west := [-9.5, -5.5, -1.5, 2.5, 6.5]
	for i in west.size():
		_rock(Vector3(-17.4 + (i % 2) * 0.4, 0, west[i]), PI / 2 + i * 2.3, 1.1 + (i % 2) * 0.2, false)
	_rock(Vector3(-17.2, 0, -13), 0.8, 1.3, false)
	_collide_box(Vector3(36, 6, 2), Vector3(-1, 3, -13.5))
	_collide_box(Vector3(2, 6, 28), Vector3(-17.5, 3, -1))

	# near rim (south and east): rock too, but always cut to waist height
	var south := [-14.0, -10.0, -6.0, -2.0, 2.0, 6.0]
	for i in south.size():
		_rock(Vector3(south[i], 0, 11.6 - (i % 2) * 0.4), i * 1.9, 1.0 + (i % 3) * 0.1, true)
	_rock(Vector3(17.4, 0, -2.0), 0.4, 1.1, true)
	_rock(Vector3(17.6, 0, 8.5), 2.2, 1.15, true)
	_rock(Vector3(10.5, 0, 11.4), 1.1, 1.05, true)
	_collide_box(Vector3(36, 3, 2), Vector3(-1, 1.5, 12))
	_collide_box(Vector3(2, 3, 9), Vector3(18, 1.5, -2.5))
	_collide_box(Vector3(2, 3, 6), Vector3(18, 1.5, 9))
	# the exit: a steel door frame in the east rock, the walkway runs out through it
	_place("door_frame", Vector3(17.2, 0, 4), PI / 2, true)

	# the steel wall the station built against the rock, behind the booth (north-east)
	for i in 3:
		_place(["wall_curved", "wall_curved", "door_frame"][i], Vector3(8.0 + i * 4.0, 0, -12.2), PI)
	_place("wall_corner", Vector3(6, 0, -12.2), PI)


func _rock(pos: Vector3, yaw: float, s: float, low: bool) -> void:
	var r := _place_env("rock_wall", pos, yaw, Vector3(s, s * 1.15, s))
	if low:
		_always_cut(r)


# --------------------------------------------------------------------------
# The ore line: a conveyor into the crusher, along the north wall
# --------------------------------------------------------------------------

func _build_ore_line() -> void:
	# conveyor runs east -> west, the crusher at the west end takes it in its hopper
	_place_env("conveyor", Vector3(-3.6, 0, -6.5), 0.0, Vector3.ONE * 1.05)
	_place_env("conveyor", Vector3(4.6, 0, -6.5), 0.0, Vector3.ONE * 1.05)
	_collide_box(Vector3(16.8, 2.2, 2.6), Vector3(0.5, 1.1, -6.5))
	_place_env("ore_crusher", Vector3(-11.8, 0, -6.6), PI, Vector3.ONE * 1.35)
	_collide_box(Vector3(7.6, 4, 2.8), Vector3(-11.8, 2, -6.6))
	# ore spilled at the crusher's mouth
	_place_env("rock_cluster", Vector3(-15.2, 0, -3.6), 2.0, Vector3.ONE * 0.75)
	_collide_box(Vector3(2.2, 1.4, 2.2), Vector3(-15.2, 0.7, -3.6))


# --------------------------------------------------------------------------
# The control booth (north-east): a steel box with amber windows
# --------------------------------------------------------------------------

func _build_booth() -> void:
	var amber := StandardMaterial3D.new()
	amber.albedo_color = Color(0.05, 0.03, 0.02)
	amber.emission_enabled = true
	amber.emission = Color(1.0, 0.55, 0.18)
	amber.emission_energy_multiplier = 0.55
	# south face: two windows looking over the hall; west face: a window and a door
	for x in [12.0, 16.0]:
		_amber_glass(_place("wall_window", Vector3(x, 0, -7.2), PI), amber)
	_amber_glass(_place("wall_window", Vector3(10.0, 0, -9.2), PI / 2), amber)
	_place("wall_corner", Vector3(10.0, 0, -7.2), PI / 2)
	_collide_box(Vector3(8, 4, 5), Vector3(14, 2, -9.6))
	_place("chest", Vector3(8.6, 0, -6.4), 0.4)
	_collide_box(Vector3(1.4, 0.8, 1.0), Vector3(8.6, 0.4, -6.4))
	_place("cargo_stack", Vector3(15.6, 0, -4.8), 0.2)
	_collide_box(Vector3(2.4, 1.8, 2.2), Vector3(15.6, 0.9, -4.8))


func _amber_glass(n: Node, mat: Material) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var src := m.mesh.surface_get_material(s)
			if src and src.resource_name == "SpaceGlass":
				m.set_surface_override_material(s, mat)


# --------------------------------------------------------------------------
# The breach (south-east): fallen rock and the Smile corruption growing through
# --------------------------------------------------------------------------

func _build_breach() -> void:
	_place_env("rock_cluster", Vector3(13.2, 0, 8.4), 0.6, Vector3.ONE * 1.25)
	_place_env("rock_cluster", Vector3(8.4, 0, 9.6), 2.6, Vector3.ONE * 0.9)
	_place_env("corruption_mound", Vector3(10.8, 0, 7.4), 0.4, Vector3.ONE * 1.15)
	_place_env("corruption_mound", Vector3(15.6, 0, 6.9), 2.1, Vector3.ONE * 0.75)
	_place_env("corruption_mound", Vector3(6.4, 0, 8.0), 4.0, Vector3.ONE * 0.6)
	_collide_box(Vector3(4, 2, 3), Vector3(13.2, 1, 8.8))
	_collide_box(Vector3(2.6, 1.5, 2.2), Vector3(8.4, 0.75, 9.8))
	_collide_cyl(1.4, 2.0, Vector3(10.8, 0, 7.4))
	_collide_cyl(0.9, 1.5, Vector3(15.6, 0, 6.9))


# --------------------------------------------------------------------------
# The middle: two light pillars, some cargo, room to fight
# --------------------------------------------------------------------------

func _build_middle() -> void:
	for p in [Vector3(-6, 0, 2.5), Vector3(3, 0, 1.0)]:
		_place("light_pillar", p, 0.0)
		_collide_cyl(0.75, 3.4, p)
	_place("cargo_stack", Vector3(-13.4, 0, 5.5), PI * 0.5)
	_collide_box(Vector3(2.4, 1.8, 2.2), Vector3(-13.4, 0.9, 5.5))
	_place("cargo_stack", Vector3(-1.0, 0, 8.6), PI * 0.1)
	_collide_box(Vector3(2.4, 1.8, 2.2), Vector3(-1.0, 0.9, 8.6))
	_place_env("rock_cluster", Vector3(-9.5, 0, 9.0), 4.1, Vector3.ONE * 0.8)
	_collide_box(Vector3(2.2, 1.4, 2.2), Vector3(-9.5, 0.7, 9.0))


# --------------------------------------------------------------------------
# Overhead: girders and the crane rail; cut near the player like everything tall
# --------------------------------------------------------------------------

func _build_overhead() -> void:
	var dark := _surface("metal_plate", Color(0.22, 0.21, 0.24), 0.5)
	for z in [-9.0, -2.5, 4.0]:
		_mesh_box(Vector3(34, 0.7, 0.6), Vector3(-1, 6.8, z), dark)
	for x in [-12.0, -4.0, 4.0, 12.0]:
		_mesh_box(Vector3(0.6, 0.6, 24), Vector3(x, 7.4, -1), dark)
	# crane rail over the ore line, the trolley parked above the crusher with its hook down
	_mesh_box(Vector3(30, 0.5, 0.9), Vector3(-2, 6.2, -6.5), _steel)
	_mesh_box(Vector3(1.6, 0.9, 1.6), Vector3(-8.5, 5.6, -6.5), _steel)
	_mesh_box(Vector3(0.08, 2.6, 0.08), Vector3(-8.5, 3.9, -6.5), dark)
	_mesh_box(Vector3(0.7, 0.5, 0.5), Vector3(-8.5, 2.5, -6.5), _steel)
	# support columns where the girders meet the rock
	for p in [Vector3(-12, 0, -11.4), Vector3(-4, 0, -11.4), Vector3(4, 0, -11.4), Vector3(-15.8, 0, -2.5), Vector3(-15.8, 0, 4.0)]:
		_mesh_box(Vector3(0.7, 7.2, 0.7), p + Vector3(0, 3.6, 0), dark)


func _build_lights() -> void:
	# cold work lamps hanging from the girders
	for p in [Vector3(-9, 5.6, -2.5), Vector3(-1, 5.6, -2.5), Vector3(7, 5.6, -2.5), Vector3(-5, 5.6, 4), Vector3(4, 5.6, 4)]:
		_omni(p, Color(0.82, 0.88, 1.0), 1.6, 12.0)
	# magenta pillars
	for p in [Vector3(-6, 2.2, 2.5), Vector3(3, 2.2, 1.0)]:
		_omni(p, Color(1.0, 0.45, 0.75), 1.0, 7.0)
	# the ore glow under the grates and at the crusher's mouth
	for x in [-12.0, -6.0, 0.0]:
		_omni(Vector3(x, 0.6, -6.5), Color(1.0, 0.5, 0.18), 1.2, 5.0)
	_omni(Vector3(-14.5, 1.2, -3.8), Color(1.0, 0.45, 0.15), 1.4, 5.0)
	# the booth's amber windows spill onto the walkway
	_omni(Vector3(13, 2.0, -6.0), Color(1.0, 0.6, 0.25), 1.6, 6.5)
	# the breach glows candy pink and teal
	_omni(Vector3(11.5, 1.5, 7.4), Color(1.0, 0.35, 0.6), 2.0, 7.0)
	_omni(Vector3(15.2, 0.8, 6.4), Color(0.2, 0.9, 0.85), 1.2, 4.5)
	# cold daylight-ish from the exit door
	_omni(Vector3(16.4, 2.4, 4.0), Color(0.5, 0.65, 1.0), 1.2, 6.0)
	# low fill raking across the rock walls so the hall reads as cut into stone
	for p in [Vector3(-14, 1.5, -10), Vector3(-6, 2.0, -11), Vector3(2, 2.0, -11), Vector3(-15, 1.5, 0), Vector3(-15, 1.5, 7)]:
		_omni(p, Color(1.0, 0.62, 0.38), 0.9, 7.0)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-62, -150, 0)
	key.light_color = Color(0.65, 0.72, 0.95)
	key.light_energy = 0.45
	key.shadow_enabled = true
	add_child(key)


# --------------------------------------------------------------------------
# Materials
# --------------------------------------------------------------------------

## A triplanar CC0-textured surface with the cutaway.
func _surface(tex: String, tint: Color, roughness: float, scale := 0.25) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CUTAWAY
	m.set_shader_parameter("use_textures", true)
	m.set_shader_parameter("albedo_tex", load(TEX % [tex, "albedo"]))
	m.set_shader_parameter("normal_tex", load(TEX % [tex, "normal"]))
	m.set_shader_parameter("arm_tex", load(TEX % [tex, "arm"]))
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("roughness", roughness)
	m.set_shader_parameter("metallic", 0.0)
	m.set_shader_parameter("tex_scale", scale)
	return m


## The cutaway version of an imported material: UV-textured for the AI models, flat colour (or
## steel-textured, for the station's wall panels) for the kit.
func _cutaway_of(src: Material) -> Material:
	if _mats.has(src):
		return _mats[src]
	var out: Material = src
	var std := src as BaseMaterial3D
	if std:
		var m := ShaderMaterial.new()
		m.shader = CUTAWAY
		m.set_shader_parameter("tint", std.albedo_color)
		m.set_shader_parameter("roughness", std.roughness)
		m.set_shader_parameter("metallic", std.metallic)
		if std.albedo_texture:
			m.set_shader_parameter("use_textures", true)
			m.set_shader_parameter("use_uv", true)
			m.set_shader_parameter("albedo_tex", std.albedo_texture)
			m.set_shader_parameter("normal_tex", std.normal_texture)
			m.set_shader_parameter("arm_tex", std.roughness_texture)
			m.set_shader_parameter("roughness", 0.5)
			m.set_shader_parameter("metallic", 0.0)
		elif src.resource_name.begins_with("Wall"):
			m.set_shader_parameter("use_textures", true)
			m.set_shader_parameter("albedo_tex", load(TEX % ["metal_plate", "albedo"]))
			m.set_shader_parameter("normal_tex", load(TEX % ["metal_plate", "normal"]))
			m.set_shader_parameter("arm_tex", load(TEX % ["metal_plate", "arm"]))
			m.set_shader_parameter("tint", std.albedo_color * 2.2)
			m.set_shader_parameter("tex_scale", 0.5)
		if std.emission_enabled:
			var e := std.emission
			m.set_shader_parameter("emission", Vector3(e.r, e.g, e.b))
			m.set_shader_parameter("emission_energy", std.emission_energy_multiplier)
		out = m
	_mats[src] = out
	return out


func _apply_cutaway(n: Node) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var src := m.get_surface_override_material(s)
			if src == null:
				src = m.mesh.surface_get_material(s)
			if src and src.resource_name != "SpaceGlass":
				m.set_surface_override_material(s, _cutaway_of(src))


func _always_cut(n: Node) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as GeometryInstance3D).set_instance_shader_parameter("always_cut", true)


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

func _place(piece: String, pos: Vector3, yaw: float, low := false) -> Node3D:
	return _instance(KIT % piece, pos, yaw, Vector3.ONE, low)


func _place_env(piece: String, pos: Vector3, yaw: float, scale := Vector3.ONE) -> Node3D:
	return _instance(ENV % piece, pos, yaw, scale, false)


func _instance(path: String, pos: Vector3, yaw: float, scale: Vector3, low: bool) -> Node3D:
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var n: Node3D = (_scenes[path] as PackedScene).instantiate()
	n.position = pos
	n.rotation.y = yaw
	n.scale = scale
	add_child(n)
	_apply_cutaway(n)
	if low:
		_always_cut(n)
	return n


func _plane(size: Vector2, center: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = mat
	mi.position = center
	add_child(mi)


func _stripe(center: Vector3, size: Vector2) -> void:
	var m := ShaderMaterial.new()
	m.shader = HAZARD
	_plane(size, center, m)


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


func _mesh_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
