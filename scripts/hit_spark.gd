class_name HitSpark
extends CPUParticles3D
## Small streak spray for bullet impacts. Pooled by FX.


func _ready() -> void:
	emitting = false


func play(pos: Vector3, tint: Color, normal: Vector3) -> void:
	global_position = pos
	color = tint
	direction = normal.normalized() if normal.length_squared() > 0.001 else Vector3.UP
	restart()
