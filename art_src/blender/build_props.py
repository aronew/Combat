"""Set-dressing props for the Deepworks complex (after the concept mockups).

Builds every prop as its own mesh and exports one GLB per prop into
assets/models/props/. Hard-surface, bevelled, low poly: painted panels, dark
metal, grilles and small glowing strips. Run:

    python art_src/blender/build_props.py            # bpy module (Python 3.13)
    blender -b -P art_src/blender/build_props.py     # or the Blender app
    python art_src/blender/build_props.py -- --only ac_unit --preview /tmp/p

Conventions (match the Godot side): meters, Z up, a prop's front faces +Y in
Blender (-Z in Godot), origin on the floor at the footprint centre. Materials
are shared by name across props; Godot keeps the exported colours/emission.
"""

import math
import os
import sys

import bpy  # must come before bmesh when running as the bpy module
import bmesh  # noqa: E402
from mathutils import Matrix, Vector

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(REPO, "assets", "models", "props")

# name: (base rgb, metallic, roughness, emission rgb or None, emission strength)
MATERIALS = {
    "PaintLight": ((0.42, 0.42, 0.40), 0.25, 0.55, None, 0.0),
    "PaintWhite": ((0.70, 0.70, 0.67), 0.15, 0.5, None, 0.0),
    "MetalDark": ((0.055, 0.06, 0.065), 0.7, 0.45, None, 0.0),
    "Grille": ((0.02, 0.022, 0.025), 0.6, 0.6, None, 0.0),
    "Rubber": ((0.015, 0.015, 0.015), 0.0, 0.85, None, 0.0),
    "Hazard": ((0.75, 0.55, 0.06), 0.1, 0.6, None, 0.0),
    "Case": ((0.36, 0.34, 0.27), 0.2, 0.6, None, 0.0),
    "Cable": ((0.55, 0.22, 0.06), 0.0, 0.7, None, 0.0),
    "Container": ((0.45, 0.16, 0.1), 0.35, 0.55, None, 0.0),
    "Soil": ((0.06, 0.045, 0.03), 0.0, 0.95, None, 0.0),
    "Foliage": ((0.12, 0.3, 0.06), 0.0, 0.8, None, 0.0),
    "Chitin": ((0.09, 0.08, 0.05), 0.3, 0.4, None, 0.0),
    "Egg": ((0.45, 0.47, 0.25), 0.0, 0.35, (0.55, 0.8, 0.15), 0.6),
    "GlowWhite": ((0.9, 0.95, 1.0), 0.0, 0.5, (0.9, 0.95, 1.0), 4.0),
    "GlowAmber": ((1.0, 0.6, 0.2), 0.0, 0.5, (1.0, 0.58, 0.18), 4.0),
    "GlowBlue": ((0.3, 0.6, 1.0), 0.0, 0.5, (0.3, 0.62, 1.0), 3.0),
    "GlowGreen": ((0.3, 1.0, 0.4), 0.0, 0.5, (0.3, 1.0, 0.4), 3.0),
    "GlowRed": ((1.0, 0.15, 0.1), 0.0, 0.5, (1.0, 0.12, 0.08), 4.0),
    "Screen": ((0.05, 0.2, 0.3), 0.0, 0.3, (0.15, 0.6, 0.9), 1.6),
    # Starship
    "HullPaint": ((0.30, 0.32, 0.35), 0.45, 0.45, None, 0.0),
    "HullDark": ((0.07, 0.075, 0.085), 0.6, 0.4, None, 0.0),
    "HazardYellow": ((0.85, 0.6, 0.04), 0.15, 0.5, None, 0.0),
    "GlowTeal": ((0.25, 0.95, 0.9), 0.0, 0.5, (0.25, 0.95, 0.9), 4.0),
    # Replaced in Godot by an animated star-field shader (Props.place).
    "SpaceGlass": ((0.02, 0.03, 0.08), 0.0, 0.1, (0.05, 0.1, 0.3), 1.0),
    # Foundry
    "Iron": ((0.11, 0.1, 0.095), 0.75, 0.55, None, 0.0),
    "Rust": ((0.28, 0.12, 0.05), 0.3, 0.8, None, 0.0),
    "GlowMolten": ((1.0, 0.45, 0.08), 0.0, 0.4, (1.0, 0.42, 0.06), 7.0),
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


class Prop:
    """One prop: a single bmesh with a material index per part."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.slots = []

    def _slot(self, mat):
        if mat not in self.slots:
            self.slots.append(mat)
        return self.slots.index(mat)

    def _tag(self, before, mat, smooth=False):
        idx = self._slot(mat)
        for f in set(self.bm.faces) - before:
            f.material_index = idx
            f.smooth = smooth

    def box(self, size, center, mat, bevel=0.02, rot_z=0.0, rot_x=0.0):
        """Box of full size (x, y, z) centred at `center`, edges bevelled."""
        before = set(self.bm.faces)
        m = (Matrix.Translation(Vector(center)) @ Matrix.Rotation(rot_z, 4, "Z")
             @ Matrix.Rotation(rot_x, 4, "X") @ Matrix.Diagonal((*size, 1.0)))
        res = bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)
        verts = res["verts"]
        if bevel > 0.0:
            edges = list({e for v in verts for e in v.link_edges})
            bmesh.ops.bevel(self.bm, geom=edges, offset=min(bevel, min(size) * 0.45), segments=2,
                            profile=0.5, affect="EDGES", clamp_overlap=True)
        self._tag(before, mat)

    def cyl(self, radius, depth, center, mat, axis="Z", segments=16, radius2=None):
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
        self._tag(before, mat, smooth=True)

    def ellipsoid(self, radii, center, mat, segments=12, rings=8, rot_z=0.0):
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
# Props. Front = +Y. Origin on the floor.
# ---------------------------------------------------------------------------

def ac_unit(p):
    """Rooftop-style AC box with two fan grilles on top (mockups: ring edge)."""
    p.box((1.7, 1.0, 0.85), (0, 0, 0.5), "PaintLight", 0.05)
    p.box((1.76, 1.06, 0.1), (0, 0, 0.05), "MetalDark", 0.02)
    for x in (-0.42, 0.42):
        p.cyl(0.34, 0.05, (x, 0, 0.93), "Grille", segments=20)
        p.cyl(0.08, 0.08, (x, 0, 0.95), "MetalDark", segments=10)
        for k in range(3):
            p.box((0.6, 0.06, 0.015), (x, 0, 0.955), "MetalDark", 0.0, rot_z=k * math.pi / 3)
    for i in range(6):
        p.box((0.05, 0.02, 0.5), (-0.6 + i * 0.12, 0.51, 0.48), "Grille", 0.0)
    p.box((0.35, 0.02, 0.05), (0.5, 0.515, 0.72), "GlowWhite", 0.0)


def electrical_box(p):
    """Tall service cabinet with door seams and an amber status light."""
    p.box((0.9, 0.45, 1.5), (0, 0, 0.75), "PaintLight", 0.03)
    p.box((0.02, 0.02, 1.3), (0, 0.23, 0.78), "MetalDark", 0.0)
    for z in (0.35, 1.2):
        p.box((0.8, 0.02, 0.02), (0, 0.23, z), "MetalDark", 0.0)
    p.box((0.05, 0.03, 0.18), (0.36, 0.24, 0.9), "MetalDark", 0.01)
    p.box((0.12, 0.02, 0.05), (-0.25, 0.235, 1.36), "GlowAmber", 0.0)
    p.box((0.95, 0.5, 0.06), (0, 0, 1.52), "MetalDark", 0.02)
    p.cyl(0.05, 0.6, (0.3, -0.05, 1.8), "MetalDark")


def hard_case(p):
    """Rugged equipment case with a lid seam, latches and a handle."""
    p.box((1.15, 0.72, 0.58), (0, 0, 0.29), "Case", 0.07)
    p.box((1.18, 0.75, 0.05), (0, 0, 0.42), "MetalDark", 0.02)
    for x in (-0.38, 0.38):
        p.box((0.12, 0.04, 0.14), (x, 0.375, 0.4), "MetalDark", 0.015)
    p.box((0.4, 0.05, 0.05), (0, 0.0, 0.6), "Rubber", 0.02)
    for x in (-0.48, 0.48):
        for y in (-0.28, 0.28):
            p.box((0.1, 0.1, 0.58), (x, y, 0.29), "MetalDark", 0.02)


def cable_spool(p):
    """Cable drum on a steel frame (mockup: switchgear room corner)."""
    for x in (-0.55, 0.55):
        p.box((0.08, 0.9, 0.08), (x, 0, 0.04), "MetalDark", 0.01)
        p.box((0.08, 0.08, 0.95), (x, -0.4, 0.5), "MetalDark", 0.01)
        p.box((0.08, 0.08, 0.95), (x, 0.4, 0.5), "MetalDark", 0.01)
        p.box((0.08, 0.9, 0.08), (x, 0, 0.95), "MetalDark", 0.01)
    p.cyl(0.38, 0.9, (0, 0, 0.5), "Cable", axis="X", segments=20)
    for x in (-0.47, 0.47):
        p.cyl(0.46, 0.04, (x, 0, 0.5), "PaintLight", axis="X", segments=20)
    p.cyl(0.05, 1.2, (0, 0, 0.5), "MetalDark", axis="X")


def switchgear(p):
    """One switchgear cabinet module: line several up for a row (mockup 5)."""
    p.box((1.2, 1.0, 0.12), (0, 0, 0.06), "MetalDark", 0.02)
    p.box((1.18, 0.95, 2.05), (0, 0, 1.12), "PaintWhite", 0.03)
    p.box((0.02, 0.02, 1.85), (0, 0.48, 1.1), "MetalDark", 0.0)
    for z in (0.5, 1.15, 1.75):
        p.box((1.05, 0.02, 0.02), (0, 0.48, z), "MetalDark", 0.0)
    for x in (-0.25, 0.25):
        p.box((0.04, 0.03, 0.2), (x * 0.4 + (0.1 if x > 0 else -0.1), 0.49, 1.0), "MetalDark", 0.01)
    p.box((0.6, 0.5, 0.06), (0, 0, 2.17), "Grille", 0.01)
    for i in range(5):
        p.box((0.5, 0.02, 0.02), (0, 0.495, 0.25 + i * 0.05), "Grille", 0.0)
    p.box((0.08, 0.02, 0.05), (0.4, 0.49, 1.85), "GlowAmber", 0.0)


def server_rack(p):
    """Dark rack with rows of blinking-looking LEDs."""
    p.box((0.72, 1.0, 2.1), (0, 0, 1.05), "MetalDark", 0.025)
    p.box((0.62, 0.02, 1.9), (0, 0.5, 1.05), "Grille", 0.0)
    for row in range(12):
        z = 0.25 + row * 0.15
        p.box((0.46, 0.015, 0.015), (0, 0.515, z), "GlowBlue" if row % 3 else "GlowGreen", 0.0)


def console(p):
    """Control console: dark body, sloped desk with a glowing screen."""
    p.box((1.4, 0.7, 0.85), (0, 0, 0.42), "PaintLight", 0.03)
    p.box((1.45, 0.55, 0.08), (0, 0.18, 0.92), "MetalDark", 0.02, rot_x=-0.45)
    p.box((1.1, 0.02, 0.36), (0, 0.33, 0.95), "Screen", 0.0, rot_x=-0.45 - math.pi / 2 + math.pi / 2)
    p.box((1.3, 0.15, 0.55), (0, -0.3, 1.15), "PaintLight", 0.02)
    p.box((1.0, 0.02, 0.35), (0, -0.22, 1.2), "Screen", 0.0)
    for i in range(4):
        p.box((0.06, 0.06, 0.02), (-0.45 + i * 0.3, 0.42, 0.88), "GlowAmber" if i % 2 else "GlowGreen", 0.0)


def wall_panel(p):
    """3 m modular white wall segment with recessed panels and a light strip."""
    p.box((3.0, 0.4, 3.2), (0, 0, 1.6), "PaintWhite", 0.04)
    for x in (-0.75, 0.75):
        p.box((1.2, 0.04, 2.2), (x, 0.2, 1.55), "PaintLight", 0.02)
    p.box((0.12, 0.03, 2.4), (-1.42, 0.21, 1.5), "GlowWhite", 0.0)
    p.box((3.0, 0.5, 0.22), (0, 0, 0.11), "MetalDark", 0.02)
    p.box((3.0, 0.5, 0.15), (0, 0, 3.25), "MetalDark", 0.02)
    p.cyl(0.09, 3.0, (0, 0.32, 2.7), "MetalDark", axis="X", segments=10)
    p.cyl(0.06, 3.0, (0, 0.3, 2.45), "PaintLight", axis="X", segments=10)


def door(p):
    """Heavy door with a frame and red warning lights (mockup 3)."""
    p.box((3.4, 0.7, 3.6), (0, -0.05, 1.8), "PaintWhite", 0.05)
    p.box((2.4, 0.2, 2.9), (0, 0.32, 1.45), "MetalDark", 0.03)
    p.box((0.04, 0.05, 2.8), (0, 0.43, 1.45), "Grille", 0.0)
    for x in (-1.45, 1.45):
        p.box((0.12, 0.05, 1.4), (x, 0.37, 1.8), "GlowRed", 0.0)
    p.box((1.6, 0.05, 0.12), (0, 0.37, 3.2), "GlowRed", 0.0)
    p.box((2.4, 0.4, 0.05), (0, 0.5, 0.03), "Hazard", 0.0)


def tank(p):
    """Vertical tank with steel bands, a dome and a ladder."""
    p.cyl(1.1, 3.0, (0, 0, 1.6), "PaintLight", segments=24)
    p.ellipsoid((1.1, 1.1, 0.35), (0, 0, 3.1), "PaintLight", segments=24, rings=8)
    for z in (0.6, 1.6, 2.6):
        p.cyl(1.13, 0.1, (0, 0, z), "MetalDark", segments=24)
    p.cyl(1.2, 0.15, (0, 0, 0.08), "MetalDark", segments=24)
    for z in range(10):
        p.box((0.5, 0.04, 0.04), (0, 1.16, 0.3 + z * 0.3), "MetalDark", 0.0)
    for x in (-0.25, 0.25):
        p.box((0.05, 0.05, 3.1), (x, 1.16, 1.6), "MetalDark", 0.0)
    p.cyl(0.18, 0.8, (0.9, 0.4, 0.7), "MetalDark", axis="X")


def container(p):
    """Shipping container with corrugated sides (6 x 2.4 x 2.6)."""
    p.box((6.0, 2.4, 2.6), (0, 0, 1.3), "Container", 0.04)
    for i in range(24):
        x = -2.85 + i * 0.248
        for y in (-1.21, 1.21):
            p.box((0.1, 0.04, 2.3), (x, y, 1.3), "Container", 0.0)
    for x in (-2.95, 2.95):
        for y in (-1.15, 1.15):
            p.box((0.15, 0.15, 2.6), (x, y, 1.3), "MetalDark", 0.02)
    for x in (-0.6, 0.6):
        p.box((0.06, 0.06, 2.2), (2.99 if x > 0 else 2.99, x, 1.3), "MetalDark", 0.0)


def egg_cluster(p):
    """Hive eggs on a resin base (mockup 4 alcove)."""
    p.ellipsoid((1.0, 0.8, 0.15), (0, 0, 0.05), "Chitin", segments=14, rings=6)
    for (x, y, s) in ((-0.35, 0.1, 1.0), (0.3, -0.15, 0.9), (0.05, 0.35, 0.8), (0.45, 0.35, 0.7)):
        p.ellipsoid((0.24 * s, 0.24 * s, 0.38 * s), (x, y, 0.32 * s), "Egg", segments=12, rings=8)


def floor_vent(p):
    """Floor vent with diagonal slats (mockup 1)."""
    p.box((2.0, 1.4, 0.05), (0, 0, 0.025), "PaintLight", 0.01)
    p.box((1.8, 1.2, 0.02), (0, 0, 0.045), "Grille", 0.0)
    for i in range(7):
        x = -0.75 + i * 0.25
        p.box((0.08, 1.25, 0.04), (x, 0, 0.055), "MetalDark", 0.0, rot_z=0.5)


def planter(p):
    """Hydroponics planter with overgrown foliage."""
    p.box((2.4, 1.0, 0.55), (0, 0, 0.28), "PaintLight", 0.03)
    p.box((2.25, 0.85, 0.05), (0, 0, 0.53), "Soil", 0.0)
    for i in range(7):
        x = -1.0 + i * 0.33
        s = 0.8 + (i * 37 % 10) / 20.0
        p.ellipsoid((0.26 * s, 0.24 * s, 0.22 * s), (x, (i % 2) * 0.12 - 0.06, 0.66), "Foliage", segments=8, rings=5)
    p.box((2.3, 0.04, 0.04), (0, 0.5, 0.45), "GlowGreen", 0.0)


def locker_row(p):
    """Three lockers in a row."""
    for i in range(3):
        x = -0.62 + i * 0.62
        p.box((0.58, 0.5, 2.0), (x, 0, 1.0), "PaintLight", 0.02)
        p.box((0.02, 0.02, 1.7), (x + 0.28, 0.25, 1.0), "MetalDark", 0.0)
        for z in (1.6, 1.68, 1.76):
            p.box((0.3, 0.02, 0.02), (x, 0.255, z), "Grille", 0.0)



# ---------------------------------------------------------------------------
# Starship (Cargo Deck / Teal Ring mockups)
# ---------------------------------------------------------------------------

def ship_pillar(p):
    """Round deck pillar with a vented collar and glowing red bands."""
    p.cyl(0.62, 0.25, (0, 0, 0.125), "HullDark", segments=20)
    p.cyl(0.52, 3.0, (0, 0, 1.75), "HullPaint", segments=20)
    p.cyl(0.6, 0.3, (0, 0, 3.3), "HullDark", segments=20)
    for z in (0.75, 2.55):
        p.cyl(0.55, 0.16, (0, 0, z), "GlowRed", segments=20)
    p.cyl(0.56, 0.6, (0, 0, 1.65), "Grille", segments=20)
    for k in range(4):
        a = k * math.pi / 2
        p.box((0.08, 0.08, 2.6), (math.cos(a) * 0.53, math.sin(a) * 0.53, 1.75), "HullDark", 0.01)


def hazard_crate(p):
    """Yellow cargo crate with black hazard bands and dark corner guards."""
    p.box((1.4, 1.0, 0.9), (0, 0, 0.45), "HazardYellow", 0.06)
    for x in (-0.45, 0.45):
        p.box((0.16, 1.03, 0.92), (x, 0, 0.45), "HullDark", 0.02)
    p.box((1.42, 0.3, 0.05), (0, 0, 0.92), "HullDark", 0.01)
    for x in (-0.66, 0.66):
        for y in (-0.46, 0.46):
            p.box((0.12, 0.12, 0.94), (x, y, 0.47), "HullDark", 0.02)
    p.box((0.3, 0.02, 0.08), (0, 0.51, 0.7), "GlowWhite", 0.0)


def hull_window(p):
    """3 m hull wall section with a wide viewport onto space (front = +Y)."""
    p.box((3.0, 0.4, 0.5), (0, 0, 0.25), "HullDark", 0.03)
    p.box((3.0, 0.4, 0.6), (0, 0, 2.95), "HullDark", 0.03)
    for x in (-1.38, 1.38):
        p.box((0.24, 0.42, 3.2), (x, 0, 1.6), "HullPaint", 0.03)
    p.box((2.52, 0.08, 2.2), (0, 0.06, 1.6), "SpaceGlass", 0.0)
    for x in (-0.42, 0.42):
        p.box((0.08, 0.14, 2.2), (x, 0.12, 1.6), "HullDark", 0.0)
    p.box((2.6, 0.12, 0.08), (0, 0.16, 0.48), "GlowRed", 0.0)
    p.box((3.0, 0.5, 0.15), (0, 0, 3.25), "MetalDark", 0.02)


def supply_pod(p):
    """Cargo pod lying in a cradle, with a red status light."""
    p.cyl(0.55, 1.9, (0, 0, 0.7), "HullPaint", axis="X", segments=18)
    for x in (-0.95, 0.95):
        p.cyl(0.58, 0.12, (x, 0, 0.7), "HullDark", axis="X", segments=18)
    for x in (-0.55, 0.55):
        p.box((0.2, 1.1, 0.35), (x, 0, 0.17), "HullDark", 0.02)
    p.box((1.5, 0.05, 0.1), (0, 0.56, 0.7), "HazardYellow", 0.0)
    p.box((0.12, 0.05, 0.12), (0.7, 0.57, 0.95), "GlowRed", 0.0)


# ---------------------------------------------------------------------------
# Foundry (Furnace Chasm mockup)
# ---------------------------------------------------------------------------

def crucible(p):
    """Molten-metal crucible: iron vessel, glowing pour, banded and riveted."""
    p.cyl(1.25, 0.25, (0, 0, 0.12), "Iron", segments=24)
    p.cyl(1.1, 2.0, (0, 0, 1.2), "Iron", segments=24, radius2=1.2)
    p.cyl(1.22, 0.14, (0, 0, 2.25), "MetalDark", segments=24)
    p.cyl(1.08, 0.05, (0, 0, 2.34), "GlowMolten", segments=24)
    for z in (0.6, 1.4):
        p.cyl(1.16, 0.12, (0, 0, z), "Rust", segments=24)
    p.box((0.5, 0.35, 0.3), (0, 1.15, 2.05), "Iron", 0.03)
    p.box((0.3, 0.2, 0.06), (0, 1.28, 2.2), "GlowMolten", 0.0)
    for k in range(3):
        a = k * 2 * math.pi / 3 + 0.5
        p.box((0.22, 0.22, 2.2), (math.cos(a) * 1.15, math.sin(a) * 1.15, 1.1), "MetalDark", 0.02)


def smoke_stack(p):
    """Exhaust vent: squat stack with a grille and a glow deep inside."""
    p.cyl(0.55, 0.2, (0, 0, 0.1), "MetalDark", segments=16)
    p.cyl(0.42, 1.4, (0, 0, 0.9), "Iron", segments=16)
    p.cyl(0.48, 0.1, (0, 0, 0.6), "Rust", segments=16)
    p.cyl(0.47, 0.12, (0, 0, 1.6), "MetalDark", segments=16)
    p.cyl(0.4, 0.03, (0, 0, 1.68), "GlowMolten", segments=16)
    for k in range(4):
        p.box((0.84, 0.05, 0.05), (0, 0, 1.72), "Grille", 0.0, rot_z=k * math.pi / 4)


def furnace_pillar(p):
    """Tall furnace column with glowing slits (Furnace Chasm towers)."""
    p.box((1.5, 1.5, 0.3), (0, 0, 0.15), "MetalDark", 0.03)
    p.cyl(0.65, 3.6, (0, 0, 2.1), "Iron", segments=8)
    for z in (1.2, 2.2, 3.2):
        p.cyl(0.7, 0.14, (0, 0, z), "Rust", segments=8)
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 8
        p.box((0.12, 0.08, 0.7), (math.cos(a) * 0.62, math.sin(a) * 0.62, 1.7), "GlowMolten", 0.0, rot_z=a)
        p.box((0.12, 0.08, 0.7), (math.cos(a) * 0.62, math.sin(a) * 0.62, 2.7), "GlowMolten", 0.0, rot_z=a)
    p.cyl(0.5, 0.4, (0, 0, 4.1), "MetalDark", segments=8)


def ingot_stack(p):
    """Pallet of cast ingots, the top row still glowing."""
    p.box((1.3, 1.0, 0.14), (0, 0, 0.07), "MetalDark", 0.01)
    for row in range(3):
        mat = "GlowMolten" if row == 2 else "Iron"
        for k in range(4 if row % 2 == 0 else 3):
            if row % 2 == 0:
                p.box((1.2, 0.2, 0.16), (0, -0.33 + k * 0.22, 0.22 + row * 0.17), mat, 0.03)
            else:
                p.box((0.22, 0.9, 0.16), (-0.33 + k * 0.33, 0, 0.22 + row * 0.17), mat, 0.03)

PROPS = {
    "ac_unit": ac_unit,
    "electrical_box": electrical_box,
    "hard_case": hard_case,
    "cable_spool": cable_spool,
    "switchgear": switchgear,
    "server_rack": server_rack,
    "console": console,
    "wall_panel": wall_panel,
    "door": door,
    "tank": tank,
    "container": container,
    "egg_cluster": egg_cluster,
    "floor_vent": floor_vent,
    "planter": planter,
    "locker_row": locker_row,
    "ship_pillar": ship_pillar,
    "hazard_crate": hazard_crate,
    "hull_window": hull_window,
    "supply_pod": supply_pod,
    "crucible": crucible,
    "smoke_stack": smoke_stack,
    "furnace_pillar": furnace_pillar,
    "ingot_stack": ingot_stack,
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


def render_preview(obj, out_dir, name):
    os.makedirs(out_dir, exist_ok=True)
    scn = bpy.context.scene
    scn.render.engine = "CYCLES"
    scn.cycles.samples = 24
    scn.cycles.device = "CPU"
    scn.render.resolution_x = 640
    scn.render.resolution_y = 480
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.03, 0.05, 0.07, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    scn.world = world
    dims = obj.dimensions
    r = max(dims.x, dims.y, dims.z) * 1.6 + 1.0
    cam_data = bpy.data.cameras.new("Cam")
    cam = bpy.data.objects.new("Cam", cam_data)
    scn.collection.objects.link(cam)
    cam.location = (r * 0.8, r * 0.9, r * 0.9)
    direction = Vector((0, 0, dims.z * 0.4)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scn.camera = cam
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 3.0
    sun_obj = bpy.data.objects.new("Sun", sun)
    sun_obj.rotation_euler = (0.8, 0.2, 0.6)
    scn.collection.objects.link(sun_obj)
    scn.render.filepath = os.path.join(out_dir, name + ".png")
    bpy.ops.render.render(write_still=True)
    for o in (cam, sun_obj):
        bpy.data.objects.remove(o)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    only = argv[argv.index("--only") + 1].split(",") if "--only" in argv else list(PROPS)
    preview = argv[argv.index("--preview") + 1] if "--preview" in argv else None
    reset_scene()
    mats = make_materials()
    os.makedirs(OUT, exist_ok=True)
    for name in only:
        p = Prop(name)
        PROPS[name](p)
        obj = p.finish(mats)
        tris = sum(len(poly.vertices) - 2 for poly in obj.data.polygons)
        path = os.path.join(OUT, name + ".glb")
        export_glb(obj, path)
        print(f"{name}: {tris} tris -> {path}")
        if preview:
            render_preview(obj, preview, name)
        bpy.data.objects.remove(obj)


main()
