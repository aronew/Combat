"""Shared parts kit for the hive bugs.

Every enemy is assembled from the same few primitives so the roster reads as one
species: tapered limb tubes, pointed chitin "blades" (plates, spikes, claws,
mandibles), ellipsoid body segments and glow orbs.

Conventions (match the Godot side):
- Blender units are meters, Z is up, the bug faces +Y. The glTF exporter turns
  that into Godot's Y-up with the bug facing -Z, which is what enemy.gd expects.
- The origin is on the ground under the body.
- Two material slots only: "Chitin" and "Glow". Godot remaps them to its own
  materials on import, so colours/tiers stay tunable in the engine.
- Rigid skinning: every part is weighted 100% to a single bone (chitin doesn't
  bend). Parts are tagged with the bone name and joined into one mesh.
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

SHARP_ANGLE = math.radians(38.0)


# ---------------------------------------------------------------------------
# Scene / materials
# ---------------------------------------------------------------------------

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def make_materials(glow_rgb):
    chitin = bpy.data.materials.new("Chitin")
    chitin.use_nodes = True
    b = chitin.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.105, 0.075, 0.062, 1.0)
    b.inputs["Metallic"].default_value = 0.3
    b.inputs["Roughness"].default_value = 0.38

    glow = bpy.data.materials.new("Glow")
    glow.use_nodes = True
    g = glow.node_tree.nodes["Principled BSDF"]
    g.inputs["Base Color"].default_value = (*glow_rgb, 1.0)
    g.inputs["Emission Color"].default_value = (*glow_rgb, 1.0)
    g.inputs["Emission Strength"].default_value = 3.5
    return {"Chitin": chitin, "Glow": glow}


# ---------------------------------------------------------------------------
# Part builders. Each returns a Part (a bmesh + material + bone tag).
# ---------------------------------------------------------------------------

class Part:
    def __init__(self, name, bone, material):
        self.name = name
        self.bone = bone
        self.material = material
        self.bm = bmesh.new()


def _frame(forward, up):
    f = Vector(forward).normalized()
    u = Vector(up)
    s = f.cross(u).normalized()
    u = s.cross(f).normalized()
    return f, u, s


def blade(name, bone, material, base, forward, up, length, width, thickness,
          curl=0.0, sweep=0.0, sections=6, base_round=0.25):
    """A pointed chitin blade: diamond cross-section tapering to a tip.

    Used for carapace plates, spikes, claws and mandibles.
    curl bends the blade toward `up` along its length, sweep toward its side.
    """
    p = Part(name, bone, material)
    bm = p.bm
    f, u, s = _frame(forward, up)
    base = Vector(base)
    rings = []
    for i in range(sections + 1):
        t = i / sections
        # width profile: rounded base, pointed tip
        w = width * (1.0 - t) ** 0.85 * (base_round + (1.0 - base_round) * math.sin(min(1.0, t * 3.0 + 0.35) * math.pi * 0.5))
        h = thickness * (1.0 - t) ** 0.7
        c = base + f * (t * length) + u * (curl * length * t * t) + s * (sweep * length * t * t)
        if i == sections:
            rings.append([bm.verts.new(c)])
            break
        ring = [
            bm.verts.new(c + s * w),
            bm.verts.new(c + u * h),
            bm.verts.new(c - s * w),
            bm.verts.new(c - u * h * 0.35),
        ]
        rings.append(ring)
    # base cap
    bm.faces.new(list(reversed(rings[0])))
    for a, b in zip(rings[:-1], rings[1:]):
        n = len(a)
        for k in range(n):
            k2 = (k + 1) % n
            if len(b) == 1:
                bm.faces.new((a[k], a[k2], b[0]))
            else:
                bm.faces.new((a[k], a[k2], b[k2], b[k]))
    return p


def tube(name, bone, material, points, radii, sides=6, tip=True):
    """A tapered limb along a polyline. Ends in a point if tip is True."""
    p = Part(name, bone, material)
    bm = p.bm
    pts = [Vector(v) for v in points]
    rings = []
    prev_n = None
    for i, c in enumerate(pts):
        if i == 0:
            tan = (pts[1] - pts[0]).normalized()
        elif i == len(pts) - 1:
            tan = (pts[-1] - pts[-2]).normalized()
        else:
            tan = ((pts[i + 1] - pts[i]).normalized() + (pts[i] - pts[i - 1]).normalized()).normalized()
        if tip and i == len(pts) - 1:
            rings.append([bm.verts.new(c)])
            break
        ref = Vector((0, 0, 1)) if abs(tan.z) < 0.9 else Vector((1, 0, 0))
        n1 = tan.cross(ref).normalized() if prev_n is None else (prev_n - tan * prev_n.dot(tan)).normalized()
        prev_n = n1
        n2 = tan.cross(n1)
        r = radii[i]
        rings.append([bm.verts.new(c + (n1 * math.cos(a) + n2 * math.sin(a)) * r)
                      for a in (2 * math.pi * k / sides for k in range(sides))])
    bm.faces.new(list(reversed(rings[0])))
    for a, b in zip(rings[:-1], rings[1:]):
        n = len(a)
        for k in range(n):
            k2 = (k + 1) % n
            if len(b) == 1:
                bm.faces.new((a[k], a[k2], b[0]))
            else:
                bm.faces.new((a[k], a[k2], b[k2], b[k]))
    if len(rings[-1]) > 1:
        bm.faces.new(rings[-1])
    return p


def ellipsoid(name, bone, material, center, radii, segments=12, rings=7, pinch_front=0.0):
    """Low-poly ellipsoid body segment. pinch_front narrows the +Y end."""
    p = Part(name, bone, material)
    bm = p.bm
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    c = Vector(center)
    for v in bm.verts:
        x, y, z = v.co
        k = 1.0 - pinch_front * max(0.0, y)
        v.co = Vector((x * radii[0] * k, y * radii[1], z * radii[2] * k)) + c
    return p


def orb(name, bone, material, center, radius, segments=8, rings=5):
    return ellipsoid(name, bone, material, center, (radius, radius, radius), segments, rings)


def mirror_x(v):
    return Vector((-v[0], v[1], v[2]))


# ---------------------------------------------------------------------------
# Assembly
# ---------------------------------------------------------------------------

def build_mesh_object(name, parts, materials):
    """Join parts into one mesh with material slots and one vertex group per bone."""
    mat_order = ["Chitin", "Glow"]
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for m in mat_order:
        mesh.materials.append(materials[m])

    out = bmesh.new()
    deform = out.verts.layers.deform.verify()
    bone_names = []
    for part in parts:
        if part.bone not in bone_names:
            bone_names.append(part.bone)
        gi = bone_names.index(part.bone)
        mi = mat_order.index(part.material)
        vmap = {}
        for v in part.bm.verts:
            nv = out.verts.new(v.co)
            nv[deform][gi] = 1.0
            vmap[v] = nv
        for f in part.bm.faces:
            try:
                nf = out.faces.new([vmap[v] for v in f.verts])
            except ValueError:
                continue
            nf.material_index = mi
        part.bm.free()
    bmesh.ops.recalc_face_normals(out, faces=out.faces)
    # smooth shading with sharp creases between chitin facets
    for f in out.faces:
        f.smooth = True
    for e in out.edges:
        if len(e.link_faces) == 2 and e.calc_face_angle(0.0) > SHARP_ANGLE:
            e.smooth = False
    out.to_mesh(mesh)
    out.free()
    for bn in bone_names:
        obj.vertex_groups.new(name=bn)
    return obj


def build_armature(name, bones):
    """bones: list of (name, head, tail, parent_name_or_None)."""
    arm = bpy.data.armatures.new(name)
    rig = bpy.data.objects.new(name, arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for bname, head, tail, parent in bones:
        eb = arm.edit_bones.new(bname)
        eb.head = Vector(head)
        eb.tail = Vector(tail)
        eb.roll = 0.0
        if parent:
            eb.parent = arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
    return rig


def skin(mesh_obj, rig):
    mesh_obj.parent = rig
    mod = mesh_obj.modifiers.new("Armature", "ARMATURE")
    mod.object = rig


# ---------------------------------------------------------------------------
# Animation helpers
# ---------------------------------------------------------------------------

def local_rotation(rig, bone_name, axis, angle):
    """Rotation about an armature-space axis through the bone's head,
    expressed as that bone's local pose rotation."""
    r = rig.data.bones[bone_name].matrix_local.to_quaternion()
    q = Quaternion(Vector(axis).normalized(), angle)
    return r.inverted() @ q @ r


def local_offset(rig, bone_name, offset):
    """Armature-space translation expressed in the bone's local space."""
    r = rig.data.bones[bone_name].matrix_local.to_quaternion()
    return r.inverted() @ Vector(offset)


def new_action(rig, name):
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    if rig.animation_data is None:
        rig.animation_data_create()
    rig.animation_data.action = act
    return act


def key_pose(rig, frame, rotations, offsets=None):
    """rotations: {bone: Quaternion}; offsets: {bone: Vector (local)}.
    Bones not listed are keyed at rest so every clip drives every bone."""
    offsets = offsets or {}
    for pb in rig.pose.bones:
        pb.rotation_quaternion = rotations.get(pb.name, Quaternion())
        pb.location = offsets.get(pb.name, Vector())
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        pb.keyframe_insert("location", frame=frame)


def export_glb(path):
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_yup=True,
        export_apply=False,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_skins=True,
        export_def_bones=False,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )
