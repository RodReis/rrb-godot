"""Monta art/heroes/ranger.blend e exporta shared/assets/rrb/heroes/ranger.glb (ADR-0005).

Ranger do KayKit Adventurers 2.0 (CC0) + arco bow_withString no handslot.l + animacoes do
Knight do KayKit Adventurers 1.0 (CC0): o rig e o mesmo (23 ossos, mesmos nomes, mesma pose de
repouso), entao as acoes servem sem retarget. Uso:
  blender --background --factory-startup --python build_ranger.py -- <pack2_dir> <repo> [preview_dir]
"""
import math
import sys

import bpy
from mathutils import Euler, Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
PACK, REPO = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""
KNIGHT = REPO + r"\shared\assets\kaykit\adventurers\Knight.glb"
BLEND = REPO + r"\art\heroes\ranger.blend"
GLB = REPO + r"\shared\assets\rrb\heroes\ranger.glb"

# Animacoes levadas do Knight; -loop no nome = laco no importador do Godot.
ANIMATIONS = {
    "Idle": "Idle-loop",
    "Running_A": "Running_A-loop",
    "Dodge_Forward": "Dodge_Forward",
    "2H_Ranged_Shoot": "2H_Ranged_Shoot",
    "Spellcast_Shoot": "Spellcast_Shoot",
    "Hit_B": "Hit_B-loop",
    "Death_A": "Death_A",
}
# Arco na mao esquerda: no espaco do osso handslot.l (Y ao longo do braco).
BOW_SCALE = 0.55
BOW_ROTATION = Euler((math.radians(270.0), 0.0, math.radians(90.0)), "XYZ")

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=PACK + r"\Characters\gltf\Ranger.glb")
rig = bpy.data.objects["Rig_Medium"]
bpy.ops.import_scene.gltf(filepath=KNIGHT)
bpy.ops.import_scene.gltf(filepath=PACK + r"\Assets\gltf\bow_withString.gltf")
bow = bpy.data.objects["bow_withString"]

# Fora: o Knight (so as acoes ficam) e as icosferas de forma de osso do importador.
knight = bpy.data.objects["Rig"]
doomed = [o for o in bpy.data.objects if o == knight or o.parent == knight or o.name.startswith("Icosphere")]
for o in doomed:
    bpy.data.objects.remove(o, do_unlink=True)

bow.parent = rig
bow.parent_type = "BONE"
bow.parent_bone = "handslot.l"
bone = rig.data.bones["handslot.l"]
# Objeto filho de osso fica na ponta do osso; volta para a cabeca (handslot e o ponto da mao).
bow.matrix_parent_inverse = Matrix.Translation(Vector((0.0, -bone.length, 0.0)))
bow.matrix_basis = BOW_ROTATION.to_matrix().to_4x4() @ Matrix.Scale(BOW_SCALE, 4)

ad = rig.animation_data_create()
for src, dst in ANIMATIONS.items():
    action = bpy.data.actions[src]
    action.name = dst
    track = ad.nla_tracks.new()
    track.name = dst
    strip = track.strips.new(dst, int(action.frame_range[0]), action)
    if hasattr(strip, "action_slot") and len(action.slots) > 0:
        strip.action_slot = action.slots[0]
    track.mute = True
for action in list(bpy.data.actions):
    if action.name not in ANIMATIONS.values():
        bpy.data.actions.remove(action)

bpy.ops.wm.save_as_mainfile(filepath=BLEND)
bpy.ops.export_scene.gltf(
    filepath=GLB,
    export_format="GLB",
    export_animation_mode="NLA_TRACKS",
    export_force_sampling=True,
    export_yup=True,
)


def tris(objects):
    total = 0
    for o in objects:
        if o.type == "MESH":
            total += sum(len(p.vertices) - 2 for p in o.data.polygons)
    return total


print("RESULT tris", tris(bpy.data.objects), "bow", tris([bow]))
print("RESULT bow material", [m.name for m in bow.data.materials])

if PREVIEW:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x = 480
    scene.render.resolution_y = 480
    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    for view, loc in (("front", (2.2, -3.2, 2.0)), ("side", (3.8, 0.4, 1.6))):
        cam.location = loc
        direction = Vector((0.0, 0.0, 1.1)) - cam.location
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        for name, frac in (("Idle-loop", 0.0), ("2H_Ranged_Shoot", 0.35), ("Running_A-loop", 0.3),
                           ("Dodge_Forward", 0.4), ("Spellcast_Shoot", 0.4)):
            action = bpy.data.actions[name]
            ad.action = action
            if hasattr(ad, "action_slot"):
                ad.action_slot = action.slots[0]
            start, end = action.frame_range
            scene.frame_set(int(start + (end - start) * frac))
            scene.render.filepath = PREVIEW + "\\%s_%s.png" % (view, name)
            bpy.ops.render.render(write_still=True)
    ad.action = None
