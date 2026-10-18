"""Monta art/heroes/occultist.blend e exporta shared/assets/rrb/heroes/occultist.glb (ADR-0005, ADR-0016 item 8,
SPEC-077).

Mage do KayKit Adventurers 2.0 Extra (CC0) com duas mudancas do projeto (excecao a ADR-0006 so para o
Ocultista, decisao do PI): (1) atlas proprio escuro (preto/roxo) art/heroes/occultist_texture.png, gerado
aqui sobre o LAYOUT do mage_texture (mesmas celulas 8x4; cada celula recebe um degrade vertical de duas
cores, como o atlas KayKit), usado tambem pelo cajado e pelo livro; (2) sem o chapeu pontudo (Mage_Hat):
no lugar, capuz modelado aqui (bmesh, UV na celula da capa), preso ao osso head, cobrindo a cabeca e caindo
sobre os ombros, com a ponta caida para tras. O rosto fica a mostra (palido): sem "rosto preto com dois
olhos brilhando" (ADR-0016 achado 8).
`spellbook_open` em handslot.l e `staff` em handslot.r, na mesma posicao relativa ao osso em que o Mage do
Adventurers 1.0 prende `Spellbook_open` e `2H_Staff`. Animacoes do Knight do Adventurers 1.0 como NLA (o
rig e o mesmo; padrao do build_druid.py).
Uso:
  blender --background --factory-startup --python build_occultist.py -- <extra_dir> <repo> [preview_dir]
"""
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
PACK, REPO = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""
KNIGHT = REPO + r"\shared\assets\kaykit\adventurers\Knight.glb"
MAGE_1 = REPO + r"\shared\assets\kaykit\adventurers\Mage.glb"
ATLAS = REPO + r"\art\heroes\occultist_texture.png"
BLEND = REPO + r"\art\heroes\occultist.blend"
GLB = REPO + r"\shared\assets\rrb\heroes\occultist.glb"

# Animacoes levadas do Knight (as do build_druid.py); -loop no nome = laco no importador do Godot.
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

# Atlas escuro: celula (coluna, linha a partir do topo) -> (cor do topo, cor da base) em sRGB 0-255.
# Papeis medidos no Mage do Extra (UV por malha): (0,0)/(7,2) pele, (1,0) cabelo, (2,0) olhos, (3,0)/(4,0)
# metal e punhos, (5,0) faixa laranja, (0,1) tunica, (2,1) capa, (7,1) calca e cinto, (3,2) botas,
# (0,2) branco; cajado e livro: (3,1) metal, (5,1) madeira e couro, (1,2) capa do livro, (2,2) e (6,2)
# pedra e orbe. Pele palida acinzentada, tunica quase preta, capa e capuz roxo fundo; o laranja, o
# verde e o turquesa viram o lilas vivo do brilho.
SKIN = ((224, 210, 212), (182, 164, 172))
CELLS = {
    (0, 0): SKIN,
    (1, 0): ((46, 40, 54), (14, 11, 18)),
    (2, 0): ((37, 34, 43), (5, 4, 7)),
    (3, 0): ((139, 130, 160), (62, 56, 80)),
    (4, 0): ((76, 67, 96), (34, 28, 46)),
    (5, 0): ((199, 155, 255), (122, 63, 214)),
    (0, 1): ((58, 48, 72), (13, 10, 18)),
    (1, 1): ((58, 48, 72), (13, 10, 18)),
    (2, 1): ((91, 42, 134), (30, 12, 51)),
    (3, 1): ((122, 114, 144), (58, 52, 74)),
    (5, 1): ((74, 54, 70), (30, 20, 30)),
    (7, 1): ((34, 28, 44), (8, 6, 11)),
    (0, 2): ((196, 184, 206), (128, 112, 142)),
    (1, 2): ((110, 44, 143), (42, 15, 59)),
    (2, 2): ((166, 107, 255), (75, 30, 158)),
    (3, 2): ((58, 48, 66), (20, 16, 24)),
    (6, 2): ((227, 200, 255), (106, 43, 208)),
    (7, 2): SKIN,
}
# Celula sem papel no Mage: tom escuro violeta pela luminancia original.
UNUSED = ((107, 90, 128), (12, 9, 16))
HOOD = (2, 1)  # capuz na cor da capa
# Borda de baixo do capuz: sobre os ombros (o corpo do Mage vai ate z 1.31, os bracos saem em z ~1.25).
SHOULDER_Z = 1.06
# Cajado de pe na mao direita no Idle do Knight (mesma rotacao do build_druid.py: o eixo +Z do cajado vai
# para -X do osso handslot.r). O livro fica na posicao do Spellbook_open do Mage 1.0, inclinado para as
# paginas olharem para cima (para a camera do jogo, de cima) em vez de para a frente.
RIGHT_HAND_ROTATION = Matrix(((0.0, 0.0, -1.0), (0.0, -1.0, 0.0), (-1.0, 0.0, 0.0)))
# Mao mais baixa na haste: a lua da ponta sobe acima do capuz.
GRIP_SHIFT = 0.30
# Normal das paginas no Idle (para cima e um pouco para a frente, para a camera do jogo).
BOOK_FACING = Vector((0.0, -0.45, 0.89))


def dark_atlas(source):
    """Pinta o atlas escuro sobre o layout de `source` (imagem 8x4 celulas) e salva em ATLAS."""
    w, h = source.size
    px = np.array(source.pixels[:], dtype=np.float32).reshape(h, w, 4)
    lum = px[:, :, 0] * 0.2126 + px[:, :, 1] * 0.7152 + px[:, :, 2] * 0.0722
    out = np.ones_like(px)
    cw, ch = w // 8, h // 4
    # Linhas da imagem do Blender vao de baixo para cima: t = 1 no topo da celula (parte clara).
    t = (np.arange(ch, dtype=np.float32) + 0.5) / ch
    for col in range(8):
        for row in range(4):
            y0 = h - (row + 1) * ch
            x0 = col * cw
            cell = (slice(y0, y0 + ch), slice(x0, x0 + cw))
            if (col, row) in CELLS:
                top, bottom = (np.array(c, dtype=np.float32) / 255.0 for c in CELLS[(col, row)])
                s = np.repeat(t[:, None], cw, axis=1)
            else:
                top, bottom = (np.array(c, dtype=np.float32) / 255.0 for c in UNUSED)
                s = lum[cell]
            for k in range(3):
                out[cell][:, :, k] = bottom[k] + (top[k] - bottom[k]) * s
    img = bpy.data.images.new("occultist_texture", w, h, alpha=False)
    img.pixels = out.ravel().tolist()
    img.filepath_raw = ATLAS
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def cell_uv(cell, t):
    """UV na celula: t = 1 no topo (parte clara do degrade)."""
    col, row = cell
    return ((col + 0.5) / 8.0, 1.0 - (row + 0.08 + 0.84 * (1.0 - t)) / 4.0)


def head_points(head):
    return [head.matrix_world @ v.co for v in head.data.vertices]


def smoothstep(a, b, x):
    t = min(max((x - a) / (b - a), 0.0), 1.0)
    return t * t * (3.0 - 2.0 * t)


def hood(material, head, shoulder_z):
    """Capuz no espaco do modelo (Z para cima, frente -Y), ajustado a cabeca do Mage em repouso: meia
    elipsoide sobre o cranio, aba sobre a testa, bico caido na nuca e a metade de baixo aberta em sino
    ate os ombros (cai sobre a capa), aberta na frente do rosto e do peito."""
    pts = head_points(head)
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    c = (lo + hi) / 2.0
    half = (hi - lo) / 2.0

    def skull(p):
        # Cranio: acima das bochechas e fora do rosto. O cabelo que desce dos lados sai pela abertura.
        face = p.y < c.y - 0.30 * half.y and p.z < c.z + 0.30 * half.z
        return p.z > c.z - 0.15 * half.z and not face

    # Menor elipsoide (proporcao da caixa) que contem o cranio, com folga.
    k = max(sum(((p - c)[i] / half[i]) ** 2 for i in range(3)) for p in pts if skull(p)) ** 0.5
    r = Vector((half.x * k * 1.04, half.y * k * 1.06, half.z * k * 1.04))
    drop = (c.z - shoulder_z) / 0.81  # ultimo anel mantido (latitude -0.81) na altura dos ombros
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    sphere = bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=1.0)
    unit = {}
    for v in sphere["verts"]:
        n = v.co.copy()  # esfera unitaria: n.z = seno da latitude
        unit[v] = n
        front = max(0.0, -n.y)
        back = max(0.0, n.y)
        if n.z >= 0.0:
            d = Vector((n.x * r.x, n.y * r.y, n.z * r.z))
        else:
            # Metade de baixo: desce ate os ombros, afina no pescoco e abre de leve na borda; atras a
            # barra cai mais, sobre a capa.
            flat = Vector((n.x, n.y, 0.0))
            flat = flat.normalized() if flat.length > 1e-6 else flat
            t = -n.z
            scale = 1.0 - 0.10 * np.sin(np.pi * t) + 0.08 * t
            hang = drop + 0.45 * back ** 1.5 * smoothstep(0.5, 1.0, t)
            d = Vector((flat.x * r.x * scale, flat.y * r.y * scale, -t * hang))
        # Aba da frente: o alto da abertura avanca e desce sobre a testa.
        brim = front * smoothstep(-0.1, 0.45, n.z) * (1.0 - smoothstep(0.75, 1.0, n.z))
        brim *= 1.0 - smoothstep(0.2, 0.75, abs(n.x))
        d.y -= 0.14 * brim
        d.z -= 0.06 * brim
        # Bico de tras: o alto da nuca alonga para tras e cai (capuz de pano, nao chapeu pontudo).
        peak = back ** 2 * smoothstep(0.1, 0.8, n.z) * (1.0 - smoothstep(0.0, 0.6, abs(n.x)))
        d.y += 0.48 * peak
        d.z -= 0.10 * peak
        v.co = c + d
    doomed = []
    for f in bm.faces:
        fc = f.calc_center_median()
        pole = min(unit[v].z for v in f.verts) < -0.9
        if pole or (fc.y < c.y - 0.40 * r.y and fc.z < c.z + 0.30 * r.z):
            doomed.append(f)
    bmesh.ops.delete(bm, geom=doomed, context="FACES")
    bmesh.ops.solidify(bm, geom=list(bm.faces), thickness=0.05)
    bm.normal_update()
    inner = {f for f in bm.faces if f.normal.dot(Vector((c.x, c.y, f.calc_center_median().z)) - f.calc_center_median()) > 0.0}
    zs = [v.co.z for v in bm.verts]
    z0, z1 = min(zs), max(zs)
    for f in bm.faces:
        for loop in f.loops:
            # Lado de dentro no fundo escuro do degrade: sombra no rosto sem pintar o rosto de preto.
            t = 0.0 if f in inner else 0.35 + 0.65 * (loop.vert.co.z - z0) / (z1 - z0)
            loop[uv].uv = cell_uv(HOOD, t)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    for f in bm.faces:
        f.smooth = True
    for e in bm.edges:
        if len(e.link_faces) == 2 and e.calc_face_angle(0.0) > 1.0:
            e.smooth = False
    mesh = bpy.data.meshes.new("Occultist_Hood")
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(material)
    obj = bpy.data.objects.new("Occultist_Hood", mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def bone_relative(path, names):
    """Posicao de cada objeto de `names` relativa ao osso pai, no glb `path`, em repouso."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    rel = {}
    for name in names:
        o = bpy.data.objects[name]
        rig = o.parent
        bone = rig.data.bones[o.parent_bone]
        rig.data.pose_position = "REST"
        bpy.context.view_layer.update()
        rel[name] = (o.parent_bone, (rig.matrix_world @ bone.matrix_local).inverted() @ o.matrix_world)
    return rel


def hold(obj, rig, bone_name, relative):
    bone = rig.data.bones[bone_name]
    obj.parent = rig
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    obj.matrix_world = rig.matrix_world @ bone.matrix_local @ relative


REL = bone_relative(MAGE_1, ("Spellbook_open",))

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=PACK + r"\Characters\gltf\Mage.glb")
rig = bpy.data.objects["Rig_Medium"]
bpy.ops.import_scene.gltf(filepath=KNIGHT)
bpy.ops.import_scene.gltf(filepath=PACK + r"\Assets\gltf\staff.gltf")
bpy.ops.import_scene.gltf(filepath=PACK + r"\Assets\gltf\spellbook_open.gltf")
staff = bpy.data.objects["staff"]
book = bpy.data.objects["spellbook_open"]

# Fora: o Knight (so as acoes ficam), o chapeu e as icosferas de forma de osso do importador.
knight = bpy.data.objects["Rig"]
doomed = [o for o in bpy.data.objects
          if o == knight or o.parent == knight or o.name.startswith("Icosphere") or o.name == "Mage_Hat"]
for o in doomed:
    bpy.data.objects.remove(o, do_unlink=True)

# Atlas escuro no lugar do mage_texture: um so material e uma so imagem para corpo, capuz, cajado e livro.
mage_image = next(i for i in bpy.data.images if i.name.startswith("mage_texture") and i.packed_file)
dark_atlas(mage_image)
atlas = bpy.data.images.load(ATLAS)
atlas.pack()
atlas.name = "occultist_texture"
material = bpy.data.materials["mage"]
material.name = "occultist"
for node in material.node_tree.nodes:
    if node.type == "TEX_IMAGE":
        node.image = atlas
for prop in (staff, book):
    prop.data.materials.clear()
    prop.data.materials.append(material)
for mat in list(bpy.data.materials):
    if mat.users == 0:
        bpy.data.materials.remove(mat)
for image in list(bpy.data.images):
    if image.users == 0:
        bpy.data.images.remove(image)

rig.data.pose_position = "REST"
bpy.context.view_layer.update()
head_mesh = bpy.data.objects["Mage_Head"]
cowl = hood(material, head_mesh, SHOULDER_Z)
hold(cowl, rig, "head", Matrix.Identity(4))
cowl.matrix_world = Matrix.Identity(4)  # modelado no espaco do modelo: fica onde esta
hold(staff, rig, "handslot.r", RIGHT_HAND_ROTATION.to_4x4() @ Matrix.Translation((0.0, 0.0, GRIP_SHIFT)))
hold(book, rig, *REL["Spellbook_open"])
rig.data.pose_position = "POSE"

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


def face_book_up():
    """Gira o livro no proprio centro para as paginas (celula (0,2)) olharem para BOOK_FACING no Idle."""
    idle = bpy.data.actions["Idle-loop"]
    ad.action = idle
    if hasattr(ad, "action_slot"):
        ad.action_slot = idle.slots[0]
    bpy.context.scene.frame_set(int(idle.frame_range[0]))
    uvl = book.data.uv_layers.active
    normal = Vector()
    for poly in book.data.polygons:
        u, v = uvl.data[poly.loop_indices[0]].uv
        if int(u * 8) == 0 and int((1.0 - v) * 4) == 2:
            normal += poly.normal * poly.area
    world = book.matrix_world.copy()
    turn = (world.to_3x3() @ normal).normalized().rotation_difference(BOOK_FACING).to_matrix().to_4x4()
    loc = world.to_translation()
    book.matrix_world = Matrix.Translation(loc) @ turn @ Matrix.Translation(-loc) @ world
    ad.action = None
    bpy.context.scene.frame_set(0)


face_book_up()

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


body = [o for o in bpy.data.objects if o.type == "MESH" and o not in (cowl, staff, book)]
print("RESULT tris", tris(bpy.data.objects), "body", tris(body), "hood", tris([cowl]), "staff", tris([staff]),
      "book", tris([book]))
print("RESULT meshes", [(o.name, o.parent_bone or "") for o in bpy.data.objects if o.type == "MESH"])
print("RESULT actions", sorted(a.name for a in bpy.data.actions))

if PREVIEW:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x = 560
    scene.render.resolution_y = 560
    scene.world = bpy.data.worlds.new("w")
    scene.world.color = (0.30, 0.34, 0.40)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam

    def aim(loc, target):
        cam.location = loc
        cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()

    def pose(name, frac):
        action = bpy.data.actions[name]
        ad.action = action
        if hasattr(ad, "action_slot"):
            ad.action_slot = action.slots[0]
        start, end = action.frame_range
        scene.frame_set(int(start + (end - start) * frac))

    def render(path):
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)

    pose("Idle-loop", 0.0)
    for view, loc in (("front", (0.0, -5.6, 1.9)), ("side", (5.6, 0.0, 1.9)), ("back", (0.0, 5.6, 1.9)),
                      ("three_quarter", (3.4, -4.2, 3.0))):
        aim(loc, (0.0, 0.0, 1.15))
        render(PREVIEW + "\\occultist_%s.png" % view)
    for name, frac in (("Spellcast_Shoot", 0.4), ("Spellcast_Raise", 0.5), ("Running_A-loop", 0.3),
                       ("Hit_B-loop", 0.3), ("Death_A", 0.7)):
        pose(name, frac)
        aim((3.4, -4.2, 3.0), (0.0, 0.0, 1.0))
        render(PREVIEW + "\\occultist_anim_%s.png" % name)
    pose("Idle-loop", 0.0)

    # Lado a lado com o Mage 1.0 do Bruxo de Fogo (pecas escondidas como em fire_wizard.tscn).
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=MAGE_1)
    wizard = [o for o in bpy.data.objects if o not in before]
    for o in wizard:
        if o.name.startswith(("1H_Wand", "Spellbook", "Icosphere")):
            o.hide_render = True
        if o.parent is None:
            o.location.x += 2.4
    wizard_rig = next(o for o in wizard if o.type == "ARMATURE")
    if wizard_rig.animation_data and "Idle" in bpy.data.actions:
        wizard_rig.animation_data.action = bpy.data.actions["Idle"]
    scene.frame_set(1)
    aim((1.2, -6.8, 2.2), (1.2, 0.0, 1.15))
    render(PREVIEW + "\\side_by_side_front.png")
    aim((1.2, 6.8, 2.2), (1.2, 0.0, 1.15))
    render(PREVIEW + "\\side_by_side_back.png")
    # Camera do jogo: 45 graus, 11 u e 14 u do heroi (modelo a 0,78 no jogo -> /0,78 no espaco do modelo).
    scene.render.resolution_x = 480
    scene.render.resolution_y = 270
    cam.data.lens = 35.0
    for dist in (11.0, 14.0):
        d = dist / 0.78
        aim((1.2, -d * 0.7071, 1.0 + d * 0.7071), (1.2, 0.0, 1.0))
        render(PREVIEW + "\\side_by_side_game_%du.png" % int(dist))
