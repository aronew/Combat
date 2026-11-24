extends Node
## Dev helper / attract mode. Launch with:
##   godot --path . -- --autoplay [--god] [--wave=N] [--shots=DIR] [--shot-times=4,10,16] [--quit-after=SECONDS]
## A bot strafes around, aims at the nearest bug, fires and dashes. Prints FPS and
## swarm stats every 2 s and can save PNG screenshots at given game times.

var _t := 0.0
var _orbit := 0.0
var _dash_cd := 0.0
var _report_t := 0.0
var _frames := 0
var _god := false
var _shots_dir := ""
var _shot_times: Array[float] = [4.0, 10.0, 16.0]
var _next_shot := 0
var _quit_after := 0.0
var _capturing := false
var _test_restart := false
var _over_t := 0.0
var _go_shot_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg == "--god":
			_god = true
		elif arg == "--test-restart":
			_test_restart = true
		elif arg.begins_with("--shots="):
			_shots_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-times="):
			_shot_times.clear()
			for s in arg.get_slice("=", 1).split(","):
				_shot_times.append(s.to_float())
		elif arg.begins_with("--quit-after="):
			_quit_after = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--wave="):
			if Game.spawner:
				Game.spawner.wave = maxi(arg.get_slice("=", 1).to_int() - 1, 0)
	if _shots_dir != "":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	if _test_restart:
		var restarts: int = Engine.get_meta("autoplay_restarts", 0)
		if restarts >= 1:
			print("[autoplay] restart OK: fresh run (wave=%d kills=%d hp=%d time_scale=%.2f)" % [Game.wave, Game.kills, roundi(Game.player.health), Engine.time_scale])
			_quit_after = 3.0
	if Game.player:
		Game.player.autopilot = true
	print("[autoplay] started god=%s shots=%s" % [_god, _shots_dir])


func _process(delta: float) -> void:
	_t += delta
	_frames += 1
	_drive(delta)
	if _shots_dir != "" and Game.is_game_over and _go_shot_t >= 0.0:
		_go_shot_t += delta
		if _go_shot_t >= 0.6 and not _capturing:
			_go_shot_t = -INF
			_capture("%s/game_over.png" % _shots_dir)
	if _test_restart and Game.is_game_over:
		_over_t += delta
		if _over_t >= 1.0:
			_over_t = -INF
			print("[autoplay] game over at wave %d with %d kills (time_scale=%.2f) -> pressing R" % [Game.wave, Game.kills, Engine.time_scale])
			var ev := InputEventKey.new()
			ev.physical_keycode = KEY_R
			ev.pressed = true
			Engine.set_meta("autoplay_restarts", Engine.get_meta("autoplay_restarts", 0) + 1)
			Input.parse_input_event(ev)

	_report_t += delta
	if _report_t >= 2.0:
		_report_t = 0.0
		var sp := Game.spawner
		print("[autoplay] t=%.1f fps=%d process=%.2fms physics=%.2fms wave=%d alive=%d kills=%d hp=%d bolts=%d" % [
			_t, Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, Game.wave,
			sp.active.size() if sp else 0, Game.kills,
			roundi(Game.player.health) if Game.player else 0,
			Game.projectiles.active_count() if Game.projectiles else 0])
		_report_stalls(sp)
		if sp and sp.active.size() <= 2:
			for e in sp.active:
				print("   [left] state=%d pos=%s vel=%s t=%.2f" % [e.state, e.global_position.snapped(Vector3.ONE * 0.1), e.velocity.snapped(Vector3.ONE * 0.1), e._state_t])

	if _shots_dir != "" and not _capturing and _next_shot < _shot_times.size() and _t >= _shot_times[_next_shot]:
		_capture("%s/shot_%02d.png" % [_shots_dir, _next_shot])
		_next_shot += 1

	if _quit_after > 0.0 and _t >= _quit_after and not _capturing:
		print("[autoplay] done: wave=%d kills=%d rescued=%d" % [Game.wave, Game.kills, Game.spawner.rescued if Game.spawner else 0])
		get_tree().quit()


## Flags chasing bugs that haven't moved 0.75 m in 3 s (pathing regressions).
var _stall := {}
func _report_stalls(sp: Spawner) -> void:
	if sp == null or Game.is_game_over:
		return
	var seen := {}
	for e in sp.active:
		if e.state != Enemy.State.CHASE:
			continue
		var id := e.get_instance_id()
		seen[id] = true
		var rec = _stall.get(id)
		if rec == null or e.global_position.distance_to(rec[0]) > 0.75:
			_stall[id] = [e.global_position, _t]
		elif _t - rec[1] >= 3.0 and Game.player and e.global_position.distance_to(Game.player.global_position) > 2.0:
			print("   [stall] bug stuck %.1fs at %s" % [_t - rec[1], e.global_position.snapped(Vector3.ONE * 0.1)])
	for id in _stall.keys():
		if not seen.has(id):
			_stall.erase(id)


func _drive(delta: float) -> void:
	var p := Game.player
	if p == null or not p.alive:
		return
	if _god:
		p.health = p.max_health
	_orbit += delta * 0.4
	var goal := Vector3(cos(_orbit) * 8.0, 0.0, sin(_orbit) * 4.0)
	var to := goal - p.global_position
	p.auto_move = Vector2(to.x, to.z).limit_length(1.0) if to.length() > 0.6 else Vector2.ZERO

	var nearest: Enemy = null
	var best := INF
	if Game.spawner:
		for e in Game.spawner.active:
			if e.state != Enemy.State.CHASE:
				continue
			var d := p.global_position.distance_to(e.global_position)
			if d < best:
				best = d
				nearest = e
	if nearest:
		p.auto_aim = nearest.global_position
		p.auto_fire = true
	else:
		p.auto_fire = false
		p.auto_aim = p.global_position + p.aim_dir * 5.0

	_dash_cd -= delta
	if nearest and best < 2.6 and _dash_cd <= 0.0:
		var away := (p.global_position - nearest.global_position).normalized()
		p.auto_move = Vector2(away.x, away.z)
		p.auto_dash = true
		_dash_cd = 1.2


func _capture(path: String) -> void:
	_capturing = true
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("[autoplay] screenshot %s (%s)" % [path, error_string(err)])
	_capturing = false
