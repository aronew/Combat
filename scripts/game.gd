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
signal loot_picked(item: Dictionary)
signal level_up(level: int)
signal blade_chain_changed(count: int)
signal energy_changed(current: float, maximum: float)

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
var _hitstop_scale := 0.03
var _slowmo_end_usec := 0
var _slowmo_scale := 1.0
var _base_time_scale := 1.0
var _delayed: Array[Dictionary] = []
## True while fading between scenes (floor changes).
var transitioning := false
var _fade_layer: CanvasLayer
var _fade: ColorRect
var _fade_title: Label


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
	_slowmo_end_usec = 0
	_base_time_scale = 1.0
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	# Hitstop and slow-mo run on real time so they end even while Engine.time_scale is ~0.
	if _hitstop_end_usec > 0 or _slowmo_end_usec > 0:
		var now := Time.get_ticks_usec()
		if _hitstop_end_usec > 0 and now >= _hitstop_end_usec:
			_hitstop_end_usec = 0
		if _slowmo_end_usec > 0 and now >= _slowmo_end_usec:
			_slowmo_end_usec = 0
		Engine.time_scale = _current_time_scale()
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
	_hitstop_scale = scale
	Engine.time_scale = _current_time_scale()


## Slow-motion: time runs at `scale` for `duration` real seconds (hitstop still wins).
func slowmo(duration: float, scale: float = 0.3) -> void:
	if duration <= 0.0 or is_game_over:
		return
	var end := Time.get_ticks_usec() + int(duration * 1_000_000.0)
	_slowmo_end_usec = maxi(_slowmo_end_usec, end)
	_slowmo_scale = scale
	Engine.time_scale = _current_time_scale()


func _current_time_scale() -> float:
	var s := _base_time_scale
	if _slowmo_end_usec > 0:
		s = minf(s, _slowmo_scale)
	if _hitstop_end_usec > 0:
		s = minf(s, _hitstop_scale)
	return s


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
	if player and player.alive and player_damage > 0.0:
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
	if fx == null:
		shake(0.45)
		hitstop(0.05)
	# (With FX, the explosion effect's CameraFeedback profile shakes and stops time,
	# attenuated by distance from the player.)


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


## Every enemy death passes through here: XP and loot (Mission), legendary
## procs (Player). `kind` is what killed it (bullet, slash, explosion...).
func on_enemy_killed(e: Enemy, pos: Vector3, kind: StringName) -> void:
	if mission:
		mission.on_enemy_killed(e, pos, kind)
	if player and player.alive:
		player.on_kill(e, pos, kind)


## Shock element: arcs from `source` to up to `count` nearby bugs.
func shock_chain(source: Enemy, damage: float, count: int) -> void:
	if spawner == null or not is_instance_valid(source):
		return
	var from := source.global_position
	var others: Array = []
	for e in spawner.enemies_in_radius(from, 4.5):
		if e != source and e.is_active():
			others.append(e)
	others.sort_custom(func(a, b): return a.global_position.distance_squared_to(from) < b.global_position.distance_squared_to(from))
	for i in mini(count, others.size()):
		var t: Enemy = others[i]
		if fx:
			fx.lightning(from + Vector3.UP * 0.6, t.global_position + Vector3.UP * 0.6)
		t.take_hit(damage, (t.global_position - from).normalized(), 2.0, TEAM_PLAYER, &"shock")


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
	_slowmo_end_usec = 0
	if not success:
		_base_time_scale = 0.35  # dramatic slow-mo under the results screen
	Engine.time_scale = _current_time_scale()


func restart() -> void:
	_hitstop_end_usec = 0
	_slowmo_end_usec = 0
	_base_time_scale = 1.0
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


## Fade to black, change scene, fade back in (used between dive floors).
func transition_to(path: String, title := "", sub := "") -> void:
	if transitioning:
		return
	transitioning = true
	_ensure_fade()
	_fade_title.text = title + ("\n" + sub if sub != "" else "")
	var t := create_tween().set_ignore_time_scale(true)
	t.tween_property(_fade, "color:a", 1.0, 0.5)
	t.parallel().tween_property(_fade_title, "modulate:a", 1.0, 0.5)
	t.tween_interval(0.5)
	t.tween_callback(go_to_scene.bind(path))
	t.tween_interval(0.6)
	t.tween_property(_fade, "color:a", 0.0, 0.7)
	t.parallel().tween_property(_fade_title, "modulate:a", 0.0, 0.7)
	t.tween_callback(func() -> void: transitioning = false)


func _ensure_fade() -> void:
	if _fade_layer:
		return
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 90
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.01, 0.02, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade)
	_fade_title = Label.new()
	_fade_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fade_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fade_title.add_theme_font_size_override("font_size", 46)
	_fade_title.add_theme_color_override("font_color", Color("19f4ff"))
	_fade_title.add_theme_constant_override("outline_size", 10)
	_fade_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_fade_title.modulate.a = 0.0
	_fade_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_title)


func go_to_scene(path: String) -> void:
	_hitstop_end_usec = 0
	_slowmo_end_usec = 0
	_base_time_scale = 1.0
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(path)
