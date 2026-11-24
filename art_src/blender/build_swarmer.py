"""Swarmer: the fodder bug. Builds the mesh, rig and clips, exports a .glb.

Run (either works):
    blender -b -P art_src/blender/build_swarmer.py -- [--preview DIR]
    python art_src/blender/build_swarmer.py [--preview DIR]      # with `pip install bpy`

Output: assets/models/enemies/swarmer.glb
Clips:  idle (loop), walk (loop, one stride cycle), attack (one-shot bite)
"""

import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(REPO, "assets", "models", "enemies", "swarmer.glb")

GLOW = (1.0, 0.36, 0.03)  # amber, matches the concept sheet
FPS = 30

# ---------------------------------------------------------------------------
# Proportions (meters). Body length ~0.95, legs span ~1.2, top of plates ~0.55.
# ---------------------------------------------------------------------------
THORAX = ((0.0, 0.05, 0.25), (0.18, 0.19, 0.10))
ABDOMEN = ((0.0, -0.25, 0.27), (0.23, 0.29, 0.13))
HEAD = ((0.0, 0.25, 0.23), (0.12, 0.12, 0.075))

# name: (hip y, knee dy, foot dy, swing amplitude)
LEGS = {
    "front": (0.14, 0.10, 0.27, 0.40),
    "mid": (0.00, 0.00, 0.02, 0.34),
    "back": (-0.13, -0.10, -0.27, 0.40),
}
HIP_X, KNEE_X, FOOT_X = 0.15, 0.35, 0.47
HIP_Z, KNEE_Z = 0.24, 0.41


def top_z(x, y):
    """Height of the body surface above (x, y); used to seat the plates."""
    best = 0.0
    for (cx, cy, cz), (rx, ry, rz) in (THORAX, ABDOMEN, HEAD):
        d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
        if d < 1.0:
            best = max(best, cz + rz * math.sqrt(1.0 - d))
    return best


def leg_points(name, side):
    hy, kdy, fdy, _ = LEGS[name]
    hip = Vector((side * HIP_X, hy, HIP_Z))
    knee = Vector((side * KNEE_X, hy + kdy, KNEE_Z))
    foot = Vector((side * FOOT_X, hy + fdy, 0.0))
    return hip, knee, foot


def bone_name(leg, side, seg):
    return f"leg_{leg}_{'L' if side < 0 else 'R'}_{seg}"


# ---------------------------------------------------------------------------
# Mesh
# ---------------------------------------------------------------------------

def build_parts():
    P = []
    C, G = "Chitin", "Glow"

    # body segments (mostly hidden under the shell; they fill the gaps)
    P.append(kit.ellipsoid("thorax", "body", C, *THORAX))
    P.append(kit.ellipsoid("abdomen", "abdomen", C, *ABDOMEN, segments=12, rings=7))
    P.append(kit.ellipsoid("head", "head", C, *HEAD, pinch_front=0.6))

    # eyes sit low under the brow: two amber slits and two small ones
    for s in (-1, 1):
        P.append(kit.ellipsoid(f"eye_{s}", "head", G, (s * 0.058, 0.335, 0.215), (0.03, 0.02, 0.017), 8, 4))
        P.append(kit.orb(f"eye_small_{s}", "head", G, (s * 0.1, 0.29, 0.235), 0.014, 6, 4))

    # brow: a broad armoured plate over the head, ending in a point at the front
    P.append(kit.blade("brow", "head", C, (0, 0.13, 0.31), (0, 1, -0.42), (0, 0.4, 1),
                       length=0.30, width=0.16, thickness=0.05, curl=-0.06, base_round=0.75))
    for s in (-1, 1):
        P.append(kit.blade(f"cheek_{s}", "head", C, (s * 0.07, 0.2, 0.28), (s * 0.35, 1, -0.55), (s * 0.6, 0.2, 1),
                           length=0.18, width=0.07, thickness=0.035, curl=-0.05, base_round=0.7))
    # crest: one tall spike and two short ones, swept back
    P.append(kit.blade("crest", "head", C, (0, 0.2, 0.33), (0, -0.35, 1), (0, 1, 0.3),
                       length=0.17, width=0.05, thickness=0.035, curl=-0.3))
    for s in (-1, 1):
        P.append(kit.blade(f"crest_{s}", "head", C, (s * 0.06, 0.18, 0.31), (s * 0.55, -0.45, 0.75), (0, 1, 0.3),
                           length=0.12, width=0.04, thickness=0.03, curl=-0.25))

    # mandibles curving inward
    for s in (-1, 1):
        P.append(kit.blade(f"mandible_{s}", "mand_" + ("L" if s < 0 else "R"), C,
                           (s * 0.05, 0.34, 0.17), (-s * 0.22, 1, -0.25), (0, 0, 1),
                           length=0.13, width=0.03, thickness=0.024, sweep=-s * 0.35))

    # carapace: broad plates shingled backward along the spine...
    for k, y in enumerate((0.16, 0.0, -0.16, -0.32)):
        bone = "body" if y > -0.1 else "abdomen"
        P.append(kit.blade(f"shell_{k}", bone, C, (0, y, top_z(0, y) - 0.03), (0, -1, 0.32), (0, 0.3, 1),
                           length=0.30, width=0.15 - 0.012 * k, thickness=0.055, curl=0.12, base_round=0.7))
    # ...and flank plates draping over the sides, their tips form the spiky fringe
    for k, y in enumerate((0.1, -0.06, -0.22, -0.38)):
        bone = "body" if y > -0.1 else "abdomen"
        for s in (-1, 1):
            x = s * (0.11 if k < 3 else 0.07)
            P.append(kit.blade(f"flank_{k}_{s}", bone, C, (x, y, top_z(x, y) - 0.035),
                               (s * 0.85, -0.7, 0.05), (s * 0.5, 0, 1),
                               length=0.25 - 0.02 * k, width=0.1, thickness=0.045, curl=0.1, base_round=0.7))
    # tail spike
    P.append(kit.blade("tail", "abdomen", C, (0, -0.5, 0.27), (0, -1, 0.15), (0, 0, 1),
                       length=0.13, width=0.05, thickness=0.04, curl=0.1))
    # glow seams peeking between the shell plates: the amber that reads from the top-down camera
    for s in (-1, 1):
        for y, r in ((-0.06, 0.05), (-0.23, 0.058)):
            P.append(kit.ellipsoid(f"seam_{y}_{s}", "body" if y > -0.1 else "abdomen", G,
                                   (s * 0.085, y, top_z(s * 0.085, y) + 0.005), (r, r * 1.35, 0.03), 8, 4))

    # legs: thick femur + sickle tibia + knee spike
    for leg in LEGS:
        for s in (-1, 1):
            hip, knee, foot = leg_points(leg, s)
            hip_in = hip + Vector((-s * 0.06, 0, 0))
            mid = hip.lerp(knee, 0.5) + Vector((0, 0, 0.025))
            P.append(kit.tube(f"femur_{leg}_{s}", bone_name(leg, s, "up"), C,
                              [hip_in, mid, knee], [0.05, 0.045, 0.038], sides=6, tip=False))
            out = Vector((s, 0, 0))
            P.append(kit.blade(f"tibia_{leg}_{s}", bone_name(leg, s, "lo"), C, knee,
                               foot - knee, out, length=(foot - knee).length * 1.03,
                               width=0.045, thickness=0.04, curl=0.14, sections=6, base_round=0.9))
            P.append(kit.blade(f"knee_spike_{leg}_{s}", bone_name(leg, s, "up"), C,
                               knee + Vector((0, 0, 0.015)), (s * 0.45, -0.55, 0.7), (0, 0, 1),
                               length=0.08, width=0.025, thickness=0.02, curl=0.2))
    return P


# ---------------------------------------------------------------------------
# Rig
# ---------------------------------------------------------------------------

def build_rig():
    bones = [
        ("body", (0, -0.02, 0.25), (0, 0.16, 0.25), None),
        ("abdomen", (0, -0.06, 0.27), (0, -0.40, 0.27), "body"),
        ("head", (0, 0.16, 0.23), (0, 0.34, 0.23), "body"),
        ("mand_L", (-0.05, 0.34, 0.17), (-0.08, 0.47, 0.14), "head"),
        ("mand_R", (0.05, 0.34, 0.17), (0.08, 0.47, 0.14), "head"),
    ]
    for leg in LEGS:
        for s in (-1, 1):
            hip, knee, foot = leg_points(leg, s)
            bones.append((bone_name(leg, s, "up"), hip, knee, "body"))
            bones.append((bone_name(leg, s, "lo"), knee, foot, bone_name(leg, s, "up")))
    return kit.build_armature("SwarmerRig", bones)


# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)


def leg_pose(rig, R, leg, s, yaw, lift, knee):
    """yaw > 0 swings the foot forward; lift > 0 raises the leg; knee > 0 tucks the foot."""
    hip, kn, foot = leg_points(leg, s)
    d = Vector((s, 0, 0))
    lift_axis = d.cross(Vector(Z))
    up = bone_name(leg, s, "up")
    lo = bone_name(leg, s, "lo")
    R[up] = kit.local_rotation(rig, up, Z, s * yaw) @ kit.local_rotation(rig, up, lift_axis, lift)
    R[lo] = kit.local_rotation(rig, lo, lift_axis, -knee)


TRIPOD = {("front", -1): 0.0, ("mid", 1): 0.0, ("back", -1): 0.0,
          ("front", 1): 0.5, ("mid", -1): 0.5, ("back", 1): 0.5}


def anim_walk(rig, frames=16):
    kit.new_action(rig, "walk")
    for f in range(frames + 1):
        t = f / frames
        R, O = {}, {}
        for (leg, s), ph in TRIPOD.items():
            amp = LEGS[leg][3]
            u = (t + ph) % 1.0
            if u < 0.5:  # stance: foot planted, sweeps backward
                yaw = amp * (1.0 - 4.0 * u)
                lift = 0.0
                kn = 0.0
            else:  # swing: lift and reach forward
                w = (u - 0.5) * 2.0
                yaw = -amp * math.cos(w * math.pi)
                lift = 0.42 * math.sin(w * math.pi)
                kn = 0.3 * math.sin(w * math.pi)
            leg_pose(rig, R, leg, s, yaw, lift, kn)
        roll = 0.05 * math.sin(t * 2 * math.pi)
        R["body"] = kit.local_rotation(rig, "body", Y, roll)
        O["body"] = kit.local_offset(rig, "body", (0, 0, 0.014 * abs(math.sin(t * 2 * math.pi))))
        R["abdomen"] = kit.local_rotation(rig, "abdomen", Z, 0.06 * math.sin(t * 2 * math.pi + 1.2))
        R["head"] = kit.local_rotation(rig, "head", Z, -0.04 * math.sin(t * 2 * math.pi))
        kit.key_pose(rig, f, R, O)


def anim_idle(rig, frames=48):
    kit.new_action(rig, "idle")
    for f in range(0, frames + 1, 3):
        t = f / frames
        w = t * 2 * math.pi
        R, O = {}, {}
        for i, ((leg, s), _) in enumerate(TRIPOD.items()):
            leg_pose(rig, R, leg, s, 0.035 * math.sin(w + i * 1.3), 0.03 * max(0.0, math.sin(w * 2 + i)), 0.0)
        O["body"] = kit.local_offset(rig, "body", (0, 0, -0.008 + 0.008 * math.sin(w)))
        R["abdomen"] = kit.local_rotation(rig, "abdomen", X, 0.05 * math.sin(w))
        R["head"] = kit.local_rotation(rig, "head", Z, 0.12 * math.sin(w + 0.6)) @ \
            kit.local_rotation(rig, "head", X, 0.04 * math.sin(w * 2))
        m = 0.12 + 0.12 * math.sin(w * 3)
        R["mand_L"] = kit.local_rotation(rig, "mand_L", Z, m)
        R["mand_R"] = kit.local_rotation(rig, "mand_R", Z, -m)
        kit.key_pose(rig, f, R, O)


def anim_attack(rig):
    """Rear up with mandibles open, lunge and snap, recover. 0.4 s."""
    kit.new_action(rig, "attack")
    # (frame, pitch, forward, mandible, front lift)
    keys = [(0, 0.0, 0.0, 0.1, 0.0), (4, 0.32, -0.04, 0.55, 0.75), (6, -0.22, 0.12, -0.12, 0.1),
            (8, -0.12, 0.08, -0.05, 0.0), (12, 0.0, 0.0, 0.1, 0.0)]
    for f, pitch, fwd, mand, flift in keys:
        R, O = {}, {}
        R["body"] = kit.local_rotation(rig, "body", X, pitch)
        O["body"] = kit.local_offset(rig, "body", (0, fwd, 0.04 * max(pitch, 0.0)))
        R["abdomen"] = kit.local_rotation(rig, "abdomen", X, -pitch * 0.6)
        R["head"] = kit.local_rotation(rig, "head", X, -pitch * 0.4)
        R["mand_L"] = kit.local_rotation(rig, "mand_L", Z, mand)
        R["mand_R"] = kit.local_rotation(rig, "mand_R", Z, -mand)
        for s in (-1, 1):
            leg_pose(rig, R, "front", s, 0.25 * flift, flift, 0.4 * flift)
            leg_pose(rig, R, "mid", s, 0.0, -0.08 * pitch, 0.0)
            leg_pose(rig, R, "back", s, -0.05 * flift, -0.1 * pitch, 0.0)
        kit.key_pose(rig, f, R, O)


# ---------------------------------------------------------------------------
# Preview render (Cycles, CPU) for review outside the engine
# ---------------------------------------------------------------------------

def render_preview(rig, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    scn = bpy.context.scene
    scn.render.engine = "CYCLES"
    scn.cycles.device = "CPU"
    scn.cycles.samples = 48
    scn.render.resolution_x, scn.render.resolution_y = 900, 600
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.09, 0.09, 0.095, 1)
    scn.world = world

    bpy.ops.mesh.primitive_plane_add(size=8)
    floor = bpy.context.object
    fm = bpy.data.materials.new("Floor")
    fm.use_nodes = True
    fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.11, 0.11, 0.115, 1)
    floor.data.materials.append(fm)

    def light(kind, loc, energy, color=(1, 1, 1), rot=None, size=1.0):
        ld = bpy.data.lights.new(kind + str(loc), kind)
        ld.energy = energy
        ld.color = color
        if kind == "AREA":
            ld.size = size
        o = bpy.data.objects.new(ld.name, ld)
        o.location = loc
        if rot:
            o.rotation_euler = rot
        scn.collection.objects.link(o)
        return o

    light("SUN", (0, 0, 5), 2.5, rot=(math.radians(35), 0, math.radians(30)))
    light("AREA", (-1.2, -1.5, 1.4), 120, (0.4, 0.8, 1.0), size=1.2)
    light("AREA", (1.5, 1.0, 1.2), 60, (1.0, 0.7, 0.45), size=1.0)

    cam_d = bpy.data.cameras.new("Cam")
    cam = bpy.data.objects.new("Cam", cam_d)
    scn.collection.objects.link(cam)
    scn.camera = cam

    def shoot(name, loc, target=(0, 0, 0.25), lens=50, frame=None, action=None):
        rig.animation_data.action = bpy.data.actions[action] if action else None
        for pb in rig.pose.bones:
            pb.rotation_quaternion = (1, 0, 0, 0)
            pb.location = (0, 0, 0)
        if frame is not None:
            scn.frame_set(frame)
        cam.location = loc
        d = Vector(target) - Vector(loc)
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        cam_d.lens = lens
        scn.render.filepath = os.path.join(out_dir, name + ".png")
        bpy.ops.render.render(write_still=True)
        print("preview:", scn.render.filepath)

    shoot("swarmer_3q", (1.7, 2.1, 1.25))
    shoot("swarmer_front", (0, 2.6, 0.55))
    shoot("swarmer_top", (0, -1.2, 3.2), lens=50)
    shoot("swarmer_walk", (1.9, 1.6, 1.1), action="walk", frame=4)
    shoot("swarmer_attack", (2.1, 0.4, 0.9), action="attack", frame=4)


# ---------------------------------------------------------------------------

def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    preview = argv[argv.index("--preview") + 1] if "--preview" in argv else None

    kit.reset_scene()
    bpy.context.scene.render.fps = FPS
    mats = kit.make_materials(GLOW)
    rig = build_rig()
    mesh = kit.build_mesh_object("Swarmer", build_parts(), mats)
    kit.skin(mesh, rig)
    print("swarmer tris:", sum(len(p.vertices) - 2 for p in mesh.data.polygons))

    anim_idle(rig)
    anim_walk(rig)
    anim_attack(rig)
    rig.animation_data.action = None
    for pb in rig.pose.bones:
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    kit.export_glb(OUT)
    print("exported:", OUT)

    if preview:
        render_preview(rig, preview)


main()
