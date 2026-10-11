"""Construcoes do patio da base (F50, #131) montadas com pecas do Medieval Village MegaKit
(Quaternius, versao Standard gratuita, CC0 1.0) e exportadas em .glb (ADR-0005).

O pack nao e versionado (161 MB): baixe de
  https://store.godotengine.org/asset/quaternius/medieval-village-megakit/
(ou https://quaternius.com/packs/medievalvillagemegakit.html), extraia e passe a pasta glTF.
Pecas como vem (materiais e texturas do pack, ADR-0006: pack CC0 sem retoque); o script so
compoe, junta a malha por material (poucas draw calls), reduz as texturas a TEXTURE_SIZE e
exporta em JPEG. Sem colisao: ela continua no builder da arena (caixas em arena_layout.gd).

Coordenadas do Godot (x leste, y para cima, z sul), frente da casa em +x. Paredes do pack:
modulo de 2 u (x de -1 a 1), 3,12 u de altura, face externa em +z.
Uso (na raiz do repo):
  blender --background --factory-startup --python art/arena/build_megakit.py -- <repo> <pasta glTF>
Saida: art/arena/megakit_patio.blend (composicao; texturas apontam para o pack),
art/arena/preview_megakit.png e shared/assets/rrb/arena/megakit_*.glb.
"""
import math
import os
import re
import sys

import bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
REPO = argv[0]
PACK = argv[1]
ART = os.path.join(REPO, "art", "arena")
OUT = os.path.join(REPO, "shared", "assets", "rrb", "arena")
TEXTURE_SIZE = 1024
JPEG_QUALITY = 85
FLOOR = 3.12  # altura de um andar (parede do pack)

# Pecas (nome do .gltf do pack).
UB = "Wall_UnevenBrick_Straight"
UB_DOOR = "Wall_UnevenBrick_Door_Round"
UB_WIN = "Wall_UnevenBrick_Window_Wide_Round"
PL = "Wall_Plaster_Straight"
PL_GRID = "Wall_Plaster_WoodGrid"
PL_WIN = "Wall_Plaster_Window_Wide_Flat"
PL_DOOR = "Wall_Plaster_Door_Round"
WIN_ROUND = "Window_Wide_Round1"
WIN_FLAT = "Window_Wide_Flat1"
SHUTTERS = "WindowShutters_Wide_Round_Open"
DOOR = "Door_1_Round"
POST = "Corner_Exterior_Wood"
GABLE = "Roof_Front_Brick4"
CHIMNEY = "Prop_Chimney"
WAGON = "Prop_Wagon"
CRATE = "Prop_Crate"
BRICK = "Prop_Brick1"
FENCE = "Prop_WoodenFence_Single"

# Folha da porta: dobradica no x 0 da peca, vao centrado no modulo.
DOOR_OFFSET = -0.55
# Janela que preenche o vao de cada parede com janela.
WINDOW_FOR = {UB_WIN: WIN_ROUND, PL_WIN: WIN_FLAT}


def side_walls(half_x, half_z, pieces_x, pieces_z):
    """(peca, x, z, yaw) das quatro faces de uma caixa: frente +x, fundo -x, lados +z/-z.
    pieces_* listam as pecas da face na ordem de z (frente/fundo) ou x (lados) crescente."""
    out = []
    for i, piece in enumerate(pieces_x[0]):
        out.append((piece, half_x, -half_z + 1 + 2 * i, 90.0))
    for i, piece in enumerate(pieces_x[1]):
        out.append((piece, -half_x, -half_z + 1 + 2 * i, -90.0))
    for i, piece in enumerate(pieces_z[0]):
        out.append((piece, -half_x + 1 + 2 * i, half_z, 0.0))
    for i, piece in enumerate(pieces_z[1]):
        out.append((piece, -half_x + 1 + 2 * i, -half_z, 180.0))
    return out


def storey(placements, walls, y, posts, half_x, half_z, shutters=()):
    """Um andar: paredes, janelas nos vaos, porta na parede com porta, postes nos cantos."""
    for piece, x, z, yaw in walls:
        placements.append((piece, x, y, z, yaw))
        if piece in WINDOW_FOR:
            placements.append((WINDOW_FOR[piece], x, y, z, yaw))
            if (x, z) in shutters:
                placements.append((SHUTTERS, x, y, z, yaw))
        if piece in (UB_DOOR, PL_DOOR):
            dx, dz = local_offset(DOOR_OFFSET, 0.0, yaw)
            placements.append((DOOR, x + dx, y, z + dz, yaw))
    if posts:
        for sx in (-1, 1):
            for sz in (-1, 1):
                placements.append((POST, sx * half_x, y, sz * half_z, 0.0))


def local_offset(lx, lz, yaw):
    """Deslocamento local (x, z) girado por yaw graus em torno de +y (convencao do Godot)."""
    a = math.radians(yaw)
    return lx * math.cos(a) + lz * math.sin(a), -lx * math.sin(a) + lz * math.cos(a)


def house_long():
    """Casa de 2 andares, 4 x 6 u (fundo 4 em x, frente 6 em z): tijolo embaixo, enxaimel em
    cima, telhado de telha redonda 4x6, oitoes de tijolo e chamine."""
    p = []
    ground = side_walls(2, 3, [[UB_WIN, UB_DOOR, UB_WIN], [UB, UB, UB]], [[UB, UB_WIN], [UB_WIN, UB]])
    storey(p, ground, 0.0, True, 2, 3, shutters={(2, -2), (2, 2)})
    upper = side_walls(
        2, 3, [[PL_GRID, PL_WIN, PL_GRID], [PL, PL, PL]], [[PL_GRID, PL_WIN], [PL_WIN, PL_GRID]]
    )
    storey(p, upper, FLOOR, True, 2, 3)
    top = FLOOR * 2
    p.append(("Roof_RoundTiles_4x6", 0.0, top, 0.0, 0.0))
    p.append((GABLE, 0.0, top, 3.0, 0.0))
    p.append((GABLE, 0.0, top, -3.0, 180.0))
    p.append((CHIMNEY, -1.0, top + 1.7, 1.6, 0.0))
    return p


def house_small():
    """Casinha de 1 andar, 4 x 4 u, enxaimel com porta e janela na frente, telhado 4x4."""
    p = []
    walls = side_walls(2, 2, [[PL_DOOR, PL_WIN], [PL, PL]], [[PL_GRID, PL_WIN], [PL_WIN, PL_GRID]])
    storey(p, walls, 0.0, True, 2, 2)
    p.append(("Roof_RoundTiles_4x4", 0.0, FLOOR, 0.0, 0.0))
    p.append((GABLE, 0.0, FLOOR, 2.0, 0.0))
    p.append((GABLE, 0.0, FLOOR, -2.0, 180.0))
    return p


def yard_corner():
    """Canto do patio (origem no canto, eixos do mundo da base A: +x leste, -z norte): carroca,
    caixotes empilhados, cerca e tijolos soltos, dentro de 4,5 x 4,5 u."""
    return [
        (WAGON, 2.6, 0.0, -1.2, 135.0),
        (CRATE, 0.9, 0.0, -3.4, 10.0),
        (CRATE, 0.9, 1.06, -3.4, 35.0),
        (CRATE, 2.0, 0.0, -3.7, -15.0),
        (CRATE, 3.7, 0.0, -0.8, 5.0),
        (FENCE, 3.6, 0.0, -4.2, 0.0),
        (FENCE, 4.2, 0.0, -2.6, 90.0),
        (BRICK, 1.6, 0.1, -2.2, 20.0),
        (BRICK, 1.9, 0.1, -2.0, 70.0),
        (BRICK, 1.7, 0.3, -2.1, 45.0),
    ]


BUILDS = {
    "megakit_house_long": house_long,
    "megakit_house_small": house_small,
    "megakit_yard_corner": yard_corner,
}

_library = {}


def base_name(name):
    return re.sub(r"\.\d{3}$", "", name)


def load_piece(name):
    """Importa a peca uma vez e junta os objetos dela num so, com transformacao aplicada."""
    if name in _library:
        return _library[name]
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(PACK, name + ".gltf"))
    meshes = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    extras = [o for o in bpy.data.objects if o not in before and o.type != "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    for o in extras:
        bpy.data.objects.remove(o, do_unlink=True)
    obj.name = "lib_" + name
    obj.hide_render = True
    obj.hide_set(True)
    _library[name] = obj
    return obj


def dedupe_materials():
    """Cada import cria MI_X.001, MI_X.002...: remapeia para o primeiro de cada nome."""
    first = {}
    for mat in list(bpy.data.materials):
        key = base_name(mat.name)
        if key not in first:
            first[key] = mat
        elif mat is not first[key]:
            mat.user_remap(first[key])
            bpy.data.materials.remove(mat)
    images = {}
    for img in list(bpy.data.images):
        key = base_name(img.name)
        if key not in images:
            images[key] = img
        elif img is not images[key]:
            img.user_remap(images[key])
            bpy.data.images.remove(img)


def merge_slots(obj):
    """Depois do join, um material pode estar em varios slots: tudo no primeiro slot dele."""
    slot_of = {}
    remap = []
    for i, slot in enumerate(obj.material_slots):
        key = slot.material.name if slot.material else ""
        slot_of.setdefault(key, i)
        remap.append(slot_of[key])
    for poly in obj.data.polygons:
        poly.material_index = remap[poly.material_index]
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.material_slot_remove_unused()


def compose(name, placements):
    """Instancia as pecas (copia da malha), junta num objeto so e devolve o objeto."""
    for piece, *_ in placements:
        load_piece(piece)
    dedupe_materials()
    parts = []
    for i, (piece, x, y, z, yaw) in enumerate(placements):
        src = _library[piece]
        obj = bpy.data.objects.new("%s_%d" % (name, i), src.data.copy())
        bpy.context.scene.collection.objects.link(obj)
        # Godot (x, y, z) -> Blender (x, -z, y); yaw em torno de +y do Godot = +z do Blender.
        obj.matrix_world = Matrix.Translation((x, -z, y)) @ Matrix.Rotation(math.radians(yaw), 4, "Z")
        parts.append(obj)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    merge_slots(obj)
    return obj


def shrink_textures():
    for img in bpy.data.images:
        w, h = img.size
        if max(w, h) > TEXTURE_SIZE:
            img.scale(TEXTURE_SIZE, TEXTURE_SIZE * h // w)


def export(obj, name):
    bpy.ops.object.select_all(action="DESELECT")
    obj.hide_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUT, name + ".glb"),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_animations=False,
        export_image_format="JPEG",
        export_jpeg_quality=JPEG_QUALITY,
    )


def preview(objects):
    """Previa Workbench (cor da textura) lado a lado em art/arena/preview_megakit.png."""
    x = 0.0
    for obj in objects:
        obj.location.x = x
        x += 9.0
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.display.shading.show_shadows = True
    scene.render.resolution_x = 1400
    scene.render.resolution_y = 800
    scene.render.filepath = os.path.join(ART, "preview_megakit.png")
    bpy.context.view_layer.update()
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for obj in objects:
        for corner in obj.bound_box:
            p = obj.matrix_world @ Vector(corner)
            lo = Vector(min(a, b) for a, b in zip(lo, p))
            hi = Vector(max(a, b) for a, b in zip(hi, p))
    center = (lo + hi) / 2
    size = (hi - lo).length
    cam_data = bpy.data.cameras.new("PreviewCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = size * 1.15
    cam = bpy.data.objects.new("PreviewCam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = center + Vector((0.9, -1.0, 0.8)).normalized() * size * 2.0
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam_data.clip_end = size * 10.0
    scene.camera = cam
    bpy.ops.render.render(write_still=True)
    for obj in objects:
        obj.location.x = 0.0


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    built = []
    for name, recipe in BUILDS.items():
        obj = compose(name, recipe())
        built.append(obj)
        tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
        mats = [s.material.name for s in obj.material_slots]
        print("[megakit] %s: %d tris, materiais %s" % (name, tris, mats))
    shrink_textures()
    for obj in built:
        export(obj, obj.name)
    preview(built)
    # O import do glTF embute as texturas: a fonte guarda so a composicao (texturas no pack).
    for img in bpy.data.images:
        if img.packed_file:
            img.unpack(method="REMOVE")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ART, "megakit_patio.blend"))


main()
