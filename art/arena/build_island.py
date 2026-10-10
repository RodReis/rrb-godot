"""Monta os kits da Ilha Flutuante Arcana (F40 sobre a SPEC-044) e exporta os .glb (ADR-0005).

Geometria escrita em coordenadas do Godot (x leste, y para cima, z sul; origem no centro da
cratera) e convertida para o Blender na hora de criar a malha, para o .glb cair no lugar certo
sem transformacao. Cor-base pelo atlas KayKit (UV apontando para uma celula do atlas; o degrade
vertical da celula faz as faces de cima mais claras). Bevel de 1-2 segmentos so no cenario
proprio (ADR-0006 D-V3). Nenhuma malha traz colisao: ela continua no builder da arena.
Uso (na raiz do repo):
  blender --background --factory-startup --python art/arena/build_island.py -- <repo>
Saida: art/arena/*.blend (fonte), art/arena/preview_*.png (previa Workbench) e
shared/assets/rrb/arena/*.glb.
"""
import math
import os
import sys

import bpy
from mathutils import Vector, noise
from mathutils.geometry import delaunay_2d_cdt

argv = sys.argv[sys.argv.index("--") + 1:]
REPO = argv[0]
ART = os.path.join(REPO, "art", "arena")
OUT = os.path.join(REPO, "shared", "assets", "rrb", "arena")
ATLAS = os.path.join(REPO, "shared", "assets", "kaykit", "medieval_hexagon", "hexagons_medieval.png")

# Celulas do atlas KayKit (coluna 0..7, linha 0..3; linha 0 = topo).
GRASS = (4, 1)
GRASS_LIGHT = (0, 2)
DIRT = (3, 2)
SAND = (5, 1)
STONE = (2, 0)
STONE_DARK = (3, 0)
STONE_BLUE = (2, 2)
CHARCOAL = (4, 0)
BROWN = (6, 0)
BROWN_DARK = (7, 1)
WOOD = (2, 1)
WOOD_DARK = (7, 3)
MAGENTA = (6, 2)
GREEN_DARK = (1, 2)
GREEN = (3, 3)
RED = (1, 3)
CREAM = (5, 2)

# Medidas da SPEC-044 (mesmas constantes do tools/arena/build_arena.gd).
ARENA_RADIUS = 35.0
ISLAND_RADIUS = 37.0
LIP_RADIUS = 37.6
RING_IN = 14.0
RING_OUT = 18.0
RING_MID = 16.0
WATER_HALF = 1.7
CHANNEL_HALF = 2.0
BANK = 0.8
GROOVE_DEPTH = -1.0
WATER_Y = -0.45
CRATER_RADIUS = 6.0
BRIDGE_AZIMUTHS = (45.0, 135.0, 225.0, 315.0)
SPAWN_A = (-24.0, -24.0)
GATE_A = (-15.0, -15.0)
FIELD_O = (-26.0, 0.0)
FIELD_SO = (-16.0, 24.0)
# Cor das runas por time (SPEC-007 §5): ciano na base A, dourado na B; magma na cratera.
RUNE_A = (0.1, 0.9, 1.0)
RUNE_B = (1.0, 0.75, 0.2)
MAGMA = (1.0, 0.45, 0.1)
CRYSTAL = (0.85, 0.15, 0.85)

TRIS = {}


# --- utilidades ----------------------------------------------------------------------------


def polar(azimuth_deg, r):
    """Azimute anti-horario a partir do norte (-z), visto de cima: N 0, O 90, S 180, L 270."""
    a = math.radians(azimuth_deg)
    return (-math.sin(a) * r, -math.cos(a) * r)


def n3(x, y, z):
    return noise.noise(Vector((x, y, z)))


def _mapped(geometry, fn):
    """Aplica fn a cada vertice; aceita lista de pontos ou (vertices, faces)."""
    if isinstance(geometry, tuple) and len(geometry) == 2:
        return [fn(p) for p in geometry[0]], geometry[1]
    return [fn(p) for p in geometry]


def rot_y(geometry, deg, pivot=(0.0, 0.0, 0.0)):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))

    def fn(p):
        dx, dz = p[0] - pivot[0], p[2] - pivot[2]
        return (pivot[0] + dx * c + dz * s, p[1], pivot[2] - dx * s + dz * c)

    return _mapped(geometry, fn)


def rot_z(geometry, deg, pivot=(0.0, 0.0, 0.0)):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))

    def fn(p):
        dx, dy = p[0] - pivot[0], p[1] - pivot[1]
        return (pivot[0] + dx * c - dy * s, pivot[1] + dx * s + dy * c, p[2])

    return _mapped(geometry, fn)


def rot_x(geometry, deg, pivot=(0.0, 0.0, 0.0)):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))

    def fn(p):
        dy, dz = p[1] - pivot[1], p[2] - pivot[2]
        return (p[0], pivot[1] + dy * c - dz * s, pivot[2] + dy * s + dz * c)

    return _mapped(geometry, fn)


def translate(geometry, dx, dy, dz):
    return _mapped(geometry, lambda p: (p[0] + dx, p[1] + dy, p[2] + dz))


# --- primitivas (listas de vertices em coordenadas do Godot + faces) ------------------------


def box(x0, y0, z0, sx, sy, sz):
    v = [
        (x0, y0, z0), (x0 + sx, y0, z0), (x0 + sx, y0, z0 + sz), (x0, y0, z0 + sz),
        (x0, y0 + sy, z0), (x0 + sx, y0 + sy, z0), (x0 + sx, y0 + sy, z0 + sz), (x0, y0 + sy, z0 + sz),
    ]
    f = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    return v, f


def prism(cx, cz, y0, y1, r0, r1, n, phase=0.0, jitter=0.0, seed=0.0):
    """Tronco de n lados; r1 = 0 vira cone. jitter desloca os vertices (rocha)."""
    v, f = [], []
    for k, (y, r) in enumerate(((y0, r0), (y1, r1))):
        if r <= 0.0:
            v.append((cx, y, cz))
            continue
        for i in range(n):
            a = math.radians(phase + 360.0 * i / n)
            rr = r + jitter * n3(cx + math.cos(a) * 3.0, y * 2.0 + seed, cz + math.sin(a) * 3.0)
            yy = y + jitter * 0.5 * n3(math.cos(a) * 5.0, seed + 7.0, math.sin(a) * 5.0)
            v.append((cx + math.cos(a) * rr, yy, cz + math.sin(a) * rr))
    if r1 <= 0.0:
        apex = n
        for i in range(n):
            f.append((i, apex, (i + 1) % n))
        f.append(tuple(range(n - 1, -1, -1)))
    else:
        for i in range(n):
            j = (i + 1) % n
            f.append((i, j, n + j, n + i))
        f.append(tuple(range(n - 1, -1, -1)))
        f.append(tuple(range(n, 2 * n)))
    return v, f


def extrude_profile(profile_zy, x0, x1):
    """Poligono no plano (z, y) extrudado ao longo de x (perfil de ponte)."""
    v = [(x0, y, z) for z, y in profile_zy] + [(x1, y, z) for z, y in profile_zy]
    n = len(profile_zy)
    f = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))]
    for i in range(n):
        j = (i + 1) % n
        f.append((i, n + i, n + j, j))
    return v, f


class Kit:
    """Acumula vertices/faces de um objeto; cada face lembra a celula do atlas e a faixa t."""

    def __init__(self, name):
        self.name = name
        self.verts = []
        self.faces = []
        self.cells = []
        self.rune = {}  # indice da face -> (r, g, b) emissivo

    def add(self, geometry, cell, t=(0.3, 0.8), rune=None):
        verts, faces = geometry
        base = len(self.verts)
        self.verts.extend(verts)
        for face in faces:
            if rune is not None:
                self.rune[len(self.faces)] = rune
            self.faces.append(tuple(base + i for i in face))
            self.cells.append((cell, t))

    def tris(self):
        return sum(len(f) - 2 for f in self.faces)


# --- Blender: materiais, malha, export, previa ---------------------------------------------


_materials = {}


def atlas_material():
    if "kaykit_atlas" in _materials:
        return _materials["kaykit_atlas"]
    mat = bpy.data.materials.new("kaykit_atlas")
    mat.use_nodes = True
    mat.use_backface_culling = False
    nodes = mat.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.85
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ATLAS, check_existing=True)
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    _materials["kaykit_atlas"] = mat
    return mat


def trim_material():
    """Cintas de ferro do bau: material proprio ("chest_trim") que o chest.gd troca pela raridade."""
    if "chest_trim" in _materials:
        return _materials["chest_trim"]
    mat = bpy.data.materials.new("chest_trim")
    mat.use_nodes = True
    mat.use_backface_culling = False
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.28, 0.29, 0.32, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.6
    bsdf.inputs["Roughness"].default_value = 0.45
    _materials["chest_trim"] = mat
    return mat


def rune_material(color):
    key = "rune_%02x%02x%02x" % tuple(int(c * 255) for c in color)
    if key in _materials:
        return _materials[key]
    mat = bpy.data.materials.new(key)
    mat.use_nodes = True
    mat.use_backface_culling = False
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
    bsdf.inputs["Emission Strength"].default_value = 2.5
    bsdf.inputs["Roughness"].default_value = 0.3
    _materials[key] = mat
    return mat


def uv_of(cell, t):
    col, row = cell
    return ((col + 0.5) / 8.0, 1.0 - (row + 1.0 - t) / 4.0)


def build(kit, bevel=0.0):
    """Cria o objeto no Blender a partir do Kit (coordenadas Godot -> Blender: (x, -z, y))."""
    mesh = bpy.data.meshes.new(kit.name)
    verts = [(x, -z, y) for x, y, z in kit.verts]
    mesh.from_pydata(verts, [], kit.faces)
    mesh.validate()
    atlas = atlas_material()
    mesh.materials.append(atlas)
    rune_slots = {}
    uv = mesh.uv_layers.new(name="UVMap")
    for poly in mesh.polygons:
        poly.use_smooth = False
        (cell, (t_lo, t_hi)) = kit.cells[poly.index]
        rune = kit.rune.get(poly.index)
        if rune is not None:
            if rune not in rune_slots:
                mesh.materials.append(trim_material() if rune == "trim" else rune_material(rune))
                rune_slots[rune] = len(mesh.materials) - 1
            poly.material_index = rune_slots[rune]
        ys = [kit.verts[mesh.loops[l].vertex_index][1] for l in poly.loop_indices]
        y_min, y_max = min(ys), max(ys)
        for l in poly.loop_indices:
            y = kit.verts[mesh.loops[l].vertex_index][1]
            if y_max - y_min < 1e-4:
                t = t_hi if poly.normal.z > 0.5 else (t_lo if poly.normal.z < -0.5 else (t_lo + t_hi) / 2)
            else:
                t = t_lo + (t_hi - t_lo) * (y - y_min) / (y_max - y_min)
            uv.data[l].uv = uv_of(cell, t)
    obj = bpy.data.objects.new(kit.name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    import bmesh

    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    if bevel > 0.0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = "ANGLE"
        mod.angle_limit = math.radians(40.0)
    TRIS[kit.name] = kit.tris()
    return obj


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _materials.clear()


def export(obj, name):
    for o in bpy.context.scene.objects:
        o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUT, name + ".glb"),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_animations=False,
        export_image_format="AUTO",
    )


def preview(name, objects, spread=0.0, top=False):
    """Previa Workbench (cor da textura) com os objetos lado a lado; salva art/arena/preview_<name>.png."""
    x = 0.0
    for obj in objects:
        obj.location.x = x
        x += spread
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 800
    scene.render.filepath = os.path.join(ART, "preview_%s.png" % name)
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
    cam_data.ortho_scale = size * 1.05
    cam = bpy.data.objects.new("PreviewCam", cam_data)
    scene.collection.objects.link(cam)
    direction = Vector((0.0, -0.05, 1.0)) if top else Vector((0.6, -1.0, 0.75))
    cam.location = center + direction.normalized() * size * 2.0
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam_data.clip_end = size * 10.0
    scene.camera = cam
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)


def save(name):
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ART, name + ".blend"))


# --- kit 1: ilha (piso + penhascos + leito do rio), rio de mana, lago de magma --------------


def groove_distance(x, z):
    r = math.hypot(x, z)
    d_ring = abs(r - RING_MID) - WATER_HALF
    d_channel = max(abs(x) - WATER_HALF, RING_OUT - r)
    return min(d_ring, d_channel)


def island_height(x, z):
    r = math.hypot(x, z)
    d = groove_distance(x, z)
    if d <= 0.0:
        y = GROOVE_DEPTH
    elif d < BANK:
        y = GROOVE_DEPTH * (1.0 - d / BANK)
    else:
        y = 0.0
    if r > ISLAND_RADIUS:
        y -= 0.35 * (r - ISLAND_RADIUS) / (LIP_RADIUS - ISLAND_RADIUS)
    return y


def segment_distance(px, pz, ax, az, bx, bz):
    dx, dz = bx - ax, bz - az
    length2 = dx * dx + dz * dz
    t = 0.0 if length2 == 0.0 else max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / length2))
    return math.hypot(px - (ax + dx * t), pz - (az + dz * t))


def road_segments():
    """Estradas de terra da metade A (x < 0); a metade B e o espelho em x."""
    segs = [(SPAWN_A, GATE_A, 1.8), (GATE_A, polar(45.0, 18.6), 1.8), (GATE_A, FIELD_O, 1.4)]
    arc = [polar(a, 20.5) for a in range(45, 136, 8)]
    for i in range(len(arc) - 1):
        segs.append((arc[i], arc[i + 1], 1.6))
    for az in (45.0, 135.0):
        segs.append((polar(az, 7.3), polar(az, 14.2), 1.8))
    mirrored = [((-a[0], a[1]), (-b[0], b[1]), hw) for a, b, hw in segs]
    return segs + mirrored


ROADS = road_segments()
PATCHES = [(FIELD_O, 4.0), (FIELD_SO, 4.0), ((-FIELD_O[0], FIELD_O[1]), 4.0), ((-FIELD_SO[0], FIELD_SO[1]), 4.0),
           ((0.0, -10.0), 3.5), ((0.0, 10.0), 3.5)]


def ground_cell(cx, cz):
    r = math.hypot(cx, cz)
    if island_height(cx, cz) < -0.05 and r < LIP_RADIUS - 0.2:
        return STONE_BLUE, (0.15, 0.35)
    if r < CRATER_RADIUS + 0.3:
        return STONE_DARK, (0.2, 0.45)
    if r < CRATER_RADIUS + 1.4:
        return CHARCOAL, (0.25, 0.5)
    for spawn in (SPAWN_A, (-SPAWN_A[0], SPAWN_A[1])):
        if math.hypot(cx - spawn[0], cz - spawn[1]) < 12.0 and r < ARENA_RADIUS:
            return SAND, (0.4, 0.6)
    for a, b, hw in ROADS:
        if segment_distance(cx, cz, a[0], a[1], b[0], b[1]) < hw:
            return DIRT, (0.45, 0.65)
    for center, radius in PATCHES:
        if math.hypot(cx - center[0], cz - center[1]) < radius:
            return DIRT, (0.45, 0.65)
    light = n3(cx * 0.35, 1.0, cz * 0.35)
    cell = GRASS_LIGHT if light > 0.45 else GRASS
    return cell, (0.45 + light * 0.1, 0.7 + light * 0.1)


def build_island():
    points = [Vector((0.0, 0.0))]
    radii = [2, 4, 5.8, 6.6, 7.5, 9, 10.5, 12, 13.2, 14.3, 16, 17.7, 18.8, 20, 22, 24, 26, 28, 30, 32, 34, 35.6, ISLAND_RADIUS]
    for r in radii:
        n = 24 if r < 6 else 72
        for i in range(n):
            a = 2 * math.pi * i / n + (0.03 if int(r) % 2 else 0.0)
            points.append(Vector((math.cos(a) * r, math.sin(a) * r)))
    # Canal N-S: linhas crispas nas bordas da agua e do barranco.
    for sign in (-1.0, 1.0):
        for x in (-2.5, -1.7, 0.0, 1.7, 2.5):
            z = 18.8 * sign
            while abs(z) < LIP_RADIUS - 0.6:
                points.append(Vector((x, z)))
                z += 1.0 * sign
    # Labio da ilha, ordenado por angulo, com o entalhe do canal.
    lip = []
    for i in range(72):
        a = 2 * math.pi * i / 72
        lip.append(a)
    for sign in (1.0, -1.0):
        for x in (-2.5, -1.7, 1.7, 2.5):
            lip.append(math.atan2(sign * math.sqrt(LIP_RADIUS**2 - x * x), x) % (2 * math.pi))
    lip = sorted(set(lip))
    lip_start = len(points)
    for a in lip:
        points.append(Vector((math.cos(a) * LIP_RADIUS, math.sin(a) * LIP_RADIUS)))
    coords, _edges, faces, orig_verts, _oe, _of = delaunay_2d_cdt(points, [], [], 0, 1e-5)
    # delaunay_2d_cdt pode reordenar: mapeia indice original -> novo.
    new_index = {}
    for new_i, originals in enumerate(orig_verts):
        for o in originals:
            new_index[o] = new_i
    kit = Kit("island_chassis")
    verts = [(c.x, island_height(c.x, c.y), c.y) for c in coords]
    top_faces = []
    for face in faces:
        cx = sum(coords[i].x for i in face) / len(face)
        cz = sum(coords[i].y for i in face) / len(face)
        top_faces.append((tuple(face), ground_cell(cx, cz)))
    base = len(kit.verts)
    kit.verts.extend(verts)
    for face, (cell, t) in top_faces:
        kit.faces.append(tuple(base + i for i in face))
        kit.cells.append((cell, t))
    # Saia rochosa: aneis abaixo do labio com ruido, fechando num ponto no fundo.
    lip_idx = [base + new_index[lip_start + k] for k in range(len(lip))]
    rings = [lip_idx]
    skirt = [(38.4, -2.6, BROWN, (0.5, 0.75)), (37.0, -6.8, BROWN, (0.35, 0.6)), (31.5, -11.6, BROWN_DARK, (0.3, 0.6)),
             (23.0, -15.8, BROWN_DARK, (0.2, 0.45))]
    for k, (rk, yk, _cell, _t) in enumerate(skirt):
        ring = []
        for a in lip:
            nz = n3(math.cos(a) * 3.1, k * 1.7, math.sin(a) * 3.1)
            rr = rk + nz * 1.6
            yy = yk + 0.8 * n3(math.cos(a) * 5.0, k * 2.3 + 9.0, math.sin(a) * 5.0)
            ring.append(len(kit.verts))
            kit.verts.append((math.cos(a) * rr, yy, math.sin(a) * rr))
        rings.append(ring)
    bottom = len(kit.verts)
    kit.verts.append((0.0, -18.6, 0.0))
    for k in range(1, len(rings)):
        cell, t = skirt[k - 1][2], skirt[k - 1][3]
        above, below = rings[k - 1], rings[k]
        for i in range(len(lip)):
            j = (i + 1) % len(lip)
            kit.faces.append((above[i], above[j], below[j], below[i]))
            kit.cells.append((cell, t))
    last = rings[-1]
    for i in range(len(lip)):
        j = (i + 1) % len(lip)
        kit.faces.append((last[i], last[j], bottom))
        kit.cells.append((CHARCOAL, (0.2, 0.3)))
    return build(kit)


def build_river():
    kit = Kit("river_mana")
    # Anel (fluxo tangencial: u = angulo).
    n = 120
    r0, r1 = RING_MID - WATER_HALF, RING_MID + WATER_HALF
    base = len(kit.verts)
    for i in range(n):
        a = 2 * math.pi * i / n
        kit.verts.append((math.cos(a) * r0, WATER_Y, math.sin(a) * r0))
        kit.verts.append((math.cos(a) * r1, WATER_Y, math.sin(a) * r1))
    for i in range(n):
        j = (i + 1) % n
        kit.faces.append((base + 2 * i, base + 2 * i + 1, base + 2 * j + 1, base + 2 * j))
        kit.cells.append((STONE_BLUE, (0.5, 0.5)))
    # Canais N e S + cascata (fluxo para fora e depois para baixo).
    for sign in (-1.0, 1.0):
        strip = []
        z = (RING_MID + WATER_HALF - 0.4) * sign
        while abs(z) < LIP_RADIUS + 0.6:
            strip.append((WATER_Y - 0.01, z))
            z += 1.5 * sign
        strip.append((WATER_Y - 0.01, (LIP_RADIUS + 0.6) * sign))
        drop = [(-2.0, 0.5), (-4.5, 1.0), (-8.0, 1.4), (-12.0, 1.6), (-16.5, 1.7)]
        for dy, lean in drop:
            strip.append((WATER_Y + dy, (LIP_RADIUS + 0.6 + lean) * sign))
        base = len(kit.verts)
        for y, zz in strip:
            kit.verts.append((-WATER_HALF, y, zz))
            kit.verts.append((WATER_HALF, y, zz))
        for i in range(len(strip) - 1):
            kit.faces.append((base + 2 * i, base + 2 * i + 1, base + 2 * i + 3, base + 2 * i + 2))
            kit.cells.append((STONE_BLUE, (0.5, 0.5)))
    obj = build(kit)
    # UV proprio do rio: u ao longo do fluxo (0..1 por trecho), v atravessado.
    mesh = obj.data
    uv = mesh.uv_layers.active
    ring_faces = n
    for poly in mesh.polygons:
        if poly.index < ring_faces:
            for l in poly.loop_indices:
                v = mesh.vertices[mesh.loops[l].vertex_index].co
                a = math.atan2(-v.y, v.x) % (2 * math.pi)
                k = (mesh.loops[l].vertex_index - 0) // 2
                u = k / n if (k / n) > 0.0 or poly.index < n - 1 else 1.0
                uv.data[l].uv = (u, 0.0 if (mesh.loops[l].vertex_index % 2 == 0) else 1.0)
        else:
            for l in poly.loop_indices:
                vi = mesh.loops[l].vertex_index
                v = mesh.vertices[vi].co
                along = (abs(v.y) - (RING_MID + WATER_HALF - 0.4)) / 24.0 + max(0.0, -v.z) / 20.0
                uv.data[l].uv = (along, 0.0 if vi % 2 == 0 else 1.0)
    for poly in mesh.polygons:
        poly.use_smooth = True
    return obj


def build_lava():
    kit = Kit("lava_lake")
    n = 48
    r = CRATER_RADIUS + 0.4
    base = 0
    kit.verts.append((0.0, 0.03, 0.0))
    for i in range(n):
        a = 2 * math.pi * i / n
        kit.verts.append((math.cos(a) * r, 0.03, math.sin(a) * r))
    for i in range(n):
        j = (i + 1) % n
        kit.faces.append((base, base + 1 + j, base + 1 + i))
        kit.cells.append((CHARCOAL, (0.3, 0.3)))
    obj = build(kit)
    uv = obj.data.uv_layers.active
    for poly in obj.data.polygons:
        for l in poly.loop_indices:
            v = obj.data.vertices[obj.data.loops[l].vertex_index].co
            uv.data[l].uv = ((v.x / r + 1.0) / 2.0, (v.y / r + 1.0) / 2.0)
    return obj


# --- kit 2: cratera (pilar de obsidiana) ----------------------------------------------------


def build_pillar():
    kit = Kit("obsidian_pillar")
    # Espira principal: cobre o cilindro de colisao r 1,4 x h 3,0 (8 lados, r 1,55).
    kit.add(prism(0, 0, 0.0, 1.3, 1.55, 1.25, 8, phase=22.5, jitter=0.08, seed=1), CHARCOAL, (0.2, 0.45))
    kit.add(prism(0, 0, 1.3, 2.5, 1.25, 0.8, 8, phase=22.5, jitter=0.1, seed=2), CHARCOAL, (0.3, 0.55))
    kit.add(prism(0.15, -0.1, 2.5, 3.45, 0.8, 0.0, 8, phase=22.5, jitter=0.06, seed=3), STONE_DARK, (0.35, 0.65))
    # Lascas em volta e veios de magma na base.
    kit.add(prism(1.3, 0.6, 0.0, 1.5, 0.45, 0.0, 6, phase=10.0), CHARCOAL, (0.25, 0.5))
    kit.add(prism(-1.1, -0.9, 0.0, 1.1, 0.4, 0.0, 6, phase=40.0), CHARCOAL, (0.25, 0.5))
    kit.add(prism(0.2, 1.4, 0.0, 0.8, 0.35, 0.0, 5, phase=70.0), STONE_DARK, (0.3, 0.55))
    kit.add(prism(0, 0, 0.3, 0.55, 1.58, 1.5, 8, phase=22.5), CHARCOAL, (0.3, 0.3), rune=MAGMA)
    return build(kit)


# --- kit 3: castelo -------------------------------------------------------------------------


def stone_courses(kit, x0, x1, y0, y1, z, outward, rows=3, seed=0.0):
    """Fiadas de blocos de pedra em relevo numa face vertical paralela a x (referencia do PI:
    muralha em blocos). outward = +1 face em +z, -1 face em -z. Blocos alternados por fiada."""
    height = (y1 - y0) / rows
    for r in range(rows):
        offset = 0.0 if r % 2 == 0 else 0.26
        x = x0 - offset
        k = 0
        while x < x1 - 0.05:
            w = 0.46 + 0.12 * n3(x * 3.0 + seed, r * 1.7, k)
            bx0, bx1 = max(x0, x), min(x1, x + w)
            if bx1 - bx0 > 0.12:
                depth = 0.035 + 0.02 * n3(bx0, r + seed, 3.0)
                zz = z if outward > 0 else z - depth
                t = 0.5 + 0.15 * n3(bx0 * 2.0, r * 3.0 + seed, 7.0)
                kit.add(box(bx0, y0 + r * height + 0.03, zz, bx1 - bx0, height - 0.06, depth), STONE, (t - 0.1, t + 0.15))
            x += w + 0.05
            k += 1


def stone_ring_courses(kit, cx, cz, y0, y1, r, n, rows=4, seed=0.0):
    """Fiadas de blocos em relevo em volta de um prisma de n lados (torre)."""
    height = (y1 - y0) / rows
    for row in range(rows):
        for i in range(n):
            a = math.radians(22.5 + 360.0 * i / n + (0.0 if row % 2 == 0 else 180.0 / n))
            w = 0.62 + 0.1 * n3(i * 2.0, row + seed, 1.0)
            depth = 0.04 + 0.02 * n3(i, row * 2.0 + seed, 5.0)
            t = 0.5 + 0.15 * n3(i * 3.0, row + seed, 9.0)
            face = box(-w / 2, y0 + row * height + 0.03, r - 0.01, w, height - 0.06, depth)
            face = rot_y(face, -math.degrees(a) + 90.0)
            kit.add(translate(face, cx, 0.0, cz), STONE, (t - 0.1, t + 0.15))


def build_wall(team):
    rune = RUNE_A if team == "a" else RUNE_B
    kit = Kit("castle_wall_%s" % team)
    kit.add(box(-1.0, 0.0, -0.4, 2.0, 2.1, 0.8), STONE, (0.35, 0.7))
    for x in (-0.85, -0.2, 0.45):
        kit.add(box(x, 2.1, -0.4, 0.4, 0.4, 0.8), STONE, (0.5, 0.8))
    stone_courses(kit, -1.0, 1.0, 0.35, 1.1, 0.4, 1, rows=2, seed=1.0)
    stone_courses(kit, -1.0, 1.0, 1.45, 2.1, 0.4, 1, rows=2, seed=2.0)
    stone_courses(kit, -1.0, 1.0, 0.35, 1.1, -0.4, -1, rows=2, seed=3.0)
    stone_courses(kit, -1.0, 1.0, 1.45, 2.1, -0.4, -1, rows=2, seed=4.0)
    kit.add(box(-0.98, 1.15, -0.44, 1.96, 0.22, 0.88), STONE, (0.3, 0.3), rune=rune)
    kit.add(box(-1.0, 0.0, -0.5, 2.0, 0.35, 1.0), STONE_DARK, (0.3, 0.55))
    return build(kit, bevel=0.05)


def build_tower(team):
    rune = RUNE_A if team == "a" else RUNE_B
    kit = Kit("castle_tower_%s" % team)
    kit.add(prism(0, 0, 0.0, 3.9, 1.2, 1.1, 8, phase=22.5), STONE, (0.3, 0.7))
    # 2 + 3 fiadas (40 blocos): torre fica em ~700 tris, dentro do orcamento de cenario.
    stone_ring_courses(kit, 0, 0, 0.5, 1.55, 1.17, 8, rows=2, seed=1.0)
    stone_ring_courses(kit, 0, 0, 1.95, 3.85, 1.12, 8, rows=3, seed=2.0)
    kit.add(prism(0, 0, 0.0, 0.5, 1.35, 1.25, 8, phase=22.5), STONE_DARK, (0.3, 0.5))
    kit.add(prism(0, 0, 3.9, 4.15, 1.3, 1.3, 8, phase=22.5), STONE, (0.55, 0.8))
    for i in range(8):
        a = math.radians(22.5 + 45.0 * i)
        cx, cz = math.cos(a) * 1.05, math.sin(a) * 1.05
        kit.add(rot_y(box(cx - 0.24, 4.15, cz - 0.2, 0.48, 0.4, 0.4), -math.degrees(a), (cx, 0, cz)), STONE, (0.5, 0.8))
    kit.add(prism(0, 0, 1.6, 1.9, 1.18, 1.18, 8, phase=22.5), STONE, (0.3, 0.3), rune=rune)
    kit.add(box(-0.05, 4.15, -0.05, 0.1, 1.5, 0.1), WOOD_DARK, (0.3, 0.6))
    flag = ([(0.05, 5.6, 0.0), (0.05, 5.15, 0.0), (0.95, 5.38, 0.15)], [(0, 1, 2)])
    kit.add(flag, RED, (0.5, 0.5), rune=rune)
    return build(kit, bevel=0.05)


def build_gate(team):
    rune = RUNE_A if team == "a" else RUNE_B
    kit = Kit("castle_gate_%s" % team)
    for sx in (-1.0, 1.0):
        x0 = 2.5 if sx > 0 else -3.1
        kit.add(box(x0, 0.0, -0.5, 0.6, 3.3, 1.0), STONE, (0.35, 0.7))
        for face in (1, -1):
            stone_courses(kit, x0, x0 + 0.6, 0.1, 1.1, 0.5 * face, face, rows=3, seed=sx + face)
            stone_courses(kit, x0, x0 + 0.6, 1.55, 2.85, 0.5 * face, face, rows=3, seed=sx * 2 + face)
        kit.add(box(x0 - 0.02, 1.2, -0.54, 0.64, 0.25, 1.08), STONE, (0.3, 0.3), rune=rune)
        bx = 3.15 if sx > 0 else -3.35
        kit.add(box(bx, 1.9, 0.5, 0.2, 0.2, 0.35), WOOD_DARK, (0.3, 0.6))
        kit.add(prism(bx + 0.1, 0.75, 2.1, 2.55, 0.14, 0.0, 6), RED, (0.5, 0.5), rune=MAGMA)
    kit.add(box(-3.1, 2.9, -0.5, 6.2, 0.55, 1.0), STONE, (0.4, 0.75))
    for x in (-2.9, -1.7, -0.5, 0.7, 1.9):
        kit.add(box(x, 3.45, -0.5, 0.5, 0.4, 1.0), STONE, (0.5, 0.8))
    kit.add(box(-3.1, 2.95, -0.55, 6.2, 0.2, 1.1), STONE, (0.3, 0.3), rune=rune)
    return build(kit, bevel=0.05)


def build_door():
    kit = Kit("castle_door")
    for x0 in (-2.45, 0.05):
        kit.add(box(x0, 0.05, -0.18, 2.4, 2.85, 0.36), WOOD, (0.35, 0.7))
        for y in (0.5, 1.45, 2.4):
            kit.add(box(x0 - 0.02, y, -0.22, 2.44, 0.14, 0.44), CHARCOAL, (0.3, 0.5))
    return build(kit, bevel=0.03)


# --- kit 4: pontes, rochas, barricadas ------------------------------------------------------


def build_bridge():
    kit = Kit("bridge_stone")
    profile = [(-3.0, 0.0), (3.0, 0.0), (3.0, -1.6), (2.3, -1.55), (1.5, -1.1), (0.7, -0.55), (0.0, -0.3),
               (-0.7, -0.55), (-1.5, -1.1), (-2.3, -1.55), (-3.0, -1.6)]
    kit.add(extrude_profile(profile, -3.1, 3.1), STONE, (0.3, 0.65))
    for sx in (-1.0, 1.0):
        x0 = 2.6 if sx > 0 else -3.1
        for z0 in (-3.0, -1.0, 1.0):
            kit.add(box(x0, 0.0, z0, 0.5, 0.45, 1.6), STONE, (0.45, 0.8))
        for z0 in (-3.0, 2.6):
            kit.add(box(x0 - 0.05, 0.0, z0, 0.6, 0.7, 0.5), STONE_DARK, (0.4, 0.75))
    return build(kit, bevel=0.05)


def build_boulder():
    kit = Kit("boulder")
    kit.add(prism(0, 0, -0.2, 0.9, 1.55, 1.72, 7, phase=12.0, jitter=0.22, seed=4), STONE_DARK, (0.25, 0.55))
    kit.add(prism(0, 0, 0.9, 1.9, 1.72, 1.2, 7, phase=12.0, jitter=0.22, seed=5), STONE_DARK, (0.35, 0.65))
    kit.add(prism(0.1, -0.1, 1.9, 2.65, 1.2, 0.0, 7, phase=12.0, jitter=0.15, seed=6), STONE, (0.4, 0.7))
    kit.add(prism(1.2, 0.9, -0.1, 0.7, 0.6, 0.0, 6, phase=30.0, jitter=0.1, seed=7), STONE_DARK, (0.3, 0.55))
    return build(kit, bevel=0.06)


def build_barricade():
    """Cavalo-de-frisa (referencia do PI): estacas afiadas cruzadas em X sobre uma viga."""
    kit = Kit("barricade")
    for i in range(6):
        x = -1.0 + 0.4 * i
        for lean in (34.0, -34.0):
            stake = prism(0, 0, -0.15, 1.35, 0.085, 0.085, 6, phase=i * 7.0)
            tip = prism(0, 0, 1.35, 1.6, 0.085, 0.0, 6, phase=i * 7.0)
            for geo in (stake, tip):
                kit.add(translate(rot_x(geo, lean, (0.0, 0.75, 0.0)), x, 0.0, 0.0), WOOD, (0.35, 0.7))
    kit.add(prism(0, 0, 0.0, 2.4, 0.07, 0.07, 6), WOOD_DARK, (0.4, 0.7))
    beam = rot_z(prism(0, 0, -1.2, 1.2, 0.07, 0.07, 6), 90.0)
    kit.add(translate(beam, 0.0, 0.78, 0.0), WOOD_DARK, (0.4, 0.7))
    return build(kit, bevel=0.02)


def build_chest_body():
    """Corpo do bau (madeira + cintas de ferro; referencia do PI). Origem no chao, centro."""
    kit = Kit("chest_body")
    kit.add(box(-0.45, 0.0, -0.3, 0.9, 0.5, 0.6), WOOD, (0.3, 0.65))
    for z in (-0.31, 0.3):
        for y in (0.08, 0.3):
            kit.add(box(-0.44, y, z, 0.88, 0.05, 0.01), WOOD_DARK, (0.4, 0.5))
    for x in (-0.46, -0.03, 0.4):
        kit.add(box(x, -0.01, -0.32, 0.06, 0.53, 0.64), CHARCOAL, (0.3, 0.3), rune="trim")
    kit.add(box(-0.47, 0.0, -0.32, 0.94, 0.07, 0.64), CHARCOAL, (0.3, 0.3), rune="trim")
    kit.add(box(-0.06, 0.36, 0.3, 0.12, 0.12, 0.04), CHARCOAL, (0.3, 0.3), rune="trim")
    return build(kit, bevel=0.015)


def build_chest_lid():
    """Tampa abaulada; origem na dobradica (aresta de tras, em cima do corpo): o chest.gd gira o
    node pai. Geometria em z 0..0.64 e y 0..0.32."""
    kit = Kit("chest_lid")
    n = 7
    verts, faces = [], []
    for side, x in ((0, -0.47), (1, 0.47)):
        for i in range(n):
            a = math.pi * i / (n - 1)
            verts.append((x, 0.02 + 0.3 * math.sin(a), 0.32 - 0.32 * math.cos(a)))
    for i in range(n - 1):
        faces.append((i, i + 1, n + i + 1, n + i))
    faces.append(tuple(range(n - 1, -1, -1)))
    faces.append(tuple(range(n, 2 * n)))
    bottom = len(verts)
    verts.extend([(-0.47, 0.0, 0.0), (0.47, 0.0, 0.0), (0.47, 0.0, 0.64), (-0.47, 0.0, 0.64)])
    faces.append((bottom, bottom + 1, bottom + 2, bottom + 3))
    kit.add((verts, faces), WOOD, (0.4, 0.75))
    for x in (-0.48, -0.03, 0.42):
        band_v, band_f = [], []
        for i in range(n):
            a = math.pi * i / (n - 1)
            for dx in (0.0, 0.06):
                band_v.append((x + dx, 0.03 + 0.315 * math.sin(a), 0.32 - 0.335 * math.cos(a)))
        for i in range(n - 1):
            band_f.append((2 * i, 2 * i + 2, 2 * i + 3, 2 * i + 1))
        kit.add((band_v, band_f), CHARCOAL, (0.3, 0.3), rune="trim")
    kit.add(box(-0.05, 0.02, 0.6, 0.1, 0.1, 0.06), CHARCOAL, (0.3, 0.3), rune="trim")
    return build(kit, bevel=0.012)


# --- kit 5: props (cristais, pinheiro, torre de vigia, balista, ilhotas) --------------------


def shard(h, r, tilt_x, tilt_z, dx, dz):
    geo = prism(0, 0, -0.25, h, r, 0.0, 6, phase=15.0)
    v, f = geo
    # Estreita a base e desloca o anel para 30 % da altura: bipiramide.
    v = [(x * (0.55 if y < 0 else 1.0), y, z * (0.55 if y < 0 else 1.0)) for x, y, z in v]
    ring = [(x, h * 0.3, z) if 0 <= i < 6 else (x, y, z) for i, (x, y, z) in enumerate(v)]
    bottom = [(0.0, -0.25, 0.0)]
    verts = ring + bottom
    faces = list(f) + [(i, (i + 1) % 6, 7) for i in range(6)]
    faces = [fc for fc in faces if len(fc) != 6]
    verts = translate(rot_z(rot_x(verts, tilt_x), tilt_z), dx, 0.0, dz)
    return verts, faces


def build_crystal(name, shards):
    kit = Kit(name)
    kit.add(prism(0, 0, 0.0, 0.35, 0.95, 0.75, 8, phase=22.5, jitter=0.08, seed=8), STONE_DARK, (0.25, 0.5))
    # Lascas em material proprio ("rune_d826d8"): o Godot troca por arcane_crystal.gdshader no
    # .import (use_external); a rocha da base continua no atlas.
    for h, r, tx, tz, dx, dz in shards:
        kit.add(shard(h, r, tx, tz, dx, dz), MAGENTA, (0.2, 0.6), rune=CRYSTAL)
    return build(kit)


def build_pine():
    kit = Kit("pine_tree")
    kit.add(prism(0, 0, 0.0, 0.9, 0.2, 0.16, 6), BROWN_DARK, (0.3, 0.6))
    for y, r, h in ((0.7, 1.15, 1.2), (1.5, 0.9, 1.15), (2.25, 0.6, 1.05)):
        kit.add(prism(0, 0, y, y + h, r, 0.0, 7, phase=10.0 + y * 30.0), GREEN_DARK, (0.3, 0.8))
    return build(kit)


def build_watchtower():
    kit = Kit("watchtower")
    for x in (-0.8, 0.65):
        for z in (-0.8, 0.65):
            kit.add(box(x, 0.0, z, 0.16, 3.2, 0.16), WOOD_DARK, (0.3, 0.6))
    kit.add(box(-1.1, 3.0, -1.1, 2.2, 0.18, 2.2), WOOD, (0.4, 0.7))
    kit.add(box(-0.8, 1.2, -0.7, 0.1, 0.1, 1.4), WOOD, (0.4, 0.7))
    kit.add(box(0.7, 1.2, -0.7, 0.1, 0.1, 1.4), WOOD, (0.4, 0.7))
    for x in (-1.05, 0.95):
        for z in (-1.05, 0.95):
            kit.add(box(x, 3.18, z, 0.1, 1.2, 0.1), WOOD_DARK, (0.3, 0.6))
    for z in (-1.05, 0.95):
        kit.add(box(-1.05, 3.7, z, 2.1, 0.08, 0.08), WOOD, (0.4, 0.7))
    kit.add(prism(0, 0, 4.3, 5.3, 1.7, 0.0, 4, phase=45.0), WOOD_DARK, (0.3, 0.6))
    return build(kit)


def build_ballista():
    kit = Kit("ballista")
    kit.add(box(-0.8, 0.0, -0.5, 1.6, 0.3, 1.0), WOOD_DARK, (0.3, 0.6))
    kit.add(box(-0.12, 0.3, -0.12, 0.24, 0.6, 0.24), WOOD_DARK, (0.3, 0.6))
    kit.add(rot_x(box(-0.1, 0.9, -1.0, 0.2, 0.14, 2.0), 12.0, (0, 0.9, 0)), WOOD, (0.4, 0.7))
    kit.add(rot_y(box(-1.1, 0.95, -0.95, 2.2, 0.12, 0.12), 0.0), WOOD, (0.4, 0.7))
    kit.add(box(-0.03, 1.02, -0.95, 0.06, 0.06, 1.6), CHARCOAL, (0.3, 0.5))
    return build(kit)


def build_islet(name, radius, seed):
    kit = Kit(name)
    n = 24
    top = []
    for i in range(n):
        a = 2 * math.pi * i / n
        rr = radius * (1.0 + 0.18 * n3(math.cos(a) * 2.0 + seed, seed, math.sin(a) * 2.0))
        top.append((math.cos(a) * rr, 0.3 * n3(math.cos(a) * 4.0, seed + 3.0, math.sin(a) * 4.0), math.sin(a) * rr))
    center = len(kit.verts)
    kit.verts.append((0.0, 0.25, 0.0))
    base = len(kit.verts)
    kit.verts.extend(top)
    for i in range(n):
        j = (i + 1) % n
        kit.faces.append((center, base + j, base + i))
        kit.cells.append((GRASS, (0.5, 0.75)))
    rings = [list(range(base, base + n))]
    for k, (rk, yk, cell) in enumerate(((1.02, -1.8, BROWN), (0.85, -4.2, BROWN_DARK), (0.5, -6.5, BROWN_DARK))):
        ring = []
        for i in range(n):
            a = 2 * math.pi * i / n
            rr = radius * rk * (1.0 + 0.2 * n3(math.cos(a) * 3.0 + seed, k * 1.3 + seed, math.sin(a) * 3.0))
            ring.append(len(kit.verts))
            kit.verts.append((math.cos(a) * rr, yk * radius / 6.0, math.sin(a) * rr))
        rings.append(ring)
        above, below = rings[-2], rings[-1]
        for i in range(n):
            j = (i + 1) % n
            kit.faces.append((above[i], above[j], below[j], below[i]))
            kit.cells.append((cell, (0.3, 0.65)))
    bottom = len(kit.verts)
    kit.verts.append((0.0, -7.5 * radius / 6.0, 0.0))
    last = rings[-1]
    for i in range(n):
        j = (i + 1) % n
        kit.faces.append((last[i], last[j], bottom))
        kit.cells.append((CHARCOAL, (0.2, 0.3)))
    return build(kit)


# --- montagem -------------------------------------------------------------------------------


def main():
    os.makedirs(OUT, exist_ok=True)

    reset_scene()
    island = build_island()
    river = build_river()
    lava = build_lava()
    for obj, name in ((island, "island_chassis"), (river, "river_mana"), (lava, "lava_lake")):
        export(obj, name)
    save("island_chassis")
    preview("island_chassis", [island, river, lava], top=True)
    preview("island_chassis_side", [island, river, lava])

    reset_scene()
    pillar = build_pillar()
    export(pillar, "obsidian_pillar")
    save("volcanic_crater")
    preview("volcanic_crater", [pillar])

    reset_scene()
    castle = [build_wall("a"), build_wall("b"), build_tower("a"), build_tower("b"), build_gate("a"), build_gate("b"), build_door()]
    for obj in castle:
        export(obj, obj.name)
    save("castle_modular")
    preview("castle_modular", castle, spread=7.5)

    reset_scene()
    ruins = [build_bridge(), build_boulder(), build_barricade(), build_chest_body(), build_chest_lid()]
    for obj in ruins:
        export(obj, obj.name)
    save("ruins_bridges")
    preview("ruins_bridges", ruins, spread=8.0)

    reset_scene()
    small = [(0.9, 0.22, 8.0, -6.0, 0.0, 0.0), (0.6, 0.16, -18.0, 10.0, 0.42, 0.25), (0.5, 0.13, 12.0, 22.0, -0.35, 0.3)]
    large = [(2.6, 0.5, 5.0, -4.0, 0.0, 0.0), (1.7, 0.36, -22.0, 12.0, 0.7, 0.3), (1.3, 0.3, 15.0, 25.0, -0.6, 0.45),
             (1.0, 0.24, 28.0, -14.0, 0.2, -0.7), (0.8, 0.2, -10.0, -28.0, -0.55, -0.5)]
    props = [build_crystal("crystal_small", small), build_crystal("crystal_large", large), build_pine(), build_watchtower(),
             build_ballista(), build_islet("islet_a", 6.0, 1.0), build_islet("islet_b", 9.0, 2.0), build_islet("islet_c", 7.0, 3.0)]
    for obj in props:
        export(obj, obj.name)
    save("props_crystals")
    preview("props_crystals", props, spread=9.0)

    print("[island] triangulos por asset:")
    for name, tris in TRIS.items():
        print("  %-18s %6d" % (name, tris))


main()
