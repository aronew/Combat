class_name Mission
extends Node3D
## "First Dive" mission flow:
##   INFILTRATE  reach the uplink in the Reactor Ring (stealth optional)
##   UPLOAD      start the uplink -> ALARM; hold the zone until the bar fills
##   EXTRACT     fight back to the drop lift
##   LIFT        stand on the pad while the lift arrives
##   COMPLETE    salvage banked   /   FAILED (death): salvage lost
## Also spawns the hand-placed population, drives radio chatter and the objective beacon.

enum Phase { INFILTRATE, UPLOAD, EXTRACT, LIFT, COMPLETE, FAILED, DESCEND }

@export var mission_name := "FIRST DIVE"
@export var sector_name := "DEEPWORKS // SECTOR 1"
@export var upload_duration := 60.0
@export var upload_zone_radius := 7.0
@export var lift_countdown := 6.0
@export var elite_at_progress := 0.5
@export var uplink_salvage := 120
@export var spawn_population := true

@export_group("Rewards")
## XP per kill by enemy tier (normal, blue, gold, purple); scaled by depth.
@export var xp_by_tier: Array[int] = [6, 18, 45, 300]
## Item drop chance by enemy tier; scaled by depth.
@export var drop_chance_by_tier: Array[float] = [0.012, 0.12, 0.4, 1.0]
@export var nest_xp := 60
## Health orb drop chance by enemy tier (normal, blue, gold, purple).
@export var health_orb_chance_by_tier: Array[float] = [0.07, 0.3, 0.7, 1.0]
@export var health_orb_heal := 14
@export var uplink_xp := 300

var phase := Phase.INFILTRATE
var haul := 0
var upload := 0.0
var data_secured := false
var elapsed := 0.0
var profile := {}

var _elite_spawned := false
var _breakers_on := 0
var _lift_t := 0.0
var _in_zone := true
var _seen_rooms := {}
var _radio_queue: Array = []  # [time, speaker, text]
var _beacon: MeshInstance3D
var _zone_ring: MeshInstance3D
var _zone_mat: ShaderMaterial


func _ready() -> void:
	Game.mission = self
	if not Profile.dive_active:
		Profile.start_dive(maxi(Profile.dive_depth, 1))
	_build_markers()
	_begin.call_deferred()


func _begin() -> void:
	var lvl := Game.level
	if lvl == null:
		return
	if spawn_population and Game.spawner:
		for p in lvl.placements:
			var opts := {"tier": p.tier, "to": p.to, "alerted": false}
			for k in ["idle", "food", "radius", "route"]:
				if p.has(k):
					opts[k] = p[k]
			Game.spawner.spawn_now(p.type, p.mode, p.pos, opts)
		for t in lvl.turret_spots:
			Game.spawner.spawn_static(Game.spawner.turret_scene, t.pos, t.yaw)
	if lvl.uplink:
		lvl.uplink.used.connect(_on_uplink_used)
	for n in lvl.nests:
		n.destroyed.connect(_on_nest_destroyed)
	for b in lvl.breakers:
		b.used.connect(_on_breaker_used.bind(b))
	if lvl.cargo:
		lvl.cargo.used.connect(_on_cargo_used)
		lvl.cargo.set_enabled(lvl.breakers.is_empty())
	_restore_carry()
	if lvl.generated:
		mission_name = "DEEP DESCENT"
		sector_name = "DEEPWORKS // SECTOR %d" % Profile.dive_depth
		var fl := "FLOOR %d / %d" % [Profile.dive_floor + 1, Profile.dive_floors]
		if Profile.dive_floor == 0:
			Game.banner.emit("OPERATION: " + mission_name, "%s  ·  %s  ·  DEPTH %d" % [fl, lvl.floor_name.to_upper(), Profile.dive_depth])
		else:
			Game.banner.emit(fl, "%s  ·  DEPTH %d" % [lvl.floor_name.to_upper(), Profile.dive_depth])
		_floor_radio(lvl)
	else:
		Game.banner.emit("OPERATION: " + mission_name, "%s  ·  DEPTH %d" % [sector_name, Profile.dive_depth])
		_radio(1.0, "HANDLER", "You're down, Breaker. Uplink's in the reactor ring, three sections deep.")
		_radio(7.0, "HANDLER", "Hive's asleep. Keep it that way: the blade is quiet, the rifle is not.")
		_radio(14.0, "HANDLER", "Sleeping bugs die silent if you get the blade in first. [Q] to swap.")
	_update_floor_objective()
	Game.mission_phase_changed.emit(phase)
	Game.haul_changed.emit(haul)


func _floor_radio(lvl: Level) -> void:
	var f := Profile.dive_floor
	var floors := Profile.dive_floors
	if f == 0:
		_radio(1.0, "HANDLER", "You're in, Breaker. The uplink's at the bottom of this complex, %d floors down." % floors)
		if not lvl.is_final_floor:
			_radio(7.0, "HANDLER", "Cargo lifts are dead. Throw the breakers on each floor, then ride the lift down.")
		_radio(14.0, "HANDLER", "Hive's asleep. The blade is quiet, the rifle is not. [Q] to swap, [M] for the map.")
	elif lvl.is_final_floor:
		_radio(1.0, "HANDLER", "Bottom floor: the reactor core. Find the uplink and plug in.")
		_radio(8.0, "HANDLER", "Your way out is the lift you just rode down. Remember where it is.")
	else:
		_radio(1.0, "HANDLER", "Floor %d: %s. Same drill: breakers, then the cargo lift." % [f + 1, lvl.floor_name])


func _update_floor_objective() -> void:
	var lvl := Game.level
	if lvl.is_final_floor:
		_set_objective("Reach the uplink in the reactor core" if lvl.generated else "Reach the uplink in the Reactor Ring")
		return
	var total := lvl.breakers.size()
	if _breakers_on < total:
		_set_objective("Throw the breakers (%d/%d) to power the cargo lift" % [_breakers_on, total])
	else:
		_set_objective("Ride the cargo lift down")


func _on_breaker_used(_by: Node, b: Interactable) -> void:
	if not b.enabled:
		return
	b.set_enabled(false)
	_breakers_on += 1
	Audio.play_at(&"breaker_on", b.global_position)
	Game.shake(0.25)
	if Game.fx:
		Game.fx.text_popup(b.global_position + Vector3.UP * 2.0, "POWER ON", Color("ffd23d"), 1.1)
	# Breakers are loud: anything nearby comes to look.
	if Game.director:
		Game.director.make_noise(b.global_position, 14.0, 10.0)
	var left := Game.level.breakers.size() - _breakers_on
	if left > 0:
		_radio(0.2, "HANDLER", "Breaker's on. %d to go." % left)
	else:
		if Game.level.cargo:
			Game.level.cargo.set_enabled(true)
		Game.banner.emit("POWER RESTORED", "GET TO THE CARGO LIFT")
		_radio(0.2, "HANDLER", "That's power to the cargo lift. Get on it.")
	_update_floor_objective()


func _on_cargo_used(_by: Node) -> void:
	if phase != Phase.INFILTRATE or Game.transitioning:
		return
	phase = Phase.DESCEND
	var p := Game.player
	if p:
		p.input_locked = true
		p.grant_invulnerability(5.0)
	if Game.director:
		Game.director.stop()
	Profile.dive_carry = _carry_state()
	Profile.dive_floor += 1
	Game.mission_phase_changed.emit(phase)
	var next_final := Profile.dive_floor >= Profile.dive_floors - 1
	Game.transition_to(get_tree().current_scene.scene_file_path, "DESCENDING",
		"FLOOR %d / %d%s" % [Profile.dive_floor + 1, Profile.dive_floors, "  ·  REACTOR CORE" if next_final else ""])


func _carry_state() -> Dictionary:
	var p := Game.player
	return {
		"haul": haul, "kills": Game.kills, "best_combo": Game.best_combo, "elapsed": elapsed,
		"health": p.health if p else 0.0, "weapon": p.weapon if p else 0,
		"alert": Game.director.alert if Game.director else 0.0,
		"peak_alert": Game.director.peak_alert if Game.director else 0.0,
	}


## Next floor: bring the haul, health (plus a patch-up on the ride), kills and some of the alert.
func _restore_carry() -> void:
	var c := Profile.dive_carry
	if c.is_empty():
		return
	Profile.dive_carry = {}
	haul = int(c.haul)
	elapsed = float(c.elapsed)
	Game.kills = int(c.kills)
	Game.best_combo = int(c.best_combo)
	Game.kills_changed.emit(Game.kills, 0)
	var p := Game.player
	if p:
		p.health = minf(float(c.health) + p.max_health * 0.25, p.max_health)
		Game.player_health_changed.emit(p.health, p.max_health)
		p.set_weapon(int(c.weapon))
	if Game.director:
		Game.director.peak_alert = float(c.peak_alert)
		Game.director.add_alert(float(c.alert) * 0.5)


func _physics_process(delta: float) -> void:
	elapsed += delta
	_tick_radio(delta)
	_update_markers(delta)
	var p := Game.player
	if p == null or not p.alive or phase == Phase.COMPLETE or phase == Phase.FAILED:
		return
	_room_chatter(p)
	match phase:
		Phase.UPLOAD:
			_in_zone = _flat(p.global_position).distance_to(_flat(Game.level.uplink_position)) <= upload_zone_radius
			if _in_zone:
				upload = minf(upload + delta / upload_duration, 1.0)
			Game.upload_changed.emit(upload, _in_zone)
			if not _elite_spawned and upload >= elite_at_progress:
				_spawn_elite()
			if upload >= 1.0:
				_upload_done()
		Phase.EXTRACT:
			if _flat(p.global_position).distance_to(_flat(Game.level.lift_position)) <= Game.level.lift_radius:
				phase = Phase.LIFT
				_lift_t = 0.0
				Game.level.lift.set_state(&"called")
				_set_objective("Hold the lift pad")
				_radio(0.0, "HANDLER", "Lift's coming down. Hold that pad!")
				Game.mission_phase_changed.emit(phase)
		Phase.LIFT:
			var on_pad := _flat(p.global_position).distance_to(_flat(Game.level.lift_position)) <= Game.level.lift_radius + 0.5
			if on_pad:
				_lift_t += delta
			Game.upload_changed.emit(_lift_t / lift_countdown, on_pad)
			if _lift_t >= lift_countdown:
				_complete()


func _on_uplink_used(_by: Node) -> void:
	if phase != Phase.INFILTRATE:
		return
	phase = Phase.UPLOAD
	Audio.play(&"terminal_use")
	Game.level.uplink.set_enabled(false)
	if Game.director:
		Game.director.start_alarm()
	Game.banner.emit("ALARM TRIGGERED", "HOLD THE UPLINK ZONE")
	_set_objective("Hold the uplink zone")
	_radio(0.3, "HANDLER", "Uplink's live and the whole station heard it. Hold the zone, I need %d seconds." % roundi(upload_duration))
	Game.shake(0.5)
	Game.mission_phase_changed.emit(phase)


func _spawn_elite() -> void:
	_elite_spawned = true
	var lvl := Game.level
	var scope: Array[int] = [lvl.region_of(Game.player.global_position)]
	var pos := lvl.random_point(scope, Game.player.global_position, 6.0, 12.0)
	if pos == Vector3.INF:
		pos = lvl.clamp_to_walkable(Game.player.global_position + Vector3(0, 0, 6))
	Game.spawner.spawn(&"shield", &"drop", pos, {"tier": Enemy.Tier.PURPLE, "alerted": true})
	_radio(0.0, "HANDLER", "Big signature dropping on you, purple-class. Get behind its shield!")


func _upload_done() -> void:
	phase = Phase.EXTRACT
	data_secured = true
	add_haul(uplink_salvage)
	_give_xp(uplink_xp)
	# The uplink spits out a data cache: a guaranteed rare-or-better item.
	var d := Profile.dive_depth
	var cache := Loot.roll_item(Profile.item_level_for_depth(d), Loot.roll_rarity([0.0, 60.0 - d * 4.0, 32.0 + d * 2.0, 8.0 + d * 2.0]))
	Game.pickups.drop_item(Game.level.uplink_position + Vector3(0, 0, 2.2), cache)
	if Game.director:
		Game.director.start_extraction()
	Game.banner.emit("UPLINK COMPLETE", "GET TO THE LIFT")
	_set_objective("Extract: get back to the drop lift")
	_radio(0.2, "HANDLER", "Data's ours! Back to the lift, the long way. Seal doors behind you.")
	Game.mission_phase_changed.emit(phase)


func _complete() -> void:
	phase = Phase.COMPLETE
	if Game.player:
		Game.player.grant_invulnerability(3600.0)  # the lift has you; stragglers can't touch you
	Game.level.lift.set_state(&"ready")
	if Game.director:
		Game.director.stop()
	profile = Profile.bank_dive(haul)
	_radio(0.0, "HANDLER", "Lift's moving. Good work, Breaker.")
	Game.mission_phase_changed.emit(phase)
	Game.end_run(true)
	Game.mission_ended.emit(true, _summary())


func fail() -> void:
	if phase == Phase.COMPLETE or phase == Phase.FAILED:
		return
	phase = Phase.FAILED
	if Game.director:
		Game.director.stop()
	profile = Profile.lose_dive(haul)
	_radio(0.0, "HANDLER", "Breaker? ...Signal lost.")
	Game.mission_phase_changed.emit(phase)
	Game.end_run(false)
	Game.mission_ended.emit(false, _summary())


func add_haul(amount: int) -> void:
	if phase == Phase.COMPLETE or phase == Phase.FAILED:
		return
	haul += roundi(amount * (1.0 + float(Profile.stats().get("salvage", 0.0))))
	Game.haul_changed.emit(haul)


func _summary() -> Dictionary:
	return {
		"haul": haul,
		"data": data_secured,
		"kills": Game.kills,
		"best_combo": Game.best_combo,
		"peak_alert": Game.director.peak_alert if Game.director else 0.0,
		"time": elapsed,
		"banked": Profile.data.salvage,
		"dives": Profile.data.dives,
		"items": profile.get("items", []),
		"xp": profile.get("xp", 0),
		"levels": profile.get("levels", 0),
		"level": Profile.data.level,
		"unlocked": profile.get("unlocked", 0),
		"depth": Profile.dive_depth,
	}


# --------------------------------------------------------------------------
# Rewards: XP and loot
# --------------------------------------------------------------------------

func on_enemy_killed(e: Enemy, pos: Vector3, _kind: StringName) -> void:
	if phase == Phase.COMPLETE or phase == Phase.FAILED:
		return
	var d := Profile.dive_depth
	var type_mult: float = {&"shield": 2.5, &"turret": 3.0, &"burster": 1.2}.get(e.type_id, 1.0)
	_give_xp(roundi(xp_by_tier[e.tier] * type_mult * (1.0 + 0.25 * (d - 1))))
	if randf() < health_orb_chance_by_tier[e.tier]:
		Game.pickups.drop_health(pos, 3 if e.tier == Enemy.Tier.PURPLE else 1, health_orb_heal)
	var chance: float = drop_chance_by_tier[e.tier] * (1.0 + 0.15 * (d - 1)) * type_mult
	if randf() < chance:
		var rarity := Loot.roll_rarity(Loot.drop_weights(e.tier, d))
		Game.pickups.drop_item(pos, Loot.roll_item(Profile.item_level_for_depth(d), rarity))


func _on_nest_destroyed(nest: HiveNest) -> void:
	_give_xp(nest_xp)
	Game.pickups.drop_health(nest.global_position, 2, health_orb_heal)
	var d := Profile.dive_depth
	if randf() < 0.6:
		Game.pickups.drop_item(nest.global_position + Vector3(0, 0, 2.0), Loot.roll_item(Profile.item_level_for_depth(d), Loot.roll_rarity(Loot.drop_weights(1, d))))


func _give_xp(amount: int) -> void:
	var gained := Profile.add_xp(amount)
	if gained > 0:
		Game.level_up.emit(Profile.data.level)
		Game.banner.emit("LEVEL UP", "LEVEL %d  ·  PERK POINT READY AT THE RIG" % Profile.data.level)


func objective_position() -> Vector3:
	match phase:
		Phase.INFILTRATE, Phase.UPLOAD:
			if not Game.level.is_final_floor:
				return _next_breaker_position()
			return Game.level.uplink_position
		Phase.EXTRACT, Phase.LIFT:
			return Game.level.lift_position
	return Vector3.INF


## Nearest breaker still off, or the cargo lift once they're all on.
func _next_breaker_position() -> Vector3:
	var lvl := Game.level
	var best := lvl.cargo_position
	var best_d := INF
	var from := Game.player.global_position if Game.player else lvl.player_start
	for b in lvl.breakers:
		if b.enabled:
			var d := from.distance_to(b.global_position)
			if d < best_d:
				best_d = d
				best = b.global_position
	return best


func is_player_in_zone() -> bool:
	return _in_zone


func _set_objective(text: String) -> void:
	Game.objective_changed.emit(text)


func _room_chatter(p: Player) -> void:
	if Game.level.generated:
		return
	var room := Game.level.room_of(p.global_position)
	if room == &"" or _seen_rooms.has(room):
		return
	_seen_rooms[room] = true
	if phase != Phase.INFILTRATE:
		return
	match room:
		&"gallery":
			_radio(0.0, "HANDLER", "Switchgear gallery. Loop around the cabinets if they swarm you.")
		&"lock":
			_radio(0.0, "HANDLER", "Pressure lock. That blast door seals from the west side; remember it on the way out.")
		&"reactor":
			_radio(0.0, "HANDLER", "Reactor ring. The uplink's on the far side. Plug in and it all wakes up.")


func _radio(delay: float, speaker: String, text: String) -> void:
	_radio_queue.append([delay, speaker, text])


func _tick_radio(delta: float) -> void:
	for item in _radio_queue.duplicate():
		item[0] -= delta
		if item[0] <= 0.0:
			_radio_queue.erase(item)
			Game.radio.emit(item[1], item[2])


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


# --------------------------------------------------------------------------
# World markers: objective light column + uplink zone ring
# --------------------------------------------------------------------------

func _build_markers() -> void:
	var shader := preload("res://scripts/shaders/neon_fade.gdshader")
	_beacon = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.6
	cyl.height = 24.0
	cyl.radial_segments = 12
	_beacon.mesh = cyl
	var bm := ShaderMaterial.new()
	bm.shader = shader
	bm.set_shader_parameter("tint", Color("19f4ff"))
	bm.set_shader_parameter("energy", 1.2)
	bm.set_shader_parameter("fade", 0.35)
	bm.set_shader_parameter("edge_softness", 0.9)
	_beacon.material_override = bm
	_beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beacon.top_level = true
	add_child(_beacon)

	_zone_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.97
	tm.outer_radius = 1.0
	tm.rings = 64
	tm.ring_segments = 4
	_zone_ring.mesh = tm
	_zone_mat = ShaderMaterial.new()
	_zone_mat.shader = shader
	_zone_mat.set_shader_parameter("tint", Color("19f4ff"))
	_zone_mat.set_shader_parameter("energy", 1.1)
	_zone_mat.set_shader_parameter("fade", 0.55)
	_zone_ring.material_override = _zone_mat
	_zone_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_zone_ring.top_level = true
	_zone_ring.visible = false
	add_child(_zone_ring)


func _update_markers(_delta: float) -> void:
	var target := objective_position() if Game.level else Vector3.INF
	_beacon.visible = target != Vector3.INF and phase != Phase.UPLOAD
	if _beacon.visible:
		_beacon.global_position = target + Vector3(0, 12.0, 0)
	_zone_ring.visible = phase == Phase.UPLOAD
	if _zone_ring.visible:
		_zone_ring.global_position = Game.level.uplink_position + Vector3(0, 0.05, 0)
		_zone_ring.scale = Vector3(upload_zone_radius, 0.3, upload_zone_radius)
		var bad := not _in_zone and fmod(elapsed * 4.0, 1.0) > 0.5
		_zone_mat.set_shader_parameter("tint", Color("ff2b4b") if bad else Color("19f4ff"))
