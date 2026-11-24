class_name ProjectilePool
extends Node3D
## Pre-instantiates projectiles once and recycles them (no allocation while firing).

@export var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
@export var pool_size := 220

var _pool: Array[Projectile] = []
var _next := 0


func _ready() -> void:
	Game.projectiles = self
	for i in pool_size:
		var p: Projectile = projectile_scene.instantiate()
		p.pool = self
		add_child(p)
		_pool.append(p)


## payload: see Projectile (damage, knockback, pierce, crit, elements, blast, color...).
func fire(origin: Vector3, direction: Vector3, speed: float, lifetime: float, payload: Dictionary) -> Projectile:
	# Round-robin search for a free bolt; if all are in flight, recycle the oldest.
	var p: Projectile = null
	for i in _pool.size():
		var candidate := _pool[(_next + i) % _pool.size()]
		if not candidate.active:
			p = candidate
			_next = (_next + i + 1) % _pool.size()
			break
	if p == null:
		p = _pool[_next]
		_next = (_next + 1) % _pool.size()
	p.launch(origin, direction, speed, lifetime, payload)
	return p


func active_count() -> int:
	var n := 0
	for p in _pool:
		if p.active:
			n += 1
	return n
