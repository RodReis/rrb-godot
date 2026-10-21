"""Vale em volta da arena (F56, ADR-0012): faixa externa so visual que substitui o abismo da
Ilha Flutuante. Relevo (piso de floresta, encostas e cristas), riacho que sai da poca do canto
NO/SE, em .glb (ADR-0005); mais as posicoes das arvores e da margem do riacho em JSON para o
builder da arena (tools/arena/arena_valley.gd). O pinheiro e o kit_pine_far (build_rim_kit.py, F96)
e a margem usa as pedras e os juncos do kit do meio do mapa (F95).

Reusa as medidas e utilidades do build_island.py (mesmas coordenadas do Godot: x leste, y para
cima, z sul, origem no centro da cratera). Nenhuma malha traz colisao nem navmesh: o vale fica
fora da area jogavel (|x|, |z| <= 40). A beira da ilha (labio a 0,6 u) e o buraco do relevo:
a malha comeca exatamente no contorno do labio, na mesma altura (sem fresta).

Uso (na raiz do repo):
  blender --background --factory-startup --python art/arena/build_valley.py -- <repo>
Saida: art/arena/valley.blend (fonte), art/arena/preview_valley.png, shared/assets/rrb/arena/
valley_terrain.glb, valley_stream.glb e tools/arena/valley_trees.json.
"""
import json
import math
import os
import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.geometry import delaunay_2d_cdt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_island as bi  # noqa: E402  (main() so roda como script)

TREES_JSON = os.path.join(bi.REPO, "tools", "arena", "valley_trees.json")

# Relevo. rho = max(|x|, |z|) (quadrado, como a ilha). O piso de floresta vai ate RISE_FROM; dali
# as encostas sobem ate a crista (CREST_RHO, CREST_HEIGHT variam com o angulo). Nos cantos NO/SE
# o piso se alarga (BAY) para caber o riacho e a lagoa. A camera do jogo (45 graus, FOV 75) nunca
# ve acima do horizonte: toda encosta mais alta que ~12 u e a 20 u dela fecha a vista.
OUTER = 108.0
RISE_FROM = 52.0
CREST_RHO = (80.0, 92.0)
CREST_HEIGHT = (30.0, 42.0)
SLOPE_POWER = 1.6
BAY_EXTRA = 14.0
BAY_SIGMA_DEG = 22.0
LIP_Y = -0.35  # altura do labio da ilha em island_height
FLOOR_RAMP = (0.6, 7.0)  # distancia a ilha (sd) em que o piso sai do labio e passa a ondular

# Riacho (cantos NO e SE): comeca no canto da poca (labio) e segue pela diagonal, com meandros,
# ate a lagoa; (s ao longo da diagonal, v lateral) a partir do canto.
STREAM_START = (-(bi.BASTION_POOL + bi.LIP), -(bi.BASTION_POOL + bi.LIP))
STREAM_PATH = ((-2.0, 0.0), (0.0, 0.0), (6.0, 1.6), (12.0, -1.4), (18.0, 2.2), (23.0, 0.4), (27.0, 0.0))
STREAM_HALF = 0.85
STREAM_BED_HALF = 1.6
STREAM_BANK = 2.4
STREAM_DEPTH = 0.75
STREAM_STEP = 1.2
# A fita do riacho comeca no leito, depois da queda do vertedouro (a cortina kit_falls_sheet cobre
# o canal e a queda e emenda nela).
STREAM_FROM_SD = bi.LIP + 1.0
POND_RADIUS = 4.2
POND_BANK = 3.2
POND_DEPTH = 1.1
WATER_LIFT = 0.1

# Floresta (pontos de arvore): grade com jitter, filtrada por inclinacao, altura e agua.
TREE_STEP = 2.3
TREE_FROM_SD = 2.4
TREE_MAX_SLOPE_Y = 0.62
TREE_SCALE = (1.15, 2.1)
# A camera do jogo fica ate ~10 u acima do heroi e ~10 u para fora da beira: perto da ilha as
# arvores sao mudas (abaixo dela) e crescem ate o tamanho cheio em TREE_GROW_SD.
TREE_GROW_SD = (3.0, 28.0)
TREE_NEAR_FACTOR = 0.32
TREE_SINK = 0.25
TREE_CLEAR_STREAM = 3.0
TREE_CLEAR_POND = 6.5

# Margem do riacho (F96): a cada BANK_STEP u dos dois lados da fita e em volta da lagoa, pedra
# (kind 0) ou junco (kind 1) do kit, a BANK_OFFSET u alem da agua; o resto fica vazio.
BANK_STEP = 0.9
BANK_OFFSET = (0.15, 0.9)
BANK_STONE_CHANCE = 0.34
BANK_REED_CHANCE = 0.3
BANK_SCALE = ((0.7, 1.5), (0.8, 1.3))


def smooth(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def hash01(x, z):
    return (math.sin(x * 12.9898 + z * 78.233) * 43758.5453) % 1.0


def stream_points(sign):
    """Polilinha do riacho no mundo (x, z); sign = 1 canto NO, -1 canto SE (rotacao de 180)."""
    dx, dz = -0.70710678, -0.70710678
    px, pz = 0.70710678, -0.70710678
    out = []
    for s, v in STREAM_PATH:
        out.append(((STREAM_START[0] + dx * s + px * v) * sign, (STREAM_START[1] + dz * s + pz * v) * sign))
    return out


def densify_path(points, step):
    """Catmull-Rom pelos pontos de controle, amostrado a cada ~step u (meandro liso, sem quinas)."""
    pts = [points[0]] + list(points) + [points[-1]]
    out = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        n = max(1, int(math.hypot(p2[0] - p1[0], p2[1] - p1[1]) / step))
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            out.append(tuple(
                0.5 * (2 * p1[a] + (-p0[a] + p2[a]) * t + (2 * p0[a] - 5 * p1[a] + 4 * p2[a] - p3[a]) * t2
                       + (-p0[a] + 3 * p1[a] - 3 * p2[a] + p3[a]) * t3)
                for a in (0, 1)))
    out.append(points[-1])
    return out


STREAMS = [densify_path(stream_points(sign), STREAM_STEP) for sign in (1.0, -1.0)]
PONDS = [(path[-1][0], path[-1][1]) for path in STREAMS]


def path_distance(x, z, path):
    best = 1e9
    for a, b in zip(path, path[1:]):
        abx, abz = b[0] - a[0], b[1] - a[1]
        t = max(0.0, min(1.0, ((x - a[0]) * abx + (z - a[1]) * abz) / (abx * abx + abz * abz)))
        best = min(best, math.hypot(x - (a[0] + abx * t), z - (a[1] + abz * t)))
    return best


def angular_bay(x, z):
    """Alargamento do piso em direcao aos cantos NO (-135 graus) e SE (45 graus)."""
    a = math.degrees(math.atan2(z, x))
    d = min(abs((a + 135.0 + 180.0) % 360.0 - 180.0), abs((a - 45.0 + 180.0) % 360.0 - 180.0))
    return BAY_EXTRA * math.exp(-((d / BAY_SIGMA_DEG) ** 2))


def height(x, z):
    """Altura do vale em (x, z). Fora da ilha: piso de floresta que sai do labio, encostas e crista."""
    sd = bi.island_sd(x, z)
    rho = max(abs(x), abs(z))
    theta = math.atan2(z, x)
    crest_rho = CREST_RHO[0] + (CREST_RHO[1] - CREST_RHO[0]) * (0.5 + 0.5 * bi.n3(math.cos(theta) * 1.3, 11.0, math.sin(theta) * 1.3))
    crest_h = CREST_HEIGHT[0] + (CREST_HEIGHT[1] - CREST_HEIGHT[0]) * (0.5 + 0.5 * bi.n3(math.cos(theta) * 1.7, 3.0, math.sin(theta) * 1.7))
    rho_e = rho - angular_bay(x, z)
    t = max(0.0, min(1.0, (rho_e - RISE_FROM) / (crest_rho - RISE_FROM)))
    rise = crest_h * t ** SLOPE_POWER
    amp = 0.5 + 6.0 * t
    ridge = 1.0 - abs(bi.n3(x * 0.045, 5.0, z * 0.045))
    detail = (bi.n3(x * 0.06, 1.0, z * 0.06) * amp + bi.n3(x * 0.17, 2.0, z * 0.17) * amp * 0.4
              + 7.0 * t * t * ridge)
    beyond = smooth(crest_rho, crest_rho + 16.0, rho_e) * crest_h * 0.55
    roll = 0.9 * bi.n3(x * 0.05, 9.0, z * 0.05) + 0.35 * bi.n3(x * 0.18, 4.0, z * 0.18)
    ground = LIP_Y + (roll + rise + detail - beyond - LIP_Y) * smooth(FLOOR_RAMP[0], FLOOR_RAMP[1], sd) \
        if sd < FLOOR_RAMP[1] else roll + rise + detail - beyond
    for path, pond in zip(STREAMS, PONDS):
        # Leito fundo ja logo depois do labio: a agua do vertedouro da poca cai nele (F96).
        along = smooth(0.0, 1.0, bi.island_sd(x, z) - bi.LIP)
        c = path_distance(x, z, path)
        carve = STREAM_DEPTH * (1.0 - smooth(STREAM_BED_HALF, STREAM_BED_HALF + STREAM_BANK, c)) * along
        pd = math.hypot(x - pond[0], z - pond[1])
        carve = max(carve, POND_DEPTH * (1.0 - smooth(POND_RADIUS, POND_RADIUS + POND_BANK, pd)))
        ground -= carve
    return ground


def grid_points():
    """Pontos internos: espacamento 2,5 u perto da ilha, ate 6 u no fundo; fora do buraco da ilha."""
    pts = []
    step = 2.5
    n = int(OUTER / step)
    for i in range(-n, n + 1):
        for j in range(-n, n + 1):
            x = i * step + 0.4 * step * bi.n3(i * 0.7, 3.0, j * 0.7)
            z = j * step + 0.4 * step * bi.n3(j * 0.7, 5.0, i * 0.7)
            if max(abs(x), abs(z)) > OUTER - 2.5 or bi.island_sd(x, z) < bi.LIP + 1.1:
                continue
            rho = max(abs(x), abs(z))
            spacing = 2.5 if rho < 62.0 else (3.4 if rho < 96.0 else 6.0)
            if hash01(x, z) > (step / spacing) ** 2:
                continue
            pts.append((x, z))
    return pts


def build_terrain():
    lip = bi.densify(bi.outline(bi.LIP), 1.5)
    outer = bi.densify([(-OUTER, -OUTER), (OUTER, -OUTER), (OUTER, OUTER), (-OUTER, OUTER)], 6.0)
    vecs = [Vector(p) for p in outer] + [Vector(p) for p in lip] + [Vector(p) for p in grid_points()]
    n_out, n_lip = len(outer), len(lip)
    coords, _e, faces, _ov, _oe, _of = delaunay_2d_cdt(
        vecs, [], [list(range(n_out)), list(range(n_out, n_out + n_lip))], 2, 1e-5)
    kit = bi.Kit("valley_terrain")
    for c in coords:
        # O labio fica exatamente na altura do labio da ilha (sem degrau na emenda; no vertedouro
        # da poca o labio desce com o canal).
        on_lip = bi.island_sd(c.x, c.y) < bi.LIP + 0.01
        kit.verts.append((c.x, bi.island_height(c.x, c.y) if on_lip else height(c.x, c.y), c.y))
    for f in faces:
        kit.faces.append(tuple(f))
        kit.cells.append((bi.GRASS, (0.5, 0.5)))
    return face_up(bi.build(kit))


def face_up(obj):
    """Folha aberta: o recalc do build() nao tem "fora" para escolher e deixa as faces viradas para
    baixo; vira as que olham para baixo (normal e luz do piso saem pelo lado de cima)."""
    import bmesh

    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for face in bm.faces:
        if face.normal.z < 0.0:
            face.normal_flip()
    bm.to_mesh(obj.data)
    bm.free()
    return obj


def surface_probe(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    tree = BVHTree.FromObject(obj, depsgraph)

    def probe(x, z):
        """Altura e normal.y da malha em (x, z) (a malha esta em coordenadas do Blender: (x, -z, y))."""
        hit, normal, _i, _d = tree.ray_cast(Vector((x, -z, 200.0)), Vector((0.0, 0.0, -1.0)))
        return (hit.z, normal.z) if hit is not None else (None, None)

    return probe


def build_stream(probe):
    """Fita de agua do riacho + disco da lagoa, no material do rio de mana (arcane_river.tres)."""
    kit = bi.Kit("valley_stream")
    pieces = []
    for path, pond in zip(STREAMS, PONDS):
        path = [q for q in path if bi.island_sd(q[0], q[1]) >= STREAM_FROM_SD]
        strip = []
        for k, (x, z) in enumerate(path):
            a, b = path[min(k + 1, len(path) - 1)], path[max(k - 1, 0)]
            tx, tz = a[0] - b[0], a[1] - b[1]
            length = math.hypot(tx, tz) or 1.0
            nx, nz = -tz / length, tx / length
            taper = 1.0 - 0.25 * k / (len(path) - 1)
            row = []
            for side in (-1.0, 1.0):
                px, pz = x + nx * STREAM_HALF * taper * side, z + nz * STREAM_HALF * taper * side
                y, _ny = probe(px, pz)
                row.append((px, (y if y is not None else height(px, pz)) + WATER_LIFT, pz))
            # A agua nao sobe mais que o leito do centro (margem alta enterra a ponta, nao a fita).
            strip.append(tuple(row))
        base = len(kit.verts)
        for left, right in strip:
            kit.verts.append(left)
            kit.verts.append(right)
        for k in range(len(strip) - 1):
            i = base + 2 * k
            kit.faces.append((i, i + 1, i + 3, i + 2))
            kit.cells.append((bi.STONE_BLUE, (0.5, 0.5)))
        pieces.append((base, len(strip), "strip"))
        y, _ny = probe(pond[0], pond[1])
        level = (y if y is not None else height(pond[0], pond[1])) + 0.55
        centre = len(kit.verts)
        kit.verts.append((pond[0], level, pond[1]))
        m = 28
        for k in range(m):
            a = 2 * math.pi * k / m
            kit.verts.append((pond[0] + math.cos(a) * POND_RADIUS, level, pond[1] + math.sin(a) * POND_RADIUS))
        for k in range(m):
            kit.faces.append((centre, centre + 1 + k, centre + 1 + (k + 1) % m))
            kit.cells.append((bi.STONE_BLUE, (0.5, 0.5)))
        pieces.append((centre, m, "disc"))
    obj = bi.build(kit)
    uv = obj.data.uv_layers.active
    vert_uv = {}
    for base, count, kind in pieces:
        if kind == "strip":
            for k in range(count):
                vert_uv[base + 2 * k] = (k / (count - 1), 0.0)
                vert_uv[base + 2 * k + 1] = (k / (count - 1), 1.0)
        else:
            vert_uv[base] = (0.5, 0.5)
            for k in range(count):
                a = 2 * math.pi * k / count
                vert_uv[base + 1 + k] = (0.5 + 0.5 * math.cos(a), 0.5 + 0.5 * math.sin(a))
    for poly in obj.data.polygons:
        for loop in poly.loop_indices:
            uv.data[loop].uv = vert_uv.get(obj.data.loops[loop].vertex_index, (0.0, 0.0))
        poly.use_smooth = True
    return face_up(obj)


def scatter_trees(probe):
    trees = []
    n = int(OUTER / TREE_STEP)
    for i in range(-n, n + 1):
        for j in range(-n, n + 1):
            x = i * TREE_STEP + TREE_STEP * 0.45 * bi.n3(i * 0.9, 7.0, j * 0.9)
            z = j * TREE_STEP + TREE_STEP * 0.45 * bi.n3(j * 0.9, 8.0, i * 0.9)
            rho = max(abs(x), abs(z))
            if rho > OUTER - 6.0 or bi.island_sd(x, z) < TREE_FROM_SD:
                continue
            if any(path_distance(x, z, p) < TREE_CLEAR_STREAM for p in STREAMS):
                continue
            if any(math.hypot(x - q[0], z - q[1]) < TREE_CLEAR_POND for q in PONDS):
                continue
            y, ny = probe(x, z)
            if y is None or ny < TREE_MAX_SLOPE_Y:
                continue
            clump = 0.5 + 0.5 * bi.n3(x * 0.08, 6.0, z * 0.08)
            keep = (1.0 - smooth(6.0, 30.0, y) * 0.7) * (0.55 + 0.6 * clump)
            if hash01(x + 3.1, z + 8.7) > keep:
                continue
            scale = TREE_SCALE[0] + (TREE_SCALE[1] - TREE_SCALE[0]) * hash01(x + 1.7, z + 5.3)
            scale *= TREE_NEAR_FACTOR + (1.0 - TREE_NEAR_FACTOR) * smooth(TREE_GROW_SD[0], TREE_GROW_SD[1], bi.island_sd(x, z))
            trees.append([round(x, 2), round(y - TREE_SINK, 2), round(z, 2), round(scale, 2)])
    return trees


def bank_piece(x, z, probe, out):
    """Pedra ou junco em (x, z), sorteado pelo hash da posicao (sem RNG: sai igual a cada rodada)."""
    roll = hash01(x + 4.4, z + 1.9)
    if roll < BANK_STONE_CHANCE:
        kind = 0
    elif roll > 1.0 - BANK_REED_CHANCE:
        kind = 1
    else:
        return
    y, _ny = probe(x, z)
    if y is None:
        return
    lo, hi = BANK_SCALE[kind]
    scale = lo + (hi - lo) * hash01(x + 2.2, z + 8.8)
    out.append([round(x, 2), round(y, 2), round(z, 2), round(scale, 2), kind])


def scatter_banks(probe):
    """Margem dos dois riachos: dos dois lados da fita (so onde ela existe, depois da queda) e em
    volta da lagoa."""
    banks = []
    for path, pond in zip(STREAMS, PONDS):
        path = [q for q in path if bi.island_sd(q[0], q[1]) >= STREAM_FROM_SD]
        for a, b in zip(path, path[1:]):
            tx, tz = b[0] - a[0], b[1] - a[1]
            length = math.hypot(tx, tz)
            nx, nz = -tz / length, tx / length
            for k in range(max(1, int(length / BANK_STEP))):
                cx, cz = a[0] + tx * k * BANK_STEP / length, a[1] + tz * k * BANK_STEP / length
                for side in (-1.0, 1.0):
                    off = STREAM_HALF + BANK_OFFSET[0] + (BANK_OFFSET[1] - BANK_OFFSET[0]) * hash01(cx * side, cz)
                    bank_piece(cx + nx * off * side, cz + nz * off * side, probe, banks)
        count = int(2 * math.pi * POND_RADIUS / BANK_STEP)
        for k in range(count):
            a = 2 * math.pi * k / count
            r = POND_RADIUS + BANK_OFFSET[0] + (BANK_OFFSET[1] - BANK_OFFSET[0]) * hash01(pond[0] + k, pond[1])
            bank_piece(pond[0] + math.cos(a) * r, pond[1] + math.sin(a) * r, probe, banks)
    return banks


def main():
    os.makedirs(bi.OUT, exist_ok=True)
    bi.reset_scene()
    terrain = build_terrain()
    probe = surface_probe(terrain)
    stream = build_stream(probe)
    trees = scatter_trees(probe)
    banks = scatter_banks(probe)
    with open(TREES_JSON, "w", encoding="utf-8", newline="\n") as f:
        json.dump({"trees": trees, "banks": banks}, f, separators=(",", ":"))
        f.write("\n")
    for obj, name in ((terrain, "valley_terrain"), (stream, "valley_stream")):
        bi.export(obj, name)
    bi.save("valley")
    bi.preview("valley", [terrain, stream], top=True)
    print("[valley] triangulos: " + ", ".join("%s %d" % (k, v) for k, v in bi.TRIS.items()))
    print("[valley] arvores: %d, margem: %d -> %s" % (len(trees), len(banks), TREES_JSON))


if __name__ == "__main__":
    main()
