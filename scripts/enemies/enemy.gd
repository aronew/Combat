class_name Enemy
extends CharacterBody3D
## Base hive bug (the Swarmer uses it as-is). Handles:
## - stealth states: DORMANT (asleep, short sight), PATROL, INVESTIGATE (noise);
## - senses: sight cone + line of sight; spotted -> scream -> CHASE;
## - entrances: burrow (EMERGE), drop from above (DROP), leap from the void (LEAP);
## - chasing through the level's region graph, wall-following around cover;
## - tiers (blue / gold / purple elite) with stat multipliers and an aura;
## - hits, knockback, white flash, death, salvage drops.
## Special enemies override the hooks at the bottom of this file.

enum State { INACTIVE, DORMANT, PATROL, INVESTIGATE, EMERGE, LEAP, DROP, CHASE }
enum Tier { NORMAL, BLUE, GOLD, PURPLE }

const TIER_COLORS := [Color(1, 1, 1, 0), Color("3aa0ff"), Color("ffc23d"), Color("b04dff")]
const TIER_LABELS := ["", "VETERAN", "CHAMPION", "ELITE"]
const TIER_HEALTH := [1.0, 2.0, 3.5, 10.0]
const TIER_DAMAGE := [1.0, 1.2, 1.4, 1.6]
const TIER_SPEED := [1.0, 1.05, 1.1, 1.1]
const TIER_SCALE := [1.0, 1.12, 1.25, 1.65]
const TIER_SALVAGE := [1, 3, 6, 30]

@export_group("Identity")
@export var type_id: StringName = &"swarmer"
@export var display_name := "Swarmer"
## Colour of the bug's blood: hit sprays, floor splats.
@export var ichor_color := Color("ffb03b")

@export_group("Stats")
@export var base_health := 30.0
@export var base_speed := 5.2
@export var contact_damage := 7.0
@export var contact_range := 0.85
## Bites are telegraphed: the bug slows, swells and rears up for this long,
## then lunges. It only connects if you're still within reach, so keep moving.
@export var bite_windup := 0.32
## Pause between bites from the same bug.
@export var bite_recover := 0.7
## Reach multiplier for the lunge at the end of the wind-up.
@export var bite_reach_mult := 1.3
## Move speed multiplier while winding up.
@export var bite_windup_speed := 0.25
@export var radius := 0.4
@export_range(0.0, 1.0) var knockback_resistance := 0.0
@export var salvage := 1

@export_group("Senses")
@export var sight_range := 7.0
@export var sight_cone_degrees := 120.0
## Asleep bugs only notice you this close (no cone).
@export var sleep_sight_range := 2.8
@export var investigate_speed := 0.55
@export var patrol_speed := 0.32

@export_group("Idle")
## Burrowed bugs only notice you this close (or on loud noise).
@export var burrow_sense_range := 2.4
## Move speed multiplier while wandering about unaware.
@export var wander_speed := 0.22

@export_group("Movement")
@export var acceleration := 38.0
@export var turn_speed := 14.0
@export var knockback_decay := 9.0
@export var hit_stagger := 0.25
@export var detour_time := 2.5
@export var bob_height := 0.07

@export_group("Entrance")
@export var emerge_duration := 0.45
@export var leap_duration := 0.65
@export var leap_height := 3.6
@export var drop_duration := 0.42
@export var drop_height := 11.0

@export_group("Animation")
## Ground speed (m/s) at which the model's "walk" clip plays at 1x.
@export var walk_anim_speed := 1.3
@export var max_anim_speed := 3.5
## Time (s) into the "attack" clip where the mandibles snap shut; the clip is
## sped up or slowed down so this lines up with the end of the bite wind-up.
@export var attack_anim_hit_time := 0.2

@export_group("Feedback")
@export var flash_duration := 0.07
@export var flash_material: Material = preload("res://scenes/materials/hit_flash.tres")

var state := State.INACTIVE
var tier := Tier.NORMAL
var health := 0.0
var max_health := 0.0
var speed := 5.0
var damage_mult := 1.0
var spawner: Spawner
var pooled := true

var _tier_scale := 1.0
var _home := Vector3.ZERO
var _patrol_to := Vector3.ZERO
var _patrol_forward := true
var _wait := 0.0
var _noise_pos := Vector3.ZERO
var _sense_t := 0.0
var _entrance_alerted := true
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
var _aura: MeshInstance3D
var _nameplate: Label3D
var _burn_t := 0.0
var _burn_dps := 0.0
var _burn_tick := 0.0
var _cryo_t := 0.0
var _corrode_t := 0.0
var _status_fx_t := 0.0
var _bite_t := -1.0
var _bite_cd := 0.0
## What an unaware bug is doing: &"sleep", &"feed" (around `_food`), &"burrow"
## (hidden under a mound), &"wander" (milling about home) or &"roam" (walking a
## route of waypoints between rooms). Set from spawn opts {"idle": ...}.
var idle: StringName = &"sleep"
var _food := Vector3.ZERO
var _wander_r := 0.0
var _wander_to := Vector3.INF
var _route: Array[Vector3] = []
var _route_i := 0
var _idle_t := 0.0
var _mound: Node3D
static var _mound_mat: StandardMaterial3D
static var _mound_glow: StandardMaterial3D
var _anim: AnimationPlayer
var _anim_lock := 0.0

static var _aura_mats := {}

@onready var visual: Node3D = $Visual
## Hit reactions: the model sits under a "Flinch" node that tilts away from each
## hit and squashes; heavy hits (knockback at or over the threshold, counters)
## stagger the bug briefly: no steering, no bites.
@export_group("Hit reactions")
@export var stagger_threshold := 9.0
@export var stagger_time := 0.28
var _flinch_node: Node3D
var _flinch := Vector2.ZERO
var _flinch_sq := 0.0
var _stagger_t := 0.0


func _ready() -> void:
	_los_query.collision_mask = 1
	_los_query.exclude = [get_rid()]
	_flinch_node = Node3D.new()
	_flinch_node.name = "Flinch"
	var kids := visual.get_children()
	visual.add_child(_flinch_node)
	for c in kids:
		c.reparent(_flinch_node, false)
	for n in visual.find_children("*", "GeometryInstance3D", true, false):
		_flash_targets.append(n)
	_anim = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_phase = randf() * TAU
	_aura = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.82
	tm.outer_radius = 1.0
	tm.rings = 32
	tm.ring_segments = 4
	_aura.mesh = tm
	_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_aura.position = Vector3(0, 0.05, 0)
	_aura.visible = false
	add_child(_aura)
	_build_mound()


# ==========================================================================
# Spawning
# ==========================================================================

## mode: &"dormant", &"patrol" (opts.to), &"burrow", &"drop", &"leap" (opts.from), &"chase".
## opts: tier, health_mult, speed_mult, alerted (entrances default to alerted), yaw.
func spawn_at(pos: Vector3, mode: StringName, opts := {}) -> void:
	tier = opts.get("tier", Tier.NORMAL)
	_activate(opts.get("health_mult", 1.0), opts.get("speed_mult", 1.0))
	damage_mult *= float(opts.get("damage_mult", 1.0))
	var p := Vector3(pos.x, 0.0, pos.z)
	_home = p
	_entrance_alerted = opts.get("alerted", mode != &"dormant" and mode != &"patrol")
	idle = opts.get("idle", &"sleep")
	_food = opts.get("food", p)
	_wander_r = float(opts.get("radius", 2.5 if idle == &"wander" else 0.0))
	_wander_to = Vector3.INF
	_route.assign(opts.get("route", []))
	_route_i = 0
	_idle_t = randf_range(0.5, 3.0)
	_set_mound(false)
	match mode:
		&"dormant":
			state = State.DORMANT
			global_position = p
			visual.rotation.y = opts.get("yaw", randf() * TAU)
			match idle:
				&"wander", &"roam":
					state = State.PATROL
					_patrol_to = p
				&"burrow":
					_set_mound(true)
				&"feed":
					_face_dir(_food - p, 1.0)
		&"patrol":
			state = State.PATROL
			global_position = p
			_patrol_to = opts.get("to", p)
			_patrol_forward = true
			_face_dir(_patrol_to - p, 1.0)
		&"burrow":
			state = State.EMERGE
			global_position = p
			visual.scale = Vector3.ONE * 0.1
			visual.position.y = -0.4
		&"drop":
			state = State.DROP
			_to = p
			global_position = p + Vector3(0.0, drop_height, 0.0)
		&"leap":
			state = State.LEAP
			_from = opts.get("from", p + Vector3(0, -3, 0))
			_to = p
			global_position = _from
			_face_dir(_to - _from, 1.0)
		_:
			state = State.CHASE
			global_position = p
	_on_spawned()


func _activate(health_mult: float, speed_mult: float) -> void:
	max_health = base_health * TIER_HEALTH[tier] * health_mult
	health = max_health
	speed = base_speed * TIER_SPEED[tier] * speed_mult * randf_range(0.92, 1.1)
	damage_mult = TIER_DAMAGE[tier]
	_tier_scale = TIER_SCALE[tier]
	_move_vel = Vector3.ZERO
	_knock = Vector3.ZERO
	_sep = Vector3.ZERO
	_state_t = 0.0
	_flash_t = 0.0
	_stuck_t = 0.0
	_detour_t = 0.0
	_wait = 0.0
	_sense_t = randf() * 0.2
	_detour_sign = 1.0 if randf() < 0.5 else -1.0
	_burn_t = 0.0
	_cryo_t = 0.0
	_corrode_t = 0.0
	_bite_t = -1.0
	_bite_cd = 0.0
	_set_flash(false)
	visual.scale = Vector3.ONE * _tier_scale
	visual.position = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	_anim_lock = 0.0
	_flinch = Vector2.ZERO
	_flinch_sq = 0.0
	_stagger_t = 0.0
	if _anim and _anim.has_animation(&"idle"):
		_anim.play(&"idle")
		_anim.seek(randf() * _anim.current_animation_length, true)
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	_update_tier_visuals()


func deactivate() -> void:
	state = State.INACTIVE
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	global_position = Vector3(0.0, -500.0, 0.0)
	if _nameplate:
		_nameplate.visible = false


func _update_tier_visuals() -> void:
	_aura.visible = tier != Tier.NORMAL
	if _aura.visible:
		if not _aura_mats.has(tier):
			var m := ShaderMaterial.new()
			m.shader = preload("res://scripts/shaders/neon_fade.gdshader")
			m.set_shader_parameter("tint", TIER_COLORS[tier])
			m.set_shader_parameter("energy", 2.2)
			m.set_shader_parameter("fade", 0.85)
			_aura_mats[tier] = m
		_aura.material_override = _aura_mats[tier]
		var s := radius * 1.9 * _tier_scale
		_aura.scale = Vector3(s, 0.12, s)
	if tier == Tier.PURPLE:
		if _nameplate == null:
			_nameplate = Label3D.new()
			_nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			_nameplate.no_depth_test = true
			_nameplate.font_size = 44
			_nameplate.outline_size = 12
			_nameplate.pixel_size = 0.008
			_nameplate.render_priority = 15
			_nameplate.modulate = Color("d79bff")
			_nameplate.outline_modulate = Color("1a0626")
			add_child(_nameplate)
		_nameplate.text = "ELITE " + display_name.to_upper()
		_nameplate.position = Vector3(0, 1.4 * _tier_scale + 0.4, 0)
		_nameplate.visible = true
		Game.elite_changed.emit(self)
	elif _nameplate:
		_nameplate.visible = false


# ==========================================================================
# Queries
# ==========================================================================

func is_active() -> bool:
	return state != State.INACTIVE


## Can the blade's target assist pick (and dash-strike to) this bug?
func is_targetable() -> bool:
	return state == State.CHASE or state == State.DORMANT or state == State.PATROL or state == State.INVESTIGATE


## True while winding up a bite: a blade cut now is a counter.
func is_counterable() -> bool:
	return _bite_t >= 0.0


func is_unaware() -> bool:
	return state == State.DORMANT or state == State.PATROL or state == State.INVESTIGATE


func get_facing() -> Vector3:
	var yaw := visual.rotation.y
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func get_hit_radius() -> float:
	return radius * _tier_scale


## Asleep bugs can be finished from any side; wandering ones only from behind.
func can_be_assassinated(to_player: Vector3) -> bool:
	if state == State.DORMANT:
		return true
	if state == State.PATROL or state == State.INVESTIGATE:
		return get_facing().dot(to_player.normalized()) < -0.2
	return false


## Blade attack on an unaware bug: instant silent kill for normal/blue tiers,
## a brutal (but loud) hit for gold/purple.
func assassinate(direction: Vector3, blade_damage: float) -> float:
	if tier <= Tier.BLUE:
		return take_hit(health + 1.0, direction, 2.0, Game.TEAM_PLAYER, &"silent")
	return take_hit(blade_damage * 4.0, direction, 2.0, Game.TEAM_PLAYER, &"slash")


# ==========================================================================
# Awareness
# ==========================================================================

## Called by the Hive Director for noise within earshot.
func hear_noise(pos: Vector3, loud: bool) -> void:
	if not is_unaware():
		return
	if loud or (Game.director and Game.director.level >= HiveDirector.AlertLevel.HUNTING):
		alert(false)
	elif idle == &"burrow" and state == State.DORMANT:
		return  # too deep to hear anything quiet
	else:
		_reset_pose()
		state = State.INVESTIGATE
		_noise_pos = Vector3(pos.x, 0.0, pos.z)
		_wait = 0.0


## Switch to hunting the player. `scream` wakes nearby bugs and raises the alert.
func alert(scream := true) -> void:
	if not is_active() or state == State.CHASE:
		return
	var was_unaware := is_unaware()
	if state == State.EMERGE or state == State.LEAP or state == State.DROP:
		_entrance_alerted = true
		return
	_reset_pose()
	if idle == &"burrow" and state == State.DORMANT:
		# Burst out of the mound, then hunt.
		_set_mound(false)
		state = State.EMERGE
		_state_t = 0.0
		_entrance_alerted = true
		visual.scale = Vector3.ONE * 0.1
		visual.position.y = -0.4
		if Game.fx:
			Game.fx.burst(global_position + Vector3.UP * 0.2, Vector3.UP, 0.7)
	else:
		state = State.CHASE
	idle = &"sleep"
	if was_unaware:
		_on_alerted()
		if scream and Game.director:
			Game.director.on_enemy_spotted(self)


func _tick_senses(delta: float) -> void:
	_sense_t -= delta
	if _sense_t > 0.0:
		return
	_sense_t = 0.2 + randf() * 0.05
	if _can_see_player():
		alert(true)


func _can_see_player() -> bool:
	var p := Game.player
	if p == null or not p.alive:
		return false
	var to := p.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	var sight_mult := 1.0 - p.stealth
	if state == State.DORMANT:
		var r := burrow_sense_range if idle == &"burrow" else sleep_sight_range
		if dist > r * sight_mult:
			return false
	else:
		if dist > sight_range * sight_mult:
			return false
		if dist > 1.8 and get_facing().dot(to / dist) < cos(deg_to_rad(sight_cone_degrees * 0.5)):
			return false
	return _has_line_of_sight(p.global_position)


func _has_line_of_sight(target: Vector3) -> bool:
	_los_query.from = global_position + Vector3.UP * 0.5
	_los_query.to = target + Vector3.UP * 0.5
	return get_world_3d().direct_space_state.intersect_ray(_los_query).is_empty()


# ==========================================================================
# Update
# ==========================================================================

func set_separation(v: Vector3) -> void:
	_sep = v


func _physics_process(delta: float) -> void:
	_state_t += delta
	_stagger_t = maxf(_stagger_t - delta, 0.0)
	_update_flinch(delta)
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_set_flash(false)
	if _burn_t > 0.0 or _cryo_t > 0.0 or _corrode_t > 0.0:
		_tick_status(delta)
		if not is_active():
			return
	_update_anim(delta)
	if _custom_tick(delta):
		return
	match state:
		State.DORMANT:
			_tick_idle(delta)
			_tick_senses(delta)
		State.PATROL:
			_tick_patrol(delta)
			_tick_senses(delta)
		State.INVESTIGATE:
			_tick_investigate(delta)
			_tick_senses(delta)
		State.EMERGE:
			_tick_emerge()
		State.LEAP:
			_tick_leap()
		State.DROP:
			_tick_drop()
		State.CHASE:
			if _stagger_t > 0.0:
				_settle(delta)
			else:
				_tick_chase(delta)


func _tick_patrol(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		_settle(delta)
		return
	if not _route.is_empty():
		# Roaming pack: walk the route through the doorways, pause at each stop.
		var wp := _route[_route_i]
		_steer(wp, speed * patrol_speed, delta, true)
		if Vector2(wp.x - global_position.x, wp.z - global_position.z).length() < 1.6:
			_route_i = (_route_i + 1) % _route.size()
			_wait = randf_range(0.6, 2.0)
		return
	if _wander_r > 0.0:
		# Milling about: short slow walks to random nearby spots, with pauses.
		_idle_t -= delta
		if _wander_to == Vector3.INF or _idle_t <= 0.0:
			_wander_to = _pick_wander_point(_home, _wander_r)
			_idle_t = randf_range(2.5, 5.0)
		var d := Vector2(_wander_to.x - global_position.x, _wander_to.z - global_position.z).length()
		if d < 0.5:
			_wander_to = Vector3.INF
			_wait = randf_range(1.0, 3.5)
			_settle(delta)
			return
		_steer(_wander_to, speed * wander_speed, delta, false)
		return
	var target := _patrol_to if _patrol_forward else _home
	_steer(target, speed * patrol_speed, delta, false)
	if Vector2(target.x - global_position.x, target.z - global_position.z).length() < 0.8:
		_patrol_forward = not _patrol_forward
		_wait = 1.2


func _tick_investigate(delta: float) -> void:
	var d := Vector2(_noise_pos.x - global_position.x, _noise_pos.z - global_position.z).length()
	if d > 1.5 and _wait <= 0.0:
		_steer(_noise_pos, speed * investigate_speed, delta, true)
		return
	_settle(delta)
	_wait += delta
	if _wait > 2.5:
		# Lost interest: mill about here.
		state = State.PATROL
		_home = global_position
		idle = &"wander"
		_wander_r = 2.5
		_wander_to = Vector3.INF
		_route.clear()


func _tick_emerge() -> void:
	var t := clampf(_state_t / emerge_duration, 0.0, 1.0)
	var pop := 1.0 + sin(t * PI) * 0.35
	visual.scale = Vector3.ONE * _tier_scale * lerpf(0.1, 1.0, t) * pop
	visual.position.y = lerpf(-0.4, 0.0, t)
	if t >= 1.0:
		_end_entrance()


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
			Game.fx.on_enemy_land(_to, false)
		_end_entrance()


func _tick_drop() -> void:
	var t := clampf(_state_t / drop_duration, 0.0, 1.0)
	global_position = _to + Vector3(0.0, drop_height * (1.0 - t * t), 0.0)
	if t >= 1.0:
		global_position = _to
		if Game.fx:
			Game.fx.on_enemy_land(_to, true)
		_end_entrance()


func _end_entrance() -> void:
	visual.scale = Vector3.ONE * _tier_scale
	visual.position = Vector3.ZERO
	state = State.CHASE if _entrance_alerted else State.DORMANT
	_state_t = 0.0


func _tick_chase(delta: float) -> void:
	var player := Game.player
	var goal := player.global_position if player else global_position
	var winding := _bite_t >= 0.0
	_steer(goal, speed * (bite_windup_speed if winding else 1.0), delta, true)
	if winding:
		# Telegraph: swell and rear up before the lunge.
		var k := 1.0 - _bite_t / bite_windup
		visual.scale = Vector3.ONE * _tier_scale * (1.0 + 0.22 * k)
		visual.position.y = 0.12 * k
		visual.rotation.x = 0.5 * k
	else:
		visual.position.y = absf(sin(_state_t * 22.0 + _phase)) * bob_height
	if player and player.alive:
		_attack_tick(player, delta)
	elif winding:
		_end_bite()


## Move toward `goal` (routing through doorways if `use_nav`), with swarm
## separation, knockback, and wall-following when wedged against cover.
func _steer(goal: Vector3, move_speed: float, delta: float, use_nav: bool) -> void:
	var g := goal
	if use_nav and Game.level:
		g = Game.level.get_nav_target(global_position, goal, get_hit_radius())
	var to := g - global_position
	to.y = 0.0
	var dir := to.normalized() if to.length_squared() > 0.01 else Vector3.ZERO
	if _detour_t > 0.0:
		_detour_t -= delta
		_los_t -= delta
		if _los_t <= 0.0:
			_los_t = 0.15
			if _has_line_of_sight(g):
				_detour_t = 0.0
		if _detour_t > 0.0:
			dir = (dir * 0.25 + _detour).normalized()
	var desired := dir * move_speed * _speed_factor(dir) * (0.5 if _cryo_t > 0.0 else 1.0)
	if state == State.CHASE or not _route.is_empty():
		desired += _sep
	_move_vel = _move_vel.move_toward(desired, acceleration * delta)
	velocity = _move_vel + _knock
	move_and_slide()
	global_position.y = 0.0
	_knock *= exp(-knockback_decay * delta)
	_update_stuck(dir, move_speed, delta)
	var face := _facing_target()
	if face == Vector3.ZERO:
		face = _move_vel + _knock * 0.3
	_face_dir(face, delta)


## Stand still but still get shoved around by knockback.
func _settle(delta: float) -> void:
	if _knock.length_squared() < 0.01:
		return
	velocity = _knock
	move_and_slide()
	global_position.y = 0.0
	_knock *= exp(-knockback_decay * delta)


func _face_dir(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.04:
		return
	var yaw := atan2(-dir.x, -dir.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, yaw, clampf(1.0 - exp(-turn_speed * delta), 0.0, 1.0))


## Detect "pushing into a wall without progress" and start (or reverse) a sidestep.
func _update_stuck(intended: Vector3, move_speed: float, delta: float) -> void:
	if intended == Vector3.ZERO or move_speed <= 0.01:
		_stuck_t = 0.0
		return
	var actual := get_real_velocity()
	actual.y = 0.0
	if get_slide_collision_count() > 0 and actual.dot(intended) < move_speed * 0.35:
		_stuck_t += delta
	else:
		_stuck_t = maxf(_stuck_t - delta * 2.0, 0.0)
	if _stuck_t > 0.25:
		_stuck_t = 0.0
		if _detour_t > 0.0:
			_detour_sign = -_detour_sign
			_detour = -_detour
		else:
			_detour = Vector3(-intended.z, 0.0, intended.x) * _detour_sign
		_detour_t = detour_time
		_los_t = 0.3


# ==========================================================================
# Damage
# ==========================================================================

## Returns the damage actually dealt (0 if blocked or already dead).
## kind: &"bullet", &"slash", &"counter", &"silent", &"explosion", &"laser", &"beam", &"crush", &"reflect", &"self".
func take_hit(damage: float, direction: Vector3, knockback: float, _source_team: int = 0, kind: StringName = &"bullet") -> float:
	if state == State.INACTIVE:
		return 0.0
	var dealt := _modify_damage(damage, direction, kind)
	if dealt <= 0.0:
		if Game.fx:
			Game.fx.on_blocked(global_position + Vector3.UP * 0.7, direction)
		if is_unaware():
			alert(true)
		return 0.0
	if _corrode_t > 0.0:
		dealt *= 1.25
	if is_unaware() and kind != &"silent" and Profile.has_legendary("hunters_eye"):
		dealt *= 2.0
	health -= dealt
	if kind != &"burn":
		_flash_t = flash_duration
		_set_flash(true)
	var push := Vector3(direction.x, 0.0, direction.z)
	push = push.normalized() if push.length_squared() > 0.0001 else Vector3.ZERO
	_knock += push * knockback * (1.0 - knockback_resistance)
	_move_vel *= hit_stagger
	# Visible reaction: tilt the model away from the hit, squash it, maybe stagger.
	var kb := knockback * (1.0 - knockback_resistance)
	var amt := clampf(kb / 12.0, 0.12, 0.55)
	if kind == &"burn":
		amt = 0.0
	var local := Basis(Vector3.UP, visual.rotation.y).inverse() * push
	_flinch += Vector2(local.z, -local.x) * amt
	_flinch = _flinch.limit_length(0.7)
	_flinch_sq = maxf(_flinch_sq, amt)
	if kb >= stagger_threshold or kind == &"counter":
		_stagger_t = maxf(_stagger_t, stagger_time * (1.0 - knockback_resistance))
	if _bite_t >= 0.0 and kind in [&"slash", &"slash_crit", &"counter"]:
		_end_bite()  # blade hits interrupt a bite
	var killed := health <= 0.0
	if Game.fx and kind != &"silent":
		Game.fx.on_enemy_hit(global_position, dealt, killed, kind, get_instance_id())
	if killed:
		_die(push, kind)
	elif is_unaware() and kind != &"silent":
		alert(true)
	return dealt


func _die(direction: Vector3, kind: StringName) -> void:
	var pos := global_position
	var was_elite := tier == Tier.PURPLE
	_on_death(direction, kind)
	if Game.fx:
		Game.fx.on_enemy_killed(pos + Vector3.UP * 0.35 * _tier_scale, direction, tier, kind == &"silent", kind)
		if kind != &"self":
			Game.fx.on_enemy_body(self, direction, kind)
	if kind != &"self":
		Game.register_kill()
		Game.on_enemy_killed(self, pos, kind)
		if Game.pickups:
			var mult: float = Game.director.loot_multiplier() if Game.director else 1.0
			Game.pickups.drop_salvage(pos, roundi(salvage * TIER_SALVAGE[tier] * mult))
	if was_elite:
		Game.elite_changed.emit(null)
	if spawner:
		spawner.release(self)
	else:
		deactivate()


# ==========================================================================
# Idle life (unaware bugs)
# ==========================================================================

func _tick_idle(delta: float) -> void:
	match idle:
		&"feed":
			# Heads down over the carcass, pecking; now and then shuffle round it.
			_idle_t -= delta
			if _idle_t <= 0.0:
				_idle_t = randf_range(2.5, 6.0)
				var ang := atan2(global_position.z - _food.z, global_position.x - _food.x) + randf_range(-0.9, 0.9)
				var r := randf_range(0.9, 1.4) * _tier_scale
				_wander_to = _food + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
			if _wander_to != Vector3.INF and Vector2(_wander_to.x - global_position.x, _wander_to.z - global_position.z).length() > 0.15:
				_steer(_wander_to, speed * 0.16, delta, false)
			else:
				_wander_to = Vector3.INF
				_settle(delta)
			_face_dir(_food - global_position, delta)
			var peck := maxf(sin(_state_t * 7.0 + _phase), 0.0)
			visual.rotation.x = -0.25 - 0.3 * peck
			visual.position.y = -0.04 * peck
		&"burrow":
			_settle(delta)
			if _mound:
				_mound.scale = Vector3(1.0, 1.0 + 0.1 * sin(_state_t * 1.7 + _phase), 1.0) * _tier_scale
		_:
			# Asleep: breathing, and the odd twitch.
			_settle(delta)
			visual.position.y = sin(_state_t * 2.0 + _phase) * 0.02
			visual.scale = Vector3.ONE * _tier_scale * (1.0 + 0.035 * sin(_state_t * 1.8 + _phase))
			_idle_t -= delta
			if _idle_t <= 0.0:
				_idle_t = randf_range(3.0, 7.0)
				visual.rotation.y += randf_range(-0.5, 0.5)


## Random walkable spot near `center`, inside the same convex region (so a
## straight walk gets there). Falls back to `center`.
func _pick_wander_point(center: Vector3, radius: float) -> Vector3:
	var lvl := Game.level
	if lvl == null:
		return center
	var home_r := lvl.region_of(center)
	for attempt in 8:
		var a := randf() * TAU
		var r := sqrt(randf()) * radius
		var q := Vector3(center.x + cos(a) * r, 0.0, center.z + sin(a) * r)
		if lvl.region_of(q) == home_r and not lvl.is_blocked(q, 0.4):
			return q
	return center


func _reset_pose() -> void:
	visual.rotation.x = 0.0
	visual.position.y = 0.0
	visual.scale = Vector3.ONE * _tier_scale


## Burrowed: the bug is hidden and a breathing hive mound sits in its place.
func _set_mound(on: bool) -> void:
	if _mound:
		_mound.visible = on
	visual.visible = not on


func _build_mound() -> void:
	if _mound_mat == null:
		_mound_mat = StandardMaterial3D.new()
		_mound_mat.albedo_color = Color("26281d")
		_mound_mat.roughness = 0.9
		_mound_glow = StandardMaterial3D.new()
		_mound_glow.albedo_color = Color(0.05, 0.08, 0.02)
		_mound_glow.emission_enabled = true
		_mound_glow.emission = Color("8dff2e")
		_mound_glow.emission_energy_multiplier = 1.6
	_mound = Node3D.new()
	_mound.name = "Mound"
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.62
	sm.height = 0.5
	sm.radial_segments = 12
	sm.rings = 6
	dome.mesh = sm
	dome.material_override = _mound_mat
	dome.position.y = 0.02
	_mound.add_child(dome)
	# Glowing cracks on top.
	for i in 3:
		var crack := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, 0.03, 0.05)
		crack.mesh = bm
		crack.material_override = _mound_glow
		crack.position = Vector3(0.0, 0.2, 0.0)
		crack.rotation.y = i * PI / 3.0 + 0.3
		_mound.add_child(crack)
	for i in 4:
		var clod := MeshInstance3D.new()
		var cm := SphereMesh.new()
		cm.radius = 0.14
		cm.height = 0.16
		cm.radial_segments = 6
		cm.rings = 3
		clod.mesh = cm
		clod.material_override = _mound_mat
		var a := i * TAU / 4.0 + 0.4
		clod.position = Vector3(cos(a) * 0.62, 0.03, sin(a) * 0.62)
		_mound.add_child(clod)
	_mound.visible = false
	add_child(_mound)


# ==========================================================================
# Model animation (only for models that ship an AnimationPlayer)
# ==========================================================================

## Clips: "idle" and "walk" loop, others are one-shots that hold until done.
func _update_anim(delta: float) -> void:
	if _anim == null:
		return
	if _anim_lock > 0.0:
		_anim_lock -= delta
		return
	var spd := Vector2(_move_vel.x + _knock.x, _move_vel.z + _knock.z).length()
	if state == State.EMERGE or state == State.LEAP or state == State.DROP:
		_play_anim(&"walk", max_anim_speed)
	elif spd > 0.3:
		_play_anim(&"walk", clampf(spd / walk_anim_speed, 0.5, max_anim_speed))
	else:
		_play_anim(&"idle", 0.5 if state == State.DORMANT else 1.0)


func _play_anim(clip: StringName, speed_scale: float) -> void:
	if not _anim.has_animation(clip):
		return
	if _anim.current_animation != clip:
		_anim.play(clip, 0.12)
	_anim.speed_scale = speed_scale


func play_anim_oneshot(clip: StringName, speed_scale := 1.0) -> void:
	if _anim == null or not _anim.has_animation(clip):
		return
	_anim.play(clip, 0.05)
	_anim.speed_scale = speed_scale
	_anim_lock = _anim.get_animation(clip).length / maxf(speed_scale, 0.01)


func _update_flinch(delta: float) -> void:
	if _flinch_node == null:
		return
	_flinch = _flinch.lerp(Vector2.ZERO, 1.0 - exp(-12.0 * delta))
	_flinch_sq = move_toward(_flinch_sq, 0.0, delta * 3.5)
	_flinch_node.rotation = Vector3(_flinch.x, 0.0, _flinch.y)
	_flinch_node.scale = Vector3(1.0 + 0.16 * _flinch_sq, 1.0 - 0.2 * _flinch_sq, 1.0 + 0.16 * _flinch_sq)


func is_staggered() -> bool:
	return _stagger_t > 0.0


func _set_flash(on: bool) -> void:
	for g in _flash_targets:
		g.material_override = flash_material if on else null


# ==========================================================================
# Status effects (from gear elements)
# ==========================================================================

## burn: `power` = total damage over 3 s. cryo: 50% slow for 2 s. corrode: +25% damage taken for 4 s.
func apply_status(kind: StringName, power: float) -> void:
	if not is_active():
		return
	match kind:
		&"burn":
			_burn_dps = maxf(_burn_dps if _burn_t > 0.0 else 0.0, power / 3.0)
			_burn_t = 3.0
		&"cryo":
			_cryo_t = maxf(_cryo_t, 2.0 * power)
		&"corrode":
			_corrode_t = maxf(_corrode_t, 4.0 * power)
	if Game.fx:
		Game.fx.status_pop(global_position + Vector3.UP * 1.0, kind)


func _tick_status(delta: float) -> void:
	_cryo_t = maxf(_cryo_t - delta, 0.0)
	_corrode_t = maxf(_corrode_t - delta, 0.0)
	_status_fx_t -= delta
	if _status_fx_t <= 0.0 and Game.fx:
		_status_fx_t = 0.35
		var c := Color("ff7a1a") if _burn_t > 0.0 else (Color("9fe8ff") if _cryo_t > 0.0 else Color("b6ff3d"))
		Game.fx.spark(global_position + Vector3.UP * 0.6, c, Vector3.UP)
	if _burn_t > 0.0:
		_burn_t -= delta
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick = 0.5
			take_hit(_burn_dps * 0.5, Vector3.ZERO, 0.0, Game.TEAM_PLAYER, &"burn")


# ==========================================================================
# Hooks for special enemies
# ==========================================================================

func _on_spawned() -> void:
	pass


func _on_alerted() -> void:
	pass


## Return true to replace the default state machine for this frame.
func _custom_tick(_delta: float) -> bool:
	return false


## Return 0 to block the hit (e.g. a shield).
func _modify_damage(amount: float, _direction: Vector3, _kind: StringName) -> float:
	return amount


## Called every chase frame while the player is alive. Default: a telegraphed
## contact bite (wind-up, then a short lunge that hits if you're still close).
func _attack_tick(player: Player, delta: float) -> void:
	var d := Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z)
	var reach := contact_range * _tier_scale
	if _bite_t >= 0.0:
		_bite_t -= delta
		if _bite_t >= 0.0:
			return
		_end_bite()
		var dir := Vector3(d.x, 0.0, d.y).normalized()
		if d.length() < reach * bite_reach_mult and player.take_damage(contact_damage * damage_mult, global_position):
			_knock = -dir * 10.0
			_move_vel = Vector3.ZERO
		else:
			_knock += dir * 5.0  # whiffed lunge
		return
	_bite_cd -= delta
	if _bite_cd <= 0.0 and d.length() < reach * 1.1:
		_bite_t = bite_windup
		# time the clip so its snap lands when the bite resolves
		play_anim_oneshot(&"attack", attack_anim_hit_time / maxf(bite_windup, 0.05))


func _end_bite() -> void:
	_bite_t = -1.0
	_bite_cd = bite_recover * randf_range(0.85, 1.15)
	visual.scale = Vector3.ONE * _tier_scale
	visual.rotation.x = 0.0


func _on_death(_direction: Vector3, _kind: StringName) -> void:
	pass


## Movement speed multiplier for a move direction (shield bugs can't strafe).
func _speed_factor(_dir: Vector3) -> float:
	return 1.0


## Direction to face instead of the movement direction (ZERO = movement).
func _facing_target() -> Vector3:
	return Vector3.ZERO
