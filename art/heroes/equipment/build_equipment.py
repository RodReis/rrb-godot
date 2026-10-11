"""Monta art/heroes/equipment/equipment.blend, exporta as pecas em shared/assets/rrb/equipment/ e
renderiza os icones em shared/ui/icons/items/ (SPEC-048, ADR-0005, ADR-0010).

Pecas rigidas: cada objeto e modelado no espaco do modelo do heroi em pose de repouso (Z para
cima, frente -Y; o rig do Knight e do Ranger e o mesmo) e se chama "<peca>__<osso>" com "." do
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
BLEND = os.path.join(REPO, "art", "heroes", "equipment", "equipment.blend")
OUT = os.path.join(REPO, "shared", "assets", "rrb", "equipment")
ICONS = os.path.join(REPO, "shared", "ui", "icons", "items")

TRIS_MIN, TRIS_MAX = 50, 800
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


def pack_weapon(path, mesh_name):
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
    return mesh, world


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


WEAPON_ITEMS = ["sword_t1", "sword_t2", "sword_t3_epic"]  # indice = raridade
# heroi: (glb, malha do pack, osso, enfeites, eixo local da arma, eixo local de vista do icone)
WEAPONS = {
    "knight": (KNIGHT, "1H_Sword", "handslot.r", sword_accents, (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)),
    "ranger": (RANGER, "bow_withString", "handslot.l", bow_accents, (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)),
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

    for hero, (path, mesh_name, bone, accents, axis_local, view_local) in WEAPONS.items():
        mesh, world = pack_weapon(path, mesh_name)
        axis = (world.to_3x3() @ Vector(axis_local), world.to_3x3() @ Vector(view_local))
        for rarity, item in enumerate(WEAPON_ITEMS):
            name = "%s_%s" % (hero, item)
            coll = bpy.data.collections.new(name)
            bpy.context.scene.collection.children.link(coll)
            obj = weapon_piece(obj_name(name, bone), bone, mesh, world, rarity, accents, atlas, epic)
            coll.objects.link(obj)
            pieces.append((coll, name, name, axis))

    for coll, glb, _icon, _axis in pieces:
        count = sum(tris(o) for o in coll.objects)
        report.append((glb, count))
        if not TRIS_MIN <= count <= TRIS_MAX:
            raise SystemExit("%s: %d triangulos fora de %d-%d" % (glb, count, TRIS_MIN, TRIS_MAX))
        export(coll, os.path.join(OUT, glb + ".glb"))

    bpy.ops.wm.save_as_mainfile(filepath=BLEND)

    cam = setup_render()
    for coll, _glb, icon, axis in pieces:
        render_icon(cam, coll, os.path.join(ICONS, icon + ".png"), weapon_axes=axis)

    for name, count in report:
        print("PIECE %-28s %4d tris" % (name, count))


main()
