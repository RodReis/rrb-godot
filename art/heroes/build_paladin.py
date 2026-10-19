"""Monta art/heroes/paladin.blend e exporta shared/assets/rrb/heroes/paladin.glb (ADR-0005, SPEC-076).

Knight do KayKit Adventurers 2.0 Extra (CC0) com a textura alternativa knight_texture_alt_B (cinza e
dourado), sem o elmo e sem a viseira (excecao do ADR-0011 item 3: o rosto e o cabelo ficam a mostra).
Escudo do pack Extra diferente do Badge_Shield do Cavaleiro (escolha do PI no aceite, parametro <shield>),
preso em handslot.l na mesma posicao relativa ao osso em que o Knight do Adventurers 1.0 prende os escudos
(mesma malha de origem). Maca modelada aqui (bmesh, ~260 triangulos, cor pelas celulas do proprio atlas
do Knight) em handslot.r, no referencial da 1H_Sword do Knight 1.0 (haste em +Z, punho na origem).
Animacoes do Knight do Adventurers 1.0 como NLA (o rig e o mesmo; padrao do build_druid.py).
Uso:
  blender --background --factory-startup --python build_paladin.py -- <extra_dir> <repo> <shield> [preview_dir]
  <shield>: square | square_color | round | round_color | spikes | spikes_color
"""
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
PACK, REPO, SHIELD = argv[0], argv[1], argv[2]
PREVIEW = argv[3] if len(argv) > 3 else ""
KNIGHT = REPO + r"\shared\assets\kaykit\adventurers\Knight.glb"
BLEND = REPO + r"\art\heroes\paladin.blend"
GLB = REPO + r"\shared\assets\rrb\heroes\paladin.glb"
ALT_B = PACK + r"\Textures\knight_texture_alt_B.png"

# Escudo do Extra -> escudo do Knight 1.0 com a mesma malha (de quem copia a posicao no osso).
SHIELDS = {
    "square": "Rectangle_Shield",
    "square_color": "Rectangle_Shield",
    "round": "Round_Shield",
    "round_color": "Round_Shield",
    "spikes": "Spike_Shield",
    "spikes_color": "Spike_Shield",
}
if SHIELD not in SHIELDS:
    raise SystemExit("escudo invalido: %s (use %s)" % (SHIELD, ", ".join(SHIELDS)))

# Animacoes levadas do Knight; -loop no nome = laco no importador do Godot.
ANIMATIONS = {
    "Idle": "Idle-loop",
    "Running_A": "Running_A-loop",
    "1H_Melee_Attack_Slice_Diagonal": "1H_Melee_Attack_Slice_Diagonal",
    "1H_Melee_Attack_Chop": "1H_Melee_Attack_Chop",
    "Block": "Block",
    "Cheer": "Cheer",
    "Interact": "Interact",
    "Hit_B": "Hit_B-loop",
    "Death_A": "Death_A",
}

# Celulas do atlas 8x4 do Knight (coluna, linha a partir do topo); na alt_B: aco claro, aco, ouro, couro.
STEEL = (3, 1)
STEEL_LIGHT = (7, 0)
GOLD = (0, 1)
LEATHER = (5, 1)


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

    def cylinder(self, cell, z0, z1, r0, r1, segs, caps=True):
        m = Matrix.Translation((0.0, 0.0, (z0 + z1) / 2.0))
        r = bmesh.ops.create_cone(self.bm, cap_ends=caps, segments=segs, radius1=r0, radius2=r1, depth=z1 - z0, matrix=m)
        self.add(r["verts"], cell)

    def sphere(self, cell, z, radius, segs, rings):
        m = Matrix.Translation((0.0, 0.0, z))
        r = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=rings, radius=radius, matrix=m)
        self.add(r["verts"], cell)

    def box(self, cell, center, size, angle):
        m = Matrix.Rotation(angle, 4, "Z") @ Matrix.Translation(center) @ Matrix.Diagonal((*size, 1.0))
        r = bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)
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
        mesh = bpy.data.meshes.new(self.name)
        bm.to_mesh(mesh)
        bm.free()
        for poly in mesh.polygons:
            poly.use_smooth = False
        mesh.materials.append(material)
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        return obj


def mace(material):
    """Maca de flanges no referencial da 1H_Sword do Knight 1.0: haste em +Z, punho na origem, pomo em
    z ~ -0.36 e topo em z ~ 1.05 (a espada vai de -0.37 a 1.41; a maca e mais curta e mais pesada)."""
    m = Shape("mace")
    m.sphere(GOLD, -0.33, 0.07, 8, 4)  # pomo
    m.cylinder(LEATHER, -0.30, 0.52, 0.05, 0.05, 8, caps=False)  # cabo
    m.cylinder(GOLD, 0.48, 0.56, 0.08, 0.09, 8)  # colar
    m.cylinder(STEEL, 0.56, 0.88, 0.14, 0.14, 8)  # cabeca
    m.cylinder(STEEL, 0.88, 1.05, 0.14, 0.02, 8)  # ponta
    for i in range(6):  # flanges
        angle = i * 3.14159265 / 3.0
        m.box(STEEL_LIGHT, (0.19, 0.0, 0.72), (0.14, 0.04, 0.32), angle)
    return m.build(material)


def hold(obj, rig, bone_name, basis):
    obj.parent = rig
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.matrix_basis = basis


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=PACK + r"\Characters\gltf\Knight.glb")
rig = bpy.data.objects["Rig_Medium"]
bpy.ops.import_scene.gltf(filepath=KNIGHT)
knight = bpy.data.objects["Rig"]
sword_basis = bpy.data.objects["1H_Sword"].matrix_basis.copy()
shield_basis = bpy.data.objects[SHIELDS[SHIELD]].matrix_basis.copy()
bpy.ops.import_scene.gltf(filepath=PACK + r"\Assets\gltf\shield_%s.gltf" % SHIELD)
shield = bpy.data.objects["shield_" + SHIELD]
shield.name = "shield"

# Fora: o Knight 1.0 (so as acoes ficam), o elmo e a viseira do Extra e as icosferas de forma de osso.
doomed = [
    o for o in bpy.data.objects
    if o == knight or o.parent == knight or o.name.startswith("Icosphere")
    or o.name in ("Knight_Helmet", "Knight_HelmetVisor")
]
for o in doomed:
    bpy.data.objects.remove(o, do_unlink=True)

# Textura alt_B no corpo e no escudo: um so material, uma so imagem embutida no glb.
alt_b = bpy.data.images.load(ALT_B)
alt_b.name = "knight_texture_alt_B"
alt_b.pack()
body_material = bpy.data.objects["Knight_Body"].data.materials[0]
for node in body_material.node_tree.nodes:
    if node.type == "TEX_IMAGE":
        node.image = alt_b
shield.data.materials[0] = body_material
for image in list(bpy.data.images):
    if image.users == 0:
        bpy.data.images.remove(image)
for material in list(bpy.data.materials):
    if material.users == 0:
        bpy.data.materials.remove(material)

hold(shield, rig, "handslot.l", shield_basis)
weapon = mace(body_material)
hold(weapon, rig, "handslot.r", sword_basis)

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


print("RESULT tris", tris(bpy.data.objects), "mace", tris([weapon]), "shield", tris([shield]))
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
    CLIPS = (("Idle-loop", (0.0,)), ("Running_A-loop", (0.3,)),
             ("1H_Melee_Attack_Slice_Diagonal", (0.2, 0.4, 0.6)), ("1H_Melee_Attack_Chop", (0.2, 0.4, 0.6)),
             ("Block", (0.3, 0.6)), ("Cheer", (0.3, 0.6)), ("Hit_B-loop", (0.3,)), ("Death_A", (0.6,)))
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
