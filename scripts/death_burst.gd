class_name DeathBurst
extends Node3D
## "Neon swarm overkill" kill explosion: magenta/lime/yellow sparks + chunks,
## a hot white flash and an expanding shockwave ring on the deck. Pooled by FX.

@export var duration := 0.7
@export var flash_time := 0.12
@export var flash_size := 1.9
@export var ring_time := 0.32
@export var ring_size := 3.4

@onready var sparks: CPUParticles3D = $Sparks
@onready var chunks: CPUParticles3D = $Chunks
@onready var flash: MeshInstance3D = $Flash
@onready var ring: MeshInstance3D = $Ring

var _t := 0.0
var _size := 1.0
var _flash_mat: ShaderMaterial
var _ring_mat: ShaderMaterial


func _ready() -> void:
	_flash_mat = flash.material_override
	_ring_mat = ring.material_override
	visible = false
	set_process(false)


func play(pos: Vector3, direction: Vector3, size := 1.0) -> void:
	global_position = pos
	_size = size
	_t = 0.0
	visible = true
	# Bias the spray along the bullet direction for a directional "splat".
	var dir := Vector3(direction.x, 0.6, direction.z)
	sparks.direction = dir.normalized() if direction.length_squared() > 0.01 else Vector3.UP
	sparks.scale_amount_min = 0.6 * size
	sparks.scale_amount_max = 1.5 * size
	sparks.restart()
	chunks.restart()
	_ring_mat.set_shader_parameter("tint", Palette.NEON_BURST.pick_random())
	ring.position = Vector3(0.0, -0.3, 0.0)
	_update_visuals()
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	_update_visuals()
	if _t >= duration:
		visible = false
		set_process(false)


func _update_visuals() -> void:
	var ft := clampf(_t / flash_time, 0.0, 1.0)
	flash.visible = ft < 1.0
	flash.scale = Vector3.ONE * lerpf(0.4, flash_size, 1.0 - pow(1.0 - ft, 3.0)) * _size
	_flash_mat.set_shader_parameter("fade", 1.0 - ft)
	var rt := clampf(_t / ring_time, 0.0, 1.0)
	ring.visible = rt < 1.0
	ring.scale = Vector3.ONE * lerpf(0.2, ring_size, 1.0 - pow(1.0 - rt, 2.5)) * _size
	_ring_mat.set_shader_parameter("fade", 1.0 - rt)
