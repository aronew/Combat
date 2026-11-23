class_name Player
extends CharacterBody3D
## Twin-stick mercenary: WASD (or left stick) to move, mouse (or right stick) to
## aim, hold LMB / right trigger to fire, Space / A / RB to dash.

signal health_changed(current: float, maximum: float)
signal died

@export_group("Movement")
@export var move_speed := 9.5
@export var acceleration := 85.0
@export var deceleration := 110.0
@export var turn_speed := 28.0

@export_group("Aim")
## Height of the plane the mouse ray is cast onto (0 = floor).
@export var aim_plane_height := 0.0
@export var stick_deadzone := 0.25

@export_group("Shooting")
@export var fire_rate := 12.0
@export var projectile_damage := 12.0
@export var projectile_speed := 44.0
@export var projectile_lifetime := 0.85
@export var spread_degrees := 3.5
@export var projectile_knockback := 6.5
@export var barrel_offset := 0.14

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


func _ready() -> void:
	Game.player = self
	health = max_health
	muzzle_flash.visible = false
	muzzle_light.light_energy = 0.0
	_ghost_mesh = ($Visual/Body as MeshInstance3D).mesh
	_build_ghosts()
	health_changed.emit(health, max_health)
	Game.player_health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_fire_cd = maxf(_fire_cd - delta, 0.0)
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)

	_update_aim()

	var input := _read_move_input()
	var wish := Vector3(input.x, 0.0, input.y)
	if Game.camera_rig:
		wish = Game.camera_rig.get_flat_basis() * wish

	if _wants_dash() and _dash_cd <= 0.0 and _dash_t <= 0.0:
		_start_dash(wish)

	if _dash_t > 0.0:
		_dash_t -= delta
		velocity = _dash_dir * dash_speed
		_ghost_t -= delta
		if _ghost_t <= 0.0:
			_ghost_t = dash_ghost_interval
			_spawn_ghost()
		if _dash_t <= 0.0:
			velocity = _dash_dir * move_speed
	else:
		var target := wish * move_speed
		var rate := acceleration if wish.length_squared() > 0.01 else deceleration
		velocity = velocity.move_toward(target, rate * delta)

	velocity += _knock
	_knock = _knock.move_toward(Vector3.ZERO, 60.0 * delta)
	velocity.y = 0.0
	move_and_slide()
	velocity -= _knock
	global_position.y = 0.0

	_update_facing(delta)
	_update_shooting()


func _process(delta: float) -> void:
	_update_ghosts(delta)
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
	if autopilot:
		return auto_move.limit_length(1.0)
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _wants_dash() -> bool:
	if autopilot:
		var d := auto_dash
		auto_dash = false
		return d
	return Input.is_action_just_pressed("dash")


func _wants_fire() -> bool:
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
	_fire_cd = 1.0 / fire_rate
	_barrel = -_barrel
	var side := aim_dir.cross(Vector3.UP).normalized()
	var origin := muzzle.global_position + side * barrel_offset * _barrel
	var dir := aim_dir.rotated(Vector3.UP, deg_to_rad(randf_range(-spread_degrees, spread_degrees)))
	if Game.projectiles:
		Game.projectiles.fire(origin, dir, projectile_speed, projectile_damage, projectile_lifetime, projectile_knockback)
	_flash_t = 0.045
	muzzle_flash.visible = true
	muzzle_flash.rotation.z = randf() * TAU
	muzzle_light.light_energy = 3.0
	if Game.fx:
		Game.fx.on_player_shot()


# --------------------------------------------------------------------------
# Dash
# --------------------------------------------------------------------------

func _start_dash(wish: Vector3) -> void:
	_dash_dir = wish.normalized() if wish.length_squared() > 0.01 else aim_dir
	_dash_t = dash_duration
	_dash_cd = dash_cooldown
	_invuln = maxf(_invuln, dash_duration + dash_invincibility_extra)
	_ghost_t = 0.0
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
	Game.trigger_game_over()
