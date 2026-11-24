extends Node
## Autoload "Game": shared references, run state, and global combat helpers
## (teams, explosions, hitstop, shake). Tuning lives on the scene nodes.

## Damage teams. Neutral damage (explosions, lasers, crushing doors) hurts everyone.
const TEAM_PLAYER := 0
const TEAM_HIVE := 1
const TEAM_NEUTRAL := 2

signal player_health_changed(current: float, maximum: float)
signal player_damaged(amount: float)
signal weapon_changed(weapon: int)
signal kills_changed(kills: int, combo: int)
signal alert_changed(level: int, value: float)
signal mission_phase_changed(phase: int)
signal objective_changed(text: String)
signal upload_changed(ratio: float, in_zone: bool)
signal haul_changed(amount: int)
signal radio(speaker: String, text: String)
signal banner(title: String, subtitle: String)
signal elite_changed(enemy: Node)
signal mission_ended(success: bool, summary: Dictionary)

# Scene references (each node registers itself in _ready).
var player: Player
var camera_rig: CameraRig
var level: Level
var spawner: Spawner
var projectiles: ProjectilePool
var fx: FX
var pickups: Pickups
var director: HiveDirector
var mission: Mission
var hud: Node
var interactables: Array = []  ## Interactable nodes in the level.
var damageables: Array = []  ## Barrels, nests: anything with take_hit() that isn't an Enemy.

# Run state
var kills := 0
var combo := 0
var best_combo := 0
var is_game_over := false
var combo_window := 1.6

var _combo_timer := 0.0
var _hitstop_end_usec := 0
var _base_time_scale := 1.0
var _delayed: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Called by Main when a run starts (also after a restart reloads the scene).
func reset_run() -> void:
	player = null
	camera_rig = null
	level = null
	spawner = null
	projectiles = null
	fx = null
	pickups = null
	director = null
	mission = null
	hud = null
	interactables.clear()
	damageables.clear()
	_delayed.clear()
	kills = 0
	combo = 0
	best_combo = 0
	is_game_over = false
	_combo_timer = 0.0
	_hitstop_end_usec = 0
	_base_time_scale = 1.0
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	# Hitstop runs on real time so it ends even while Engine.time_scale is ~0.
	if _hitstop_end_usec > 0 and Time.get_ticks_usec() >= _hitstop_end_usec:
		_hitstop_end_usec = 0
		Engine.time_scale = _base_time_scale
	if combo > 0 and not is_game_over:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			combo = 0
			kills_changed.emit(kills, combo)
	_tick_delayed(delta)


# --------------------------------------------------------------------------
# Feel
# --------------------------------------------------------------------------

## Freeze-frame: drop time scale to `scale` for `duration` real seconds.
func hitstop(duration: float, scale: float = 0.03) -> void:
	if duration <= 0.0:
		return
	var end := Time.get_ticks_usec() + int(duration * 1_000_000.0)
	_hitstop_end_usec = maxi(_hitstop_end_usec, end)
	Engine.time_scale = minf(scale, _base_time_scale)


func shake(trauma: float) -> void:
	if camera_rig:
		camera_rig.add_trauma(trauma)


func register_kill() -> void:
	kills += 1
	combo += 1
	best_combo = maxi(best_combo, combo)
	_combo_timer = combo_window
	kills_changed.emit(kills, combo)


# --------------------------------------------------------------------------
# Combat helpers
# --------------------------------------------------------------------------

## Area damage that hurts bugs, the player, barrels and nests alike, and makes noise.
func explode(pos: Vector3, radius: float, enemy_damage: float, player_damage: float, knockback: float,
		source: Object = null, fx_size := 2.0) -> void:
	if fx:
		fx.explosion(pos, fx_size)
	if spawner:
		for e in spawner.enemies_in_radius(pos, radius):
			if e == source or not e.is_active():
				continue
			var d := e.global_position - pos
			d.y = 0.0
			var fall := 1.0 - clampf(d.length() / radius, 0.0, 1.0) * 0.5
			var dir := d.normalized() if d.length() > 0.01 else Vector3.FORWARD
			e.take_hit(enemy_damage * fall, dir, knockback * fall, TEAM_NEUTRAL, &"explosion")
	if player and player.alive:
		var dp := player.global_position - pos
		dp.y = 0.0
		if dp.length() < radius * 0.85:
			player.take_damage(player_damage * (1.0 - dp.length() / radius * 0.5), pos)
	for d in damageables.duplicate():
		if d == source or not is_instance_valid(d) or not d.is_alive():
			continue
		var dd: Vector3 = d.global_position - pos
		dd.y = 0.0
		if dd.length() < radius + d.hit_radius:
			d.take_hit(enemy_damage, dd.normalized(), 0.0, TEAM_NEUTRAL, &"explosion")
	if director:
		director.make_noise(pos, director.explosion_noise_radius, director.explosion_noise_alert)
	shake(0.45)
	hitstop(0.05)


## Explosion after a short fuse, so chain reactions ripple outward instead of recursing.
func delayed_explode(delay: float, pos: Vector3, radius: float, enemy_damage: float, player_damage: float,
		knockback: float, source: Object = null, fx_size := 2.0) -> void:
	_delayed.append({"t": delay, "args": [pos, radius, enemy_damage, player_damage, knockback, source, fx_size]})


func _tick_delayed(delta: float) -> void:
	if _delayed.is_empty():
		return
	var due: Array[Dictionary] = []
	for d in _delayed:
		d.t -= delta
		if d.t <= 0.0:
			due.append(d)
	for d in due:
		_delayed.erase(d)
		var a: Array = d.args
		explode(a[0], a[1], a[2], a[3], a[4], a[5] if is_instance_valid(a[5]) else null, a[6])


# --------------------------------------------------------------------------
# Run flow
# --------------------------------------------------------------------------

func on_player_died() -> void:
	if mission:
		mission.fail()
	else:
		end_run(false)


func end_run(success: bool) -> void:
	if is_game_over:
		return
	is_game_over = true
	if not success:
		_base_time_scale = 0.35  # dramatic slow-mo under the results screen
		Engine.time_scale = _base_time_scale


func restart() -> void:
	_hitstop_end_usec = 0
	_base_time_scale = 1.0
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
