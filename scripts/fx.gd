class_name FX
extends Node3D
## Game-feel hub. Gameplay code reports events here ("enemy hit", "enemy killed",
## "player hit"...) and this node decides how hard to juice them: particles,
## damage numbers, hitstop, and camera shake. All intensities are exported.

@export var death_burst_scene: PackedScene = preload("res://scenes/death_burst.tscn")
@export var hit_spark_scene: PackedScene = preload("res://scenes/hit_spark.tscn")
@export var damage_number_scene: PackedScene = preload("res://scenes/damage_number.tscn")

@export_group("Pools")
@export var burst_pool_size := 48
@export var spark_pool_size := 48
@export var number_pool_size := 80

@export_group("Hitstop")
@export var hitstop_on_kill := 0.045
@export var hitstop_on_player_hit := 0.14
@export var hitstop_on_player_death := 0.35
@export_range(0.0, 1.0) var hitstop_time_scale := 0.03
## Minimum real seconds between kill hitstops, so a mass kill doesn't stall the game.
@export var hitstop_kill_cooldown := 0.12

@export_group("Camera shake")
@export var shake_on_shot := 0.035
@export var shake_on_hit := 0.07
@export var shake_on_kill := 0.2
@export var shake_on_player_hit := 0.65
@export var shake_on_dash := 0.12
@export var shake_on_land := 0.0

@export_group("Damage numbers")
@export var damage_numbers_enabled := true
@export var number_color := Color("f2f6f8")
@export var kill_number_color := Color("ffe23d")
@export var number_scale := 1.0

@export_group("Colors")
@export var shot_spark_color := Color("19f4ff")
@export var wall_spark_color := Color("9ff8ff")
@export var player_hit_color := Color("ff2b6b")

var _bursts: Array[DeathBurst] = []
var _sparks: Array[HitSpark] = []
var _numbers: Array[DamageNumber] = []
var _burst_i := 0
var _spark_i := 0
var _number_i := 0
var _last_kill_stop_usec := 0


func _ready() -> void:
	Game.fx = self
	for i in burst_pool_size:
		var b: DeathBurst = death_burst_scene.instantiate()
		add_child(b)
		_bursts.append(b)
	for i in spark_pool_size:
		var s: HitSpark = hit_spark_scene.instantiate()
		add_child(s)
		_sparks.append(s)
	for i in number_pool_size:
		var n: DamageNumber = damage_number_scene.instantiate()
		add_child(n)
		_numbers.append(n)


# --------------------------------------------------------------------------
# Events
# --------------------------------------------------------------------------

func on_player_shot() -> void:
	Game.shake(shake_on_shot)


func on_player_dash(_pos: Vector3) -> void:
	Game.shake(shake_on_dash)


func on_projectile_hit(pos: Vector3, direction: Vector3) -> void:
	spark(pos, shot_spark_color, -direction)


func on_wall_hit(pos: Vector3, normal: Vector3) -> void:
	spark(pos, wall_spark_color, normal)


func on_enemy_hit(pos: Vector3, damage: float, killed: bool) -> void:
	Game.shake(shake_on_hit)
	if damage_numbers_enabled:
		var col := kill_number_color if killed else number_color
		var s := number_scale * (1.35 if killed else 1.0)
		damage_number(pos + Vector3(randf_range(-0.3, 0.3), 1.1, randf_range(-0.2, 0.2)), str(roundi(damage)), col, s)


func on_enemy_killed(pos: Vector3, direction: Vector3) -> void:
	burst(pos, direction)
	Game.shake(shake_on_kill)
	var now := Time.get_ticks_usec()
	if now - _last_kill_stop_usec >= int(hitstop_kill_cooldown * 1_000_000.0):
		_last_kill_stop_usec = now
		Game.hitstop(hitstop_on_kill, hitstop_time_scale)


func on_enemy_land(_pos: Vector3) -> void:
	if shake_on_land > 0.0:
		Game.shake(shake_on_land)


func on_player_hit(pos: Vector3, _amount: float) -> void:
	Game.shake(shake_on_player_hit)
	Game.hitstop(hitstop_on_player_hit, hitstop_time_scale)
	for i in 3:
		spark(pos, player_hit_color, Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1)).normalized())


func on_player_death(pos: Vector3) -> void:
	Game.shake(1.0)
	Game.hitstop(hitstop_on_player_death, hitstop_time_scale)
	for i in 4:
		burst(pos + Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5)), Vector3.ZERO, 1.6)


# --------------------------------------------------------------------------
# Primitives
# --------------------------------------------------------------------------

func burst(pos: Vector3, direction := Vector3.ZERO, size := 1.0) -> void:
	var b := _bursts[_burst_i]
	_burst_i = (_burst_i + 1) % _bursts.size()
	b.play(pos, direction, size)


func spark(pos: Vector3, color: Color, normal := Vector3.UP) -> void:
	var s := _sparks[_spark_i]
	_spark_i = (_spark_i + 1) % _sparks.size()
	s.play(pos, color, normal)


func damage_number(pos: Vector3, text: String, color: Color, scale_mult := 1.0) -> void:
	var n := _numbers[_number_i]
	_number_i = (_number_i + 1) % _numbers.size()
	n.play(pos, text, color, scale_mult)
