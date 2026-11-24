extends SceneTree
## Headless sanity test for items, stats and the profile save.
##   godot --headless --path . --script res://tests/test_loot.gd

func _initialize() -> void:
	var fails := 0
	var counts := [0, 0, 0, 0]
	for i in 2000:
		var rarity := Loot.roll_rarity([40.0, 35.0, 20.0, 5.0])
		counts[rarity] += 1
		var item := Loot.roll_item(randi_range(1, 20), rarity)
		var lines := Loot.describe(item, {})
		if item.name == "" or lines.size() < 2:
			fails += 1
			print("BAD ITEM ", item)
		if rarity == Loot.Rarity.LEGENDARY and item.legendary == "":
			fails += 1
			print("LEGENDARY WITHOUT EFFECT ", item)
	print("rarity spread ", counts)
	for arch in Loot.GUNS:
		var g := Loot.roll_item(5, Loot.Rarity.EPIC, "gun", arch)
		print("  %-9s %-22s dps %5d  %s" % [arch, g.name, roundi(Loot.gun_dps(g, {})), Loot.describe(g, {})[1][0]])
	for arch in Loot.BLADES:
		var b := Loot.roll_item(5, Loot.Rarity.RARE, "blade", arch)
		print("  %-9s %-22s dps %5d" % [arch, b.name, roundi(Loot.blade_dps(b, {}))])
	var equipped := {"gun": Loot.starter_gun(), "blade": Loot.starter_blade(),
		"chest": Loot.roll_item(10, Loot.Rarity.LEGENDARY, "chest"), "boots": Loot.roll_item(10, Loot.Rarity.EPIC, "boots")}
	var s := PlayerStats.compute(equipped, {"carapace": 2, "deadeye": 1}, 5)
	print("stats: max_health=%.1f armor=%.3f crit=%.3f move=%.3f legendaries=%s" % [s.max_health, s.armor, s.crit_chance, s.move_speed, s.legendaries])
	if s.max_health < 40.0 or s.legendaries.size() != 1:
		fails += 1
		print("STAT AGGREGATION WRONG")

	# Profile round trip (backs up and restores any real save).
	await process_frame  # autoloads join the tree after _initialize
	var prof = root.get_node("/root/Profile")
	var backup = prof.data.duplicate(true)
	prof.reset_profile()
	prof.data.salvage = 5000
	var crate: Dictionary = prof.buy_crate("armory")
	if crate.is_empty() or crate.rarity < 1:
		fails += 1
		print("CRATE FAILED ", crate)
	if not prof.equip(crate.id):
		fails += 1
		print("EQUIP FAILED")
	prof.add_xp(5000)
	var level_before: int = prof.data.level
	prof.save()
	prof.load_profile()
	if prof.data.level != level_before or prof.equipped(crate.slot).id != crate.id:
		fails += 1
		print("SAVE ROUND TRIP FAILED")
	print("profile: level %d, perk points %d, salvage %d, stash %d, equipped %s" % [prof.data.level, prof.data.perk_points, prof.data.salvage, prof.data.stash.size(), prof.data.equipped.keys()])
	prof.data = backup
	prof.save()
	print("RESULT: %s (%d failures)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)
