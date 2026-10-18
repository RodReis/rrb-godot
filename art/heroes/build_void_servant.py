"""Monta art/heroes/void_servant.blend e exporta shared/assets/rrb/heroes/void_servant.glb (ADR-0005,
SPEC-078): o Servo do Vazio, invocacao do Ocultista. Arte propria, sem esqueleto: a animacao (andar,
atacar, morrer) e procedural no codigo, por transform dos nos

  VoidServant (raiz, origem no chao)
    Body   corpo encurvado de manto fantasmagorico, barra em farrapos no chao, capuz caido para a frente
    ArmL   braco esquerdo em garra, pivo no ombro
    ArmR   braco direito, espelho do esquerdo
    Eyes   dois olhos lilas brilhantes no fundo do capuz

Cor pelo atlas escuro do Ocultista (art/heroes/occultist_texture.png, gerado pelo build_occultist.py,
celulas 8x4 com degrade vertical), embutido no glb como no occultist.glb; os olhos usam o mesmo atlas
tambem como emissao. Espaco do Blender: Z para cima, frente -Y (= +Z do glTF/Godot, como os modelos
KayKit; a cena do heroi gira o Model 180 graus).
Uso:
  blender --background --factory-startup --python build_void_servant.py -- <repo> [preview_dir]
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
ATLAS = os.path.join(REPO, "art", "heroes", "occultist_texture.png")
BLEND = os.path.join(REPO, "art", "heroes", "void_servant.blend")
GLB = os.path.join(REPO, "shared", "assets", "rrb", "heroes", "void_servant.glb")
OCCULTIST = os.path.join(REPO, "shared", "assets", "rrb", "heroes", "occultist.glb")

BUDGET = (50, 800)
# Celulas do atlas do Ocultista (coluna, linha a partir do topo), ver CELLS no build_occultist.py.
CLOAK = (2, 1)  # roxo fundo da capa
TUNIC = (0, 1)  # quase preto
VOID = (7, 1)  # preto da calca: fundo do capuz
CLAW = (3, 0)  # violeta acinzentado do metal: garras claras contra o manto
GLOW = (6, 2)  # lilas do orbe

SIDES = 10
# Aneis do corpo, de baixo para cima: (z, raio x, raio frente, raio tras, centro y). Frente = -Y.
# Barra larga no chao, cintura fina, corcunda alta atras dos ombros e cabeca (capuz) projetada para a
# frente e para baixo; a ponta do capuz cai para tras.
RINGS = (
    (0.00, 0.40, 0.40, 0.44, 0.06),
    (0.26, 0.31, 0.30, 0.34, 0.05),
    (0.56, 0.26, 0.25, 0.30, 0.04),
    (0.84, 0.32, 0.26, 0.38, 0.04),
    (1.06, 0.40, 0.26, 0.42, 0.00),
    (1.20, 0.33, 0.24, 0.36, -0.08),
    (1.24, 0.22, 0.22, 0.20, -0.24),
    (1.40, 0.21, 0.24, 0.18, -0.30),
    (1.52, 0.15, 0.16, 0.14, -0.26),
)
HOOD_TIP = Vector((0.0, -0.08, 1.60))
HOOD_FROM = 6  # aneis da cabeca em diante
HEM_RAGGED = 0.16  # altura das pontas de farrapo da barra (alternadas)

SHOULDER = Vector((0.37, -0.10, 1.06))  # pivo do ArmL (lado +X); ArmR espelha em X
# Braco no espaco do ombro: pende para a frente e para fora, mao baixa na altura do quadril.
ARM_POINTS = (Vector((0.0, 0.0, 0.0)), Vector((0.12, -0.10, -0.24)), Vector((0.14, -0.26, -0.46)),
              Vector((0.10, -0.36, -0.56)))
ARM_RADII = (0.10, 0.075, 0.065, 0.07)
# Tres garras saindo da mao: (direcao, comprimento).
CLAWS = ((Vector((0.45, -0.55, -0.70)), 0.24), (Vector((0.05, -0.75, -0.65)), 0.27),
         (Vector((-0.40, -0.60, -0.70)), 0.22))

EYE = Vector((0.09, -0.51, 1.36))  # olho esquerdo; o direito espelha
EYE_SIZE = Vector((0.07, 0.035, 0.04))
EYE_TILT = math.radians(18.0)  # olho rasgado: canto de fora mais alto


def cell_uv(cell, t):
    """UV na celula: t = 1 no topo (parte clara do degrade). Mesma conta do build_occultist.py."""
    col, row = cell
    return ((col + 0.5) / 8.0, 1.0 - (row + 0.08 + 0.84 * (1.0 - t)) / 4.0)


def link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj


def materials():
    """Atlas embutido (como no occultist.glb): manto opaco e olhos com o atlas tambem na emissao."""
    atlas = bpy.data.images.load(ATLAS)
    atlas.pack()
    atlas.name = "occultist_texture"
    result = []
    for name, emission in (("void_servant", 0.0), ("void_servant_glow", 3.0)):
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        tree = mat.node_tree
        bsdf = tree.nodes["Principled BSDF"]
        bsdf.inputs["Roughness"].default_value = 0.85
        tex = tree.nodes.new("ShaderNodeTexImage")
        tex.image = atlas
        tex.interpolation = "Closest"
        tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        if emission > 0.0:
            tree.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = emission
        result.append(mat)
    return result


def part(name, bm, cells, mat, origin, parent, smooth=True):
    """Objeto `name` com pivo em `origin` (geometria em bm ja no espaco do modelo). cells: face ->
    (celula, t) ou celula (t pela altura da face)."""
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    uv = bm.loops.layers.uv.new("UVMap")
    zs = [v.co.z for v in bm.verts]
    z0, z1 = min(zs), max(zs)
    for f in bm.faces:
        cell = cells.get(f, CLOAK)
        fixed = None
        if isinstance(cell[0], tuple):
            cell, fixed = cell
        for loop in f.loops:
            t = fixed if fixed is not None else 0.15 + 0.85 * (loop.vert.co.z - z0) / max(z1 - z0, 1e-6)
            loop[uv].uv = cell_uv(cell, t)
        f.smooth = smooth
    bmesh.ops.translate(bm, verts=bm.verts, vec=-origin)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(mat)
    obj = link(bpy.data.objects.new(name, mesh))
    obj.parent = parent
    obj.location = origin
    return obj


def ring_point(ring, angle):
    z, rx, rf, rb, cy = ring
    s = math.sin(angle)
    return Vector((rx * math.cos(angle), cy + (rb if s > 0.0 else rf) * s, z))


def body(mat, root):
    """Manto em aneis (lathe) com barra em farrapos, fechado na ponta do capuz. A frente da cabeca
    (aneis do capuz voltados para -Y) fica no preto do fundo, onde os olhos aparecem."""
    bm = bmesh.new()
    cells = {}
    rings = []
    for i, ring in enumerate(RINGS):
        verts = []
        for k in range(SIDES):
            a = -math.pi / 2.0 + math.tau * k / SIDES  # k = 0 na frente (-Y)
            p = ring_point(ring, a)
            if i == 0 and k % 2:
                p.z += HEM_RAGGED  # farrapo: vertices alternados sobem, os outros tocam o chao
                p.xy *= 0.86
            verts.append(bm.verts.new(p))
        rings.append(verts)
    for i in range(len(rings) - 1):
        lo, hi = rings[i], rings[i + 1]
        for k in range(SIDES):
            j = (k + 1) % SIDES
            f = bm.faces.new((lo[k], lo[j], hi[j], hi[k]))
            if i >= HOOD_FROM and (k in (0, SIDES - 1)):
                cells[f] = (VOID, 0.2)  # rosto: abertura escura do capuz
            elif i == 0:
                cells[f] = (TUNIC, 0.25)  # barra escura
    tip = bm.verts.new(HOOD_TIP)
    for k in range(SIDES):
        bm.faces.new((rings[-1][k], rings[-1][(k + 1) % SIDES], tip))
    return part("Body", bm, cells, mat, Vector(), root)


def tube(bm, points, radii, sides):
    """Tubo de secao regular pelos `points`, fechado na ponta e na base."""
    rings = []
    for i, (p, r) in enumerate(zip(points, radii)):
        d = (points[min(i + 1, len(points) - 1)] - points[max(i - 1, 0)]).normalized()
        ref = Vector((0.0, 0.0, 1.0)) if abs(d.z) < 0.9 else Vector((0.0, 1.0, 0.0))
        u = d.cross(ref).normalized()
        w = d.cross(u)
        rings.append([bm.verts.new(p + (u * math.cos(math.tau * k / sides) + w * math.sin(math.tau * k / sides)) * r)
                      for k in range(sides)])
    faces = []
    for lo, hi in zip(rings, rings[1:]):
        for k in range(sides):
            j = (k + 1) % sides
            faces.append(bm.faces.new((lo[k], lo[j], hi[j], hi[k])))
    faces.append(bm.faces.new(list(reversed(rings[0]))))
    faces.append(bm.faces.new(rings[-1]))
    return faces


def spike(bm, base, direction, radius, length, sides=4):
    """Garra: ponta de `sides` lados que curva para dentro no ultimo terco."""
    d = direction.normalized()
    ref = Vector((0.0, 0.0, 1.0)) if abs(d.z) < 0.9 else Vector((0.0, 1.0, 0.0))
    u = d.cross(ref).normalized()
    w = d.cross(u)
    ring = [bm.verts.new(base + (u * math.cos(math.tau * k / sides + 0.4) + w * math.sin(math.tau * k / sides + 0.4)) * radius)
            for k in range(sides)]
    mid_c = base + d * (length * 0.55)
    mid = [bm.verts.new(mid_c + (v.co - base) * 0.55) for v in ring]
    hook = Vector((0.0, -0.35, 0.25)) * length  # a ponta volta para a frente e para cima: gancho
    tip = bm.verts.new(base + d * length + hook * 0.4)
    faces = [bm.faces.new(list(reversed(ring)))]
    for k in range(sides):
        j = (k + 1) % sides
        faces.append(bm.faces.new((ring[k], ring[j], mid[j], mid[k])))
        faces.append(bm.faces.new((mid[k], mid[j], tip)))
    return faces


def arm(name, mat, root, side):
    """Braco do lado `side` (+1 esquerdo do modelo = +X, -1 direito) com pivo no ombro."""
    flip = Vector((side, 1.0, 1.0))

    def world(v):
        return SHOULDER * flip + v * flip

    bm = bmesh.new()
    cells = {}
    pts = [world(p) for p in ARM_POINTS]
    for f in tube(bm, pts, ARM_RADII, 5):
        cells[f] = CLOAK
    hand = pts[-1]
    for direction, length in CLAWS:
        for f in spike(bm, hand + (direction * flip).normalized() * 0.03, direction * flip, 0.03, length):
            cells[f] = (CLAW, 0.7)
    return part(name, bm, cells, mat, SHOULDER * flip, root, smooth=False)


def eyes(mat, root):
    bm = bmesh.new()
    cells = {}
    for side in (1.0, -1.0):
        centre = Vector((EYE.x * side, EYE.y, EYE.z))
        m = (Matrix.Translation(centre) @ Matrix.Rotation(EYE_TILT * side, 4, "Y")
             @ Matrix.Diagonal((*EYE_SIZE, 1.0)))
        result = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0, matrix=m)
        for f in {f for v in result["verts"] for f in v.link_faces}:
            cells[f] = (GLOW, 0.7)  # lilas saturado (o topo da celula e quase branco)
    return part("Eyes", bm, cells, mat, Vector((0.0, EYE.y, EYE.z)), root)


def tris(objects):
    total = 0
    for o in objects:
        o.data.calc_loop_triangles()
        total += len(o.data.loop_triangles)
    return total


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    cloak, glow = materials()
    root = link(bpy.data.objects.new("VoidServant", None))
    parts = [body(cloak, root), arm("ArmL", cloak, root, 1.0), arm("ArmR", cloak, root, -1.0),
             eyes(glow, root)]
    bpy.context.view_layer.update()
    count = tris(parts)
    if not BUDGET[0] <= count <= BUDGET[1]:
        raise SystemExit("void_servant: %d triangulos fora de %d-%d" % (count, *BUDGET))
    pts = [o.matrix_world @ v.co for o in parts for v in o.data.vertices]
    print("RESULT tris", count, {o.name: tris([o]) for o in parts})
    print("RESULT z [%.3f, %.3f] x [%.3f, %.3f] y [%.3f, %.3f]" % (
        min(p.z for p in pts), max(p.z for p in pts), min(p.x for p in pts), max(p.x for p in pts),
        min(p.y for p in pts), max(p.y for p in pts)))
    print("RESULT pivots", {o.name: tuple(round(c, 3) for c in o.location) for o in parts})
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    bpy.ops.export_scene.gltf(
        filepath=GLB,
        export_format="GLB",
        export_yup=True,
        export_animations=False,
        export_apply=True,
    )
    if PREVIEW:
        preview()


def preview():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x = 560
    scene.render.resolution_y = 560
    scene.world = bpy.data.worlds.new("w")
    scene.world.color = (0.30, 0.34, 0.40)
    cam = link(bpy.data.objects.new("cam", bpy.data.cameras.new("cam")))
    scene.camera = cam
    os.makedirs(PREVIEW, exist_ok=True)

    def aim(loc, target):
        cam.location = loc
        cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()

    def render(name):
        scene.render.filepath = os.path.join(PREVIEW, name + ".png")
        bpy.ops.render.render(write_still=True)

    for view, loc in (("front", (0.0, -4.6, 1.3)), ("side", (4.6, 0.0, 1.3)),
                      ("three_quarter", (2.8, -3.4, 2.4)), ("top", (0.0, -0.01, 5.0))):
        aim(loc, (0.0, 0.0, 0.8))
        render("void_servant_" + view)
    # Pose de ataque (bracos para a frente) para conferir pivos.
    arms = [bpy.data.objects["ArmL"], bpy.data.objects["ArmR"]]
    for a in arms:
        a.rotation_euler.x = math.radians(-70.0)
    aim((2.8, -3.4, 2.4), (0.0, 0.0, 0.8))
    render("void_servant_attack_pose")
    for a in arms:
        a.rotation_euler.x = 0.0
    # Ao lado do Ocultista, na camera do jogo (45 graus, 14 u), escala do jogo 0,78 nos dois.
    bpy.ops.import_scene.gltf(filepath=OCCULTIST)
    for o in bpy.data.objects:
        if o.parent is None and o.type != "CAMERA" and o.name != "VoidServant":
            o.location.x -= 1.3
    scene.render.resolution_x = 640
    scene.render.resolution_y = 360
    aim((-0.6, -6.5, 2.0), (-0.6, 0.0, 0.9))
    render("void_servant_with_occultist")
    cam.data.lens = 100.0  # recorte da camera do jogo (35 mm) em volta dos dois
    d = 14.0 / 0.78
    aim((-0.6, -d * 0.7071, 1.0 + d * 0.7071), (-0.6, 0.0, 0.7))
    render("void_servant_game_14u")


main()
