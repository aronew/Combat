class_name Enemy
extends CharacterBody3D
## Swarmer: small, fast bug with a glowing orange core. Pooled by the Spawner.
## Enters either by bursting out of the hive or by leaping up from the void over
## the railing, then chases the player as part of the swarm.

enum State { INACTIVE, EMERGE, LEAP, CHASE }

@export_group("Combat")
@export var contact_damage := 9.0
@export var contact_range := 0.85
@export var radius := 0.4

@export_group("Movement")
@export var acceleration := 38.0
@export var turn_speed := 14.0
@export var knockback_decay := 9.0
@export var hit_stagger := 0.25  ## Fraction of chase speed kept right after a hit.
@export var detour_time := 2.5  ## Max wall-follow time when wedged against cover.

@export_group("Entrance")
@export var emerge_duration := 0.4
@export var leap_duration := 0.65
@export var leap_height := 3.6

@export_group("Feedback")
@export var flash_duration := 0.07
@export var flash_material: Material = preload("res://scenes/materials/hit_flash.tres")

var state := State.INACTIVE
var health := 0.0
var max_health := 0.0
var speed := 5.0
var spawner: Spawner

var _move_vel := Vector3.ZERO
var _knock := Vector3.ZERO
var _sep := Vector3.ZERO
var _state_t := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _flash_t := 0.0
var _phase := 0.0
var _flash_targets: Array[GeometryInstance3D] = []
var _stuck_t := 0.0
var _detour_t := 0.0
var _detour := Vector3.ZERO
var _detour_sign := 1.0
var _los_t := 0.0
var _los_query := PhysicsRayQueryParameters3D.new()

@onready var visual: Node3D = $Visual


func _ready() -> void:
	_los_query.collision_mask = 1
	for n in visual.find_children("*", "GeometryInstance3D", true, false):
		_flash_targets.append(n)
	_phase = randf() * TAU


func activate_emerge(pos: Vector3, hp: float, move_speed: float) -> void:
	_activate(hp, move_speed)
	state = State.EMERGE
	_to = Vector3(pos.x, 0.0, pos.z)
	global_position = _to
	visual.scale = Vector3.ONE * 0.1
	visual.position.y = -0.4
	var away := _to - Game.arena.hive_center if Game.arena else Vector3.FORWARD
	visual.rotation.y = atan2(-away.x, -away.z)


func activate_leap(from: Vector3, to: Vector3, hp: float, move_speed: float) -> void:
	_activate(hp, move_speed)
	state = State.LEAP
	_from = from
	_to = Vector3(to.x, 0.0, to.z)
	global_position = from
	var d := _to - from
	visual.rotation.y = atan2(-d.x, -d.z)


func _activate(hp: float, move_speed: float) -> void:
	health = hp
	max_health = hp
	speed = move_speed * randf_range(0.9, 1.12)
	_move_vel = Vector3.ZERO
	_knock = Vector3.ZERO
	_state_t = 0.0
	_flash_t = 0.0
	_stuck_t = 0.0
	_detour_t = 0.0
	_detour_sign = 1.0 if randf() < 0.5 else -1.0
	_set_flash(false)
	visual.scale = Vector3.ONE
	visual.position = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true


func deactivate() -> void:
	state = State.INACTIVE
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	global_position = Vector3(0.0, -500.0, 0.0)


func is_active() -> bool:
	return state != State.INACTIVE


## Separation force is written by the Spawner each physics frame.
func set_separation(v: Vector3) -> void:
	_sep = v


func _physics_process(delta: float) -> void:
	_state_t += delta
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_set_flash(false)
	match state:
		State.EMERGE:
			_tick_emerge()
		State.LEAP:
			_tick_leap()
		State.CHASE:
			_tick_chase(delta)


func _tick_emerge() -> void:
	var t := clampf(_state_t / emerge_duration, 0.0, 1.0)
	var pop := 1.0 + sin(t * PI) * 0.35
	visual.scale = Vector3.ONE * lerpf(0.1, 1.0, t) * pop
	visual.position.y = lerpf(-0.4, 0.0, t)
	if t >= 1.0:
		_begin_chase()


func _tick_leap() -> void:
	var t := clampf(_state_t / leap_duration, 0.0, 1.0)
	var p := _from.lerp(_to, 1.0 - pow(1.0 - t, 1.6))
	p.y = lerpf(_from.y, 0.0, t) + sin(t * PI) * leap_height
	global_position = p
	visual.rotation.x = lerpf(-0.9, 0.0, t)
	if t >= 1.0:
		global_position = _to
		visual.rotation.x = 0.0
		if Game.fx:
			Game.fx.on_enemy_land(_to)
		_begin_chase()


func _begin_chase() -> void:
	state = State.CHASE
	visual.scale = Vector3.ONE
	visual.position = Vector3.ZERO


func _tick_chase(delta: float) -> void:
	var player := Game.player
	var chase := Vector3.ZERO
	var goal := global_position
	if player and player.alive:
		goal = player.global_position
		if Game.arena:
			goal = Game.arena.get_nav_target(global_position, goal)
		var to := goal - global_position
		to.y = 0.0
		if to.length_squared() > 0.01:
			chase = to.normalized()
	# Wall-follow around cover: keep sidestepping until the goal is in sight.
	if _detour_t > 0.0:
		_detour_t -= delta
		_los_t -= delta
		if _los_t <= 0.0:
			_los_t = 0.15
			if _has_line_of_sight(goal):
				_detour_t = 0.0
		if _detour_t > 0.0:
			chase = (chase * 0.25 + _detour).normalized()
	var desired := chase * speed + _sep
	_move_vel = _move_vel.move_toward(desired, acceleration * delta)

	velocity = _move_vel + _knock
	move_and_slide()
	global_position.y = 0.0
	_knock *= exp(-knockback_decay * delta)
	_update_stuck(chase, delta)

	# Face movement, scuttle bob.
	var face := _move_vel + _knock * 0.3
	if face.length_squared() > 0.2:
		var yaw := atan2(-face.x, -face.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, yaw, 1.0 - exp(-turn_speed * delta))
	visual.position.y = absf(sin(_state_t * 22.0 + _phase)) * 0.07

	# Contact damage.
	if player and player.alive:
		var d := Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z)
		if d.length() < contact_range and player.take_damage(contact_damage, global_position):
			var back := Vector3(-d.x, 0.0, -d.y).normalized()
			_knock = back * 10.0
			_move_vel = Vector3.ZERO


## Detect "pushing into a wall without progress" and start (or reverse) a sidestep.
func _update_stuck(intended: Vector3, delta: float) -> void:
	if intended == Vector3.ZERO:
		_stuck_t = 0.0
		return
	var actual := get_real_velocity()
	actual.y = 0.0
	if get_slide_collision_count() > 0 and actual.dot(intended) < speed * 0.35:
		_stuck_t += delta
	else:
		_stuck_t = maxf(_stuck_t - delta * 2.0, 0.0)
	if _stuck_t > 0.25:
		_stuck_t = 0.0
		if _detour_t > 0.0:
			_detour_sign = -_detour_sign  # the sidestep itself hit a corner: try the other way
			_detour = -_detour
		else:
			_detour = Vector3(-intended.z, 0.0, intended.x) * _detour_sign
		_detour_t = detour_time
		_los_t = 0.3


func _has_line_of_sight(goal: Vector3) -> bool:
	_los_query.from = global_position + Vector3.UP * 0.4
	_los_query.to = goal + Vector3.UP * 0.4
	return get_world_3d().direct_space_state.intersect_ray(_los_query).is_empty()


## Called by projectiles. `direction` is the bolt's travel direction.
func take_hit(damage: float, direction: Vector3, knockback: float) -> void:
	if state == State.INACTIVE:
		return
	health -= damage
	_flash_t = flash_duration
	_set_flash(true)
	var push := Vector3(direction.x, 0.0, direction.z).normalized()
	_knock += push * knockback
	_move_vel *= hit_stagger
	var killed := health <= 0.0
	if Game.fx:
		Game.fx.on_enemy_hit(global_position, damage, killed)
	if killed:
		_die(push)


func _die(direction: Vector3) -> void:
	if Game.fx:
		Game.fx.on_enemy_killed(global_position + Vector3.UP * 0.35, direction)
	Game.register_kill()
	if spawner:
		spawner.release(self)
	else:
		deactivate()


func _set_flash(on: bool) -> void:
	for g in _flash_targets:
		g.material_override = flash_material if on else null
