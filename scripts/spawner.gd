class_name Spawner
extends Node3D
## Wave director + enemy pool + spatial hash.
## - Pre-instantiates `pool_size` swarmers and recycles them.
## - Each wave spawns more (and faster, tougher) bugs from the hive and the edges.
## - Rebuilds a uniform grid every physics frame; used for swarm separation and
##   for projectile hit tests, so 100+ bugs stay cheap.

enum Phase { INTERMISSION, SPAWNING, CLEARING }

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var pool_size := 240

@export_group("Waves")
@export var first_wave_delay := 1.2
@export var wave_pause := 2.5
@export var wave_banner_lead := 1.3  ## Seconds between "WAVE X" banner and first spawn.
@export var base_enemy_count := 24
@export var enemy_count_growth := 1.32  ## Multiplier per wave.
@export var max_enemy_count := 400
@export var max_alive := 220

@export_group("Enemy scaling")
@export var base_enemy_speed := 5.2
@export var speed_growth_per_wave := 0.08  ## +8% per wave.
@export var max_enemy_speed := 11.5
@export var base_enemy_health := 30.0
@export var health_growth_per_wave := 0.06

@export_group("Spawn pacing")
@export var spawn_interval := 0.45
@export var spawn_interval_decay := 0.88  ## Interval multiplier per wave.
@export var min_spawn_interval := 0.1
@export var batch_size := 3
@export var batch_growth_per_wave := 1
@export_range(0.0, 1.0) var hive_spawn_ratio := 0.45
@export var min_spawn_distance_to_player := 6.0

@export_group("Swarm behaviour")
@export var separation_radius := 0.95
@export var separation_strength := 7.0
@export var grid_cell_size := 2.0

var wave := 0
var wave_total := 0
var wave_killed := 0
var active: Array[Enemy] = []

var _free: Array[Enemy] = []
var _phase := Phase.INTERMISSION
var _timer := 0.0
var _to_spawn := 0
var _grid := {}
var _rescue_t := 0.0
var rescued := 0  ## Debug counter: strays put back on the deck.


func _ready() -> void:
	Game.spawner = self
	for i in pool_size:
		var e: Enemy = enemy_scene.instantiate()
		e.spawner = self
		add_child(e)
		e.deactivate()
		_free.append(e)
	_phase = Phase.INTERMISSION
	_timer = first_wave_delay


func _physics_process(delta: float) -> void:
	_rebuild_grid()
	_apply_separation()
	_rescue_t -= delta
	if _rescue_t <= 0.0:
		_rescue_t = 0.5
		_rescue_strays()
	if Game.is_game_over:
		return
	match _phase:
		Phase.INTERMISSION:
			_timer -= delta
			if _timer <= 0.0:
				_start_wave()
		Phase.SPAWNING:
			_timer -= delta
			if _timer <= 0.0:
				_spawn_batch()
				_timer = _current_interval()
			if _to_spawn <= 0:
				_phase = Phase.CLEARING
		Phase.CLEARING:
			if active.is_empty():
				Game.wave_cleared.emit(wave)
				_phase = Phase.INTERMISSION
				_timer = wave_pause


# --------------------------------------------------------------------------
# Waves
# --------------------------------------------------------------------------

func _start_wave() -> void:
	wave += 1
	wave_total = mini(roundi(base_enemy_count * pow(enemy_count_growth, wave - 1)), max_enemy_count)
	wave_killed = 0
	_to_spawn = wave_total
	_phase = Phase.SPAWNING
	_timer = wave_banner_lead
	Game.announce_wave(wave, wave_total)
	Game.wave_progress.emit(wave_total, wave_total)


func _current_interval() -> float:
	return maxf(spawn_interval * pow(spawn_interval_decay, wave - 1), min_spawn_interval)


func current_speed() -> float:
	return minf(base_enemy_speed * (1.0 + speed_growth_per_wave * (wave - 1)), max_enemy_speed)


func current_health() -> float:
	return base_enemy_health * (1.0 + health_growth_per_wave * (wave - 1))


func _spawn_batch() -> void:
	var room := max_alive - active.size()
	var n := mini(mini(batch_size + batch_growth_per_wave * (wave - 1), _to_spawn), room)
	if n <= 0:
		return
	var player_pos := Game.player.global_position if Game.player else Vector3.ZERO
	# Decide per batch so bugs arrive in readable clumps.
	var from_hive := randf() < hive_spawn_ratio
	var edge: Array[Vector3] = []
	if not from_hive and Game.arena:
		edge = Game.arena.get_edge_spawn(player_pos, min_spawn_distance_to_player)
	for i in n:
		if _free.is_empty():
			return
		var e: Enemy = _free.pop_back()
		active.append(e)
		_to_spawn -= 1
		if from_hive or edge.is_empty():
			var p := Game.arena.get_hive_spawn() if Game.arena else Vector3.ZERO
			e.activate_emerge(p, current_health(), current_speed())
		else:
			var jitter := Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(-1.2, 1.2))
			var land := Game.arena.clamp_to_walkable(edge[1] + jitter * 0.6)
			var start := edge[0] + jitter
			e.activate_leap(start, land, current_health(), current_speed())
			e._state_t = -i * 0.06  # stagger the leaps a little


## Safety net: a chasing bug that somehow ended up off the deck is put back on it,
## so a wave can never soft-lock on an unreachable straggler.
func _rescue_strays() -> void:
	if Game.arena == null:
		return
	for e in active:
		if e.state == Enemy.State.CHASE and not Game.arena.is_walkable(e.global_position):
			e.global_position = Game.arena.clamp_to_walkable(e.global_position)
			rescued += 1


func release(e: Enemy) -> void:
	var idx := active.find(e)
	if idx >= 0:
		active[idx] = active[active.size() - 1]
		active.pop_back()
	e.deactivate()
	_free.append(e)
	wave_killed += 1
	Game.wave_progress.emit(maxi(wave_total - wave_killed, 0), wave_total)


func remaining() -> int:
	return maxi(wave_total - wave_killed, 0)


# --------------------------------------------------------------------------
# Spatial grid
# --------------------------------------------------------------------------

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
	var r2 := separation_radius * separation_radius
	for e in active:
		if e.state != Enemy.State.CHASE:
			continue
		var p := e.global_position
		var c := _cell(p)
		var push := Vector3.ZERO
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var bucket = _grid.get(Vector2i(c.x + dx, c.y + dz))
				if bucket == null:
					continue
				for o in bucket:
					if o == e:
						continue
					var d: Vector3 = p - o.global_position
					d.y = 0.0
					var l2 := d.length_squared()
					if l2 < r2 and l2 > 0.0001:
						var l := sqrt(l2)
						push += d / l * (1.0 - l / separation_radius)
		e.set_separation(push * separation_strength)


## Closest enemy whose circle (in XZ) intersects segment a->b, or null.
func find_enemy_on_segment(a: Vector3, b: Vector3, extra_radius: float) -> Enemy:
	var min_x := minf(a.x, b.x) - 1.0
	var max_x := maxf(a.x, b.x) + 1.0
	var min_z := minf(a.z, b.z) - 1.0
	var max_z := maxf(a.z, b.z) + 1.0
	var c0 := _cell(Vector3(min_x, 0, min_z))
	var c1 := _cell(Vector3(max_x, 0, max_z))
	var seg := Vector2(b.x - a.x, b.z - a.z)
	var seg_len2 := maxf(seg.length_squared(), 0.000001)
	var best: Enemy = null
	var best_t := INF
	for cx in range(c0.x, c1.x + 1):
		for cz in range(c0.y, c1.y + 1):
			var bucket = _grid.get(Vector2i(cx, cz))
			if bucket == null:
				continue
			for e: Enemy in bucket:
				if not e.is_active():
					continue
				var ep := Vector2(e.global_position.x - a.x, e.global_position.z - a.z)
				var t := clampf(ep.dot(seg) / seg_len2, 0.0, 1.0)
				var closest := seg * t
				var rr := e.radius + extra_radius
				if (ep - closest).length_squared() <= rr * rr and t < best_t:
					best_t = t
					best = e
	return best


func enemies_in_radius(center: Vector3, r: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	var c0 := _cell(center - Vector3(r, 0, r))
	var c1 := _cell(center + Vector3(r, 0, r))
	for cx in range(c0.x, c1.x + 1):
		for cz in range(c0.y, c1.y + 1):
			var bucket = _grid.get(Vector2i(cx, cz))
			if bucket == null:
				continue
			for e: Enemy in bucket:
				var d := Vector2(e.global_position.x - center.x, e.global_position.z - center.z)
				if e.is_active() and d.length() <= r + e.radius:
					out.append(e)
	return out
