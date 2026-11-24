class_name Minimap
extends Control
## Whole-dive map (bottom-right, like the sciveg reference): deck shapes,
## machinery and walls, objective, lift, nests, hunting bugs and the player.

@export var floor_color := Color(0.75, 0.8, 0.84, 0.55)
@export var solid_color := Color(0.12, 0.14, 0.16, 0.95)
@export var player_color := Color("19f4ff")
@export var enemy_color := Color("ff3b4b")
@export var objective_color := Color("ffd23d")
@export var nest_color := Color("8dff2e")
@export var lift_color := Color("ffae45")
@export var padding := 8.0

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var lvl := Game.level
	if lvl == null or lvl.regions.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.05, 0.06, 0.55))
	var b: Rect2 = lvl.bounds
	var avail := size - Vector2(padding, padding) * 2.0
	var s := minf(avail.x / b.size.x, avail.y / b.size.y)
	var offset := Vector2(padding, padding) + (avail - b.size * s) * 0.5 - b.position * s

	for reg in lvl.regions:
		var r: Rect2 = reg.rect
		draw_rect(Rect2(r.position * s + offset, r.size * s), floor_color)
	for r in lvl.minimap_solids:
		draw_rect(Rect2(r.position * s + offset, r.size * s), solid_color)

	var to_map := func(p: Vector3) -> Vector2: return Vector2(p.x, p.z) * s + offset

	draw_rect(Rect2(to_map.call(lvl.lift_position) - Vector2(4, 4), Vector2(8, 8)), lift_color)
	for n in lvl.nests:
		if is_instance_valid(n) and n.is_alive():
			draw_circle(to_map.call(n.global_position), 3.0, nest_color)
	if Game.spawner:
		for e in Game.spawner.active:
			if e.state == Enemy.State.CHASE or e.tier == Enemy.Tier.PURPLE:
				var c: Color = Enemy.TIER_COLORS[e.tier] if e.tier > 0 else enemy_color
				draw_circle(to_map.call(e.global_position), 1.6 if e.tier == 0 else 3.0, c)
	if Game.mission:
		var obj := Game.mission.objective_position()
		if obj != Vector3.INF:
			var o: Vector2 = to_map.call(obj)
			var r := 5.0 + 1.5 * sin(_t * 5.0)
			draw_colored_polygon(PackedVector2Array([o + Vector2(0, -r), o + Vector2(r, 0), o + Vector2(0, r), o + Vector2(-r, 0)]), objective_color)
	var p := Game.player
	if p:
		var pp: Vector2 = to_map.call(p.global_position)
		draw_circle(pp, 3.5, player_color)
		draw_line(pp, pp + Vector2(p.aim_dir.x, p.aim_dir.z) * 9.0, player_color, 1.5, true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.15), false, 1.0)
