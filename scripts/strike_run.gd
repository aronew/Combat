class_name StrikeRun
extends Node
## Runs a strike operation's fights (the layout comes from ComplexGen.generate with strike on).
## Walk into an arena and energy gates seal its doorways; clear the fight and the gates drop,
## loot spills out and the path goes on. Quiet rooms between arenas keep their sleeping bugs,
## so you can open each stretch on your own terms. Encounter kinds:
##   purge  three waves, each harder, leaping up from the void, burrowing, dropping in
##   nests  hive nests keep spawning bugs until you destroy them, then the stragglers
##   final  a wave, then a purple elite with escorts, reinforced while it lives
## Mission owns this node and listens to `cleared` and `finished`.

signal started(index: int)
signal cleared(index: int)
signal finished

## How far inside an arena (from every doorway) you have to be before it seals behind you.
@export var trigger_depth := 3.5
## The next wave comes when this many of the last are left, or after wave_max_time.
@export var next_wave_when_left := 3
@export var wave_max_time := 13.0
## A wave's bugs arrive spread over this long rather than all at once.
@export var wave_spread := 1.6
@export var nest_spawn_interval := 2.2
@export var nest_cap := 14
@export var elite_reinforce_interval := 7.5
@export var elite_reinforce_cap := 10
## Safety valve: if the last few bugs of a fight don't show up for this long, the fight ends.
@export var straggler_timeout := 25.0

var encounters: Array[Dictionary] = []
## Index of the fight in progress, or -1.
var current := -1
var done := false

var _level: Level
var _gates: Array[EnergyGate] = []
var _waves: Array = []
var _wave_i := 0
var _wave_t := 0.0
var _queue: Array = []  # [delay, unit]
var _tag := &""
var _regions: Array[int] = []
var _nests: Array[HiveNest] = []
var _nest_t := 0.0
var _elite: Enemy
var _elite_due := false
var _reinforce_t := 0.0
var _quiet_t := 0.0


func setup(level: Level) -> void:
	_level = level
	for e in level.layout.get("encounters", []):
		var enc: Dictionary = e.duplicate()
		enc.state = &"idle"
		enc.doors = _doorways(enc.room)
		encounters.append(enc)
	_update_objective()


func fights_total() -> int:
	return encounters.size()


func fights_cleared() -> int:
	var n := 0
	for e in encounters:
		if e.state == &"cleared":
			n += 1
	return n


## Where to head next: the next arena, or the nearest nest during a nest fight (nothing
## otherwise while a fight is on).
func objective_position() -> Vector3:
	if current >= 0:
		return nest_target(Game.player.global_position if Game.player else Vector3.ZERO)
	for e in encounters:
		if e.state == &"idle":
			return _level.clamp_to_walkable(e.center)
	return Vector3.INF


func is_fighting() -> bool:
	return current >= 0


## The nearest live nest of the fight in progress, or Vector3.INF.
func nest_target(from: Vector3) -> Vector3:
	var best := Vector3.INF
	for n in _nests:
		if is_instance_valid(n) and n.is_alive() and (best == Vector3.INF or from.distance_to(n.global_position) < from.distance_to(best)):
			best = n.global_position
	return best


# --------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if done or _level == null or Game.is_game_over or Game.player == null or not Game.player.alive:
		return
	if current < 0:
		_check_trigger()
	else:
		_tick_fight(delta)


## Portals from this room's walkways to anything else (catwalks, corridors, other rooms).
func _doorways(room: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in _level.portals:
		var ra: StringName = _level.regions[p.a].room
		var rb: StringName = _level.regions[p.b].room
		if (ra == room) != (rb == room):
			out.append(p)
	return out


func _check_trigger() -> void:
	var p := Game.player.global_position
	var room := _level.room_of(p)
	for i in encounters.size():
		var e := encounters[i]
		if e.state != &"idle" or e.room != room:
			continue
		for d in e.doors:
			if _dist_to_portal(p, d) < trigger_depth:
				return
		_start(i)
		return


func _dist_to_portal(p: Vector3, d: Dictionary) -> float:
	var c: Vector3 = d.center
	if d.axis == &"x":
		return Vector2(p.x - c.x, clampf(p.z, d.lo, d.hi) - p.z).length()
	return Vector2(clampf(p.x, d.lo, d.hi) - p.x, p.z - c.z).length()


func _start(i: int) -> void:
	current = i
	var e := encounters[i]
	e.state = &"active"
	_tag = StringName("enc%d" % i)
	_regions.clear()
	for r in _level.regions.size():
		if _level.regions[r].room == e.room:
			_regions.append(r)
	# Seal the doorways.
	for d in e.doors:
		var g := EnergyGate.new()
		g.width = d.half * 2.0 + 0.6
		g.position = d.center
		g.rotation.y = PI * 0.5 if d.axis == &"x" else 0.0
		_level.add_child(g)
		g.raise()
		_gates.append(g)
	Audio.play(&"blast_door_close")
	_nests.clear()
	for n in _level.nests:
		if n.is_alive() and _level.room_of(n.global_position) == e.room:
			_nests.append(n)
	_waves = _plan(e)
	_wave_i = 0
	_queue.clear()
	_elite = null
	_elite_due = false
	_quiet_t = 0.0
	_spawn_next_wave()
	var title: String = {"purge": "AMBUSH", "nests": "INFESTATION", "final": "FINAL STAND"}.get(e.kind, "CONTACT")
	var sub: String = {"purge": "SURVIVE THE WAVES", "nests": "DESTROY THE NESTS", "final": "KILL THE ELITE"}.get(e.kind, "")
	Game.banner.emit(title, "%s  ·  %s" % [String(e.name).to_upper(), sub])
	Game.shake(0.35)
	if Game.director:
		Game.director.add_alert(30.0)
	started.emit(i)
	_update_objective()


## The waves of one fight: arrays of {type, tier}, or {"elite": true, ...}.
func _plan(e: Dictionary) -> Array:
	var b: int = e.beat
	var scale := (1.0 + 0.15 * (Profile.dive_depth - 1)) * (1.0 + 0.12 * b)
	match e.kind:
		"purge":
			return [_wave(6, scale, b, 0, false), _wave(8, scale, b, 1, false), _wave(10, scale, b, 2, true)]
		"nests":
			return [_wave(5, scale, b, 0, false)]
		"final":
			return [_wave(8, scale, b, 1, false), [{"elite": true}], _wave(6, scale, b, 2, true)]
	return [_wave(8, scale, b, 1, false)]


func _wave(n: int, scale: float, beat: int, step: int, champion: bool) -> Array:
	var out: Array = []
	for k in roundi(n * scale):
		var r := randf()
		var type := &"swarmer"
		if r < 0.13 + 0.02 * step:
			type = &"burster"
		elif r < 0.2 + 0.03 * beat + 0.03 * step and beat + step >= 1:
			type = &"shield"
		var tier := Enemy.Tier.BLUE if randf() < 0.05 + 0.04 * beat + 0.03 * step else Enemy.Tier.NORMAL
		out.append({"type": type, "tier": tier})
	if champion and beat >= 1:
		out.append({"type": &"shield" if randf() < 0.5 else &"swarmer", "tier": Enemy.Tier.GOLD})
	return out


func _spawn_next_wave() -> void:
	if _wave_i >= _waves.size():
		return
	var wave: Array = _waves[_wave_i]
	_wave_i += 1
	_wave_t = 0.0
	for k in wave.size():
		var u: Dictionary = wave[k]
		if u.get("elite", false):
			_elite_due = true
			continue
		_queue.append([wave_spread * k / maxf(wave.size(), 1.0) + randf_range(0.0, 0.25), u])
	_queue.sort_custom(func(a, b): return a[0] < b[0])
	_update_objective()


func _tick_fight(delta: float) -> void:
	var e := encounters[current]
	_wave_t += delta
	for q in _queue:
		q[0] -= delta
	while not _queue.is_empty() and _queue[0][0] <= 0.0:
		_spawn_unit(_queue.pop_front()[1])
	if _elite_due:
		_elite_due = false
		_spawn_elite()
	var alive := Game.spawner.count_tagged(_tag) + _queue.size()

	if e.kind == "nests":
		_nests = _nests.filter(func(n: HiveNest) -> bool: return is_instance_valid(n) and n.is_alive())
		if not _nests.is_empty():
			_nest_t -= delta
			if _nest_t <= 0.0 and alive < nest_cap:
				_nest_t = nest_spawn_interval / sqrt(float(_nests.size()))
				var n: HiveNest = _nests.pick_random()
				var t := &"burster" if randf() < 0.15 else &"swarmer"
				Game.spawner.spawn(t, &"burrow", n.get_spawn_point(), {"tier": Enemy.Tier.NORMAL, "alerted": true, "tag": _tag})
			_update_objective()
			return

	if _wave_i < _waves.size():
		if alive <= next_wave_when_left or _wave_t >= wave_max_time:
			_spawn_next_wave()
		return

	if is_instance_valid(_elite) and _elite.is_active():
		_reinforce_t -= delta
		if _reinforce_t <= 0.0 and alive < elite_reinforce_cap:
			_reinforce_t = elite_reinforce_interval
			for k in randi_range(3, 5):
				_queue.append([randf_range(0.0, 1.2), {"type": &"burster" if randf() < 0.25 else &"swarmer", "tier": Enemy.Tier.NORMAL}])
			_queue.sort_custom(func(a, b): return a[0] < b[0])
		return

	if alive == 0:
		_clear()
	elif alive <= 2:
		_quiet_t += delta
		if _quiet_t > straggler_timeout:
			for en in Game.spawner.tagged(_tag):
				Game.spawner.release(en)
			_clear()
	else:
		_quiet_t = 0.0


func _spawn_unit(u: Dictionary) -> void:
	var p := Game.player.global_position
	var opts := {"tier": u.tier, "alerted": true, "tag": _tag}
	var roll := randf()
	if roll < 0.45:
		var edge := _level.get_leap_spawn(_regions, p, 4.0, 18.0)
		if not edge.is_empty():
			opts["from"] = edge[0]
			Game.spawner.spawn(u.type, &"leap", edge[1], opts)
			return
	var pos := _level.random_point(_regions, p, 4.0, 16.0)
	if pos == Vector3.INF:
		pos = _level.random_point(_regions, p, 2.5, 60.0)
	if pos == Vector3.INF:
		return
	Game.spawner.spawn(u.type, &"burrow" if roll < 0.8 else &"drop", pos, opts)


func _spawn_elite() -> void:
	var p := Game.player.global_position
	var pos := _level.random_point(_regions, p, 6.0, 12.0)
	if pos == Vector3.INF:
		pos = _level.random_point(_regions, p, 3.0, 60.0)
	if pos == Vector3.INF:
		return
	_elite = Game.spawner.spawn_now(&"shield", &"drop", pos, {"tier": Enemy.Tier.PURPLE, "alerted": true, "tag": _tag})
	_reinforce_t = elite_reinforce_interval
	Audio.play(&"elite_arrival")
	Game.shake(0.5)


func _clear() -> void:
	var e := encounters[current]
	e.state = &"cleared"
	current = -1
	for g in _gates:
		g.drop()
		get_tree().create_timer(1.5).timeout.connect(g.queue_free)
	_gates.clear()
	Audio.play(&"blast_door_open")
	Audio.play(&"uplink_complete")
	# The spoils: a guaranteed item (better the deeper into the operation), health, salvage.
	var b: int = e.beat
	var d := Profile.dive_depth
	var p := Game.player.global_position
	var weights := [0.0, 0.0, 65.0, 35.0] if e.kind == "final" else [maxf(40.0 - 12.0 * b, 0.0), 42.0, 14.0 + 6.0 * b, 4.0 + 3.0 * b]
	var drop_at := _level.clamp_to_walkable(p + Game.player.aim_dir * 2.0)
	Game.pickups.drop_item(drop_at, Loot.roll_item(Profile.item_level_for_depth(d), Loot.roll_rarity(weights)))
	Game.pickups.drop_health(p, 2, 14)
	if Game.mission:
		Game.mission.add_haul(25 + 15 * b)
		Game.mission._give_xp(60 + 30 * b)
	if e.kind != "final":
		Game.banner.emit("AREA CLEARED", "%d OF %d  ·  THE WAY IS OPEN" % [fights_cleared(), fights_total()])
	if e.kind == "final":
		done = true
	cleared.emit(encounters.find(e))
	if done:
		finished.emit()
	else:
		_update_objective()


func _update_objective() -> void:
	var text := ""
	if current >= 0:
		var e := encounters[current]
		match e.kind:
			"nests":
				text = "Destroy the nests (%d left)" % _nests.size() if not _nests.is_empty() else "Clear out the stragglers"
			"final":
				text = "Kill the elite" if is_instance_valid(_elite) and _elite.is_active() else "Hold out: wave %d / %d" % [_wave_i, _waves.size()]
			_:
				text = "Survive: wave %d / %d" % [_wave_i, _waves.size()]
	else:
		var next := -1
		for i in encounters.size():
			if encounters[i].state == &"idle":
				next = i
				break
		if next < 0:
			return
		var e := encounters[next]
		text = ("Push on to the %s (fight %d / %d)" % [e.name, fights_cleared() + 1, fights_total()]) if e.kind != "final" else "Push on to the %s: the final fight" % e.name
	Game.objective_changed.emit(text)
