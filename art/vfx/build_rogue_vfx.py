"""Monta art/vfx/rogue_vfx.blend e exporta as malhas de VFX da Ladina em shared/assets/rrb/vfx/
(ADR-0005, SPEC-058 §6): rogue_bolt (virote do pack arrow_crossbow, ponta na origem e voo em -Z do
Godot), smoke_puff_a/b/c (tufos de fumaca de faces planas, cor pelo atlas KayKit hexagons_medieval)
e slash_x (2 laminas curvas cruzadas do golpe da Emboscada).
Uso:
  blender --background --factory-startup --python build_rogue_vfx.py -- <pack2_dir> <repo> [preview_dir]
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
ATLAS = os.path.join(REPO, "shared", "assets", "kaykit", "medieval_hexagon", "hexagons_medieval.png")
BLEND = os.path.join(REPO, "art", "vfx", "rogue_vfx.blend")
OUT = os.path.join(REPO, "shared", "assets", "rrb", "vfx")

# Orcamento de triangulos (SPEC-058 §6).
BUDGET = {"rogue_bolt": (30, 80), "smoke_puff_a": (40, 80), "smoke_puff_b": (40, 80),
          "smoke_puff_c": (40, 80), "slash_x": (20, 40)}
# Celula do atlas 8x4 (coluna, linha a partir do topo) para a fumaca: cinza claro do aco.
SMOKE_CELL = (2, 0)
# Laminas do corte: raio do arco, abertura (graus), largura, segmentos.
SLASH_RADIUS = 0.6
SLASH_ARC = 110.0
SLASH_WIDTH = 0.12
SLASH_SEGMENTS = 8
SLASH_DARK_RED = (0.32, 0.02, 0.04, 1.0)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def atlas_material():
    mat = bpy.data.materials.new("smoke_atlas")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 1.0
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ATLAS)
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def flat_material(name, color):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = color
    return mat


def link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj


def bolt():
    bpy.ops.import_scene.gltf(filepath=PACK + r"\Assets\gltf\arrow_crossbow.gltf")
    src = bpy.data.objects["arrow_crossbow"]
    mesh = src.data.copy()
    # Ponta em -Y do pack (a ponta e a ponta mais estreita); ponta para +Y do Blender = -Z do
    # Godot, e ponta na origem (Arrow.origin e a ponta do projetil).
    tip = min(v.co.y for v in mesh.vertices)
    mesh.transform(Matrix.Rotation(math.pi, 4, "Z") @ Matrix.Translation((0.0, -tip, 0.0)))
    bpy.data.objects.remove(src, do_unlink=True)
    for poly in mesh.polygons:
        poly.use_smooth = False
    return link(bpy.data.objects.new("rogue_bolt", mesh))


def puff(name, seed, atlas):
    rng = random.Random(seed)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.5)  # 80 triangulos
    for v in bm.verts:
        v.co *= 0.85 + 0.3 * rng.random()
        v.co.z *= 0.8
    zs = [v.co.z for v in bm.verts]
    lo, hi = min(zs), max(zs)
    col, row = SMOKE_CELL
    for f in bm.faces:
        for loop in f.loops:
            t = (loop.vert.co.z - lo) / (hi - lo)
            loop[uv].uv = ((col + 0.5) / 8.0, 1.0 - (row + 0.15 + 0.7 * (1.0 - t)) / 4.0)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(atlas)
    for poly in mesh.polygons:
        poly.use_smooth = False
    return link(bpy.data.objects.new(name, mesh))


def slash(red):
    bm = bmesh.new()
    for sign in (-1.0, 1.0):
        rows = []
        for i in range(SLASH_SEGMENTS + 1):
            a = math.radians(-SLASH_ARC / 2.0 + SLASH_ARC * i / SLASH_SEGMENTS)
            # Lamina fina nas pontas e larga no meio.
            w = SLASH_WIDTH * math.sin(math.pi * i / SLASH_SEGMENTS)
            outer = Vector((math.sin(a) * (SLASH_RADIUS + w), 0.0, math.cos(a) * (SLASH_RADIUS + w)))
            inner = Vector((math.sin(a) * SLASH_RADIUS, 0.0, math.cos(a) * SLASH_RADIUS))
            turn = Matrix.Rotation(math.radians(45.0 * sign), 3, "Y")
            shift = Vector((0.0, 0.0, -SLASH_RADIUS))
            rows.append((bm.verts.new(turn @ (outer + shift)), bm.verts.new(turn @ (inner + shift))))
        for (a0, b0), (a1, b1) in zip(rows, rows[1:]):
            bm.faces.new((a0, b0, b1, a1))
    bmesh.ops.triangulate(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("slash_x")
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(red)
    return link(bpy.data.objects.new("slash_x", mesh))


def tris(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def export(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUT, obj.name + ".glb"),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_animations=False,
    )


def main():
    reset()
    os.makedirs(OUT, exist_ok=True)
    atlas = atlas_material()
    red = flat_material("slash_red", SLASH_DARK_RED)
    objects = [bolt(), puff("smoke_puff_a", 1, atlas), puff("smoke_puff_b", 2, atlas),
               puff("smoke_puff_c", 3, atlas), slash(red)]
    for obj in objects:
        count = tris(obj)
        low, high = BUDGET[obj.name]
        if not low <= count <= high:
            raise SystemExit("%s: %d triangulos fora de %d-%d" % (obj.name, count, low, high))
        print("PIECE %-14s %3d tris" % (obj.name, count))
        export(obj)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    if PREVIEW:
        scene = bpy.context.scene
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.shading.color_type = "TEXTURE"
        scene.render.resolution_x = 320
        scene.render.resolution_y = 320
        cam = link(bpy.data.objects.new("cam", bpy.data.cameras.new("cam")))
        scene.camera = cam
        for i, obj in enumerate(objects):
            obj.location = Vector((i * 1.6, 0.0, 0.0))
        for i, obj in enumerate(objects):
            cam.location = obj.location + Vector((1.2, -1.6, 1.0))
            direction = obj.location - cam.location
            cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = os.path.join(PREVIEW, obj.name + ".png")
            bpy.ops.render.render(write_still=True)


main()
