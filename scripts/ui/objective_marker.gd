class_name ObjectiveMarker
extends Control
## Diamond + distance over the current objective; clamps to the screen edge
## with an arrow when the objective is off-screen.

@export var color := Color("ffd23d")
@export var edge_margin := 56.0

var _t := 0.0
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if Game.mission == null or Game.camera_rig == null or Game.player == null or Game.is_game_over:
		return
	var target := Game.mission.objective_position()
	if target == Vector3.INF:
		return
	var cam := Game.camera_rig.camera
	var world := target + Vector3.UP * 2.2
	var vp := get_viewport_rect().size
	var screen := cam.unproject_position(world)
	var behind := cam.is_position_behind(world)
	var inner := Rect2(Vector2(edge_margin, edge_margin), vp - Vector2(edge_margin, edge_margin) * 2.0)
	var dist := Vector2(target.x - Game.player.global_position.x, target.z - Game.player.global_position.z).length()
	var label := "%dm" % roundi(dist)
	if not behind and inner.has_point(screen):
		var bob := sin(_t * 4.0) * 4.0
		var c := screen + Vector2(0, bob)
		var r := 11.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), Color(color, 0.9))
		draw_polyline(PackedVector2Array([c + Vector2(0, -r - 4), c + Vector2(r + 4, 0), c + Vector2(0, r + 4), c + Vector2(-r - 4, 0), c + Vector2(0, -r - 4)]), color, 1.5, true)
		draw_string(_font, c + Vector2(-20, r + 22), label, HORIZONTAL_ALIGNMENT_CENTER, 40, 15, Color.WHITE)
		return
	# Off-screen: arrow on the edge pointing toward the objective.
	var center := vp * 0.5
	var dir := (screen - center).normalized()
	if behind:
		dir = -dir
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	var t := INF
	if absf(dir.x) > 0.001:
		t = minf(t, ((inner.end.x if dir.x > 0 else inner.position.x) - center.x) / dir.x)
	if absf(dir.y) > 0.001:
		t = minf(t, ((inner.end.y if dir.y > 0 else inner.position.y) - center.y) / dir.y)
	var p := center + dir * t
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([p + dir * 16.0, p - dir * 8.0 + side * 11.0, p - dir * 8.0 - side * 11.0]), color)
	draw_string(_font, p - dir * 30.0 + Vector2(-20, 5), label, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color.WHITE)
