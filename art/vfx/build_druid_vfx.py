"""Monta art/vfx/druid_vfx.blend e exporta as malhas de VFX do Druida em shared/assets/rrb/vfx/
(ADR-0005, SPEC-074). Eixo da peca = +Z do Blender = +Y do Godot.
  potion_green.glb  pocao verde do pack (potion_large_green), origem no centro da garrafa, ~0,35 u de altura
  root_tendril.glb  raiz/espinho curvo e afilado, base na origem, ponta em +Y do Godot, ~1,2 u
  leaf.glb          folha pequena dobrada na nervura (2 lados), origem no peciolo, ponta em +Y do Godot
Cor pelo atlas KayKit hexagons_medieval (embutido) ou pela textura do proprio pack (druid_texture).
Uso:
  blender --background --factory-startup --python build_druid_vfx.py -- <extra_dir> <repo> [preview_dir]
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
PACK, REPO = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""
ASSETS = PACK + r"\Assets\gltf"
ATLAS = os.path.join(REPO, "shared", "assets", "kaykit", "medieval_hexagon", "hexagons_medieval.png")
BLEND = os.path.join(REPO, "art", "vfx", "druid_vfx.blend")
OUT = os.path.join(REPO, "shared", "assets", "rrb", "vfx")

# Orcamento de triangulos (prop 50-800 do CLAUDE.md; raiz e folha pedem menos: sao instanciadas em massa).
BUDGET = {"potion_green": (50, 250), "root_tendril": (40, 150), "leaf": (8, 20)}
# Celulas do atlas 8x4 (coluna, linha a partir do topo), as mesmas do build_equipment.py.
WOOD = (2, 1)
LEAF_GREEN = (4, 1)
POTION_HEIGHT = 0.35
# Raiz: comprimento, raio da base, curvatura lateral no topo, lados da secao e segmentos.
ROOT_LENGTH = 1.2
ROOT_RADIUS = 0.09
ROOT_BEND = 0.28
ROOT_SIDES = 5
ROOT_SEGMENTS = 7
ROOT_GREEN_FROM = 0.55  # a partir desta fracao do comprimento a raiz fica verde
# Folha: comprimento e meia-largura; altura da dobra na nervura.
LEAF_LENGTH = 0.24
LEAF_HALF_WIDTH = 0.075
LEAF_FOLD = 0.022


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj


def atlas_material(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 1.0
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ATLAS)
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    mat.use_backface_culling = False  # raiz e folha sao vistas por dentro (casca fina, particulas)
    return mat


def paint(faces, uv, cell, lo, hi, axis=2):
    """UV na celula do atlas: degrade vertical pela altura do vertice no eixo `axis`."""
    col, row = cell
    span = max(hi - lo, 1e-6)
    for f in faces:
        for loop in f.loops:
            t = min(max((loop.vert.co[axis] - lo) / span, 0.0), 1.0)
            loop[uv].uv = ((col + 0.5) / 8.0, 1.0 - (row + 0.15 + 0.7 * (1.0 - t)) / 4.0)


def mesh_object(name, bm, material):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(material)
    for poly in mesh.polygons:
        poly.use_smooth = False
    return link(bpy.data.objects.new(name, mesh))


def tris(obj):
    deps = bpy.context.evaluated_depsgraph_get()
    mesh = obj.evaluated_get(deps).to_mesh()
    mesh.calc_loop_triangles()
    count = len(mesh.loop_triangles)
    obj.evaluated_get(deps).to_mesh_clear()
    return count


# ---------------------------------------------------------------------------------------------
# Pecas


def potion():
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=ASSETS + r"\potion_large_green.gltf")
    src = next(o for o in set(bpy.data.objects) - before if o.type == "MESH")
    mesh = src.data.copy()
    mat = mesh.materials[0]
    bpy.data.objects.remove(src, do_unlink=True)
    zs = [v.co.z for v in mesh.vertices]
    centre = Vector((0.0, 0.0, (min(zs) + max(zs)) / 2.0))
    scale = POTION_HEIGHT / (max(zs) - min(zs))
    # Origem no centro da garrafa (centro do volume da caixa), escala ja aplicada na malha.
    mesh.transform(Matrix.Diagonal((scale, scale, scale, 1.0)) @ Matrix.Translation(-centre))
    obj = link(bpy.data.objects.new("potion_green", mesh))
    mat.use_backface_culling = False
    for poly in mesh.polygons:
        poly.use_smooth = False
    return obj


def root_tendril(atlas):
    """Tubo de secao pentagonal que afina ate a ponta, curvado no plano XZ; base na origem, ponta em +Z."""
    bm = bmesh.new()
    rings = []
    for i in range(ROOT_SEGMENTS + 1):
        t = i / ROOT_SEGMENTS
        centre = Vector((ROOT_BEND * t * t, 0.0, ROOT_LENGTH * t))
        # Tangente da curva: sentido do tubo (a secao e perpendicular a ele).
        tangent = Vector((2.0 * ROOT_BEND * t, 0.0, ROOT_LENGTH)).normalized()
        side = Vector((0.0, 1.0, 0.0))
        other = tangent.cross(side)
        radius = ROOT_RADIUS * (1.0 - t) ** 0.8
        twist = 0.35 * i  # o giro leve da secao da a ideia de raiz torcida
        ring = []
        for k in range(ROOT_SIDES):
            a = math.tau * k / ROOT_SIDES + twist
            ring.append(bm.verts.new(centre + (side * math.cos(a) + other * math.sin(a)) * radius))
        rings.append(ring)
    tip = bm.verts.new(Vector((ROOT_BEND, 0.0, ROOT_LENGTH)))
    for lower, upper in zip(rings, rings[1:]):
        for k in range(ROOT_SIDES):
            a, b = lower[k], lower[(k + 1) % ROOT_SIDES]
            c, d = upper[(k + 1) % ROOT_SIDES], upper[k]
            bm.faces.new((a, b, c, d))
    for k in range(ROOT_SIDES):
        bm.faces.new((rings[-1][k], rings[-1][(k + 1) % ROOT_SIDES], tip))
    bm.faces.new(rings[0][::-1])  # tampa da base (a raiz sai do chao: raramente aparece)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    uv = bm.loops.layers.uv.new("UVMap")
    bm.faces.ensure_lookup_table()
    split = ROOT_LENGTH * ROOT_GREEN_FROM
    paint([f for f in bm.faces if f.calc_center_median().z < split], uv, WOOD, 0.0, split)
    paint([f for f in bm.faces if f.calc_center_median().z >= split], uv, LEAF_GREEN, split, ROOT_LENGTH)
    return mesh_object("root_tendril", bm, atlas)


def leaf(atlas):
    """Folha dobrada na nervura: dois lados, origem no peciolo, ponta em +Z."""
    bm = bmesh.new()
    n, w, f = LEAF_LENGTH, LEAF_HALF_WIDTH, LEAF_FOLD
    base = bm.verts.new((0.0, 0.0, 0.0))
    mid1 = bm.verts.new((0.0, f, 0.30 * n))
    mid2 = bm.verts.new((0.0, f * 0.7, 0.68 * n))
    tip = bm.verts.new((0.0, 0.0, n))
    left = (bm.verts.new((-w, 0.0, 0.34 * n)), bm.verts.new((-w * 0.55, 0.0, 0.72 * n)))
    right = (bm.verts.new((w, 0.0, 0.34 * n)), bm.verts.new((w * 0.55, 0.0, 0.72 * n)))
    for edge in (left, right):
        sign = 1 if edge is left else -1
        l1, l2 = edge
        order = [(base, l1, mid1), (mid1, l1, l2, mid2), (mid2, l2, tip)]
        for face in order:
            bm.faces.new(face if sign > 0 else face[::-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    uv = bm.loops.layers.uv.new("UVMap")
    bm.faces.ensure_lookup_table()
    paint(bm.faces, uv, LEAF_GREEN, 0.0, n)
    return mesh_object("leaf", bm, atlas)


# ---------------------------------------------------------------------------------------------


def export(obj, name):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUT, name + ".glb"),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_animations=False,
        export_apply=True,
    )


def main():
    reset()
    os.makedirs(OUT, exist_ok=True)
    atlas = atlas_material("vfx_atlas")
    objects = {"potion_green": potion(), "root_tendril": root_tendril(atlas), "leaf": leaf(atlas)}
    for name, obj in objects.items():
        count = tris(obj)
        low, high = BUDGET[name]
        if not low <= count <= high:
            raise SystemExit("%s: %d triangulos fora de %d-%d" % (name, count, low, high))
        zs = [v.co.z for v in obj.data.vertices]
        print("PIECE %-13s %4d tris  z [%.3f, %.3f]" % (name, count, min(zs), max(zs)))
        export(obj, name)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    if PREVIEW:
        preview(objects)


def preview(objects):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "TEXTURE"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.show_backface_culling = False
    scene.render.resolution_x = 360
    scene.render.resolution_y = 360
    scene.world = bpy.data.worlds.new("w")
    scene.world.color = (0.30, 0.34, 0.40)
    cam = link(bpy.data.objects.new("cam", bpy.data.cameras.new("cam")))
    cam.data.type = "ORTHO"
    scene.camera = cam
    for name, obj in objects.items():
        for o in objects.values():
            o.hide_render = o is not obj
        pts = [obj.matrix_world @ v.co for v in obj.data.vertices]
        centre = sum(pts, Vector()) / len(pts)
        radius = max((p - centre).length for p in pts)
        cam.data.ortho_scale = radius * 2.6
        for view, direction in (("front", (0, -1, 0.15)), ("iso", (1, -1, 0.9)), ("top", (0, -0.15, 1))):
            d = Vector(direction).normalized()
            cam.location = centre + d * 10
            cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = os.path.join(PREVIEW, "vfx_%s_%s.png" % (name, view))
            bpy.ops.render.render(write_still=True)


main()
