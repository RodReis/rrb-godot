"""Monta art/vfx/carrasco_vfx.blend e exporta as malhas de VFX do Carrasco em shared/assets/rrb/vfx/
(ADR-0005, ADR-0032, SPEC-098 §4). Arte propria, estilo realista da arena nova (ADR-0030): ferro
escuro e vermelho-sangue com emissao nos espinhos e nas correntes, luz dourada no julgamento; cor por
material + emissao (sem atlas). Eixo: +Z do Blender = +Y do Godot; a frente e +Y do Blender (= -Z do
Godot).
  thorn_spike.glb    Espinhos (golpe): espinho afilado e levemente curvo de 0,7 u, base na origem,
                     ponta para cima; ferro escuro com a ponta em sangue (o VFX planta varios no cone)
  thorns_volley.glb  Espinhos (recast): feixe de 4 espinhos apontando para a frente, centro na origem
  chain_link.glb     Correntes: um elo alongado (0,22 u) no eixo da frente; o VFX enfileira varios
  shackle_head.glb   Correntes: grilhao aberto com gancho na ponta do projetil, abertura para a frente
  light_pillar.glb   Correntes: coluna de luz aberta (raio 1, altura 6) com alfa na cor do vertice
                     sumindo para cima e aro no chao; o VFX escala pelo raio da luz (2,5 u)
Uso:
  blender --background --factory-startup --python build_carrasco_vfx.py -- <repo> [preview_dir]
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
BLEND = os.path.join(REPO, "art", "vfx", "carrasco_vfx.blend")
OUT = os.path.join(REPO, "shared", "assets", "rrb", "vfx")

# Orcamento de triangulos (pedido do SPEC-098 e prop 50-800 do CLAUDE.md).
BUDGET = {
    "thorn_spike": (20, 60),
    "thorns_volley": (60, 200),
    "chain_link": (32, 80),
    "shackle_head": (60, 200),
    "light_pillar": (40, 200),
}

# Paleta: (cor base, metal, rugosidade, (cor da emissao, forca)).
IRON = ((0.16, 0.15, 0.15), 0.85, 0.45, ((0.0, 0.0, 0.0), 0.0))
BLOOD = ((0.55, 0.03, 0.03), 0.2, 0.35, ((0.9, 0.05, 0.03), 2.2))
CHAIN = ((0.30, 0.28, 0.27), 0.9, 0.35, ((0.45, 0.06, 0.03), 0.15))
GOLD = ((1.0, 0.86, 0.5), 0.0, 1.0, ((1.0, 0.82, 0.45), 3.0))


def link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj


def material(name, palette):
    base, metal, rough, (emit, strength) = palette
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Emission Color"].default_value = (*emit, 1.0)
    bsdf.inputs["Emission Strength"].default_value = strength
    mat.diffuse_color = (*(emit if strength > 0 else base), 1.0)  # cor do Workbench (preview)
    return mat


def mesh_object(name, bm, materials, smooth=True):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for mat in materials:
        mesh.materials.append(mat)
    for poly in mesh.polygons:
        poly.use_smooth = smooth
    return link(bpy.data.objects.new(name, mesh))


def tris(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def spike(bm, base, axis, length, radius, sides=6, rings=(0.0, 0.55, 0.82), bend=0.08, tip_from=2):
    """Espinho afilado de `base` ao longo de `axis`, curvado de leve; aneis a partir de `tip_from`
    (indice) ganham o material 1 (ponta em sangue)."""
    axis = Vector(axis).normalized()
    side = axis.orthogonal().normalized()
    other = axis.cross(side)
    loops = []
    for k, t in enumerate(rings):
        centre = Vector(base) + axis * (length * t) + side * (bend * length * t * t)
        r = radius * (1.0 - t) ** 0.8
        loop = []
        for i in range(sides):
            a = math.tau * i / sides
            loop.append(bm.verts.new(centre + (side * math.cos(a) + other * math.sin(a)) * r))
        loops.append(loop)
    tip = bm.verts.new(Vector(base) + axis * length + side * (bend * length))
    for k in range(len(loops) - 1):
        for i in range(sides):
            j = (i + 1) % sides
            f = bm.faces.new([loops[k][i], loops[k][j], loops[k + 1][j], loops[k + 1][i]])
            f.material_index = 1 if k + 1 >= tip_from else 0
    for i in range(sides):
        f = bm.faces.new([loops[-1][i], loops[-1][(i + 1) % sides], tip])
        f.material_index = 1
    bm.faces.new(list(reversed(loops[0]))).material_index = 0  # tampa da base


def torus(bm, centre, major_x, major_y, minor, segs, sides, arc=math.tau, mat=0, plane="XY"):
    """Toro eliptico (elo/grilhao) em `plane`; `arc` < tau deixa aberto."""
    closed = arc >= math.tau - 1e-6
    count = segs if closed else segs + 1
    loops = []
    for s in range(count):
        u = arc * s / segs
        cu, su = math.cos(u), math.sin(u)
        ring_c = Vector((cu * major_x, su * major_y, 0.0))
        out = Vector((cu * major_y, su * major_x, 0.0)).normalized()
        loop = []
        for i in range(sides):
            v = math.tau * i / sides
            p = ring_c + out * (math.cos(v) * minor) + Vector((0, 0, math.sin(v) * minor))
            if plane == "XZ":
                p = Vector((p.x, p.z, p.y))
            elif plane == "YZ":
                p = Vector((p.z, p.x, p.y))
            loop.append(bm.verts.new(Vector(centre) + p))
        loops.append(loop)
    last = len(loops) if closed else len(loops) - 1
    for s in range(last):
        a, b = loops[s], loops[(s + 1) % len(loops)]
        for i in range(sides):
            j = (i + 1) % sides
            bm.faces.new([a[i], a[j], b[j], b[i]]).material_index = mat
    return loops


# ---------------------------------------------------------------------------------------------
# Pecas


def thorn_spike():
    bm = bmesh.new()
    spike(bm, (0, 0, 0), (0, 0, 1), 0.7, 0.075, sides=6)
    return mesh_object("thorn_spike", bm, [material("car_iron", IRON), material("car_blood", BLOOD)])


def thorns_volley():
    """4 espinhos apontando para a frente (+Y), um no meio maior e 3 em volta."""
    bm = bmesh.new()
    spike(bm, (0, -0.3, 0), (0, 1, 0), 0.62, 0.07, sides=6, bend=0.0)
    for k in range(3):
        a = math.tau * k / 3 + 0.4
        off = Vector((math.cos(a) * 0.09, -0.22, math.sin(a) * 0.09))
        d = Vector((math.cos(a) * 0.12, 1.0, math.sin(a) * 0.12))
        spike(bm, off, d, 0.46, 0.05, sides=5, bend=0.05)
    return mesh_object("thorns_volley", bm, [material("car_iron", IRON), material("car_blood", BLOOD)])


def chain_link():
    """Elo alongado no eixo da frente (Y): 0,22 de comprido, 0,12 de largo, arame de 0,03."""
    bm = bmesh.new()
    torus(bm, (0, 0, 0), 0.06, 0.11, 0.028, 10, 4, plane="XY")
    return mesh_object("chain_link", bm, [material("car_chain", CHAIN)])


def shackle_head():
    """Grilhao aberto (aro de 0,17 em pe, de frente) com o gancho para tras, onde a corrente prende."""
    bm = bmesh.new()
    torus(bm, (0, 0.05, 0), 0.17, 0.17, 0.035, 12, 4, arc=math.tau * 0.78, mat=0, plane="XZ")
    torus(bm, (0, -0.14, 0), 0.05, 0.08, 0.025, 6, 4, mat=0, plane="XY")  # olhal para a corrente
    spike(bm, (0.12, 0.05, 0.12), (0.4, 1.0, 0.4), 0.16, 0.03, sides=4, bend=0.0)
    spike(bm, (-0.12, 0.05, 0.12), (-0.4, 1.0, 0.4), 0.16, 0.03, sides=4, bend=0.0)
    return mesh_object("shackle_head", bm, [material("car_chain", CHAIN), material("car_blood", BLOOD)])


def light_pillar():
    """Coluna aberta (raio 1, altura 6, 16 lados) com alfa 1 embaixo e 0 em cima, mais um aro no chao."""
    bm = bmesh.new()
    col = bm.loops.layers.color.new("Col")
    sides = 16
    heights = (0.0, 1.2, 6.0)
    alphas = (1.0, 0.55, 0.0)
    rings = []
    for h in heights:
        rings.append([bm.verts.new((math.cos(math.tau * i / sides), math.sin(math.tau * i / sides), h))
                      for i in range(sides)])
    alpha_of = {}
    for ring_verts, a in zip(rings, alphas):
        for v in ring_verts:
            alpha_of[v] = a
    for k in range(len(rings) - 1):
        for i in range(sides):
            j = (i + 1) % sides
            bm.faces.new([rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]])
    ground = []
    for i in range(sides):
        a, b = math.tau * i / sides, math.tau * (i + 1) / sides
        vs = [bm.verts.new((math.cos(a) * r, math.sin(a) * r, 0.02)) for r in (1.08, 0.86)]
        vs += [bm.verts.new((math.cos(b) * r, math.sin(b) * r, 0.02)) for r in (0.86, 1.08)]
        for v in vs:
            alpha_of[v] = 1.0
        ground.append(bm.faces.new(vs))
    for face in bm.faces:
        for loop in face.loops:
            a = alpha_of[loop.vert]
            loop[col] = (1.0, 1.0, 1.0, a)
    obj = mesh_object("light_pillar", bm, [material("car_light", GOLD)], smooth=True)
    attrs = obj.data.color_attributes
    attrs.active_color = attrs["Col"]  # o exportador so leva a cor do vertice ativa
    attrs.render_color_index = attrs.active_color_index
    return obj


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
        export_vertex_color="ACTIVE" if name == "light_pillar" else "NONE",
    )


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(OUT, exist_ok=True)
    objects = {
        "thorn_spike": thorn_spike(),
        "thorns_volley": thorns_volley(),
        "chain_link": chain_link(),
        "shackle_head": shackle_head(),
        "light_pillar": light_pillar(),
    }
    for name, obj in objects.items():
        count = tris(obj)
        low, high = BUDGET[name]
        if not low <= count <= high:
            raise SystemExit("%s: %d triangulos fora de %d-%d" % (name, count, low, high))
        pts = [v.co for v in obj.data.vertices]
        print("PIECE %-14s %4d tris  x [%.3f, %.3f]  y [%.3f, %.3f]  z [%.3f, %.3f]" % (
            name, count, min(p.x for p in pts), max(p.x for p in pts), min(p.y for p in pts),
            max(p.y for p in pts), min(p.z for p in pts), max(p.z for p in pts)))
        export(obj, name)
    for i, obj in enumerate(objects.values()):
        obj.location.x = i * 1.5  # so na fonte: as pecas exportadas ficam na origem
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    if PREVIEW:
        preview(objects)


def preview(objects):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.light = "STUDIO"
    scene.render.resolution_x = 360
    scene.render.resolution_y = 360
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
        d = Vector((0.6, -1.0, 0.7)).normalized()
        cam.location = centre + d * 10
        cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(PREVIEW, "car_%s.png" % name)
        bpy.ops.render.render(write_still=True)


main()
