class_name Minimap
extends Control
## Dive map. Two modes:
## - corner (default): follows the player at a fixed zoom, with an arrow at the
##   edge pointing to the objective when it's off the map;
## - full (`full = true`, the [M] overlay): the whole floor.
## On generated floors only explored areas are drawn (you reveal the region you
## stand in and its neighbours). Shows decks, machinery and walls, the
## objective, lifts, breakers, nests, hunting bugs and the player.

@export var full := false
## Corner mode: metres shown across the map's width.
@export var view_width := 78.0
@export var floor_color := Color(0.75, 0.8, 0.84, 0.55)
@export var bridge_color := Color(0.6, 0.66, 0.7, 0.45)
@export var solid_color := Color(0.12, 0.14, 0.16, 0.95)
@export var player_color := Color("19f4ff")
@export var enemy_color := Color("ff3b4b")
@export var objective_color := Color("ffd23d")
@export var nest_color := Color("8dff2e")
@export var lift_color := Color("ffae45")
@export var breaker_color := Color("ffd23d")
@export var padding := 8.0

var _t := 0.0
var _scale := 1.0
var _offset := Vector2.ZERO
## Map rotation so "up" on the map is "up" on screen (the camera is turned 45°).
var _rot := 0.0
var _font: Font


func _ready() -> void:
	clip_contents = true
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_t += delta
	if not is_visible_in_tree():
		return
	if Game.level and Game.player and not full:
		Game.level.discover(Game.player.global_position)
	queue_redraw()


func _to_map(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z).rotated(_rot) * _scale + _offset


func _rect_poly(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		_to_map(Vector3(r.position.x, 0, r.position.y)), _to_map(Vector3(r.end.x, 0, r.position.y)),
		_to_map(Vector3(r.end.x, 0, r.end.y)), _to_map(Vector3(r.position.x, 0, r.end.y))])


func _draw() -> void:
	var lvl := Game.level
	if lvl == null or lvl.regions.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.05, 0.06, 0.82 if full else 0.55))
	var p := Game.player
	_rot = deg_to_rad(Game.camera_rig.yaw_degrees) if Game.camera_rig else 0.0
	if full or not lvl.generated or p == null:
		# Fit the (rotated) floor into the map.
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for reg in lvl.regions:
			var rr: Rect2 = reg.rect
			for c in [rr.position, Vector2(rr.end.x, rr.position.y), rr.end, Vector2(rr.position.x, rr.end.y)]:
				var q: Vector2 = (c as Vector2).rotated(_rot)
				lo = lo.min(q)
				hi = hi.max(q)
		var avail := size - Vector2(padding, padding) * 2.0
		var ext := (hi - lo).max(Vector2(1, 1))
		_scale = minf(avail.x / ext.x, avail.y / ext.y)
		_offset = Vector2(padding, padding) + (avail - ext * _scale) * 0.5 - lo * _scale
	else:
		_scale = size.x / view_width
		_offset = size * 0.5 - Vector2(p.global_position.x, p.global_position.z).rotated(_rot) * _scale
	var view := Rect2(Vector2.ZERO, size)

	for i in lvl.regions.size():
		var reg: Dictionary = lvl.regions[i]
		var poly := _rect_poly(reg.rect)
		var mb := Rect2(poly[0], Vector2.ZERO)
		for v in poly:
			mb = mb.expand(v)
		if not mb.intersects(view):
			continue
		if lvl.discovered.has(i):
			draw_colored_polygon(poly, bridge_color if reg.room == &"bridge" else floor_color)
		elif full:
			# Unexplored: just a faint shape on the full map, so you can plan a route.
			draw_colored_polygon(poly, Color(floor_color, 0.1))
	for r in lvl.minimap_solids:
		if _seen(lvl, Vector3(r.get_center().x, 0, r.get_center().y), r.size.length() * 0.5 + 1.0):
			draw_colored_polygon(_rect_poly(r), solid_color)

	_marker_square(lvl.lift_position, lift_color, 4.0, _seen(lvl, lvl.lift_position, 3.0))
	if lvl.cargo_position != Vector3.INF:
		_marker_square(lvl.cargo_position, lift_color, 4.0, _seen(lvl, lvl.cargo_position, 3.0))
	for b in lvl.breakers:
		if is_instance_valid(b) and _seen(lvl, b.global_position, 2.0):
			var c := breaker_color if b.enabled else Color("3dff9a")
			var o := _to_map(b.global_position)
			draw_rect(Rect2(o - Vector2(3, 3), Vector2(6, 6)), c, false, 2.0)
	for n in lvl.nests:
		if is_instance_valid(n) and n.is_alive() and _seen(lvl, n.global_position, 2.0):
			draw_circle(_to_map(n.global_position), 3.0, nest_color)
	if Game.spawner:
		for e in Game.spawner.active:
			if e.state == Enemy.State.CHASE or e.tier == Enemy.Tier.PURPLE:
				var ep := _to_map(e.global_position)
				if view.has_point(ep):
					var c: Color = Enemy.TIER_COLORS[e.tier] if e.tier > 0 else enemy_color
					draw_circle(ep, 1.6 if e.tier == 0 else 3.0, c)
	if Game.mission:
		var obj := Game.mission.objective_position()
		if obj != Vector3.INF:
			var o := _to_map(obj)
			if view.grow(-6.0).has_point(o):
				var r := 5.0 + 1.5 * sin(_t * 5.0)
				draw_colored_polygon(PackedVector2Array([o + Vector2(0, -r), o + Vector2(r, 0), o + Vector2(0, r), o + Vector2(-r, 0)]), objective_color)
			else:
				_edge_arrow(o)
	if p:
		var pp := _to_map(p.global_position)
		draw_circle(pp, 3.5, player_color)
		draw_line(pp, pp + Vector2(p.aim_dir.x, p.aim_dir.z).rotated(_rot) * 9.0, player_color, 1.5, true)
	if full and _font:
		var title := "%s   ·   [M] CLOSE" % lvl.floor_name.to_upper()
		if lvl.generated:
			title = "FLOOR %d / %d   ·   %s" % [Profile.dive_floor + 1, Profile.dive_floors, title]
		draw_string(_font, Vector2(14, 26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.85))
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.15), false, 1.0)


## Explored (or not a generated floor)?
func _seen(lvl: Level, pos: Vector3, slack: float) -> bool:
	if not lvl.generated:
		return true
	var r := lvl.region_of(pos)
	if r >= 0:
		return lvl.discovered.has(r)
	# Objects just off a region edge (e.g. inside machinery): check around them.
	for d in [Vector3(slack, 0, 0), Vector3(-slack, 0, 0), Vector3(0, 0, slack), Vector3(0, 0, -slack)]:
		var r2 := lvl.region_of(pos + d)
		if r2 >= 0 and lvl.discovered.has(r2):
			return true
	return false


func _marker_square(pos: Vector3, c: Color, half: float, seen: bool) -> void:
	if not seen:
		return
	var o := _to_map(pos)
	draw_rect(Rect2(o - Vector2(half, half), Vector2(half, half) * 2.0), c)


## Triangle on the map border pointing toward an off-map objective.
func _edge_arrow(target: Vector2) -> void:
	var c := size * 0.5
	var d := target - c
	if d.length() < 0.01:
		return
	d = d.normalized()
	var half := size * 0.5 - Vector2(9, 9)
	var k := minf(half.x / maxf(absf(d.x), 0.001), half.y / maxf(absf(d.y), 0.001))
	var tip := c + d * k
	var side := Vector2(-d.y, d.x)
	var pulse := 1.0 + 0.15 * sin(_t * 6.0)
	draw_colored_polygon(PackedVector2Array([tip + d * 6.0 * pulse, tip - d * 5.0 + side * 6.0, tip - d * 5.0 - side * 6.0]), objective_color)
