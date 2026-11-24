"""Six-legged walker shared by most hive bugs: leg layout, geometry, bones and gait.

A bug describes its legs once (hip/knee/foot placement per pair) and gets
matching leg meshes, bones and poses for idle/walk/attack clips.
"""

import math

from mathutils import Vector

import kit

Z = (0, 0, 1)

# Alternating tripod gait: these three legs share a phase, the other three are half a cycle off.
TRIPOD = {("front", -1): 0.0, ("mid", 1): 0.0, ("back", -1): 0.0,
          ("front", 1): 0.5, ("mid", -1): 0.5, ("back", 1): 0.5}


class Hexapod:
    def __init__(self, legs, hip_x, knee_x, foot_x, hip_z, knee_z, parent="body",
                 femur_radii=(0.05, 0.045, 0.038), tibia_width=0.045, tibia_thickness=0.04,
                 tibia_curl=0.14, knee_spike=0.08):
        """legs: {"front"|"mid"|"back": (hip y, knee dy, foot dy, swing amplitude)}"""
        self.legs = legs
        self.hip_x, self.knee_x, self.foot_x = hip_x, knee_x, foot_x
        self.hip_z, self.knee_z = hip_z, knee_z
        self.parent = parent
        self.femur_radii = femur_radii
        self.tibia_width = tibia_width
        self.tibia_thickness = tibia_thickness
        self.tibia_curl = tibia_curl
        self.knee_spike = knee_spike

    @staticmethod
    def bone(leg, side, seg):
        return f"leg_{leg}_{'L' if side < 0 else 'R'}_{seg}"

    def points(self, leg, side):
        hy, kdy, fdy, _ = self.legs[leg]
        hip = Vector((side * self.hip_x, hy, self.hip_z))
        knee = Vector((side * self.knee_x, hy + kdy, self.knee_z))
        foot = Vector((side * self.foot_x, hy + fdy, 0.0))
        return hip, knee, foot

    # -- mesh / rig --------------------------------------------------------

    def parts(self, material="Chitin"):
        """Thick femur tube, sickle-shaped tibia blade and a knee spike per leg."""
        P = []
        for leg in self.legs:
            for s in (-1, 1):
                hip, knee, foot = self.points(leg, s)
                hip_in = hip + Vector((-s * 0.06, 0, 0))
                mid = hip.lerp(knee, 0.5) + Vector((0, 0, 0.025))
                P.append(kit.tube(f"femur_{leg}_{s}", self.bone(leg, s, "up"), material,
                                  [hip_in, mid, knee], list(self.femur_radii), sides=6, tip=False))
                P.append(kit.blade(f"tibia_{leg}_{s}", self.bone(leg, s, "lo"), material, knee,
                                   foot - knee, Vector((s, 0, 0)), length=(foot - knee).length * 1.03,
                                   width=self.tibia_width, thickness=self.tibia_thickness,
                                   curl=self.tibia_curl, sections=6, base_round=0.9))
                if self.knee_spike > 0.0:
                    P.append(kit.blade(f"knee_spike_{leg}_{s}", self.bone(leg, s, "up"), material,
                                       knee + Vector((0, 0, 0.015)), (s * 0.45, -0.55, 0.7), (0, 0, 1),
                                       length=self.knee_spike, width=0.025, thickness=0.02, curl=0.2))
        return P

    def bones(self):
        out = []
        for leg in self.legs:
            for s in (-1, 1):
                hip, knee, foot = self.points(leg, s)
                out.append((self.bone(leg, s, "up"), hip, knee, self.parent))
                out.append((self.bone(leg, s, "lo"), knee, foot, self.bone(leg, s, "up")))
        return out

    # -- posing ------------------------------------------------------------

    def pose(self, rig, R, leg, s, yaw, lift, knee):
        """yaw > 0 swings the foot forward; lift > 0 raises the leg; knee > 0 tucks the foot."""
        lift_axis = Vector((s, 0, 0)).cross(Vector(Z))
        up = self.bone(leg, s, "up")
        lo = self.bone(leg, s, "lo")
        R[up] = kit.local_rotation(rig, up, Z, s * yaw) @ kit.local_rotation(rig, up, lift_axis, lift)
        R[lo] = kit.local_rotation(rig, lo, lift_axis, -knee)

    def walk(self, rig, R, t, lift=0.42, knee=0.3):
        """Tripod gait at cycle position t in [0, 1)."""
        for (leg, s), ph in TRIPOD.items():
            amp = self.legs[leg][3]
            u = (t + ph) % 1.0
            if u < 0.5:  # stance: foot planted, sweeps backward
                self.pose(rig, R, leg, s, amp * (1.0 - 4.0 * u), 0.0, 0.0)
            else:  # swing: lift and reach forward
                w = (u - 0.5) * 2.0
                self.pose(rig, R, leg, s, -amp * math.cos(w * math.pi),
                          lift * math.sin(w * math.pi), knee * math.sin(w * math.pi))

    def fidget(self, rig, R, w, amount=1.0):
        """Small idle leg shuffles at angle w (radians through the idle loop)."""
        for i, (leg, s) in enumerate(TRIPOD):
            self.pose(rig, R, leg, s, 0.035 * amount * math.sin(w + i * 1.3),
                      0.03 * amount * max(0.0, math.sin(w * 2 + i)), 0.0)
