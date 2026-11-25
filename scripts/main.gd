extends Node3D
## Root of the game scene: resets run state, handles restart, and optionally
## attaches the autoplay/screenshot helper when launched with `-- --autoplay`.

const AUTOPLAY := preload("res://scripts/debug_autoplay.gd")


func _enter_tree() -> void:
	# Runs before any child's _ready, so children can register into a clean Game.
	Game.reset_run()
	if has_node("Mission"):
		_setup_dive()


## Dive scenes: make sure a dive is running before the Level builds its floor.
## Dev flags (first load only): --classic (small test level), --strike (a strike operation), --seed=N,
## --floor=N (1-based), --depth=N, --skip-to=uplink (jumps to the bottom floor),
## --dest=deepworks|starship|foundry.
func _setup_dive() -> void:
	var first := not Engine.has_meta("dive_flags_done")
	Engine.set_meta("dive_flags_done", true)
	var seed_ := -1
	var floor_ := -1
	for arg in OS.get_cmdline_user_args():
		if arg == "--classic":
			Profile.dive_layout = "classic"
		elif arg == "--strike":
			Profile.dive_layout = "strike"
		elif arg.begins_with("--dest="):
			Profile.dive_destination = arg.get_slice("=", 1)
		elif arg.begins_with("--depth="):
			Profile.data.max_depth = Profile.MAX_DEPTH
			Profile.dive_depth = clampi(arg.get_slice("=", 1).to_int(), 1, Profile.MAX_DEPTH)
		elif first and arg.begins_with("--seed="):
			seed_ = arg.get_slice("=", 1).to_int()
		elif first and arg.begins_with("--floor="):
			floor_ = arg.get_slice("=", 1).to_int() - 1
		elif first and arg == "--skip-to=uplink":
			floor_ = 99
	if not Profile.dive_active:
		Profile.start_dive(maxi(Profile.dive_depth, 1))
		if seed_ >= 0:
			Profile.dive_seed = seed_
		if floor_ >= 0:
			Profile.dive_floor = clampi(floor_, 0, Profile.dive_floors - 1)


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autoplay") and has_node("Mission"):
			var bot := Node.new()
			bot.name = "DebugAutoplay"
			bot.set_script(AUTOPLAY)
			add_child(bot)
			break


func _unhandled_input(event: InputEvent) -> void:
	if Game.is_game_over and event.is_action_pressed("restart"):
		Game.restart()
	elif Game.is_game_over and event.is_action_pressed("interact"):
		Game.go_to_scene("res://scenes/hub.tscn")
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_F11:
		var mode := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
