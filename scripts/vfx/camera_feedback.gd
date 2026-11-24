class_name CameraFeedback
extends Resource
## How hard an event hits the camera and the clock. Shared by any effect.
## Intensity falls off with distance from the player: full inside `near`,
## nothing past `far`, smooth in between.

## Trauma added to the camera shake (0..1; shake grows with trauma squared).
@export_range(0.0, 1.0) var shake := 0.0
## Directional camera shove in metres-ish (CameraRig.kick).
@export var kick := 0.0
## true: shove away from the event toward the player (blasts). false: along the
## event's direction (recoil).
@export var kick_from_source := true
## Global hitstop in real seconds (0 = none) and how slow time runs during it.
@export var hitstop := 0.0
@export_range(0.0, 1.0) var hitstop_scale := 0.05
## Hitstop only when the attenuated strength is at least this (near the player).
@export_range(0.0, 1.0) var hitstop_min_strength := 0.5
@export var near := 4.0
@export var far := 26.0


## 1 inside near, 0 beyond far.
func strength_at(distance: float) -> float:
	if far <= near:
		return 1.0
	var t := clampf((distance - near) / (far - near), 0.0, 1.0)
	return 1.0 - t * t * (3.0 - 2.0 * t)


## Apply to the camera and clock for an event at `pos` (with `dir` for kicks).
func apply(pos: Vector3, dir := Vector3.ZERO, intensity := 1.0) -> void:
	# Autoload looked up at runtime so tool scripts that load this resource compile.
	var game: Node = Engine.get_main_loop().root.get_node_or_null("/root/Game")
	if game == null:
		return
	var listener := pos
	if game.player and is_instance_valid(game.player):
		listener = game.player.global_position
	var flat := Vector3(listener.x - pos.x, 0.0, listener.z - pos.z)
	var s := strength_at(flat.length()) * intensity
	if s <= 0.0:
		return
	if shake > 0.0:
		game.shake(shake * s)
	if kick > 0.0 and game.camera_rig:
		var d := flat if kick_from_source else dir
		if d.length_squared() < 0.0001:
			d = Vector3(randf() - 0.5, 0.0, randf() - 0.5)
		game.camera_rig.kick(d, kick * s)
	if hitstop > 0.0 and s >= hitstop_min_strength:
		game.hitstop(hitstop * s, hitstop_scale)
