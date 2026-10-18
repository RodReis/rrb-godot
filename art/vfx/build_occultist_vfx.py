"""Monta art/vfx/occultist_vfx.blend e exporta as malhas de VFX do Ocultista em shared/assets/rrb/vfx/
(ADR-0005, SPEC-077). Arte propria, faces planas, cor por material + emissao (o atlas KayKit nao tem
roxo, entao estas pecas nao usam o atlas; a exceção de paleta e so do Ocultista, ADR-0016 item 8).
Eixo: +Z do Blender = +Y do Godot; a frente do projetil e +Y do Blender (= -Z do Godot).
  shadow_orb.glb      Projetil Sombrio: orbe escura com 5 fiapos roxos que ficam para tras (-Y do Blender)
  curse_glyph.glb     marca de Maldicao: runa em losango em pe (plano XZ), gira em torno de Y no Godot
  plague_cloud.glb    Praga: aglomerado de bolhas verde-doente e roxo (corpo do projetil e do alvo)
  profane_glyph.glb   Circulo Profano: aneis + estrela de 5 pontas deitados no chao, raio 1 u
Uso:
  blender --background --factory-startup --python build_occultist_vfx.py -- <repo> [preview_dir]
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
BLEND = os.path.join(REPO, "art", "vfx", "occultist_vfx.blend")
OUT = os.path.join(REPO, "shared", "assets", "rrb", "vfx")

# Orcamento de triangulos (prop 50-800 do CLAUDE.md; sao instanciadas em massa, entao enxutas).
BUDGET = {"shadow_orb": (60, 400), "curse_glyph": (40, 200), "plague_cloud": (60, 400),
          "profane_glyph": (60, 400)}

# Paleta: (cor base, cor/forca da emissao). Preto-roxo profundo + roxo vivo e lilas; praga com verde.
VOID = ((0.045, 0.012, 0.09), ((0.30, 0.06, 0.62), 1.6))
VIOLET = ((0.30, 0.06, 0.62), ((0.55, 0.14, 1.0), 3.0))
LILAC = ((0.62, 0.42, 0.95), ((0.78, 0.55, 1.0), 3.5))
SICK_GREEN = ((0.28, 0.55, 0.12), ((0.45, 0.95, 0.20), 2.6))
PLAGUE_VIOLET = ((0.28, 0.10, 0.40), ((0.50, 0.22, 0.75), 2.0))


def link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj


def material(name, palette):
    base, (emit, strength) = palette
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Emission Color"].default_value = (*emit, 1.0)
    bsdf.inputs["Emission Strength"].default_value = strength
    mat.diffuse_color = (*emit, 1.0)  # cor do Workbench (preview)
    mat.use_backface_culling = False  # glTF doubleSided: pecas finas e vistas dos dois lados
    return mat


def mesh_object(name, bm, materials):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for mat in materials:
        mesh.materials.append(mat)
    for poly in mesh.polygons:
        poly.use_smooth = False
    return link(bpy.data.objects.new(name, mesh))


def tris(obj):
    mesh = obj.data
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def sphere(bm, centre, radius, subdivisions, mat):
    result = bmesh.ops.create_icosphere(
        bm, subdivisions=subdivisions, radius=radius, matrix=Matrix.Translation(centre))
    for face in {f for v in result["verts"] for f in v.link_faces}:
        face.material_index = mat


def tube(bm, points, radii, sides, mat):
    """Tubo de secao regular pelos `points`, afinando ate a ponta (ultimo ponto vira vertice)."""
    rings = []
    for i, (p, r) in enumerate(zip(points[:-1], radii)):
        tangent = (points[i + 1] - p).normalized()
        ref = Vector((0.0, 0.0, 1.0)) if abs(tangent.z) < 0.9 else Vector((1.0, 0.0, 0.0))
        side = tangent.cross(ref).normalized()
        other = tangent.cross(side)
        ring = []
        for k in range(sides):
            a = math.tau * k / sides + 0.5 * i
            ring.append(bm.verts.new(p + (side * math.cos(a) + other * math.sin(a)) * r))
        rings.append(ring)
    tip = bm.verts.new(points[-1])
    faces = []
    for lower, upper in zip(rings, rings[1:]):
        for k in range(sides):
            faces.append(bm.faces.new(
                (lower[k], lower[(k + 1) % sides], upper[(k + 1) % sides], upper[k])))
    for k in range(sides):
        faces.append(bm.faces.new((rings[-1][k], rings[-1][(k + 1) % sides], tip)))
    for face in faces:
        face.material_index = mat


def box(bm, centre, size, mat):
    result = bmesh.ops.create_cube(bm, size=1.0)
    verts = result["verts"]
    bmesh.ops.scale(bm, verts=verts, vec=Vector(size), space=Matrix.Identity(4))
    bmesh.ops.translate(bm, verts=verts, vec=centre)
    for face in {f for v in verts for f in v.link_faces}:
        face.material_index = mat


def quad(bm, a, b, c, d, mat):
    face = bm.faces.new([bm.verts.new(v) for v in (a, b, c, d)])
    face.material_index = mat


def bar(bm, p, q, width, mat, z=0.0):
    """Barra plana de largura `width` entre p e q (no plano XY, altura z)."""
    d = (Vector(q) - Vector(p)).normalized()
    n = Vector((-d.y, d.x, 0.0)) * (width / 2.0)
    p, q = Vector((*p, z)), Vector((*q, z))
    quad(bm, p + n, q + n, q - n, p - n, mat)


# ---------------------------------------------------------------------------------------------
# Pecas


def shadow_orb():
    """Orbe escura com fiapos roxos para tras; a frente e +Y."""
    bm = bmesh.new()
    sphere(bm, Vector((0.0, 0.0, 0.0)), 0.14, 1, 0)
    lengths = (1.0, 0.75, 1.15, 0.65, 0.9)
    for k, scale in enumerate(lengths):
        a = math.tau * k / len(lengths)
        radial = Vector((math.cos(a), 0.0, math.sin(a)))
        pts = [
            radial * 0.09 + Vector((0.0, -0.06, 0.0)),
            radial * 0.15 + Vector((0.0, -0.22 * scale, 0.0)),
            radial * 0.12 + Vector((0.03 * math.sin(a * 2), -0.44 * scale, 0.0)),
            radial * 0.04 + Vector((0.0, -0.68 * scale, 0.0)),
        ]
        tube(bm, pts, (0.05, 0.036, 0.02), 4, 1)
    return mesh_object("shadow_orb", bm, [material("occ_orb_core", VOID), material("occ_wisp", VIOLET)])


def curse_glyph():
    """Runa em losango em pe (plano XZ, espessura em Y): moldura lilas e nucleo violeta."""
    bm = bmesh.new()
    half_w, half_h, thick, depth = 0.11, 0.17, 0.035, 0.018
    outer = [(0.0, half_h), (half_w, 0.0), (0.0, -half_h), (-half_w, 0.0)]
    k = 1.0 - thick / half_w * 1.3  # losango interno, mais fino
    inner = [(x * k, z * k) for x, z in outer]
    for y in (-depth, depth):
        for i in range(4):
            j = (i + 1) % 4
            quad(bm, (outer[i][0], y, outer[i][1]), (outer[j][0], y, outer[j][1]),
                 (inner[j][0], y, inner[j][1]), (inner[i][0], y, inner[i][1]), 0)
    for i in range(4):  # laterais da moldura (espessura)
        j = (i + 1) % 4
        for pts in (outer, inner):
            quad(bm, (pts[i][0], -depth, pts[i][1]), (pts[j][0], -depth, pts[j][1]),
                 (pts[j][0], depth, pts[j][1]), (pts[i][0], depth, pts[i][1]), 0)
    # Nucleo: losango cheio com um traco para cima e outro para baixo (um olho em pe; nada de cruz).
    gem = 0.055
    core = [(0.0, gem), (gem * 0.8, 0.0), (0.0, -gem), (-gem * 0.8, 0.0)]
    for y in (-depth, depth):
        quad(bm, *[(x, y, z) for x, z in core], 1)
    for i in range(4):
        j = (i + 1) % 4
        quad(bm, (core[i][0], -depth, core[i][1]), (core[j][0], -depth, core[j][1]),
             (core[j][0], depth, core[j][1]), (core[i][0], depth, core[i][1]), 1)
    box(bm, Vector((0.0, 0.0, 0.1)), (0.022, 0.03, 0.05), 1)
    box(bm, Vector((0.0, 0.0, -0.1)), (0.022, 0.03, 0.05), 1)
    return mesh_object("curse_glyph", bm, [material("occ_glyph_frame", LILAC),
                                           material("occ_glyph_core", VIOLET)])


def plague_cloud():
    """Bolhas de tamanhos diferentes: as grandes verde-doente, as pequenas roxo-esverdeado."""
    bm = bmesh.new()
    blobs = [
        (Vector((0.0, 0.0, 0.0)), 0.15, 1, 0),
        (Vector((0.14, 0.04, 0.07)), 0.1, 1, 1),
        (Vector((-0.12, -0.05, 0.08)), 0.105, 1, 0),
        (Vector((0.03, 0.1, -0.12)), 0.08, 0, 1),
        (Vector((-0.06, -0.12, -0.09)), 0.07, 0, 0),
        (Vector((0.12, -0.1, -0.05)), 0.06, 0, 1),
    ]
    for centre, radius, subdivisions, mat in blobs:
        sphere(bm, centre, radius, subdivisions, mat)
    return mesh_object("plague_cloud", bm, [material("occ_plague_green", SICK_GREEN),
                                            material("occ_plague_violet", PLAGUE_VIOLET)])


def profane_glyph():
    """Circulo no chao (plano XY, raio 1): aro externo, aro interno, estrela de 5 pontas, runas."""
    bm = bmesh.new()
    sides = 24
    for r_out, r_in in ((0.99, 0.93), (0.66, 0.62)):
        for i in range(sides):
            a, b = math.tau * i / sides, math.tau * (i + 1) / sides
            quad(bm, (math.cos(a) * r_out, math.sin(a) * r_out, 0.0),
                 (math.cos(b) * r_out, math.sin(b) * r_out, 0.0),
                 (math.cos(b) * r_in, math.sin(b) * r_in, 0.0),
                 (math.cos(a) * r_in, math.sin(a) * r_in, 0.0), 0)
    tips = [(math.cos(math.tau * k / 5 + math.pi / 2) * 0.63,
             math.sin(math.tau * k / 5 + math.pi / 2) * 0.63) for k in range(5)]
    for k in range(5):  # estrela {5/2}
        bar(bm, tips[k], tips[(k + 2) % 5], 0.035, 1)
    for k in range(5):  # traco radial da ponta da estrela ate o aro externo
        a = math.tau * k / 5 + math.pi / 2
        bar(bm, (math.cos(a) * 0.66, math.sin(a) * 0.66), (math.cos(a) * 0.93, math.sin(a) * 0.93),
            0.045, 1)
    for k in range(5):  # losangos entre os tracos, no meio da faixa
        a = math.tau * k / 5 + math.pi / 2 + math.pi / 5
        c = Vector((math.cos(a) * 0.795, math.sin(a) * 0.795, 0.0))
        t = Vector((math.cos(a), math.sin(a), 0.0))
        s = Vector((-t.y, t.x, 0.0))
        quad(bm, c + t * 0.09, c + s * 0.05, c - t * 0.09, c - s * 0.05, 1)
    return mesh_object("profane_glyph", bm, [material("occ_circle_ring", LILAC),
                                             material("occ_circle_star", VIOLET)])


# ---------------------------------------------------------------------------------------------


def export(obj, name):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUT, name + ".glb"),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_animations=False,
        export_apply=True,
    )


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(OUT, exist_ok=True)
    objects = {"shadow_orb": shadow_orb(), "curse_glyph": curse_glyph(),
               "plague_cloud": plague_cloud(), "profane_glyph": profane_glyph()}
    for name, obj in objects.items():
        count = tris(obj)
        low, high = BUDGET[name]
        if not low <= count <= high:
            raise SystemExit("%s: %d triangulos fora de %d-%d" % (name, count, low, high))
        zs = [v.co.z for v in obj.data.vertices]
        ys = [v.co.y for v in obj.data.vertices]
        print("PIECE %-14s %4d tris  z [%.3f, %.3f]  y [%.3f, %.3f]" % (
            name, count, min(zs), max(zs), min(ys), max(ys)))
        export(obj, name)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    if PREVIEW:
        preview(objects)


def preview(objects):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.light = "FLAT"
    scene.display.shading.show_backface_culling = False
    scene.render.resolution_x = 420
    scene.render.resolution_y = 420
    scene.world = bpy.data.worlds.new("w")
    scene.world.color = (0.10, 0.11, 0.14)
    cam = link(bpy.data.objects.new("cam", bpy.data.cameras.new("cam")))
    cam.data.type = "ORTHO"
    scene.camera = cam
    os.makedirs(PREVIEW, exist_ok=True)
    for name, obj in objects.items():
        for o in objects.values():
            o.hide_render = o is not obj
        pts = [obj.matrix_world @ v.co for v in obj.data.vertices]
        centre = sum(pts, Vector()) / len(pts)
        radius = max((p - centre).length for p in pts)
        cam.data.ortho_scale = radius * 2.6
        for view, direction in (("front", (0, -1, 0.15)), ("side", (1, 0, 0.15)),
                                ("iso", (1, -1, 0.9)), ("top", (0, -0.15, 1))):
            d = Vector(direction).normalized()
            cam.location = centre + d * 10
            cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = os.path.join(PREVIEW, "occ_%s_%s.png" % (name, view))
            bpy.ops.render.render(write_still=True)


main()
