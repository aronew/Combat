class_name Player
extends CharacterBody3D
## Twin-stick mercenary: WASD (or left stick) to move, mouse (or right stick) to
## aim, LMB / right trigger to attack, Space / A / RB to roll, Q / Y / wheel to
## swap between the loud RIFLE and the quiet BLADE, E / X to interact.
## The blade's 3-hit combo silently kills unaware bugs and parries turret beams.
## Blade flow: swings lock onto the best bug in front of you; bugs out of reach
## get a dash-strike (you zip to them, invincible, and cut on arrival). Hits in
## quick succession build a CHAIN (more damage, longer dash-strikes), and
## cutting a bug while it rears up to bite is a COUNTER (big damage through
## shields, slow-motion, a little health back).

signal health_changed(current: float, maximum: float)
signal died

enum Weapon { RIFLE, BLADE }

@export_group("Movement")
@export var move_speed := 9.5
@export var acceleration := 85.0
@export var deceleration := 110.0
@export var turn_speed := 28.0

## Reversing direction accelerates this much harder, so turn-arounds feel snappy.
@export var turnaround_boost := 1.9
## Dash and blade presses this many seconds early still count (input buffer).
@export var input_buffer := 0.16

@export_group("Body animation")
## Procedural animation on the primitive body: lean into movement, run bob and
## leg swing, recoil kick, squash and stretch on the roll, flinch when hit.
@export var lean_forward := 0.16
@export var lean_side := 0.12
@export var stride_length := 1.7
@export var bob_height := 0.07
@export var leg_swing := 0.75
@export var recoil_body := 0.1
@export var recoil_gun := 0.2

@export_group("Aim")
## Height of the plane the mouse ray is cast onto (0 = floor).
@export var aim_plane_height := 0.45
@export var stick_deadzone := 0.25

## Gun and blade numbers come from the equipped items (Profile -> Loot.GUNS /
## Loot.BLADES, scaled by item level, rarity, affixes and perks).
@export_group("Shooting")
@export var barrel_offset := 0.14
## Height bolts travel at (gameplay: low cover and short bugs are tuned around it), whatever
## height the rifle's muzzle is drawn at.
@export var bolt_height := 1.2
## Use the animated hunter model (false keeps the old placeholder body).
@export var use_hunter := true
@export_group("Hunter troubleshooting")
## Untick one at a time to find which part of the hunter a GPU has trouble with.
@export var hunter_rim_pass := true
@export var hunter_rim_light := true
@export var hunter_ghosts := true
@export var hunter_fixed_bounds := true
@export_group("")

@export_group("Blade")
@export var blade_combo_window := 0.6
@export var blade_lunge := 7.0
@export var blade_knockback := 5.0
## Seconds after a swing during which turret beams from the front are reflected.
@export var parry_window := 0.25
## Wind-up: seconds from the press to the blade crossing her front, when the cut hits (and the
## hitstop, sparks and numbers land with it). Stretched for slower blades. 0 = hit on the press.
@export var swing_contact_time := 0.07
## The finisher is a leap and slam: its wind-up is the jump, so it needs a little longer.
@export var finisher_contact_time := 0.18
## How long the crescent takes to sweep open, and how long it lingers after.
@export var slash_sweep_time := 0.07
@export var slash_linger := 0.14

@export_group("Blade flow")
## Target assist: swings snap toward the best bug inside this range and cone.
@export var assist_range := 6.5
@export var assist_cone_degrees := 120.0
## Targets beyond normal reach get a dash-strike at this speed, stopping this far away.
@export var strike_speed := 42.0
@export var strike_stop_distance := 1.15
@export var strike_max_time := 0.28
## Seconds between dash-strikes (halved while the chain is 3+). In between,
## out-of-reach targets get a normal lunging swing.
@export var strike_cooldown := 0.6
## Hits within this many seconds of each other keep the chain alive.
@export var chain_window := 1.5
## Extra damage per chain link, and the cap.
@export var chain_damage_step := 0.08
@export var chain_damage_max := 0.8
## Extra dash-strike range once the chain reaches 3.
@export var chain_range_bonus := 2.5
## Counter: a cut that lands while the bug winds up a bite.
@export var counter_damage_mult := 3.5
@export var counter_heal := 2.0
## Real seconds of slow-motion after a counter.
@export var counter_slowmo := 0.32

@export_group("Dash")
@export var dash_speed := 30.0
@export var dash_duration := 0.15
@export var dash_cooldown := 0.8
@export var dash_invincibility_extra := 0.12
@export var dash_ghost_interval := 0.025

@export_group("Health")
@export var max_health := 140.0
@export var hurt_invincibility := 0.9
## Out-of-combat recovery: after this many seconds without taking damage,
## slowly heal (stacks with regen from gear and perks).
@export var recover_delay := 6.0
@export var recover_rate := 4.0
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
var _dash_buffer := 0.0
var _attack_buffer := 0.0
var _lean := Vector2.ZERO  # x = pitch, y = roll (radians)
var _phase := 0.0
var _stride_amt := 0.0
var _recoil := 0.0
var _gun_kick := 0.0
var _squash := 0.0
var _squash_v := 0.0
var _flinch := Vector2.ZERO
var _hips: Array[Node3D] = []
var _gun_node: Node3D
var _flash_len := 0.045
var _flash_light := 3.0
## Per-gun muzzle flash: [scale (x, y, length), duration, light energy].
const FLASH := {
	"AR": [Vector3(1.0, 1.0, 2.2), 0.045, 3.0],
	"SM": [Vector3(0.7, 0.7, 1.6), 0.03, 2.0],
	"SG": [Vector3(2.0, 1.6, 1.8), 0.07, 6.0],
	"RL": [Vector3(0.7, 0.7, 5.5), 0.08, 7.0],
	"HP": [Vector3(1.8, 1.8, 1.4), 0.06, 4.5],
}
var _gun_base := Vector3.ZERO
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
## The animated hunter (null when use_hunter is off).
var body: HunterBody
const PLACEHOLDER_PARTS := ["Body", "Torso", "ChestPlate", "Head", "Visor", "HelmetStripe",
	"ShoulderL", "ShoulderR", "Backpack", "ThighL", "ThighR", "Gun"]

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
## The crescent's sweep: seconds since it started, and how long it takes to open.
var _slash_age := 0.0
var _slash_dur := 0.07
## A cut that has started but not yet landed (see swing_contact_time).
var _hit_pending_t := -1.0
var _hit_dir := Vector3.FORWARD
var _hit_finisher := false
var _hit_step := 1
var _arc_mesh: ArrayMesh
var _finisher_mesh: ArrayMesh
var _blade_node: Node3D
var _strike_t := 0.0
var _strike_target: Enemy
var _strike_dir := Vector3.ZERO
var _strike_from := Vector3.ZERO
var _strike_cd := 0.0
var _face_t := 0.0
var _face_dir := Vector3.FORWARD
var _chain := 0
var _chain_t := 0.0
var _swing_t := 0.0
var _swing_from := 0.0
var _swing_to := 0.0
var _swing_dur := 0.13
var _streak: MeshInstance3D
var _streak_mat: ShaderMaterial
var _streak_t := 0.0
var _assist_ray := PhysicsRayQueryParameters3D.new()
const SWING_TIME := 0.13
const SHOT_SOUNDS := {"rifle": &"rifle_shot", "smg": &"smg_shot", "shotgun": &"scattergun_shot", "railgun": &"rail_shot", "launcher": &"launcher_shot"}
## Run stats (read by the autoplay bot).
var stat_strikes := 0
var stat_counters := 0

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
	# Start on the floor's arrival point (generated floors move it around).
	if Game.level and Game.level.player_start != Vector3.INF:
		global_position = Game.level.player_start
	_base_max_health = max_health
	_base_move_speed = move_speed
	_base_dash_cooldown = dash_cooldown
	load_loadout()
	health = max_health
	muzzle_flash.visible = false
	muzzle_light.light_energy = 0.0
	_ghost_mesh = ($Visual/Body as MeshInstance3D).mesh
	if use_hunter:
		# Loaded by path so a hunter script that fails to compile on some platform falls back
		# to the placeholder (with a message) instead of stopping the player's setup.
		var hunter_script := load("res://scripts/player/hunter_body.gd") as Script
		if hunter_script == null or not hunter_script.can_instantiate():
			_show_hunter_failure("her script did not load (it failed to compile, or her model files did not import)")
			use_hunter = false
	if use_hunter:
		body = load("res://scripts/player/hunter_body.gd").new()
		body.name = "Hunter"
		body.use_rim_pass = hunter_rim_pass
		body.use_rim_light = hunter_rim_light
		body.use_ghosts = hunter_ghosts
		body.fixed_bounds = hunter_fixed_bounds
		visual.add_child(body)
		if body.ok:
			for part in PLACEHOLDER_PARTS:
				var n := visual.get_node_or_null(part) as Node3D
				if n:
					n.visible = false
		else:
			push_error("Player: the hunter body failed to set up; using the placeholder body")
			_show_hunter_failure("setup stopped while %s" % body.stage)
			body.queue_free()
			body = null
	_build_ghosts()
	_build_blade()
	_setup_body_rig()
	_apply_weapon_visuals()
	health_changed.emit(health, max_health)
	Game.player_health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_fire_cd -= delta  # may go negative: carried into the next shot (exact fire rates)
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_attack_buffer = maxf(_attack_buffer - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_blade_cd = maxf(_blade_cd - delta, 0.0)
	_parry_t = maxf(_parry_t - delta, 0.0)
	_combo_t = maxf(_combo_t - delta, 0.0)
	_face_t = maxf(_face_t - delta, 0.0)
	_strike_cd = maxf(_strike_cd - delta, 0.0)
	if _hit_pending_t >= 0.0:
		_hit_pending_t -= delta
		if _hit_pending_t <= 0.0:
			_hit_pending_t = -1.0
			_swing_contact()
	if _chain > 0:
		_chain_t -= delta
		if _chain_t <= 0.0:
			_set_chain(0)
	_tick_buffs(delta)
	_update_weapon_input()
	_update_interact()

	_update_aim()

	var input := _read_move_input()
	var wish := Vector3(input.x, 0.0, input.y)
	if Game.camera_rig and not autopilot:  # the bot steers in world space
		wish = Game.camera_rig.get_flat_basis() * wish

	# Buffered: a press shortly before the roll is ready still rolls.
	if _wants_dash():
		_dash_buffer = input_buffer
	_dash_buffer = maxf(_dash_buffer - delta, 0.0)
	if _dash_buffer > 0.0 and _dash_cd <= 0.0 and _dash_t <= 0.0:
		_dash_buffer = 0.0
		_strike_t = 0.0
		_start_dash(wish)

	if _strike_t > 0.0:
		_tick_strike(delta)
	elif _dash_t > 0.0:
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
		# Turning against your momentum bites harder (no ice-skating turn-arounds).
		if wish.length_squared() > 0.01 and velocity.length_squared() > 1.0 and wish.dot(velocity.normalized()) < -0.2:
			rate *= turnaround_boost
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
		_slash_age += delta
		_slash_mat.set_shader_parameter("progress", clampf(_slash_age / _slash_dur, 0.0, 1.0))
		_slash_mat.set_shader_parameter("fade", clampf(_slash_t / slash_linger, 0.0, 1.0))
		_slash_fx.visible = _slash_t > 0.0
	if _streak_t > 0.0:
		_streak_t -= delta
		_streak_mat.set_shader_parameter("fade", clampf(_streak_t / 0.2, 0.0, 1.0))
		_streak.visible = _streak_t > 0.0
	_animate_blade(delta)
	_animate_body(delta)
	if _flash_t > 0.0:
		_flash_t -= delta
		muzzle_flash.visible = _flash_t > 0.0
		muzzle_light.light_energy = _flash_light * clampf(_flash_t / _flash_len, 0.0, 1.0) if _flash_t > 0.0 else 0.0
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
	var f := _face_dir if (_face_t > 0.0 or _strike_t > 0.0) else aim_dir
	var target_yaw := atan2(-f.x, -f.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))


# --------------------------------------------------------------------------
# Shooting
# --------------------------------------------------------------------------

func _update_shooting() -> void:
	if not _wants_fire() or _dash_t > 0.0:
		_fire_cd = maxf(_fire_cd, 0.0)
		return
	if _fire_cd > 0.0:
		return
	# Carry the leftover time so the real rate matches the gun's stat at any frame rate.
	_fire_cd += 1.0 / (float(gun.fire_rate) * (1.0 + 0.08 * _adrenal_stacks))
	_fire_cd = maxf(_fire_cd, 0.0)
	_barrel = -_barrel
	var side := aim_dir.cross(Vector3.UP).normalized()
	var origin := muzzle.global_position + (side * barrel_offset * _barrel if body == null else Vector3.ZERO)
	if body:
		origin.y = global_position.y + bolt_height
	# Bolts converge on the cursor (at bolt height), not parallel to the body's aim
	# line: what's under the crosshair is what gets hit.
	var shot_dir := aim_dir
	var to_aim := Vector3(aim_point.x - origin.x, 0.0, aim_point.z - origin.z)
	if to_aim.length() > 2.0:
		shot_dir = to_aim.normalized()
	var pellets := int(gun.pellets)
	var spread: float = gun.spread
	if Game.projectiles:
		for i in pellets:
			var dir := shot_dir.rotated(Vector3.UP, deg_to_rad(randf_range(-spread, spread)))
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
			Game.projectiles.fire(origin, shot_dir, 110.0, 0.5, rail)
			Audio.play(&"rail_shot", -4.0)
	Audio.play(SHOT_SOUNDS.get(String(gun_item.get("archetype", "rifle")), &"rifle_shot"))
	_recoil = minf(_recoil + 0.35 + float(gun.shake) * 5.0, 1.6)
	_gun_kick = minf(_gun_kick + 0.6 + float(gun.shake) * 4.0, 1.6)
	if body:
		body.kick(0.6 + float(gun.shake) * 4.0)
	var fl: Array = FLASH.get(String(gun.get("code", "AR")), FLASH.AR)
	_flash_len = fl[1]
	_flash_light = fl[2]
	_flash_t = _flash_len
	var flash_scale: Vector3 = fl[0]
	muzzle_flash.scale = flash_scale * randf_range(0.85, 1.15)
	if body == null:
		muzzle_flash.position.z = -0.95 - flash_scale.z * 0.12
	var fm := muzzle_flash.material_override as ShaderMaterial
	if fm:
		fm.set_shader_parameter("tint", Color(gun.color).lerp(Color.WHITE, 0.55))
	muzzle_light.light_color = Color(gun.color).lerp(Color.WHITE, 0.3)
	# Guns with a framework muzzle effect use it (it follows the muzzle);
	# the rest keep the built-in flash mesh and light.
	if Game.fx and Game.fx.muzzle(String(gun.get("code", "")), muzzle.global_position, shot_dir, muzzle, Color(gun.color)):
		_flash_t = 0.0
		muzzle_flash.visible = false
		muzzle_light.light_energy = 0.0
	else:
		muzzle_flash.visible = true
		muzzle_flash.rotation.z = randf() * TAU
		muzzle_light.light_energy = _flash_light
	if String(gun.get("code", "")) == "RL" and Game.fx:
		Game.fx.rail_beam(origin, shot_dir, float(gun.speed) * float(gun.lifetime), Color(gun.color))
	if Game.fx:
		Game.fx.on_player_shot(gun.shake)
	if Game.camera_rig:
		Game.camera_rig.kick(-shot_dir, float(gun.shake) * 1.3)
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
	if body:
		body.set_rifle_mode(weapon == Weapon.RIFLE)
		return
	$Visual/Gun.visible = weapon == Weapon.RIFLE
	if _blade_node:
		_blade_node.visible = weapon == Weapon.BLADE


func _update_blade() -> void:
	# A tap while the blade is busy is remembered briefly and fires when it frees up.
	if not autopilot and not input_locked and Input.is_action_just_pressed("fire"):
		_attack_buffer = input_buffer
	if _dash_t > 0.0 or _strike_t > 0.0 or _blade_cd > 0.0:
		return
	if _wants_fire() or _attack_buffer > 0.0:
		_attack_buffer = 0.0
		_blade_attack()


## Pick a target (assist), then either swing now or dash-strike to it.
func _blade_attack() -> void:
	var reach_range := assist_range + (chain_range_bonus if _chain >= 3 else 0.0)
	var target := _find_blade_target(reach_range)
	if target:
		var to := target.global_position - global_position
		to.y = 0.0
		var d := to.length()
		var dir := to / d if d > 0.01 else aim_dir
		if d > blade_range * 0.8 and _strike_cd <= 0.0:
			_start_strike(target, dir, d)
			return
		# In reach (or strike recharging): snap to it and step in.
		_knock += dir * blade_lunge * clampf((d - 0.8) / 1.2, 0.25, 1.4)
		_swing(dir)
		return
	_knock += aim_dir * blade_lunge
	_swing(aim_dir)


## Best bug for the blade: close, near where you aim, reachable. Bugs winding
## up a bite are preferred (counter chances).
func _find_blade_target(max_range: float) -> Enemy:
	if Game.spawner == null:
		return null
	var best: Enemy = null
	var best_score := INF
	var cos_half := cos(deg_to_rad(assist_cone_degrees * 0.5))
	for e in Game.spawner.enemies_in_radius(global_position, max_range):
		if not e.is_targetable():
			continue
		var to := e.global_position - global_position
		to.y = 0.0
		var d := to.length()
		var dot := aim_dir.dot(to / d) if d > 0.01 else 1.0
		if d > 1.2 and dot < cos_half:
			continue
		var score := d + (1.0 - dot) * 5.0
		if e.is_counterable():
			score -= 2.5
		if e.is_unaware():
			score -= 1.0
		if score < best_score and (d < 1.5 or _clear_path_to(e)):
			best = e
			best_score = score
	return best


func _clear_path_to(e: Enemy) -> bool:
	_assist_ray.from = global_position + Vector3.UP * 0.6
	_assist_ray.to = e.global_position + Vector3.UP * 0.6
	_assist_ray.collision_mask = 1
	_assist_ray.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(_assist_ray).is_empty()


func _start_strike(target: Enemy, dir: Vector3, dist: float) -> void:
	stat_strikes += 1
	_strike_target = target
	_strike_dir = dir
	_strike_from = global_position
	_strike_t = clampf((dist - strike_stop_distance) / strike_speed + 0.06, 0.06, strike_max_time)
	_invuln = maxf(_invuln, _strike_t + 0.04)
	_strike_cd = strike_cooldown * (0.5 if _chain >= 3 else 1.0)
	_face_dir = dir
	_ghost_t = 0.0
	_blade_cd = _strike_t + 0.02
	Audio.play(&"dash_strike")
	if Game.fx:
		Game.fx.on_player_dash(global_position)


func _tick_strike(delta: float) -> void:
	_strike_t -= delta
	var t := _strike_target
	var arrived := false
	if t and t.is_targetable():
		var to := t.global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d > 0.01:
			_strike_dir = to / d
		arrived = d <= strike_stop_distance
	_face_dir = _strike_dir
	velocity = Vector3.ZERO if arrived else _strike_dir * strike_speed
	_ghost_t -= delta
	if _ghost_t <= 0.0:
		_ghost_t = dash_ghost_interval
		_spawn_ghost()
	if arrived or _strike_t <= 0.0:
		_strike_t = 0.0
		velocity = _strike_dir * 2.0
		_show_streak(_strike_from, global_position)
		_swing(_strike_dir, true)  # the dash was the wind-up: cut on arrival


## One cut in `dir`: starts the swing now and lands it at contact (see swing_contact_time).
## instant: land it right away (a dash-strike arriving; the dash was the wind-up).
func _swing(dir: Vector3, instant := false) -> void:
	if _hit_pending_t >= 0.0:  # never drop a cut that has not landed yet
		_hit_pending_t = -1.0
		_swing_contact()
	_combo_step = (_combo_step % 3) + 1 if _combo_t > 0.0 else 1
	_combo_t = blade_combo_window
	var finisher := _combo_step == 3
	_blade_cd = blade_cooldown * (1.5 if finisher else 1.0)
	_parry_t = parry_window
	# slower, heavier blades take longer over the same motion
	var pace := clampf(blade_cooldown / 0.24, 0.8, 1.8)
	var contact := 0.0 if instant else (finisher_contact_time if finisher else swing_contact_time) * pace
	_face_dir = dir
	_face_t = 0.18 + contact
	_start_swing_anim(finisher)
	if body:
		body.swing(_combo_step, contact, pace, _blade_color(finisher))
	var cleaver := String(blade_item.get("archetype", "mono")) == "cleaver"
	if finisher:
		Audio.play(&"blade_finisher", 0.0, 0.85 if cleaver else 1.0)
	else:
		Audio.play(&"cleaver_swing" if cleaver else &"blade_swing", 0.0, 1.0 + (_combo_step - 1) * 0.05)
	_hit_dir = dir
	_hit_finisher = finisher
	_hit_step = _combo_step
	if contact <= 0.0:
		_swing_contact()
	else:
		_hit_pending_t = contact


## The blade's colour for this cut (finishers burn hotter).
func _blade_color(finisher: bool) -> Color:
	var c := Color(blade.get("color", "19f4ff"))
	return c.lerp(Color(1.0, 1.0, 1.0), 0.25) if finisher else c


## The moment the blade crosses her front: hits everything in the arc, counters bugs mid wind-up.
func _swing_contact() -> void:
	if not alive:
		return
	var dir := _hit_dir
	var finisher := _hit_finisher
	var arc := blade_finisher_arc_degrees if finisher else blade_arc_degrees
	var reach := blade_range * (1.15 if finisher else 1.0)
	var chain_mult := 1.0 + minf(chain_damage_step * _chain, chain_damage_max)
	var dmg := (blade_finisher_damage if finisher else blade_damage) * chain_mult
	_show_slash(finisher, dir)

	var cos_half := cos(deg_to_rad(arc * 0.5))
	var hits := 0
	var counters := 0
	if Game.spawner:
		for e in Game.spawner.enemies_in_radius(global_position, reach + 0.4):
			if not e.is_active():
				continue
			var to := e.global_position - global_position
			to.y = 0.0
			var d := to.length()
			if d > reach + e.get_hit_radius():
				continue
			var edir := to / d if d > 0.01 else dir
			if d > 0.7 and dir.dot(edir) < cos_half:
				continue
			if e.can_be_assassinated(global_position - e.global_position):
				e.assassinate(edir, dmg)
			elif e.is_counterable():
				counters += 1
				var dealt_c := e.take_hit(dmg * counter_damage_mult, edir, blade_knockback * 2.0, Game.TEAM_PLAYER, &"counter")
				if dealt_c > 0.0 and e.is_active():
					_blade_elements(e, dealt_c)
			else:
				var crit := randf() < float(blade.get("crit_chance", 0.05))
				var d_hit := dmg * (float(blade.get("crit_mult", 1.5)) if crit else 1.0)
				var dealt := e.take_hit(d_hit, edir, blade_knockback * (1.6 if finisher else 1.0), Game.TEAM_PLAYER, &"slash_crit" if crit else &"slash")
				if dealt > 0.0 and e.is_active():
					_blade_elements(e, dealt)
			hits += 1
	for t in Game.damageables.duplicate():
		if not is_instance_valid(t) or not t.is_alive():
			continue
		var to2: Vector3 = t.global_position - global_position
		to2.y = 0.0
		if to2.length() <= reach + t.hit_radius and (to2.length() < 0.5 or dir.dot(to2.normalized()) >= cos_half):
			t.take_hit(dmg, to2.normalized(), 0.0, Game.TEAM_PLAYER, &"slash")
			hits += 1
	if hits > 0:
		_set_chain(_chain + 1)
		Game.hitstop(0.03 if not finisher else 0.06)
		Game.shake(0.08 if not finisher else 0.2)
		if Game.director:
			Game.director.make_noise(global_position, Game.director.blade_noise_radius, Game.director.blade_noise_alert)
	if counters > 0:
		stat_counters += counters
		Game.hitstop(0.07)
		Game.slowmo(counter_slowmo, 0.3)
		Game.shake(0.3)
		heal(counter_heal * counters)
		if Game.fx:
			Game.fx.text_popup(global_position + Vector3.UP * 2.6, "COUNTER!" if counters == 1 else "COUNTER x%d!" % counters, Color("ff2bd6"), 1.25)


func _set_chain(n: int) -> void:
	_chain = n
	_chain_t = chain_window
	Game.blade_chain_changed.emit(_chain)


func get_blade_chain() -> int:
	return _chain


func is_striking() -> bool:
	return _strike_t > 0.0


## True while a recent swing faces `source` (used by turrets to reflect beams).
func is_parrying_toward(source: Vector3) -> bool:
	if _parry_t <= 0.0 or weapon != Weapon.BLADE:
		return false
	var to := source - global_position
	to.y = 0.0
	return to.length_squared() > 0.01 and aim_dir.dot(to.normalized()) > 0.5


func _show_slash(finisher: bool, dir: Vector3) -> void:
	_slash_fx.mesh = _finisher_mesh if finisher else _arc_mesh
	# Sweeps open the way the blade travels: the cuts alternate direction, and each is tilted
	# like the blade's path (the first rises to her left, the second comes down from her right).
	var sweep := body.swing_sweep(_hit_step) if body else (-1.0 if _hit_step == 2 else 1.0)
	var tilt: float = [-0.18, 0.22, 0.0][clampi(_hit_step, 1, 3) - 1]
	var yaw := atan2(-dir.x, -dir.z)
	_slash_fx.global_transform = Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, tilt),
		global_position + Vector3.UP * (1.0 if not finisher else 0.9))
	_slash_mat.set_shader_parameter("tint", _blade_color(finisher))
	_slash_mat.set_shader_parameter("energy", 2.8 if finisher else 2.2)
	_slash_mat.set_shader_parameter("sweep", sweep)
	_slash_mat.set_shader_parameter("progress", 0.0)
	_slash_mat.set_shader_parameter("fade", 1.0)
	_slash_fx.visible = true
	_slash_dur = slash_sweep_time * (1.4 if finisher else 1.0)
	_slash_age = 0.0
	_slash_t = _slash_dur + slash_linger


## Neon streak along a dash-strike path.
func _show_streak(a: Vector3, b: Vector3) -> void:
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if flat.length() < 0.5:
		return
	_streak.global_position = (a + b) * 0.5 + Vector3.UP * 0.9
	_streak.rotation = Vector3(0.0, atan2(-flat.x, -flat.z), 0.0)
	_streak.scale = Vector3(1.0, 1.0, flat.length())
	_streak_mat.set_shader_parameter("tint", Color(blade.get("color", "19f4ff")))
	_streak_mat.set_shader_parameter("fade", 1.0)
	_streak.visible = true
	_streak_t = 0.2


## Sweep the blade across the front (alternating sides), or all the way round on a finisher.
func _start_swing_anim(finisher: bool) -> void:
	var side := -1.0 if _combo_step == 2 else 1.0
	var half := 150.0 if finisher else 80.0
	_swing_from = side * half
	_swing_to = -side * half
	_swing_dur = SWING_TIME * (1.4 if finisher else 1.0)
	_swing_t = _swing_dur


func _animate_blade(delta: float) -> void:
	if _blade_node == null or body:
		return
	if _swing_t > 0.0:
		_swing_t = maxf(_swing_t - delta, 0.0)
		var k := 1.0 - _swing_t / _swing_dur
		var e := 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 3.0)
		_blade_node.rotation_degrees = Vector3(-85.0, lerpf(_swing_from, _swing_to, e), 0.0)
	else:
		_blade_node.rotation_degrees = _blade_node.rotation_degrees.lerp(Vector3(-70.0, 0.0, 0.0), clampf(delta * 10.0, 0.0, 1.0))


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
	_blade_node.visible = body == null
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
	_slash_mat.shader = preload("res://scripts/shaders/vfx/slash_arc.gdshader")
	_slash_fx = MeshInstance3D.new()
	_slash_fx.material_override = _slash_mat
	_slash_fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_slash_fx.top_level = true
	_slash_fx.visible = false
	add_child(_slash_fx)

	_streak_mat = ShaderMaterial.new()
	_streak_mat.shader = preload("res://scripts/shaders/neon_fade.gdshader")
	_streak_mat.set_shader_parameter("energy", 3.0)
	_streak_mat.set_shader_parameter("edge_softness", 0.5)
	var sm := BoxMesh.new()
	sm.size = Vector3(0.22, 0.04, 1.0)
	_streak = MeshInstance3D.new()
	_streak.mesh = sm
	_streak.material_override = _streak_mat
	_streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_streak.top_level = true
	_streak.visible = false
	add_child(_streak)


## Flat crescent in front of the player (-Z), thicker in the middle. UV.x runs along the arc
## from her left end (0) to her right end (1), UV.y from the inner edge (0) to the outer (1).
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
		var u0 := float(i) / steps
		var u1 := float(i + 1) / steps
		for pv in [[n0, Vector2(u0, 0)], [o0, Vector2(u0, 1)], [o1, Vector2(u1, 1)], [n0, Vector2(u0, 0)], [o1, Vector2(u1, 1)], [n1, Vector2(u1, 0)]]:
			st.set_normal(Vector3.UP)
			st.set_uv(pv[1])
			st.add_vertex(pv[0])
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
	var rate := _regen if _since_hurt > 4.0 else 0.0
	if _since_hurt > recover_delay:
		rate += recover_rate
	if rate > 0.0 and alive and health < max_health:
		health = minf(health + rate * delta, max_health)
		_regen_emit_t -= delta
		if _regen_emit_t <= 0.0:
			_regen_emit_t = 0.25
			Game.player_health_changed.emit(health, max_health)


## Legendary and perk procs on any kill you caused.
func on_kill(_e: Enemy, pos: Vector3, kind: StringName) -> void:
	if not kind in [&"bullet", &"crit", &"slash", &"slash_crit", &"counter", &"silent", &"burn", &"shock", &"reflect"]:
		return
	if Profile.has_legendary("chain_reaction") and kind != &"silent" and randf() < 0.35:
		Game.delayed_explode(0.08, pos + Vector3.UP * 0.4, 2.6, float(gun.damage) * 1.5, 0.0, 9.0, null, 1.6)
	if Profile.has_legendary("reaper") and kind in [&"slash", &"slash_crit", &"counter", &"silent"]:
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
	Audio.play(&"roll")
	_invuln = maxf(_invuln, dash_duration + dash_invincibility_extra)
	_ghost_t = 0.0
	if Profile.has_legendary("bulwark"):
		_bulwark_t = dash_duration + 1.5
	_squash_v += 9.0 if body == null else 3.0
	if body:
		body.roll()
	if Game.fx:
		Game.fx.on_player_dash(global_position)
		Game.fx.burst(global_position + Vector3.UP * 0.15, -_dash_dir, 0.45, Color(0.75, 0.85, 0.95, 0.5))


func is_dashing() -> bool:
	return _dash_t > 0.0


## 0 = just used, 1 = ready.
func get_dash_ready_ratio() -> float:
	return 1.0 - (_dash_cd / dash_cooldown) if dash_cooldown > 0.0 else 1.0


func get_dash_cooldown_left() -> float:
	return _dash_cd


func _build_ghosts() -> void:
	var shader := preload("res://scripts/shaders/neon_fade.gdshader")
	if body:
		var gm := ShaderMaterial.new()
		gm.shader = shader
		gm.set_shader_parameter("tint", Palette.NEON_CYAN)
		gm.set_shader_parameter("energy", 1.6)
		gm.set_shader_parameter("edge_softness", 0.6)
		body.build_ghosts(5, gm)
		return
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
	if body:
		body.spawn_ghost()
		return
	var g := _ghosts[_ghost_index]
	_ghost_index = (_ghost_index + 1) % _ghosts.size()
	g.global_transform = ($Visual/Body as Node3D).global_transform
	g.visible = true
	g.set_meta("life", 0.22)


func _update_ghosts(delta: float) -> void:
	if body:
		for g in body.ghosts():
			if not g.visible:
				continue
			var life: float = g.get_meta("life") - delta
			g.set_meta("life", life)
			if life <= 0.0:
				g.visible = false
			else:
				for m in body.ghost_meshes(g):
					((m as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("fade", life / 0.22 * 0.7)
		return
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

## Invincible for `seconds` (floor transitions, cutscene-ish moments).
func grant_invulnerability(seconds: float) -> void:
	_invuln = maxf(_invuln, seconds)


func is_invincible() -> bool:
	return _invuln > 0.0 or not alive


## Returns true if the hit landed.
func heal(amount: float) -> void:
	if not alive or amount <= 0.0:
		return
	health = minf(health + amount, max_health)
	Game.player_health_changed.emit(health, max_health)
	if Game.fx:
		Game.fx.text_popup(global_position + Vector3.UP * 2.2, "+%d" % roundi(amount), Color("3dff7a"), 0.9)


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
		var local := Basis(Vector3.UP, visual.rotation.y).inverse() * away.normalized()
		_flinch = Vector2(local.z, -local.x) * 0.45
	if body:
		body.hit()
		if Game.camera_rig:
			Game.camera_rig.kick(away, 0.35)
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
	velocity = Vector3.ZERO
	if body:
		body.die()  # she falls and stays down
		visual.visible = true
	else:
		visual.visible = false
	if Game.fx:
		Game.fx.on_player_death(global_position + Vector3.UP * 0.8)
	died.emit()
	Game.on_player_died()


# --------------------------------------------------------------------------
# Procedural body animation
# --------------------------------------------------------------------------

## Hips become pivots so the legs swing from the top, and the gun's rest pose
## is remembered for the recoil kick.
func _setup_body_rig() -> void:
	for name in ["ThighL", "ThighR"]:
		var thigh := visual.get_node_or_null(name) as Node3D
		if thigh == null:
			continue
		var hip := Node3D.new()
		hip.name = name + "Hip"
		hip.position = thigh.position + Vector3(0, 0.14, 0)
		visual.add_child(hip)
		thigh.reparent(hip, false)
		thigh.position = Vector3(0, -0.14, 0)
		_hips.append(hip)
	_gun_node = visual.get_node_or_null("Gun") as Node3D
	if _gun_node:
		_gun_base = _gun_node.position


func _animate_body(delta: float) -> void:
	if not alive:
		return
	if body:
		_drive_hunter()
	var yaw := visual.rotation.y
	var flat_v := Vector3(velocity.x, 0.0, velocity.z)
	var local := Basis(Vector3.UP, yaw).inverse() * flat_v
	var ref := maxf(_base_move_speed, 0.1)
	var spd := flat_v.length()
	var ratio := clampf(spd / ref, 0.0, 1.0)

	# Lean into the direction of travel (harder while rolling), smoothed for weight.
	var target := Vector2(clampf(local.z / ref, -1.3, 1.3) * lean_forward, clampf(-local.x / ref, -1.3, 1.3) * lean_side)
	_lean = _lean.lerp(target, 1.0 - exp(-14.0 * delta))
	_flinch = _flinch.lerp(Vector2.ZERO, 1.0 - exp(-10.0 * delta))

	# Stride: phase advances with distance covered, so feet don't skate.
	_phase = fmod(_phase + spd * delta / stride_length * TAU, TAU)
	_stride_amt = lerpf(_stride_amt, ratio if _dash_t <= 0.0 else 0.0, 1.0 - exp(-12.0 * delta))
	var bob := absf(sin(_phase)) * bob_height * _stride_amt if body == null else 0.0
	var sway := sin(_phase) * 0.045 * _stride_amt

	# Recoil decays fast; the gun snaps back a little slower than the body.
	_recoil = move_toward(_recoil, 0.0, delta * 9.0)
	_gun_kick = move_toward(_gun_kick, 0.0, delta * 7.0)

	# Squash and stretch: a damped spring, pushed by the roll start.
	var sq_target := 1.0 if _dash_t > 0.0 else 0.0
	_squash_v += ((sq_target - _squash) * 320.0 - _squash_v * 20.0) * delta
	_squash += _squash_v * delta

	visual.rotation.x = _lean.x + _flinch.x - _recoil * 0.06
	visual.rotation.z = _lean.y + _flinch.y + sway
	var back := Basis(Vector3.UP, yaw) * Vector3(0, 0, 1)
	visual.position = Vector3(0, bob, 0) + back * _recoil * recoil_body
	var sq := clampf(_squash, -0.6, 1.4) * (1.0 if body == null else 0.4)
	visual.scale = Vector3(1.0 + 0.1 * sq, 1.0 - 0.14 * sq, 1.0 + 0.1 * sq)

	# Legs swing along the direction of travel relative to facing.
	if _hips.size() == 2:
		var fw := clampf(-local.z / maxf(spd, 0.1), -1.0, 1.0)
		var side := clampf(local.x / maxf(spd, 0.1), -1.0, 1.0)
		var swing := sin(_phase) * leg_swing * _stride_amt
		_hips[0].rotation = Vector3(swing * fw, 0.0, swing * side * 0.6)
		_hips[1].rotation = Vector3(-swing * fw, 0.0, -swing * side * 0.6)
	if _gun_node:
		_gun_node.position = _gun_base + Vector3(0, 0.02 * _gun_kick, _gun_kick * recoil_gun)
		_gun_node.rotation.x = _gun_kick * 0.22


## Feeds the hunter's animation: movement relative to her facing picks the run clip, and the
## rifle's muzzle drives where shots and the flash come from.
func _drive_hunter() -> void:
	var flat_v := Vector3(velocity.x, 0.0, velocity.z)
	if _dash_t > 0.0 or _strike_t > 0.0:
		flat_v = Vector3.ZERO  # the roll and the strike clips carry the body
	var local := Basis(Vector3.UP, visual.rotation.y).inverse() * flat_v
	var ref := maxf(current_move_speed(), 0.1)
	body.set_move(Vector2(local.x, -local.z) / ref, flat_v.length())
	var tip := body.muzzle_position()
	muzzle.global_position = tip
	muzzle_flash.global_position = tip + aim_dir * 0.08
	muzzle_light.global_position = tip + aim_dir * 0.2 + Vector3.UP * 0.1


## On-screen note when the hunter can't be used (the web editor has no easy error console).
func _show_hunter_failure(reason: String) -> void:
	push_error("Player: hunter not loaded: " + reason)
	var layer := CanvasLayer.new()
	layer.layer = 90
	var label := Label.new()
	label.text = "HUNTER DIDN'T LOAD: %s.\nShowing the placeholder body. (Screenshot this for Claude.)" % reason
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.position = Vector2(24, 120)
	layer.add_child(label)
	add_child(layer)
	get_tree().create_timer(15.0).timeout.connect(layer.queue_free)
