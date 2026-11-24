extends Node3D
## Root of the game scene: resets run state, handles restart, and optionally
## attaches the autoplay/screenshot helper when launched with `-- --autoplay`.

const AUTOPLAY := preload("res://scripts/debug_autoplay.gd")


func _enter_tree() -> void:
	# Runs before any child's _ready, so children can register into a clean Game.
	Game.reset_run()


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
