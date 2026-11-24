"""Burster: a bloated runner carrying a volatile glowing sac. Exports a .glb.

Run (either works):
    blender -b -P art_src/blender/build_burster.py -- [--preview DIR]
    python art_src/blender/build_burster.py [--preview DIR]      # with `pip install bpy`

Output: assets/models/enemies/burster.glb
Clips:  idle (loop, the sac throbs), walk (loop, one stride cycle),
        swell (one-shot, 0.53 s: braces and inflates before it blows; matches the fuse)
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402
from hexapod import Hexapod  # noqa: E402
from mathutils import Vector  # noqa: E402

GLOW = (0.75, 1.0, 0.12)  # acid lime, matches the concept sheet
X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)

# ---------------------------------------------------------------------------
# Proportions (meters). Sac ~0.8 across and ~0.9 tall at the top, legs span ~1.3.
# ---------------------------------------------------------------------------
THORAX = ((0.0, 0.14, 0.26), (0.17, 0.17, 0.11))
HEAD = ((0.0, 0.34, 0.23), (0.12, 0.11, 0.075))
SAC_C = (0.0, -0.12, 0.53)
SAC_R = (0.37, 0.41, 0.35)

LEGS = {
    "front": (0.22, 0.10, 0.28, 0.38),
    "mid": (0.08, 0.00, 0.02, 0.32),
    "back": (-0.04, -0.12, -0.27, 0.38),
}
HEX = Hexapod(LEGS, hip_x=0.15, knee_x=0.43, foot_x=0.56, hip_z=0.25, knee_z=0.44,
              femur_radii=(0.055, 0.05, 0.042), tibia_width=0.05, tibia_thickness=0.045)


def sac_point(theta, phi, lift=1.0):
    """Point on the sac surface. theta: 0 = front, pi = back (over the top); phi: 0 = top."""
    cx, cy, cz = SAC_C
    rx, ry, rz = SAC_R
    return (cx + rx * lift * math.sin(theta) * math.sin(phi),
            cy + ry * lift * math.cos(theta),
            cz + rz * lift * math.sin(theta) * math.cos(phi))


# ---------------------------------------------------------------------------
# Mesh
# ---------------------------------------------------------------------------

def build_parts():
    P = []
    C, G = "Chitin", "Glow"

    P.append(kit.ellipsoid("thorax", "body", C, *THORAX))
    P.append(kit.ellipsoid("head", "head", C, *HEAD, pinch_front=0.6))

    # the sac: big glowing ellipsoid...
    P.append(kit.ellipsoid("sac", "sac", G, SAC_C, SAC_R, segments=18, rings=11))
    # ...veined with thin, wandering chitin ridges that break the glow into cells
    for k, phi in enumerate((-1.25, -0.75, -0.25, 0.25, 0.75, 1.25)):
        pts = [sac_point(math.radians(a), phi + 0.13 * math.sin(math.radians(a) * 3.0 + k * 1.7), 1.012)
               for a in range(64, 173, 12)]
        P.append(kit.tube(f"vein_{k}", "sac", C, pts, [0.017] * (len(pts) - 1) + [0.0], sides=4))
    pts = [sac_point(1.95 + 0.12 * math.sin(math.radians(a) * 0.08), math.radians(a), 1.012)
           for a in range(-120, 121, 20)]
    P.append(kit.tube("vein_belt", "sac", C, pts, [0.015] * len(pts), sides=4, tip=False))

    # armour: chitin plates shingled over the front and top of the sac, tips pointing back
    for k, (theta, phis, width, length) in enumerate((
            (0.42, (0.0,), 0.2, 0.3),
            (0.62, (-0.62, 0.62), 0.16, 0.27),
            (0.88, (0.0,), 0.19, 0.3),
            (1.02, (-0.85, 0.85), 0.14, 0.24),
            (1.3, (-0.42, 0.42), 0.14, 0.24))):
        for phi in phis:
            base = Vector(sac_point(theta, phi, 0.96))
            ahead = Vector(sac_point(theta + 0.05, phi, 0.96))
            normal = Vector(((base.x - SAC_C[0]) / SAC_R[0] ** 2, (base.y - SAC_C[1]) / SAC_R[1] ** 2,
                             (base.z - SAC_C[2]) / SAC_R[2] ** 2)).normalized()
            P.append(kit.blade(f"plate_{k}_{phi}", "sac", C, base, ahead - base, normal,
                               length=length, width=width, thickness=0.05, curl=0.12, base_round=0.75))
    # crest: a tall spike at the front of the shell and two swept horns
    P.append(kit.blade("crest", "sac", C, sac_point(0.5, 0.0, 0.97), (0, 0.15, 1), (0, 1, 0.2),
                       length=0.22, width=0.06, thickness=0.045, curl=-0.35))
    for s in (-1, 1):
        P.append(kit.blade(f"horn_{s}", "sac", C, sac_point(0.75, s * 0.9, 0.97), (s * 0.8, 0.2, 0.7),
                           (0, 1, 0.3), length=0.16, width=0.045, thickness=0.035, curl=-0.3))
    # collar where the thorax meets the sac
    for s in (-1, 0, 1):
        P.append(kit.blade(f"collar_{s}", "body", C, (s * 0.1, 0.16, 0.33), (s * 0.5, 0.6, 0.25),
                           (0, 0, 1), length=0.16, width=0.07, thickness=0.04, curl=0.1))

    # brow over the face, small lime eyes, short mandibles
    P.append(kit.blade("brow", "head", C, (0, 0.2, 0.31), (0, 1, -0.45), (0, 0.4, 1),
                       length=0.28, width=0.15, thickness=0.05, curl=-0.06, base_round=0.75))
    for s in (-1, 1):
        P.append(kit.ellipsoid(f"eye_{s}", "head", G, (s * 0.058, 0.42, 0.215), (0.026, 0.018, 0.015), 8, 4))
        P.append(kit.blade(f"mandible_{s}", "mand_" + ("L" if s < 0 else "R"), C,
                           (s * 0.05, 0.42, 0.17), (-s * 0.22, 1, -0.25), (0, 0, 1),
                           length=0.11, width=0.028, thickness=0.022, sweep=-s * 0.35))

    P += HEX.parts()
    return P


def build_rig():
    bones = [
        ("body", (0, 0.04, 0.26), (0, 0.22, 0.26), None),
        ("sac", SAC_C, (SAC_C[0], SAC_C[1], SAC_C[2] + 0.3), "body"),
        ("head", (0, 0.25, 0.23), (0, 0.42, 0.23), "body"),
        ("mand_L", (-0.05, 0.42, 0.17), (-0.08, 0.54, 0.14), "head"),
        ("mand_R", (0.05, 0.42, 0.17), (0.08, 0.54, 0.14), "head"),
    ]
    bones += HEX.bones()
    return kit.build_armature("BursterRig", bones)


# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

def anim_idle(rig, frames=48):
    """Slow look-around while the sac throbs like a heartbeat."""
    kit.new_action(rig, "idle")
    for f in range(0, frames + 1, 2):
        w = f / frames * 2 * math.pi
        R, O, S = {}, {}, {}
        HEX.fidget(rig, R, w)
        beat = math.exp(-((math.sin(w * 2) - 1.0) ** 2) * 4.0)  # sharp double-pulse
        S["sac"] = 1.0 + 0.045 * beat
        O["body"] = kit.local_offset(rig, "body", (0, 0, -0.006 + 0.006 * math.sin(w)))
        R["head"] = kit.local_rotation(rig, "head", Z, 0.1 * math.sin(w + 0.6))
        m = 0.1 + 0.08 * math.sin(w * 3)
        R["mand_L"] = kit.local_rotation(rig, "mand_L", Z, m)
        R["mand_R"] = kit.local_rotation(rig, "mand_R", Z, -m)
        kit.key_pose(rig, f, R, O, S)


def anim_walk(rig, frames=16):
    """Tripod scuttle; the heavy sac lags and wobbles."""
    kit.new_action(rig, "walk")
    for f in range(frames + 1):
        t = f / frames
        w = t * 2 * math.pi
        R, O, S = {}, {}, {}
        HEX.walk(rig, R, t, lift=0.38, knee=0.28)
        R["body"] = kit.local_rotation(rig, "body", Y, 0.045 * math.sin(w))
        O["body"] = kit.local_offset(rig, "body", (0, 0, 0.012 * abs(math.sin(w))))
        R["sac"] = kit.local_rotation(rig, "sac", X, 0.05 * math.sin(w * 2 + 1.0)) @ \
            kit.local_rotation(rig, "sac", Y, -0.06 * math.sin(w - 0.8))
        S["sac"] = (1.0 + 0.03 * math.sin(w * 2), 1.0 - 0.02 * math.sin(w * 2), 1.0 + 0.03 * math.sin(w * 2))
        R["head"] = kit.local_rotation(rig, "head", Z, -0.04 * math.sin(w))
        kit.key_pose(rig, f, R, O, S)


def anim_swell(rig):
    """Brace, throb, inflate. Ends on the fullest pose (Godot holds the last frame)."""
    kit.new_action(rig, "swell")
    # (frame, sac scale, crouch, mandibles)
    keys = [(0, 1.0, 0.0, 0.1), (3, 1.12, 0.03, 0.4), (5, 1.05, 0.04, 0.3), (8, 1.18, 0.05, 0.55),
            (10, 1.1, 0.05, 0.45), (13, 1.26, 0.06, 0.7), (16, 1.3, 0.06, 0.75)]
    for f, sac, crouch, mand in keys:
        R, O, S = {}, {}, {}
        S["sac"] = sac
        O["body"] = kit.local_offset(rig, "body", (0, 0, -crouch))
        R["head"] = kit.local_rotation(rig, "head", X, 0.25 * crouch / 0.06)
        R["mand_L"] = kit.local_rotation(rig, "mand_L", Z, mand)
        R["mand_R"] = kit.local_rotation(rig, "mand_R", Z, -mand)
        for leg in LEGS:
            for s in (-1, 1):
                # splay the legs outward and flatten them to brace
                HEX.pose(rig, R, leg, s, 0.0, -crouch * 2.5, -crouch * 2.0)
        kit.key_pose(rig, f, R, O, S)


# ---------------------------------------------------------------------------

SHOTS = [
    ("3q", (1.9, 2.3, 1.45), (0, 0, 0.35), None, 0),
    ("front", (0, 2.9, 0.7), (0, 0, 0.4), None, 0),
    ("side", (2.8, 0.1, 0.7), (0, 0, 0.4), None, 0),
    ("top", (0, -1.3, 3.6), (0, 0, 0.3), None, 0),
    ("walk", (2.1, 1.8, 1.3), (0, 0, 0.35), "walk", 4),
    ("swell", (2.2, 1.4, 1.2), (0, 0, 0.35), "swell", 16),
]


def build(mats):
    rig = build_rig()
    mesh = kit.build_mesh_object("Burster", build_parts(), mats)
    kit.skin(mesh, rig)
    anim_idle(rig)
    anim_walk(rig)
    anim_swell(rig)
    return rig, mesh, SHOTS


kit.run("burster", GLOW, build)
