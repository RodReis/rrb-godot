"""Monta art/vfx/paladin_vfx.blend e exporta as malhas de VFX do Paladino em shared/assets/rrb/vfx/
(ADR-0005, SPEC-076). Arte propria, faces planas, cor por material + emissao (dourado e branco-quente,
a luz "radiante" do Paladino). Eixo: +Z do Blender = +Y do Godot; a frente e +Y do Blender (= -Z do
Godot).
  holy_sigil.glb         Golpe Consagrado: faixa no chao (plano XY) de 2,5 u x 1 u com moldura, cruz e
                         divisas apontando para a frente; centro na origem (o VFX a poe 1,25 u a frente)
  retribution_ring.glb   Retribuicao: aro no chao de raio 1 u com 12 espinhos para fora (o VFX escala
                         pelo alcance de 3 u)
  blessing_halo.glb      Bencao Inviolavel: aureola deitada (raio 0,32 u) com 8 raios curtos, sobre a cabeca
Uso:
  blender --background --factory-startup --python build_paladin_vfx.py -- <repo> [preview_dir]
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
BLEND = os.path.join(REPO, "art", "vfx", "paladin_vfx.blend")
OUT = os.path.join(REPO, "shared", "assets", "rrb", "vfx")

# Orcamento de triangulos (prop 50-800 do CLAUDE.md).
BUDGET = {"holy_sigil": (20, 300), "retribution_ring": (60, 300), "blessing_halo": (40, 300)}

# Paleta: (cor base, (cor da emissao, forca)). Ouro e branco-quente.
GOLD = ((0.95, 0.70, 0.22), ((1.0, 0.70, 0.22), 1.2))
LIGHT = ((1.0, 0.92, 0.70), ((1.0, 0.86, 0.50), 1.6))


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
    mat.use_backface_culling = False  # glTF doubleSided: pecas finas
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
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def quad(bm, a, b, c, d, mat, z=0.0):
    face = bm.faces.new([bm.verts.new((p[0], p[1], z)) for p in (a, b, c, d)])
    face.material_index = mat


def tri(bm, a, b, c, mat, z=0.0):
    face = bm.faces.new([bm.verts.new((p[0], p[1], z)) for p in (a, b, c)])
    face.material_index = mat


def bar(bm, p, q, width, mat, z=0.0):
    """Barra plana de largura `width` entre p e q (no plano XY)."""
    d = (Vector(q) - Vector(p)).normalized()
    n = Vector((-d.y, d.x)) * (width / 2.0)
    p, q = Vector(p), Vector(q)
    quad(bm, p + n, q + n, q - n, p - n, mat, z)


def ring(bm, r_out, r_in, sides, mat, z=0.0):
    for i in range(sides):
        a, b = math.tau * i / sides, math.tau * (i + 1) / sides
        quad(bm, (math.cos(a) * r_out, math.sin(a) * r_out), (math.cos(b) * r_out, math.sin(b) * r_out),
             (math.cos(b) * r_in, math.sin(b) * r_in), (math.cos(a) * r_in, math.sin(a) * r_in), mat, z)


# ---------------------------------------------------------------------------------------------
# Pecas


def holy_sigil():
    """Faixa 2,5 x 1 (Y = comprimento, frente +Y): moldura, cruz no meio e 3 divisas para a frente."""
    bm = bmesh.new()
    hx, hy, t = 0.5, 1.25, 0.06
    bar(bm, (-hx, -hy), (hx, -hy), t, 0)
    bar(bm, (-hx, hy), (hx, hy), t, 0)
    bar(bm, (-hx, -hy - t / 2), (-hx, hy + t / 2), t, 0)
    bar(bm, (hx, -hy - t / 2), (hx, hy + t / 2), t, 0)
    # Cruz do Paladino no terco de tras.
    bar(bm, (0.0, -1.0), (0.0, -0.1), 0.12, 1)
    bar(bm, (-0.3, -0.36), (0.3, -0.36), 0.12, 1)  # travessa perto do topo: cruz em pe vista de tras
    # Divisas apontando a frente.
    for y in (0.15, 0.5, 0.85):
        bar(bm, (-0.36, y - 0.18), (0.0, y + 0.05), 0.08, 1)
        bar(bm, (0.36, y - 0.18), (0.0, y + 0.05), 0.08, 1)
    return mesh_object("holy_sigil", bm, [material("pal_sigil_frame", GOLD), material("pal_sigil_light", LIGHT)])


def retribution_ring():
    """Aro de raio 1 no chao com 12 espinhos triangulares para fora e 12 losangos no meio."""
    bm = bmesh.new()
    ring(bm, 1.0, 0.94, 36, 0)
    ring(bm, 0.82, 0.79, 36, 1)
    for k in range(12):
        a = math.tau * k / 12
        t = Vector((math.cos(a), math.sin(a)))
        s = Vector((-t.y, t.x))
        base = t * 0.99
        tri(bm, base + s * 0.06, base + t * 0.16, base - s * 0.06, 0)
        c = t * 0.88
        quad(bm, c + t * 0.045, c + s * 0.03, c - t * 0.045, c - s * 0.03, 1)
    return mesh_object("retribution_ring", bm, [material("pal_ring_gold", GOLD), material("pal_ring_light", LIGHT)])


def blessing_halo():
    """Aureola deitada (raio 0,32) com 8 raios curtos para fora."""
    bm = bmesh.new()
    ring(bm, 0.32, 0.26, 24, 0)
    for k in range(8):
        a = math.tau * k / 8 + math.pi / 8
        t = Vector((math.cos(a), math.sin(a)))
        bar(bm, t * 0.34, t * 0.46, 0.035, 1)
    return mesh_object("blessing_halo", bm, [material("pal_halo_gold", GOLD), material("pal_halo_light", LIGHT)])


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
    objects = {"holy_sigil": holy_sigil(), "retribution_ring": retribution_ring(),
               "blessing_halo": blessing_halo()}
    for name, obj in objects.items():
        count = tris(obj)
        low, high = BUDGET[name]
        if not low <= count <= high:
            raise SystemExit("%s: %d triangulos fora de %d-%d" % (name, count, low, high))
        xs = [v.co.x for v in obj.data.vertices]
        ys = [v.co.y for v in obj.data.vertices]
        print("PIECE %-18s %4d tris  x [%.3f, %.3f]  y [%.3f, %.3f]" % (
            name, count, min(xs), max(xs), min(ys), max(ys)))
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
        cam.data.ortho_scale = radius * 2.4
        d = Vector((0.0, -0.3, 1.0)).normalized()
        cam.location = centre + d * 10
        cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(PREVIEW, "pal_%s.png" % name)
        bpy.ops.render.render(write_still=True)


main()
