"""Monta art/heroes/equipment/equipment.blend, exporta as pecas em shared/assets/rrb/equipment/ e
renderiza os icones em shared/ui/icons/items/ (SPEC-048, ADR-0005, ADR-0010).

Pecas rigidas: cada objeto e modelado no espaco do modelo do heroi em pose de repouso (Z para
cima, frente -Y; o rig do Knight, do Ranger, do Barbarian, do Mage, do Rogue e do Engineer e o mesmo) e se chama "<peca>__<osso>" com "." do
osso trocado por "_" (o Godot nao aceita "." em nome de no). O HeroVisual prende cada objeto ao
osso por BoneAttachment3D. Raridade = mesma forma, acabamento diferente: comum liso; raro com
friso azul; epico com friso dourado e detalhe roxo (PATTERNS P6). Cores pelo atlas KayKit
hexagons_medieval; o atlas nao tem roxo, entao o detalhe epico usa um material liso PURPLE.
Arma comum = peca do pack como vem; rara/epica derivadas dela.

Uso:
  blender --background --factory-startup --python build_equipment.py -- <repo> [preview_dir]
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
REPO = argv[0]
PREVIEW = argv[1] if len(argv) > 1 else ""
ATLAS = os.path.join(REPO, "shared", "assets", "kaykit", "medieval_hexagon", "hexagons_medieval.png")
KNIGHT = os.path.join(REPO, "shared", "assets", "kaykit", "adventurers", "Knight.glb")
RANGER = os.path.join(REPO, "shared", "assets", "rrb", "heroes", "ranger.glb")
BARBARIAN = os.path.join(REPO, "shared", "assets", "kaykit", "adventurers", "Barbarian.glb")
MAGE = os.path.join(REPO, "shared", "assets", "kaykit", "adventurers", "Mage.glb")
ROGUE = os.path.join(REPO, "shared", "assets", "rrb", "heroes", "rogue.glb")
ENGINEER = os.path.join(REPO, "shared", "assets", "rrb", "heroes", "engineer.glb")
DRUID = os.path.join(REPO, "shared", "assets", "rrb", "heroes", "druid.glb")
BERSERKER = os.path.join(REPO, "shared", "assets", "rrb", "heroes", "berserker.glb")
OCCULTIST = os.path.join(REPO, "shared", "assets", "rrb", "heroes", "occultist.glb")
BLEND = os.path.join(REPO, "art", "heroes", "equipment", "equipment.blend")
OUT = os.path.join(REPO, "shared", "assets", "rrb", "equipment")
ICONS = os.path.join(REPO, "shared", "ui", "icons", "items")

TRIS_MIN, TRIS_MAX = 50, 800
# Arma do pack acima disto (o shotgun tem 1.120) e reduzida no Blender, para sobrar orcamento ao enfeite.
WEAPON_BASE_MAX = 700
# Cajado do Druida (1.062 no pack): base menor, o enfeite epico (colar, pontas, pedra) soma ~110.
BASE_MAX_BY_HERO = {"druid": 640}
ICON_SIZE = 128
# Token PURPLE (#A855F7) em sRGB; o material converte para linear.
PURPLE_SRGB = (0.659, 0.333, 0.969)

# Celulas do atlas 8x4 (coluna, linha a partir do topo); cada celula e um degrade vertical.
STEEL = (2, 0)
STEEL_DARK = (3, 0)
BLACK = (0, 0)
# Enfeite com 3o valor: tom fixo no degrade (1 = topo), sem escurecer pela altura.
GOLD = (3, 1, 0.9)
BLUE = (1, 1, 0.55)
LEATHER = (2, 1)
LEATHER_DARK = (7, 1)
TAN = (5, 1)
HOOD = (1, 2)
EPIC = "epic"  # material liso roxo
RARITY_TRIM = [STEEL_DARK, BLUE, GOLD]  # indice = raridade

# ---------------------------------------------------------------------------------------------
# Cena e materiais


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def make_materials():
    atlas = bpy.data.materials.new("equipment_atlas")
    atlas.use_nodes = True
    nodes = atlas.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.7
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ATLAS)
    atlas.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    epic = bpy.data.materials.new("rarity_epic")
    epic.use_nodes = True
    ebsdf = epic.node_tree.nodes["Principled BSDF"]
    ebsdf.inputs["Base Color"].default_value = (*[srgb_to_linear(c) for c in PURPLE_SRGB], 1.0)
    ebsdf.inputs["Roughness"].default_value = 0.35
    return atlas, epic


# ---------------------------------------------------------------------------------------------
# Construcao por bmesh: cada parte recebe material e UV na celula do atlas (degrade pela altura)


class Piece:
    """Uma malha de uma peca presa a um osso."""

    def __init__(self, name, bone):
        self.name = name
        self.bone = bone
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.parts = []  # (faces, cell)

    def add(self, geom_verts, cell):
        faces = set()
        for v in geom_verts:
            faces.update(v.link_faces)
        self.parts.append((list(faces), cell))
        return faces

    def cylinder(self, cell, center, r_bottom, r_top, z0, z1, segs, sy=1.0, caps=True, rot=0.0):
        m = Matrix.Translation((center[0], center[1], (z0 + z1) / 2.0))
        m = m @ Matrix.Rotation(rot, 4, "Z") @ Matrix.Diagonal((1.0, sy, 1.0, 1.0))
        r = bmesh.ops.create_cone(
            self.bm, cap_ends=caps, cap_tris=False, segments=segs,
            radius1=r_bottom, radius2=r_top, depth=z1 - z0, matrix=m,
        )
        return self.add(r["verts"], cell)

    def box(self, cell, center, size, rot=None):
        m = Matrix.Translation(center)
        if rot is not None:
            m = m @ rot
        m = m @ Matrix.Diagonal((*size, 1.0))
        r = bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)
        return self.add(r["verts"], cell)

    def dome(self, cell, center, rx, ry, rz, segs, rings, keep_below=False):
        """Meia elipsoide acima de center (ou abaixo, com keep_below)."""
        m = Matrix.Translation(center) @ Matrix.Diagonal((rx, ry, rz, 1.0))
        r = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=rings, radius=1.0, matrix=m)
        verts = r["verts"]
        if keep_below:
            cut = [v for v in verts if v.co.z > center[2] + 1e-4]
        else:
            cut = [v for v in verts if v.co.z < center[2] - 1e-4]
        bmesh.ops.delete(self.bm, geom=cut, context="VERTS")
        return self.add([v for v in verts if v.is_valid], cell)

    def gem(self, cell, center, size):
        """size: raio (achatado em Y, frente/tras) ou (x, y, z)."""
        if not isinstance(size, tuple):
            size = (size, size * 0.6, size * 1.2)
        m = Matrix.Translation(center) @ Matrix.Diagonal((*size, 1.0))
        r = bmesh.ops.create_icosphere(self.bm, subdivisions=1, radius=1.0, matrix=m)
        return self.add(r["verts"], cell)

    def build(self, atlas, epic, extra_materials=()):
        bm = self.bm
        bm.faces.ensure_lookup_table()
        zs = [v.co.z for v in bm.verts] or [0.0]  # arma comum: sem enfeite
        z_lo, z_hi = min(zs), max(zs)
        span = max(z_hi - z_lo, 1e-4)
        mats = list(extra_materials) + [atlas, epic]
        for faces, cell in self.parts:
            for f in faces:
                if not f.is_valid:
                    continue
                if cell == EPIC:
                    f.material_index = mats.index(epic)
                    continue
                f.material_index = mats.index(atlas)
                col, row = cell[0], cell[1]
                for loop in f.loops:
                    # 1 = topo = parte clara do degrade
                    t = cell[2] if len(cell) > 2 else (loop.vert.co.z - z_lo) / span
                    u = (col + 0.5) / 8.0
                    v = 1.0 - (row + 0.15 + 0.7 * (1.0 - t)) / 4.0
                    loop[self.uv].uv = (u, v)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        mesh = bpy.data.meshes.new(self.name)
        bm.to_mesh(mesh)
        bm.free()
        for poly in mesh.polygons:
            poly.use_smooth = False
        for mat in mats:
            mesh.materials.append(mat)
        obj = bpy.data.objects.new(self.name, mesh)
        return obj


def obj_name(piece, bone):
    return piece + "__" + bone.replace(".", "_")


# ---------------------------------------------------------------------------------------------
# Conjunto Guarda (placa de metal)


def guard_helm(name, rarity):
    # Medidas pela cabeca dos dois herois (a da Arqueira tem a aba do capuz mais alta): o maior
    # vertice fica a ~95 % do raio do elmo.
    p = Piece(obj_name(name, "head"), "head")
    p.cylinder(STEEL, (0.0, -0.04), 0.64, 0.64, 1.30, 1.92, 12)
    p.dome(STEEL, (0.0, -0.04, 1.92), 0.64, 0.64, 0.70, 12, 8)
    p.box(BLACK, (0.0, -0.665, 1.66), (0.72, 0.06, 0.08))  # viseira
    p.box(STEEL_DARK, (0.0, -0.68, 1.70), (0.08, 0.06, 0.56))  # nasal
    p.cylinder(RARITY_TRIM[rarity], (0.0, -0.04), 0.665, 0.66, 1.28, 1.37, 12, caps=False)
    if rarity == 2:
        p.box(GOLD, (0.0, -0.04, 2.58), (0.08, 0.95, 0.18))  # crista
        p.gem(EPIC, (0.0, -0.69, 1.90), 0.07)
    return [p]


def guard_chest(name, rarity):
    p = Piece(obj_name(name, "chest"), "chest")
    p.cylinder(STEEL, (0.0, 0.03), 0.45, 0.42, 0.80, 1.30, 10)
    p.box(STEEL_DARK, (0.0, -0.43, 1.06), (0.07, 0.05, 0.40))  # quilha
    trim = RARITY_TRIM[rarity]
    p.cylinder(trim, (0.0, 0.03), 0.47, 0.465, 0.78, 0.87, 10, caps=False)  # cinto
    for side in (-1.0, 1.0):
        p.dome(STEEL_DARK, (side * 0.40, 0.02, 1.20), 0.21, 0.21, 0.16, 8, 6)  # ombreira
        p.cylinder(trim, (side * 0.40, 0.02), 0.22, 0.22, 1.17, 1.21, 8, caps=False)
    if rarity == 2:
        p.gem(EPIC, (0.0, -0.47, 1.14), 0.07)
    return [p]


def guard_boots(name, rarity):
    pieces = []
    for side, suffix in ((1.0, "l"), (-1.0, "r")):
        x = side * 0.17
        shaft = Piece(obj_name(name, "lowerleg." + suffix), "lowerleg." + suffix)
        shaft.cylinder(STEEL, (x, -0.01), 0.155, 0.165, 0.12, 0.36, 8)
        shaft.box(STEEL_DARK, (x, -0.18, 0.37), (0.16, 0.06, 0.12))  # joelheira
        shaft.cylinder(RARITY_TRIM[rarity], (x, -0.01), 0.175, 0.175, 0.31, 0.36, 8, caps=False)
        if rarity == 2:
            shaft.gem(EPIC, (x, -0.19, 0.24), 0.05)
        shoe = Piece(obj_name(name, "foot." + suffix), "foot." + suffix)
        shoe.box(STEEL_DARK, (x, -0.09, 0.075), (0.27, 0.46, 0.15))
        shoe.box(STEEL, (x, -0.30, 0.10), (0.22, 0.10, 0.10))  # biqueira
        pieces += [shaft, shoe]
    return pieces


# ---------------------------------------------------------------------------------------------
# Conjunto Cacador (couro e capuz)


def hunter_helm(name, rarity):
    p = Piece(obj_name(name, "head"), "head")
    m = Matrix.Translation((0.0, 0.02, 1.78)) @ Matrix.Diagonal((0.64, 0.62, 0.70, 1.0))
    r = bmesh.ops.create_uvsphere(p.bm, u_segments=14, v_segments=9, radius=1.0, matrix=m)
    verts = r["verts"]
    doomed = []
    for f in {f for v in verts for f in v.link_faces}:
        c = f.calc_center_median()
        if c.z < 1.30 or (c.y < -0.22 and c.z < 2.12):
            doomed.append(f)
    bmesh.ops.delete(p.bm, geom=doomed, context="FACES")
    shell = [v for v in verts if v.is_valid]
    faces = list({f for v in shell for f in v.link_faces})
    # Espessura (o capuz e uma casca aberta na frente).
    bmesh.ops.solidify(p.bm, geom=faces, thickness=0.04)
    p.add([v for v in p.bm.verts], HOOD)
    p.cylinder(LEATHER, (0.0, 0.04), 0.50, 0.44, 1.12, 1.34, 12)  # gola sobre os ombros
    p.cylinder(RARITY_TRIM[rarity] if rarity else LEATHER_DARK, (0.0, 0.04), 0.515, 0.51, 1.10, 1.17, 12, caps=False)
    tip = Matrix.Translation((0.0, 0.52, 2.22)) @ Matrix.Rotation(math.radians(-60.0), 4, "X")
    r = bmesh.ops.create_cone(p.bm, cap_ends=True, segments=6, radius1=0.12, radius2=0.0, depth=0.30, matrix=tip)
    p.add(r["verts"], HOOD)
    if rarity == 2:
        p.gem(EPIC, (0.0, -0.44, 1.24), 0.07)  # broche
    return [p]


def hunter_chest(name, rarity):
    p = Piece(obj_name(name, "chest"), "chest")
    p.cylinder(LEATHER, (0.0, 0.03), 0.44, 0.41, 0.80, 1.28, 10)
    p.cylinder(LEATHER_DARK, (0.0, 0.03), 0.465, 0.46, 0.78, 0.87, 10, caps=False)  # cinto
    sash = Matrix.Rotation(math.radians(40.0), 4, "Y")
    p.box(LEATHER_DARK, (0.0, -0.44, 1.05), (0.80, 0.04, 0.09), rot=sash)  # bandoleira
    for side in (-1.0, 1.0):
        p.dome(TAN, (side * 0.38, 0.02, 1.19), 0.18, 0.18, 0.12, 8, 6)
    if rarity:
        p.cylinder(RARITY_TRIM[rarity], (0.0, 0.03), 0.425, 0.41, 1.24, 1.30, 10, caps=False)  # gola
    if rarity == 2:
        p.gem(EPIC, (0.0, -0.49, 0.83), 0.07)  # fivela
    return [p]


def hunter_boots(name, rarity):
    pieces = []
    for side, suffix in ((1.0, "l"), (-1.0, "r")):
        x = side * 0.17
        shaft = Piece(obj_name(name, "lowerleg." + suffix), "lowerleg." + suffix)
        shaft.cylinder(LEATHER, (x, -0.01), 0.150, 0.158, 0.10, 0.34, 8)
        shaft.cylinder(TAN, (x, -0.01), 0.185, 0.19, 0.32, 0.41, 8, caps=False)  # dobra
        if rarity:
            shaft.cylinder(RARITY_TRIM[rarity], (x, -0.01), 0.165, 0.165, 0.18, 0.23, 8, caps=False)
        if rarity == 2:
            shaft.gem(EPIC, (x, -0.18, 0.205), 0.05)
        shoe = Piece(obj_name(name, "foot." + suffix), "foot." + suffix)
        shoe.box(LEATHER_DARK, (x, -0.09, 0.07), (0.26, 0.45, 0.14))
        pieces += [shaft, shoe]
    return pieces


# Peitoral do Engenheiro (F59): a mochila ocupa y 0.22-0.64 e z 0.35-1.26 nas costas; o anel inteiro
# (raio 0.45, ate y 0.48) a atravessaria. Variante so da frente e dos lados: sem as faces do tras do
# tronco (y acima de BACK_CUT_Y e |x| < BACK_CUT_X; as ombreiras ficam fora do corte).
BACK_CUT_Y = 0.12
BACK_CUT_X = 0.33


def cut_back(pieces):
    for p in pieces:
        faces = [f for f in p.bm.faces
                 if f.calc_center_median().y > BACK_CUT_Y and abs(f.calc_center_median().x) < BACK_CUT_X]
        bmesh.ops.delete(p.bm, geom=faces, context="FACES")
    return pieces


# Berserker (F75): o Barbarian_Large tem o rig com os mesmos ossos e a mesma orientacao do rig medio,
# mas outras proporcoes. Peitoral e botas sao as mesmas pecas, levadas ao corpo Large osso a osso: a
# caixa dos vertices de cada osso (pelo grupo de maior peso, em pose de repouso) no Knight vira a
# caixa do mesmo osso no Berserker (centro e escala por eixo). Elmo nao: o Berserker tem o de chifres.
LARGE_FIT = {
    "chest": ("spine", "chest"),
    "lowerleg.l": ("lowerleg.l",),
    "lowerleg.r": ("lowerleg.r",),
    "foot.l": ("foot.l", "toes.l"),
    "foot.r": ("foot.r", "toes.r"),
}
# Folga para fora na escala (a peca e uma casca sobre o corpo; sem ela o corpo maior a atravessa).
LARGE_FIT_MARGIN = 1.06
# Ajuste por osso depois da caixa (escala por eixo, deslocamento em u): o Barbarian_Large anda curvado
# e a cabeca afunda entre os ombros; o peitoral inteiro cobria o rosto na camera do jogo (PI
# 2026-10-18). Mais baixo e mais curto, ele fica no tronco.
LARGE_FIT_TWEAK = {"chest": (Vector((0.92, 1.0, 0.72)), Vector((0.0, 0.0, -0.32)))}


def bone_boxes(path):
    """Caixa (min, max) dos vertices de cada osso de LARGE_FIT no modelo de `path`, em repouso."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    imported = [o for o in bpy.data.objects if o not in before]
    for o in imported:
        if o.type == "ARMATURE":
            o.data.pose_position = "REST"
    bpy.context.view_layer.update()
    points = {bone: [] for bone in LARGE_FIT}
    for o in imported:
        # So corpo e pernas: ombreira, pele e capa tambem pesam no chest e inchariam a caixa.
        if o.type != "MESH" or not o.vertex_groups or not ("_Body" in o.name or "_Leg" in o.name):
            continue
        names = {g.index: g.name for g in o.vertex_groups}
        for v in o.data.vertices:
            if not v.groups:
                continue
            owner = names[max(v.groups, key=lambda g: g.weight).group]
            for bone, sources in LARGE_FIT.items():
                if owner in sources:
                    points[bone].append(o.matrix_world @ v.co)
    for o in imported:
        bpy.data.objects.remove(o, do_unlink=True)
    boxes = {}
    for bone, pts in points.items():
        lo = Vector([min(p[i] for p in pts) for i in range(3)])
        hi = Vector([max(p[i] for p in pts) for i in range(3)])
        boxes[bone] = (lo, hi)
    return boxes


def large_fit():
    """osso -> (centro no Knight, centro no Berserker, escala por eixo)."""
    medium, large = bone_boxes(KNIGHT), bone_boxes(BERSERKER)
    fit = {}
    for bone in LARGE_FIT:
        (mlo, mhi), (llo, lhi) = medium[bone], large[bone]
        scale = Vector([LARGE_FIT_MARGIN * (lhi[i] - llo[i]) / (mhi[i] - mlo[i]) for i in range(3)])
        shift = Vector()
        if bone in LARGE_FIT_TWEAK:
            factor, shift = LARGE_FIT_TWEAK[bone]
            scale = Vector([scale[i] * factor[i] for i in range(3)])
        fit[bone] = ((mlo + mhi) / 2.0, (llo + lhi) / 2.0 + shift, scale)
    return fit


def to_large(pieces, fit):
    for p in pieces:
        center_m, center_l, scale = fit[p.bone]
        for v in p.bm.verts:
            d = v.co - center_m
            v.co = center_l + Vector((d.x * scale.x, d.y * scale.y, d.z * scale.z))
    return pieces


ARMOR = {
    "guard_helm": guard_helm,
    "guard_chest": guard_chest,
    "guard_boots": guard_boots,
    "hunter_helm": hunter_helm,
    "hunter_chest": hunter_chest,
    "hunter_boots": hunter_boots,
}

# ---------------------------------------------------------------------------------------------
# Armas: peca do pack no espaco do modelo (pose de repouso) + acabamento por raridade


def pack_weapon(path, mesh_name, limit=WEAPON_BASE_MAX):
    """Malha da arma do pack com a transformacao de repouso aplicada (espaco do modelo)."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    imported = [o for o in bpy.data.objects if o not in before]
    for o in imported:
        if o.type == "ARMATURE":
            o.data.pose_position = "REST"
    bpy.context.view_layer.update()
    src = next(o for o in imported if o.name.startswith(mesh_name))
    world = src.matrix_world.copy()
    mesh = src.data.copy()
    for o in imported:
        bpy.data.objects.remove(o, do_unlink=True)
    return decimated(mesh, limit), world


def decimated(mesh, limit):
    """Mesma malha, reduzida por colapso ate `limit` triangulos (so se passar do limite)."""
    mesh.calc_loop_triangles()
    count = len(mesh.loop_triangles)
    if count <= limit:
        return mesh
    holder = bpy.data.objects.new("decimate_holder", mesh)
    bpy.context.scene.collection.objects.link(holder)
    mod = holder.modifiers.new("decimate", "DECIMATE")
    mod.ratio = limit / count
    reduced = bpy.data.meshes.new_from_object(holder.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    bpy.data.objects.remove(holder, do_unlink=True)
    for poly in reduced.polygons:
        poly.use_smooth = False
    return reduced


def weapon_piece(name, bone, mesh, world, rarity, accents, atlas, epic):
    """accents(piece, rarity) desenha os enfeites no espaco local da arma."""
    p = Piece(name, bone)
    accents(p, rarity)
    extra = list(mesh.materials)
    deco = p.build(atlas, epic, extra_materials=extra)
    base = bpy.data.objects.new(name + "_base", mesh.copy())
    bpy.context.scene.collection.objects.link(base)
    bpy.context.scene.collection.objects.link(deco)
    bpy.ops.object.select_all(action="DESELECT")
    deco.select_set(True)
    base.select_set(True)
    bpy.context.view_layer.objects.active = base
    if deco.data.polygons:
        bpy.ops.object.join()
    else:
        bpy.data.objects.remove(deco, do_unlink=True)
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    # Espaco do modelo: aplica a pose de repouso na malha (mesh.transform sozinho deixa a malha
    # avaliada antiga e o exportador leria as coordenadas locais da arma).
    obj.matrix_world = world
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for coll in obj.users_collection:
        coll.objects.unlink(obj)
    return obj


def sword_accents(p, rarity):
    # Espaco local da 1H_Sword: lamina em +Z (0.30-1.41, +-0.157, espessura +-0.048), guarda em
    # z 0.08-0.30 (+-0.25, +-0.065), pomo em z -0.37 a -0.19.
    if rarity == 1:
        p.box(BLUE, (0.0, 0.0, 0.80), (0.04, 0.105, 0.85))  # fio azul na lamina
        p.gem(BLUE, (0.0, 0.0, 0.19), (0.075, 0.09, 0.09))
    elif rarity == 2:
        p.box(GOLD, (0.0, 0.0, 0.19), (0.56, 0.15, 0.24))  # guarda dourada
        p.box(GOLD, (0.0, 0.0, -0.28), (0.25, 0.11, 0.20))  # pomo dourado
        p.gem(EPIC, (0.0, 0.0, 0.19), (0.08, 0.11, 0.10))


def bow_accents(p, rarity):
    # Espaco local do bow_withString: bracos em +-Y (pontas em +-0.99, x~-0.35), empunhadura na
    # origem; o pack ja traz a empunhadura azul, entao o raro marca as pontas.
    if rarity == 0:
        return
    tip_cell = BLUE if rarity == 1 else GOLD
    for tip in (-1.0, 1.0):
        m = Matrix.Translation((-0.35, tip * 0.92, 0.0)) @ Matrix.Rotation(math.radians(-90.0 * tip), 4, "X")
        r = bmesh.ops.create_cone(p.bm, cap_ends=True, segments=6, radius1=0.05, radius2=0.0, depth=0.16, matrix=m)
        p.add(r["verts"], tip_cell)
    if rarity == 2:
        p.box(GOLD, (0.0, 0.0, 0.0), (0.10, 0.24, 0.115))  # empunhadura dourada
    p.gem(BLUE if rarity == 1 else EPIC, (0.06, 0.0, 0.0), (0.045, 0.055, 0.055))


def axe_accents(p, rarity):
    # Espaco local do 2H_Axe (F53): cabo em +Z (-0.40 a 0.45, +-0.08), cabeca de lamina dupla em
    # z 0.45-1.32 (+-0.62 em X no fio, espessura +-0.13 em Y no olho, fio fino).
    if rarity == 0:
        return
    trim = BLUE if rarity == 1 else GOLD
    p.cylinder(trim, (0.0, 0.0), 0.095, 0.095, 0.16, 0.26, 8, caps=False)  # anel da empunhadura
    if rarity == 1:
        p.gem(BLUE, (0.0, 0.0, 0.90), (0.09, 0.15, 0.09))  # pedra no olho da cabeca
        return
    for side in (-1.0, 1.0):
        p.box(GOLD, (side * 0.60, 0.0, 0.88), (0.06, 0.05, 0.56))  # fio dourado das laminas
    p.cylinder(GOLD, (0.0, 0.0), 0.10, 0.10, -0.44, -0.30, 8)  # pomo dourado
    p.gem(EPIC, (0.0, 0.0, 0.90), (0.10, 0.17, 0.10))


def staff_accents(p, rarity):
    # Espaco local do 2H_Staff (F54): haste em +Z (-0.80 a 0.60, raio 0.05-0.09), gola em z ~0.60
    # (raio 0.11), orbe verde com gancho em z 0.70-1.30 (x -0.25 a 0.33, y +-0.15).
    if rarity == 0:
        return
    trim = BLUE if rarity == 1 else GOLD
    p.cylinder(trim, (0.0, 0.0), 0.075, 0.075, 0.30, 0.40, 8, caps=False)  # anel da empunhadura
    p.cylinder(trim, (0.0, 0.0), 0.10, 0.10, -0.62, -0.52, 8, caps=False)  # anel do pe
    if rarity == 1:
        p.gem(BLUE, (0.0, -0.11, 0.60), (0.05, 0.04, 0.06))  # pedra na gola
        return
    p.cylinder(GOLD, (0.0, 0.0), 0.13, 0.11, 0.52, 0.66, 8)  # gola dourada
    m = Matrix.Translation((0.04, 0.0, 1.36))
    r = bmesh.ops.create_cone(p.bm, cap_ends=True, segments=6, radius1=0.07, radius2=0.0, depth=0.22, matrix=m)
    p.add(r["verts"], GOLD)  # ponta dourada sobre o orbe
    p.gem(EPIC, (0.0, -0.14, 0.59), (0.06, 0.05, 0.07))


def crossbow_accents(p, rarity):
    # Espaco local do crossbow_1handed (F58): arco em -Y (bracos +-0.45 em X, y ~-0.62, z 0.02-0.19),
    # ponta em y -0.94, coronha ate +0.28 com a empunhadura descendo em -Z (y 0 a 0.2).
    if rarity == 0:
        return
    tip_cell = BLUE if rarity == 1 else GOLD
    for side in (-1.0, 1.0):
        m = Matrix.Translation((side * 0.47, -0.62, 0.06)) @ Matrix.Rotation(math.radians(-90.0 * side), 4, "Y")
        r = bmesh.ops.create_cone(p.bm, cap_ends=True, segments=6, radius1=0.05, radius2=0.0, depth=0.12, matrix=m)
        p.add(r["verts"], tip_cell)
    if rarity == 1:
        p.gem(BLUE, (0.0, -0.30, 0.17), (0.05, 0.06, 0.04))  # pedra sobre a coronha
        return
    p.box(GOLD, (0.0, -0.35, 0.09), (0.30, 0.10, 0.22))  # cinta dourada na coronha
    p.box(GOLD, (0.0, -0.92, 0.06), (0.20, 0.06, 0.12))  # ponteira dourada
    p.gem(EPIC, (0.0, -0.35, 0.22), (0.06, 0.07, 0.05))


def shotgun_accents(p, rarity):
    # Espaco local do shotgun (F59): cano em -Y (muzzle em y -1.15), coronha em +Y (ate 0.52, z -0.27
    # a 0.08), bloco dos dois canos em y -1.15 a -0.60 (x +-0.23, z -0.10 a 0.26), forend em y -0.35
    # (x +-0.23, topo z 0.31). Cima = +Z.
    if rarity == 0:
        return
    trim = BLUE if rarity == 1 else GOLD
    for y in ((-0.80,) if rarity == 1 else (-0.80, -0.68)):
        p.box(trim, (0.0, y, 0.08), (0.50, 0.07, 0.40))  # anel nos canos
    if rarity == 1:
        p.gem(BLUE, (0.0, -0.35, 0.33), (0.07, 0.08, 0.05))  # pedra sobre o forend
        return
    p.box(GOLD, (0.0, 0.50, -0.10), (0.17, 0.07, 0.40))  # chapa dourada da coronha
    p.box(GOLD, (0.0, -1.10, 0.17), (0.50, 0.06, 0.34))  # boca dourada
    p.gem(EPIC, (0.0, -0.35, 0.34), (0.08, 0.09, 0.06))


# Ocultista (F77): o `staff` do Extra tem o mesmo desenho do 2H_Staff (haste -0.90 a 0.55, gola em z ~0.60,
# orbe com gancho em z 0.70-1.30, x -0.25 a 0.33); os enfeites sao os do cajado do Bruxo. A cor da base vem
# do atlas escuro do Ocultista (material do occultist.glb), entao as tres raridades ficam pretas e roxas.
occultist_accents = staff_accents


def druid_staff_accents(p, rarity):
    # Espaco local do druid_staff (F74): haste em +Z (-0.89 a 0.80; raio 0.04-0.09), no do punho z ~0.2, forquilha
    # de galhos em z 0.8-1.36 (x -0.57 a 0.30, y +-0.33), ponta do pe fina em z -0.89.
    if rarity == 0:
        return
    trim = BLUE if rarity == 1 else GOLD
    p.cylinder(trim, (0.0, 0.0), 0.085, 0.085, -0.56, -0.46, 8, caps=False)  # anel do pe
    p.cylinder(trim, (0.0, 0.0), 0.10, 0.10, 0.46, 0.55, 8, caps=False)  # anel acima do punho
    if rarity == 1:
        p.gem(BLUE, (0.0, -0.10, 0.50), (0.05, 0.04, 0.06))  # pedra no anel
        return
    p.cylinder(GOLD, (0.0, 0.0), 0.11, 0.09, 0.40, 0.46, 8)  # colar dourado
    for tip in ((-0.52, 0.0, 1.30), (-0.30, 0.28, 1.30), (-0.30, -0.28, 1.30)):
        r = bmesh.ops.create_cone(p.bm, cap_ends=True, segments=6, radius1=0.06, radius2=0.0, depth=0.20,
                                  matrix=Matrix.Translation(tip))
        p.add(r["verts"], GOLD)  # pontas douradas nos galhos
    p.gem(EPIC, (-0.12, 0.0, 0.84), (0.08, 0.08, 0.10))  # pedra roxa no cruzamento dos galhos


def axe1h_accents(p, rarity):
    # Espaco local do axe_1handed_Large (F75): cabo em +Z (-0.55 a ~1.0, raio ~0.10), cabeca de uma
    # lamina em z 0.95-1.94 para -X (fio em x ~-1.15), espessura +-0.185 em Y no olho.
    if rarity == 0:
        return
    trim = BLUE if rarity == 1 else GOLD
    p.cylinder(trim, (0.0, 0.0), 0.13, 0.13, 0.10, 0.26, 8, caps=False)  # anel da empunhadura
    if rarity == 1:
        p.gem(BLUE, (-0.40, 0.0, 1.45), (0.12, 0.20, 0.12))  # pedra no olho da cabeca
        return
    p.box(GOLD, (-1.12, 0.0, 1.45), (0.09, 0.07, 0.86))  # fio dourado da lamina
    p.cylinder(GOLD, (0.0, 0.0), 0.15, 0.13, -0.58, -0.40, 8)  # pomo dourado
    p.gem(EPIC, (-0.40, 0.0, 1.45), (0.13, 0.21, 0.13))


WEAPON_ITEMS = ["sword_t1", "sword_t2", "sword_t3_epic"]  # indice = raridade
# Berserker (F75): o par de machados vale um item de arma; o glb tem um machado em cada mao.
BERSERKER_WEAPONS = ["axe_t1", "axe_t2", "axe_t3_epic"]
# F74/F77: o Druida e o Ocultista usam cajado, nao espada.
HERO_WEAPON_ITEMS = {
    "druid": ["staff_t1", "staff_t2", "staff_t3_epic"],
    "occultist": ["staff_t1", "staff_t2", "staff_t3_epic"],
}
# heroi: (glb, malha do pack, osso, enfeites, eixo local da arma, eixo local de vista do icone)
WEAPONS = {
    "knight": (KNIGHT, "1H_Sword", "handslot.r", sword_accents, (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)),
    "ranger": (RANGER, "bow_withString", "handslot.l", bow_accents, (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)),
    "barbarian": (BARBARIAN, "2H_Axe", "handslot.r", axe_accents, (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)),
    "fire_wizard": (MAGE, "2H_Staff", "handslot.r", staff_accents, (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)),
    "rogue": (ROGUE, "crossbow_1handed", "handslot.r", crossbow_accents, (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)),
    "engineer": (ENGINEER, "shotgun", "handslot.r", shotgun_accents, (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)),
    "druid": (DRUID, "druid_staff", "handslot.r", druid_staff_accents, (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)),
    "occultist": (OCCULTIST, "staff", "handslot.r", occultist_accents, (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)),
}

# ---------------------------------------------------------------------------------------------
# Export, contagem e icones


def tris(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def export(collection, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in collection.objects:
        o.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_animations=False,
        export_apply=True,
    )


def look_at(cam, target, forward, up):
    f = forward.normalized()
    r = f.cross(up).normalized()
    u = r.cross(f)
    cam.matrix_world = Matrix((
        (r.x, u.x, -f.x, 0.0), (r.y, u.y, -f.y, 0.0), (r.z, u.z, -f.z, 0.0), (0.0, 0.0, 0.0, 1.0),
    ))
    cam.location = target - f * 10.0


def setup_render():
    scene = bpy.context.scene
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in engines else "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = ICON_SIZE
    scene.render.resolution_y = ICON_SIZE
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("icon_world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.55, 0.6, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    scene.world = world
    sun = bpy.data.objects.new("icon_sun", bpy.data.lights.new("icon_sun", "SUN"))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50.0), 0.0, math.radians(-35.0))
    scene.collection.objects.link(sun)
    cam = bpy.data.objects.new("icon_cam", bpy.data.cameras.new("icon_cam"))
    cam.data.type = "ORTHO"
    scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def frame(a, b):
    """Base ortonormal com a e b (b ortogonalizado contra a) como colunas."""
    a = a.normalized()
    b = (b - a * b.dot(a)).normalized()
    return Matrix((a, b, a.cross(b))).transposed()


def render_icon(cam, collection, path, weapon_axes=None):
    view_layer = bpy.context.view_layer
    for child in view_layer.layer_collection.children:
        child.exclude = child.collection != collection
    if weapon_axes is not None:
        # Arma de chapa na diagonal da tela: eixo da arma -> (1, 0, 1), eixo de vista -> -Y (camera).
        axis, view = weapon_axes
        turn = frame(Vector((1.0, 0.0, 1.0)), Vector((0.0, -1.0, 0.0))) @ frame(axis, view).transposed()
        for o in collection.objects:
            o.matrix_world = turn.to_4x4()
    bpy.context.view_layer.update()
    corners = [o.matrix_world @ Vector(c) for o in collection.objects for c in o.bound_box]
    center = sum(corners, Vector()) / len(corners)
    if weapon_axes is None:
        forward = -Vector((0.55, -1.0, 0.45))  # 3/4 de frente, de cima
    else:
        forward = Vector((0.0, 1.0, 0.0))
    look_at(cam, center, forward, Vector((0.0, 0.0, 1.0)))
    bpy.context.view_layer.update()
    inv = cam.matrix_world.inverted()
    local = [inv @ c for c in corners]
    extent = max(max(p.x for p in local) - min(p.x for p in local), max(p.y for p in local) - min(p.y for p in local))
    cam.data.ortho_scale = extent * 1.12
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for o in collection.objects:
        o.matrix_world = Matrix.Identity(4)


# ---------------------------------------------------------------------------------------------


def main():
    reset()
    atlas, epic = make_materials()
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(ICONS, exist_ok=True)
    report = []
    pieces = []  # (collection, glb, icon, eixos da arma no modelo ou None)

    for group, build in ARMOR.items():
        for rarity in range(3):
            name = "%s_t%d" % (group, rarity + 1)
            coll = bpy.data.collections.new(name)
            bpy.context.scene.collection.children.link(coll)
            for piece in build(name, rarity):
                coll.objects.link(piece.build(atlas, epic))
            pieces.append((coll, name, name, None))

    # Peitorais sem costas para o Engenheiro: mesmo id de item, peca propria (so cena; sem icone novo).
    for group in ("guard_chest", "hunter_chest"):
        for rarity in range(3):
            name = "engineer_%s_t%d" % (group, rarity + 1)
            coll = bpy.data.collections.new(name)
            bpy.context.scene.collection.children.link(coll)
            for piece in cut_back(ARMOR[group](name, rarity)):
                coll.objects.link(piece.build(atlas, epic))
            pieces.append((coll, name, None, None))

    # Peitoral e botas no corpo Large do Berserker (F75): mesmo id de item, peca propria (sem icone novo).
    fit = large_fit()
    for group in ("guard_chest", "guard_boots", "hunter_chest", "hunter_boots"):
        for rarity in range(3):
            name = "berserker_%s_t%d" % (group, rarity + 1)
            coll = bpy.data.collections.new(name)
            bpy.context.scene.collection.children.link(coll)
            for piece in to_large(ARMOR[group](name, rarity), fit):
                coll.objects.link(piece.build(atlas, epic))
            pieces.append((coll, name, None, None))

    for hero, (path, mesh_name, bone, accents, axis_local, view_local) in WEAPONS.items():
        mesh, world = pack_weapon(path, mesh_name, BASE_MAX_BY_HERO.get(hero, WEAPON_BASE_MAX))
        axis = (world.to_3x3() @ Vector(axis_local), world.to_3x3() @ Vector(view_local))
        for rarity, item in enumerate(HERO_WEAPON_ITEMS.get(hero, WEAPON_ITEMS)):
            name = "%s_%s" % (hero, item)
            coll = bpy.data.collections.new(name)
            bpy.context.scene.collection.children.link(coll)
            obj = weapon_piece(obj_name(name, bone), bone, mesh, world, rarity, accents, atlas, epic)
            coll.objects.link(obj)
            pieces.append((coll, name, name, axis))

    # Berserker (F75): um machado em cada mao no mesmo glb; o teto de triangulos vale por mao e o icone
    # e so o da direita (colecao propria, renderizada como a das outras armas).
    hands = {}
    icon_only = []
    mesh_r, world_r = pack_weapon(BERSERKER, "Axe_R")
    mesh_l, world_l = pack_weapon(BERSERKER, "Axe_L")
    axis = (world_r.to_3x3() @ Vector((0.0, 0.0, 1.0)), world_r.to_3x3() @ Vector((0.0, 1.0, 0.0)))
    for rarity, item in enumerate(BERSERKER_WEAPONS):
        name = "berserker_" + item
        coll = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(coll)
        right = weapon_piece(obj_name(name, "handslot.r"), "handslot.r", mesh_r, world_r, rarity, axe1h_accents, atlas, epic)
        left = weapon_piece(obj_name(name, "handslot.l"), "handslot.l", mesh_l, world_l, rarity, axe1h_accents, atlas, epic)
        coll.objects.link(right)
        coll.objects.link(left)
        hands[name] = 2
        icon_coll = bpy.data.collections.new(name + "_icon")
        bpy.context.scene.collection.children.link(icon_coll)
        icon_coll.objects.link(right)
        icon_only.append((icon_coll, name, axis))
        pieces.append((coll, name, None, axis))

    for coll, glb, _icon, _axis in pieces:
        count = sum(tris(o) for o in coll.objects)
        report.append((glb, count))
        per_hand = count / hands.get(glb, 1)
        if not TRIS_MIN <= per_hand <= TRIS_MAX:
            raise SystemExit("%s: %d triangulos fora de %d-%d" % (glb, count, TRIS_MIN, TRIS_MAX))
        export(coll, os.path.join(OUT, glb + ".glb"))

    bpy.ops.wm.save_as_mainfile(filepath=BLEND)

    cam = setup_render()
    for coll, _glb, icon, axis in pieces:
        if icon is not None:
            render_icon(cam, coll, os.path.join(ICONS, icon + ".png"), weapon_axes=axis)
    for coll, icon, axis in icon_only:
        render_icon(cam, coll, os.path.join(ICONS, icon + ".png"), weapon_axes=axis)

    for name, count in report:
        print("PIECE %-28s %4d tris" % (name, count))

    if PREVIEW:  # so as pecas do Berserker, em 512 px, para conferir o acabamento
        bpy.context.scene.render.resolution_x = 512
        bpy.context.scene.render.resolution_y = 512
        for coll, glb, _icon, axis in pieces:
            if glb.startswith("berserker"):
                render_icon(cam, coll, os.path.join(PREVIEW, glb + ".png"), weapon_axes=axis)


main()
