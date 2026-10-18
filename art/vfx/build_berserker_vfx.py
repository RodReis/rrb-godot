"""Monta art/vfx/berserker_vfx.blend e exporta shared/assets/rrb/vfx/thrown_axe.glb (ADR-0005, SPEC-075).

Machado do Arremesso de Machado (Q do Berserker): o axe_1handed_Large do KayKit Adventurers 2.0 Extra
(CC0) com a textura alternativa do Berserker, origem no centro da caixa e deitado no plano de giro: no
Godot o cabo fica em +Y e a lamina na frente (-Z), entao o projetil (que olha para onde voa) gira em
torno do proprio X e o machado da cambalhotas de ponta a ponta.
Uso:
  blender --background --factory-startup --python build_berserker_vfx.py -- <extra_dir> <repo> <A|B|C>
"""
import math
import sys

import bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
PACK, REPO, ALT = argv[0], argv[1], argv[2].upper()
BLEND = REPO + r"\art\vfx\berserker_vfx.blend"
GLB = REPO + r"\shared\assets\rrb\vfx\thrown_axe.glb"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=PACK + r"\Assets\gltf\axe_1handed_Large.gltf")
axe = next(o for o in bpy.data.objects if o.type == "MESH")
axe.name = "ThrownAxe"
axe.data.name = "ThrownAxe"

alt = bpy.data.images.load(PACK + r"\Textures\barbarian_texture_alt_%s.png" % ALT)
alt.pack()
alt.name = "berserker_texture"
for mat in axe.data.materials:
    for node in mat.node_tree.nodes:
        if node.type == "TEX_IMAGE":
            node.image = alt
for image in list(bpy.data.images):
    if image.users == 0:
        bpy.data.images.remove(image)

# Lamina (-X do pack) para +Y do Blender (-Z no Godot); depois o centro da caixa na origem.
axe.data.transform(Matrix.Rotation(math.radians(-90.0), 4, "Z"))
corners = [Vector(c) for c in axe.bound_box]
center = sum(corners, Vector()) / 8.0
axe.data.transform(Matrix.Translation(-center))
axe.location = (0.0, 0.0, 0.0)

bpy.ops.wm.save_as_mainfile(filepath=BLEND)
bpy.ops.export_scene.gltf(filepath=GLB, export_format="GLB", export_yup=True, export_animations=False)
print("RESULT tris", sum(len(p.vertices) - 2 for p in axe.data.polygons), "dims", [round(d, 3) for d in axe.dimensions])
