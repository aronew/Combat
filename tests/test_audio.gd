extends SceneTree
## Sound bank sanity: every sound the code asks for has takes on disk, every
## take on disk is used somewhere, and loops really loop.
##   godot --headless --path . --script res://tests/test_audio.gd

var fails := 0


func _initialize() -> void:
	await process_frame
	var audio = root.get_node("/root/Audio")
	# Every &"name" passed to Audio.* in scripts/
	var used := {}
	var re := RegEx.create_from_string("Audio\\.(?:play|play_at|attach_loop|set_loop)\\(\\s*&\"([a-z_0-9]+)\"")
	var re_any := RegEx.create_from_string("&\"([a-z_]+(?:_shot|_swing|loot_drop_[a-z]+))\"")
	for f in _scripts("res://scripts"):
		var src := FileAccess.get_file_as_string(f)
		for m in re.search_all(src):
			used[m.get_string(1)] = f
		for m in re_any.search_all(src):
			used[m.get_string(1)] = f
	for k in audio.MIX:
		used[String(k)] = "MIX"
	for bed in audio.BEDS.values():
		for layer in bed:
			used[String(layer[0])] = "BEDS"
	for s in used:
		if not audio.has_sound(StringName(s)):
			_fail("'%s' (%s) has no sound files" % [s, used[s]])
	for s in audio._banks:
		if not used.has(String(s)):
			_fail("'%s' is never played" % s)
	for s in [&"alarm", &"uplink_loop", &"low_health", &"laser_hum", &"bug_feeding", &"amb_abyss", &"amb_foundry"]:
		for st in audio._banks.get(s, []):
			if not st.loop:
				_fail("'%s' does not loop" % s)
	print("%d sounds, %d takes" % [audio._banks.size(), audio._banks.values().reduce(func(a, b): return a + b.size(), 0)])
	print("RESULT: %s (%d failures)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)


func _scripts(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		out.append_array(_scripts(dir + "/" + sub))
	return out


func _fail(msg: String) -> void:
	fails += 1
	print("FAIL ", msg)
