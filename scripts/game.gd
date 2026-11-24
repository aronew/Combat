extends Node
## Autoload "Game": shared references, run state (wave/kills/combo), and global
## game-feel mechanisms (hitstop, camera shake passthrough). Tuning values live on
## the scene nodes (FX, CameraRig, Spawner, Player) as @export variables.

signal wave_announced(wave: int, total_enemies: int)
signal wave_progress(remaining: int, total: int)
signal wave_cleared(wave: int)
signal kills_changed(kills: int, combo: int)
signal player_health_changed(current: float, maximum: float)
signal player_damaged(amount: float)
signal game_over(wave: int, kills: int)

# Scene references (each node registers itself in _ready).
var player: Player
var camera_rig: CameraRig
var arena: Arena
var spawner: Spawner
var projectiles: ProjectilePool
var fx: FX
var hud: Node

# Run state
var wave := 0
var kills := 0
var combo := 0
var best_combo := 0
var is_game_over := false
var combo_window := 1.6

var _combo_timer := 0.0
var _hitstop_end_usec := 0
var _base_time_scale := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Called by Main when a run starts (also after a restart reloads the scene).
func reset_run() -> void:
	player = null
	camera_rig = null
	arena = null
	spawner = null
	projectiles = null
	fx = null
	hud = null
	wave = 0
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
		_combo_timer -= delta  # scaled delta: combo timer pauses during hitstop
		if _combo_timer <= 0.0:
			combo = 0
			kills_changed.emit(kills, combo)


## Freeze-frame: drop time scale to `scale` for `duration` real seconds.
func hitstop(duration: float, scale: float = 0.03) -> void:
	if duration <= 0.0:
		return
	var end := Time.get_ticks_usec() + int(duration * 1_000_000.0)
	_hitstop_end_usec = maxi(_hitstop_end_usec, end)
	Engine.time_scale = minf(scale, _base_time_scale)


func is_in_hitstop() -> bool:
	return _hitstop_end_usec > 0


func shake(trauma: float) -> void:
	if camera_rig:
		camera_rig.add_trauma(trauma)


func register_kill() -> void:
	kills += 1
	combo += 1
	best_combo = maxi(best_combo, combo)
	_combo_timer = combo_window
	kills_changed.emit(kills, combo)


func announce_wave(new_wave: int, total: int) -> void:
	wave = new_wave
	wave_announced.emit(new_wave, total)


func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	_base_time_scale = 0.35  # dramatic slow-mo while the GAME OVER screen comes up
	Engine.time_scale = _base_time_scale
	game_over.emit(wave, kills)


func restart() -> void:
	_hitstop_end_usec = 0
	_base_time_scale = 1.0
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
