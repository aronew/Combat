"""Station room kit: modular pieces for hand-built rooms (the look-test hall and the first level).

The look follows the station hall and transit concourse mockups: dark teal-grey floor plates,
curved dark walls lined with magenta neon, round light pillars, big windows onto space,
orange-lit cargo and doors, and pink corruption creeping over the floor.

Every piece snaps to a 2 m grid. Conventions match build_props.py: metres, Z up, a piece's
front faces +Y in Blender (-Z in Godot, toward the room), origin on the floor. Wall pieces
stand on the origin line with their thickness behind it (-Y), so a wall placed on a room's
edge has its face exactly on that edge. Exports one GLB per piece to assets/models/kit/.

    python art_src/blender/build_station_kit.py                  # bpy 5.x module
    python art_src/blender/build_station_kit.py -- --only light_pillar --preview DIR
"""

import math
import os
import sys

import bpy  # must come before bmesh when running as the bpy module
import bmesh  # noqa: E402
from mathutils import Matrix, Vector

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(REPO, "assets", "models", "kit")

# name: (base rgb, metallic, roughness, emission rgb or None, emission strength)
MATERIALS = {
    "FloorPlate": ((0.075, 0.095, 0.10), 0.55, 0.5, None, 0.0),
    "FloorSeam": ((0.02, 0.025, 0.028), 0.4, 0.7, None, 0.0),
    "FloorInset": ((0.10, 0.125, 0.13), 0.5, 0.45, None, 0.0),
    "WallDark": ((0.07, 0.07, 0.085), 0.6, 0.5, None, 0.0),
    "WallPanel": ((0.24, 0.21, 0.25), 0.45, 0.45, None, 0.0),
    "WallTrim": ((0.32, 0.3, 0.34), 0.55, 0.4, None, 0.0),
    "MetalDark": ((0.055, 0.06, 0.065), 0.7, 0.45, None, 0.0),
    "Rubber": ((0.015, 0.015, 0.015), 0.0, 0.85, None, 0.0),
    "HazardYellow": ((0.85, 0.6, 0.04), 0.15, 0.5, None, 0.0),
    "CargoOrange": ((0.38, 0.17, 0.06), 0.4, 0.5, None, 0.0),
    "GlowMagenta": ((1.0, 0.2, 0.6), 0.0, 0.5, (1.0, 0.12, 0.55), 3.0),
    "GlowRed": ((1.0, 0.15, 0.2), 0.0, 0.5, (1.0, 0.1, 0.18), 3.0),
    "GlowAmber": ((1.0, 0.6, 0.2), 0.0, 0.5, (1.0, 0.55, 0.15), 2.5),
    "GlowWhite": ((0.9, 0.95, 1.0), 0.0, 0.5, (0.9, 0.95, 1.0), 4.0),
    "PillarLight": ((0.9, 0.78, 0.82), 0.0, 0.6, (1.0, 0.78, 0.84), 0.65),
    # Replaced in Godot by the animated star-field shader (as on the starship's hull windows).
    "SpaceGlass": ((0.02, 0.03, 0.08), 0.0, 0.1, (0.05, 0.1, 0.3), 1.0),
    "CorruptPink": ((0.75, 0.1, 0.38), 0.0, 0.45, (0.9, 0.1, 0.45), 0.6),
    "CorruptDeep": ((0.32, 0.03, 0.14), 0.0, 0.6, None, 0.0),
    "CorruptTeal": ((0.1, 0.75, 0.7), 0.0, 0.3, (0.1, 0.85, 0.8), 1.2),
}


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def make_materials():
    mats = {}
    for name, (rgb, metal, rough, emit, strength) in MATERIALS.items():
        m = bpy.data.materials.new(name)
        bsdf = m.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Metallic"].default_value = metal
        bsdf.inputs["Roughness"].default_value = rough
        if emit:
            bsdf.inputs["Emission Color"].default_value = (*emit, 1.0)
            bsdf.inputs["Emission Strength"].default_value = strength
        mats[name] = m
    return mats


class Piece:
    """One kit piece: a single bmesh with a material index per part."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.slots = []

    def _tag(self, before, mat, smooth=False):
        if mat not in self.slots:
            self.slots.append(mat)
        idx = self.slots.index(mat)
        for f in set(self.bm.faces) - before:
            f.material_index = idx
            f.smooth = smooth

    def box(self, size, center, mat, bevel=0.02, rot_z=0.0, rot_x=0.0, rot_y=0.0):
        """Box of full size (x, y, z) centred at `center`, edges bevelled."""
        before = set(self.bm.faces)
        m = (Matrix.Translation(Vector(center)) @ Matrix.Rotation(rot_z, 4, "Z")
             @ Matrix.Rotation(rot_y, 4, "Y") @ Matrix.Rotation(rot_x, 4, "X")
             @ Matrix.Diagonal((*size, 1.0)))
        res = bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)
        if bevel > 0.0:
            edges = list({e for v in res["verts"] for e in v.link_edges})
            bmesh.ops.bevel(self.bm, geom=edges, offset=min(bevel, min(size) * 0.45), segments=2,
                            profile=0.5, affect="EDGES", clamp_overlap=True)
        self._tag(before, mat)

    def cyl(self, radius, depth, center, mat, segments=16, radius2=None, axis="Z", smooth=True):
        before = set(self.bm.faces)
        rot = Matrix.Identity(4)
        if axis == "X":
            rot = Matrix.Rotation(math.pi / 2, 4, "Y")
        elif axis == "Y":
            rot = Matrix.Rotation(math.pi / 2, 4, "X")
        m = Matrix.Translation(Vector(center)) @ rot
        bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=segments,
                              radius1=radius, radius2=radius if radius2 is None else radius2,
                              depth=depth, matrix=m)
        self._tag(before, mat, smooth)

    def blob(self, radii, center, mat, segments=10, rings=6, rot_z=0.0):
        before = set(self.bm.faces)
        m = (Matrix.Translation(Vector(center)) @ Matrix.Rotation(rot_z, 4, "Z")
             @ Matrix.Diagonal((*radii, 1.0)))
        bmesh.ops.create_uvsphere(self.bm, u_segments=segments, v_segments=rings, radius=1.0, matrix=m)
        self._tag(before, mat, smooth=True)

    def finish(self, mats):
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for s in self.slots:
            mesh.materials.append(mats[s])
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        return obj


# ---------------------------------------------------------------------------
# Pieces. Front = +Y. Origin on the floor.
# ---------------------------------------------------------------------------

def floor_plate(p):
    """4 x 4 m deck plate, top at z = 0: four inset panels, seams, bolts and a hazard corner."""
    p.box((4.0, 4.0, 0.3), (0, 0, -0.15), "FloorSeam", 0.0)
    for x in (-1.0, 1.0):
        for y in (-1.0, 1.0):
            p.box((1.9, 1.9, 0.06), (x, y, -0.01), "FloorPlate", 0.03)
            p.box((1.1, 1.1, 0.02), (x, y, 0.03), "FloorInset", 0.01)
            for bx in (-0.82, 0.82):
                for by in (-0.82, 0.82):
                    p.cyl(0.035, 0.03, (x + bx, y + by, 0.035), "MetalDark", 6, smooth=False)


def floor_plate_lit(p):
    """Floor plate with a magenta light strip along one seam: guides the eye along a path."""
    floor_plate(p)
    p.box((3.6, 0.12, 0.03), (0, 0, 0.01), "GlowMagenta", 0.0)


def wall_curved(p):
    """4 m wide, 4.5 m tall wall that leans in over the floor like a hull rib, lined with
    magenta neon: a skirting strip, a rib post at each end with a vertical strip."""
    p.box((4.0, 0.6, 0.7), (0, -0.3, 0.35), "WallDark", 0.04)            # plinth
    p.box((4.0, 0.12, 0.06), (0, 0.02, 0.55), "GlowMagenta", 0.0)         # skirting neon
    p.box((3.6, 0.4, 2.0), (0, -0.35, 1.7), "WallPanel", 0.05)            # lower panel
    p.box((3.6, 0.4, 2.2), (0, -0.05, 3.65), "WallPanel", 0.05, rot_x=-0.35)  # upper panel, leaning in
    for x in (-0.6, 0.6):
        p.box((0.9, 0.06, 0.12), (x, -0.12, 2.75), "GlowRed", 0.0)        # small red slots
    for x in (-1.9, 1.9):
        p.box((0.32, 0.8, 4.6), (x, -0.25, 2.3), "WallTrim", 0.05)         # rib posts
        p.box((0.1, 0.06, 3.2), (x, 0.17, 2.3), "GlowMagenta", 0.0)        # rib neon
    p.box((4.0, 1.2, 0.3), (0, 0.2, 4.6), "WallDark", 0.05)               # header beam


def wall_window(p):
    """4 m wall section with a tall window onto space (the glass is the star-field shader)."""
    p.box((4.0, 0.6, 0.7), (0, -0.3, 0.35), "WallDark", 0.04)
    p.box((4.0, 0.12, 0.06), (0, 0.02, 0.55), "GlowMagenta", 0.0)
    p.box((3.4, 0.08, 3.4), (0, -0.4, 2.45), "SpaceGlass", 0.0)
    for x in (-0.55, 0.55):
        p.box((0.1, 0.2, 3.4), (x, -0.3, 2.45), "MetalDark", 0.0)          # mullions
    p.box((3.4, 0.2, 0.1), (0, -0.3, 2.45), "MetalDark", 0.0)
    for x in (-1.9, 1.9):
        p.box((0.32, 0.8, 4.6), (x, -0.25, 2.3), "WallTrim", 0.05)
        p.box((0.1, 0.06, 3.2), (x, 0.17, 2.3), "GlowMagenta", 0.0)
    p.box((4.0, 1.2, 0.3), (0, 0.2, 4.6), "WallDark", 0.05)
    p.box((3.4, 0.5, 0.25), (0, -0.2, 0.82), "WallTrim", 0.03)             # sill


def wall_corner(p):
    """Corner post where two walls meet."""
    p.box((1.0, 1.0, 0.7), (-0.3, -0.3, 0.35), "WallDark", 0.04)
    p.box((0.8, 0.8, 4.8), (-0.3, -0.3, 2.4), "WallTrim", 0.06)
    p.box((0.08, 0.08, 3.6), (0.12, 0.12, 2.3), "GlowMagenta", 0.0)


def door_frame(p):
    """Big orange-lit blast door set in a 4 m wall section (closed)."""
    p.box((4.0, 0.8, 4.8), (0, -0.4, 2.4), "WallDark", 0.04)
    p.box((2.6, 0.5, 3.2), (0, -0.05, 1.6), "CargoOrange", 0.04)
    for x in (-0.75, -0.25, 0.25, 0.75):
        p.box((0.12, 0.06, 2.4), (x, 0.22, 1.6), "GlowAmber", 0.0)        # light slats
    p.box((2.9, 0.3, 0.3), (0, 0.05, 3.35), "WallTrim", 0.03)
    p.box((1.6, 0.06, 0.16), (0, 0.22, 3.35), "GlowAmber", 0.0)
    for x in (-1.45, 1.45):
        p.box((0.3, 0.6, 3.5), (x, 0.0, 1.75), "WallTrim", 0.03)
    for i in range(5):                                                    # hazard sill
        p.box((0.45, 0.6, 0.04), (-1.0 + i * 0.5, 0.35, 0.02), "HazardYellow" if i % 2 == 0 else "Rubber", 0.0)


def light_pillar(p):
    """Round pillar, 1.4 m across and 3.4 m tall: cover and a light source. Lit panels between
    dark ribs, magenta bands top and bottom, an octagonal cap with a vent."""
    p.cyl(0.85, 0.3, (0, 0, 0.15), "WallDark", 8, smooth=False)            # base
    p.box((1.9, 1.9, 0.04), (0, 0, 0.02), "Rubber", 0.0)                   # dark footing plate
    p.cyl(0.82, 0.08, (0, 0, 0.34), "GlowRed", 8, smooth=False)
    p.cyl(0.7, 2.5, (0, 0, 1.65), "PillarLight", 16)                       # lit body
    for k in range(6):
        a = k * math.pi / 3
        p.box((0.16, 0.16, 2.5), (math.cos(a) * 0.68, math.sin(a) * 0.68, 1.65), "WallDark", 0.02, rot_z=a)
    for z in (0.65, 2.55):
        p.cyl(0.74, 0.07, (0, 0, z), "GlowMagenta", 16)
    p.cyl(0.85, 0.5, (0, 0, 3.15), "WallDark", 8, smooth=False)            # cap
    p.cyl(0.55, 0.06, (0, 0, 3.42), "MetalDark", 8, smooth=False)
    for k in range(8):
        a = k * math.pi / 4 + math.pi / 8
        p.box((0.08, 0.3, 0.12), (math.cos(a) * 0.82, math.sin(a) * 0.82, 3.15), "GlowRed", 0.0, rot_z=a)


def railing(p):
    """4 m railing for platform edges: posts, two rails and a magenta strip along the foot."""
    for x in (-1.9, 0.0, 1.9):
        p.box((0.1, 0.1, 1.05), (x, 0, 0.525), "WallTrim", 0.02)
    p.box((4.0, 0.08, 0.08), (0, 0, 1.05), "MetalDark", 0.02)
    p.box((4.0, 0.06, 0.06), (0, 0, 0.6), "MetalDark", 0.02)
    p.box((4.0, 0.14, 0.12), (0, 0, 0.06), "WallDark", 0.02)
    p.box((4.0, 0.04, 0.04), (0, 0.08, 0.1), "GlowMagenta", 0.0)


def platform_edge(p):
    """The visible rim of a platform over the void: a 4 m long, 2.5 m deep fascia under the
    floor's edge with hazard trim and a neon strip, and support struts going down."""
    p.box((4.0, 0.4, 2.5), (0, -0.2, -1.25), "WallDark", 0.03)
    p.box((4.0, 0.06, 0.12), (0, 0.02, -0.18), "GlowMagenta", 0.0)
    for i in range(8):
        p.box((0.5, 0.05, 0.18), (-1.75 + i * 0.5, 0.02, -0.4), "HazardYellow" if i % 2 == 0 else "Rubber", 0.0)
    for x in (-1.5, 1.5):
        p.box((0.25, 0.3, 4.0), (x, -0.5, -3.5), "MetalDark", 0.02)
        p.box((0.2, 0.2, 3.0), (x, -0.5, -3.3), "WallTrim", 0.02, rot_x=0.35)


def stairs(p):
    """4 m wide stair run dropping one deck (3 m) over 6 m, front (+Y) = the bottom step.
    Origin at the top step's back edge on the upper floor; the run descends toward +Y."""
    steps = 12
    for i in range(steps):
        z = -0.25 * (i + 1)
        y = 0.25 + 0.5 * i
        p.box((4.0, 0.52, 0.25), (0, y, z + 0.125), "FloorPlate", 0.02)
        p.box((4.0, 0.05, 0.03), (0, y + 0.24, z + 0.25), "HazardYellow", 0.0)
    for x in (-2.1, 2.1):
        p.box((0.25, 6.2, 0.5), (x, 3.0, -1.5), "WallDark", 0.03, rot_x=math.atan2(3.0, 6.0))
        p.box((0.06, 6.2, 0.06), (x, 3.0, -1.12), "GlowMagenta", 0.0, rot_x=math.atan2(3.0, 6.0))


def cargo_stack(p):
    """Stacked cargo cases with orange-lit faces (kept to the room's edges)."""
    def case(cx, cy, cz, w, d, h):
        p.box((w, d, h), (cx, cy, cz + h / 2), "MetalDark", 0.05)
        p.box((w * 0.8, 0.04, h * 0.18), (cx, cy + d / 2 + 0.01, cz + h * 0.62), "GlowAmber", 0.0)
        p.box((w + 0.04, d * 0.3, 0.06), (cx, cy, cz + h + 0.02), "CargoOrange", 0.01)
    case(-0.6, 0.0, 0.0, 1.1, 1.0, 1.1)
    case(0.6, 0.05, 0.0, 1.1, 1.0, 1.1)
    case(0.0, -0.05, 1.1, 1.2, 1.0, 0.9)


def chest(p):
    """Loot chest: dark case, hazard banding, a bright seam. Godot adds the beam and opening."""
    p.box((1.3, 0.8, 0.55), (0, 0, 0.275), "MetalDark", 0.05)
    p.box((1.36, 0.86, 0.12), (0, 0, 0.6), "CargoOrange", 0.03)
    for x in (-0.55, 0.55):
        p.box((0.14, 0.84, 0.58), (x, 0, 0.29), "HazardYellow", 0.02)
    p.box((0.9, 0.03, 0.05), (0, 0.42, 0.52), "GlowAmber", 0.0)


def corruption_patch(p):
    """Pink Smile growth spreading over the floor: lumps, a few glowing teal pustules."""
    import random
    rnd = random.Random(7)
    p.blob((1.6, 1.2, 0.08), (0, 0, 0.0), "CorruptDeep", 14, 6)
    for _ in range(14):
        a = rnd.uniform(0, math.tau)
        d = rnd.uniform(0.1, 1.2)
        r = rnd.uniform(0.15, 0.4)
        p.blob((r * 1.2, r, r * 0.7), (math.cos(a) * d, math.sin(a) * d * 0.75, r * 0.2), "CorruptPink", 8, 5,
               rot_z=rnd.uniform(0, math.pi))
    for _ in range(6):
        a = rnd.uniform(0, math.tau)
        d = rnd.uniform(0.2, 1.0)
        p.blob((0.09, 0.09, 0.09), (math.cos(a) * d, math.sin(a) * d * 0.75, 0.2), "CorruptTeal", 6, 4)


PIECES = {
    "floor_plate": floor_plate,
    "floor_plate_lit": floor_plate_lit,
    "wall_curved": wall_curved,
    "wall_window": wall_window,
    "wall_corner": wall_corner,
    "door_frame": door_frame,
    "light_pillar": light_pillar,
    "railing": railing,
    "platform_edge": platform_edge,
    "stairs": stairs,
    "cargo_stack": cargo_stack,
    "chest": chest,
    "corruption_patch": corruption_patch,
}


def export_glb(obj, path):
    for o in bpy.context.scene.objects:
        o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", use_selection=True, export_yup=True,
        export_apply=True, export_materials="EXPORT", export_animations=False,
        export_cameras=False, export_lights=False)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    only = argv[argv.index("--only") + 1].split(",") if "--only" in argv else list(PIECES)
    reset_scene()
    mats = make_materials()
    os.makedirs(OUT, exist_ok=True)
    for name in only:
        p = Piece(name)
        PIECES[name](p)
        obj = p.finish(mats)
        tris = sum(len(poly.vertices) - 2 for poly in obj.data.polygons)
        path = os.path.join(OUT, name + ".glb")
        export_glb(obj, path)
        print(f"{name}: {tris} tris -> {os.path.relpath(path, REPO)}")
        bpy.data.objects.remove(obj)


main()
