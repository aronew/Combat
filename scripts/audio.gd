extends Node
## Autoload "Audio": every sound in the game goes through here.
##
## Sounds live in res://assets/audio/sfx as <name>_<n>.mp3; all takes of a name
## form a bank and one is picked at random (never the same twice in a row),
## with a little pitch jitter so repeats don't sound copy-pasted.
##
##   Audio.play(&"ui_click")                 2D (player, UI, stingers)
##   Audio.play_at(&"bug_death", pos)        positioned in the world
##   Audio.attach_loop(node, &"laser_hum")   looping emitter that follows a node
##
## Also runs the ambience bed for wherever you are (hub, Deepworks, starship,
## foundry, reactor), the alarm / uplink / low-health loops, and reacts to the
## Game signals (mission phases, loot, level-ups, radio, blade chain...).
## Volumes: [-] / [=] master volume, saved in user://settings.cfg.

const DIR := "res://assets/audio/sfx/"
const SETTINGS := "user://settings.cfg"
const POOL_2D := 24
const POOL_3D := 48

## Per-sound mix: db = volume, jit = pitch jitter, max = voices at once,
## gap = min seconds between starts, dist = audible range (3D), loop.
const MIX := {
	&"rifle_shot": {"db": -7.0, "max": 4, "gap": 0.03},
	&"smg_shot": {"db": -9.0, "max": 4, "gap": 0.03},
	&"scattergun_shot": {"db": -5.0, "max": 2},
	&"rail_shot": {"db": -4.0, "max": 2},
	&"launcher_shot": {"db": -5.0, "max": 2},
	&"impact_metal": {"db": -16.0, "max": 3, "gap": 0.06},
	&"impact_bug": {"db": -11.0, "max": 4, "gap": 0.035},
	&"weapon_swap": {"db": -10.0, "max": 1, "gap": 0.2},
	&"blade_swing": {"db": -6.0, "max": 3},
	&"cleaver_swing": {"db": -6.0, "max": 3},
	&"blade_finisher": {"db": -4.0, "max": 2},
	&"blade_hit": {"db": -7.0, "max": 3, "gap": 0.04},
	&"dash_strike": {"db": -6.0, "max": 2},
	&"counter": {"db": -2.0, "max": 1, "gap": 0.15},
	&"parry": {"db": -5.0, "max": 1, "gap": 0.15},
	&"silent_kill": {"db": -6.0, "max": 2},
	&"burn": {"db": -14.0, "max": 2, "gap": 0.25},
	&"shock": {"db": -12.0, "max": 2, "gap": 0.08},
	&"cryo": {"db": -12.0, "max": 2, "gap": 0.25},
	&"corrode": {"db": -14.0, "max": 2, "gap": 0.25},
	&"step_deck": {"db": -24.0, "max": 2, "jit": 0.1},
	&"step_grate": {"db": -22.0, "max": 2, "jit": 0.1},
	&"roll": {"db": -8.0, "max": 1},
	&"hurt": {"db": -5.0, "max": 1, "gap": 0.25},
	&"low_health": {"db": -10.0, "loop": true, "jit": 0.0},
	&"death": {"db": -2.0, "max": 1, "jit": 0.0},
	&"heal_orb": {"db": -10.0, "max": 2, "gap": 0.08},
	&"salvage_pickup": {"db": -20.0, "max": 3, "gap": 0.05, "jit": 0.12},
	&"level_up": {"db": -4.0, "max": 1, "jit": 0.0},
	&"loot_drop_common": {"db": -14.0, "max": 2},
	&"loot_drop_rare": {"db": -10.0, "max": 2},
	&"loot_drop_epic": {"db": -8.0, "max": 2, "jit": 0.02},
	&"loot_drop_legendary": {"db": -4.0, "max": 1, "jit": 0.0, "dist": 80.0},
	&"loot_pickup": {"db": -8.0, "max": 1},
	&"bug_chitter": {"db": -16.0, "max": 3, "gap": 0.4, "dist": 20.0},
	&"bug_alert": {"db": -10.0, "max": 3, "gap": 0.2, "dist": 40.0},
	&"bug_feeding": {"db": -14.0, "loop": true, "dist": 12.0},
	&"bite_windup": {"db": -12.0, "max": 3, "gap": 0.08, "dist": 18.0},
	&"bite": {"db": -9.0, "max": 3, "gap": 0.06, "dist": 18.0},
	&"bug_death": {"db": -9.0, "max": 4, "gap": 0.04},
	&"swarm_skitter": {"db": -16.0, "loop": true},
	&"burrow_mound": {"db": -16.0, "loop": true, "dist": 10.0},
	&"burrow_emerge": {"db": -9.0, "max": 3, "gap": 0.1},
	&"ground_crack_warning": {"db": -10.0, "max": 3, "gap": 0.15},
	&"drop_warning": {"db": -10.0, "max": 3, "gap": 0.15},
	&"bug_leap": {"db": -12.0, "max": 3, "gap": 0.08},
	&"bug_land": {"db": -12.0, "max": 3, "gap": 0.08},
	&"burster_swell": {"db": -6.0, "max": 3, "dist": 30.0},
	&"burster_pop": {"db": -4.0, "max": 3},
	&"shield_block": {"db": -10.0, "max": 2, "gap": 0.07},
	&"shield_step": {"db": -14.0, "max": 3, "gap": 0.2, "dist": 24.0},
	&"shield_roar": {"db": -5.0, "max": 2, "dist": 45.0},
	&"elite_arrival": {"db": -2.0, "max": 1, "jit": 0.0, "dist": 80.0},
	&"nest_hit": {"db": -10.0, "max": 2, "gap": 0.08},
	&"nest_destroyed": {"db": -3.0, "max": 2, "dist": 50.0},
	&"turret_wake": {"db": -8.0, "max": 2, "dist": 30.0},
	&"turret_charge": {"db": -8.0, "max": 2, "dist": 35.0},
	&"turret_lock": {"db": -9.0, "max": 2, "dist": 35.0},
	&"turret_beam": {"db": -5.0, "max": 2, "dist": 40.0},
	&"explosion": {"db": -2.0, "max": 3, "gap": 0.05, "dist": 60.0},
	&"laser_arm": {"db": -9.0, "max": 2},
	&"laser_hum": {"db": -18.0, "loop": true, "dist": 9.0},
	&"laser_zap": {"db": -6.0, "max": 2, "gap": 0.1},
	&"blast_door_close": {"db": -4.0, "max": 2, "dist": 50.0},
	&"blast_door_open": {"db": -6.0, "max": 2, "dist": 40.0},
	&"switch": {"db": -8.0, "max": 1},
	&"breaker_on": {"db": -5.0, "max": 1, "dist": 50.0},
	&"terminal_use": {"db": -8.0, "max": 1},
	&"uplink_start": {"db": -4.0, "max": 1, "jit": 0.0},
	&"uplink_loop": {"db": -16.0, "loop": true, "jit": 0.0},
	&"uplink_complete": {"db": -4.0, "max": 1, "jit": 0.0},
	&"alarm": {"db": -18.0, "loop": true, "jit": 0.0},
	&"cargo_lift_ride": {"db": -4.0, "max": 1, "jit": 0.0},
	&"lift_arrive": {"db": -5.0, "max": 1, "jit": 0.0},
	&"ui_click": {"db": -10.0, "max": 2, "gap": 0.04, "jit": 0.04},
	&"ui_hover": {"db": -20.0, "max": 1, "gap": 0.05, "jit": 0.04},
	&"ui_panel": {"db": -12.0, "max": 1, "gap": 0.1},
	&"equip": {"db": -8.0, "max": 1},
	&"scrap": {"db": -8.0, "max": 1},
	&"crate_open": {"db": -6.0, "max": 1},
	&"crate_legendary": {"db": -3.0, "max": 1, "jit": 0.0},
	&"perk_unlock": {"db": -6.0, "max": 1},
	&"map_open": {"db": -12.0, "max": 1},
	&"radio_blip": {"db": -14.0, "max": 1, "gap": 0.5},
	&"combo_tick": {"db": -16.0, "max": 2, "jit": 0.0},
	&"mission_start": {"db": -4.0, "max": 1, "jit": 0.0},
	&"mission_failed": {"db": -4.0, "max": 1, "jit": 0.0},
	&"extraction_success": {"db": -4.0, "max": 1, "jit": 0.0},
	&"card_reveal": {"db": -8.0, "max": 1},
	&"card_pick": {"db": -6.0, "max": 1},
}
const DEFAULT_MIX := {"db": -8.0, "jit": 0.06, "max": 3, "gap": 0.0, "dist": 32.0, "loop": false}

## Ambience beds per place (layers play together).
const BEDS := {
	&"hub": [[&"amb_rig", -14.0]],
	&"deepworks": [[&"amb_machinery", -17.0], [&"amb_abyss", -19.0]],
	&"hive": [[&"amb_hive", -16.0], [&"amb_abyss", -21.0]],
	&"reactor": [[&"amb_reactor", -15.0], [&"amb_machinery", -22.0]],
	&"starship": [[&"amb_starship", -14.0]],
	&"foundry": [[&"amb_foundry", -15.0], [&"lava_bubble", -24.0]],
}

var master_db := 0.0
var muted := false

var _banks := {}       # name -> Array[AudioStream]
var _last_pick := {}   # name -> index
var _last_start := {}  # name -> usec
var _voices := {}      # name -> Array of players currently on it
var _pool2d: Array[AudioStreamPlayer] = []
var _pool3d: Array[AudioStreamPlayer3D] = []
var _i2d := 0
var _i3d := 0
var _listener: AudioListener3D
var _beds: Array[AudioStreamPlayer] = []   # current ambience layers
var _bed_key := &""
var _loops := {}  # key -> AudioStreamPlayer (2D state loops: alarm, uplink, low_health)
var _scene: Node = null
var _scene_t := 0.0
var _step_t := 0.0
var _swarm_t := 0.0
var _sfx_bus := 0
var _amb_bus := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx_bus = _ensure_bus("SFX")
	_amb_bus = _ensure_bus("Ambience")
	_load_banks()
	for i in POOL_2D:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool2d.append(p)
	for i in POOL_3D:
		var p3 := AudioStreamPlayer3D.new()
		p3.bus = "SFX"
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p3.unit_size = 9.0
		p3.panning_strength = 0.6
		p3.top_level = true
		add_child(p3)
		_pool3d.append(p3)
	_listener = AudioListener3D.new()
	_listener.top_level = true
	add_child(_listener)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		master_db = float(cfg.get_value("audio", "master_db", 0.0))
		muted = bool(cfg.get_value("audio", "muted", false))
	_apply_volume()
	_connect_game()


func _ensure_bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	return idx


## Collect <name>_<n>.mp3 takes into banks. Exported builds list *.import files.
func _load_banks() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		push_warning("Audio: no sound folder at %s" % DIR)
		return
	var files := {}
	for f in dir.get_files():
		var base := f.trim_suffix(".import").trim_suffix(".remap")
		if base.get_extension() in ["mp3", "ogg", "wav"]:
			files[base] = true
	var names := files.keys()
	names.sort()
	for f in names:
		var stem: String = (f as String).get_basename()
		var cut := stem.rfind("_")
		var key := StringName(stem.substr(0, cut) if cut > 0 and stem.substr(cut + 1).is_valid_int() else stem)
		var s: AudioStream = load(DIR + f)
		if s == null:
			continue
		if _mix(key).loop or String(key).begins_with("amb_") or key == &"lava_bubble":
			if "loop" in s:
				s.loop = true
		if not _banks.has(key):
			_banks[key] = []
		_banks[key].append(s)


func has_sound(sound: StringName) -> bool:
	return _banks.has(sound)


func _mix(sound: StringName) -> Dictionary:
	var m: Dictionary = DEFAULT_MIX.duplicate()
	m.merge(MIX.get(sound, {}), true)
	return m


func _pick(sound: StringName) -> AudioStream:
	var bank: Array = _banks.get(sound, [])
	if bank.is_empty():
		return null
	var i := randi() % bank.size()
	if bank.size() > 1 and i == int(_last_pick.get(sound, -1)):
		i = (i + 1) % bank.size()
	_last_pick[sound] = i
	return bank[i]


## Voice limiting: too soon after the last start, or too many still ringing.
func _allowed(sound: StringName, m: Dictionary) -> bool:
	var now := Time.get_ticks_usec()
	if now - int(_last_start.get(sound, -10_000_000)) < int(float(m.gap) * 1_000_000.0):
		return false
	var live: Array = _voices.get(sound, [])
	var still: Array = []
	for p in live:
		if is_instance_valid(p) and p.playing and p.get_meta("sound", &"") == sound:
			still.append(p)
	_voices[sound] = still
	if still.size() >= int(m.max):
		return false
	_last_start[sound] = now
	return true


## Non-positional one-shot. Returns the player (or null if skipped).
func play(sound: StringName, volume_db := 0.0, pitch := 1.0) -> AudioStreamPlayer:
	var m := _mix(sound)
	if not _allowed(sound, m):
		return null
	var s := _pick(sound)
	if s == null:
		return null
	var p := _pool2d[_i2d]
	_i2d = (_i2d + 1) % _pool2d.size()
	p.stop()
	p.stream = s
	p.volume_db = float(m.db) + volume_db
	p.pitch_scale = pitch * (1.0 + randf_range(-m.jit, m.jit))
	p.set_meta("sound", sound)
	p.play()
	_voices[sound].append(p)
	return p


## One-shot at a world position (falls back to 2D when there's no 3D world).
func play_at(sound: StringName, pos: Vector3, volume_db := 0.0, pitch := 1.0) -> AudioStreamPlayer3D:
	var m := _mix(sound)
	if _listener_pos() != Vector3.INF and pos.distance_to(_listener_pos()) > float(m.dist) * 1.1:
		return null  # out of earshot: don't burn a voice
	if not _allowed(sound, m):
		return null
	var s := _pick(sound)
	if s == null:
		return null
	var p := _pool3d[_i3d]
	_i3d = (_i3d + 1) % _pool3d.size()
	p.stop()
	p.stream = s
	p.global_position = pos
	p.volume_db = float(m.db) + volume_db
	p.max_distance = float(m.dist)
	p.pitch_scale = pitch * (1.0 + randf_range(-m.jit, m.jit))
	p.set_meta("sound", sound)
	p.play()
	_voices[sound].append(p)
	return p


## Looping positional emitter parented to `node` (freed with it).
func attach_loop(node: Node3D, sound: StringName, volume_db := 0.0, offset := Vector3.ZERO) -> AudioStreamPlayer3D:
	if node == null or not _banks.has(sound):
		return null
	var m := _mix(sound)
	var p := AudioStreamPlayer3D.new()
	p.bus = "Ambience"
	p.stream = _pick(sound)
	p.volume_db = float(m.db) + volume_db
	p.max_distance = float(m.dist)
	p.unit_size = 4.0
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	p.position = offset
	p.autoplay = true
	node.add_child(p)
	# Start somewhere random in the loop so neighbours don't phase.
	p.play(randf() * maxf(p.stream.get_length() - 0.1, 0.0))
	return p


## 2D state loop on/off with a short fade (alarm, uplink, low health).
func set_loop(sound: StringName, on: bool, fade := 0.6) -> void:
	var p: AudioStreamPlayer = _loops.get(sound)
	if on:
		if p and p.playing:
			return
		if p == null:
			p = AudioStreamPlayer.new()
			p.bus = "SFX"
			add_child(p)
			_loops[sound] = p
		var s := _pick(sound)
		if s == null:
			return
		p.stream = s
		p.volume_db = -50.0
		p.play()
		create_tween().tween_property(p, "volume_db", float(_mix(sound).db), fade)
	elif p and p.playing:
		var tw := create_tween()
		tw.tween_property(p, "volume_db", -50.0, fade)
		tw.tween_callback(p.stop)


func stop_all_loops() -> void:
	for k in _loops:
		set_loop(k, false, 0.3)


# --------------------------------------------------------------------------
# Ambience
# --------------------------------------------------------------------------

func set_ambience(key: StringName, fade := 2.0) -> void:
	if key == _bed_key:
		return
	_bed_key = key
	for old in _beds:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -60.0, fade)
		tw.tween_callback(old.queue_free)
	_beds.clear()
	for layer in BEDS.get(key, []):
		var s := _pick(layer[0])
		if s == null:
			continue
		var p := AudioStreamPlayer.new()
		p.bus = "Ambience"
		p.stream = s
		p.volume_db = -60.0
		add_child(p)
		p.play(randf() * maxf(s.get_length() - 0.1, 0.0))
		create_tween().tween_property(p, "volume_db", float(layer[1]), fade)
		_beds.append(p)


func _bed_for_scene(scene: Node) -> StringName:
	var path := scene.scene_file_path if scene else ""
	if "hub" in path:
		return &"hub"
	var lvl = Game.level
	if lvl == null:
		return &""
	if lvl.generated:
		match Profile.dive_destination:
			"starship":
				return &"starship"
			"foundry":
				return &"foundry"
		if lvl.is_final_floor:
			return &"reactor"
		if "hive" in String(lvl.floor_name).to_lower():
			return &"hive"
	return &"deepworks"


# --------------------------------------------------------------------------
# Per-frame: listener, scene changes, footsteps
# --------------------------------------------------------------------------

func _listener_pos() -> Vector3:
	return _listener.global_position if _listener.is_current() else Vector3.INF


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _scene:
		_scene = scene
		_scene_t = 0.0
		stop_all_loops()
		_bed_key = &"?"  # force re-pick once the level is up
	_scene_t += delta
	if _bed_key == &"?" and _scene_t > 0.15 and scene:
		set_ambience(_bed_for_scene(scene))
		if scene.scene_file_path.contains("dive") and Profile.dive_floor == 0 and Game.mission:
			play(&"mission_start")
	# Listener: on the player, turned like the camera (so left is screen-left).
	var cam := get_viewport().get_camera_3d() if get_viewport() else null
	var pl = Game.player
	if cam and is_instance_valid(pl):
		var b := Basis(Vector3.UP, cam.global_rotation.y)
		_listener.global_transform = Transform3D(b, pl.global_position + Vector3.UP * 1.0)
		if not _listener.is_current():
			_listener.make_current()
		_tick_steps(pl, delta)
		_swarm_t -= delta
		if _swarm_t <= 0.0:
			_swarm_t = 0.5
			_tick_swarm(pl)
	elif cam:
		_listener.global_transform = cam.global_transform
		if not _listener.is_current():
			_listener.make_current()


## A pack closing in: skittering legs under everything.
func _tick_swarm(pl) -> void:
	var n := 0
	if Game.spawner and pl.alive:
		for e in Game.spawner.enemies_in_radius(pl.global_position, 14.0):
			if e.state == Enemy.State.CHASE:
				n += 1
	set_loop(&"swarm_skitter", n >= 6, 1.0)


func _tick_steps(pl, delta: float) -> void:
	if not pl.alive or pl.is_dashing():
		_step_t = 0.0
		return
	var v := Vector2(pl.velocity.x, pl.velocity.z).length()
	if v < 1.5:
		_step_t = 0.12
		return
	_step_t -= delta * v
	if _step_t <= 0.0:
		_step_t = 2.1
		var grate := false
		if Game.level and Game.level.regions.size() > 0:
			var r: int = Game.level.region_of(pl.global_position)
			grate = r >= 0 and Game.level.regions[r].room == &"bridge"
		play(&"step_grate" if grate else &"step_deck")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_MINUS:
				set_master_db(master_db - 3.0)
			KEY_EQUAL:
				set_master_db(master_db + 3.0)


func set_master_db(db: float) -> void:
	master_db = clampf(db, -30.0, 6.0)
	muted = master_db <= -30.0
	_apply_volume()
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("audio", "master_db", master_db)
	cfg.set_value("audio", "muted", muted)
	cfg.save(SETTINGS)
	if Graphics.has_method("_show_toast"):
		Graphics._show_toast("VOLUME: %s   ·   [-] [=]" % ("MUTED" if muted else "%d%%" % roundi(db_to_linear(master_db) * 100.0)))


func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, master_db)
	AudioServer.set_bus_mute(0, muted)


# --------------------------------------------------------------------------
# Game signals
# --------------------------------------------------------------------------

func _connect_game() -> void:
	Game.player_damaged.connect(func(_a): play(&"hurt"))
	Game.player_health_changed.connect(_on_health)
	Game.weapon_changed.connect(func(_w):
		if _scene_t > 0.6:
			play(&"weapon_swap"))
	Game.mission_phase_changed.connect(_on_phase)
	Game.radio.connect(func(_s, _t): play(&"radio_blip"))
	Game.elite_changed.connect(func(e):
		if e != null:
			play(&"elite_arrival"))
	Game.loot_picked.connect(func(_item): play(&"loot_pickup"))
	Game.level_up.connect(func(_l): play(&"level_up"))
	Game.blade_chain_changed.connect(func(n):
		if n >= 2:
			play(&"combo_tick", 0.0, 1.0 + minf(n - 2, 10) * 0.06))
	Game.mission_ended.connect(func(ok, _s):
		stop_all_loops()
		play(&"extraction_success" if ok else &"mission_failed"))


func _on_health(current: float, maximum: float) -> void:
	set_loop(&"low_health", current > 0.0 and maximum > 0.0 and current / maximum < 0.3)


func _on_phase(phase: int) -> void:
	match phase:
		Mission.Phase.UPLOAD:
			play(&"uplink_start")
			set_loop(&"alarm", true, 1.5)
			set_loop(&"uplink_loop", true, 1.0)
		Mission.Phase.EXTRACT:
			set_loop(&"uplink_loop", false)
			play(&"uplink_complete")
		Mission.Phase.LIFT:
			play(&"lift_arrive")
		Mission.Phase.DESCEND:
			stop_all_loops()
			play(&"cargo_lift_ride")
		Mission.Phase.COMPLETE, Mission.Phase.FAILED:
			stop_all_loops()


func _exit_tree() -> void:
	for p in _pool2d:
		p.stream = null
	for p in _pool3d:
		p.stream = null
	for p in _beds:
		p.stream = null
	for k in _loops:
		(_loops[k] as AudioStreamPlayer).stream = null
	_banks.clear()
	_voices.clear()
