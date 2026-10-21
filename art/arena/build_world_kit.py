"""Kit do meio do mapa no estilo Eternal Return (ADR-0030, F95): ponte de cantaria, rochas e cristais
do centro, afloramentos e pinheiros da selva, margem do rio, borda da cratera e mato alto.

Reaproveita os helpers do kit das bases (art/arena/build_castle_kit.py: Piece, Foliage, material,
export, preview): mesma direcao (proporcoes reais, bevel, PBR CC0 por UV planar em metros, cor de
vertice com sujeira), mesmas regras (ate 1.600 triangulos por objeto, .glb sem imagem: o import troca
cada material pelo .tres de shared/resources/materials/kit/). Nenhuma malha traz colisao: o builder
(tools/arena/build_arena.gd) cobre a colisao dele com estas pecas, nunca menores.

Geometria em coordenadas do Godot (x leste, y para cima, z sul).
Uso (na raiz do repo):
  blender --background --factory-startup --python art/arena/build_world_kit.py -- <repo> [grupo ...]
Saida: art/arena/kit_<grupo>.blend, art/arena/preview_kit_<grupo>.png e
shared/assets/rrb/arena/kit/*.glb (+ .glb.import, criado se faltar).
"""
import math
import os
import random
import re
import sys
import zlib

import bmesh
from mathutils import Euler, Matrix, Vector, noise

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_castle_kit as K  # noqa: E402

# Materiais novos: nome -> (pasta da textura em shared/assets/textures/kit, metros por repeticao, cor).
K.MATERIALS.update({
    "kit_cliff": ("cliff", 2.4, None),
    "kit_bark": ("bark", 1.2, None),
    # Folhagem escura dos pinheiros (mesmo atlas de folhas do kit das bases, outra tinta no .tres).
    "kit_pine": ("leaves", 1.0, None),
    # Lascas de cristal: o import troca pelo arcane_crystal (mesmo contrato do crystal_*.glb antigo).
    "rune_d826d8": (None, 1.0, (0.85, 0.15, 0.85)),
    # Laminas de capim (shared/shaders/tall_grass.gdshader): sem textura, a cor vem do shader.
    "kit_basalt": ("crater", 2.2, None),
    "kit_grass": (None, 1.0, (0.3, 0.5, 0.15)),
    "kit_reeds": (None, 1.0, (0.5, 0.55, 0.25)),
    # Cortina de agua da fonte de cura (shared/shaders/fountain_fall.gdshader).
    "fountain_fall": (None, 1.0, (0.7, 0.88, 0.95)),
})
K.GRIMY.update({"kit_cliff", "kit_basalt"})
K.LEAF_MATS.add("kit_pine")

# Material -> caminho do .tres que o import usa no lugar do material do .glb.
MATERIAL_PATHS = {
    "rune_d826d8": "res://shared/resources/materials/arcane_crystal_magenta.tres",
    # O mato alto usa o material compartilhado que o HeroVisual abre em volta do heroi (F72).
    "kit_grass": "res://shared/resources/materials/tall_grass.tres",
}
KIT_MATERIALS = "res://shared/resources/materials/kit/%s.tres"
# Pecas com folhagem: GI dinamico (sondas), fora do lightmap, como as plantas das casas do F94.
DYNAMIC = {"kit_pine", "kit_reeds", "kit_grass_4x3", "kit_grass_4x4", "kit_fountain_fall"}
Piece = K.Piece
rng = K._rng


# --- importacao no Godot -------------------------------------------------------------------------


def write_import(name, mats):
    """Cria <name>.glb.import (materiais externos) a partir do import da muralha, se faltar. O
    uid e o caminho do .scn o proprio Godot preenche na primeira importacao."""
    path = os.path.join(K.OUT, name + ".glb.import")
    if os.path.exists(path):
        return
    text = open(os.path.join(K.OUT, "kit_wall.glb.import"), encoding="utf-8").read()
    text = re.sub(r'^(uid|path|dest_files)=.*\n', "", text, flags=re.M)
    text = re.sub(r'source_file="[^"]*"', 'source_file="res://shared/assets/rrb/arena/kit/%s.glb"' % name, text)
    text = text.replace("meshes/light_baking=2", "meshes/light_baking=%d" % (3 if name in DYNAMIC else 2))
    extra = ""
    for mat in mats:
        target = MATERIAL_PATHS.get(mat, KIT_MATERIALS % mat)
        if '"%s": {' % mat in text:
            continue
        extra += ',\n"%s": {\n"use_external/enabled": true,\n"use_external/fallback_path": "%s",\n"use_external/path": "%s"\n}' % (mat, target, target)
    text = text.replace("\n}\n}\ngltf/", "%s\n}\n}\ngltf/" % extra, 1)
    open(path, "w", encoding="utf-8", newline="\n").write(text)


# --- primitivas novas ----------------------------------------------------------------------------


def blob(p, mat, center, radii, seed, subdiv=3, jitter=0.2, floor=None, tint=None):
    """Rocha: icosfera achatada e deslocada por ruido (casca irregular), com o fundo cortado em
    [param floor]. Varias juntas formam o bloco; a interseccao fica por conta do relevo."""
    r = random.Random(seed)
    off = Vector((r.uniform(-40, 40), r.uniform(-40, 40), r.uniform(-40, 40)))
    verts = bmesh.ops.create_icosphere(p.bm, subdivisions=subdiv, radius=1.0)["verts"]
    for v in verts:
        d = v.co.normalized()
        n = noise.noise(d * 1.5 + off) * 0.65 + noise.noise(d * 3.8 + off) * 0.35
        k = 1.0 + jitter * n
        y = center[1] + d.y * radii[1] * k
        if floor is not None:
            y = max(y, floor)
        v.co = Vector((center[0] + d.x * radii[0] * k, y, center[2] + d.z * radii[2] * k))
    return p._take(verts, mat, tint, False)


def cone_at(p, mat, base, turn, r1, r2, h, segs, tint=None):
    """Tronco de cone de [param base] ao longo do eixo +Y girado por [param turn] (Matrix 4x4)."""
    m = Matrix.Translation(Vector(base)) @ turn @ K.up_axis() @ Matrix.Translation((0.0, 0.0, h / 2.0))
    verts = bmesh.ops.create_cone(p.bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1,
                                  radius2=r2, depth=h, matrix=m)["verts"]
    return p._take(verts, mat, tint, False)


def tilt(x_deg, z_deg, yaw_deg=0.0):
    return Euler((math.radians(x_deg), math.radians(yaw_deg), math.radians(z_deg)), "XYZ").to_matrix().to_4x4()


# --- ponte de cantaria ---------------------------------------------------------------------------

# Vao da ponte (z, y): arco abatido de 4,6 u de corda, flecha 1,3 (como a ponte antiga, que a malha
# nova cobre: deck em y 0, 6,2 u de largura em x, 6 u de comprimento em z).
SPAN_HALF = 2.3
SPRING_Y = -1.6
CROWN_Y = -0.3
SPAN_R = (SPAN_HALF ** 2 + (CROWN_Y - SPRING_Y) ** 2) / (2.0 * (CROWN_Y - SPRING_Y))
SPAN_CY = CROWN_Y - SPAN_R


def arch_zy(radius, steps):
    """Pontos (z, y) do arco da ponte, de z -SPAN_HALF a +SPAN_HALF."""
    a0 = math.asin(SPAN_HALF / radius)
    return [(math.sin(-a0 + 2.0 * a0 * i / steps) * radius,
             SPAN_CY + math.cos(-a0 + 2.0 * a0 * i / steps) * radius) for i in range(steps + 1)]


def build_bridge():
    """Ponte de cantaria (origem no centro do vao, topo do piso em y 0, como a bridge_stone): corpo
    de silhar com o arco abatido, aduelas com fecho nas duas faces, piso de pedra, parapeitos de
    blocos com capeamento e pilares nos cantos. Cobre a largura util de 5 u (SPEC-046 §2.1)."""
    body = Piece("kit_bridge_body", bevel=0.05, segments=1)
    arch = [(z, y) for z, y in arch_zy(SPAN_R, 14)]
    outline = [(-3.0, -0.1), (-3.0, SPRING_Y)] + arch + [(3.0, SPRING_Y), (3.0, -0.1)]
    body.prism("kit_stone", outline, "x", -3.1, 3.1)
    body.box("kit_cobble", (0.0, -0.05, 0.0), (5.2, 0.1, 6.0), bevel=False, tint=1.0)
    ring = Piece("kit_bridge_ring", bevel=0.04)
    count = 11
    extra = 0.42
    a0 = math.asin(SPAN_HALF / SPAN_R)
    for sx in (-1.0, 1.0):
        for i in range(count):
            a = -a0 + 2.0 * a0 * (i + 0.5) / count
            r_mid = SPAN_R + extra / 2.0
            chord = 2.0 * r_mid * math.sin(a0 / count) * 0.94
            key = i == count // 2
            at = (sx * 3.07, SPAN_CY + math.cos(a) * r_mid, math.sin(a) * r_mid)
            size = (0.34, extra + (0.1 if key else 0.0), chord * (1.2 if key else 1.0))
            ring.box("kit_stone", at, size, rot=(math.degrees(a), 0.0, 0.0), tint=1.05 if key else None)
    # Parapeito e pilares so sobre a agua (|z| <= 1,8; o rio vai de z -2 a 2): ali a colisao do rio ja
    # segura o heroi. Nas pontas em terra fica so o piso, livre para virar a direita ou a esquerda
    # entre a ponte e as torres do portao (PI 2026-10-21: o heroi atravessava o pilar da ponta).
    wall = Piece("kit_bridge_parapet", bevel=0.035)
    for sx in (-1.0, 1.0):
        x = sx * 2.85
        for k in range(4):
            wall.box("kit_stone", (x, 0.225, -1.2 + k * 0.8), (0.5, 0.65, 0.76))
        wall.box("kit_stone", (x, 0.64, 0.0), (0.64, 0.16, 3.4), bevel=True, tint=1.06)
        for z in (-1.45, 1.45):
            wall.box("kit_stone", (x, 0.5, z), (0.74, 1.2, 0.7), tint=1.02)
            wall.box("kit_stone", (x, 1.14, z), (0.84, 0.14, 0.8), tint=1.08)
    return [body.build(), ring.build(), wall.build()]


# --- rochas e cristais ---------------------------------------------------------------------------


def build_boulder():
    """Rocha do centro e do patio (colisao: cilindro de 1,3 de raio e 2,5 de altura): bloco de
    rocha musgosa em 3 massas com topo chato e chanfrado, que cobre o cilindro."""
    p = Piece("kit_boulder", bevel=0.05, segments=1, smooth=48.0)
    blob(p, "kit_cliff", (0.0, 0.7, 0.0), (1.78, 1.3, 1.7), 11, jitter=0.16, floor=-0.25)
    blob(p, "kit_cliff", (0.35, 1.45, -0.2), (1.45, 1.1, 1.42), 12, jitter=0.18)
    blob(p, "kit_cliff", (-0.95, 0.5, 0.95), (0.85, 0.7, 0.8), 13, subdiv=2, jitter=0.2, floor=-0.25)
    p.cyl("kit_cliff", (0.15, 1.75, -0.1), 1.44, 1.32, 0.82, 7, yaw=14.0, bevel=True, tint=1.06)
    p.cyl("kit_cliff", (0.0, -0.25, 0.0), 1.68, 1.62, 1.3, 9, yaw=8.0, bevel=False, tint=0.88)
    return [p.build()]


def crystal_shards(name, shards, base_rock=True):
    """Cristal arcano: lascas hexagonais de ponta (material rune, que o import troca pelo
    arcane_crystal) saindo de um tufo de pedra. shards: (altura, raio, giro x, giro z, dx, dz)."""
    p = Piece(name, bevel=0.0, smooth=60.0)
    if base_rock:
        blob(p, "kit_cliff", (0.0, 0.0, 0.0), (0.95, 0.42, 0.9), zlib.crc32(name.encode()) % 97, subdiv=2, jitter=0.25, floor=-0.1)
    for h, r, tx, tz, dx, dz in shards:
        turn = tilt(tx, tz)
        body_h = h * 0.72
        cone_at(p, "rune_d826d8", (dx, 0.0, dz), turn, r, r * 0.9, body_h, 6)
        tip = Vector((dx, 0.0, dz)) + (turn @ Vector((0.0, body_h, 0.0)))
        cone_at(p, "rune_d826d8", tip, turn, r * 0.9, 0.0, h * 0.28, 6)
    return [p.build()]


def build_crystal_small():
    return crystal_shards("kit_crystal_small", [(1.05, 0.15, 6, -8, 0.0, 0.0), (0.7, 0.11, -14, 12, 0.32, 0.18),
                                                (0.55, 0.09, 18, 6, -0.3, 0.22)])


def build_crystal_large():
    return crystal_shards("kit_crystal_large", [(1.9, 0.24, 4, -6, 0.0, 0.0), (1.3, 0.17, -12, 10, 0.55, 0.3),
                                                (1.0, 0.14, 16, 8, -0.5, 0.4), (0.8, 0.12, -6, -16, 0.2, -0.55)])


def build_outcrop(name, seed, stretch):
    """Afloramento da selva, facetado: pegada de raio >= 1,05 ate y 0,4 e topo acima de 1,35 em
    escala 1 (o builder estica por bolsao e a colisao do bolsao fica sempre coberta,
    test_arena_jungle)."""
    p = Piece(name, bevel=0.04, segments=1, smooth=26.0)
    blob(p, "kit_cliff", (0.0, 0.55, 0.0), (1.3 * stretch, 1.0, 1.3 / stretch), seed, subdiv=2, jitter=0.3, floor=-0.3)
    blob(p, "kit_cliff", (0.15, 1.1, -0.1), (0.85 * stretch, 0.75, 0.85 / stretch), seed + 5, subdiv=2, jitter=0.32)
    p.cyl("kit_cliff", (0.0, -0.3, 0.0), 1.16, 1.08, 0.78, 9, yaw=seed * 7.0, bevel=False, tint=0.86)
    return [p.build()]


# --- selva: pinheiro de cartoes ---------------------------------------------------------------

# Saias do pinheiro (altura, raio): de baixo para cima; copa de cartoes de folha escuros e tronco de casca.
PINE_TIERS = ((1.1, 1.5), (1.7, 1.32), (2.3, 1.12), (2.9, 0.92), (3.4, 0.72), (3.85, 0.5), (4.25, 0.3))


def build_pine():
    """Pinheiro da selva (~4,6 u como o pine_dark): tronco de casca e 7 saias de cartoes de folha
    escuros com balanco de vento. Pegada de 1,5 u de raio."""
    trunk = Piece("kit_pine_trunk", bevel=0.0, smooth=50.0)
    trunk.cyl("kit_bark", (0.0, 0.0, 0.0), 0.34, 0.2, 0.5, 8)
    trunk.cyl("kit_bark", (0.0, 0.45, 0.0), 0.2, 0.09, 3.9, 8)
    crown = K.Foliage("kit_pine_crown")
    for k, (y, r) in enumerate(PINE_TIERS):
        crown.clump((0.0, y, 0.0), (r, 0.32, r), int(40 + r * 55), 0.46 - 0.025 * k, 300 + k, mat="kit_pine", up_bias=0.25)
    return [trunk.build(), crown.build()]


def build_bank_stones():
    """Pedras soltas da margem do rio e da lagoa: 6 pedras de tamanhos diferentes em ~1,3 u, para
    o builder espalhar com giro e escala (cobrem a quina dura entre a agua e o chao)."""
    p = Piece("kit_bank_stones", bevel=0.02, segments=1, smooth=40.0)
    for i, (x, z, r, sy) in enumerate(((0.0, 0.0, 0.34, 0.7), (0.5, 0.28, 0.22, 0.8), (-0.42, 0.3, 0.2, 0.6),
                                       (0.18, -0.46, 0.26, 0.7), (-0.35, -0.3, 0.15, 0.9), (0.75, -0.2, 0.13, 0.7))):
        blob(p, "kit_cliff", (x, r * sy * 0.6, z), (r * 1.15, r * sy, r), 90 + i, subdiv=2, jitter=0.3, floor=-0.05)
    return [p.build()]


# --- capim: lamina por cartao --------------------------------------------------------------------


class Blades(K.Foliage):
    """Laminas de capim: cada uma e um cartao em pe de 2 segmentos (curva para fora), com UV
    (u de lado a lado, v da raiz a ponta) para o shader tall_grass.gdshader. Cor de vertice: rgb =
    tom da touceira, alpha = peso do balanco (v ao quadrado). Normais para cima (luz macia)."""

    def blade(self, mat, base, yaw, height, width, lean, tone, rows=(0.0, 0.55, 1.0)):
        if mat not in self.mats:
            self.mats.append(mat)
        direction = Vector((math.cos(yaw), 0.0, math.sin(yaw)))
        side = Vector((-direction.z, 0.0, direction.x))
        start = len(self.verts)
        for v in rows:
            centre = Vector(base) + direction * (lean * v ** 1.7) + Vector((0.0, height * v - lean * v * v * 0.12, 0.0))
            for k, sgn in enumerate((-1.0, 1.0)):
                self.verts.append(centre + side * (sgn * width * 0.5))
                self.uvs.append((float(k), v))
                self.normals.append((Vector((0.0, 1.0, 0.0)) + direction * 0.3).normalized())
                self.cols.append((tone[0], tone[1], tone[2], v * v))
        for row in range(len(rows) - 1):
            a = start + row * 2
            self.faces.append((a, a + 1, a + 3, a + 2))
            self.face_mats.append(self.mats.index(mat))

    def tuft(self, mat, at, rng, height, width, count=3, spread=0.5, rows=(0.0, 0.55, 1.0), bounds=None):
        """Touceira de [param count] laminas abertas em leque. Com [param bounds] (meia caixa x, z), a
        lamina que pendesse para fora da caixa pende para dentro (o capim nao cobre o que esta ao lado)."""
        tone = rng.uniform(0.8, 1.15)
        hue = (tone * rng.uniform(0.92, 1.05), tone, tone * rng.uniform(0.85, 1.0))
        face = rng.uniform(0.0, math.tau)
        for i in range(count):
            yaw = face + (i - (count - 1) / 2.0) * spread + rng.uniform(-0.15, 0.15)
            base = (at[0] + rng.uniform(-0.04, 0.04), 0.0, at[1] + rng.uniform(-0.04, 0.04))
            h = height * rng.uniform(0.75, 1.15)
            lean = height * rng.uniform(0.18, 0.4)
            if bounds is not None:
                tip_x = base[0] + math.cos(yaw) * lean
                tip_z = base[2] + math.sin(yaw) * lean
                if abs(tip_x) > bounds[0] or abs(tip_z) > bounds[1]:
                    yaw += math.pi
            self.blade(mat, base, yaw, h, width * rng.uniform(0.85, 1.15), lean, hue, rows)


def build_tall_grass(name, size, seed):
    """Moita 'dá para se esconder aqui': touceiras de laminas cobrindo a caixa de colisao [param
    size] (x, z) de ponta a ponta, ~1,2 u de altura como a malha antiga (SPEC-007, SPEC-072)."""
    f = Blades(name)
    r = random.Random(seed)
    step = 0.33
    half = (size[0] / 2.0 + 0.06, size[1] / 2.0 + 0.06)
    nx, nz = int(2 * half[0] / step), int(2 * half[1] / step)
    for i in range(nx + 1):
        for j in range(nz + 1):
            x = -half[0] + i * (2 * half[0] / nx) + r.uniform(-0.1, 0.1)
            z = -half[1] + j * (2 * half[1] / nz) + r.uniform(-0.1, 0.1)
            x = max(-half[0], min(half[0], x))
            z = max(-half[1], min(half[1], z))
            edge = min(half[0] - abs(x), half[1] - abs(z))
            h = 1.1 * (0.6 + 0.4 * min(edge / 0.4, 1.0)) * r.uniform(0.85, 1.12)
            f.tuft("kit_grass", (x, z), r, h, 0.22, count=3, spread=0.55, rows=(0.0, 1.0), bounds=half)
    return [f.build()]


def build_reeds():
    """Junco da margem do rio: touceira de 14 laminas altas e finas, amareladas."""
    f = Blades("kit_reeds")
    r = random.Random(7)
    for k in range(5):
        a = r.uniform(0.0, math.tau)
        d = r.uniform(0.0, 0.32)
        f.tuft("kit_reeds", (math.cos(a) * d, math.sin(a) * d), r, r.uniform(1.0, 1.6), 0.1, count=3, spread=0.7)
    return [f.build()]


# --- cratera: borda do lago de magma -------------------------------------------------------------

CRATER_RING = 6.55  # raio do lago (CRATER_RADIUS 6,0 + 0,4 do disco de magma, build_island.py) + folga


def build_crater_rim(half):
    """Borda do lago de magma: colunas de basalto hexagonais em duas fileiras (a de dentro mais alta),
    levemente inclinadas, de topo irregular. [param half] 0 ou 1 (cada metade do anel, para ficar
    abaixo de 1.600 triangulos por objeto). Mais baixa que o heroi: so visual, a cratera nao tem
    colisao (ADR-0014)."""
    p = Piece("kit_crater_rim_%s" % "ab"[half], bevel=0.025, segments=1, smooth=60.0)
    r = random.Random(60 + half)
    for row, (radius, count, h_lo, h_hi) in enumerate(((CRATER_RING, 30, 0.25, 0.95), (CRATER_RING + 0.8, 36, 0.12, 0.5))):
        for i in range(count):
            if r.random() < 0.12:
                continue  # falha na fileira: a borda nao e uma palicada
            a = math.tau * (half * count + i + r.uniform(-0.4, 0.4)) / (2 * count)
            d = radius + r.uniform(-0.3, 0.35)
            width = r.uniform(0.22, 0.55)
            h = r.uniform(h_lo, h_hi)
            turn = tilt(r.uniform(-16, 16), r.uniform(-16, 16), r.uniform(0, 60))
            cone_at(p, "kit_basalt", (math.cos(a) * d, -0.3, math.sin(a) * d), turn, width, width * r.uniform(0.7, 0.95),
                    h + 0.3, 6, tint=r.uniform(0.8, 1.05))
    return [p.build()]


# --- fonte de cura: agua caindo -----------------------------------------------------------------

# Perfil (raio, altura) da cortina, da borda da taca (kit_fountain: r 0,46 em y 1,18) ate a agua da
# bacia (y 0,58), abrindo para fora como agua que transborda.
FALL_PROFILE = ((0.465, 1.175), (0.5, 1.1), (0.545, 0.96), (0.585, 0.8), (0.615, 0.6))
FALL_SEGMENTS = 24


def build_fountain_fall():
    """Cortina de agua que transborda da taca para a bacia: anel aberto com UV u em volta e v da
    borda (0) a bacia (1); o shader faz os fios de agua descerem. Folha dupla face, sem colisao."""
    import bpy
    verts, faces, uvs = [], [], []
    rows = len(FALL_PROFILE)
    for k, (radius, y) in enumerate(FALL_PROFILE):
        for i in range(FALL_SEGMENTS + 1):  # costura com u = 1 duplicado
            a = math.tau * i / FALL_SEGMENTS
            verts.append(Vector((math.cos(a) * radius, -math.sin(a) * radius, y)))  # Godot -> Blender
            uvs.append((i / FALL_SEGMENTS, 1.0 - k / (rows - 1)))  # glTF vira o v: no Godot UV.y 0 = topo
    stride = FALL_SEGMENTS + 1
    for k in range(rows - 1):
        for i in range(FALL_SEGMENTS):
            a = k * stride + i
            faces.append((a, a + 1, a + 1 + stride, a + stride))
    mesh = bpy.data.meshes.new("kit_fountain_fall")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(K.material("fountain_fall"))
    layer = mesh.uv_layers.new(name="UVMap")
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            layer.data[li].uv = uvs[mesh.loops[li].vertex_index]
    mesh.shade_smooth()
    mesh.update()
    obj = bpy.data.objects.new("kit_fountain_fall", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mesh.calc_loop_triangles()
    K.TRIS[obj.name] = len(mesh.loop_triangles)
    return [obj]


GROUPS = {
    "bridge": lambda: {"kit_bridge": build_bridge()},
    "boulder": lambda: {"kit_boulder": build_boulder(), "kit_crystal_small": build_crystal_small(),
                        "kit_crystal_large": build_crystal_large()},
    "pine": lambda: {"kit_pine": build_pine()},
    "bank": lambda: {"kit_bank_stones": build_bank_stones(), "kit_reeds": build_reeds()},
    "grass": lambda: {"kit_grass_4x4": build_tall_grass("kit_grass_4x4", (4.0, 4.0), 41),
                      "kit_grass_4x3": build_tall_grass("kit_grass_4x3", (4.0, 3.0), 43)},
    "crater": lambda: {"kit_crater_rim_a": build_crater_rim(0), "kit_crater_rim_b": build_crater_rim(1)},
    "fountain": lambda: {"kit_fountain_fall": build_fountain_fall()},
    "outcrops": lambda: {"kit_outcrop_a": build_outcrop("kit_outcrop_a", 21, 1.12),
                         "kit_outcrop_b": build_outcrop("kit_outcrop_b", 34, 0.92),
                         "kit_outcrop_c": build_outcrop("kit_outcrop_c", 47, 1.0)},
}


def main():
    for group, make in GROUPS.items():
        if K.ONLY and group not in K.ONLY:
            continue
        K.reset_scene()
        pieces = make()
        everything = []
        for name, objects in pieces.items():
            K.export(objects, name)
            write_import(name, sorted({m.name for o in objects for m in o.data.materials}))
            everything.extend(objects)
        K.save("world_" + group)
        x = 0.0
        for objects in pieces.values():
            for o in objects:
                o.location.x += x
            x += 9.0
        K.preview("world_" + group, everything)
        for name in sorted(o.name for o in everything):
            print("  %-28s %6d" % (name, K.TRIS[name]))


if __name__ == "__main__":
    main()
