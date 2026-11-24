extends SceneTree
## Builds the combat VFX scenes (scenes/vfx/*.tscn) and their profiles
## (scenes/vfx/profiles/*.tres). The scenes are ordinary Godot scenes and can be
## tuned in the editor; this script is how they were first authored and can
## rebuild them from scratch (it overwrites hand edits, so tune one or the other).
##   godot --headless --path . --script res://art_src/vfx/build_vfx.gd
##
## Look rules for every effect (isometric camera, swarms on screen):
##   - short: flashes 40-90 ms, sparks under half a second, smoke under 2 s
##   - bright core, quick falloff; colour carries identity, not size
##   - shockwaves and ground flashes lie flat on the floor (read from above)
##   - few, purposeful particles; additive only for light (fire, sparks, energy),
##     alpha for matter (smoke, dust, ichor, debris)

const ADD := preload("res://scripts/shaders/vfx/vfx_add.gdshader")
const MIX := preload("res://scripts/shaders/vfx/vfx_mix.gdshader")
const OUT := "res://scenes/vfx/"

enum Shape { DOT, STREAK, STAR, RING, PUFF, HEX, FLARE }


func _initialize() -> void:
	_build_rifle_muzzle()
	_build_impact_organic()
	_build_impact_metal()
	_build_impact_shield()
	_build_impact_environment()
	_build_grenade_explosion()
	print("VFX built.")
	quit()


# ==========================================================================
# Helpers
# ==========================================================================

func _root(name: String, duration: float, profile: VfxProfile) -> VfxEffect:
	var r := VfxEffect.new()
	r.name = name
	r.duration = duration
	r.profile = profile
	return r


func _mat(additive: bool, shape: int, energy: float, billboard := true, extra := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = ADD if additive else MIX
	m.set_shader_parameter("shape", shape)
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("billboard", billboard)
	for k in extra:
		if k == "priority":
			m.render_priority = extra[k]  # additive fire draws over the smoke it sits in
		else:
			m.set_shader_parameter(k, extra[k])
	return m


func _quad(size: Vector2) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = size
	return q


func _plane(size: Vector2) -> PlaneMesh:
	var p := PlaneMesh.new()
	p.size = size
	return p


func _grad(stops: Array) -> GradientTexture1D:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for s in stops:
		offs.append(s[0])
		cols.append(s[1])
	g.offsets = offs
	g.colors = cols
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _curve(points: Array) -> CurveTexture:
	var c := Curve.new()
	c.max_value = 4.0
	for p in points:
		c.add_point(Vector2(p[0], p[1]))
	var t := CurveTexture.new()
	t.curve = c
	return t


## A one-shot burst emitter. opts: direction, spread, vel (Vector2 min/max),
## gravity, damping (Vector2), scale (Vector2), scale_curve, color (gradient
## texture), angle / angular (Vector2, degrees), sphere (emission radius),
## box (Vector3 extents), flat (bool: spread in the floor plane), lifetime_rand,
## explosiveness, align (velocity-aligned streaks), delay, keep_color, ground.
func _emitter(parent: Node3D, name: String, mesh: Mesh, mat: Material, amount: int, lifetime: float, opts := {}) -> GPUParticles3D:
	var e := GPUParticles3D.new()
	e.name = name
	e.amount = amount
	e.lifetime = lifetime
	e.one_shot = true
	e.emitting = false
	e.explosiveness = opts.get("explosiveness", 1.0)
	e.randomness = opts.get("lifetime_rand", 0.3)
	e.draw_pass_1 = mesh
	e.material_override = mat
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	e.visibility_aabb = AABB(Vector3(-8, -4, -8), Vector3(16, 14, 16))
	if opts.get("align", false):
		e.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY
	var pm := ParticleProcessMaterial.new()
	pm.direction = opts.get("direction", Vector3(0, 0, -1))
	pm.spread = opts.get("spread", 30.0)
	if opts.get("flat", false):
		pm.flatness = 1.0
	var vel: Vector2 = opts.get("vel", Vector2(2, 4))
	pm.initial_velocity_min = vel.x
	pm.initial_velocity_max = vel.y
	pm.gravity = opts.get("gravity", Vector3(0, -9.8, 0))
	var damp: Vector2 = opts.get("damping", Vector2.ZERO)
	pm.damping_min = damp.x
	pm.damping_max = damp.y
	var sc: Vector2 = opts.get("scale", Vector2.ONE)
	pm.scale_min = sc.x
	pm.scale_max = sc.y
	if opts.has("scale_curve"):
		pm.scale_curve = opts.scale_curve
	if opts.has("color"):
		pm.color_ramp = opts.color
	if opts.has("angle"):
		var a: Vector2 = opts.angle
		pm.angle_min = a.x
		pm.angle_max = a.y
	if opts.has("angular"):
		var av: Vector2 = opts.angular
		pm.angular_velocity_min = av.x
		pm.angular_velocity_max = av.y
	if opts.has("sphere"):
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = opts.sphere
	elif opts.has("box"):
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = opts.box
	e.process_material = pm
	if opts.has("delay"):
		e.set_meta("delay", opts.delay)
	if opts.get("keep_color", false):
		e.set_meta("keep_color", true)
	if opts.get("ground", false):
		e.set_meta("ground", true)
	parent.add_child(e)
	if opts.has("position"):
		e.position = opts.position
	return e


## A mesh animated by a VfxPulse (flash, plume, ring).
func _pulse_mesh(parent: Node3D, name: String, mesh: Mesh, mat: Material, pulse: Dictionary, opts := {}) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.position = opts.get("position", Vector3.ZERO)
	mi.rotation = opts.get("rotation", Vector3.ZERO)
	if opts.get("keep_color", false):
		mi.set_meta("keep_color", true)
	if opts.get("ground", false):
		mi.set_meta("ground", true)
	_add_pulse(mi, pulse)
	return mi


func _light(parent: Node3D, name: String, color: Color, energy: float, range_m: float, life: float, pos := Vector3.ZERO) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = name
	l.light_color = color
	l.omni_range = range_m
	l.light_energy = 0.0
	l.shadow_enabled = false
	parent.add_child(l)
	l.position = pos
	_add_pulse(l, {"life": life, "light_energy": energy, "ease_power": 1.0})
	return l


func _add_pulse(target: Node, p: Dictionary) -> void:
	var vp := VfxPulse.new()
	vp.name = "Pulse"
	vp.delay = p.get("delay", 0.0)
	vp.life = p.get("life", 0.1)
	vp.scale_from = p.get("scale_from", Vector3.ONE)
	vp.scale_to = p.get("scale_to", Vector3.ONE)
	vp.ease_power = p.get("ease_power", 2.5)
	vp.fade_from = p.get("fade_from", 1.0)
	vp.fade_to = p.get("fade_to", 0.0)
	vp.random_spin = p.get("random_spin", false)
	vp.ground_snap = p.get("ground_snap", false)
	vp.light_energy = p.get("light_energy", 0.0)
	target.add_child(vp)


func _feedback(shake: float, kick: float, hitstop: float, near: float, far: float, from_source := true) -> CameraFeedback:
	var f := CameraFeedback.new()
	f.shake = shake
	f.kick = kick
	f.hitstop = hitstop
	f.near = near
	f.far = far
	f.kick_from_source = from_source
	return f


func _profile(name: String, color: Color, feedback: CameraFeedback = null) -> VfxProfile:
	var p := VfxProfile.new()
	p.color = color
	p.feedback = feedback
	var path := OUT + "profiles/%s.tres" % name
	ResourceSaver.save(p, path)
	return load(path)


func _save(root: Node) -> void:
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	var path := OUT + root.name.to_snake_case() + ".tscn"
	var err := ResourceSaver.save(ps, path)
	print("saved ", path, " err=", err)
	root.free()


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)


# Common gradients ------------------------------------------------------------

func _fade_white() -> GradientTexture1D:
	return _grad([[0.0, Color(1, 1, 1, 1)], [0.6, Color(1, 1, 1, 0.8)], [1.0, Color(1, 1, 1, 0)]])


func _hot_sparks() -> GradientTexture1D:
	return _grad([[0.0, Color(1, 1, 0.92, 1)], [0.3, Color(1, 0.78, 0.35, 1)], [1.0, Color(1, 0.32, 0.06, 0)]])


# ==========================================================================
# 1. Assault rifle muzzle
# ==========================================================================

func _build_rifle_muzzle() -> void:
	var prof := _profile("rifle_muzzle", Color("7ff8ff"))
	var r := _root("RifleMuzzle", 0.6, prof)
	# Hot core and a spinning star: the flash itself (seen from any angle).
	_pulse_mesh(r, "Core", _quad(Vector2(0.55, 0.55)), _mat(true, Shape.FLARE, 4.0), {"life": 0.05, "scale_from": Vector3.ONE * 1.3, "scale_to": Vector3.ONE * 0.5, "ease_power": 1.5}, {"position": Vector3(0, 0, -0.12)})
	_pulse_mesh(r, "Star", _quad(Vector2(0.95, 0.95)), _mat(true, Shape.STAR, 2.6, true, {"star_points": 5.0}), {"life": 0.045, "scale_to": Vector3.ONE * 0.6, "random_spin": true}, {"position": Vector3(0, 0, -0.2)})
	# Forward plume lying flat so it reads from the high camera.
	_pulse_mesh(r, "Plume", _plane(Vector2(0.3, 1.2)), _mat(true, Shape.STREAK, 3.2, false), {"life": 0.05, "scale_from": Vector3(1, 1, 0.6), "scale_to": Vector3(1, 1, 1.3), "ease_power": 1.8}, {"position": Vector3(0, 0, -0.62)})
	for s in [-1.0, 1.0]:
		_pulse_mesh(r, "Brake" + ("L" if s < 0 else "R"), _plane(Vector2(0.12, 0.45)), _mat(true, Shape.STREAK, 2.4, false), {"life": 0.04, "scale_to": Vector3(1, 1, 1.4)}, {"position": Vector3(s * 0.13, 0, -0.26), "rotation": Vector3(0, s * -0.9, 0)})
	_emitter(r, "Sparks", _quad(Vector2(0.045, 0.32)), _mat(true, Shape.STREAK, 3.0, false), 7, 0.14, {
		"spread": 16.0, "vel": Vector2(16, 26), "gravity": Vector3(0, -4, 0), "scale": Vector2(0.7, 1.2),
		"color": _fade_white(), "align": true})
	_emitter(r, "Smoke", _quad(Vector2(0.5, 0.5)), _mat(false, Shape.PUFF, 1.0, true, {"erosion": 0.8}), 3, 0.55, {
		"spread": 25.0, "vel": Vector2(0.8, 2.0), "damping": Vector2(2, 3), "gravity": Vector3(0, 1.2, 0),
		"scale_curve": _curve([[0.0, 0.5], [1.0, 1.6]]), "explosiveness": 0.8, "keep_color": true,
		"color": _grad([[0.0, Color(0.75, 0.8, 0.85, 0.35)], [1.0, Color(0.75, 0.8, 0.85, 0.0)]]), "angle": Vector2(0, 360)})
	_light(r, "Light", Color(0.6, 0.95, 1.0), 2.5, 5.0, 0.06)
	_save(r)


# ==========================================================================
# 2. Bullet impacts by surface (the effect's -Z points out of the surface)
# ==========================================================================

func _build_impact_organic() -> void:
	var prof := _profile("impact_organic", Color("ffb03b"))
	var r := _root("ImpactOrganic", 0.7, prof)
	_pulse_mesh(r, "Wound", _quad(Vector2(0.5, 0.5)), _mat(true, Shape.FLARE, 2.2), {"life": 0.06, "scale_to": Vector3.ONE * 0.4, "ease_power": 1.5})
	var drop := _mat(false, Shape.DOT, 1.0, true, {"softness": 0.4})
	_emitter(r, "Ichor", _quad(Vector2(0.18, 0.18)), drop, 14, 0.5, {
		"spread": 55.0, "vel": Vector2(3, 7.5), "gravity": Vector3(0, -16, 0), "scale": Vector2(0.5, 1.1),
		"scale_curve": _curve([[0.0, 1.0], [1.0, 0.4]]), "color": _fade_white()})
	_emitter(r, "ExitSpray", _quad(Vector2(0.12, 0.12)), drop, 6, 0.4, {
		"direction": Vector3(0, 0, 1), "spread": 25.0, "vel": Vector2(2, 5), "gravity": Vector3(0, -16, 0),
		"scale": Vector2(0.5, 1.0), "color": _fade_white()})
	_emitter(r, "Mist", _quad(Vector2(0.6, 0.6)), _mat(false, Shape.PUFF, 1.0, true, {"erosion": 0.9}), 2, 0.35, {
		"spread": 40.0, "vel": Vector2(0.5, 1.5), "damping": Vector2(3, 4), "gravity": Vector3.ZERO,
		"scale_curve": _curve([[0.0, 0.6], [1.0, 1.4]]), "color": _grad([[0.0, Color(1, 1, 1, 0.35)], [1.0, Color(1, 1, 1, 0)]])})
	var chitin := StandardMaterial3D.new()
	chitin.albedo_color = Color(0.09, 0.07, 0.05)
	chitin.metallic = 0.3
	chitin.roughness = 0.4
	var bit := BoxMesh.new()
	bit.size = Vector3(0.06, 0.03, 0.08)
	_emitter(r, "Bits", bit, chitin, 5, 0.6, {
		"spread": 60.0, "vel": Vector2(2.5, 5), "gravity": Vector3(0, -18, 0), "scale": Vector2(0.7, 1.3),
		"angular": Vector2(-540, 540), "keep_color": true})
	_save(r)


func _build_impact_metal() -> void:
	var prof := _profile("impact_metal", Color(1, 0.85, 0.55))
	var r := _root("ImpactMetal", 0.6, prof)
	_pulse_mesh(r, "Flash", _quad(Vector2(0.6, 0.6)), _mat(true, Shape.FLARE, 3.2), {"life": 0.05, "scale_to": Vector3.ONE * 0.4, "ease_power": 1.5}, {"keep_color": true})
	_pulse_mesh(r, "Star", _quad(Vector2(0.7, 0.7)), _mat(true, Shape.STAR, 3.0, true, {"star_points": 4.0}), {"life": 0.04, "scale_to": Vector3.ONE * 0.5, "random_spin": true})
	_emitter(r, "Sparks", _quad(Vector2(0.035, 0.3)), _mat(true, Shape.STREAK, 3.0, false), 14, 0.4, {
		"spread": 65.0, "vel": Vector2(5, 13), "gravity": Vector3(0, -20, 0), "damping": Vector2(0.5, 1.5),
		"scale": Vector2(0.6, 1.2), "color": _hot_sparks(), "align": true, "keep_color": true, "lifetime_rand": 0.45})
	_emitter(r, "Smoke", _quad(Vector2(0.45, 0.45)), _mat(false, Shape.PUFF, 1.0), 2, 0.5, {
		"spread": 30.0, "vel": Vector2(0.5, 1.5), "damping": Vector2(2, 3), "gravity": Vector3(0, 1.0, 0),
		"scale_curve": _curve([[0.0, 0.6], [1.0, 1.5]]), "keep_color": true,
		"color": _grad([[0.0, Color(0.5, 0.5, 0.52, 0.3)], [1.0, Color(0.5, 0.5, 0.52, 0)]])})
	_light(r, "Light", Color(1, 0.7, 0.35), 1.5, 3.0, 0.05)
	_save(r)


func _build_impact_shield() -> void:
	var prof := _profile("impact_shield", Color("4fb0ff"))
	var r := _root("ImpactShield", 0.4, prof)
	_pulse_mesh(r, "Hex", _quad(Vector2(1.3, 1.3)), _mat(true, Shape.HEX, 2.4), {"life": 0.25, "scale_from": Vector3.ONE * 0.6, "scale_to": Vector3.ONE * 1.25, "ease_power": 2.0})
	_pulse_mesh(r, "Flash", _quad(Vector2(0.45, 0.45)), _mat(true, Shape.FLARE, 3.0), {"life": 0.05, "scale_to": Vector3.ONE * 0.4})
	_emitter(r, "Sparks", _quad(Vector2(0.035, 0.26)), _mat(true, Shape.STREAK, 3.0, false), 9, 0.25, {
		"spread": 75.0, "vel": Vector2(4, 9), "gravity": Vector3(0, -2, 0), "scale": Vector2(0.6, 1.1),
		"color": _fade_white(), "align": true})
	_save(r)


func _build_impact_environment() -> void:
	var prof := _profile("impact_environment", Color(1, 0.8, 0.55))
	var r := _root("ImpactEnvironment", 0.9, prof)
	_pulse_mesh(r, "Flash", _quad(Vector2(0.3, 0.3)), _mat(true, Shape.FLARE, 2.5), {"life": 0.04, "scale_to": Vector3.ONE * 0.4})
	_emitter(r, "Sparks", _quad(Vector2(0.03, 0.22)), _mat(true, Shape.STREAK, 2.5, false), 5, 0.25, {
		"spread": 50.0, "vel": Vector2(4, 9), "gravity": Vector3(0, -18, 0), "scale": Vector2(0.6, 1.0),
		"color": _hot_sparks(), "align": true, "keep_color": true})
	_emitter(r, "Dust", _quad(Vector2(0.55, 0.55)), _mat(false, Shape.PUFF, 1.0, true, {"erosion": 0.7}), 5, 0.8, {
		"spread": 35.0, "vel": Vector2(0.8, 2.5), "damping": Vector2(3, 4), "gravity": Vector3(0, 0.4, 0),
		"scale_curve": _curve([[0.0, 0.6], [1.0, 1.8]]), "keep_color": true, "angle": Vector2(0, 360),
		"color": _grad([[0.0, Color(0.55, 0.52, 0.48, 0.45)], [1.0, Color(0.55, 0.52, 0.48, 0)]])})
	var grit := StandardMaterial3D.new()
	grit.albedo_color = Color(0.3, 0.3, 0.32)
	grit.roughness = 0.8
	var chip := BoxMesh.new()
	chip.size = Vector3(0.05, 0.03, 0.05)
	_emitter(r, "Debris", chip, grit, 4, 0.55, {
		"spread": 50.0, "vel": Vector2(2, 4), "gravity": Vector3(0, -18, 0), "angular": Vector2(-400, 400), "keep_color": true})
	_save(r)


# ==========================================================================
# 3. Grenade explosion (upright; feedback through its profile)
# ==========================================================================

func _build_grenade_explosion() -> void:
	var prof := _profile("grenade_explosion", Color(1, 0.75, 0.45), _feedback(0.36, 0.18, 0.04, 3.0, 22.0))
	var r := _root("GrenadeExplosion", 2.2, prof)
	var up := Vector3(0, 1, 0)
	# 1. A blinding core flash: the moment of detonation.
	_pulse_mesh(r, "CoreFlash", _quad(Vector2(3.0, 3.0)), _mat(true, Shape.FLARE, 2.0), {"life": 0.09, "scale_from": Vector3.ONE * 0.6, "scale_to": Vector3.ONE * 1.3, "ease_power": 1.6}, {"keep_color": true})
	# 2. Fireball: puffs that bloom outward, burn from white to red and erode away.
	_emitter(r, "Fireball", _quad(Vector2(1.0, 1.0)), _mat(true, Shape.PUFF, 1.15, true, {"erosion": 0.9, "noise_scale": 2.2, "priority": 1}), 18, 0.75, {
		"direction": up, "spread": 180.0, "vel": Vector2(2.5, 6), "damping": Vector2(4, 6), "gravity": Vector3(0, 1.5, 0),
		"sphere": 0.5, "scale": Vector2(1.4, 2.4), "scale_curve": _curve([[0.0, 0.5], [0.25, 1.0], [1.0, 1.3]]),
		"angle": Vector2(0, 360), "keep_color": true, "lifetime_rand": 0.35, "explosiveness": 0.95,
		"color": _grad([[0.0, Color(1, 1, 0.85, 1)], [0.07, Color(1, 0.8, 0.35, 1)], [0.3, Color(1, 0.45, 0.08, 0.9)], [0.55, Color(0.75, 0.2, 0.03, 0.35)], [0.75, Color(0.3, 0.08, 0.02, 0)], [1.0, Color(0, 0, 0, 0)]])})
	# 3. Smoke column rising after the fire.
	_emitter(r, "Smoke", _quad(Vector2(1.3, 1.3)), _mat(false, Shape.PUFF, 1.0, true, {"erosion": 0.6}), 12, 1.8, {
		"direction": up, "spread": 60.0, "vel": Vector2(1, 3), "damping": Vector2(1, 2), "gravity": Vector3(0, 1.1, 0),
		"sphere": 0.8, "scale": Vector2(1.8, 3.0), "scale_curve": _curve([[0.0, 0.4], [1.0, 1.5]]), "angle": Vector2(0, 360),
		"keep_color": true, "delay": 0.05, "lifetime_rand": 0.3,
		"color": _grad([[0.0, Color(0.08, 0.07, 0.07, 0)], [0.08, Color(0.1, 0.09, 0.09, 0.75)], [0.5, Color(0.2, 0.19, 0.19, 0.5)], [1.0, Color(0.28, 0.28, 0.29, 0)]])})
	# 4. Embers: fast streaks that arc and fall.
	_emitter(r, "Embers", _quad(Vector2(0.05, 0.38)), _mat(true, Shape.STREAK, 3.0, false), 46, 0.9, {
		"direction": up, "spread": 80.0, "vel": Vector2(8, 20), "gravity": Vector3(0, -16, 0), "damping": Vector2(0.3, 0.8),
		"sphere": 0.3, "scale": Vector2(0.6, 1.3), "color": _hot_sparks(), "align": true, "keep_color": true, "lifetime_rand": 0.5})
	# 5. Debris chunks tumbling out.
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.12, 0.12, 0.13)
	metal.metallic = 0.6
	metal.roughness = 0.5
	var chunk := BoxMesh.new()
	chunk.size = Vector3(0.14, 0.07, 0.11)
	_emitter(r, "Debris", chunk, metal, 12, 1.3, {
		"direction": up, "spread": 65.0, "vel": Vector2(6, 12), "gravity": Vector3(0, -24, 0), "scale": Vector2(0.6, 1.4),
		"angular": Vector2(-600, 600), "keep_color": true})
	# 6. Ground shockwave ring and a dust skirt racing outward on the floor.
	_pulse_mesh(r, "Shockwave", _plane(Vector2(1, 1)), _mat(true, Shape.RING, 1.8, false, {"ring_width": 0.08}), {"life": 0.32, "scale_from": Vector3(1, 1, 1), "scale_to": Vector3(9, 1, 9), "ease_power": 2.2}, {"keep_color": false, "ground": true})
	_emitter(r, "DustSkirt", _quad(Vector2(0.9, 0.9)), _mat(false, Shape.PUFF, 1.0, true, {"erosion": 0.7}), 20, 1.0, {
		"direction": Vector3(1, 0, 0), "spread": 180.0, "flat": true, "vel": Vector2(5, 9), "damping": Vector2(5, 7),
		"gravity": Vector3(0, 0.3, 0), "box": Vector3(0.6, 0.05, 0.6), "scale_curve": _curve([[0.0, 0.6], [1.0, 2.0]]),
		"angle": Vector2(0, 360), "keep_color": true, "ground": true,
		"color": _grad([[0.0, Color(0.45, 0.4, 0.35, 0.5)], [1.0, Color(0.45, 0.4, 0.35, 0)]])})
	# 7. Light: a hard orange pop that dies fast.
	_light(r, "Light", Color(1, 0.6, 0.25), 5.0, 11.0, 0.4, Vector3(0, 1.0, 0))
	_save(r)
