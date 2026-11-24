class_name SentryTurret
extends Enemy
## Rooted hive turret. Asleep until it sees you (short range, any direction) or
## hears gunfire. Then: track you, show a red aim line, lock the aim briefly,
## and fire a beam that hurts you AND every bug in its path. Roll sideways when
## the line locks, use cover, lure bugs into the line, or parry it with the
## blade to send the beam back into the turret.

@export_group("Beam")
@export var beam_range := 22.0
@export var fire_interval := 2.4
@export var charge_time := 0.95
@export var lock_time := 0.3
@export var beam_player_damage := 20.0
@export var beam_bug_damage := 60.0
@export var beam_width := 0.55
@export var reflect_damage := 260.0
@export var head_turn_speed := 5.0

var _cd := 1.0
var _charge := -1.0
var _aim := Vector3.FORWARD
var _beam_t := 0.0
var _beam_ray := PhysicsRayQueryParameters3D.new()

@onready var head: Node3D = $Visual/Head
@onready var telegraph: MeshInstance3D = $Telegraph
@onready var beam: MeshInstance3D = $Beam
@onready var beam_mat: ShaderMaterial = beam.material_override


func _ready() -> void:
	super()
	pooled = false
	telegraph.top_level = true
	beam.top_level = true
	telegraph.visible = false
	beam.visible = false
	_beam_ray.collision_mask = 1
	_beam_ray.exclude = [get_rid()]


func _on_spawned() -> void:
	speed = 0.0
	_cd = 1.0
	_charge = -1.0
	telegraph.visible = false
	beam.visible = false


func can_be_assassinated(_to_player: Vector3) -> bool:
	return state == State.DORMANT


func deactivate() -> void:
	super()
	if is_node_ready():
		telegraph.visible = false
		beam.visible = false


func _custom_tick(delta: float) -> bool:
	_knock = Vector3.ZERO
	if _beam_t > 0.0:
		_beam_t -= delta
		beam_mat.set_shader_parameter("fade", clampf(_beam_t / 0.2, 0.0, 1.0))
		beam.visible = _beam_t > 0.0
	if state == State.DORMANT:
		head.rotation.x = 0.5  # folded down while asleep
		_tick_senses(delta)
		return true
	if state != State.CHASE:
		return true
	head.rotation.x = lerpf(head.rotation.x, 0.0, 0.2)
	var p := Game.player
	if p == null or not p.alive:
		telegraph.visible = false
		return true
	var to := p.global_position - global_position
	to.y = 0.0
	if _charge < 0.0:
		_turn_head(to, delta)
		_cd -= delta
		if _cd <= 0.0 and to.length() < beam_range and _has_line_of_sight(p.global_position):
			_charge = charge_time
			_aim = to.normalized()
	else:
		_charge -= delta
		if _charge > lock_time and to.length_squared() > 0.01:
			_aim = _aim.slerp(to.normalized(), clampf(10.0 * delta, 0.0, 1.0)).normalized()
		_turn_head(_aim, delta * 3.0)
		_update_telegraph()
		if _charge <= 0.0:
			_fire()
			_charge = -1.0
			_cd = fire_interval
			telegraph.visible = false
	return true


func _turn_head(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.01:
		return
	var yaw := atan2(-dir.x, -dir.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, yaw, clampf(head_turn_speed * delta, 0.0, 1.0))


func _beam_points() -> Array[Vector3]:
	var origin := global_position + Vector3.UP * 1.05 + _aim * 0.6
	var end := origin + _aim * beam_range
	_beam_ray.from = origin
	_beam_ray.to = end
	var hit := get_world_3d().direct_space_state.intersect_ray(_beam_ray)
	if not hit.is_empty():
		end = hit.position
	return [origin, end]


func _update_telegraph() -> void:
	var pts := _beam_points()
	_place_line(telegraph, pts[0], pts[1])
	telegraph.visible = fmod(_charge * 14.0, 1.0) > 0.3 or _charge < lock_time


func _place_line(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	mi.global_position = (a + b) * 0.5
	mi.look_at(b, Vector3.UP)
	mi.scale = Vector3(1.0, 1.0, maxf(length, 0.01))


func _fire() -> void:
	var pts := _beam_points()
	var origin := pts[0]
	var end := pts[1]
	_place_line(beam, origin, end)
	beam.visible = true
	_beam_t = 0.2
	beam_mat.set_shader_parameter("fade", 1.0)
	Game.shake(0.12)
	if Game.director:
		Game.director.make_noise(global_position, 10.0, 0.8)

	# Barrels, nests, anything damageable the beam stops on.
	_beam_ray.from = origin
	_beam_ray.to = origin + _aim * beam_range
	var hit := get_world_3d().direct_space_state.intersect_ray(_beam_ray)
	if not hit.is_empty() and hit.collider and hit.collider != self and hit.collider.has_method("take_hit"):
		hit.collider.take_hit(beam_bug_damage, _aim, 3.0, Game.TEAM_HIVE, &"beam")

	var p := Game.player
	if p and p.alive:
		var pp := Vector3(p.global_position.x, 0.0, p.global_position.z)
		var q := Geometry3D.get_closest_point_to_segment(pp, Vector3(origin.x, 0, origin.z), Vector3(end.x, 0, end.z))
		if q.distance_to(pp) < beam_width:
			if p.is_parrying_toward(global_position):
				take_hit(reflect_damage, -_aim, 0.0, Game.TEAM_PLAYER, &"reflect")
				if Game.fx:
					Game.fx.text_popup(p.global_position + Vector3.UP * 2.0, "PARRY!", Color("19f4ff"), 1.3)
				Game.hitstop(0.09)
				return
			p.take_damage(beam_player_damage * damage_mult, global_position)
	# Friendly fire: the beam cuts through other bugs.
	if Game.spawner:
		for e in Game.spawner.enemies_on_segment(origin, end, beam_width * 0.5):
			if e != self:
				e.take_hit(beam_bug_damage, _aim, 5.0, Game.TEAM_HIVE, &"beam")
