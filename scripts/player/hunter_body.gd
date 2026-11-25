class_name HunterBody
extends Node3D
## The hunter's animated body: the skinned model, its animation tree and her weapons.
##
## The player drives it with a few calls: `set_move` (direction relative to her facing and
## speed), `set_rifle_mode`, and the one-shot actions `swing`, `roll`, `hit`, `die`. Her legs
## blend between the run clips by direction; with the rifle out, her upper body holds an aimed
## pose on top. Swings, roll and hit reactions are short cuts of library moves, sped up to
## match the game's timing (see art_src/blender/import_hunter.py).
##
## The body faces -Z like the rest of the player's visual.

const MODEL := preload("res://assets/models/hunter/hunter.glb")
const RIFLE := preload("res://assets/models/hunter/hive_rifle.glb")
const BLADE := preload("res://assets/models/hunter/chitin_blade.glb")

## Bones above the waist: the aimed pose and hit reactions only drive these.
const UPPER_BONES := ["Spine01", "Spine", "neck", "Head", "head_end", "headfront",
	"LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand",
	"RightShoulder", "RightArm", "RightForeArm", "RightHand"]

## Running speed (m/s) at which the run clips play at normal speed.
@export var run_clip_speed := 5.5
@export var min_clip_scale := 0.7
@export var max_clip_scale := 1.9
## How long the cut clips should take in game (seconds of real time).
@export var swing_time := 0.2
@export var finisher_time := 0.27
@export var roll_time := 0.38
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
@export var blade_in_hand_rotation := Vector3(0.0, -90.0, 0.0)
@export var rim_light_energy := 0.9
## Material tuning for the generated textures. They are authored as fully metallic, which
## reads as black under the game's dim ambient light (there are no sky reflections to show).
@export var metal_scale := 0.3
@export var albedo_lift := 1.6
## Her red lines are an emission map; this is how hard they glow.
@export var glow_energy := 4.0
## Silhouette rim (see rim_glow.gdshader): makes her read on dark floors from far away.
@export var rim_color := Color(1.0, 0.4, 0.34)
@export var rim_strength := 1.1
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
	set_rifle_mode(true)
	ok = skeleton != null and tree != null and rifle != null and blade != null


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
	if rifle:
		_kick = move_toward(_kick, 0.0, delta * 7.0)
		_place_rifle()


## Gun recoil: pushes the rifle back along the barrel (the player adds body lean on top).
func kick(amount: float) -> void:
	_kick = minf(_kick + amount, 1.6)


## The rifle's muzzle in world space.
func muzzle_position() -> Vector3:
	if rifle == null:
		return global_position + global_transform.basis * Vector3(0.2, 1.1, -0.9)
	return rifle.global_transform * _muzzle_local


## One cut of the combo: step 1..3, the third is the finisher.
func swing(step: int) -> void:
	if tree == null or _dead:
		return
	var finisher := step >= 3
	var clip := "swing_%d" % clampi(step, 1, 3)
	tree.set("parameters/swing_pick/transition_request", clip)
	tree.set("parameters/swing_speed/scale", anim.get_animation(clip).length / (finisher_time if finisher else swing_time))
	tree.set("parameters/swing/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func roll() -> void:
	if tree == null or _dead:
		return
	tree.set("parameters/roll_speed/scale", anim.get_animation("roll_fast").length / roll_time)
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
	for p in ["swing", "roll", "hit"]:
		tree.set("parameters/%s/request" % p, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	tree.set("parameters/life/transition_request", "dead")


func revive() -> void:
	_dead = false
	if tree:
		tree.set("parameters/life/transition_request", "alive")


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
	bt.connect_node("hit", 0, "aim")
	bt.connect_node("hit", 1, "hit_speed")

	# Blade swings: one of three cuts, whole body.
	var pick := AnimationNodeTransition.new()
	pick.xfade_time = 0.0
	for i in 3:
		pick.add_input("swing_%d" % (i + 1))
		bt.add_node("swing_%d" % (i + 1), _clip("swing_%d" % (i + 1)), Vector2(800, 150 + 120 * i))
	bt.add_node("swing_pick", pick, Vector2(1000, 150))
	for i in 3:
		bt.connect_node("swing_pick", i, "swing_%d" % (i + 1))
	bt.add_node("swing_speed", AnimationNodeTimeScale.new(), Vector2(1200, 150))
	bt.connect_node("swing_speed", 0, "swing_pick")
	var swing_shot := AnimationNodeOneShot.new()
	swing_shot.fadein_time = 0.03
	swing_shot.fadeout_time = 0.1
	bt.add_node("swing", swing_shot, Vector2(1400, 0))
	bt.connect_node("swing", 0, "hit")
	bt.connect_node("swing", 1, "swing_speed")

	# Roll: whole body.
	bt.add_node("roll_clip", _clip("roll_fast"), Vector2(1400, 150))
	bt.add_node("roll_speed", AnimationNodeTimeScale.new(), Vector2(1600, 150))
	bt.connect_node("roll_speed", 0, "roll_clip")
	var roll_shot := AnimationNodeOneShot.new()
	roll_shot.fadein_time = 0.03
	roll_shot.fadeout_time = 0.1
	bt.add_node("roll", roll_shot, Vector2(1800, 0))
	bt.connect_node("roll", 0, "swing")
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
	tree.active = true
	tree.set("parameters/loco_speed/scale", 1.0)
	tree.set("parameters/aim/blend_amount", 1.0)
	tree.set("parameters/life/transition_request", "alive")


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


## A soft light above and behind her so the dark chitin reads on dark floors.
func _add_rim_light() -> void:
	var l := OmniLight3D.new()
	l.name = "RimLight"
	l.position = Vector3(0.0, 2.6, 1.1)
	l.light_color = Color(1.0, 0.55, 0.5)
	l.light_energy = rim_light_energy
	l.omni_range = 3.2
	l.shadow_enabled = false
	l.light_volumetric_fog_energy = 0.0  # a moving light in the volumetric fog is costly
	add_child(l)
