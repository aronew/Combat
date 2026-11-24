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

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402
from hexapod import Hexapod  # noqa: E402

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
HEX = Hexapod(LEGS, hip_x=0.15, knee_x=0.35, foot_x=0.47, hip_z=0.24, knee_z=0.41)


def top_z(x, y):
    """Height of the body surface above (x, y); used to seat the plates."""
    best = 0.0
    for (cx, cy, cz), (rx, ry, rz) in (THORAX, ABDOMEN, HEAD):
        d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
        if d < 1.0:
            best = max(best, cz + rz * math.sqrt(1.0 - d))
    return best


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

    P += HEX.parts()
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
    bones += HEX.bones()
    return kit.build_armature("SwarmerRig", bones)


# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)


def anim_walk(rig, frames=16):
    kit.new_action(rig, "walk")
    for f in range(frames + 1):
        t = f / frames
        R, O = {}, {}
        HEX.walk(rig, R, t)
        R["body"] = kit.local_rotation(rig, "body", Y, 0.05 * math.sin(t * 2 * math.pi))
        O["body"] = kit.local_offset(rig, "body", (0, 0, 0.014 * abs(math.sin(t * 2 * math.pi))))
        R["abdomen"] = kit.local_rotation(rig, "abdomen", Z, 0.06 * math.sin(t * 2 * math.pi + 1.2))
        R["head"] = kit.local_rotation(rig, "head", Z, -0.04 * math.sin(t * 2 * math.pi))
        kit.key_pose(rig, f, R, O)


def anim_idle(rig, frames=48):
    kit.new_action(rig, "idle")
    for f in range(0, frames + 1, 3):
        w = f / frames * 2 * math.pi
        R, O = {}, {}
        HEX.fidget(rig, R, w)
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
            HEX.pose(rig, R, "front", s, 0.25 * flift, flift, 0.4 * flift)
            HEX.pose(rig, R, "mid", s, 0.0, -0.08 * pitch, 0.0)
            HEX.pose(rig, R, "back", s, -0.05 * flift, -0.1 * pitch, 0.0)
        kit.key_pose(rig, f, R, O)


# ---------------------------------------------------------------------------

SHOTS = [
    ("3q", (1.7, 2.1, 1.25), (0, 0, 0.25), None, 0),
    ("front", (0, 2.6, 0.55), (0, 0, 0.25), None, 0),
    ("top", (0, -1.2, 3.2), (0, 0, 0.25), None, 0),
    ("walk", (1.9, 1.6, 1.1), (0, 0, 0.25), "walk", 4),
    ("attack", (2.1, 0.4, 0.9), (0, 0, 0.25), "attack", 4),
]


def build(mats):
    rig = build_rig()
    mesh = kit.build_mesh_object("Swarmer", build_parts(), mats)
    kit.skin(mesh, rig)
    anim_idle(rig)
    anim_walk(rig)
    anim_attack(rig)
    return rig, mesh, SHOTS


kit.run("swarmer", GLOW, build)
