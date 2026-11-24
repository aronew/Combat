class_name Player
extends CharacterBody3D
## Twin-stick mercenary: WASD (or left stick) to move, mouse (or right stick) to
## aim, LMB / right trigger to attack, Space / A / RB to roll, Q / Y / wheel to
## swap between the loud RIFLE and the quiet BLADE, E / X to interact.
## The blade's 3-hit combo silently kills unaware bugs and parries turret beams.

signal health_changed(current: float, maximum: float)
signal died

enum Weapon { RIFLE, BLADE }

@export_group("Movement")
@export var move_speed := 9.5
@export var acceleration := 85.0
@export var deceleration := 110.0
@export var turn_speed := 28.0

@export_group("Aim")
## Height of the plane the mouse ray is cast onto (0 = floor).
@export var aim_plane_height := 0.0
@export var stick_deadzone := 0.25

## Gun and blade numbers come from the equipped items (Profile -> Loot.GUNS /
## Loot.BLADES, scaled by item level, rarity, affixes and perks).
@export_group("Shooting")
@export var barrel_offset := 0.14

@export_group("Blade")
@export var blade_combo_window := 0.6
@export var blade_lunge := 7.0
@export var blade_knockback := 5.0
## Seconds after a swing during which turret beams from the front are reflected.
@export var parry_window := 0.25

@export_group("Dash")
@export var dash_speed := 30.0
@export var dash_duration := 0.15
@export var dash_cooldown := 0.8
@export var dash_invincibility_extra := 0.12
@export var dash_ghost_interval := 0.025

@export_group("Health")
@export var max_health := 100.0
@export var hurt_invincibility := 0.7
@export var hurt_knockback := 9.0

@onready var visual: Node3D = $Visual
@onready var muzzle: Marker3D = $Visual/Muzzle
@onready var muzzle_flash: MeshInstance3D = $Visual/MuzzleFlash
@onready var muzzle_light: OmniLight3D = $Visual/MuzzleLight

var health := 0.0
var alive := true
var aim_dir := Vector3.FORWARD
var aim_point := Vector3.ZERO

## True while a menu is open (hub panels): no movement, attacks or interaction.
var input_locked := false
## Set by DebugAutoplay to drive the player without input.
var autopilot := false
var auto_move := Vector2.ZERO
var auto_aim := Vector3.ZERO
var auto_fire := false
var auto_dash := false

var _fire_cd := 0.0
var _dash_t := 0.0
var _dash_cd := 0.0
var _dash_dir := Vector3.ZERO
var _ghost_t := 0.0
var _invuln := 0.0
var _hurt_t := 0.0
var _flash_t := 0.0
var _barrel := 1
var _knock := Vector3.ZERO
var _ghosts: Array[MeshInstance3D] = []
var _ghost_index := 0
var _ghost_mesh: Mesh

var weapon := Weapon.RIFLE
var current_interactable: Interactable
var auto_interact := false
var auto_weapon := -1
var _blade_cd := 0.0
var _combo_step := 0
var _combo_t := 0.0
var _parry_t := 0.0
var _slash_fx: MeshInstance3D
var _slash_mat: ShaderMaterial
var _slash_t := 0.0
var _arc_mesh: ArrayMesh
var _finisher_mesh: ArrayMesh
var _blade_node: Node3D

## Loadout from Profile: the stat sheet and resolved gun / blade numbers.
var stats := {}
var gun_item := {}
var blade_item := {}
var gun := {}
var blade := {}
var armor := 0.0
var stealth := 0.0
var _gun_payload := {}
var _elements := {}
var _base_max_health := 100.0
var _base_move_speed := 9.5
var _base_dash_cooldown := 0.8
var _regen := 0.0
var _regen_emit_t := 0.0
var _since_hurt := 99.0
var _bulwark_t := 0.0
var _adrenal_stacks := 0
var _adrenal_t := 0.0
var _shot_count := 0
var _blade_mat: StandardMaterial3D
var blade_damage := 26.0
var blade_finisher_damage := 48.0
var blade_range := 2.5
var blade_arc_degrees := 140.0
var blade_finisher_arc_degrees := 230.0
var blade_cooldown := 0.24


func _ready() -> void:
	Game.player = self
	_base_max_health = max_health
	_base_move_speed = move_speed
	_base_dash_cooldown = dash_cooldown
	load_loadout()
	health = max_health
	muzzle_flash.visible = false
	muzzle_light.light_energy = 0.0
	_ghost_mesh = ($Visual/Body as MeshInstance3D).mesh
	_build_ghosts()
	_build_blade()
	_apply_weapon_visuals()
	health_changed.emit(health, max_health)
	Game.player_health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_fire_cd = maxf(_fire_cd - delta, 0.0)
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_blade_cd = maxf(_blade_cd - delta, 0.0)
	_parry_t = maxf(_parry_t - delta, 0.0)
	_combo_t = maxf(_combo_t - delta, 0.0)
	_tick_buffs(delta)
	_update_weapon_input()
	_update_interact()

	_update_aim()

	var input := _read_move_input()
	var wish := Vector3(input.x, 0.0, input.y)
	if Game.camera_rig:
		wish = Game.camera_rig.get_flat_basis() * wish

	if _wants_dash() and _dash_cd <= 0.0 and _dash_t <= 0.0:
		_start_dash(wish)

	if _dash_t > 0.0:
		_dash_t -= delta
		velocity = _dash_dir * dash_speed * (1.4 if Profile.has_legendary("phase_step") else 1.0)
		_ghost_t -= delta
		if _ghost_t <= 0.0:
			_ghost_t = dash_ghost_interval
			_spawn_ghost()
		if _dash_t <= 0.0:
			velocity = _dash_dir * current_move_speed()
			if Profile.has_legendary("phase_step"):
				_cryo_burst()
	else:
		var target := wish * current_move_speed()
		var rate := acceleration if wish.length_squared() > 0.01 else deceleration
		velocity = velocity.move_toward(target, rate * delta)

	velocity += _knock
	_knock = _knock.move_toward(Vector3.ZERO, 60.0 * delta)
	velocity.y = 0.0
	move_and_slide()
	velocity -= _knock
	global_position.y = 0.0

	_update_facing(delta)
	if weapon == Weapon.RIFLE:
		_update_shooting()
	else:
		_update_blade()


func _process(delta: float) -> void:
	_update_ghosts(delta)
	if _slash_t > 0.0:
		_slash_t -= delta
		_slash_mat.set_shader_parameter("fade", clampf(_slash_t / 0.16, 0.0, 1.0))
		_slash_fx.visible = _slash_t > 0.0
	if _flash_t > 0.0:
		_flash_t -= delta
		muzzle_flash.visible = _flash_t > 0.0
		muzzle_light.light_energy = 3.0 if _flash_t > 0.0 else 0.0
	# Blink while invincible after taking damage.
	if _hurt_t > 0.0 and alive:
		_hurt_t -= delta
		visual.visible = _hurt_t <= 0.0 or fmod(_hurt_t, 0.1) > 0.04
	elif alive:
		visual.visible = true


# --------------------------------------------------------------------------
# Input
# --------------------------------------------------------------------------

func _read_move_input() -> Vector2:
	if input_locked:
		return Vector2.ZERO
	if autopilot:
		return auto_move.limit_length(1.0)
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _wants_dash() -> bool:
	if input_locked:
		return false
	if autopilot:
		var d := auto_dash
		auto_dash = false
		return d
	return Input.is_action_just_pressed("dash")


func _wants_fire() -> bool:
	if input_locked:
		return false
	return auto_fire if autopilot else Input.is_action_pressed("fire")


func _update_aim() -> void:
	var flat_pos := Vector3(global_position.x, 0.0, global_position.z)
	if autopilot:
		aim_point = auto_aim
	else:
		var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
		if stick.length() > stick_deadzone:
			var dir := Vector3(stick.x, 0.0, stick.y)
			if Game.camera_rig:
				dir = Game.camera_rig.get_flat_basis() * dir
			aim_point = flat_pos + dir.normalized() * 8.0
		elif Game.camera_rig:
			var cam := Game.camera_rig.camera
			var mouse := get_viewport().get_mouse_position()
			var origin := cam.project_ray_origin(mouse)
			var normal := cam.project_ray_normal(mouse)
			var plane := Plane(Vector3.UP, aim_plane_height)
			var hit = plane.intersects_ray(origin, normal)
			if hit != null:
				aim_point = hit
	var to := aim_point - flat_pos
	to.y = 0.0
	if to.length_squared() > 0.04:
		aim_dir = to.normalized()


## Used by the camera for look-ahead: aim direction scaled by how far you aim.
func get_aim_offset() -> Vector3:
	var flat := Vector3(global_position.x, 0.0, global_position.z)
	var dist := Vector2(aim_point.x - flat.x, aim_point.z - flat.z).length()
	return aim_dir * clampf(dist / 10.0, 0.0, 1.0)


func _update_facing(delta: float) -> void:
	var target_yaw := atan2(-aim_dir.x, -aim_dir.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))


# --------------------------------------------------------------------------
# Shooting
# --------------------------------------------------------------------------

func _update_shooting() -> void:
	if not _wants_fire() or _fire_cd > 0.0 or _dash_t > 0.0:
		return
	_fire_cd = 1.0 / (float(gun.fire_rate) * (1.0 + 0.08 * _adrenal_stacks))
	_barrel = -_barrel
	var side := aim_dir.cross(Vector3.UP).normalized()
	var origin := muzzle.global_position + side * barrel_offset * _barrel
	var pellets := int(gun.pellets)
	var spread: float = gun.spread
	if Game.projectiles:
		for i in pellets:
			var dir := aim_dir.rotated(Vector3.UP, deg_to_rad(randf_range(-spread, spread)))
			var spd: float = gun.speed * (randf_range(0.9, 1.06) if pellets > 1 else 1.0)
			Game.projectiles.fire(origin, dir, spd, gun.lifetime, _gun_payload)
		_shot_count += 1
		if Profile.has_legendary("overclock") and _shot_count % 8 == 0:
			var rail := _gun_payload.duplicate()
			rail.damage = float(gun.damage) * 3.0
			rail.pierce = 5
			rail.blast = 0.0
			rail.color = Color("e6f6ff")
			rail.scale = 2.2
			Game.projectiles.fire(origin, aim_dir, 110.0, 0.5, rail)
	_flash_t = 0.045
	muzzle_flash.visible = true
	muzzle_flash.rotation.z = randf() * TAU
	muzzle_light.light_energy = 3.0
	if Game.fx:
		Game.fx.on_player_shot(gun.shake)
	if Game.director:
		var noise: float = gun.noise
		Game.director.make_noise(global_position, Game.director.gun_noise_radius * clampf(noise, 0.4, 1.6), Game.director.gun_noise_alert * noise)


# --------------------------------------------------------------------------
# Weapons, blade, interaction
# --------------------------------------------------------------------------

func _update_weapon_input() -> void:
	if autopilot:
		if auto_weapon >= 0 and auto_weapon != weapon:
			set_weapon(auto_weapon)
		return
	if not input_locked and Input.is_action_just_pressed("swap_weapon"):
		set_weapon(Weapon.BLADE if weapon == Weapon.RIFLE else Weapon.RIFLE)


func _unhandled_input(event: InputEvent) -> void:
	if not alive or autopilot:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_weapon(Weapon.BLADE if weapon == Weapon.RIFLE else Weapon.RIFLE)


func set_weapon(w: int) -> void:
	if w == weapon:
		return
	weapon = w
	_combo_step = 0
	_apply_weapon_visuals()
	Game.weapon_changed.emit(weapon)


func _apply_weapon_visuals() -> void:
	$Visual/Gun.visible = weapon == Weapon.RIFLE
	if _blade_node:
		_blade_node.visible = weapon == Weapon.BLADE


func _update_blade() -> void:
	if _dash_t > 0.0 or _blade_cd > 0.0:
		return
	var wants := _wants_fire()
	if wants:
		_blade_attack()


func _blade_attack() -> void:
	_combo_step = (_combo_step % 3) + 1 if _combo_t > 0.0 else 1
	_combo_t = blade_combo_window
	var finisher := _combo_step == 3
	_blade_cd = blade_cooldown * (1.5 if finisher else 1.0)
	_parry_t = parry_window
	var arc := blade_finisher_arc_degrees if finisher else blade_arc_degrees
	var reach := blade_range * (1.15 if finisher else 1.0)
	var dmg := blade_finisher_damage if finisher else blade_damage
	_knock += aim_dir * blade_lunge * (1.4 if finisher else 1.0)
	_show_slash(finisher)

	var cos_half := cos(deg_to_rad(arc * 0.5))
	var hits := 0
	if Game.spawner:
		for e in Game.spawner.enemies_in_radius(global_position, reach):
			var to := e.global_position - global_position
			to.y = 0.0
			var d := to.length()
			var dir := to / d if d > 0.01 else aim_dir
			if d > 0.5 and aim_dir.dot(dir) < cos_half:
				continue
			if e.can_be_assassinated(global_position - e.global_position):
				e.assassinate(dir, dmg)
			else:
				var crit := randf() < float(blade.get("crit_chance", 0.05))
				var d_hit := dmg * (float(blade.get("crit_mult", 1.5)) if crit else 1.0)
				var dealt := e.take_hit(d_hit, dir, blade_knockback * (1.6 if finisher else 1.0), Game.TEAM_PLAYER, &"slash_crit" if crit else &"slash")
				if dealt > 0.0 and e.is_active():
					_blade_elements(e, dealt)
			hits += 1
	for t in Game.damageables.duplicate():
		if not is_instance_valid(t) or not t.is_alive():
			continue
		var to2: Vector3 = t.global_position - global_position
		to2.y = 0.0
		if to2.length() <= reach + t.hit_radius and (to2.length() < 0.5 or aim_dir.dot(to2.normalized()) >= cos_half):
			t.take_hit(dmg, to2.normalized(), 0.0, Game.TEAM_PLAYER, &"slash")
			hits += 1
	if hits > 0:
		Game.hitstop(0.03 if not finisher else 0.06)
		Game.shake(0.08 if not finisher else 0.2)
		if Game.director:
			Game.director.make_noise(global_position, Game.director.blade_noise_radius, Game.director.blade_noise_alert)


## True while a recent swing faces `source` (used by turrets to reflect beams).
func is_parrying_toward(source: Vector3) -> bool:
	if _parry_t <= 0.0 or weapon != Weapon.BLADE:
		return false
	var to := source - global_position
	to.y = 0.0
	return to.length_squared() > 0.01 and aim_dir.dot(to.normalized()) > 0.5


func _show_slash(finisher: bool) -> void:
	_slash_fx.mesh = _finisher_mesh if finisher else _arc_mesh
	_slash_fx.global_position = global_position + Vector3.UP * 1.0
	_slash_fx.rotation = Vector3(0.0, atan2(-aim_dir.x, -aim_dir.z), 0.0)
	_slash_fx.scale = Vector3(-1.0 if _combo_step == 2 else 1.0, 1.0, 1.0)
	var base_c := Color(blade.get("color", "19f4ff"))
	var c := Color("ff2bd6") if finisher else (base_c if _combo_step == 1 else base_c.lightened(0.35))
	_slash_mat.set_shader_parameter("tint", c)
	_slash_mat.set_shader_parameter("fade", 1.0)
	_slash_fx.visible = true
	_slash_t = 0.16


func _build_blade() -> void:
	var blade_mat := StandardMaterial3D.new()
	_blade_mat = blade_mat
	blade_mat.albedo_color = Color(0.1, 0.3, 0.35)
	blade_mat.emission_enabled = true
	blade_mat.emission = Color(blade.get("color", "19f4ff"))
	blade_mat.emission_energy_multiplier = 4.0
	var hilt_mat := StandardMaterial3D.new()
	hilt_mat.albedo_color = Color("1c1f23")
	_blade_node = Node3D.new()
	_blade_node.position = Vector3(0.38, 1.05, -0.35)
	_blade_node.rotation_degrees = Vector3(-70, 0, 0)
	visual.add_child(_blade_node)
	var blade := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.06, 1.1, 0.02)
	blade.mesh = bm
	blade.material_override = blade_mat
	blade.position = Vector3(0, 0.62, 0)
	_blade_node.add_child(blade)
	var hilt := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.08, 0.22, 0.08)
	hilt.mesh = hm
	hilt.material_override = hilt_mat
	_blade_node.add_child(hilt)

	_arc_mesh = _make_arc(blade_range, blade_arc_degrees)
	_finisher_mesh = _make_arc(blade_range * 1.15, blade_finisher_arc_degrees)
	_slash_mat = ShaderMaterial.new()
	_slash_mat.shader = preload("res://scripts/shaders/neon_fade.gdshader")
	_slash_mat.set_shader_parameter("energy", 3.5)
	_slash_mat.set_shader_parameter("edge_softness", 0.0)
	_slash_fx = MeshInstance3D.new()
	_slash_fx.material_override = _slash_mat
	_slash_fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_slash_fx.top_level = true
	_slash_fx.visible = false
	add_child(_slash_fx)


## Flat crescent in front of the player (-Z), thicker in the middle.
func _make_arc(reach: float, arc_deg: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 24
	var half := deg_to_rad(arc_deg * 0.5)
	for i in steps:
		var a0 := lerpf(-half, half, float(i) / steps)
		var a1 := lerpf(-half, half, float(i + 1) / steps)
		var w0 := 0.35 + 0.65 * sin(PI * float(i) / steps)
		var w1 := 0.35 + 0.65 * sin(PI * float(i + 1) / steps)
		var o0 := Vector3(sin(a0), 0, -cos(a0)) * reach
		var o1 := Vector3(sin(a1), 0, -cos(a1)) * reach
		var n0 := Vector3(sin(a0), 0, -cos(a0)) * (reach - 0.8 * w0)
		var n1 := Vector3(sin(a1), 0, -cos(a1)) * (reach - 0.8 * w1)
		for v in [n0, o0, o1, n0, o1, n1]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()


func _update_interact() -> void:
	var best: Interactable = null
	var best_d := INF
	for it in Game.interactables:
		var d := Vector2(it.global_position.x - global_position.x, it.global_position.z - global_position.z).length()
		if d <= it.radius and d < best_d:
			best = it
			best_d = d
	current_interactable = best
	if best == null or not best.enabled:
		return
	var pressed := auto_interact if autopilot else (Input.is_action_just_pressed("interact") and not input_locked)
	if pressed:
		auto_interact = false
		best.use(self)


# --------------------------------------------------------------------------
# Loadout (gear + perks from Profile)
# --------------------------------------------------------------------------

## Re-reads equipped gear and perks. Called at spawn and whenever the Profile
## changes (equipping at the Rig updates you live).
func load_loadout() -> void:
	var health_ratio := health / max_health if max_health > 0.0 and health > 0.0 else 1.0
	stats = Profile.stats()
	gun_item = Profile.equipped("gun")
	blade_item = Profile.equipped("blade")
	gun = Loot.gun_profile(gun_item, stats)
	blade = Loot.blade_profile(blade_item, stats)
	max_health = _base_max_health + float(stats.get("max_health", 0.0))
	armor = stats.get("armor", 0.0)
	stealth = stats.get("stealth", 0.0)
	_regen = stats.get("regen", 0.0)
	dash_cooldown = _base_dash_cooldown * (1.0 + float(stats.get("roll_cd", 0.0)))
	blade_damage = blade.damage
	blade_finisher_damage = blade.finisher
	blade_range = blade.range
	blade_arc_degrees = blade.arc
	blade_finisher_arc_degrees = blade.finisher_arc
	blade_cooldown = blade.cooldown
	_elements = {}
	for el in Loot.ELEMENTS:
		if float(stats.get(el, 0.0)) > 0.0:
			_elements[el] = stats[el]
	_gun_payload = {
		"damage": gun.damage, "knockback": gun.knockback, "pierce": gun.pierce, "crit_chance": gun.crit_chance,
		"crit_mult": gun.crit_mult, "blast": gun.blast, "elements": _elements, "element_power": 0.0,
		"splitter": Profile.has_legendary("splitter"), "generation": 0, "color": Color(gun.color), "scale": gun.bolt,
	}
	if health > 0.0:
		health = max_health * health_ratio
	if _slash_fx:
		_arc_mesh = _make_arc(blade_range, blade_arc_degrees)
		_finisher_mesh = _make_arc(blade_range * 1.15, blade_finisher_arc_degrees)
	if _blade_mat:
		_blade_mat.emission = Color(blade.color)
	if not Profile.changed.is_connected(load_loadout):
		Profile.changed.connect(load_loadout)
	Game.player_health_changed.emit(health, max_health)
	Game.weapon_changed.emit(weapon)


func current_move_speed() -> float:
	return _base_move_speed * (1.0 + float(stats.get("move_speed", 0.0)) + 0.08 * _adrenal_stacks)


func get_gun_name() -> String:
	return gun_item.get("name", "Rifle")


func get_blade_name() -> String:
	return blade_item.get("name", "Blade")


func _tick_buffs(delta: float) -> void:
	_since_hurt += delta
	_bulwark_t = maxf(_bulwark_t - delta, 0.0)
	if _adrenal_t > 0.0:
		_adrenal_t -= delta
		if _adrenal_t <= 0.0:
			_adrenal_stacks = 0
	if _regen > 0.0 and _since_hurt > 4.0 and health < max_health:
		health = minf(health + _regen * delta, max_health)
		_regen_emit_t -= delta
		if _regen_emit_t <= 0.0:
			_regen_emit_t = 0.25
			Game.player_health_changed.emit(health, max_health)


## Legendary and perk procs on any kill you caused.
func on_kill(_e: Enemy, pos: Vector3, kind: StringName) -> void:
	if not kind in [&"bullet", &"crit", &"slash", &"slash_crit", &"silent", &"burn", &"shock", &"reflect"]:
		return
	if Profile.has_legendary("chain_reaction") and kind != &"silent" and randf() < 0.35:
		Game.delayed_explode(0.08, pos + Vector3.UP * 0.4, 2.6, float(gun.damage) * 1.5, 0.0, 9.0, null, 1.6)
	if Profile.has_legendary("reaper") and kind in [&"slash", &"slash_crit", &"silent"]:
		health = minf(health + 4.0, max_health)
		_dash_cd = 0.0
		Game.player_health_changed.emit(health, max_health)
	if Profile.has_legendary("adrenal"):
		_adrenal_stacks = mini(_adrenal_stacks + 1, 5)
		_adrenal_t = 3.0


func _blade_elements(e: Enemy, dealt: float) -> void:
	if randf() < float(_elements.get("burn", 0.0)):
		e.apply_status(&"burn", dealt * 0.6)
	if randf() < float(_elements.get("cryo", 0.0)):
		e.apply_status(&"cryo", 1.0)
	if randf() < float(_elements.get("corrode", 0.0)):
		e.apply_status(&"corrode", 1.0)
	if randf() < float(_elements.get("shock", 0.0)):
		Game.shock_chain(e, dealt * 0.6, 2)


## Phase Step legendary: chill everything near where the roll ends.
func _cryo_burst() -> void:
	if Game.fx:
		Game.fx.burst(global_position + Vector3.UP * 0.4, Vector3.ZERO, 0.8, Color("9fe8ff"))
	if Game.spawner:
		for e in Game.spawner.enemies_in_radius(global_position, 3.5):
			e.apply_status(&"cryo", 1.0)


# --------------------------------------------------------------------------
# Dash
# --------------------------------------------------------------------------

func _start_dash(wish: Vector3) -> void:
	_dash_dir = wish.normalized() if wish.length_squared() > 0.01 else aim_dir
	_dash_t = dash_duration
	_dash_cd = dash_cooldown
	_invuln = maxf(_invuln, dash_duration + dash_invincibility_extra)
	_ghost_t = 0.0
	if Profile.has_legendary("bulwark"):
		_bulwark_t = dash_duration + 1.5
	if Game.fx:
		Game.fx.on_player_dash(global_position)


func is_dashing() -> bool:
	return _dash_t > 0.0


## 0 = just used, 1 = ready.
func get_dash_ready_ratio() -> float:
	return 1.0 - (_dash_cd / dash_cooldown) if dash_cooldown > 0.0 else 1.0


func get_dash_cooldown_left() -> float:
	return _dash_cd


func _build_ghosts() -> void:
	var shader := preload("res://scripts/shaders/neon_fade.gdshader")
	for i in 8:
		var g := MeshInstance3D.new()
		g.mesh = _ghost_mesh
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("tint", Palette.NEON_CYAN)
		m.set_shader_parameter("energy", 1.6)
		m.set_shader_parameter("edge_softness", 0.6)
		g.material_override = m
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.top_level = true
		g.visible = false
		g.set_meta("life", 0.0)
		add_child(g)
		_ghosts.append(g)


func _spawn_ghost() -> void:
	var g := _ghosts[_ghost_index]
	_ghost_index = (_ghost_index + 1) % _ghosts.size()
	g.global_transform = ($Visual/Body as Node3D).global_transform
	g.visible = true
	g.set_meta("life", 0.22)


func _update_ghosts(delta: float) -> void:
	for g in _ghosts:
		if not g.visible:
			continue
		var life: float = g.get_meta("life") - delta
		g.set_meta("life", life)
		if life <= 0.0:
			g.visible = false
		else:
			(g.material_override as ShaderMaterial).set_shader_parameter("fade", life / 0.22 * 0.7)


# --------------------------------------------------------------------------
# Damage
# --------------------------------------------------------------------------

func is_invincible() -> bool:
	return _invuln > 0.0 or not alive


## Returns true if the hit landed.
func take_damage(amount: float, from_position: Vector3) -> bool:
	if is_invincible():
		return false
	amount *= 1.0 - armor
	if _bulwark_t > 0.0:
		amount *= 0.5
	_since_hurt = 0.0
	health = maxf(health - amount, 0.0)
	_invuln = hurt_invincibility
	_hurt_t = hurt_invincibility
	var away := global_position - from_position
	away.y = 0.0
	if away.length_squared() > 0.001:
		_knock = away.normalized() * hurt_knockback
	health_changed.emit(health, max_health)
	Game.player_health_changed.emit(health, max_health)
	Game.player_damaged.emit(amount)
	if Game.fx:
		Game.fx.on_player_hit(global_position + Vector3.UP, amount)
	if health <= 0.0:
		_die()
	return true


func _die() -> void:
	alive = false
	visual.visible = false
	velocity = Vector3.ZERO
	if Game.fx:
		Game.fx.on_player_death(global_position + Vector3.UP * 0.8)
	died.emit()
	Game.on_player_died()
