extends SceneTree
## End-to-end hub test: stations, purchases, equipping, perks, every weapon
## archetype on the test range, then deploying into a dive.
##   godot --headless --path . --script res://tests/test_hub.gd
## Add `-- --shots=DIR` (with a rendering driver) to save screenshots of each panel.

const RIFLE := 0  # Player.Weapon (kept literal: tests compile before autoloads)
const BLADE := 1
var fails := 0
var shots := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			shots = a.get_slice("=", 1)
			DirAccess.make_dir_recursive_absolute(shots)
	await process_frame
	var prof = root.get_node("/root/Profile")
	var game = root.get_node("/root/Game")
	var backup: Dictionary = prof.data.duplicate(true)
	prof.reset_profile()
	prof.data.salvage = 20000
	prof.data.max_depth = 3
	prof.add_xp(4000)
	prof.save()

	change_scene_to_file("res://scenes/hub.tscn")
	for i in 20:
		await process_frame
	var hub_ui = game.hud
	_check(hub_ui != null and hub_ui.has_method("open"), "hub UI registered")
	_check(game.player != null, "player spawned in hub")
	await _shot("hub_overview")

	# Fabricator: buy one of each crate.
	hub_ui.open("fabricator")
	for id in ["field", "armory", "elite"]:
		hub_ui._on_buy(id)
	_check(prof.data.stash.size() == 3, "3 crates bought (stash %d)" % prof.data.stash.size())
	await _frames(5)
	await _shot("fabricator")

	# Armory: select a stash item, equip it, scrap another.
	hub_ui.open("armory")
	var item: Dictionary = prof.data.stash[0]
	hub_ui._select("stash", item, item.slot)
	await _frames(5)
	await _shot("armory_compare")
	hub_ui._on_equip(item)
	_check(prof.equipped(item.slot).id == item.id, "equipped %s" % item.name)
	var before: int = prof.data.salvage
	if prof.data.stash.size() > 0:
		var scrap_id: String = prof.data.stash[0].id
		hub_ui._on_scrap(scrap_id)
		_check(prof.data.salvage > before, "scrap gave salvage")

	# Augments: spend points.
	hub_ui.open("augments")
	var pts: int = prof.data.perk_points
	hub_ui._on_perk("deadeye")
	hub_ui._on_perk("carapace")
	_check(prof.data.perk_points == pts - 2, "perk points spent (%d -> %d)" % [pts, prof.data.perk_points])
	await _frames(5)
	await _shot("augments")
	hub_ui.close()

	# Test range: every gun archetype and both blades vs a dummy.
	var player = game.player
	var dummy = null
	for n in root.find_children("*", "StaticBody3D", true, false):
		if n.has_method("take_hit") and "dps_window" in n:
			dummy = n
			break
	_check(dummy != null, "training dummy present")
	player.autopilot = true
	if shots == "":
		for arch in Loot.GUNS:
			await _test_weapon(prof, player, dummy, Loot.roll_item(6, Loot.Rarity.EPIC, "gun", arch), RIFLE, 150)
		for arch in Loot.BLADES:
			await _test_weapon(prof, player, dummy, Loot.roll_item(6, Loot.Rarity.EPIC, "blade", arch), BLADE, 150)
	else:
		await _test_weapon(prof, player, dummy, Loot.roll_item(6, Loot.Rarity.LEGENDARY, "gun", "launcher"), RIFLE, 24)
		await _shot("range")
	player.auto_fire = false

	# Contracts: deploy to depth 2.
	hub_ui.open("contracts")
	hub_ui._on_depth(2)
	await _frames(5)
	await _shot("contracts")
	hub_ui.deploy(2)
	for i in 30:
		await process_frame
	_check(current_scene != null and current_scene.has_node("Mission"), "deployed into the dive scene")
	_check(prof.dive_depth == 2, "dive depth 2")

	prof.data = backup
	prof.save()
	print("RESULT: %s (%d failures)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)


func _test_weapon(prof, player, dummy, item: Dictionary, weapon: int, frames: int) -> void:
	prof.data.stash.append(item)
	prof.equip(item.id)
	player.global_position = dummy.global_position + Vector3(0, 0, -2.0 if weapon == BLADE else -6.0)
	player.auto_weapon = weapon
	player.auto_aim = dummy.global_position
	player.auto_fire = true
	dummy._hits.clear()
	player._fire_cd = 0.0
	player._blade_cd = 0.0
	await _frames(10)  # let the aim settle on the dummy
	dummy._hits.clear()
	if frames >= 100:
		await create_timer(2.0).timeout  # real game time, not frame count
	else:
		await _frames(frames)
	var total := 0.0
	for h in dummy._hits:
		total += float(h[1])
	var dps: float = total / float(dummy.dps_window)
	print("  %-8s %-24s dummy DPS %4d   (sheet DPS %d)" % [item.archetype, item.name, roundi(dps),
		roundi(Loot.gun_dps(item, prof.stats()) if weapon == RIFLE else Loot.blade_dps(item, prof.stats()))])
	_check(dps > 0.0, "%s hits the dummy" % item.archetype)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	if shots == "":
		return
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [shots, name])
	print("  shot ", name)


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)
