class_name LaserGrid
extends Node3D
## Switch-armed laser fence across a walkway (spans local Z). Arm it, then run
## through during the warm-up (or roll through it later; invincibility frames
## save you) and let the swarm chasing you get sliced.

@export var span := 3.0
@export var warmup := 1.1
@export var active_time := 6.0
@export var cooldown := 9.0
@export var tick := 0.2
@export var enemy_damage_per_tick := 40.0
@export var player_damage := 22.0
@export var beam_color := Color("ff2b6b")

enum Mode { OFF, WARMUP, ON, COOLDOWN }

var switch: Interactable
var mode := Mode.OFF

var _t := 0.0
var _tick_t := 0.0
var _beams: Array[MeshInstance3D] = []
var _beam_mat: ShaderMaterial
var _emitter_mat: StandardMaterial3D


func _ready() -> void:
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color("2a3036")
	post_mat.metallic = 0.6
	_emitter_mat = StandardMaterial3D.new()
	_emitter_mat.albedo_color = Color(0.05, 0.02, 0.03)
	_emitter_mat.emission_enabled = true
	_emitter_mat.emission = beam_color
	_emitter_mat.emission_energy_multiplier = 0.5
	for s in [-1.0, 1.0]:
		_box(Vector3(0.22, 1.5, 0.22), Vector3(0, 0.75, s * (span * 0.5 + 0.05)), post_mat)
		_box(Vector3(0.26, 0.9, 0.1), Vector3(0, 0.75, s * (span * 0.5 - 0.08)), _emitter_mat)
	_beam_mat = ShaderMaterial.new()
	_beam_mat.shader = preload("res://scripts/shaders/neon_fade.gdshader")
	_beam_mat.set_shader_parameter("tint", beam_color)
	_beam_mat.set_shader_parameter("energy", 4.0)
	_beam_mat.set_shader_parameter("fade", 1.0)
	for h in [0.3, 0.7, 1.1]:
		var b := _box(Vector3(0.05, 0.05, span), Vector3(0, h, 0), _beam_mat)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		b.visible = false
		_beams.append(b)
	if switch:
		switch.used.connect(func(_by): arm())
	_set_mode(Mode.OFF)


func arm() -> void:
	if mode == Mode.OFF:
		_set_mode(Mode.WARMUP)


var _hum: AudioStreamPlayer3D


func _set_mode(m: Mode) -> void:
	mode = m
	_t = 0.0
	if m == Mode.WARMUP:
		Audio.play_at(&"laser_arm", global_position)
	if m == Mode.ON and _hum == null:
		_hum = Audio.attach_loop(self, &"laser_hum", 0.0, Vector3.UP * 0.8)
	elif m != Mode.ON and _hum:
		_hum.queue_free()
		_hum = null
	_tick_t = 0.0
	for b in _beams:
		b.visible = m == Mode.ON or m == Mode.WARMUP
	_emitter_mat.emission_energy_multiplier = 4.0 if m == Mode.ON else (2.0 if m == Mode.WARMUP else 0.5)
	if switch:
		switch.set_enabled(m == Mode.OFF)
		switch.disabled_prompt = "Laser grid live" if m == Mode.ON or m == Mode.WARMUP else "Laser grid recharging"


func _physics_process(delta: float) -> void:
	if mode == Mode.OFF:
		return
	_t += delta
	match mode:
		Mode.WARMUP:
			# Flicker so it reads as "about to go live".
			var on := fmod(_t * 12.0, 1.0) > 0.5
			_beam_mat.set_shader_parameter("fade", 0.35 if on else 0.08)
			if _t >= warmup:
				_beam_mat.set_shader_parameter("fade", 1.0)
				_set_mode(Mode.ON)
		Mode.ON:
			_beam_mat.set_shader_parameter("fade", 0.8 + 0.2 * sin(_t * 40.0))
			_tick_t -= delta
			if _tick_t <= 0.0:
				_tick_t = tick
				_zap()
			if _t >= active_time:
				_set_mode(Mode.COOLDOWN)
		Mode.COOLDOWN:
			if _t >= cooldown:
				_set_mode(Mode.OFF)


func _zap() -> void:
	var a := to_global(Vector3(0, 0, -span * 0.5))
	var b := to_global(Vector3(0, 0, span * 0.5))
	var across := global_transform.basis.x.normalized()
	if Game.spawner:
		for e in Game.spawner.enemies_on_segment(a, b, 0.2):
			var side := signf((e.global_position - global_position).dot(across))
			e.take_hit(enemy_damage_per_tick, across * (side if side != 0.0 else 1.0), 3.0, Game.TEAM_NEUTRAL, &"laser")
			Audio.play_at(&"laser_zap", e.global_position)
			if Game.fx:
				Game.fx.spark(e.global_position + Vector3.UP * 0.5, beam_color, Vector3.UP)
	var p := Game.player
	if p and p.alive:
		var q := Geometry3D.get_closest_point_to_segment(Vector3(p.global_position.x, 0, p.global_position.z), Vector3(a.x, 0, a.z), Vector3(b.x, 0, b.z))
		if q.distance_to(Vector3(p.global_position.x, 0, p.global_position.z)) < 0.45:
			if p.take_damage(player_damage, q):
				Audio.play(&"laser_zap")


func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi
