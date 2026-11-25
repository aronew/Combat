class_name HunterBody
extends Node3D
## The hunter's animated body: the skinned model, its animation tree and her weapons.
##
## The player drives it with a few calls: `set_move` (direction relative to her facing and
## speed), `set_rifle_mode`, and the one-shot actions `swing`, `roll`, `hit`, `die`. Her legs
## blend between the run clips by direction; with the rifle out, her upper body holds an aimed
## pose on top. Roll and hit reactions are short cuts of library moves, sped up to match the
## game's timing (see art_src/blender/import_hunter.py).
##
## Sword swings play a dedicated library move per cut (see SWINGS) on a time curve of their own
## instead of at a fixed speed: a short wind-up that eases in, a whip through the
## strike that crosses her front exactly when the player's hit lands, then a slower follow-
## through that blends back out. While she runs, only her upper body swings. Two swing slots
## crossfade, so chaining cuts never pops. A ribbon trails the blade through each strike.
##
## The body faces -Z like the rest of the player's visual.

const MODEL := preload("res://assets/models/hunter/hunter.glb")
const RIFLE := preload("res://assets/models/hunter/hive_rifle.glb")
const BLADE := preload("res://assets/models/hunter/chitin_blade.glb")

## Bones above the waist: the aimed pose and hit reactions only drive these.
const UPPER_BONES := ["Spine01", "Spine", "neck", "Head", "head_end", "headfront",
	"LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand",
	"RightShoulder", "RightArm", "RightForeArm", "RightHand"]

## The three cuts inside `sword_combo` (clip seconds): where the wind-up starts, where the blade
## crosses her front (contact), where the strike ends, and where the follow-through settles.
## `sweep` is the direction the blade travels across her front: +1 left to right, -1 right to
## left. Found by tracking the blade tip through the clip (fastest frames, angle around her).
## Each cut names its clip. The first set is the dedicated library moves (right-hand slash,
## left slash, Sword_Judgment leap-and-slam); COMBO_SWINGS is the original three cuts inside
## the library combo, kept for comparison (use_new_sword_clips off). Times measured the same way
## for both: contact is where the blade tip crosses straight ahead of her at full speed.
const SWINGS := [
	{"clip": "sword_slash_r", "start": 0.30, "contact": 0.587, "strike_end": 0.73, "settle": 0.80, "sweep": -1.0},
	# Left_Slash has two passes; this is the second, faster one, which sweeps the other way.
	{"clip": "sword_slash_l", "start": 1.10, "contact": 1.31, "strike_end": 1.44, "settle": 1.52, "sweep": 1.0},
	# Starts at lift-off: the wind-up is the leap, contact is the slam, settle is the landing.
	{"clip": "sword_judgment", "start": 0.62, "contact": 1.03, "strike_end": 1.13, "settle": 1.30, "sweep": 1.0},
]
const COMBO_SWINGS := [
	{"clip": "sword_combo", "start": 0.58, "contact": 0.735, "strike_end": 0.83, "settle": 0.93, "sweep": 1.0},
	{"clip": "sword_combo", "start": 1.36, "contact": 1.51, "strike_end": 1.66, "settle": 1.80, "sweep": -1.0},
	{"clip": "sword_combo", "start": 2.02, "contact": 2.225, "strike_end": 2.37, "settle": 2.56, "sweep": 1.0},
]
## The part of `roll_tight` that is the roll: the dive, the tuck and coming up (clip seconds).
const ROLL_CLIP := "roll_tight"
const ROLL_START := 0.30
const ROLL_END := 1.50
## Points on the blade model (its own units, 1.9 m along X, tip at -X) the trail runs between.
const BLADE_BASE := Vector3(0.1, 0.0, 0.0)
const BLADE_TIP := Vector3(-0.97, 0.0, 0.0)

## Running speed (m/s) at which the run clips play at normal speed.
@export var run_clip_speed := 5.5
@export var min_clip_scale := 0.7
@export var max_clip_scale := 1.9
@export_group("Swings")
## Contact to the end of the strike (seconds of game time, before the blade's pace scaling).
@export var swing_strike_time := 0.07
@export var finisher_strike_time := 0.1
## Follow-through: the blade decelerates and the swing blends back out over this long.
@export var swing_recover_time := 0.24
@export var finisher_recover_time := 0.34
## Blend from whatever she was doing into the wind-up.
@export var swing_blend_in := 0.035
## When a cut starts before the last one has finished, the old one fades out over this long.
@export var swing_crossfade := 0.06
## Below this ground speed (m/s) a swing drives her whole body; above it, only the upper body.
@export var plant_speed := 1.2
## Blade trail: how long a point of the ribbon lasts, and how bright it is.
@export var trail_life := 0.13
@export var trail_energy := 2.6
@export_group("")
@export var roll_time := 0.38
## The dedicated sword clips for the three cuts (off: the three cuts of the library combo).
@export var use_new_sword_clips := true
## Blade out: her upper body holds the sword-held guard pose over the legs (like the rifle's aim).
@export var use_sword_guard := true
@export var hit_time := 0.35
## Weapon fitting. Both models are 1.9 m long as generated; these bring them to size.
@export var rifle_scale := 0.5
@export var blade_scale := 0.62
## Where the hand grips each model, in the model's own units (it is 1.9 m along X, muzzle
## and tip at -X).
@export var rifle_grip := Vector3(0.28, -0.12, 0.0)
## Height the rifle is carried at (the hand's own height is blended toward this).
@export var rifle_height := 1.2
@export var blade_grip := Vector3(0.74, 0.0, 0.0)
## Blade in hand: rotation (degrees) of the blade relative to the right hand bone.
@export var blade_in_hand_rotation := Vector3(0.0, 35.0, -15.0)
## A soft light above and behind her so the dark chitin reads on dark floors. Neutral and cool
## so it separates her from the floor without tinting her (it used to be red).
@export var rim_light_energy := 0.55
@export var rim_light_color := Color(0.78, 0.87, 1.0)
## Material tuning for the generated textures. They are authored as fully metallic, which
## reads as black under the game's dim ambient light (there are no sky reflections to show).
@export var metal_scale := 0.35
@export var albedo_lift := 1.3
## The model's emission map (nearly empty on the current model); this is how hard it glows.
@export var glow_energy := 2.0
## Silhouette rim (see rim_glow.gdshader): a thin, cool edge so she reads on dark floors from
## far away. Kept faint: strong, it washed her whole body in colour.
@export var rim_color := Color(0.62, 0.8, 1.0)
@export var rim_strength := 0.32
@export var rim_power := 4.0
## Heroes are drawn a little larger than life so they read from the high camera.
@export var body_scale := 1.12
@export_group("Troubleshooting")
## Switches for the extras the hunter adds on top of the model, to narrow down a rendering
## problem on a particular GPU: untick one at a time and see which one fixes it.
@export var use_rim_pass := true
@export var use_rim_light := true
@export var use_ghosts := true
## Use a fixed, generous bounding box for culling instead of the one computed from the
## animated skin (a bad computed box can make the character vanish).
@export var fixed_bounds := true
@export_group("")

var skeleton: Skeleton3D
var anim: AnimationPlayer
var tree: AnimationTree
var rifle: Node3D
var blade: Node3D
var rifle_mode := true

var _model: Node3D
var _hand_attach: BoneAttachment3D
var _back_attach: BoneAttachment3D
var _rifle_basis := Basis()
var _muzzle_local := Vector3.ZERO
var _kick := 0.0
var _aim_amount := 1.0
var _dead := false
var _ghosts: Array[Node3D] = []
var _ghost_index := 0
var _pose: Array[Transform3D] = []
## Two swing slots (see _tick_swings): each {active, step, t, contact_in, strike, recover,
## fading, fade_t, clip_t, seg}. `_slot` is the one playing the newest cut.
var _swings: Array[Dictionary] = []
var _slot := 0
## 1 standing still (swings drive the whole body) .. 0 running (upper body only), smoothed.
var _plant := 1.0
var _move_speed := 0.0
var _trail: BladeTrail
var _trail_seg := 0
var _prev_xf := Transform3D.IDENTITY
var _bone_hips := -1
var _bone_hand := -1
## Track indices of SWING_CLIP per bone (rotation, position), for sampling it off the tree.
var _swing_tracks := {}  # clip name -> Array[Vector2i]
var _bt: AnimationNodeBlendTree
var _guard_amount := 0.0
## True once the model, animation tree and weapons are all set up. The player falls back to
## the old body if this is still false after adding it (a missing or broken import).
var ok := false


func _ready() -> void:
	if MODEL == null or RIFLE == null or BLADE == null:
		push_error("HunterBody: hunter models failed to load (check assets/models/hunter imports)")
		return
	_model = MODEL.instantiate()
	_model.rotation.y = PI  # the model faces +Z; the player faces -Z
	_model.scale = Vector3.ONE * body_scale
	add_child(_model)
	skeleton = _model.find_child("Skeleton3D", true, false)
	anim = _model.find_child("AnimationPlayer", true, false)
	_tune_materials(_model, use_rim_pass)
	if fixed_bounds:
		for m in _model.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).custom_aabb = AABB(Vector3(-1.5, -0.5, -1.5), Vector3(3.0, 3.0, 3.0))
	_build_tree()
	_fit_weapons()
	_tune_materials(rifle)
	_tune_materials(blade)
	if use_rim_light:
		_add_rim_light()
	_use_shadow_proxy()
	_bone_hips = skeleton.find_bone("Hips")
	_bone_hand = skeleton.find_bone("RightHand")
	_cache_swing_tracks()
	for i in 2:
		_swings.append({"active": false, "step": 1, "t": 0.0, "contact_in": 0.0, "strike": 0.1,
			"recover": 0.2, "fading": false, "fade_t": 0.0, "clip_t": 0.0, "seg": 0, "clip": ""})
	_trail = BladeTrail.new()
	_trail.name = "BladeTrail"
	_trail.life = trail_life
	add_child(_trail)
	_prev_xf = global_transform
	set_rifle_mode(true)
	ok = skeleton != null and tree != null and rifle != null and blade != null and _bone_hand >= 0


# --------------------------------------------------------------------------
# Driving
# --------------------------------------------------------------------------

## move: x = right, y = forward, relative to where she faces; length = 0 standing .. 1 full run.
## speed: actual ground speed (m/s), scales the run clips so the feet keep up.
func set_move(move: Vector2, speed: float) -> void:
	if tree == null:
		return
	tree.set("parameters/loco/blend_position", move.limit_length(1.0))
	var s := clampf(speed / run_clip_speed, min_clip_scale, max_clip_scale) if speed > 0.5 else 1.0
	tree.set("parameters/loco_speed/scale", s)
	_move_speed = speed


func set_rifle_mode(on: bool) -> void:
	rifle_mode = on
	if rifle:
		rifle.visible = on
	if blade:
		var holder := _back_attach if on else _hand_attach
		if blade.get_parent() != holder:
			blade.reparent(holder, false)
		blade.transform = blade.get_meta("back_xf") if on else blade.get_meta("hand_xf")


func _process(delta: float) -> void:
	if tree == null:
		return
	# Ease the aimed upper body in and out (it drops during a roll or a swing anyway).
	_aim_amount = move_toward(_aim_amount, 1.0 if rifle_mode and not _dead else 0.0, delta * 8.0)
	tree.set("parameters/aim/blend_amount", _aim_amount)
	_guard_amount = move_toward(_guard_amount, 1.0 if use_sword_guard and not rifle_mode and not _dead else 0.0, delta * 8.0)
	tree.set("parameters/guard/blend_amount", _guard_amount)
	if rifle:
		_kick = move_toward(_kick, 0.0, delta * 7.0)
		_place_rifle()
	_tick_swings(delta)
	_prev_xf = global_transform


## Gun recoil: pushes the rifle back along the barrel (the player adds body lean on top).
func kick(amount: float) -> void:
	_kick = minf(_kick + amount, 1.6)


## The rifle's muzzle in world space.
func muzzle_position() -> Vector3:
	if rifle == null:
		return global_position + global_transform.basis * Vector3(0.2, 1.1, -0.9)
	return rifle.global_transform * _muzzle_local


## One cut of the combo: step 1..3, the third is the finisher.
## contact_in: seconds until the player's hit lands; the blade crosses her front right then
## (0 = start at the strike, e.g. arriving from a dash-strike).
## pace: 1 for the standard blade, more for slower, heavier blades (stretches the strike and
## the follow-through).
## color: the trail's colour (the blade's).
func swing(step: int, contact_in := 0.07, pace := 1.0, color := Color(0.1, 0.95, 1.0)) -> void:
	if tree == null or _dead:
		return
	step = clampi(step, 1, 3)
	var finisher := step >= 3
	# the previous cut fades out under the new one
	var old := _swings[_slot]
	if old.active and not old.fading:
		old.fading = true
		old.fade_t = 0.0
	_slot = 1 - _slot
	var sw := _swings[_slot]
	sw.active = true
	sw.fading = false
	sw.fade_t = 0.0
	sw.step = step
	sw.t = 0.0
	sw.contact_in = maxf(contact_in, 0.0)
	sw.strike = (finisher_strike_time if finisher else swing_strike_time) * pace
	sw.recover = (finisher_recover_time if finisher else swing_recover_time) * pace
	_trail_seg += 1
	sw.seg = _trail_seg
	sw.clip = String(_cuts()[step - 1].clip)
	for part in ["up", "lo"]:
		(_bt.get_node("sw%d_%s_clip" % [_slot, part]) as AnimationNodeAnimation).animation = sw.clip
	sw.clip_t = _swing_clip_time(sw)
	_trail.set_look(color, trail_energy * (1.3 if finisher else 1.0), 1.25 if finisher else 1.0)


## Which way the blade sweeps across her front for this cut: +1 left to right, -1 right to left.
func swing_sweep(step: int) -> float:
	return _cuts()[clampi(step, 1, 3) - 1].sweep


func roll() -> void:
	if tree == null or _dead:
		return
	for sw in _swings:  # a roll cancels the follow-through
		if sw.active and not sw.fading:
			sw.fading = true
			sw.fade_t = swing_crossfade * 0.5
	tree.set("parameters/roll_speed/scale", (ROLL_END - ROLL_START) / roll_time)
	tree.set("parameters/roll_seek/seek_request", ROLL_START)
	tree.set("parameters/roll/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func hit() -> void:
	if tree == null or _dead:
		return
	tree.set("parameters/hit_speed/scale", anim.get_animation("hit_quick").length / hit_time)
	tree.set("parameters/hit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func die() -> void:
	if tree == null:
		return
	_dead = true
	for p in ["roll", "hit"]:
		tree.set("parameters/%s/request" % p, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	for i in _swings.size():
		_swings[i].active = false
		_set_swing_weights(i, 0.0, 0.0)
	tree.set("parameters/life/transition_request", "dead")


func revive() -> void:
	_dead = false
	if tree:
		tree.set("parameters/life/transition_request", "alive")


# --------------------------------------------------------------------------
# Swings: the combo clip played on a time curve, two slots crossfading, a trail on the blade
# --------------------------------------------------------------------------

## Clip time for a swing `sw.t` seconds in. Three phases, each mapped onto its piece of the clip:
## wind-up (eases in: she gathers, then whips), strike (contact to strike end, eases out) and
## follow-through (decelerates into the settle pose).
func _swing_clip_time(sw: Dictionary) -> float:
	var s: Dictionary = _cuts()[sw.step - 1]
	var t: float = sw.t
	var c: float = sw.contact_in
	if t < c:
		var k := t / c
		return lerpf(s.start, s.contact, k * k)
	t -= c
	if t < sw.strike:
		var k: float = t / sw.strike
		return lerpf(s.contact, s.strike_end, 1.0 - (1.0 - k) * (1.0 - k))
	t -= sw.strike
	var k := clampf(t / sw.recover, 0.0, 1.0)
	return lerpf(s.strike_end, s.settle, 1.0 - (1.0 - k) * (1.0 - k))


## How much of the pose this swing owns: blends in, holds through the strike, lets go during
## the follow-through (sooner while she runs) and fades out under a newer cut.
func _swing_weight(sw: Dictionary) -> float:
	var w := 1.0
	if sw.contact_in > 0.0:
		w = clampf(sw.t / swing_blend_in, 0.0, 1.0)
	var r: float = (sw.t - sw.contact_in - sw.strike) / sw.recover
	if r > 0.0:
		var let_go := lerpf(0.05, 0.35, _plant)  # running: hand the arms back to the run sooner
		w *= 1.0 - smoothstep(let_go, 1.0, r)
	if sw.fading:
		w *= 1.0 - clampf(sw.fade_t / swing_crossfade, 0.0, 1.0)
	return w


func _tick_swings(delta: float) -> void:
	if _swings.is_empty():
		return
	var plant_target := 1.0 - clampf((_move_speed - plant_speed * 0.5) / plant_speed, 0.0, 1.0)
	_plant = move_toward(_plant, plant_target, delta * 8.0)
	for i in 2:
		var sw := _swings[i]
		if not sw.active:
			continue
		var prev_clip: float = sw.clip_t
		sw.t += delta
		if sw.fading:
			sw.fade_t += delta
		sw.clip_t = _swing_clip_time(sw)
		var w := _swing_weight(sw)
		var done: bool = sw.t > sw.contact_in + sw.strike + sw.recover or (sw.fading and sw.fade_t >= swing_crossfade)
		if done:
			sw.active = false
			w = 0.0
		tree.set("parameters/sw%d_seek_up/seek_request" % i, sw.clip_t)
		tree.set("parameters/sw%d_seek_lo/seek_request" % i, sw.clip_t)
		_set_swing_weights(i, w, w * _plant)
		# The trail runs from the end of the wind-up's whip to a little into the follow-through.
		var into: float = sw.t - sw.contact_in
		if i == _slot and not sw.fading and into > -0.35 * sw.contact_in - 0.001 and into < sw.strike + sw.recover * 0.3:
			_emit_trail(sw, prev_clip, delta)


func _set_swing_weights(i: int, upper: float, lower: float) -> void:
	tree.set("parameters/sw%d_up/blend_amount" % i, upper)
	tree.set("parameters/sw%d_lo/blend_amount" % i, lower)


## Adds this frame's stretch of blade path to the trail. The blade is sampled off the clip at a
## few in-between times too (placed on her hips as they are now), so the arc stays round even
## at a low frame rate, when one frame can cover a quarter of the swing.
func _emit_trail(sw: Dictionary, prev_clip: float, delta: float) -> void:
	var steps := clampi(int(ceil(absf(sw.clip_t - prev_clip) / 0.012)), 1, 8)
	var hips_now := skeleton.get_bone_global_pose(_bone_hips)
	var sk_local := global_transform.affine_inverse() * skeleton.global_transform
	var hx: Transform3D = blade.get_meta("hand_xf")
	for j in range(1, steps + 1):
		var f := float(j) / steps
		var ct := lerpf(prev_clip, sw.clip_t, f)
		var pose := _swing_pose(sw.clip, ct)
		# the clip's hand, carried by the hips she actually has this frame (they may be running)
		var hand := hips_now * pose[0].affine_inverse() * pose[1]
		var blade_local := sk_local * hand * hx
		var body_xf := _prev_xf.interpolate_with(global_transform, f)
		var xf := body_xf * blade_local
		_trail.add_point(xf * BLADE_BASE, xf * BLADE_TIP, sw.seg, (1.0 - f) * delta)


func _cuts() -> Array:
	return SWINGS if use_new_sword_clips else COMBO_SWINGS


## Skeleton-space poses of the hips and right hand at time t of a swing clip.
func _swing_pose(clip: String, t: float) -> Array[Transform3D]:
	var a := anim.get_animation(clip)
	var tracks: Array = _swing_tracks[clip]
	var chain: Array[int] = []
	var b := _bone_hand
	while b >= 0:
		chain.push_front(b)
		b = skeleton.get_bone_parent(b)
	var hips := Transform3D.IDENTITY
	var acc := Transform3D.IDENTITY
	for bone in chain:
		var local := skeleton.get_bone_rest(bone)
		var tr: Vector2i = tracks[bone]
		if tr.x >= 0:
			local.basis = Basis(a.rotation_track_interpolate(tr.x, t)).scaled(local.basis.get_scale())
		if tr.y >= 0:
			local.origin = a.position_track_interpolate(tr.y, t)
		acc = acc * local
		if bone == _bone_hips:
			hips = acc
	return [hips, acc]


func _cache_swing_tracks() -> void:
	var skel_path := String(_model.get_path_to(skeleton))
	for cut in SWINGS + COMBO_SWINGS:
		var clip := String(cut.clip)
		if _swing_tracks.has(clip):
			continue
		var a := anim.get_animation(clip)
		var tracks: Array[Vector2i] = []
		tracks.resize(skeleton.get_bone_count())
		for b in skeleton.get_bone_count():
			var path := NodePath("%s:%s" % [skel_path, skeleton.get_bone_name(b)])
			tracks[b] = Vector2i(a.find_track(path, Animation.TYPE_ROTATION_3D) if a else -1,
				a.find_track(path, Animation.TYPE_POSITION_3D) if a else -1)
		_swing_tracks[clip] = tracks


# --------------------------------------------------------------------------
# Dash ghosts: posed copies of the body left behind during a roll or a dash-strike
# --------------------------------------------------------------------------

func build_ghosts(count: int, material: Material) -> void:
	if not use_ghosts:
		return
	for i in count:
		var g: Node3D = MODEL.instantiate()
		var ap := g.find_child("AnimationPlayer", true, false)
		if ap:
			ap.queue_free()
		for m in g.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			mi.material_override = material.duplicate()
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.top_level = true
		g.visible = false
		g.set_meta("life", 0.0)
		add_child(g)
		_ghosts.append(g)


## Leaves a copy of her current pose behind. Returns it (the caller fades it).
func spawn_ghost() -> Node3D:
	if _ghosts.is_empty():
		return null
	var g := _ghosts[_ghost_index]
	_ghost_index = (_ghost_index + 1) % _ghosts.size()
	g.global_transform = _model.global_transform
	var gs: Skeleton3D = g.find_child("Skeleton3D", true, false)
	for b in skeleton.get_bone_count():
		gs.set_bone_pose(b, skeleton.get_bone_pose(b))
	g.visible = true
	g.set_meta("life", 0.22)
	return g


func ghosts() -> Array[Node3D]:
	return _ghosts


func ghost_meshes(g: Node3D) -> Array[Node]:
	return g.find_children("*", "MeshInstance3D", true, false)


# --------------------------------------------------------------------------
# Setup
# --------------------------------------------------------------------------

func _build_tree() -> void:
	var bt := AnimationNodeBlendTree.new()
	var skel_path := String(_model.get_path_to(skeleton))

	# Legs: run clips by direction (x right, y forward), idle in the middle.
	var loco := AnimationNodeBlendSpace2D.new()
	loco.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_INTERPOLATED
	for p in [["idle", Vector2.ZERO], ["run_forward", Vector2(0, 1)], ["walk_back", Vector2(0, -1)],
			["strafe_left", Vector2(-1, 0)], ["strafe_right", Vector2(1, 0)],
			["run_back_left", Vector2(-0.72, -0.72)], ["run_back_right", Vector2(0.72, -0.72)]]:
		loco.add_blend_point(_clip(p[0]), p[1], -1, p[0])
	bt.add_node("loco", loco, Vector2(0, 0))
	bt.add_node("loco_speed", AnimationNodeTimeScale.new(), Vector2(200, 0))
	bt.connect_node("loco_speed", 0, "loco")

	# Rifle out: the upper body holds the aimed pose from the backpedal clip (rifle shouldered,
	# pointing forward) over whatever the legs are doing.
	var aim := AnimationNodeBlend2.new()
	_filter_upper(aim, skel_path)
	bt.add_node("aim_pose", _clip("walk_back"), Vector2(200, 150))
	bt.add_node("aim", aim, Vector2(400, 0))
	bt.connect_node("aim", 0, "loco_speed")
	bt.connect_node("aim", 1, "aim_pose")

	# Hit reaction: upper body only, so she keeps running.
	var hit_shot := AnimationNodeOneShot.new()
	hit_shot.fadein_time = 0.04
	hit_shot.fadeout_time = 0.15
	_filter_upper(hit_shot, skel_path)
	bt.add_node("hit_clip", _clip("hit_quick"), Vector2(400, 150))
	bt.add_node("hit_speed", AnimationNodeTimeScale.new(), Vector2(600, 150))
	bt.connect_node("hit_speed", 0, "hit_clip")
	bt.add_node("hit", hit_shot, Vector2(800, 0))
	# Blade out: the upper body holds the sword-held pose from the sword backpedal clip.
	var guard := AnimationNodeBlend2.new()
	_filter_upper(guard, skel_path)
	bt.add_node("guard_pose", _clip("sword_walk_back"), Vector2(400, 300))
	bt.add_node("guard", guard, Vector2(600, 0))
	bt.connect_node("guard", 0, "aim")
	bt.connect_node("guard", 1, "guard_pose")
	bt.connect_node("hit", 0, "guard")
	bt.connect_node("hit", 1, "hit_speed")

	# Blade swings: two slots, each the combo clip held at a time the script sets every frame
	# (seek, then a zero time scale so the tree never advances it on its own). Each slot drives
	# the upper body and, while she stands, the lower body too (see _tick_swings).
	var lower := []
	for b in skeleton.get_bone_count():
		if not skeleton.get_bone_name(b) in UPPER_BONES:
			lower.append(skeleton.get_bone_name(b))
	var prev := "hit"
	for i in 2:
		for part in ["up", "lo"]:
			var n := "sw%d_%s" % [i, part]
			bt.add_node(n + "_clip", _clip(String(_cuts()[0].clip)), Vector2(800 + 400 * i, 150 + (120 if part == "lo" else 0)))
			bt.add_node("sw%d_seek_%s" % [i, part], AnimationNodeTimeSeek.new(), Vector2(900 + 400 * i, 150))
			bt.connect_node("sw%d_seek_%s" % [i, part], 0, n + "_clip")
			var hold := AnimationNodeTimeScale.new()
			bt.add_node(n + "_hold", hold, Vector2(1000 + 400 * i, 150))
			bt.connect_node(n + "_hold", 0, "sw%d_seek_%s" % [i, part])
			var mix := AnimationNodeBlend2.new()
			if part == "up":
				_filter_upper(mix, skel_path)
			else:
				mix.filter_enabled = true
				for bn in lower:
					mix.set_filter_path(NodePath("%s:%s" % [skel_path, bn]), true)
			bt.add_node(n, mix, Vector2(1100 + 400 * i, 0))
			bt.connect_node(n, 0, prev)
			bt.connect_node(n, 1, n + "_hold")
			prev = n

	# Roll: whole body.
	# The roll starts ROLL_START into the clip (a seek, set when it fires): plain nodes that
	# every Godot 4 version has, so the web editor can run it too.
	bt.add_node("roll_clip", _clip(ROLL_CLIP), Vector2(1400, 150))
	bt.add_node("roll_seek", AnimationNodeTimeSeek.new(), Vector2(1500, 150))
	bt.connect_node("roll_seek", 0, "roll_clip")
	bt.add_node("roll_speed", AnimationNodeTimeScale.new(), Vector2(1600, 150))
	bt.connect_node("roll_speed", 0, "roll_seek")
	var roll_shot := AnimationNodeOneShot.new()
	roll_shot.fadein_time = 0.03
	roll_shot.fadeout_time = 0.1
	bt.add_node("roll", roll_shot, Vector2(1800, 0))
	bt.connect_node("roll", 0, prev)
	bt.connect_node("roll", 1, "roll_speed")

	# Death: falls and stays down.
	var life := AnimationNodeTransition.new()
	life.xfade_time = 0.12
	life.add_input("alive")
	life.add_input("dead")
	bt.add_node("death_clip", _clip("death_fall"), Vector2(1800, 150))
	bt.add_node("life", life, Vector2(2000, 0))
	bt.connect_node("life", 0, "roll")
	bt.connect_node("life", 1, "death_clip")
	bt.connect_node("output", 0, "life")

	tree = AnimationTree.new()
	tree.name = "AnimationTree"
	_model.add_child(tree)
	tree.root_node = tree.get_path_to(_model)
	tree.anim_player = tree.get_path_to(anim)
	tree.tree_root = bt
	_bt = bt
	tree.active = true
	tree.set("parameters/loco_speed/scale", 1.0)
	tree.set("parameters/aim/blend_amount", 1.0)
	tree.set("parameters/guard/blend_amount", 0.0)
	tree.set("parameters/life/transition_request", "alive")
	for i in 2:
		for part in ["up", "lo"]:
			tree.set("parameters/sw%d_%s_hold/scale" % [i, part], 0.0)
			tree.set("parameters/sw%d_%s/blend_amount" % [i, part], 0.0)


func _clip(name: String) -> AnimationNodeAnimation:
	var n := AnimationNodeAnimation.new()
	n.animation = name
	return n


func _filter_upper(node: AnimationNode, skel_path: String) -> void:
	node.filter_enabled = true
	for b in UPPER_BONES:
		node.set_filter_path(NodePath("%s:%s" % [skel_path, b]), true)


## Puts the rifle in her hands (fitted to the aimed pose) and the blade on her back.
func _fit_weapons() -> void:
	# Measure the hand in the aimed pose. The pose is computed from the clip's keys: the
	# skeleton itself only takes a pose once the scene has processed a frame.
	_pose = _clip_pose("walk_back", 0.0)
	var hand := skeleton.find_bone("RightHand")
	var spine := skeleton.find_bone("Spine")

	_hand_attach = BoneAttachment3D.new()
	_hand_attach.bone_name = "RightHand"
	skeleton.add_child(_hand_attach)
	_back_attach = BoneAttachment3D.new()
	_back_attach.bone_name = "Spine"
	skeleton.add_child(_back_attach)

	var body := global_transform
	var to_body := body.affine_inverse()
	var spine_body := to_body * skeleton.global_transform * _pose[spine]

	# Rifle: it follows the right hand's position but keeps pointing where she faces (the
	# barrel, model -X, along -Z): in a twin-stick shooter the gun must point at the aim even
	# while the legs' clip twists her hips. Placed every frame in _place_rifle().
	rifle = RIFLE.instantiate()
	rifle.name = "Rifle"
	_rifle_basis = Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0)).scaled(Vector3.ONE * rifle_scale * body_scale)
	add_child(rifle)
	_muzzle_local = Vector3(-0.95, 0.06, 0.0)
	_place_rifle()

	# Blade on her back: hilt over the right shoulder, tip down to the left hip, flat to her back.
	blade = BLADE.instantiate()
	blade.name = "Blade"
	var down := Vector3(-0.45, -0.89, 0.0).normalized()  # from the hilt toward the tip
	var bx := -down  # model +X points from the tip toward the hilt
	var by := Vector3(0, 0, 1).cross(bx).normalized()
	var bb := Basis(bx, by, bx.cross(by)).scaled(Vector3.ONE * blade_scale)
	var hilt := spine_body.origin + Vector3(0.2, 0.36, 0.2)
	var blade_body := Transform3D(bb, hilt - bb * blade_grip)
	_back_attach.add_child(blade)
	blade.set_meta("back_xf", _attach_local(spine, blade_body))
	set_blade_grip(blade_in_hand_rotation)
	blade.transform = blade.get_meta("back_xf")


## Blade in hand: the grip in the fist, rotated by `rot` (degrees) relative to the hand bone.
func set_blade_grip(rot: Vector3) -> void:
	blade_in_hand_rotation = rot
	var hand := skeleton.find_bone("RightHand")
	var hb := Basis.from_euler(rot * PI / 180.0).scaled(Vector3.ONE * blade_scale)
	# the attachment carries the skeleton's 0.01 import scale: undo it for the child
	var hand_scale := skeleton.global_transform.basis.get_scale()
	hb = Basis.from_scale(Vector3.ONE / hand_scale) * hb
	blade.set_meta("hand_xf", Transform3D(hb, -(hb * blade_grip)))
	if not rifle_mode:
		blade.transform = blade.get_meta("hand_xf")


## Grip at the right hand (in its current pose), barrel along her facing, pushed back by recoil.
func _place_rifle() -> void:
	var hand := skeleton.find_bone("RightHand")
	var hand_pos := global_transform.affine_inverse() * (skeleton.global_transform * skeleton.get_bone_global_pose(hand).origin)
	# keep it at a steady shoulder height: the hand bobs with the clip far more than a held gun should
	hand_pos.y = lerpf(hand_pos.y, rifle_height * body_scale, 0.7)
	rifle.transform = Transform3D(_rifle_basis, hand_pos - _rifle_basis * rifle_grip + Vector3(0, 0, _kick * 0.08))


## Skeleton-space transform of every bone at time t of a clip (from its keys and the rest pose).
func _clip_pose(clip: String, t: float) -> Array[Transform3D]:
	var a := anim.get_animation(clip)
	var skel_path := String(_model.get_path_to(skeleton))
	var out: Array[Transform3D] = []
	out.resize(skeleton.get_bone_count())
	for b in skeleton.get_bone_count():  # parents come before children
		var local := skeleton.get_bone_rest(b)
		var path := NodePath("%s:%s" % [skel_path, skeleton.get_bone_name(b)])
		var rt := a.find_track(path, Animation.TYPE_ROTATION_3D)
		if rt >= 0:
			local.basis = Basis(a.rotation_track_interpolate(rt, t))
		var pt := a.find_track(path, Animation.TYPE_POSITION_3D)
		if pt >= 0:
			local.origin = a.position_track_interpolate(pt, t)
		var parent := skeleton.get_bone_parent(b)
		out[b] = out[parent] * local if parent >= 0 else local
	return out


## Local transform under a BoneAttachment3D for `bone` that puts a child at `body_xf`
## (in this node's space) while the skeleton is in its current pose.
func _attach_local(bone: int, body_xf: Transform3D) -> Transform3D:
	var bone_body := global_transform.affine_inverse() * skeleton.global_transform * _pose[bone]
	return bone_body.affine_inverse() * body_xf


func _tune_materials(root: Node, rim := false) -> void:
	var rim_mat: ShaderMaterial
	if rim:
		rim_mat = ShaderMaterial.new()
		rim_mat.shader = preload("res://scripts/shaders/rim_glow.gdshader")
		rim_mat.set_shader_parameter("rim_color", rim_color)
		rim_mat.set_shader_parameter("strength", rim_strength)
		rim_mat.set_shader_parameter("power", rim_power)
	for m in root.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i) as StandardMaterial3D
			if mat == null:
				continue
			mat = mat.duplicate()
			mat.metallic = metal_scale
			mat.albedo_color = Color(albedo_lift, albedo_lift, albedo_lift)
			mat.emission_energy_multiplier = glow_energy
			mat.next_pass = rim_mat
			mi.set_surface_override_material(i, mat)


## Shadows come from a simple stand-in, not the 31k-triangle model: on HIGH every shadowed
## lamp nearby re-renders shadow casters into six cube faces each frame, and the full model
## (plus two detailed weapons) made that heavy enough to stall some GPUs.
func _use_shadow_proxy() -> void:
	for root in [_model, rifle, blade]:
		if root == null:
			continue
		for m in root.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var proxy := MeshInstance3D.new()
	proxy.name = "ShadowProxy"
	var cap := CapsuleMesh.new()
	cap.radius = 0.24
	cap.height = 1.75 * body_scale
	cap.radial_segments = 8
	cap.rings = 2
	proxy.mesh = cap
	proxy.position = Vector3(0, cap.height * 0.5, 0)
	proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	add_child(proxy)


## A soft light above and behind her (see rim_light_color).
func _add_rim_light() -> void:
	var l := OmniLight3D.new()
	l.name = "RimLight"
	l.position = Vector3(0.0, 2.6, 1.1)
	l.light_color = rim_light_color
	l.light_energy = rim_light_energy
	l.omni_range = 3.2
	l.shadow_enabled = false
	l.light_volumetric_fog_energy = 0.0  # a moving light in the volumetric fog is costly
	add_child(l)
