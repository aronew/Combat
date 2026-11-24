class_name HUD
extends CanvasLayer
## Screen-space HUD laid out like the sciveg reference: HP numbers over a
## segmented cyan bar (bottom-left), wave ring (top-centre), dash box with key
## label (top-right), kill/combo counter (top-left), big WAVE banner, GAME OVER.

@export var banner_hold := 1.3
@export var hide_os_cursor := true
@export var number_font_names := PackedStringArray(["Rajdhani", "Exo 2", "Barlow", "Inter", "Arial", "sans-serif"])
@export var title_font_names := PackedStringArray(["Orbitron", "Exo 2", "Rajdhani", "Inter Display", "Arial Black", "sans-serif"])

@onready var vignette: ColorRect = $Vignette
@onready var crosshair: Crosshair = $Crosshair
@onready var health_value: Label = $Health/Numbers/Value
@onready var health_max: Label = $Health/Numbers/Max
@onready var health_bar: SegmentedBar = $Health/Bar
@onready var wave_ring: WaveRing = $WaveRing
@onready var wave_count: Label = $WaveRing/Count
@onready var wave_label: Label = $WaveLabel
@onready var dash_box: AbilityBox = $Dash/Box
@onready var dash_cd: Label = $Dash/Box/Cooldown
@onready var dash_key: Label = $Dash/Key
@onready var kills_label: Label = $Kills
@onready var combo_label: Label = $Combo
@onready var banner: Control = $Banner
@onready var banner_title: Label = $Banner/Title
@onready var banner_sub: Label = $Banner/Sub
@onready var game_over_panel: Control = $GameOver
@onready var go_title: Label = $GameOver/Box/Title
@onready var go_wave: Label = $GameOver/Box/Wave
@onready var go_kills: Label = $GameOver/Box/Kills
@onready var go_hint: Label = $GameOver/Box/Hint

var _hurt := 0.0
var _low_pulse := 0.0
var _health_ratio := 1.0
var _banner_tween: Tween
var _combo_tween: Tween


func _ready() -> void:
	Game.hud = self
	_style()
	banner.visible = false
	game_over_panel.visible = false
	combo_label.modulate.a = 0.0
	Game.player_health_changed.connect(_on_health)
	Game.player_damaged.connect(_on_damaged)
	Game.wave_announced.connect(_on_wave_announced)
	Game.wave_progress.connect(_on_wave_progress)
	Game.wave_cleared.connect(_on_wave_cleared)
	Game.kills_changed.connect(_on_kills)
	Game.game_over.connect(_on_game_over)
	if hide_os_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	wave_count.text = "-"
	wave_label.text = "GET READY"
	kills_label.text = "KILLS  0"
	# The player is ready before the HUD, so pull its initial health once.
	if Game.player:
		_on_health(Game.player.health, Game.player.max_health)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	var p := Game.player
	if p:
		dash_box.ratio = p.get_dash_ready_ratio()
		var left := p.get_dash_cooldown_left()
		dash_cd.text = "%.1f" % left if left > 0.05 else ""
	_hurt = maxf(_hurt - delta * 2.2, 0.0)
	_low_pulse += delta
	var low := 0.0
	if _health_ratio <= 0.3 and not Game.is_game_over:
		low = 0.25 + 0.15 * sin(_low_pulse * 6.0)
	(vignette.material as ShaderMaterial).set_shader_parameter("intensity", clampf(maxf(_hurt, low), 0.0, 1.0))


# --------------------------------------------------------------------------
# Signal handlers
# --------------------------------------------------------------------------

func _on_health(current: float, maximum: float) -> void:
	_health_ratio = current / maximum if maximum > 0.0 else 0.0
	health_value.text = str(ceili(current))
	health_max.text = " / %d" % roundi(maximum)
	health_bar.set_value(_health_ratio)


func _on_damaged(_amount: float) -> void:
	_hurt = 0.85
	var t := create_tween().set_ignore_time_scale(true)
	health_value.pivot_offset = health_value.size * Vector2(0.0, 1.0)
	health_value.scale = Vector2(1.35, 1.35)
	health_value.add_theme_color_override("font_color", Palette.HUD_DANGER)
	t.tween_property(health_value, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	t.tween_callback(func(): health_value.add_theme_color_override("font_color", Palette.HUD_WHITE))


func _on_wave_announced(wave: int, total: int) -> void:
	wave_label.text = "WAVE %d" % wave
	wave_count.text = str(total)
	wave_ring.ratio = 1.0
	banner_title.text = "WAVE %d" % wave
	banner_sub.text = "%d SWARMERS INBOUND" % total
	_show_banner()


func _on_wave_progress(remaining: int, total: int) -> void:
	wave_count.text = str(remaining)
	wave_ring.ratio = float(remaining) / total if total > 0 else 0.0


func _on_wave_cleared(wave: int) -> void:
	wave_label.text = "WAVE %d CLEAR" % wave


func _on_kills(kills: int, combo: int) -> void:
	kills_label.text = "KILLS  %d" % kills
	if combo >= 3:
		combo_label.text = "COMBO x%d" % combo
		combo_label.pivot_offset = combo_label.size * 0.5
		if _combo_tween:
			_combo_tween.kill()
		_combo_tween = create_tween().set_ignore_time_scale(true)
		combo_label.modulate = Color(1, 1, 1, 1)
		combo_label.scale = Vector2(1.3, 1.3)
		_combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif combo == 0 and combo_label.modulate.a > 0.0:
		if _combo_tween:
			_combo_tween.kill()
		_combo_tween = create_tween()
		_combo_tween.tween_property(combo_label, "modulate:a", 0.0, 0.4)


func _on_game_over(wave: int, kills: int) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	crosshair.visible = false
	go_wave.text = "REACHED WAVE %d" % wave
	go_kills.text = "%d KILLS   ·   BEST COMBO x%d" % [kills, Game.best_combo]
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	go_title.pivot_offset = go_title.size * 0.5
	go_title.scale = Vector2(1.6, 1.6)
	var t := create_tween().set_ignore_time_scale(true).set_parallel(true)
	t.tween_property(game_over_panel, "modulate:a", 1.0, 0.5)
	t.tween_property(go_title, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var blink := create_tween().set_ignore_time_scale(true).set_loops()
	blink.tween_property(go_hint, "modulate:a", 0.35, 0.6)
	blink.tween_property(go_hint, "modulate:a", 1.0, 0.6)


func _show_banner() -> void:
	if _banner_tween:
		_banner_tween.kill()
	banner.visible = true
	banner.modulate.a = 0.0
	banner_title.pivot_offset = banner_title.size * 0.5
	banner_title.scale = Vector2(2.2, 2.2)
	_banner_tween = create_tween().set_ignore_time_scale(true)
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(banner, "modulate:a", 1.0, 0.18)
	_banner_tween.tween_property(banner_title, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(banner_hold)
	_banner_tween.chain().tween_property(banner, "modulate:a", 0.0, 0.35)
	_banner_tween.chain().tween_callback(func(): banner.visible = false)


# --------------------------------------------------------------------------
# Styling (fonts/colours set in code so the .tscn stays simple)
# --------------------------------------------------------------------------

func _font(names: PackedStringArray, weight: int, italic: bool) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = names
	f.font_weight = weight
	f.font_italic = italic
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	return f


func _label(l: Label, font: Font, size: int, color: Color, outline := 0) -> void:
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.9))


func _style() -> void:
	var num_italic := _font(number_font_names, 500, true)
	var num_bold := _font(number_font_names, 700, true)
	var title := _font(title_font_names, 900, true)
	var plain := _font(number_font_names, 600, false)
	_label(health_value, num_italic, 34, Palette.HUD_WHITE, 6)
	_label(health_max, num_italic, 18, Color(1, 1, 1, 0.8), 4)
	_label(wave_count, num_italic, 34, Palette.HUD_WHITE, 6)
	_label(wave_label, plain, 15, Color(1, 1, 1, 0.75), 4)
	_label(dash_key, plain, 15, Color(1, 1, 1, 0.75), 4)
	_label(dash_cd, num_bold, 26, Palette.HUD_WHITE, 6)
	_label(kills_label, plain, 18, Color(1, 1, 1, 0.8), 4)
	_label(combo_label, title, 44, Palette.NEON_YELLOW, 10)
	combo_label.add_theme_color_override("font_outline_color", Color("6a0b52"))
	_label(banner_title, title, 110, Palette.HUD_WHITE, 18)
	banner_title.add_theme_color_override("font_outline_color", Color("0b5b66"))
	_label(banner_sub, num_bold, 26, Palette.NEON_CYAN, 6)
	_label(go_title, title, 120, Palette.NEON_MAGENTA, 20)
	go_title.add_theme_color_override("font_outline_color", Color("2a0622"))
	_label(go_wave, num_bold, 40, Palette.HUD_WHITE, 8)
	_label(go_kills, num_italic, 26, Color(1, 1, 1, 0.8), 6)
	_label(go_hint, num_bold, 30, Palette.NEON_CYAN, 6)
