class_name HUD
extends CanvasLayer
## Mission HUD.
##   top-left:     kills, salvage haul, objective, combo
##   top-centre:   hive alert meter, uplink / lift progress ring, elite health bar
##   top-right:    roll cooldown box
##   bottom-left:  weapon panel (rifle LOUD / blade QUIET) + segmented health bar
##   bottom-right: minimap
##   bottom-centre: interact prompt + handler radio
##   overlays:     objective marker, banner, results screen, damage vignette, crosshair

@export var banner_hold := 1.6
@export var radio_hold := 4.5
@export var hide_os_cursor := true
@export var number_font_names := PackedStringArray(["Rajdhani", "Exo 2", "Barlow", "Inter", "Arial", "sans-serif"])
@export var title_font_names := PackedStringArray(["Orbitron", "Exo 2", "Rajdhani", "Inter Display", "Arial Black", "sans-serif"])

const ALERT_COLORS := [Color("2fd1c4"), Color("ffd23d"), Color("ff8a1e"), Color("ff2b4b")]

@onready var vignette: ColorRect = $Vignette
@onready var crosshair: Crosshair = $Crosshair
@onready var health_value: Label = $Health/Numbers/Value
@onready var health_max: Label = $Health/Numbers/Max
@onready var health_bar: SegmentedBar = $Health/Bar
@onready var rifle_chip: Label = $Weapons/Rifle
@onready var blade_chip: Label = $Weapons/Blade
@onready var swap_hint: Label = $Weapons/Hint
@onready var alert_label: Label = $Alert/Label
@onready var alert_meter: AlertMeter = $Alert/Meter
@onready var progress_ring: WaveRing = $Progress/Ring
@onready var progress_value: Label = $Progress/Ring/Value
@onready var progress_caption: Label = $Progress/Caption
@onready var progress_root: Control = $Progress
@onready var boss_root: Control = $Boss
@onready var boss_name: Label = $Boss/Name
@onready var boss_bar: BossBar = $Boss/Bar
@onready var dash_box: AbilityBox = $Dash/Box
@onready var dash_cd: Label = $Dash/Box/Cooldown
@onready var dash_key: Label = $Dash/Key
@onready var kills_label: Label = $Kills
@onready var salvage_label: Label = $Salvage
@onready var objective_head: Label = $Objective/Head
@onready var objective_text: Label = $Objective/Text
@onready var combo_label: Label = $Combo
@onready var prompt_label: Label = $Prompt
@onready var radio_label: Label = $Radio
@onready var banner: Control = $Banner
@onready var banner_title: Label = $Banner/Title
@onready var banner_sub: Label = $Banner/Sub
@onready var results: Control = $Results
@onready var res_title: Label = $Results/Box/Title
@onready var res_sub: Label = $Results/Box/Sub
@onready var res_stats: Label = $Results/Box/Stats
@onready var res_bank: Label = $Results/Box/Bank
@onready var res_hint: Label = $Results/Box/Hint

var _hurt := 0.0
var _low_pulse := 0.0
var _health_ratio := 1.0
var _elite: Enemy
var _banner_tween: Tween
var _combo_tween: Tween
var _radio_tween: Tween
var _salvage_tween: Tween


func _ready() -> void:
	Game.hud = self
	_style()
	banner.visible = false
	results.visible = false
	boss_root.visible = false
	progress_root.visible = false
	combo_label.modulate.a = 0.0
	radio_label.modulate.a = 0.0
	prompt_label.text = ""
	Game.player_health_changed.connect(_on_health)
	Game.player_damaged.connect(_on_damaged)
	Game.kills_changed.connect(_on_kills)
	Game.alert_changed.connect(_on_alert)
	Game.mission_phase_changed.connect(_on_phase)
	Game.objective_changed.connect(_on_objective)
	Game.upload_changed.connect(_on_upload)
	Game.haul_changed.connect(_on_haul)
	Game.radio.connect(_on_radio)
	Game.banner.connect(_on_banner)
	Game.elite_changed.connect(_on_elite)
	Game.mission_ended.connect(_on_mission_ended)
	Game.weapon_changed.connect(_on_weapon)
	if hide_os_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	kills_label.text = "KILLS  0"
	_on_haul(0)
	_on_alert(0, 0.0)
	_on_weapon(Player.Weapon.RIFLE)
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
		var it := p.current_interactable
		if it and p.alive and not Game.is_game_over:
			var txt := it.get_prompt()
			prompt_label.text = ("[E]  " + txt.to_upper()) if it.enabled else txt.to_upper()
			prompt_label.modulate = Color.WHITE if it.enabled else Color(1, 1, 1, 0.55)
		else:
			prompt_label.text = ""
	if is_instance_valid(_elite) and _elite.is_active():
		boss_bar.ratio = _elite.health / _elite.max_health
	elif boss_root.visible:
		boss_root.visible = false
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


func _on_alert(level: int, value: float) -> void:
	alert_meter.value = value
	alert_meter.level = level
	alert_label.text = "HIVE ALERT  ·  " + HiveDirector.LEVEL_NAMES[level]
	alert_label.add_theme_color_override("font_color", ALERT_COLORS[level])


func _on_phase(phase: int) -> void:
	match phase:
		Mission.Phase.UPLOAD:
			progress_root.visible = true
			progress_caption.text = "UPLINK"
		Mission.Phase.EXTRACT:
			progress_root.visible = false
		Mission.Phase.LIFT:
			progress_root.visible = true
			progress_caption.text = "LIFT ARRIVING"
		Mission.Phase.COMPLETE, Mission.Phase.FAILED:
			progress_root.visible = false


func _on_objective(text: String) -> void:
	objective_text.text = text
	var t := create_tween().set_ignore_time_scale(true)
	objective_text.modulate = Color("ffd23d")
	t.tween_property(objective_text, "modulate", Color.WHITE, 0.8)


func _on_upload(ratio: float, in_zone: bool) -> void:
	progress_ring.ratio = ratio
	progress_value.text = "%d%%" % floori(ratio * 100.0)
	progress_ring.ring_color = Color("19f4ff") if in_zone else Color("ff2b4b")
	if not in_zone and Game.mission and Game.mission.phase == Mission.Phase.UPLOAD:
		progress_caption.text = "RETURN TO THE ZONE"
	elif Game.mission and Game.mission.phase == Mission.Phase.UPLOAD:
		progress_caption.text = "UPLINK"


func _on_haul(amount: int) -> void:
	salvage_label.text = "◆  SALVAGE  %d" % amount
	if amount > 0:
		if _salvage_tween:
			_salvage_tween.kill()
		salvage_label.pivot_offset = Vector2(0, salvage_label.size.y * 0.5)
		salvage_label.scale = Vector2(1.18, 1.18)
		_salvage_tween = create_tween().set_ignore_time_scale(true)
		_salvage_tween.tween_property(salvage_label, "scale", Vector2.ONE, 0.2)


func _on_radio(speaker: String, text: String) -> void:
	radio_label.text = "%s:  %s" % [speaker, text]
	if _radio_tween:
		_radio_tween.kill()
	radio_label.modulate.a = 0.0
	_radio_tween = create_tween().set_ignore_time_scale(true)
	_radio_tween.tween_property(radio_label, "modulate:a", 1.0, 0.2)
	_radio_tween.tween_interval(radio_hold)
	_radio_tween.tween_property(radio_label, "modulate:a", 0.0, 0.6)


func _on_banner(title: String, subtitle: String) -> void:
	banner_title.text = title
	banner_sub.text = subtitle
	if _banner_tween:
		_banner_tween.kill()
	banner.visible = true
	banner.modulate.a = 0.0
	banner_title.pivot_offset = banner_title.size * 0.5
	banner_title.scale = Vector2(1.8, 1.8)
	_banner_tween = create_tween().set_ignore_time_scale(true)
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(banner, "modulate:a", 1.0, 0.18)
	_banner_tween.tween_property(banner_title, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(banner_hold)
	_banner_tween.chain().tween_property(banner, "modulate:a", 0.0, 0.4)
	_banner_tween.chain().tween_callback(func(): banner.visible = false)


func _on_elite(enemy: Node) -> void:
	_elite = enemy as Enemy
	boss_root.visible = _elite != null
	if _elite:
		boss_name.text = "ELITE  " + _elite.display_name.to_upper()
		boss_bar.reset()


func _on_weapon(weapon: int) -> void:
	var rifle := weapon == Player.Weapon.RIFLE
	rifle_chip.modulate = Color(1, 1, 1, 1.0 if rifle else 0.35)
	blade_chip.modulate = Color(1, 1, 1, 1.0 if not rifle else 0.35)
	rifle_chip.text = ("▶ " if rifle else "   ") + "RIFLE  ·  LOUD"
	blade_chip.text = ("▶ " if not rifle else "   ") + "BLADE  ·  QUIET"


func _on_kills(kills: int, combo: int) -> void:
	kills_label.text = "KILLS  %d" % kills
	if combo >= 3:
		combo_label.text = "COMBO x%d" % combo
		combo_label.pivot_offset = combo_label.size * Vector2(0.0, 0.5)
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


func _on_mission_ended(success: bool, s: Dictionary) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	crosshair.visible = false
	prompt_label.text = ""
	res_title.text = "EXTRACTED" if success else "SIGNAL LOST"
	res_title.add_theme_color_override("font_color", Palette.NEON_CYAN if success else Palette.NEON_MAGENTA)
	res_sub.text = "UPLINK DATA SECURED" if s.data else "UPLINK DATA NOT RECOVERED"
	var mins := int(s.time) / 60
	var secs := int(s.time) % 60
	res_stats.text = "%d KILLS   ·   BEST COMBO x%d   ·   PEAK ALERT %d%%   ·   %d:%02d" % [s.kills, s.best_combo, roundi(s.peak_alert), mins, secs]
	if success:
		res_bank.text = "◆  %d SALVAGE BANKED   ·   TOTAL %d" % [s.haul, s.banked]
		res_bank.add_theme_color_override("font_color", Palette.NEON_YELLOW)
	else:
		res_bank.text = "◆  %d SALVAGE LOST   ·   BANKED %d" % [s.haul, s.banked]
		res_bank.add_theme_color_override("font_color", Palette.HUD_DANGER)
	res_hint.text = "PRESS  R  TO DIVE AGAIN"
	results.visible = true
	results.modulate.a = 0.0
	res_title.pivot_offset = res_title.size * 0.5
	res_title.scale = Vector2(1.6, 1.6)
	var t := create_tween().set_ignore_time_scale(true).set_parallel(true)
	t.tween_property(results, "modulate:a", 1.0, 0.5).set_delay(0.6 if not success else 0.2)
	t.tween_property(res_title, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.6 if not success else 0.2)
	var blink := create_tween().set_ignore_time_scale(true).set_loops()
	blink.tween_property(res_hint, "modulate:a", 0.35, 0.6)
	blink.tween_property(res_hint, "modulate:a", 1.0, 0.6)


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
	_label(rifle_chip, num_bold, 17, Palette.HUD_WHITE, 5)
	_label(blade_chip, num_bold, 17, Palette.NEON_CYAN, 5)
	_label(swap_hint, plain, 13, Color(1, 1, 1, 0.6), 4)
	_label(alert_label, num_bold, 15, ALERT_COLORS[0], 5)
	_label(progress_value, num_italic, 26, Palette.HUD_WHITE, 6)
	_label(progress_caption, num_bold, 15, Palette.NEON_CYAN, 5)
	_label(boss_name, title, 20, Color("d79bff"), 6)
	_label(dash_key, plain, 15, Color(1, 1, 1, 0.75), 4)
	_label(dash_cd, num_bold, 26, Palette.HUD_WHITE, 6)
	_label(kills_label, plain, 18, Color(1, 1, 1, 0.8), 4)
	_label(salvage_label, num_bold, 20, Palette.NEON_YELLOW, 5)
	_label(objective_head, plain, 13, Palette.NEON_CYAN, 4)
	_label(objective_text, num_bold, 20, Palette.HUD_WHITE, 5)
	_label(combo_label, title, 40, Palette.NEON_YELLOW, 10)
	combo_label.add_theme_color_override("font_outline_color", Color("6a0b52"))
	_label(prompt_label, num_bold, 22, Palette.HUD_WHITE, 6)
	_label(radio_label, num_italic, 19, Color("cfe9ff"), 6)
	_label(banner_title, title, 84, Palette.HUD_WHITE, 16)
	banner_title.add_theme_color_override("font_outline_color", Color("0b5b66"))
	_label(banner_sub, num_bold, 24, Palette.NEON_CYAN, 6)
	_label(res_title, title, 110, Palette.NEON_MAGENTA, 20)
	res_title.add_theme_color_override("font_outline_color", Color("1a0622"))
	_label(res_sub, num_bold, 30, Palette.HUD_WHITE, 7)
	_label(res_stats, num_italic, 22, Color(1, 1, 1, 0.8), 6)
	_label(res_bank, num_bold, 28, Palette.NEON_YELLOW, 6)
	_label(res_hint, num_bold, 28, Palette.NEON_CYAN, 6)
