class_name ShieldBug
extends Enemy
## Armoured bruiser with a frontal shield plate. Bullets and blade strikes from
## the front are blocked; it turns slowly and can't strafe, so roll past it and
## hit it from behind (back hits do bonus damage). Explosions and lasers ignore
## the shield.

@export_group("Shield")
@export var shield_arc_degrees := 140.0
@export var back_damage_mult := 1.5


func _modify_damage(amount: float, direction: Vector3, kind: StringName) -> float:
	if not kind in [&"bullet", &"crit", &"slash", &"slash_crit"]:
		return amount
	var incoming := -Vector3(direction.x, 0.0, direction.z)
	if incoming.length_squared() < 0.0001:
		return amount
	var dot := get_facing().dot(incoming.normalized())
	if dot > cos(deg_to_rad(shield_arc_degrees * 0.5)):
		return 0.0
	if dot < -0.3:
		return amount * back_damage_mult
	return amount


## Always turn (slowly) toward the player while hunting.
func _facing_target() -> Vector3:
	if state == State.CHASE and Game.player:
		var to := Game.player.global_position - global_position
		to.y = 0.0
		return to
	return Vector3.ZERO


## Mostly moves where the shield points; sideways movement is slow.
func _speed_factor(dir: Vector3) -> float:
	if dir == Vector3.ZERO:
		return 1.0
	if _detour_t > 0.0:
		return 0.8  # working round an obstacle: allowed to shuffle sideways
	return clampf(get_facing().dot(dir), 0.3, 1.0)
