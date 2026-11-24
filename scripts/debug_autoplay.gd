extends Node
## Dev helper / attract mode. Launch with:
##   godot --path . -- --autoplay [--god] [--stealth] [--skip-to=uplink] [--shots=DIR]
##       [--shot-times=4,10,16] [--quit-after=SECONDS] [--test-restart]
## A bot plays the mission: follows the route through the level's doorways,
## fights whatever is hunting it, starts the uplink, holds the zone, extracts.
## Prints FPS, frame times, phase and swarm stats every 2 s, flags stuck bugs,
## and can save PNG screenshots at given game times.

const PHASES := ["INFILTRATE", "UPLOAD", "EXTRACT", "LIFT", "COMPLETE", "FAILED"]

var _t := 0.0
var _report_t := 0.0
var _god := false
var _stealth := false
var _skip := ""
var _shots_dir := ""
var _shot_times: Array[float] = [4.0, 10.0, 16.0]
var _next_shot := 0
var _quit_after := 0.0
var _capturing := false
var _test_restart := false
var _over_t := 0.0
var _go_shot_t := 0.0
var _dash_cd := 0.0
var _orbit := 0.0
var _last_pos := Vector3.ZERO
var _stuck_t := 0.0
var _side_t := 0.0
var _side := Vector3.ZERO
var _stall := {}
var _ended := false
var _gear := ""
var _loot_demo := false
var _blade := false
var _counters := 0
var _strikes := 0
var _best_chain := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg == "--god":
			_god = true
		elif arg == "--stealth":
			_stealth = true
		elif arg == "--test-restart":
			_test_restart = true
		elif arg.begins_with("--skip-to="):
			_skip = arg.get_slice("=", 1)
		elif arg.begins_with("--shots="):
			_shots_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-times="):
			_shot_times.clear()
			for s in arg.get_slice("=", 1).split(","):
				_shot_times.append(s.to_float())
		elif arg.begins_with("--quit-after="):
			_quit_after = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--depth="):
			Profile.data.max_depth = Profile.MAX_DEPTH
			Profile.dive_depth = clampi(arg.get_slice("=", 1).to_int(), 1, Profile.MAX_DEPTH)
		elif arg == "--fresh":
			# A brand-new character: starter rifle + blade, level 1, no perks. Never saved.
			Profile.persist = false
			Profile.data.level = 1
			Profile.data.perks = {}
			Profile.data.equipped = {"gun": Loot.starter_gun(), "blade": Loot.starter_blade()}
			Profile._touch()
		elif arg == "--blade":
			_blade = true
		elif arg == "--loot-demo":
			_loot_demo = true
		elif arg.begins_with("--gear="):
			_gear = arg.get_slice("=", 1)
	if _shots_dir != "":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	if _gear != "":
		_equip_test_gear()
	if _test_restart and int(Engine.get_meta("autoplay_restarts", 0)) >= 1:
		print("[autoplay] restart OK: fresh run (phase=%s kills=%d hp=%d time_scale=%.2f)" % [
			PHASES[Game.mission.phase], Game.kills, roundi(Game.player.health), Engine.time_scale])
		_quit_after = 3.0
	if Game.player:
		Game.player.autopilot = true
		if _skip == "uplink" and Game.level:
			Game.player.global_position = Game.level.uplink_position + Vector3(0, 0, 4.0)
	Game.mission_ended.connect(_on_mission_ended)
	print("[autoplay] started god=%s stealth=%s skip=%s" % [_god, _stealth, _skip])


## In-memory only (never saved): equip a random high-tier kit, each gun archetype
## and legendary gets exercised across runs. --gear=legendary | epic | random
func _equip_test_gear() -> void:
	Profile.persist = false
	var forced := _gear.get_slice(":", 1) if ":" in _gear else ""
	var kind := _gear.get_slice(":", 0)
	var rarity := Loot.Rarity.LEGENDARY if kind == "legendary" else (Loot.Rarity.EPIC if kind == "epic" else -1)
	var lvl := Profile.item_level_for_depth(Profile.dive_depth)
	for slot in Loot.SLOTS:
		var r := rarity if rarity >= 0 else Loot.roll_rarity([30.0, 35.0, 25.0, 10.0])
		var it := Loot.roll_item(lvl, r, slot)
		if forced in Loot.ELEMENTS and slot == "gun":
			it.affixes = [{"stat": forced, "value": 0.6}]
		if forced in Loot.LEGENDARIES and Loot.LEGENDARIES[forced].slot == slot:
			it.legendary = forced
		Profile.data.equipped[slot] = it
	Profile._touch()
	var names: PackedStringArray = []
	for slot in Loot.SLOTS:
		var it: Dictionary = Profile.data.equipped[slot]
		names.append("%s:%s(%s%s)" % [slot, it.archetype, Loot.RARITY_NAMES[it.rarity], ("/" + it.legendary) if it.legendary != "" else ""])
	print("[autoplay] test gear: ", ", ".join(names))
	print("[autoplay] stats: hp+%d armor %.2f crit %.2f elements %s" % [Profile.stats().max_health, Profile.stats().armor, Profile.stats().crit_chance,
		{"burn": Profile.stats().burn, "shock": Profile.stats().shock, "cryo": Profile.stats().cryo, "corrode": Profile.stats().corrode}])


func _on_mission_ended(success: bool, s: Dictionary) -> void:
	_ended = true
	print("[autoplay] MISSION %s haul=%d data=%s kills=%d peak_alert=%d time=%.1f banked=%d rescued=%d" % [
		"EXTRACTED" if success else "FAILED", s.haul, s.data, s.kills, roundi(s.peak_alert), s.time, s.banked,
		Game.spawner.rescued if Game.spawner else 0])


func _process(delta: float) -> void:
	_t += delta
	if _loot_demo and _t > 1.0 and Game.pickups and Game.player:
		_loot_demo = false
		Profile.persist = false
		for r in 4:
			var ang := -PI * 0.5 + (r - 1.5) * 0.6
			var pos := Game.player.global_position + Vector3(cos(ang), 0, sin(ang)) * 4.0
			Game.pickups.drop_item(pos, Loot.roll_item(Profile.item_level_for_depth(Profile.dive_depth), r))
	_drive(delta)

	_report_t += delta
	if _report_t >= 2.0:
		_report_t = 0.0
		var sp := Game.spawner
		var m := Game.mission
		print("[autoplay] t=%.1f fps=%d process=%.2fms physics=%.2fms phase=%s alert=%d room=%s pos=%s alive=%d kills=%d haul=%d hp=%d upload=%d%%" % [
			_t, Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			PHASES[m.phase] if m else "-", roundi(Game.director.alert) if Game.director else 0,
			Game.level.room_of(Game.player.global_position) if Game.level and Game.player else "-",
			Game.player.global_position.snapped(Vector3.ONE * 0.1) if Game.player else Vector3.ZERO,
			sp.active.size() if sp else 0, Game.kills, m.haul if m else 0,
			roundi(Game.player.health) if Game.player else 0, roundi(m.upload * 100.0) if m else 0])
		_report_stalls(sp)

	if _shots_dir != "" and not _capturing and _next_shot < _shot_times.size() and _t >= _shot_times[_next_shot]:
		_capture("%s/shot_%02d.png" % [_shots_dir, _next_shot])
		_next_shot += 1
	if _shots_dir != "" and Game.is_game_over and _go_shot_t >= 0.0:
		_go_shot_t += delta
		if _go_shot_t >= 1.2 and not _capturing:
			_go_shot_t = -INF
			_capture("%s/results.png" % _shots_dir)
	if _test_restart and Game.is_game_over:
		_over_t += delta
		if _over_t >= 1.0:
			_over_t = -INF
			print("[autoplay] run over (kills=%d time_scale=%.2f) -> pressing R" % [Game.kills, Engine.time_scale])
			Engine.set_meta("autoplay_restarts", int(Engine.get_meta("autoplay_restarts", 0)) + 1)
			var ev := InputEventKey.new()
			ev.physical_keycode = KEY_R
			ev.pressed = true
			Input.parse_input_event(ev)
	if _quit_after > 0.0 and _t >= _quit_after and not _capturing:
		print("[autoplay] done: phase=%s kills=%d rescued=%d" % [
			PHASES[Game.mission.phase] if Game.mission else "-", Game.kills, Game.spawner.rescued if Game.spawner else 0])
		if _blade and Game.player:
			print("[autoplay] blade: strikes=%d counters=%d best_chain=%d best_combo=%d" % [
				Game.player.stat_strikes, Game.player.stat_counters, _best_chain, Game.best_combo])
		get_tree().quit()
	elif _ended and _quit_after <= 0.0 and Game.is_game_over and _go_shot_t < 0.0 and not _capturing and not _test_restart:
		get_tree().quit()
	elif _ended and _quit_after <= 0.0 and _shots_dir == "" and not _test_restart:
		get_tree().quit()


func _drive(delta: float) -> void:
	var p := Game.player
	var m := Game.mission
	var lvl := Game.level
	if p == null or not p.alive or m == null or lvl == null:
		return
	if _god:
		p.health = p.max_health
	var pos := p.global_position

	# ---- where to go
	var goal := m.objective_position()
	if goal == Vector3.INF:
		goal = pos
	if m.phase == Mission.Phase.INFILTRATE:
		goal = lvl.uplink_position + Vector3(0, 0, 1.6)
		if pos.distance_to(lvl.uplink_position) < 2.4:
			p.auto_interact = true
	elif m.phase == Mission.Phase.UPLOAD:
		_orbit += delta * 1.5
		goal = lvl.uplink_position + Vector3(cos(_orbit) * 3.5, 0, 2.5 + sin(_orbit) * 1.5)
	var nav := lvl.get_nav_target(pos, goal)
	var to := nav - pos
	to.y = 0.0
	var move := to.normalized() if to.length() > 0.6 else Vector3.ZERO
	if m.phase == Mission.Phase.LIFT and pos.distance_to(lvl.lift_position) < 1.5:
		move = Vector3.ZERO

	# ---- simple unstick for the bot itself
	if move != Vector3.ZERO and pos.distance_to(_last_pos) < 0.02:
		_stuck_t += delta
	else:
		_stuck_t = maxf(_stuck_t - delta, 0.0)
	_last_pos = pos
	if _stuck_t > 0.6:
		_stuck_t = 0.0
		_side_t = 0.8
		_side = Vector3(-move.z, 0, move.x) * (1.0 if randf() < 0.5 else -1.0)
	if _side_t > 0.0:
		_side_t -= delta
		move = (move * 0.3 + _side).normalized()

	# ---- who to fight
	var nearest: Enemy = null
	var best := INF
	var sleeper: Enemy = null
	var sleeper_d := INF
	for e in Game.spawner.active:
		var d := pos.distance_to(e.global_position)
		if e.is_unaware():
			if d < sleeper_d:
				sleeper_d = d
				sleeper = e
			continue
		if e.state != Enemy.State.CHASE:
			continue
		if d < best:
			best = d
			nearest = e
	if _stealth and nearest == null and sleeper and sleeper_d < 6.0:
		p.auto_weapon = Player.Weapon.BLADE
		p.auto_aim = sleeper.global_position
		p.auto_fire = sleeper_d < 2.2
		var to_s := sleeper.global_position - pos
		move = to_s.normalized() if sleeper_d > 1.6 else Vector3.ZERO
	elif _blade and nearest and best < 9.0:
		# Blade dance: aim at the nearest bug and keep cutting; the target
		# assist and dash-strikes do the rest. Hold position otherwise.
		p.auto_weapon = Player.Weapon.BLADE
		p.auto_aim = nearest.global_position
		p.auto_fire = true
		_best_chain = maxi(_best_chain, p.get_blade_chain())
		if best < 3.0:
			move = Vector3.ZERO
	elif nearest and best < 14.0:
		p.auto_weapon = Player.Weapon.RIFLE
		p.auto_aim = nearest.global_position
		p.auto_fire = true
	else:
		p.auto_weapon = Player.Weapon.BLADE if _stealth else Player.Weapon.RIFLE
		p.auto_fire = false
		p.auto_aim = pos + (move if move != Vector3.ZERO else p.aim_dir) * 5.0

	_dash_cd -= delta
	if nearest and best < 2.4 and _dash_cd <= 0.0:
		var away := (pos - nearest.global_position).normalized()
		move = (away + move).normalized()
		p.auto_dash = true
		_dash_cd = 1.2
	p.auto_move = Vector2(move.x, move.z)


## Flags hunting bugs that haven't moved 0.75 m in 3 s (pathing regressions).
func _report_stalls(sp: Spawner) -> void:
	if sp == null or Game.is_game_over:
		return
	var seen := {}
	for e in sp.active:
		if e.state != Enemy.State.CHASE or e.type_id == &"turret":
			continue
		var id := e.get_instance_id()
		seen[id] = true
		var rec = _stall.get(id)
		if rec == null or e.global_position.distance_to(rec[0]) > 0.75:
			_stall[id] = [e.global_position, _t]
		elif _t - rec[1] >= 3.0 and Game.player and e.global_position.distance_to(Game.player.global_position) > 2.5 + e.contact_range * Enemy.TIER_SCALE[e.tier] + e.get_hit_radius():
			print("   [stall] %s stuck %.1fs at %s (room %s)" % [e.type_id, _t - rec[1], e.global_position.snapped(Vector3.ONE * 0.1), Game.level.room_of(e.global_position)])
	for id in _stall.keys():
		if not seen.has(id):
			_stall.erase(id)


func _capture(path: String) -> void:
	_capturing = true
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("[autoplay] screenshot %s (%s)" % [path, error_string(err)])
	_capturing = false
