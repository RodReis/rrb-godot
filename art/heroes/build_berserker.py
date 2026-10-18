"""Monta art/heroes/berserker.blend e exporta shared/assets/rrb/heroes/berserker.glb (ADR-0005, SPEC-075).

Barbarian_Large do KayKit Adventurers 2.0 Extra (CC0) com textura alternativa (alt_A/B/C, escolha do PI
no aceite), sem o chapeu de urso: no lugar, elmo viking de chifres modelado aqui (decisao do PI em
2026-10-18), colorido pelo proprio atlas da textura (aco e marfim, celulas iguais nas 4 texturas).
Dois axe_1handed_Large do Extra em handslot.l e handslot.r, presos como o pack prende as armas no rig
medio (mesma rotacao relativa ao osso). Rig_Large: as acoes do pack (Idle_A, Running_A, Hit_A, Death_A)
e, como o Rig_Large nao tem ataque, acoes do Knight do Adventurers 1.0 (CC0): os ossos tem os mesmos
nomes e a mesma orientacao de repouso (diferenca 0 grau, so a escala muda), entao a rotacao serve como
vem e a translacao e escalada pela altura do quadril. Ossos de IK do Knight ficam de fora.
Uso:
  blender --background --factory-startup --python build_berserker.py -- <extra_dir> <repo> <A|B|C> [preview_dir]
"""
import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
PACK, REPO, ALT = argv[0], argv[1], argv[2].upper()
PREVIEW = argv[3] if len(argv) > 3 else ""
KNIGHT = REPO + r"\shared\assets\kaykit\adventurers\Knight.glb"
BLEND = REPO + r"\art\heroes\berserker.blend"
GLB = REPO + r"\shared\assets\rrb\heroes\berserker.glb"

# Acoes do pack (Rig_Large) e do Knight; -loop no nome = laco no importador do Godot.
LARGE_ANIMATIONS = {
    "Idle_A": "Idle_A-loop",
    "Running_A": "Running_A-loop",
    "Hit_A": "Hit_A-loop",
    "Death_A": "Death_A",
}
KNIGHT_ANIMATIONS = {
    "Dualwield_Melee_Attack_Chop": "Dualwield_Melee_Attack_Chop",
    "Dualwield_Melee_Attack_Slice": "Dualwield_Melee_Attack_Slice",
    "Throw": "Throw",
    "Cheer": "Cheer",
    "Spellcast_Raise": "Spellcast_Raise",
}
# Arma relativa a cabeca do handslot no pack (rig medio, Barbarian.glb: 1H_Axe e 1H_Axe_Offhand):
# translacao no eixo Y do osso (escalada pelo comprimento do osso) e rotacao (linhas da 3x3).
SLOT_OFFSET_RATIO = 0.033 / 0.112
RIGHT_HAND = Matrix(((-1.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)))
LEFT_HAND = Matrix(((1.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, -1.0, 0.0)))

# Celulas do atlas 8x4 (coluna, linha a partir do topo), iguais nas 4 texturas do Barbarian.
STEEL = (3, 0)
STEEL_DARK = (3, 1)
HORN = (1, 3)


def cell_uv(cell, t):
    """UV na celula: t = 1 no topo (parte clara do degrade)."""
    col, row = cell
    return ((col + 0.5) / 8.0, 1.0 - (row + 0.15 + 0.7 * (1.0 - t)) / 4.0)


class Shape:
    """Malha por bmesh com UV numa celula do atlas, degrade pela altura de cada parte."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.parts = []

    def add(self, verts, cell):
        faces = {f for v in verts for f in v.link_faces}
        self.parts.append((faces, cell))

    def dome(self, cell, center, rx, ry, rz, segs, rings):
        m = Matrix.Translation(center) @ Matrix.Diagonal((rx, ry, rz, 1.0))
        r = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=rings, radius=1.0, matrix=m)
        cut = [v for v in r["verts"] if v.co.z < center[2] - 1e-4]
        bmesh.ops.delete(self.bm, geom=cut, context="VERTS")
        self.add([v for v in r["verts"] if v.is_valid], cell)

    def ring(self, cell, center, rx, ry, z0, z1, segs):
        m = Matrix.Translation((center[0], center[1], (z0 + z1) / 2.0)) @ Matrix.Diagonal((1.0, ry / rx, 1.0, 1.0))
        r = bmesh.ops.create_cone(self.bm, cap_ends=False, segments=segs, radius1=rx, radius2=rx, depth=z1 - z0, matrix=m)
        self.add(r["verts"], cell)

    def box(self, cell, center, size):
        m = Matrix.Translation(center) @ Matrix.Diagonal((*size, 1.0))
        r = bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)
        self.add(r["verts"], cell)

    def segment(self, cell, a, b, r0, r1, segs):
        """Tronco de cone de a ate b (raio r0 em a, r1 em b)."""
        axis = Vector(b) - Vector(a)
        rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
        m = Matrix.Translation((Vector(a) + Vector(b)) / 2.0) @ rot
        r = bmesh.ops.create_cone(self.bm, cap_ends=True, segments=segs, radius1=r0, radius2=r1, depth=axis.length, matrix=m)
        self.add(r["verts"], cell)

    def build(self, material):
        bm = self.bm
        for faces, cell in self.parts:
            zs = [v.co.z for f in faces for v in f.verts]
            lo, hi = min(zs), max(zs)
            span = max(hi - lo, 1e-4)
            for f in faces:
                for loop in f.loops:
                    loop[self.uv].uv = cell_uv(cell, (loop.vert.co.z - lo) / span)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        mesh = bpy.data.meshes.new(self.name)
        bm.to_mesh(mesh)
        bm.free()
        for poly in mesh.polygons:
            poly.use_smooth = False
        mesh.materials.append(material)
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        return obj


def horned_helmet(material):
    # Medidas pela cabeca do Barbarian_Large em repouso: x +-0.434, y -0.711..0.077 (frente -Y),
    # z 3.094..3.967; o elmo cobre do alto da testa para cima.
    # O aro fica acima dos olhos: na camera do jogo (de cima, heroi curvado) o rosto aparece (PI
    # 2026-10-18).
    cy, base, top = -0.31, 3.72, 3.725
    h = Shape("Berserker_Helmet")
    h.dome(STEEL, (0.0, cy, top), 0.49, 0.46, 0.44, 14, 8)
    h.ring(STEEL_DARK, (0.0, cy), 0.52, 0.49, base - 0.05, base + 0.08, 14)  # aro
    h.box(STEEL_DARK, (0.0, cy - 0.49, base - 0.07), (0.09, 0.07, 0.22))  # nasal
    h.box(STEEL_DARK, (0.0, cy, top + 0.30), (0.08, 0.98, 0.10))  # crista de frente a tras
    for side in (-1.0, 1.0):
        # Chifre: sai do lado do elmo, vai para fora e curva para cima (5 trechos, afinando).
        pts = []
        for i in range(6):
            t = i / 5.0
            pts.append(Vector((side * (0.44 + 0.42 * t), cy - 0.05 - 0.10 * t, top + 0.12 + 0.62 * t * t)))
        for i in range(5):
            r0 = 0.15 * (1.0 - i / 5.0) + 0.012
            r1 = 0.15 * (1.0 - (i + 1) / 5.0) + 0.012
            h.segment(HORN, pts[i], pts[i + 1], r0, r1, 8)
    return h.build(material)


def hold(obj, rig, bone_name, rotation):
    bone = rig.data.bones[bone_name]
    offset = Matrix.Translation((0.0, SLOT_OFFSET_RATIO * bone.length, 0.0))
    obj.parent = rig
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    obj.matrix_world = rig.matrix_world @ bone.matrix_local @ offset @ rotation.to_4x4()


def channelbag(action):
    """F-curves da acao (acoes em camadas do Blender 4.4+; uma camada, uma faixa, um slot)."""
    if hasattr(action, "layers") and len(action.layers) > 0:
        strip = action.layers[0].strips[0]
        return strip.channelbag(action.slots[0])
    return action


def retarget(action, bones, scale):
    """Tira curvas de ossos que o Rig_Large nao tem e escala a translacao."""
    bag = channelbag(action)
    for fc in list(bag.fcurves):
        path = fc.data_path
        if path.startswith('pose.bones["'):
            name = path.split('"')[1]
            if name not in bones:
                bag.fcurves.remove(fc)
                continue
        if path.endswith(".location"):
            for kp in fc.keyframe_points:
                kp.co.y *= scale
                kp.handle_left.y *= scale
                kp.handle_right.y *= scale


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=PACK + r"\Characters\gltf\Barbarian_Large.glb")
rig = bpy.data.objects["Rig_Large"]
large_actions = set(bpy.data.actions)
bpy.ops.import_scene.gltf(filepath=PACK + r"\Animations\gltf\Rig_Large\Rig_Large_General.glb")
bpy.ops.import_scene.gltf(filepath=PACK + r"\Animations\gltf\Rig_Large\Rig_Large_MovementBasic.glb")
pack_actions = {a.name: a for a in bpy.data.actions if a not in large_actions}
before = set(bpy.data.actions)
bpy.ops.import_scene.gltf(filepath=KNIGHT)
knight_actions = {a.name: a for a in bpy.data.actions if a not in before}
knight = bpy.data.objects["Rig"]
knight_hips = knight.data.bones["hips"].head_local.z
for path in ("axe_1handed_Large.gltf", "axe_1handed_Large.gltf"):
    bpy.ops.import_scene.gltf(filepath=PACK + r"\Assets\gltf\%s" % path)
axes = sorted((o for o in bpy.data.objects if o.name.startswith("axe_1handed_Large")), key=lambda o: o.name)

# Fora: rigs das animacoes, o Knight, o chapeu de urso e as icosferas de forma de osso.
keep = {rig} | set(rig.children) | set(axes)
for o in list(bpy.data.objects):
    if o not in keep or o.name.startswith("Icosphere") or o.name == "Barbarian_Large_BearHat":
        bpy.data.objects.remove(o, do_unlink=True)

# Textura alternativa no lugar da original (mesmo layout de atlas); o machado usa o mesmo PNG.
alt = bpy.data.images.load(PACK + r"\Textures\barbarian_texture_alt_%s.png" % ALT)
alt.pack()
alt.name = "berserker_texture"
material = bpy.data.materials["barbarian"]
for mat in bpy.data.materials:
    if mat.node_tree is None:
        continue
    for node in mat.node_tree.nodes:
        if node.type == "TEX_IMAGE":
            node.image = alt
for axe in axes:
    axe.data.materials.clear()
    axe.data.materials.append(material)
for image in list(bpy.data.images):
    if image.users == 0:
        bpy.data.images.remove(image)

helmet = horned_helmet(material)
hold(helmet, rig, "head", Matrix.Identity(3))
helmet.matrix_world = Matrix.Identity(4)  # modelado no espaco do modelo: fica onde esta
axes[0].name = "Axe_R"
axes[1].name = "Axe_L"
hold(axes[0], rig, "handslot.r", RIGHT_HAND)
hold(axes[1], rig, "handslot.l", LEFT_HAND)

scale = rig.data.bones["hips"].head_local.z / knight_hips
bones = {b.name for b in rig.data.bones}
wanted = {}
for src, dst in LARGE_ANIMATIONS.items():
    wanted[dst] = pack_actions[src]
for src, dst in KNIGHT_ANIMATIONS.items():
    action = knight_actions[src]
    retarget(action, bones, scale)
    wanted[dst] = action
ad = rig.animation_data_create()
for dst, action in wanted.items():
    action.name = dst
    track = ad.nla_tracks.new()
    track.name = dst
    strip = track.strips.new(dst, int(action.frame_range[0]), action)
    if hasattr(strip, "action_slot") and len(action.slots) > 0:
        strip.action_slot = action.slots[0]
    track.mute = True
for action in list(bpy.data.actions):
    if action not in wanted.values():
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
    return sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objects if o.type == "MESH")


rig.data.pose_position = "REST"
bpy.context.view_layer.update()
top = max((o.matrix_world @ Vector(c)).z for o in bpy.data.objects if o.type == "MESH" for c in o.bound_box)
rig.data.pose_position = "POSE"
print("RESULT tris", tris(bpy.data.objects), "helmet", tris([helmet]), "axes", tris(axes))
print("RESULT height", round(top, 3), "hips_scale", round(scale, 3))
print("RESULT meshes", [(o.name, o.parent_bone or "") for o in bpy.data.objects if o.type == "MESH"])
print("RESULT actions", sorted(a.name for a in bpy.data.actions))

if PREVIEW:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x = 520
    scene.render.resolution_y = 520
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    shots = (("Idle_A-loop", 0.0), ("Dualwield_Melee_Attack_Chop", 0.45), ("Dualwield_Melee_Attack_Slice", 0.45),
             ("Throw", 0.45), ("Cheer", 0.5), ("Spellcast_Raise", 0.5), ("Running_A-loop", 0.3))
    for view, loc in (("front", (3.6, -7.0, 3.6)), ("side", (7.6, 0.6, 3.2))):
        cam.location = loc
        direction = Vector((0.0, 0.0, 2.2)) - cam.location
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        for name, frac in shots if view == "front" else shots[:1]:
            action = bpy.data.actions[name]
            ad.action = action
            if hasattr(ad, "action_slot"):
                ad.action_slot = action.slots[0]
            start, end = action.frame_range
            scene.frame_set(int(start + (end - start) * frac))
            scene.render.filepath = PREVIEW + "\\%s_%s_%s.png" % (ALT, view, name)
            bpy.ops.render.render(write_still=True)
    ad.action = None
