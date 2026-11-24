class_name FX
extends Node3D
## Game-feel hub. Gameplay code reports events here ("enemy hit", "enemy killed",
## "player hit"...) and this node decides how hard to juice them: particles,
## damage numbers, hitstop, and camera shake. All intensities are exported.

@export var death_burst_scene: PackedScene = preload("res://scenes/death_burst.tscn")
@export var hit_spark_scene: PackedScene = preload("res://scenes/hit_spark.tscn")
@export var damage_number_scene: PackedScene = preload("res://scenes/damage_number.tscn")

@export_group("Pools")
@export var burst_pool_size := 48
@export var spark_pool_size := 48
@export var number_pool_size := 80

@export_group("Hitstop")
@export var hitstop_on_kill := 0.045
@export var hitstop_on_player_hit := 0.14
@export var hitstop_on_player_death := 0.35
@export_range(0.0, 1.0) var hitstop_time_scale := 0.03
## Minimum real seconds between kill hitstops, so a mass kill doesn't stall the game.
@export var hitstop_kill_cooldown := 0.12

@export_group("Camera shake")
@export var shake_on_shot := 0.035
@export var shake_on_hit := 0.07
@export var shake_on_kill := 0.2
@export var shake_on_player_hit := 0.65
@export var shake_on_dash := 0.12
@export var shake_on_land := 0.0

@export_group("Damage numbers")
@export var damage_numbers_enabled := true
@export var number_color := Color("f2f6f8")
@export var kill_number_color := Color("ffe23d")
@export var number_scale := 1.0

@export_group("Explosions & telegraphs")
@export var explosion_light_energy := 7.0
@export var explosion_light_range := 9.0
@export var burrow_color := Color("9dff2e")
@export var drop_color := Color("ff3b4b")

@export_group("Colors")
@export var shot_spark_color := Color("19f4ff")
@export var wall_spark_color := Color("9ff8ff")
@export var player_hit_color := Color("ff2b6b")

var _bursts: Array[DeathBurst] = []
var _sparks: Array[HitSpark] = []
var _numbers: Array[DamageNumber] = []
var _burst_i := 0
var _spark_i := 0
var _number_i := 0
var _last_kill_stop_usec := 0
var _last_block_usec := 0
var _lights: Array[OmniLight3D] = []
var _light_t: Array[float] = []
var _light_i := 0
var _tele: Array[Dictionary] = []
var _tele_i := 0
var _last_status_usec := 0
var _bolts: Array = []
var _bolt_t: Array[float] = []
var _bolt_i := 0
var _merge := {}
var _beams: Array[MeshInstance3D] = []
var _beam_t: Array[float] = []
var _beam_i := 0
var _splats: Array[MeshInstance3D] = []
var _splat_t: Array[float] = []
var _splat_i := 0
var _corpses: Array[Node3D] = []
var _corpse_state: Array[Dictionary] = []
var _corpse_i := 0
var _beam_ray := PhysicsRayQueryParameters3D.new()
const SPLAT_LIFE := 12.0
const CORPSE_LIFE := 4.5
@export_group("Gore and trails")
@export var splats_enabled := true
@export var corpses_enabled := true
@export var splat_pool_size := 64
@export var corpse_pool_size := 24


func _ready() -> void:
	Game.fx = self
	for i in burst_pool_size:
		var b: DeathBurst = death_burst_scene.instantiate()
		add_child(b)
		_bursts.append(b)
	for i in spark_pool_size:
		var s: HitSpark = hit_spark_scene.instantiate()
		add_child(s)
		_sparks.append(s)
	for i in number_pool_size:
		var n: DamageNumber = damage_number_scene.instantiate()
		add_child(n)
		_numbers.append(n)
	for i in 6:
		var l := OmniLight3D.new()
		l.light_color = Color("ff9a3d")
		l.omni_range = explosion_light_range
		l.light_energy = 0.0
		l.visible = false
		add_child(l)
		_lights.append(l)
		_light_t.append(0.0)
	_build_telegraphs()
	_build_bolts()
	_build_beams()
	_build_splats()
	_build_corpses()


# --------------------------------------------------------------------------
# Events
# --------------------------------------------------------------------------

func on_player_shot(amount := -1.0) -> void:
	Game.shake(shake_on_shot if amount < 0.0 else amount)


func on_player_dash(_pos: Vector3) -> void:
	Game.shake(shake_on_dash)


## Two layers: sparks in the bolt's colour back toward the shooter, and an
## ichor spray in the bug's colour out the far side.
func on_projectile_hit(pos: Vector3, direction: Vector3, bolt_color := Color(0, 0, 0, 0), ichor := Color(0, 0, 0, 0)) -> void:
	spark(pos, bolt_color if bolt_color.a > 0.0 else shot_spark_color, -direction)
	if ichor.a > 0.0:
		spark(pos, ichor, direction + Vector3.UP * 0.4)


func on_wall_hit(pos: Vector3, normal: Vector3) -> void:
	spark(pos, wall_spark_color, normal)


func on_enemy_hit(pos: Vector3, damage: float, killed: bool, kind: StringName = &"bullet", src_id := 0) -> void:
	Game.shake(shake_on_hit)
	if not damage_numbers_enabled:
		return
	# Plain hits on the same bug in quick succession add up in one number
	# instead of stacking a column of them (crits, counters, kills pop their own).
	var plain := kind == &"bullet" or kind == &"slash" or kind == &"burn"
	if src_id != 0 and plain and not killed:
		var now_m := Time.get_ticks_usec()
		var rec: Dictionary = _merge.get(src_id, {})
		if not rec.is_empty() and now_m - int(rec.t) < 350_000 and (rec.n as DamageNumber).is_showing():
			rec.total = float(rec.total) + damage
			rec.t = now_m
			(rec.n as DamageNumber).bump(str(roundi(rec.total)), number_scale * minf(1.0 + float(rec.total) / 150.0, 1.6))
			return
		_merge[src_id] = {"n": _numbers[_number_i], "total": damage, "t": now_m}
		if _merge.size() > 200:
			_merge.clear()
	var col := kill_number_color if killed else number_color
	var s := number_scale * (1.35 if killed else 1.0)
	var text := str(roundi(damage))
	match kind:
		&"crit", &"slash_crit":
			col = Color("ffb21e")
			s *= 1.4
			text += "!"
		&"counter":
			col = Color("ff2bd6")
			s *= 1.7
			text += "!"
		&"burn":
			col = Color("ff7a1a")
			s *= 0.75
		&"shock":
			col = Color("9fe8ff")
			s *= 0.9
	damage_number(pos + Vector3(randf_range(-0.3, 0.3), 1.1, randf_range(-0.2, 0.2)), text, col, s)


## Small coloured pop + label when a status effect lands (label rate-limited).
func status_pop(pos: Vector3, kind: StringName) -> void:
	var c: Color = {&"burn": Color("ff7a1a"), &"cryo": Color("9fe8ff"), &"corrode": Color("b6ff3d")}.get(kind, Color.WHITE)
	spark(pos, c, Vector3.UP)
	var now := Time.get_ticks_usec()
	if now - _last_status_usec > 400000:
		_last_status_usec = now
		var label: String = {&"burn": "BURN", &"cryo": "CHILLED", &"corrode": "CORRODED"}.get(kind, "")
		if label != "":
			text_popup(pos + Vector3.UP * 0.5, label, c, 0.7)


## Shock arc between two points (pooled, flickers out in ~0.15 s).
func lightning(a: Vector3, b: Vector3) -> void:
	var idx := _bolt_i
	var l: Array = _bolts[idx]
	_bolt_i = (_bolt_i + 1) % _bolts.size()
	var mid := (a + b) * 0.5 + Vector3(randf_range(-0.3, 0.3), randf_range(0.0, 0.4), randf_range(-0.3, 0.3))
	for k in 2:
		var seg: MeshInstance3D = l[k]
		var p0 := a if k == 0 else mid
		var p1 := mid if k == 0 else b
		seg.global_position = (p0 + p1) * 0.5
		if p0.distance_to(p1) > 0.01 and absf((p1 - p0).normalized().dot(Vector3.UP)) < 0.99:
			seg.look_at(p1, Vector3.UP)
		seg.scale = Vector3(1, 1, maxf(p0.distance_to(p1), 0.01))
		seg.visible = true
	_bolt_t[idx] = 0.15


func on_enemy_killed(pos: Vector3, direction: Vector3, tier := 0, silent := false, kind: StringName = &"") -> void:
	if silent:
		burst(pos, direction, 0.6, Color("19f4ff"))
		text_popup(pos + Vector3.UP * 1.4, "SILENT KILL", Color("19f4ff"), 0.9)
		return
	var size := 1.0 + tier * 0.35
	var ring: Color = Enemy.TIER_COLORS[tier] if tier > 0 else Color(0, 0, 0, 0)
	burst(pos, direction, size, ring)
	Game.shake(shake_on_kill * (1.0 + tier * 0.5))
	# Tiered hitstop: fodder dying to gunfire never freezes the world (swarms stay
	# smooth); tougher kills land with weight. Blade hits and counters already
	# freeze on impact in Player._swing.
	var stop := 0.0
	if tier > 0:
		stop = hitstop_on_kill * [0.0, 0.7, 1.2, 2.4][tier]
	elif kind == &"explosion":
		stop = hitstop_on_kill * 0.5
	var now := Time.get_ticks_usec()
	if stop > 0.0 and now - _last_kill_stop_usec >= int(hitstop_kill_cooldown * 1_000_000.0):
		_last_kill_stop_usec = now
		Game.hitstop(stop, hitstop_time_scale)


func on_enemy_land(pos: Vector3, heavy: bool) -> void:
	if heavy:
		spark(pos + Vector3.UP * 0.1, Color("c9cfd4"), Vector3.UP)
		Game.shake(0.06)
	elif shake_on_land > 0.0:
		Game.shake(shake_on_land)


func on_blocked(pos: Vector3, direction: Vector3) -> void:
	# The blue spark carries it; the word is a rare reminder, not a stream.
	spark(pos, Color("3aa0ff"), -direction)
	spark(pos, Color("bfe0ff"), -direction + Vector3.UP * 0.5)
	var now := Time.get_ticks_usec()
	if now - _last_block_usec > 2_500_000:
		_last_block_usec = now
		text_popup(pos + Vector3.UP * 0.6, "BLOCKED", Color("6fb6ff"), 0.55)


## Big fiery blast with a light flash (barrels, bursters).
func explosion(pos: Vector3, size := 2.0) -> void:
	burst(pos, Vector3.ZERO, size, Color("ff8a1e"), true)
	burst(pos + Vector3.UP * 0.2, Vector3.ZERO, size * 0.35, Color("ffb050"), true)
	splat(Vector3(pos.x, 0.0, pos.z), Color(0.02, 0.015, 0.01, 0.85), size * 1.3)
	if Graphics.is_low():
		return  # point lights are the expensive part on weak GPUs
	var l := _lights[_light_i]
	_light_t[_light_i] = 0.3
	_light_i = (_light_i + 1) % _lights.size()
	l.global_position = pos + Vector3.UP * 1.0
	l.light_energy = explosion_light_energy
	l.visible = true


func text_popup(pos: Vector3, text: String, color: Color, scale_mult := 1.0) -> void:
	damage_number(pos, text, color, scale_mult)


## Ground warning before a spawn: pulsing green cracks (burrow) or a growing
## shadow with a red ring (drop from above).
func telegraph(mode: StringName, pos: Vector3, time: float, tier := 0) -> void:
	var t: Dictionary = _tele[_tele_i]
	_tele_i = (_tele_i + 1) % _tele.size()
	t.mode = mode
	t.total = time
	t.t = time
	var root: Node3D = t.root
	root.global_position = Vector3(pos.x, 0.03, pos.z)
	root.visible = true
	var c: Color = burrow_color if mode == &"burrow" else drop_color
	if tier > 0:
		c = Enemy.TIER_COLORS[tier]
	(t.ring_mat as ShaderMaterial).set_shader_parameter("tint", c)
	(t.shadow as Node3D).visible = mode == &"drop"


func _build_bolts() -> void:
	var m := BoxMesh.new()
	m.size = Vector3(0.06, 0.06, 1.0)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/shaders/neon_fade.gdshader")
	mat.set_shader_parameter("tint", Color("9fe8ff"))
	mat.set_shader_parameter("energy", 5.0)
	for i in 12:
		var pair: Array = []
		for k in 2:
			var mi := MeshInstance3D.new()
			mi.mesh = m
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.top_level = true
			mi.visible = false
			add_child(mi)
			pair.append(mi)
		_bolts.append(pair)
		_bolt_t.append(0.0)


func _build_telegraphs() -> void:
	var shader := preload("res://scripts/shaders/neon_fade.gdshader")
	var tm := TorusMesh.new()
	tm.inner_radius = 0.8
	tm.outer_radius = 1.0
	tm.rings = 32
	tm.ring_segments = 4
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	disc.radial_segments = 24
	for i in 32:
		var root := Node3D.new()
		root.top_level = true
		root.visible = false
		add_child(root)
		var ring := MeshInstance3D.new()
		ring.mesh = tm
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var rm := ShaderMaterial.new()
		rm.shader = shader
		rm.set_shader_parameter("energy", 3.0)
		ring.material_override = rm
		root.add_child(ring)
		var shadow := MeshInstance3D.new()
		shadow.mesh = disc
		shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0, 0, 0, 0.6)
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shadow.material_override = sm
		root.add_child(shadow)
		_tele.append({"root": root, "ring": ring, "ring_mat": rm, "shadow": shadow, "shadow_mat": sm, "t": 0.0, "total": 1.0, "mode": &"burrow"})


func _process(delta: float) -> void:
	_tick_trails(delta)
	for i in _bolts.size():
		if _bolt_t[i] > 0.0:
			_bolt_t[i] -= delta
			if _bolt_t[i] <= 0.0:
				for seg in _bolts[i]:
					seg.visible = false
	for i in _lights.size():
		if _light_t[i] > 0.0:
			_light_t[i] -= delta
			_lights[i].light_energy = explosion_light_energy * maxf(_light_t[i] / 0.3, 0.0)
			if _light_t[i] <= 0.0:
				_lights[i].visible = false
	for t in _tele:
		var root: Node3D = t.root
		if not root.visible:
			continue
		t.t -= delta
		if t.t <= 0.0:
			root.visible = false
			continue
		var k: float = 1.0 - t.t / t.total
		var ring: MeshInstance3D = t.ring
		if t.mode == &"burrow":
			var s := 0.5 + 0.5 * k
			ring.scale = Vector3(s, 0.3, s)
			(t.ring_mat as ShaderMaterial).set_shader_parameter("fade", 0.4 + 0.6 * absf(sin(k * 18.0)))
		else:
			var s := 1.3 - 0.6 * k
			ring.scale = Vector3(s, 0.3, s)
			(t.ring_mat as ShaderMaterial).set_shader_parameter("fade", 0.9)
			var shadow: MeshInstance3D = t.shadow
			shadow.scale = Vector3(0.2 + 0.6 * k, 1.0, 0.2 + 0.6 * k)
			(t.shadow_mat as StandardMaterial3D).albedo_color = Color(0, 0, 0, 0.25 + 0.45 * k)


func on_player_hit(pos: Vector3, _amount: float) -> void:
	Game.shake(shake_on_player_hit)
	Game.hitstop(hitstop_on_player_hit, hitstop_time_scale)
	for i in 3:
		spark(pos, player_hit_color, Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1)).normalized())


func on_player_death(pos: Vector3) -> void:
	Game.shake(1.0)
	Game.hitstop(hitstop_on_player_death, hitstop_time_scale)
	for i in 4:
		burst(pos + Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5)), Vector3.ZERO, 1.6)


# --------------------------------------------------------------------------
# Primitives
# --------------------------------------------------------------------------

func burst(pos: Vector3, direction := Vector3.ZERO, size := 1.0, ring_color := Color(0, 0, 0, 0), fire := false) -> void:
	var b := _bursts[_burst_i]
	_burst_i = (_burst_i + 1) % _bursts.size()
	b.play(pos, direction, size, ring_color, fire)


func spark(pos: Vector3, color: Color, normal := Vector3.UP) -> void:
	var s := _sparks[_spark_i]
	_spark_i = (_spark_i + 1) % _sparks.size()
	s.play(pos, color, normal)


func damage_number(pos: Vector3, text: String, color: Color, scale_mult := 1.0) -> void:
	var n := _numbers[_number_i]
	_number_i = (_number_i + 1) % _numbers.size()
	n.play(pos, text, color, scale_mult)


# --------------------------------------------------------------------------
# Rail beams, floor splats, corpses
# --------------------------------------------------------------------------

func _build_beams() -> void:
	var shader := preload("res://scripts/shaders/neon_fade.gdshader")
	for i in 6:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("energy", 4.0)
		m.set_shader_parameter("edge_softness", 0.4)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.16, 0.16, 1.0)
		mi.mesh = bm
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.top_level = true
		mi.visible = false
		add_child(mi)
		_beams.append(mi)
		_beam_t.append(0.0)
	_beam_ray.collision_mask = 1


## The Rail Lance's shot leaves a bright line hanging in the air for a moment,
## from the muzzle to the first wall (it pierces bugs).
func rail_beam(origin: Vector3, dir: Vector3, max_range: float, color: Color) -> void:
	_beam_ray.from = origin
	_beam_ray.to = origin + dir * max_range
	var hit := get_world_3d().direct_space_state.intersect_ray(_beam_ray)
	var end: Vector3 = _beam_ray.to if hit.is_empty() else hit.position
	var mi := _beams[_beam_i]
	_beam_t[_beam_i] = 0.28
	_beam_i = (_beam_i + 1) % _beams.size()
	var length := origin.distance_to(end)
	if length < 0.5:
		return
	mi.global_position = (origin + end) * 0.5
	mi.look_at(end, Vector3.UP)
	mi.scale = Vector3(1.0, 1.0, length)
	(mi.material_override as ShaderMaterial).set_shader_parameter("tint", color.lerp(Color.WHITE, 0.4))
	(mi.material_override as ShaderMaterial).set_shader_parameter("fade", 1.0)
	mi.visible = true


func _build_splats() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.add_point(0.55, Color(1, 1, 1, 0.85))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var pm := PlaneMesh.new()
	pm.size = Vector2(1, 1)
	for i in splat_pool_size:
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = tex
		m.roughness = 0.25
		m.metallic_specular = 0.8
		m.emission_enabled = true
		var mi := MeshInstance3D.new()
		mi.mesh = pm
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.top_level = true
		mi.visible = false
		add_child(mi)
		_splats.append(mi)
		_splat_t.append(0.0)


## A blot on the floor (ichor, scorch) that fades over a few seconds.
func splat(pos: Vector3, color: Color, size := 1.0) -> void:
	if not splats_enabled or _splats.is_empty():
		return
	var mi := _splats[_splat_i]
	_splat_t[_splat_i] = SPLAT_LIFE
	_splat_i = (_splat_i + 1) % _splats.size()
	mi.global_position = Vector3(pos.x, 0.02 + randf() * 0.01, pos.z)
	mi.rotation = Vector3(0, randf() * TAU, 0)
	var s := size * randf_range(0.8, 1.25)
	mi.scale = Vector3(s * randf_range(0.8, 1.3), 1.0, s)
	var m := mi.material_override as StandardMaterial3D
	m.albedo_color = color
	m.emission = color * 0.08
	mi.visible = true


func _build_corpses() -> void:
	var scene: PackedScene = load("res://assets/models/enemies/swarmer.glb")
	for i in corpse_pool_size:
		var c: Node3D = scene.instantiate()
		c.top_level = true
		c.visible = false
		add_child(c)
		var ap := c.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap:
			ap.stop()
		_corpses.append(c)
		_corpse_state.append({})


## Gore for a dead bug: an ichor splat under it, and (swarmers) a corpse flung
## along the killing blow that lands on its back, lies there, then sinks away.
func on_enemy_body(e: Enemy, direction: Vector3, kind: StringName) -> void:
	var pos := e.global_position
	var ichor := e.ichor_color
	splat(pos + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3)), Color(ichor.r * 0.55, ichor.g * 0.55, ichor.b * 0.4, 0.8), 1.1 * e._tier_scale)
	if not corpses_enabled or e.type_id != &"swarmer" or kind == &"silent" or _corpses.is_empty():
		return
	var c := _corpses[_corpse_i]
	var st := _corpse_state[_corpse_i]
	_corpse_i = (_corpse_i + 1) % _corpses.size()
	var push := Vector3(direction.x, 0.0, direction.z)
	push = push.normalized() if push.length_squared() > 0.001 else Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
	var power := 9.0 if kind in [&"explosion", &"counter"] else 5.5
	c.global_position = pos
	c.rotation = Vector3(0, e.visual.rotation.y, 0)
	c.scale = Vector3.ONE * e._tier_scale
	c.visible = true
	st.vel = push * power * randf_range(0.8, 1.2) + Vector3.UP * randf_range(3.5, 5.5)
	st.spin = Vector3(randf_range(6.0, 11.0), randf_range(-4.0, 4.0), randf_range(-3.0, 3.0))
	st.t = 0.0
	st.landed = false
	st.ichor = ichor


func _tick_trails(delta: float) -> void:
	for i in _beams.size():
		if _beam_t[i] > 0.0:
			_beam_t[i] -= delta
			var mi := _beams[i]
			var k := clampf(_beam_t[i] / 0.28, 0.0, 1.0)
			(mi.material_override as ShaderMaterial).set_shader_parameter("fade", k)
			mi.scale.x = lerpf(0.2, 1.4, k)
			mi.scale.y = mi.scale.x
			if _beam_t[i] <= 0.0:
				mi.visible = false
	for i in _splats.size():
		if _splat_t[i] > 0.0:
			_splat_t[i] -= delta
			if _splat_t[i] < 3.0:
				var m := _splats[i].material_override as StandardMaterial3D
				var c := m.albedo_color
				c.a = maxf(_splat_t[i] / 3.0, 0.0) * 0.85
				m.albedo_color = c
			if _splat_t[i] <= 0.0:
				_splats[i].visible = false
	for i in _corpses.size():
		var c := _corpses[i]
		if not c.visible:
			continue
		var st := _corpse_state[i]
		st.t = float(st.t) + delta
		if not st.landed:
			var v: Vector3 = st.vel
			v.y -= 22.0 * delta
			st.vel = v
			c.global_position += v * delta
			var spin: Vector3 = st.spin
			c.rotation += spin * delta
			if c.global_position.y <= 0.0 and v.y < 0.0:
				st.landed = true
				# Settle on its back, legs up (lifted so the shell rests on the deck).
				c.rotation = Vector3(PI, c.rotation.y, 0.0)
				c.global_position.y = 0.46 * c.scale.y
				splat(c.global_position, Color(st.ichor.r * 0.5, st.ichor.g * 0.5, st.ichor.b * 0.35, 0.75), 0.8)
		elif float(st.t) > CORPSE_LIFE:
			c.global_position.y -= delta * 0.6
			if float(st.t) > CORPSE_LIFE + 1.2:
				c.visible = false
