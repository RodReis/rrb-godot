"""Monta art/heroes/druid.blend e exporta shared/assets/rrb/heroes/druid.glb (ADR-0005, SPEC-074).

Druid do KayKit Adventurers 2.0 Extra (CC0, cor original; capuz, folhas e mochila fixos como vem)
+ cajado `druid_staff` preso em handslot.r + animacoes do Knight do KayKit Adventurers 1.0 (CC0):
o rig e o mesmo (23 ossos, mesmos nomes, mesma pose de repouso), entao as acoes servem sem retarget
(padrao do build_engineer.py).
Uso:
  blender --background --factory-startup --python build_druid.py -- <extra_dir> <repo> [preview_dir]
"""
import sys

import bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
PACK, REPO = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""
KNIGHT = REPO + r"\shared\assets\kaykit\adventurers\Knight.glb"
BLEND = REPO + r"\art\heroes\druid.blend"
GLB = REPO + r"\shared\assets\rrb\heroes\druid.glb"

# Animacoes levadas do Knight; -loop no nome = laco no importador do Godot (SPEC-059 par. 5).
ANIMATIONS = {
    "Idle": "Idle-loop",
    "Running_A": "Running_A-loop",
    "Spellcast_Shoot": "Spellcast_Shoot",
    "Spellcast_Raise": "Spellcast_Raise",
    "Spellcast_Long": "Spellcast_Long",
    "Throw": "Throw",
    "Use_Item": "Use_Item",
    "Interact": "Interact",
    "1H_Ranged_Shoot": "1H_Ranged_Shoot",
    "Hit_B": "Hit_B-loop",
    "Death_A": "Death_A",
}
# Cajado no espaco do osso handslot.r, medido nos clipes do Knight: no Idle o osso tem Y = frente do modelo
# e X = baixo, entao o eixo do cajado (+Z local do pack, ponta com a forquilha) vai para -X do osso e o
# cajado fica de pe na mao direita, com a ponta para cima. Colunas = eixos locais do cajado (X, Y, Z) no
# espaco do osso: X -> -Z, Y -> -Y, Z -> -X (mao direita, det +1; a forquilha da ponta fica de lado e
# aparece para a camera de jogo).
RIGHT_HAND_ROTATION = Matrix(((0.0, 0.0, -1.0), (0.0, -1.0, 0.0), (-1.0, 0.0, 0.0)))
# Deslocamento ao longo do cajado (eixo +Z local do pack) para a mao agarrar a haste.
GRIP_SHIFT = 0.0

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=PACK + r"\Characters\gltf\Druid.glb")
rig = bpy.data.objects["Rig_Medium"]
bpy.ops.import_scene.gltf(filepath=KNIGHT)
bpy.ops.import_scene.gltf(filepath=PACK + r"\Assets\gltf\druid_staff.gltf")
staff = bpy.data.objects["druid_staff"]

# Fora: o Knight (so as acoes ficam) e as icosferas de forma de osso do importador.
knight = bpy.data.objects["Rig"]
doomed = [o for o in bpy.data.objects if o == knight or o.parent == knight or o.name.startswith("Icosphere")]
for o in doomed:
    bpy.data.objects.remove(o, do_unlink=True)

# A textura do cajado e o mesmo PNG da do Druid: um so datablock, uma so imagem no glb.
druid_image = next(i for i in bpy.data.images if i.name.startswith("druid_texture") and i.packed_file)
for mat in staff.data.materials:
    for node in mat.node_tree.nodes:
        if node.type == "TEX_IMAGE" and node.image != druid_image:
            node.image = druid_image
for image in list(bpy.data.images):
    if image.users == 0:
        bpy.data.images.remove(image)


def hold(weapon, bone_name, rotation, shift):
    # Filho de osso fica na ponta do osso; o deslocamento do pack o traz de volta para a mao.
    weapon.parent = rig
    weapon.parent_type = "BONE"
    weapon.parent_bone = bone_name
    weapon.matrix_parent_inverse = Matrix.Identity(4)
    back = Vector((0.0, -rig.data.bones[bone_name].length, 0.0))
    weapon.matrix_basis = Matrix.Translation(back) @ rotation.to_4x4() @ Matrix.Translation((0.0, 0.0, shift))


hold(staff, "handslot.r", RIGHT_HAND_ROTATION, GRIP_SHIFT)

missing = [a for a in ANIMATIONS if a not in bpy.data.actions]
if missing:
    raise SystemExit("faltam acoes no Knight.glb: %s" % missing)
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


print("RESULT tris", tris(bpy.data.objects), "staff", tris([staff]))
print("RESULT meshes", [(o.name, o.parent_bone or "") for o in bpy.data.objects if o.type == "MESH"])
print("RESULT actions", sorted(a.name for a in bpy.data.actions))

if PREVIEW:
    import numpy as np

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x = 480
    scene.render.resolution_y = 480
    scene.world = bpy.data.worlds.new("w")
    scene.world.color = (0.30, 0.34, 0.40)
    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    # (clipe, fracoes do clipe): cada clipe vira uma faixa de frames lado a lado.
    CLIPS = (("Idle-loop", (0.0,)), ("Running_A-loop", (0.3,)), ("Spellcast_Shoot", (0.2, 0.4, 0.6)),
             ("Spellcast_Raise", (0.2, 0.5, 0.8)), ("Spellcast_Long", (0.2, 0.5, 0.8)),
             ("Throw", (0.2, 0.45, 0.7)), ("Use_Item", (0.3, 0.6)), ("Interact", (0.5,)),
             ("1H_Ranged_Shoot", (0.2, 0.4, 0.6)), ("Hit_B-loop", (0.3,)), ("Death_A", (0.6,)))
    views = {"front": (3.0, -4.5, 2.6), "side": (5.4, 0.5, 2.2)}

    def shot(view, name, frac):
        cam.location = views[view]
        direction = Vector((0.0, 0.0, 1.25)) - cam.location
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        action = bpy.data.actions[name]
        ad.action = action
        if hasattr(ad, "action_slot"):
            ad.action_slot = action.slots[0]
        start, end = action.frame_range
        scene.frame_set(int(start + (end - start) * frac))
        path = PREVIEW + "\\_tmp.png"
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        img = bpy.data.images.load(path, check_existing=False)
        px = np.array(img.pixels[:], dtype=np.float32).reshape(img.size[1], img.size[0], 4)
        bpy.data.images.remove(img)
        return px

    def save_strip(path, frames):
        strip = np.concatenate(frames, axis=1)
        out = bpy.data.images.new("strip", strip.shape[1], strip.shape[0], alpha=True)
        out.pixels = strip.ravel().tolist()
        out.filepath_raw = path
        out.file_format = "PNG"
        out.save()
        bpy.data.images.remove(out)

    for view in views:
        for name, fracs in CLIPS:
            save_strip(PREVIEW + "\\%s_%s.png" % (view, name), [shot(view, name, f) for f in fracs])
    ad.action = None
