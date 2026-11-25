extends Node
## Autoload "Graphics": press V to cycle HIGH -> MEDIUM -> LOW quality, for
## low-end machines (Chromebooks, integrated GPUs). The choice is saved to
## user://settings.cfg and re-applied on every scene change.
##
##   HIGH    everything (volumetric fog, SSAO, glow, shadows, all lamp lights)
##   MEDIUM  no volumetric fog / SSAO, 85% render resolution
##   LOW     also no glow, no shadows, no lamp/point lights, cheap floor shader,
##           67% render resolution, brighter ambient light to compensate, and
##           a lower cap on how many bugs can be alive at once
## On the Compatibility (OpenGL) renderer the default is LOW.

enum Quality { HIGH, MEDIUM, LOW }
const NAMES := ["HIGH", "MEDIUM", "LOW"]
const PATH := "user://settings.cfg"
const RENDER_SCALE := [1.0, 0.85, 0.67]

var quality := Quality.HIGH

var _scene: Node
## The level the scene is actually running at. On HIGH, a newly loaded scene starts at MEDIUM
## and steps up after HIGH_WARMUP seconds: turning volumetric fog, SSAO and lamp shadows on
## while a dive is still loading (level, hunter, effect pools) broke rendering on a Windows GPU
## until restart, while switching to HIGH once in the dive worked fine.
var _active := Quality.HIGH
var _warm_t := 0.0
const HIGH_WARMUP := 1.5
var _layer: CanvasLayer
var _fps: Label
var _toast: Label
var _toast_t := 0.0
var _fps_t := 0.0
var _floor_high: Shader = preload("res://scripts/shaders/floor.gdshader")
var _floor_low: Shader = preload("res://scripts/shaders/floor_low.gdshader")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		quality = clampi(int(cfg.get_value("graphics", "quality", 0)), 0, 2)
	elif RenderingServer.get_current_rendering_method() == "gl_compatibility":
		quality = Quality.LOW
	_build_overlay()
	get_tree().node_added.connect(_on_node_added)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("graphics_quality"):
		set_quality((quality + 1) % 3)
		get_viewport().set_input_as_handled()


func set_quality(q: int) -> void:
	quality = q
	_warm_t = 0.0  # a manual change applies at once
	var cfg := ConfigFile.new()
	cfg.set_value("graphics", "quality", quality)
	cfg.save(PATH)
	apply()
	_show_toast("GRAPHICS: %s   ·   [V] to change" % NAMES[quality])


func is_low() -> bool:
	return quality == Quality.LOW


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _scene and scene != null and scene.is_node_ready():
		_scene = scene
		_warm_t = HIGH_WARMUP if quality == Quality.HIGH else 0.0
		apply()
	if _warm_t > 0.0:
		_warm_t -= delta
		if _warm_t <= 0.0:
			apply()
	_fps_t -= delta
	if _fps_t <= 0.0:
		_fps_t = 0.5
		_fps.text = "%s  ·  %d FPS   [V]" % [NAMES[quality], Engine.get_frames_per_second()]
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t, 0.0, 1.0)


## Push the current quality onto the running scene.
func apply() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	_active = Quality.MEDIUM if (quality == Quality.HIGH and _warm_t > 0.0) else quality
	var q := _active
	var vp := get_viewport()
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = RENDER_SCALE[q]
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if q != Quality.LOW else Viewport.SCREEN_SPACE_AA_DISABLED

	var env := scene.find_child("WorldEnvironment", true, false)
	if env and "volumetric_enabled" in env:
		if not env.has_meta("gfx_ambient"):
			env.set_meta("gfx_ambient", env.ambient_energy)
		env.volumetric_enabled = q == Quality.HIGH
		env.ssao_enabled = q == Quality.HIGH
		env.glow_enabled = q != Quality.LOW
		env.ambient_energy = float(env.get_meta("gfx_ambient")) * (2.6 if q == Quality.LOW else 1.0)

	for n in scene.find_children("*", "DirectionalLight3D", true, false):
		var d := n as DirectionalLight3D
		if not d.has_meta("gfx_energy"):
			d.set_meta("gfx_energy", d.light_energy)
		d.shadow_enabled = q != Quality.LOW
		d.light_energy = float(d.get_meta("gfx_energy")) * (1.35 if q == Quality.LOW else 1.0)
	for n in scene.find_children("*", "OmniLight3D", true, false):
		_apply_light(n, q)
	for n in scene.find_children("*", "FogVolume", true, false):
		(n as FogVolume).visible = q == Quality.HIGH

	for lvl in [scene.get_node_or_null("Level"), scene.get_node_or_null("HubLevel")]:
		if lvl and lvl.has_method("set_low_quality"):
			lvl.set_low_quality(q == Quality.LOW)
		if lvl and lvl.has_method("floor_materials"):
			for m in lvl.floor_materials():
				m.shader = _floor_low if q == Quality.LOW else _floor_high
		elif lvl and lvl.has_method("floor_material"):
			var m: ShaderMaterial = lvl.floor_material()
			if m:
				m.shader = _floor_low if q == Quality.LOW else _floor_high

	# CPU side: fewer bugs alive at once on LOW.
	if Game.spawner:
		if not Game.spawner.has_meta("gfx_cap"):
			Game.spawner.set_meta("gfx_cap", Game.spawner.max_alive)
		Game.spawner.max_alive = mini(int(Game.spawner.get_meta("gfx_cap")), 110) if q == Quality.LOW else int(Game.spawner.get_meta("gfx_cap"))
	if Game.director:
		if not Game.director.has_meta("gfx_cap"):
			Game.director.set_meta("gfx_cap", Game.director.max_alive_alarm)
		Game.director.max_alive_alarm = mini(int(Game.director.get_meta("gfx_cap")), 95) if q == Quality.LOW else int(Game.director.get_meta("gfx_cap"))


## Point lights are the most expensive thing on weak GPUs (especially on the
## Compatibility renderer, which draws objects once per light). LOW hides them.
func _apply_light(l: OmniLight3D, q: int) -> void:
	# Lamp posts throw long shadows on HIGH only (shadowed lights are costly).
	if l.has_meta("lamp"):
		l.shadow_enabled = q == Quality.HIGH
		l.distance_fade_shadow = 26.0
		l.shadow_bias = 0.08
	if q == Quality.LOW:
		if l.visible:
			l.set_meta("gfx_hidden", true)
			l.visible = false
	elif l.has_meta("gfx_hidden"):
		l.remove_meta("gfx_hidden")
		l.visible = true


func _on_node_added(n: Node) -> void:
	# Nodes of a scene that is still loading get the warm-up level, not the old scene's.
	var q := _active
	if quality == Quality.HIGH and (_warm_t > 0.0 or _scene == null or not is_instance_valid(_scene) or not _scene.is_ancestor_of(n)):
		q = Quality.MEDIUM
	if n is OmniLight3D and (q == Quality.LOW or n.has_meta("lamp")):
		_apply_light.call_deferred(n, q)
	elif q != Quality.HIGH and n is FogVolume:
		(n as FogVolume).set_deferred("visible", false)


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_fps = Label.new()
	_fps.add_theme_font_size_override("font_size", 13)
	_fps.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_fps.add_theme_constant_override("outline_size", 4)
	_fps.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_fps.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_fps.offset_left = -260
	_fps.offset_top = -26
	_fps.offset_right = -12
	_fps.offset_bottom = -6
	_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fps)
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.add_theme_color_override("font_color", Color("19f4ff"))
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -400
	_toast.offset_right = 400
	_toast.offset_top = 160
	_toast.offset_bottom = 200
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	_layer.add_child(_toast)


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast_t = 2.0
