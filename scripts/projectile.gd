class_name Projectile
extends Node3D
## Pooled cyan plasma bolt. Moves manually, sweeps a ray against the world
## (railings, crates) and a segment test against the swarm's spatial grid,
## so fast bolts never tunnel through small bugs.

@export var hit_radius := 0.22
## How many enemies a bolt can pass through before it stops (0 = none).
@export var pierce := 0

var active := false
var pool: ProjectilePool

var _velocity := Vector3.ZERO
var _damage := 0.0
var _life := 0.0
var _knockback := 0.0
var _pierced := 0
var _ray := PhysicsRayQueryParameters3D.new()


func _ready() -> void:
	_ray.collision_mask = 1
	_ray.collide_with_areas = false
	deactivate()


func launch(origin: Vector3, direction: Vector3, speed: float, damage: float, lifetime: float, knockback: float) -> void:
	global_position = origin
	_velocity = direction.normalized() * speed
	_damage = damage
	_life = lifetime
	_knockback = knockback
	_pierced = 0
	look_at(origin + _velocity, Vector3.UP)
	active = true
	visible = true
	set_physics_process(true)


func deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		deactivate()
		return
	var from := global_position
	var to := from + _velocity * delta

	_ray.from = from
	_ray.to = to
	var wall := get_world_3d().direct_space_state.intersect_ray(_ray)
	var seg_end: Vector3 = to if wall.is_empty() else wall.position

	if Game.spawner:
		var enemy := Game.spawner.find_enemy_on_segment(from, seg_end, hit_radius)
		if enemy:
			var dealt := enemy.take_hit(_damage, _velocity.normalized(), _knockback, Game.TEAM_PLAYER, &"bullet")
			if Game.fx and dealt > 0.0:
				Game.fx.on_projectile_hit(enemy.global_position + Vector3.UP * 0.4, _velocity.normalized())
			_pierced += 1
			if _pierced > pierce:
				deactivate()
				return

	if not wall.is_empty():
		var col: Object = wall.collider
		if col and col.has_method("take_hit") and not (col is Enemy):
			col.take_hit(_damage, _velocity.normalized(), _knockback, Game.TEAM_PLAYER, &"bullet")
		if Game.fx:
			Game.fx.on_wall_hit(wall.position, wall.normal)
		deactivate()
		return
	global_position = to
