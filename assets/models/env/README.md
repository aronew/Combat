# Environment models (AI-generated)

Made with Tripo 3D (text to 3D, via Higgsfield) for look test 2, then prepared for the game with
`art_src/blender/prep_env_asset.py` (metres, origin at the bottom centre, 1k textures; 2k for the
crusher) and `art_src/blender/glb_reencode_images.py` (Godot cannot decode some JPEGs Blender writes).

| model | size (m, before scaling in the level) | Higgsfield job |
|---|---|---|
| rock_wall | 4.5 x 5.0 x 4.0 tall | 626329f6-72cc-4dfa-9f05-959f09a7df98 |
| rock_cluster | 2.7 x 3.2 x 2.0 tall | 2a695508-19ee-4ede-a959-cfe0062911ad |
| corruption_mound | 3.2 x 3.2 x 2.2 tall | 10cf20e3-ed26-4543-8c05-9ecd4a282179 |
| ore_crusher | 5.5 x 1.9 x 3.2 tall | 94b0fffc-622a-425a-aa1a-b50180ef2845 |
| conveyor | 8.0 x 2.8 x 2.3 tall | 4093d76f-69d4-4001-8118-ee22f5e9b054 |

In a level, give them the cutaway material (see `scripts/test/look_test_2.gd`, `_apply_cutaway`).
