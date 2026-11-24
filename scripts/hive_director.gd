class_name HiveDirector
extends Node
## The station's "awareness". Noise (gunfire, explosions, screams) wakes nearby
## bugs and raises the alert meter; silence lets it decay.
##   DORMANT  -> bugs sleep / patrol, blade kills from behind are silent
##   STIRRING -> bugs that hear noise come to investigate
##   HUNTING  -> packs burrow up / drop in near you every few seconds
##   ALARM    -> uplink running: continuous waves (stronger if you arrived loud)
## Higher alert also means better salvage drops, so going loud is a choice.

enum AlertLevel { DORMANT, STIRRING, HUNTING, ALARM }
const LEVEL_NAMES := ["DORMANT", "STIRRING", "HUNTING", "ALARM"]

@export_group("Alert meter")
@export var stirring_at := 25.0
@export var hunting_at := 60.0
@export var decay_delay := 5.0
@export var decay_rate := 2.2

@export_group("Noise")
@export var gun_noise_radius := 15.0
@export var gun_noise_alert := 0.5
@export var blade_noise_radius := 3.5
@export var blade_noise_alert := 0.15
@export var explosion_noise_radius := 22.0
@export var explosion_noise_alert := 7.0
@export var scream_radius := 9.0
@export var scream_alert := 5.0

@export_group("Hunting packs")
@export var hunt_interval := Vector2(10.0, 14.0)
@export var hunt_pack_size := Vector2i(2, 4)

@export_group("Alarm waves")
@export var alarm_base_rate := 0.85  ## Bugs per second.
@export var alarm_rate_from_alert := 1.0  ## Extra bugs/s if you started the uplink at max alert.
@export var alarm_ramp := 0.01  ## Extra bugs/s per second of alarm.
@export var extract_rate := 0.6
@export var burster_chance := 0.12
@export var shield_chance := 0.07
@export var blue_chance := 0.05
@export var gold_chance := 0.015
@export var max_alive_alarm := 150

@export_group("Spawn placement")
@export var spawn_min_distance := 6.0
@export var spawn_max_distance := 15.0

@export_group("Loot")
## Salvage multiplier at full alert (1 + this). Noise pays out.
@export var loot_bonus_at_max := 1.0

var alert := 0.0
var level := AlertLevel.DORMANT
var peak_alert := 0.0
var mode := &"stealth"  # &"stealth" | &"alarm" | &"extract" | &"off"

var _quiet_t := 0.0
var _hunt_t := 8.0
var _budget := 0.0
var _alarm_t := 0.0
var _alarm_intensity := 0.0


func _ready() -> void:
	Game.director = self


## Noise at `pos`: bugs within `radius` hear it (close ones come hunting, far
## ones investigate), and the alert meter rises.
func make_noise(pos: Vector3, radius: float, alert_amount: float) -> void:
	if mode == &"off":
		return
	if Game.spawner:
		for e in Game.spawner.enemies_in_radius(pos, radius):
			if e.is_unaware():
				var d := Vector2(e.global_position.x - pos.x, e.global_position.z - pos.z).length()
				e.hear_noise(pos, d < radius * 0.5)
	add_alert(alert_amount)


func add_alert(amount: float) -> void:
	if mode != &"stealth" or amount <= 0.0:
		return
	alert = minf(alert + amount, 100.0)
	peak_alert = maxf(peak_alert, alert)
	_quiet_t = 0.0
	_update_level()


## A bug spotted the player and screamed.
func on_enemy_spotted(e: Enemy) -> void:
	make_noise(e.global_position, scream_radius, scream_alert)


func loot_multiplier() -> float:
	return 1.0 + (alert / 100.0) * loot_bonus_at_max


func start_alarm() -> void:
	_alarm_intensity = alert / 100.0
	mode = &"alarm"
	alert = 100.0
	peak_alert = 100.0
	_alarm_t = 0.0
	_budget = 0.0
	_set_level(AlertLevel.ALARM)
	# Everything nearby wakes up when the uplink screams.
	if Game.spawner and Game.player:
		for e in Game.spawner.enemies_in_radius(Game.player.global_position, 30.0):
			e.alert(false)


func start_extraction() -> void:
	mode = &"extract"
	_budget = 0.0


func stop() -> void:
	mode = &"off"


func _update_level() -> void:
	if mode != &"stealth":
		return
	var lvl := AlertLevel.DORMANT
	if alert >= hunting_at:
		lvl = AlertLevel.HUNTING
	elif alert >= stirring_at:
		lvl = AlertLevel.STIRRING
	_set_level(lvl)


func _set_level(lvl: AlertLevel) -> void:
	if lvl != level:
		var rising := lvl > level
		level = lvl
		if rising and lvl == AlertLevel.HUNTING:
			_hunt_t = 2.0
			Game.radio.emit("HANDLER", "They're hunting you now. Keep moving or go quiet.")
	Game.alert_changed.emit(level, alert)


func _physics_process(delta: float) -> void:
	if Game.is_game_over or Game.player == null or not Game.player.alive:
		return
	match mode:
		&"stealth":
			_quiet_t += delta
			if _quiet_t > decay_delay and alert > 0.0:
				alert = maxf(alert - decay_rate * delta, 0.0)
				_update_level()
			if level >= AlertLevel.HUNTING:
				_hunt_t -= delta
				if _hunt_t <= 0.0:
					_hunt_t = randf_range(hunt_interval.x, hunt_interval.y)
					var n := randi_range(hunt_pack_size.x, hunt_pack_size.y)
					var mode_pick := &"burrow" if randf() < 0.6 else &"drop"
					for i in n:
						_spawn_unit(&"swarmer", Enemy.Tier.NORMAL, mode_pick)
			Game.alert_changed.emit(level, alert)
		&"alarm":
			_alarm_t += delta
			var rate := (alarm_base_rate + alarm_rate_from_alert * _alarm_intensity + alarm_ramp * _alarm_t) * _depth_scale()
			_budget += rate * delta
			_drain_budget(max_alive_alarm)
		&"extract":
			_budget += extract_rate * _depth_scale() * delta
			_drain_budget(100)


func _drain_budget(cap: int) -> void:
	while _budget >= 1.0:
		_budget -= 1.0
		if Game.spawner and Game.spawner.alive_count() >= cap:
			_budget = 0.0
			return
		var r := randf()
		var type := &"swarmer"
		if r < shield_chance and _alarm_t > 15.0:
			type = &"shield"
		elif r < shield_chance + burster_chance:
			type = &"burster"
		var tr := randf()
		var tier := Enemy.Tier.NORMAL
		var tier_scale := 1.0 + 0.5 * (Profile.dive_depth - 1)
		if tr < gold_chance * tier_scale:
			tier = Enemy.Tier.GOLD
		elif tr < (gold_chance + blue_chance) * tier_scale:
			tier = Enemy.Tier.BLUE
		_spawn_unit(type, tier, &"")


func _depth_scale() -> float:
	return 1.0 + 0.15 * (Profile.dive_depth - 1)


## Pick an entrance near the player: leap from the void, burrow, drop in, or crawl out of a nest.
func _spawn_unit(type: StringName, tier: int, forced_mode: StringName) -> void:
	var lvl := Game.level
	var p := Game.player
	if lvl == null or p == null:
		return
	var here := lvl.region_of(p.global_position)
	if here < 0:
		return
	var scope: Array[int] = [here]
	scope.append_array(lvl.region_neighbors(here))
	var opts := {"tier": tier, "alerted": true}
	var roll := randf()
	var spawn_mode := forced_mode
	if spawn_mode == &"":
		spawn_mode = &"leap" if roll < 0.35 else (&"burrow" if roll < 0.7 else (&"drop" if roll < 0.88 else &"nest"))
	if spawn_mode == &"nest":
		var nests: Array = []
		for n in lvl.nests:
			if n.is_alive() and n.global_position.distance_to(p.global_position) < 26.0:
				nests.append(n)
		if not nests.is_empty():
			Game.spawner.spawn(type, &"burrow", nests.pick_random().get_spawn_point(), opts)
			return
		spawn_mode = &"burrow"
	if spawn_mode == &"leap":
		var edge := lvl.get_leap_spawn(scope, p.global_position, spawn_min_distance, spawn_max_distance)
		if not edge.is_empty():
			opts["from"] = edge[0]
			Game.spawner.spawn(type, &"leap", edge[1], opts)
			return
		spawn_mode = &"burrow"
	var pos := lvl.random_point(scope, p.global_position, spawn_min_distance, spawn_max_distance)
	if pos == Vector3.INF:
		return
	Game.spawner.spawn(type, spawn_mode, pos, opts)
