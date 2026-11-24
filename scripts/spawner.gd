class_name Spawner
extends Node3D
## Enemy pools + spawn execution + spatial hash.
## - Pre-instantiates a pool per enemy type and recycles them.
## - Burrow and drop-in spawns are telegraphed (glowing cracks / growing shadow)
##   before the bug appears, so fast scaling stays fair.
## - Rebuilds a uniform grid every physics frame for swarm separation and for
##   hit queries (bullets, blades, explosions, beams, lasers).
## WHAT to spawn and WHEN is decided by the HiveDirector and the Mission.

@export var swarmer_scene: PackedScene = preload("res://scenes/enemies/swarmer.tscn")
@export var swarmer_pool := 200
@export var burster_scene: PackedScene = preload("res://scenes/enemies/burster.tscn")
@export var burster_pool := 30
@export var shield_scene: PackedScene = preload("res://scenes/enemies/shield_bug.tscn")
@export var shield_pool := 14
@export var turret_scene: PackedScene = preload("res://scenes/enemies/sentry_turret.tscn")
@export var max_alive := 170

@export_group("Telegraphs")
@export var burrow_warning := 0.9
@export var drop_warning := 0.75

@export_group("Swarm behaviour")
@export var separation_radius := 0.95
@export var separation_strength := 7.0
@export var grid_cell_size := 1.0
## Upper bound on neighbours each bug inspects per update (keeps dense blobs cheap).
@export var max_separation_neighbors := 14

var active: Array[Enemy] = []
var rescued := 0  ## Debug counter: strays put back on the deck.

var _pools := {}  # type_id -> Array[Enemy] (free list)
var _pending: Array[Dictionary] = []
var _grid := {}
var _rescue_t := 0.0
var _sep_parity := 0


func _ready() -> void:
	Game.spawner = self
	_make_pool(&"swarmer", swarmer_scene, swarmer_pool)
	_make_pool(&"burster", burster_scene, burster_pool)
	_make_pool(&"shield", shield_scene, shield_pool)


func _make_pool(type: StringName, scene: PackedScene, count: int) -> void:
	var free: Array[Enemy] = []
	for i in count:
		var e: Enemy = scene.instantiate()
		e.spawner = self
		add_child(e)
		e.deactivate()
		free.append(e)
	_pools[type] = free


# ==========================================================================
# Spawning
# ==========================================================================

## Spawn with the entrance appropriate to `mode` (see Enemy.spawn_at).
## Burrow/drop spawns show a telegraph first and appear after a short delay.
func spawn(type: StringName, mode: StringName, pos: Vector3, opts := {}) -> void:
	if mode == &"burrow" or mode == &"drop":
		var warn := burrow_warning if mode == &"burrow" else drop_warning
		if Game.fx:
			Game.fx.telegraph(mode, pos, warn, opts.get("tier", 0))
		_pending.append({"t": warn, "type": type, "mode": mode, "pos": pos, "opts": opts})
	else:
		spawn_now(type, mode, pos, opts)


func spawn_now(type: StringName, mode: StringName, pos: Vector3, opts := {}) -> Enemy:
	var placed := mode == &"dormant" or mode == &"patrol"
	if not placed and active.size() >= max_alive and opts.get("tier", 0) < Enemy.Tier.PURPLE:
		return null
	var free: Array = _pools.get(type, [])
	if free.is_empty():
		return null
	var e: Enemy = free.pop_back()
	active.append(e)
	e.spawn_at(pos, mode, opts)
	return e


## Non-pooled, hand-placed enemies (turrets).
func spawn_static(scene: PackedScene, pos: Vector3, yaw: float, mode := &"dormant", opts := {}) -> Enemy:
	var e: Enemy = scene.instantiate()
	e.spawner = self
	add_child(e)
	active.append(e)
	var o := opts.duplicate()
	o["yaw"] = yaw
	e.spawn_at(pos, mode, o)
	return e


func release(e: Enemy) -> void:
	var idx := active.find(e)
	if idx >= 0:
		active[idx] = active[active.size() - 1]
		active.pop_back()
	e.deactivate()
	if e.pooled and _pools.has(e.type_id):
		_pools[e.type_id].append(e)


func alive_count() -> int:
	return active.size() + _pending.size()


func _physics_process(delta: float) -> void:
	_tick_pending(delta)
	_rebuild_grid()
	_apply_separation()
	_rescue_t -= delta
	if _rescue_t <= 0.0:
		_rescue_t = 0.5
		_rescue_strays()


func _tick_pending(delta: float) -> void:
	if _pending.is_empty():
		return
	var due: Array[Dictionary] = []
	for p in _pending:
		p.t -= delta
		if p.t <= 0.0:
			due.append(p)
	for p in due:
		_pending.erase(p)
		spawn_now(p.type, p.mode, p.pos, p.opts)


## Safety net: a hunting bug that somehow ended up off the deck is put back on it.
func _rescue_strays() -> void:
	if Game.level == null:
		return
	for e in active:
		if e.state == Enemy.State.CHASE and not Game.level.is_walkable(e.global_position):
			e.global_position = Game.level.clamp_to_walkable(e.global_position)
			rescued += 1


# ==========================================================================
# Spatial grid
# ==========================================================================

func _cell(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / grid_cell_size), floori(p.z / grid_cell_size))


func _rebuild_grid() -> void:
	_grid.clear()
	for e in active:
		var c := _cell(e.global_position)
		var bucket = _grid.get(c)
		if bucket == null:
			_grid[c] = [e]
		else:
			bucket.append(e)


func _apply_separation() -> void:
	# Cost control for big swarms: cells match the separation radius, each bug
	# looks at a capped number of neighbours, and only half the swarm updates
	# per physics step (the other half keeps last step's push).
	_sep_parity = 1 - _sep_parity
	var r2 := separation_radius * separation_radius
	for i in range(_sep_parity, active.size(), 2):
		var e := active[i]
		if e.state != Enemy.State.CHASE:
			continue
		var p := e.global_position
		var c := _cell(p)
		var push := Vector3.ZERO
		var checked := 0
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var bucket = _grid.get(Vector2i(c.x + dx, c.y + dz))
				if bucket == null:
					continue
				for o in bucket:
					if o == e:
						continue
					checked += 1
					var d: Vector3 = p - o.global_position
					d.y = 0.0
					var l2 := d.length_squared()
					if l2 < r2 and l2 > 0.0001:
						var l := sqrt(l2)
						push += d / l * (1.0 - l / separation_radius)
					if checked >= max_separation_neighbors:
						break
				if checked >= max_separation_neighbors:
					break
			if checked >= max_separation_neighbors:
				break
		e.set_separation(push * separation_strength)


func _segment_cells(a: Vector3, b: Vector3, margin: float) -> Array[Vector2i]:
	var c0 := _cell(Vector3(minf(a.x, b.x) - margin, 0, minf(a.z, b.z) - margin))
	var c1 := _cell(Vector3(maxf(a.x, b.x) + margin, 0, maxf(a.z, b.z) + margin))
	return [c0, c1]


## Closest enemy whose circle (in XZ) intersects segment a->b, or null.
func find_enemy_on_segment(a: Vector3, b: Vector3, extra_radius: float) -> Enemy:
	var hits := _segment_hits(a, b, extra_radius)
	var best: Enemy = null
	var best_t := INF
	for h in hits:
		if h[1] < best_t:
			best_t = h[1]
			best = h[0]
	return best


## Every enemy the segment passes through (beams, lasers, door crush).
func enemies_on_segment(a: Vector3, b: Vector3, extra_radius: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for h in _segment_hits(a, b, extra_radius):
		out.append(h[0])
	return out


func _segment_hits(a: Vector3, b: Vector3, extra_radius: float) -> Array:
	var cells := _segment_cells(a, b, 1.8)
	var seg := Vector2(b.x - a.x, b.z - a.z)
	var seg_len2 := maxf(seg.length_squared(), 0.000001)
	var out: Array = []
	for cx in range(cells[0].x, cells[1].x + 1):
		for cz in range(cells[0].y, cells[1].y + 1):
			var bucket = _grid.get(Vector2i(cx, cz))
			if bucket == null:
				continue
			for e: Enemy in bucket:
				if not e.is_active():
					continue
				var ep := Vector2(e.global_position.x - a.x, e.global_position.z - a.z)
				var t := clampf(ep.dot(seg) / seg_len2, 0.0, 1.0)
				var rr := e.get_hit_radius() + extra_radius
				if (ep - seg * t).length_squared() <= rr * rr:
					out.append([e, t])
	return out


func enemies_in_radius(center: Vector3, r: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	var c0 := _cell(center - Vector3(r + 1.2, 0, r + 1.2))
	var c1 := _cell(center + Vector3(r + 1.2, 0, r + 1.2))
	for cx in range(c0.x, c1.x + 1):
		for cz in range(c0.y, c1.y + 1):
			var bucket = _grid.get(Vector2i(cx, cz))
			if bucket == null:
				continue
			for e: Enemy in bucket:
				var d := Vector2(e.global_position.x - center.x, e.global_position.z - center.z)
				if e.is_active() and d.length() <= r + e.get_hit_radius():
					out.append(e)
	return out
