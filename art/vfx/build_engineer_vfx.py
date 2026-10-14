"""Monta art/vfx/engineer_vfx.blend e exporta as malhas do Engenheiro em shared/assets/rrb/vfx/
(ADR-0005, SPEC-059 par. 3 e 6). Eixo de voo/mira = +Y do Blender = -Z do Godot (como o rogue_bolt).
  turret.glb         Torreta do pack (turret_base.gltf) reduzida ao orcamento de prop; hierarquia e nomes
                     do pack (turret_base > turret_footA/B/C, turret_gun); cano do pack em +Z do Godot
  claw_hook.glb      garra da engineer_Wrench (garras + chapa + colar), origem no ponto do cabo,
                     garras abertas em +Y do Blender
  muzzle_star.glb    clarao de boca: 2 planos cruzados em estrela, origem na boca, a chama sai em +Y
  shrapnel.glb       estilhaco metalico (bipiramide hexagonal), ponta em +Y
  debris_wood_a/b    destrocos de madeira da caixa
  dynamite_crate.glb caixa aberta do pack (ammo_crate sem tampa) + 3 bastoes vermelhos + pavio
Cor pelo atlas KayKit hexagons_medieval (embutido) ou pela textura do proprio pack (engineer_texture).
Uso:
  blender --background --factory-startup --python build_engineer_vfx.py -- <extra_dir> <repo> [preview_dir]
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
PACK, REPO = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""
ASSETS = PACK + r"\Assets\gltf"
ATLAS = os.path.join(REPO, "shared", "assets", "kaykit", "medieval_hexagon", "hexagons_medieval.png")
BLEND = os.path.join(REPO, "art", "vfx", "engineer_vfx.blend")
OUT = os.path.join(REPO, "shared", "assets", "rrb", "vfx")

# Orcamento de triangulos (SPEC-059 par. 4 e 6; prop 50-800 do CLAUDE.md).
BUDGET = {"turret": (50, 800), "claw_hook": (60, 150), "muzzle_star": (8, 40), "shrapnel": (10, 20),
          "debris_wood_a": (20, 60), "debris_wood_b": (20, 60), "dynamite_crate": (50, 300)}
# Celulas do atlas 8x4 (coluna, linha a partir do topo), as mesmas do build_equipment.py.
STEEL = (2, 0)
WOOD = (2, 1)
WOOD_LIGHT = (5, 1)
# Torreta: razao do Decimate por peca. A base (colar e dobradicas finos) nao aguenta o colapso, fica como
# vem (276); a cabeca e o rosto da torreta e leva o corte maior que ainda le bem; os pes cortam mais.
TURRET_RATIO = {"turret_footA": 0.38, "turret_footB": 0.38, "turret_footC": 0.38, "turret_gun": 0.32}
# Garra: faces da engineer_Wrench abaixo deste z (cabo, porca, alavanca) saem; o colar fica.
CLAW_CUT_Z = 0.28
CLAW_TRIS = 140
# Caixa de dinamite: tampa da ammo_crate (z acima disto) sai; bastoes e pavio entram.
CRATE_LID_Z = 0.21
STICK_RADIUS = 0.05
STICKS = ((-0.12, 0.50), (0.0, 0.56), (0.12, 0.52))  # (x, topo z)
FUSE_POINTS = ((0.0, 0.0, 0.56), (0.02, 0.0, 0.63), (0.06, 0.0, 0.69), (0.11, 0.0, 0.72))
FUSE_RADIUS = 0.012


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj


def import_pack(name):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=ASSETS + "\\" + name)
    return [o for o in bpy.data.objects if o not in before]


def flat_material(name, color, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = 0.7
    if emission:
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = emission
    mat.use_backface_culling = False
    mat.diffuse_color = color  # so a visualizacao do Blender; o glb leva o Principled
    return mat


def atlas_material():
    mat = bpy.data.materials.new("vfx_atlas")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 1.0
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ATLAS)
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def paint(bm, faces, cell, lo, hi, axis=2):
    """UV na celula do atlas: degrade vertical pela altura do vertice no eixo `axis`."""
    uv = bm.loops.layers.uv.active or bm.loops.layers.uv.new("UVMap")
    col, row = cell
    span = max(hi - lo, 1e-6)
    for f in faces:
        for loop in f.loops:
            t = (loop.vert.co[axis] - lo) / span
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


def apply_decimate(obj, ratio):
    # O glTF chega com um vertice por canto (faces planas): solda antes, senao o colapso rasga a malha.
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.to_mesh(obj.data)
    bm.free()
    mod = obj.modifiers.new("decimate", "DECIMATE")
    mod.ratio = ratio
    deps = bpy.context.evaluated_depsgraph_get()
    mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(deps))
    obj.modifiers.remove(mod)
    old = obj.data
    obj.data = mesh
    bpy.data.meshes.remove(old)
    for poly in mesh.polygons:
        poly.use_smooth = False


# ---------------------------------------------------------------------------------------------
# Pecas


def turret():
    objs = import_pack("turret_base.gltf")
    for o in objs:
        if o.name in TURRET_RATIO:
            apply_decimate(o, TURRET_RATIO[o.name])
    # No pack a origem e o quadril (as pontas dos pes ficam em y -0.36): sobe a raiz para os pes
    # tocarem y = 0 no Godot; a hierarquia e as transformacoes dos filhos ficam como vem.
    meshes = [o for o in objs if o.type == "MESH"]
    root = next(o for o in objs if o.parent is None)
    bpy.context.view_layer.update()
    root.location.z -= min((o.matrix_world @ v.co).z for o in meshes for v in o.data.vertices)
    return meshes


def claw():
    src = import_pack("engineer_Wrench.gltf")[0]
    bm = bmesh.new()
    bm.from_mesh(src.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_center_median().z < CLAW_CUT_Z], context="FACES")
    boundary = [e for e in bm.edges if e.is_boundary]
    filled = bmesh.ops.holes_fill(bm, edges=boundary, sides=0)["faces"]
    uv = bm.loops.layers.uv.active
    for f in filled:  # tampa do colar: cor de um vizinho
        neighbour = next(n for e in f.edges for n in e.link_faces if n is not f and n not in filled)
        for loop in f.loops:
            loop[uv].uv = neighbour.loops[0][uv].uv
    # Ponto do cabo (colar, z = CLAW_CUT_Z) na origem; garras (+Z do pack) para +Y do Blender.
    bmesh.ops.transform(bm, matrix=Matrix.Rotation(-math.pi / 2.0, 4, "X") @ Matrix.Translation((0.0, 0.0, -CLAW_CUT_Z)),
                        verts=bm.verts)
    mat = src.data.materials[0]
    mesh = bpy.data.meshes.new("claw_hook")
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(mat)
    bpy.data.objects.remove(src, do_unlink=True)
    obj = link(bpy.data.objects.new("claw_hook", mesh))
    apply_decimate(obj, CLAW_TRIS / max(tris(obj), 1))
    return obj


def muzzle_star(material):
    # Dois planos que contem o eixo de disparo (+Y): um horizontal (XY), um vertical (ZY). Cada plano
    # e uma estrela de 4 pontas alongada para a frente.
    outline = ((0.0, 1.0), (0.12, 0.34), (0.5, 0.05), (0.14, -0.14), (0.0, -0.32), (-0.14, -0.14),
               (-0.5, 0.05), (-0.12, 0.34))
    bm = bmesh.new()
    for horizontal in (True, False):
        center = bm.verts.new((0.0, 0.05, 0.0))
        ring = []
        for u, v in outline:
            ring.append(bm.verts.new((u, v, 0.0) if horizontal else (0.0, v, u)))
        for a, b in zip(ring, ring[1:] + ring[:1]):
            bm.faces.new((center, a, b))
    return mesh_object("muzzle_star", bm, material)


def shrapnel(atlas):
    bm = bmesh.new()
    tip = bm.verts.new((0.0, 0.20, 0.0))
    tail = bm.verts.new((0.0, -0.10, 0.0))
    ring = [bm.verts.new((0.05 * math.cos(a), 0.0, 0.025 * math.sin(a)))
            for a in (math.tau * i / 6.0 for i in range(6))]
    for a, b in zip(ring, ring[1:] + ring[:1]):
        bm.faces.new((tip, a, b))
        bm.faces.new((tail, b, a))
    bm.normal_update()
    paint(bm, bm.faces, STEEL, -0.10, 0.20, axis=1)
    return mesh_object("shrapnel", bm, atlas)


def debris_a(atlas):
    rng = random.Random(11)
    bm = bmesh.new()
    plank = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Diagonal((0.56, 0.14, 0.05, 1.0)))["verts"]
    for v in plank:
        if v.co.x > 0.0:  # ponta quebrada: afina para um bico
            v.co.y *= 0.15
            v.co.z *= 0.6
        v.co += Vector((rng.uniform(-0.02, 0.02), rng.uniform(-0.01, 0.01), rng.uniform(-0.005, 0.005)))
    splinter = bmesh.ops.create_cube(
        bm, size=1.0,
        matrix=Matrix.Translation((-0.05, 0.09, 0.04)) @ Matrix.Rotation(0.5, 4, "Z") @ Matrix.Diagonal((0.26, 0.04, 0.03, 1.0)))
    bm.faces.ensure_lookup_table()
    paint(bm, bm.faces, WOOD, -0.06, 0.06)
    split_faces = {f for v in splinter["verts"] for f in v.link_faces}
    paint(bm, split_faces, WOOD_LIGHT, -0.06, 0.06)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    return mesh_object("debris_wood_a", bm, atlas)


def debris_b(atlas):
    rng = random.Random(23)
    bm = bmesh.new()
    cube = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Diagonal((0.24, 0.20, 0.15, 1.0)))["verts"]
    for v in cube:
        v.co += Vector((rng.uniform(-0.03, 0.03), rng.uniform(-0.03, 0.03), rng.uniform(-0.02, 0.02)))
    bmesh.ops.bevel(bm, geom=list(bm.edges), offset=0.035, segments=1, affect="EDGES")
    paint(bm, bm.faces, WOOD, -0.1, 0.1)
    top = [f for f in bm.faces if f.normal.z > 0.5]
    paint(bm, top, WOOD_LIGHT, -0.1, 0.1)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    return mesh_object("debris_wood_b", bm, atlas)


def dynamite_crate(red, fuse_mat):
    src = import_pack("ammo_crate.gltf")[0]
    bm = bmesh.new()
    bm.from_mesh(src.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_center_median().z > CRATE_LID_Z], context="FACES")
    crate_mat = src.data.materials[0]
    crate_mat.use_backface_culling = False  # a caixa e aberta: o interior das paredes aparece
    bm.faces.ensure_lookup_table()
    mesh = bpy.data.meshes.new("dynamite_crate")
    bm.to_mesh(mesh)
    bm.free()
    bpy.data.objects.remove(src, do_unlink=True)
    mesh.materials.append(crate_mat)
    mesh.materials.append(red)
    mesh.materials.append(fuse_mat)
    obj = link(bpy.data.objects.new("dynamite_crate", mesh))
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for x, top in STICKS:
        m = Matrix.Translation((x, 0.0, (0.04 + top) / 2.0))
        res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=True, segments=6, radius1=STICK_RADIUS,
                                    radius2=STICK_RADIUS, depth=top - 0.04, matrix=m)
        for f in {f for v in res["verts"] for f in v.link_faces}:
            f.material_index = 1
    for a, b in zip(FUSE_POINTS, FUSE_POINTS[1:]):
        va, vb = Vector(a), Vector(b)
        axis = vb - va
        rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
        res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=True, segments=4, radius1=FUSE_RADIUS,
                                    radius2=FUSE_RADIUS, depth=axis.length,
                                    matrix=Matrix.Translation((va + vb) / 2.0) @ rot)
        for f in {f for v in res["verts"] for f in v.link_faces}:
            f.material_index = 2
    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        poly.use_smooth = False
    return obj


def export(objects, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objects:
        o.select_set(True)
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
    atlas = atlas_material()
    flash = flat_material("muzzle_flash", (1.0, 0.82, 0.35, 1.0), emission=1.0)
    red = flat_material("dynamite_red", (0.62, 0.07, 0.06, 1.0))
    fuse_mat = flat_material("dynamite_fuse", (0.78, 0.66, 0.42, 1.0))
    turret_meshes = turret()
    singles = [claw(), muzzle_star(flash), shrapnel(atlas), debris_a(atlas), debris_b(atlas),
               dynamite_crate(red, fuse_mat)]
    groups = {"turret": turret_meshes}
    groups.update({o.name: [o] for o in singles})
    for name, objects in groups.items():
        count = sum(tris(o) for o in objects if o.type == "MESH")
        low, high = BUDGET[name]
        if not low <= count <= high:
            raise SystemExit("%s: %d triangulos fora de %d-%d" % (name, count, low, high))
        print("PIECE %-15s %4d tris" % (name, count))
        export(objects, name)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    if PREVIEW:
        preview(groups)


def preview(groups):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "TEXTURE"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.show_backface_culling = False
    scene.render.resolution_x = 360
    scene.render.resolution_y = 360
    cam = link(bpy.data.objects.new("cam", bpy.data.cameras.new("cam")))
    cam.data.type = "ORTHO"
    scene.camera = cam
    for i, (name, objects) in enumerate(groups.items()):
        for o in bpy.data.objects:  # so o grupo da vez aparece (todos nascem na origem)
            o.hide_render = o.type == "MESH" and o not in objects
        root = next((o for o in objects if o.parent is None), objects[0])
        root.location += Vector((i * 3.0, 0.0, 0.0))
        bpy.context.view_layer.update()
        pts = [o.matrix_world @ v.co for o in objects if o.type == "MESH" for v in o.data.vertices]
        center = sum(pts, Vector()) / len(pts)
        radius = max((p - center).length for p in pts)
        cam.data.ortho_scale = radius * 2.4
        for view, direction in (("front", (0, -1, 0.15)), ("iso", (1, -1, 0.9)), ("top", (0, -0.15, 1))):
            d = Vector(direction).normalized()
            cam.location = center + d * 10
            cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = os.path.join(PREVIEW, "%s_%s.png" % (name, view))
            bpy.ops.render.render(write_still=True)
        root.location -= Vector((i * 3.0, 0.0, 0.0))


main()
