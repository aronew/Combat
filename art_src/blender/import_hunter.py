"""Hunter: turns the Higgsfield (Meshy) downloads into the game's character and weapon files.

The hunter mesh was generated from the four-view turnaround and auto-rigged (24-bone humanoid).
Every animation clip came back as its own file with the mesh re-rigged, and the re-rigged
skeletons differ by a few centimetres and a few degrees of bone roll. So the clips are
*retargeted*, not copied: for every frame, each bone's rotation away from its rest pose in the
clip is reapplied to the same bone of the master rig (in armature space), and the hip motion is
scaled by the ratio of hip heights. The result is one skinned mesh with every clip on it.

Run (bpy 5.x):
    python art_src/blender/import_hunter.py SRC_DIR [--preview DIR]

SRC_DIR holds the downloads (see art_src/higgsfield/hunter_jobs.tsv for the job ids):
    hunter.glb                  the rigged character (master rig and skin)
    clips/<clip>.glb            one file per clip, named as in the first column of the .tsv
    rifle.glb, sword.glb        the weapons
Output:
    assets/models/hunter/hunter.glb         mesh + rig + every clip, 1024 px textures
    assets/models/hunter/hive_rifle.glb     decimated, 1024 px textures
    assets/models/hunter/chitin_blade.glb   decimated, 1024 px textures
"""

import math
import os
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "models", "hunter")
TEX = 1024
# clips that should loop in the game (Godot reads the -loop suffix on import)
LOOPS = {"idle", "run_forward", "run_back_left", "run_back_right", "strafe_left", "walk_back"}
# clips whose sideways hip travel is removed: the game moves the character itself (the roll's
# distance, the lunge of a swing), so the body must stay over the collision capsule
IN_PLACE = {"roll", "sword_combo", "sword_parry", "hit", "reload"}
# clips cut from (or mirrored from) a downloaded clip: name -> (source, start s, end s, mirror).
# The game's swings and roll are much faster than the library moves, so it plays just the
# strike or the tumble, sped up. Times come from the right hand's speed peaks (swings) and the
# hips' dip (roll, death).
DERIVED = {
    "strafe_right": ("strafe_left", None, None, True),
    "swing_1": ("sword_combo", 0.50, 0.98, False),
    "swing_2": ("sword_combo", 1.27, 1.75, False),
    "swing_3": ("sword_combo", 2.02, 2.50, False),
    "roll_fast": ("roll", 0.85, 1.83, False),
    "hit_quick": ("hit", 0.0, 0.6, False),
    "death_fall": ("death", 1.3, 3.5, False),
}
LOOPS |= {"strafe_right"}


def args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    src = a[0]
    preview = a[a.index("--preview") + 1] if "--preview" in a else None
    return src, preview


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    for o in list(new):
        # Meshy files carry a stray untextured icosphere; drop it
        if o.type == "MESH" and not o.material_slots:
            bpy.data.objects.remove(o)
            new.remove(o)
    return new


def armature_of(objs):
    return next(o for o in objs if o.type == "ARMATURE")


def rest_rot(arm):
    return {b.name: b.matrix_local.to_quaternion() for b in arm.data.bones}


def order(arm):
    """Bones parents-first."""
    out = []
    def walk(b):
        out.append(b)
        for c in b.children:
            walk(c)
    for b in arm.data.bones:
        if b.parent is None:
            walk(b)
    return out


def frame_range(arm):
    act = arm.animation_data.action
    return int(round(act.frame_range[0])), int(round(act.frame_range[1]))


def mirrored(name):
    if "Left" in name:
        return name.replace("Left", "Right")
    return name.replace("Right", "Left")


def retarget(master, clip_arm, name, start=None, end=None, mirror=False, in_place=None):
    """Bakes clip_arm's animation (or the start..end seconds of it) onto master as action `name`.
    mirror swaps left and right (the rig is symmetric across armature X)."""
    sc = bpy.context.scene
    fps = sc.render.fps / sc.render.fps_base
    if in_place is None:
        in_place = name in IN_PLACE
    m_rest, c_rest = rest_rot(master), rest_rot(clip_arm)
    bones = order(master)
    hips = bones[0].name
    m_head = master.data.bones[hips].head_local.copy()
    c_head = clip_arm.data.bones[hips].head_local.copy()
    ratio = m_head.z / c_head.z
    f0, f1 = frame_range(clip_arm)
    if start is not None:
        f0, f1 = f0 + int(round(start * fps)), min(f1, f0 + int(round(end * fps)))

    act = bpy.data.actions.new(name)
    master.animation_data_create()
    master.animation_data.action = act
    for pb in master.pose.bones:
        pb.rotation_mode = "QUATERNION"

    for f in range(f0, f1 + 1):
        sc.frame_set(f)
        # armature-space rotation of every clip bone, as a delta from its rest
        delta = {b.name: clip_arm.pose.bones[b.name].matrix.to_quaternion() @ c_rest[b.name].inverted()
                 for b in bones}
        if mirror:  # reflect across the X = 0 plane: q(w, x, y, z) -> q(w, x, -y, -z), sides swapped
            delta = {n: Quaternion((q.w, q.x, -q.y, -q.z)) for n, q in
                     ((b.name, delta[mirrored(b.name)]) for b in bones)}
        world = {}
        for b in bones:
            w = delta[b.name] @ m_rest[b.name]  # target armature-space rotation on the master
            world[b.name] = w
            if b.parent:
                p = b.parent.name
                local = m_rest[b.name].inverted() @ m_rest[p] @ world[p].inverted() @ w
            else:
                local = m_rest[b.name].inverted() @ w
            pb = master.pose.bones[b.name]
            pb.rotation_quaternion = local.normalized()
            pb.keyframe_insert("rotation_quaternion", frame=f - f0)
        # hips: same travel, scaled to the master's proportions
        travel = (clip_arm.pose.bones[hips].head - c_head) * ratio
        if mirror:
            travel.x = -travel.x
        if in_place:
            travel.x = travel.y = 0.0  # armature space is Z-up: keep only the vertical motion
        target = m_head + travel
        pb = master.pose.bones[hips]
        pb.location = m_rest[hips].to_matrix().inverted() @ (target - m_head)
        pb.keyframe_insert("location", frame=f - f0)

    # park it on an NLA track so the exporter writes it as its own animation
    master.animation_data.action = None
    track = master.animation_data.nla_tracks.new()
    track.name = name + ("-loop" if name in LOOPS else "")
    strip = track.strips.new(track.name, 0, act)
    strip.name = track.name
    if hasattr(strip, "action_slot") and len(act.slots):
        strip.action_slot = act.slots[0]  # Blender 5: a strip plays nothing without its slot
    print("  %-16s frames %3d  hip ratio %.3f  curves %d" % (name, f1 - f0 + 1, ratio, len(curves(act))))


def curves(act):
    """F-curves of an action (Blender 5 keeps them in layers/strips/channelbags)."""
    if hasattr(act, "layers"):
        return [fc for layer in act.layers for strip in layer.strips for bag in strip.channelbags for fc in bag.fcurves]
    return list(act.fcurves)


def shrink_textures(size=TEX):
    for img in bpy.data.images:
        if img.size[0] > size:
            img.scale(size, size)
            img.pack()


def export(path, animations=True):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", export_image_format="WEBP", export_image_quality=90,
        export_animations=animations, export_animation_mode="NLA_TRACKS" if animations else "ACTIONS",
        export_force_sampling=True, export_frame_step=1, export_yup=True, export_apply=False)
    print("wrote", os.path.relpath(path, ROOT), "%.1f MB" % (os.path.getsize(path) / 1e6))


def build_hunter(src):
    reset()
    objs = import_glb(os.path.join(src, "hunter.glb"))
    master = armature_of(objs)
    master.name = "HunterRig"
    if master.animation_data:
        master.animation_data.action = None
        for t in list(master.animation_data.nla_tracks):
            master.animation_data.nla_tracks.remove(t)
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    mesh = next(o for o in objs if o.type == "MESH")
    mesh.name = "Hunter"

    clip_dir = os.path.join(src, "clips")
    names = sorted(f[:-4] for f in os.listdir(clip_dir) if f.endswith(".glb"))
    print("retargeting %d clips" % len(names))
    for name in names:
        new = import_glb(os.path.join(clip_dir, name + ".glb"))
        retarget(master, armature_of(new), name)
        for d, (source, start, end, mirror) in DERIVED.items():
            if source == name:
                retarget(master, armature_of(new), d, start, end, mirror, name in IN_PLACE)
        for o in new:
            bpy.data.objects.remove(o, do_unlink=True)
        for a in list(bpy.data.actions):
            if a.users == 0:
                bpy.data.actions.remove(a)
    for m in list(bpy.data.meshes):
        if m.users == 0:
            bpy.data.meshes.remove(m)
    for i in list(bpy.data.images):
        if i.users == 0:
            bpy.data.images.remove(i)
    shrink_textures()
    export(os.path.join(OUT, "hunter.glb"))
    return names


def build_weapon(src, name, out, target_tris):
    reset()
    objs = import_glb(os.path.join(src, name))
    mesh = next(o for o in objs if o.type == "MESH")
    tris = sum(len(p.vertices) - 2 for p in mesh.data.polygons)
    if tris > target_tris:
        mod = mesh.modifiers.new("decimate", "DECIMATE")
        mod.ratio = target_tris / tris
        bpy.context.view_layer.objects.active = mesh
        bpy.ops.object.modifier_apply(modifier=mod.name)
    shrink_textures()
    export(os.path.join(OUT, out), animations=False)


def main():
    src, _preview = args()
    build_hunter(src)
    build_weapon(src, "rifle.glb", "hive_rifle.glb", 5000)
    build_weapon(src, "sword.glb", "chitin_blade.glb", 4000)


main()
