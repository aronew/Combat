extends Node3D
## VFX test arena: one room with every impact surface, the player, target bugs
## and hotkeys to fire each effect on its own or all together.
##   godot --path . res://scenes/test/vfx_arena.tscn     (or the Rig's contract board)
## Keys (shown on screen):
##   1  rifle muzzle demo burst on the stand       2  impacts on all four surfaces
##   3  explosion at the cursor (effect only)      G  throw a real grenade at the cursor
##   4  spawn a pack of bugs                       5  stress test (grenades + impacts)
##   T  slow motion x0.25                          K  clear bugs        F1 overlay
## The player is invincible here; everything else is the real game code.

const STAND_MUZZLE := Vector3(-8, 1.1, -6)
const STAND_IMPACTS := Vector3(4, 0.9, -8)

var _overlay: Label
var _slow := false
var _demo: Array = []  # [time, Callable]
var _t := 0.0
var _floor_mat: StandardMaterial3D


func _enter_tree() -> void:
	Game.reset_run()


func _ready() -> void:
	_build_room()
	if Game.player:
		Game.player.grant_invulnerability(1e9)
		Game.player.global_position = Vector3(0, 0, 6)
	_spawn_targets()
	_build_overlay()


# --------------------------------------------------------------------------
# Room
# --------------------------------------------------------------------------

func _build_room() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	add_child(body)
	_floor_mat = StandardMaterial3D.new()
	_floor_mat.albedo_color = Color(0.2, 0.22, 0.25)
	_floor_mat.roughness = 0.55
	_floor_mat.metallic = 0.3
	_box(body, Vector3(40, 1, 32), Vector3(0, -0.5, 0), _floor_mat)
	# Floor grid lines so motion and scale read.
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.12, 0.13, 0.15)
	for i in range(-10, 11):
		_mesh_box(Vector3(0.04, 0.01, 32), Vector3(i * 2.0, 0.005, 0), line_mat)
	for i in range(-8, 9):
		_mesh_box(Vector3(40, 0.01, 0.04), Vector3(0, 0.005, i * 2.0), line_mat)
	# Concrete walls: ENVIRONMENT surface.
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.42, 0.42, 0.44)
	_box(body, Vector3(40, 3, 1), Vector3(0, 1.5, -16.5), wall_mat)
	_box(body, Vector3(1, 3, 32), Vector3(-20.5, 1.5, 0), wall_mat)
	_box(body, Vector3(1, 3, 32), Vector3(20.5, 1.5, 0), wall_mat)
	_box(body, Vector3(6, 2.2, 1), Vector3(-4, 1.1, -11), wall_mat)
	# Metal crates: METAL surface.
	var metal := StaticBody3D.new()
	metal.collision_layer = 1
	metal.set_meta("surface", "metal")
	add_child(metal)
	var metal_mat := StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.35, 0.4, 0.45)
	metal_mat.metallic = 0.85
	metal_mat.roughness = 0.3
	for p in [Vector3(8, 0.8, -10), Vector3(10, 0.8, -10), Vector3(9, 2.4, -10), Vector3(12, 0.8, -3)]:
		_box(metal, Vector3(1.6, 1.6, 1.6), p, metal_mat)
	# Training dummies (metal) as a target line.
	var dummy_script := load("res://scripts/objects/training_dummy.gd")
	for i in 3:
		var d := StaticBody3D.new()
		d.set_script(dummy_script)
		add_child(d)
		d.global_position = Vector3(-12 + i * 2.5, 0, -4)
	# Labels on the floor so each zone is obvious.
	_floor_label("MUZZLE STAND  [1]", STAND_MUZZLE + Vector3(0, -1.08, 1.6))
	_floor_label("IMPACTS  [2]   organic · metal · shield · environment", STAND_IMPACTS + Vector3(1.5, -0.88, 2.2))
	_floor_label("METAL", Vector3(10, 0.02, -7.6))
	_floor_label("TRAINING DUMMIES (metal)", Vector3(-9.5, 0.02, -2.2))
	_floor_label("CONCRETE (environment)", Vector3(-4, 0.02, -9.8))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 6, -2)
	lamp.omni_range = 30.0
	lamp.light_energy = 0.8
	lamp.light_color = Color(0.85, 0.9, 1.0)
	add_child(lamp)


func _box(body: StaticBody3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = pos
	body.add_child(cs)
	_mesh_box(size, pos, mat)


func _mesh_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


func _floor_label(text: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.pixel_size = 0.01
	l.modulate = Color(1, 1, 1, 0.55)
	l.rotation_degrees = Vector3(-90, 45, 0)
	l.position = pos
	add_child(l)


func _spawn_targets() -> void:
	if Game.spawner == null:
		return
	for i in 5:
		Game.spawner.spawn_now(&"swarmer", &"dormant", Vector3(-3 + i * 1.6, 0, -4 - (i % 2) * 1.2), {})
	Game.spawner.spawn_now(&"shield", &"dormant", Vector3(5, 0, -3), {})


# --------------------------------------------------------------------------
# Hotkeys
# --------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1:
			demo_muzzle()
		KEY_2:
			demo_impacts()
		KEY_3:
			Game.fx.play_vfx(&"grenade_explosion", {"position": _cursor()})
		KEY_G:
			throw_grenade(_cursor())
		KEY_4:
			spawn_pack()
		KEY_5:
			stress()
		KEY_T:
			_slow = not _slow
			Engine.time_scale = 0.25 if _slow else 1.0
		KEY_K:
			for e in Game.spawner.active.duplicate():
				Game.spawner.release(e)
		KEY_F1:
			_overlay.visible = not _overlay.visible


func demo_muzzle() -> void:
	for i in 10:
		_later(i * 0.083, func(): Game.fx.play_vfx(&"rifle_muzzle", {"position": STAND_MUZZLE, "direction": Vector3(1, 0, 0), "color": Color("7ff8ff")}))


func demo_impacts() -> void:
	var kinds := [Surface.Kind.ORGANIC, Surface.Kind.METAL, Surface.Kind.SHIELD, Surface.Kind.ENVIRONMENT]
	for rep in 3:
		for i in kinds.size():
			var p := STAND_IMPACTS + Vector3(i * 1.6, 0, 0)
			var kind: int = kinds[i]
			_later(rep * 0.35 + i * 0.05, func(): Game.fx.impact(kind, p, Vector3(0, 0.3, 1).normalized(), Color("ffb03b") if kind == Surface.Kind.ORGANIC else Color(0, 0, 0, 0)))


func throw_grenade(target: Vector3) -> void:
	var g := VfxGrenade.new()
	add_child(g)
	var from := Game.player.global_position + Vector3.UP * 1.4 if Game.player else Vector3.UP
	g.throw(from, target)


func spawn_pack() -> void:
	var c := _cursor()
	for i in 10:
		var a := TAU * i / 10.0
		Game.spawner.spawn_now(&"swarmer", &"burrow", c + Vector3(cos(a), 0, sin(a)) * 3.0, {})
	Game.spawner.spawn_now(&"burster", &"burrow", c, {})


func stress() -> void:
	for i in 8:
		var p := Vector3(randf_range(-14, 14), 0.1, randf_range(-12, 4))
		_later(i * 0.15, func(): Game.fx.play_vfx(&"grenade_explosion", {"position": p}))
	for i in 60:
		var p2 := Vector3(randf_range(-14, 14), randf_range(0.3, 1.5), randf_range(-12, 4))
		var k: int = randi() % 4
		_later(i * 0.025, func(): Game.fx.impact(k, p2, Vector3(randf() - 0.5, 0.4, randf() - 0.5).normalized(), Color("ffb03b")))


func _later(delay: float, f: Callable) -> void:
	_demo.append([_t + delay, f])


func _cursor() -> Vector3:
	if Game.player:
		return Vector3(Game.player.aim_point.x, 0.0, Game.player.aim_point.z)
	return Vector3.ZERO


# --------------------------------------------------------------------------
# Overlay
# --------------------------------------------------------------------------

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_overlay = Label.new()
	_overlay.position = Vector2(16, 16)
	_overlay.add_theme_font_size_override("font_size", 15)
	_overlay.add_theme_color_override("font_outline_color", Color.BLACK)
	_overlay.add_theme_constant_override("outline_size", 6)
	layer.add_child(_overlay)


func _process(delta: float) -> void:
	_t += delta
	for i in range(_demo.size() - 1, -1, -1):
		if _t >= float(_demo[i][0]):
			var f: Callable = _demo[i][1]
			_demo.remove_at(i)
			f.call()
	if _overlay and _overlay.visible:
		var lines := ["VFX ARENA   [1] muzzle  [2] impacts  [3] explosion  [G] grenade  [4] bugs  [5] stress  [T] slow-mo  [K] clear  [F1] hide",
			"FPS %d   frame %.1f ms   draw calls %d   objects %d   bugs %d%s" % [Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
				Game.spawner.active.size() if Game.spawner else 0, "   SLOW-MO x0.25" if _slow else ""]]
		var total := 0
		if Game.fx:
			var st: Dictionary = Game.fx.vfx_stats()
			for k in st:
				lines.append("  %-20s %2d / %-2d busy   ~%d particles" % [k, st[k][0], st[k][1], st[k][2]])
				total += int(st[k][2])
		lines.append("  live particles ~%d" % total)
		_overlay.text = "\n".join(lines)
