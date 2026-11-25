"""Prepare an AI-generated environment model (Tripo GLB) for the game: origin at the bottom
centre, scaled so its longest side is `size` metres, textures downsized to `tex` px, JPEG glTF.
Usage: python prep_env_asset.py in.glb out.glb size [tex]
Then run glb_reencode_images.py on the output: Godot fails to decode some of Blender's JPEGs."""
import sys
import bpy
from mathutils import Vector

src, dst, size = sys.argv[1], sys.argv[2], float(sys.argv[3])
tex = int(sys.argv[4]) if len(sys.argv) > 4 else 1024
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
for o in meshes:
    for v in o.data.vertices:
        lo = Vector(map(min, lo, v.co)); hi = Vector(map(max, hi, v.co))
k = size / max(hi - lo)
off = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
for o in meshes:
    for v in o.data.vertices:
        v.co = (v.co - off) * k
for o in list(bpy.context.scene.objects):
    if o.type != 'MESH':
        bpy.data.objects.remove(o)
for img in bpy.data.images:
    if img.size[0] > tex:
        img.scale(tex, tex)
d = (hi - lo) * k
print("size m", round(d.x, 2), round(d.y, 2), round(d.z, 2))
bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB', export_image_format='JPEG', export_jpeg_quality=88)
