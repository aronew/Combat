class_name VfxEffect
extends Node3D
## One pooled visual effect. Its children do the work:
##   GPUParticles3D  restarted on every play (one-shot bursts). Meta "delay"
##                   (seconds) starts it later; meta "ground" snaps it to the floor.
##   VfxPulse        under a mesh or light: animated flash, ring, light pop.
## Nodes get the play colour as the VFX shader's `tint`, unless they carry the
## meta "keep_color" (fire, smoke and debris keep their own colours).
## FX owns the pools; gameplay never instantiates effects directly.
##   FX.play_vfx(&"impact_metal", {"position": p, "direction": normal})
## Play parameters (all optional):
##   position, direction (the effect's -Z points this way), scale, color,
##   intensity, follow (Node3D to stick to while it plays), particles (count mult).

signal finished(effect: VfxEffect)

@export var duration := 1.0
@export var profile: VfxProfile

var active := false
var follow: Node3D

var _t := 0.0
var _emitters: Array[GPUParticles3D] = []
var _pulses: Array[VfxPulse] = []
var _geoms: Array[GeometryInstance3D] = []
var _grounded: Array[Node3D] = []
var _pending: Array = []  # [start time, emitter]

const QUALITY_PARTICLES := [1.0, 0.75, 0.45]


func _ready() -> void:
	for n in find_children("*", "", true, false):
		if n is GPUParticles3D:
			var e := n as GPUParticles3D
			e.one_shot = true
			e.emitting = false
			_emitters.append(e)
		if n is VfxPulse:
			_pulses.append(n)
		if n is GeometryInstance3D:
			var g := n as GeometryInstance3D
			g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # sparks and smoke never need shadows
			# Own copies of the shader materials, so this effect's tint and
			# animation never leak into other pooled effects.
			if g.material_override is ShaderMaterial:
				g.material_override = g.material_override.duplicate()
			_geoms.append(g)
		if n is Node3D and n.has_meta("ground"):
			_grounded.append(n)
	visible = false
	set_process(false)


func play(params := {}) -> void:
	var pos: Vector3 = params.get("position", global_position)
	var dir: Vector3 = params.get("direction", Vector3.ZERO)
	var sc: float = float(params.get("scale", 1.0)) * (profile.scale if profile else 1.0)
	var b := Basis()
	if dir.length_squared() > 0.0001:
		var up := Vector3.UP if absf(dir.normalized().dot(Vector3.UP)) < 0.98 else Vector3.FORWARD
		b = Basis.looking_at(dir, up)
	global_transform = Transform3D(b.scaled(Vector3.ONE * sc), pos)
	for g in _grounded:
		var gp := g.global_position
		g.global_position = Vector3(gp.x, 0.04, gp.z)

	var color: Color = params.get("color", profile.color if profile else Color.WHITE)
	var intensity: float = float(params.get("intensity", 1.0)) * (profile.intensity if profile else 1.0)
	var tinted := Color(color.r * intensity, color.g * intensity, color.b * intensity, 1.0)
	var plain := Color(intensity, intensity, intensity, 1.0)
	for g in _geoms:
		var m := g.material_override as ShaderMaterial
		if m:
			m.set_shader_parameter("tint", plain if g.has_meta("keep_color") else tinted)

	var gfx: Node = get_node_or_null("/root/Graphics")
	var q: float = QUALITY_PARTICLES[clampi(int(gfx.quality), 0, 2)] if gfx else 1.0
	q *= float(params.get("particles", 1.0)) * (profile.particle_mult if profile else 1.0)
	_pending.clear()
	for e in _emitters:
		e.amount_ratio = clampf(q, 0.05, 1.0)
		var d := float(e.get_meta("delay", 0.0))
		if d > 0.0:
			e.emitting = false
			_pending.append([d, e])
		else:
			e.restart()
	for p in _pulses:
		p.start(intensity)

	follow = params.get("follow", null)
	_t = 0.0
	active = true
	visible = true
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	if follow and is_instance_valid(follow):
		global_position = follow.global_position
	for i in range(_pending.size() - 1, -1, -1):
		if _t >= float(_pending[i][0]):
			(_pending[i][1] as GPUParticles3D).restart()
			_pending.remove_at(i)
	for p in _pulses:
		p.tick(delta)
	if _t >= duration:
		stop()


func stop() -> void:
	active = false
	visible = false
	follow = null
	set_process(false)
	for e in _emitters:
		e.emitting = false
	finished.emit(self)


## Live particle estimate (for the arena's stats overlay).
func particle_estimate() -> int:
	if not active:
		return 0
	var n := 0
	for e in _emitters:
		# one-shot emitters clear `emitting` once they have spawned, so go by lifetime
		var start := float(e.get_meta("delay", 0.0))
		if _t >= start and _t < start + e.lifetime:
			n += int(e.amount * e.amount_ratio)
	return n
