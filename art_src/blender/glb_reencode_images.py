"""Re-encode every embedded image of a GLB as a plain baseline JPEG (ImageMagick), rebuilding
the binary chunk. Some JPEGs Blender writes fail Godot's decoder; this fixes them.
Usage: python3 glb_reencode_images.py file.glb [quality]"""
import json, struct, subprocess, sys

path = sys.argv[1]
quality = sys.argv[2] if len(sys.argv) > 2 else "88"
b = open(path, "rb").read()
jlen = struct.unpack("<I", b[12:16])[0]
j = json.loads(b[20:20 + jlen])
blen = struct.unpack("<I", b[20 + jlen:24 + jlen])[0]
binc = b[28 + jlen:28 + jlen + blen]
image_views = {im["bufferView"]: im for im in j.get("images", []) if "bufferView" in im}
out = bytearray()
for i, bv in enumerate(j["bufferViews"]):
    data = binc[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]]
    if i in image_views:
        data = subprocess.run(["convert", "-", "-strip", "-interlace", "none", "-sampling-factor", "4:2:0",
                               "-quality", quality, "jpg:-"], input=data, capture_output=True, check=True).stdout
        image_views[i]["mimeType"] = "image/jpeg"
    while len(out) % 4:
        out.append(0)
    bv["byteOffset"] = len(out)
    bv["byteLength"] = len(data)
    out += data
while len(out) % 4:
    out.append(0)
j["buffers"][0]["byteLength"] = len(out)
js = json.dumps(j, separators=(",", ":")).encode()
js += b" " * (-len(js) % 4)
glb = struct.pack("<III", 0x46546C67, 2, 28 + len(js) + len(out))
glb += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(out), 0x004E4942) + bytes(out)
open(path, "wb").write(glb)
print(path, len(glb))
