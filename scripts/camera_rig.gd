class_name CameraRig
extends Node3D
## High-angle top-down follow camera (sciveg reference). Never rotates with the
## player; follows with exponential smoothing, leans toward the aim direction,
## and applies trauma-based shake on real time so it keeps shaking during hitstop.

@export var target_path: NodePath

@export_group("Framing")
@export_range(30.0, 89.0) var pitch_degrees := 56.0
@export_range(-180.0, 180.0) var yaw_degrees := 0.0
@export var distance := 25.0
@export var fov := 48.0

@export_group("Follow")
@export var follow_smoothing := 7.0
@export var look_ahead := 2.5
@export var look_ahead_smoothing := 3.5

@export_group("Shake")
@export var max_shake_offset := 0.9
@export var max_shake_roll_degrees := 2.0
@export var shake_decay := 1.6
@export var shake_frequency := 24.0

@onready var camera: Camera3D = $Camera3D

var trauma := 0.0
var _target: Node3D
var _focus := Vector3.ZERO
var _ahead := Vector3.ZERO
var _noise := FastNoiseLite.new()
var _noise_t := 0.0
var _last_usec := 0


func _ready() -> void:
	Game.camera_rig = self
	_target = get_node_or_null(target_path) as Node3D
	_noise.seed = randi()
	_noise.frequency = 1.0
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	apply_framing()
	if _target:
		_focus = _target.global_position
		global_position = _focus
	camera.make_current()
	_last_usec = Time.get_ticks_usec()


func apply_framing() -> void:
	rotation = Vector3(0.0, deg_to_rad(yaw_degrees), 0.0)
	var pitch := deg_to_rad(pitch_degrees)
	camera.position = Vector3(0.0, sin(pitch) * distance, cos(pitch) * distance)
	camera.rotation = Vector3(-pitch, 0.0, 0.0)
	camera.fov = fov


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


## Horizontal camera basis, used by the player to make WASD camera-relative.
func get_flat_basis() -> Basis:
	return Basis(Vector3.UP, deg_to_rad(yaw_degrees))


func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_dt := minf((now - _last_usec) / 1_000_000.0, 0.1)
	_last_usec = now

	if is_instance_valid(_target):
		var lean := Vector3.ZERO
		if _target.has_method("get_aim_offset"):
			lean = _target.get_aim_offset() * look_ahead
		_ahead = _ahead.lerp(lean, 1.0 - exp(-look_ahead_smoothing * delta))
		var goal := _target.global_position + _ahead
		_focus = _focus.lerp(goal, 1.0 - exp(-follow_smoothing * delta))
		global_position = _focus

	trauma = maxf(trauma - shake_decay * real_dt, 0.0)
	_noise_t += real_dt * shake_frequency
	var s := trauma * trauma
	camera.h_offset = _noise.get_noise_2d(_noise_t, 0.0) * max_shake_offset * s * 1.6
	camera.v_offset = _noise.get_noise_2d(0.0, _noise_t + 100.0) * max_shake_offset * s * 1.6
	camera.rotation.z = deg_to_rad(max_shake_roll_degrees) * s * _noise.get_noise_2d(_noise_t + 50.0, 50.0) * 1.6
