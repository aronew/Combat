class_name Projectile
extends Node3D
## Pooled bolt. Moves manually, sweeps a ray against the world (railings,
## crates, barrels) and a segment test against the swarm's spatial grid, so fast
## bolts never tunnel through small bugs. Carries a payload from the gun:
##   damage, knockback, pierce, crit_chance/crit_mult, blast (launcher radius),
##   elements {burn, shock, cryo, corrode: chance}, splitter, generation, color, scale.

@export var hit_radius := 0.22

var active := false
var pool: ProjectilePool

var _velocity := Vector3.ZERO
var _life := 0.0
var _pierced := 0
var _p := {}
var _ray := PhysicsRayQueryParameters3D.new()

## Shared materials per bolt colour: [glow, core]. A handful of colours exist
## (one per gun archetype), so this stays tiny and needs no per-instance uniforms.
static var _mats := {}

@onready var glow: MeshInstance3D = $Glow
@onready var core: MeshInstance3D = $Core


func _ready() -> void:
	_ray.collision_mask = 1
	_ray.collide_with_areas = false
	deactivate()


func launch(origin: Vector3, direction: Vector3, speed: float, lifetime: float, payload: Dictionary) -> void:
	global_position = origin
	_velocity = direction.normalized() * speed
	_life = lifetime
	_pierced = 0
	_p = payload
	look_at(origin + _velocity, Vector3.UP)
	var c: Color = payload.get("color", Color("19f4ff"))
	var m: Array = _material_for(c)
	glow.material_override = m[0]
	core.material_override = m[1]
	var s: float = payload.get("scale", 1.0)
	scale = Vector3(s, s, s * (1.0 + 0.4 * (s - 1.0)))
	active = true
	visible = true
	set_physics_process(true)


func _material_for(c: Color) -> Array:
	var key := c.to_html()
	if not _mats.has(key):
		var g: ShaderMaterial = glow.material_override.duplicate()
		var k: ShaderMaterial = core.material_override.duplicate()
		g.set_shader_parameter("bolt_tint", c)
		k.set_shader_parameter("bolt_tint", c)
		_mats[key] = [g, k]
	return _mats[key]


func deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		if _p.get("blast", 0.0) > 0.0:
			_detonate(global_position)
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
			_hit_enemy(enemy)
			if not active:
				return
			_pierced += 1
			if _pierced > int(_p.get("pierce", 0)):
				deactivate()
				return

	if not wall.is_empty():
		var col: Object = wall.collider
		if _p.get("blast", 0.0) > 0.0:
			_detonate(wall.position + wall.normal * 0.3)
		else:
			if col and col.has_method("take_hit") and not (col is Enemy):
				col.take_hit(_p.get("damage", 10.0), _velocity.normalized(), _p.get("knockback", 5.0), Game.TEAM_PLAYER, &"bullet")
			if Game.fx:
				Game.fx.on_wall_hit(wall.position, wall.normal)
		deactivate()
		return
	global_position = to


func _hit_enemy(enemy: Enemy) -> void:
	var dir := _velocity.normalized()
	if _p.get("blast", 0.0) > 0.0:
		_detonate(enemy.global_position + Vector3.UP * 0.4)
		deactivate()
		return
	var dmg: float = _p.get("damage", 10.0)
	var crit := randf() < float(_p.get("crit_chance", 0.0))
	if crit:
		dmg *= float(_p.get("crit_mult", 1.5))
	var was_alive := enemy.is_active()
	var dealt := enemy.take_hit(dmg, dir, _p.get("knockback", 5.0), Game.TEAM_PLAYER, &"crit" if crit else &"bullet")
	if dealt <= 0.0:
		return
	if Game.fx:
		Game.fx.on_projectile_hit(enemy.global_position + Vector3.UP * 0.4, dir)
	_apply_elements(enemy, dealt)
	if was_alive and not enemy.is_active() and _p.get("splitter", false) and int(_p.get("generation", 0)) == 0:
		_split(enemy.global_position + Vector3.UP * 1.0, dir)


func _apply_elements(enemy: Enemy, dealt: float) -> void:
	var el: Dictionary = _p.get("elements", {})
	if el.is_empty():
		return
	var power := 1.0 + float(_p.get("element_power", 0.0))
	if randf() < el.get("burn", 0.0):
		enemy.apply_status(&"burn", dealt * 0.6 * power)
	if randf() < el.get("cryo", 0.0):
		enemy.apply_status(&"cryo", power)
	if randf() < el.get("corrode", 0.0):
		enemy.apply_status(&"corrode", power)
	if randf() < el.get("shock", 0.0):
		Game.shock_chain(enemy, dealt * 0.6 * power, 2)


func _detonate(pos: Vector3) -> void:
	var r: float = _p.get("blast", 3.0)
	var dmg: float = _p.get("damage", 30.0)
	if randf() < float(_p.get("crit_chance", 0.0)):
		dmg *= float(_p.get("crit_mult", 1.5))
	Game.explode(pos, r, dmg, dmg * 0.25, _p.get("knockback", 8.0) + 6.0, null, 0.7 + r * 0.25)


## Splitter legendary: three weaker bolts fan out from the kill.
func _split(pos: Vector3, dir: Vector3) -> void:
	if Game.projectiles == null:
		return
	var child := _p.duplicate()
	child.generation = 1
	child.damage = float(_p.get("damage", 10.0)) * 0.6
	child.pierce = 0
	for k in 3:
		var d := dir.rotated(Vector3.UP, deg_to_rad(-35.0 + 35.0 * k))
		Game.projectiles.fire(pos, d, _velocity.length() * 0.8, 0.5, child)
