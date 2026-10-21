"""Kit da borda da ilha e do vale no estilo Eternal Return (ADR-0030, F96): tocha, cavalo-de-frisa,
torre de vigia e balista da moldura (F40), cantaria e cortina de agua da poca dos bastioes NO/SE
(F56) e o pinheiro leve da floresta do vale.

Reaproveita os helpers dos kits das bases e do meio do mapa (build_castle_kit.py: Piece, Foliage,
material, export, preview; build_world_kit.py: blob, cone_at, tilt, write_import): mesma direcao e
mesmas regras (ate 1.600 triangulos por objeto, .glb sem imagem, import troca cada material pelo
.tres de shared/resources/materials/kit/). Os cristais e o pinheiro da floresta da borda sao os do
kit do meio do mapa (kit_crystal_*, kit_pine). Nenhuma malha traz colisao: a borda e o vale ficam
fora da area jogavel.

Geometria em coordenadas do Godot (x leste, y para cima, z sul). A cantaria e a cortina da poca
saem nas coordenadas do mundo do canto NO; o builder gira 180 graus para o SE.
Uso (na raiz do repo):
  blender --background --factory-startup --python art/arena/build_rim_kit.py -- <repo> [grupo ...]
Saida: art/arena/kit_rim_<grupo>.blend, art/arena/preview_kit_rim_<grupo>.png e
shared/assets/rrb/arena/kit/*.glb (+ .glb.import, criado se faltar).
"""
import math
import os
import random
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_castle_kit as K  # noqa: E402
import build_world_kit as W  # noqa: E402
import build_island as bi  # noqa: E402
import build_valley as bv  # noqa: E402

# Copa do pinheiro do vale: folhas escuras, preenchimento de ambiente (fora do bake), sem lightmap.
K.MATERIALS["kit_pine_far"] = ("leaves", 1.0, None)
K.LEAF_MATS.add("kit_pine_far")
W.DYNAMIC.update({"kit_pine_far", "kit_falls_sheet"})
Piece = K.Piece


# --- tocha da borda ------------------------------------------------------------------------------

# Cesto da tocha no espaco do prop (o builder poe a luz aqui, com o braco virado para a arena).
TORCH_BASKET = (0.5, 2.3, 0.0)


def build_torch():
    """Tocha da borda (substitui torch_post; origem no chao, braco em +x): pe de pedras, poste de
    tronco com cintas de ferro, braco com mao-francesa, cesto de ferro e chama."""
    p = Piece("kit_torch", bevel=0.02, smooth=50.0)
    for k, (dx, dz, s) in enumerate(((0.0, 0.0, 0.46), (0.12, -0.1, 0.3), (-0.14, 0.09, 0.28))):
        p.box("kit_rubble", (dx, s * 0.32, dz), (s, s * 0.64, s * 0.9), rot=(0.0, 23.0 * k, 0.0))
    p.cyl("kit_bark", (0.0, 0.0, 0.0), 0.12, 0.085, 2.5, 8, tint=0.9)
    for y in (0.85, 1.95):
        p.cyl("kit_metal", (0.0, y, 0.0), 0.11, 0.11, 0.06, 8)
    bx, by, bz = TORCH_BASKET
    p.box("kit_metal", (bx / 2.0, by - 0.12, 0.0), (bx + 0.06, 0.05, 0.05), bevel=False)
    p.box("kit_metal", (0.2, by - 0.32, 0.0), (0.42, 0.04, 0.04), rot=(0.0, 0.0, 35.0), bevel=False)
    p.cyl("kit_metal", (bx, by - 0.2, bz), 0.07, 0.17, 0.24, 6, bevel=False)
    p.cyl("kit_metal", (bx, by + 0.02, bz), 0.18, 0.18, 0.03, 6)
    p.cyl("kit_glow", (bx, by - 0.02, bz), 0.13, 0.0, 0.36, 6, tint=1.0)
    p.cyl("kit_glow", (bx + 0.04, by - 0.02, bz - 0.03), 0.08, 0.0, 0.5, 5, yaw=30.0, tint=1.0)
    return [p.build()]


# --- cavalo-de-frisa -----------------------------------------------------------------------------


def build_barricade():
    """Cavalo-de-frisa (substitui barricade; ~2,6 u em x, origem no chao): tronco deitado, 6 pares
    de estacas de tronco afiadas cruzadas em X e amarras de corda."""
    p = Piece("kit_barricade", bevel=0.0, smooth=50.0)
    beam_y = 0.72
    p.cyl("kit_bark", (-1.35, beam_y, 0.0), 0.13, 0.12, 2.7, 8, axis="x")
    for i in range(6):
        x = -1.0 + 0.4 * i
        for lean in (34.0, -34.0):
            turn = W.tilt(lean + (i % 2) * 3.0, 0.0)
            foot = Vector((x, beam_y, 0.0)) + turn @ Vector((0.0, -0.95, 0.0))
            W.cone_at(p, "kit_bark", foot, turn, 0.06, 0.055, 1.55, 6, tint=0.85 + 0.05 * (i % 3))
            tip = foot + turn @ Vector((0.0, 1.55, 0.0))
            W.cone_at(p, "kit_planks", tip, turn, 0.055, 0.0, 0.3, 6, tint=1.15)
        p.cyl("kit_hay", (x - 0.05, beam_y, 0.0), 0.15, 0.15, 0.1, 8, axis="x", tint=0.8)
    return [p.build()]


# --- torre de vigia ------------------------------------------------------------------------------

TOWER_HALF = 1.0
DECK_Y = 3.0
ROOF_Y = 4.75


def build_watchtower():
    """Torre de vigia de madeira (substitui watchtower; pegada ~2,2 u, origem no chao): 4 pernas
    de tronco levemente inclinadas, contraventos em X, plataforma de tabuas sobre vigas, guarda-corpo,
    escada na face +x e telhado de quatro aguas de telha."""
    legs = Piece("kit_watchtower_frame", bevel=0.0, smooth=50.0)
    for sx in (-1.0, 1.0):
        for sz in (-1.0, 1.0):
            foot = Vector((sx * (TOWER_HALF + 0.15), 0.0, sz * (TOWER_HALF + 0.15)))
            top = Vector((sx * TOWER_HALF, ROOF_Y, sz * TOWER_HALF))
            lean_x = math.degrees(math.atan2(top.x - foot.x, ROOF_Y))
            lean_z = math.degrees(math.atan2(top.z - foot.z, ROOF_Y))
            W.cone_at(legs, "kit_bark", foot, W.tilt(lean_z, -lean_x), 0.13, 0.1, (top - foot).length, 8)
            legs.box("kit_rubble", (foot.x, 0.1, foot.z), (0.4, 0.2, 0.4), tint=0.85)
    # Contraventos em X nas 4 faces (entre y 0,5 e 2,7), em tabua grossa.
    span = 2.0 * (TOWER_HALF + 0.08)
    for yaw in (0.0, 90.0, 180.0, 270.0):
        turn = K.Matrix.Rotation(math.radians(yaw), 4, "Y")
        for sign in (1.0, -1.0):
            at = turn @ Vector((0.0, 1.6, TOWER_HALF + 0.1))
            ang = math.degrees(math.atan2(2.2, span)) * sign
            legs.box("kit_planks", at, (math.hypot(span, 2.2), 0.14, 0.07), rot=(0.0, yaw, ang), tint=0.55)
        legs.box("kit_planks", turn @ Vector((0.0, 0.5, TOWER_HALF + 0.12)), (span + 0.2, 0.14, 0.08), rot=(0.0, yaw, 0.0), tint=0.5)
    deck = Piece("kit_watchtower_deck", bevel=0.015)
    for sx in (-1.0, 1.0):
        deck.box("kit_planks", (sx * (TOWER_HALF - 0.05), DECK_Y - 0.14, 0.0), (0.16, 0.18, 2.5), tint=0.5)
    for k in range(7):
        z = -1.2 + 0.4 * k
        deck.box("kit_planks", (0.0, DECK_Y, z), (2.5, 0.08, 0.37), tint=0.8 + 0.04 * (k % 3))
    # Guarda-corpo em 3 lados; a face +x fica aberta para a escada.
    for yaw in (0.0, 180.0, 270.0):
        turn = K.Matrix.Rotation(math.radians(yaw), 4, "Y")
        for y in (DECK_Y + 0.5, DECK_Y + 0.95):
            deck.box("kit_planks", turn @ Vector((0.0, y, TOWER_HALF + 0.02)), (2.1, 0.08, 0.08), rot=(0.0, yaw, 0.0), tint=0.6)
        for t in (-0.35, 0.35):
            deck.box("kit_planks", turn @ Vector((t, DECK_Y + 0.5, TOWER_HALF + 0.02)), (0.07, 0.95, 0.07), rot=(0.0, yaw, 0.0), tint=0.6)
    for sz in (-1.0, 1.0):
        deck.box("kit_planks", (TOWER_HALF + 0.55, DECK_Y / 2.0, sz * 0.3), (0.08, DECK_Y + 0.3, 0.08), rot=(0.0, 0.0, 10.0), tint=0.55)
    for k in range(8):
        y = 0.35 + k * 0.38
        deck.box("kit_planks", (TOWER_HALF + 0.82 - y * 0.176, y, 0.0), (0.06, 0.06, 0.66), bevel=False, tint=0.7)
    roof = Piece("kit_watchtower_roof", bevel=0.0)
    roof.cyl("kit_roof", (0.0, ROOF_Y, 0.0), 1.95, 0.0, 1.25, 4, yaw=45.0)
    roof.cyl("kit_planks", (0.0, ROOF_Y - 0.12, 0.0), 1.55, 1.55, 0.14, 4, yaw=45.0, tint=0.45)
    roof.cyl("kit_metal", (0.0, ROOF_Y + 1.15, 0.0), 0.05, 0.02, 0.5, 6)
    return [legs.build(), deck.build(), roof.build()]


# --- balista -------------------------------------------------------------------------------------


def build_ballista():
    """Balista de cerco (substitui ballista; frente em -z, origem no chao): cruzeta de vigas com
    escoras, pino de giro, coronha inclinada, bracos do arco com feixes de corda, corda, virote
    com ponta de ferro e sarilho atras."""
    p = Piece("kit_ballista", bevel=0.02, smooth=45.0)
    for yaw in (0.0, 90.0):
        p.box("kit_planks", (0.0, 0.12, 0.0), (2.0, 0.22, 0.24), rot=(0.0, yaw, 0.0), tint=0.55)
    for yaw in (45.0, 135.0, 225.0, 315.0):
        turn = K.Matrix.Rotation(math.radians(yaw), 4, "Y")
        p.box("kit_planks", turn @ Vector((0.0, 0.45, 0.42)), (0.12, 0.12, 0.85), rot=(42.0, yaw, 0.0), tint=0.5)
    p.cyl("kit_planks", (0.0, 0.2, 0.0), 0.16, 0.14, 0.75, 8, tint=0.5)
    p.cyl("kit_metal", (0.0, 0.88, 0.0), 0.2, 0.2, 0.08, 8)
    stock = 10.0  # inclinacao da coronha (graus, ponta para cima)
    lift = K.Matrix.Rotation(math.radians(stock), 4, "X")
    base = Vector((0.0, 1.05, 0.0))

    def on_stock(local):
        return base + lift @ Vector(local)

    p.box("kit_planks", on_stock((0.0, 0.0, 0.1)), (0.26, 0.2, 2.3), rot=(stock, 0.0, 0.0), tint=0.7)
    p.box("kit_planks", on_stock((0.0, 0.12, 0.0)), (0.08, 0.04, 2.1), rot=(stock, 0.0, 0.0), bevel=False, tint=0.45)
    # Feixes de corda torcida (o motor da balista) dos dois lados da frente.
    for sx in (-1.0, 1.0):
        p.cyl("kit_hay", on_stock((sx * 0.24, -0.25, -0.85)), 0.11, 0.11, 0.55, 8, tint=0.75)
        p.box("kit_planks", on_stock((sx * 0.24, 0.02, -0.85)), (0.2, 0.62, 0.2), rot=(stock, 0.0, 0.0), tint=0.5)
        # Braco do arco: sai do feixe para fora e para tras.
        arm_root = on_stock((sx * 0.3, 0.05, -0.85))
        arm_tip = on_stock((sx * 1.15, 0.05, -0.45))
        mid = (arm_root + arm_tip) / 2.0
        ang = math.degrees(math.atan2(arm_tip.z - arm_root.z, arm_tip.x - arm_root.x))
        p.box("kit_planks", mid, ((arm_tip - arm_root).length, 0.13, 0.11), rot=(0.0, -ang, 0.0), tint=0.65)
        p.box("kit_metal", arm_tip, (0.06, 0.16, 0.14), rot=(0.0, -ang, 0.0), bevel=False)
        # Corda do arco ate a garra atras do virote.
        claw = on_stock((0.0, 0.14, 0.35))
        cmid = (arm_tip + claw) / 2.0
        cang = math.degrees(math.atan2(claw.z - arm_tip.z, claw.x - arm_tip.x))
        p.box("kit_metal", cmid, ((claw - arm_tip).length, 0.025, 0.025), rot=(0.0, -cang, 0.0), bevel=False, tint=0.6)
    back = lift @ K.Matrix.Rotation(math.radians(90.0), 4, "X")  # +y do cone -> +z (para tras)
    front = lift @ K.Matrix.Rotation(math.radians(-90.0), 4, "X")  # +y do cone -> -z (para a frente)
    W.cone_at(p, "kit_planks", on_stock((0.0, 0.17, -0.85)), back, 0.035, 0.035, 1.6, 6, tint=0.85)
    W.cone_at(p, "kit_metal", on_stock((0.0, 0.17, -0.85)), front, 0.06, 0.0, 0.24, 6)
    p.cyl("kit_planks", on_stock((-0.3, 0.0, 1.05)), 0.09, 0.09, 0.6, 8, axis="x", tint=0.55)
    for sx in (-1.0, 1.0):
        p.box("kit_metal", on_stock((sx * 0.33, -0.12, 1.05)), (0.03, 0.3, 0.04), bevel=False)
    return [p.build()]


# --- poca dos bastioes NO/SE ---------------------------------------------------------------------

POOL = Vector((bi.FALLS_A[0], 0.0, bi.FALLS_A[1]))
# Vertedouro (build_island.py): canal pela diagonal, da poca para o canto da ilha.
SPILL = Vector((-1.0, 0.0, -1.0)).normalized()
SIDE = Vector((-SPILL.z, 0.0, SPILL.x))
SPILL_GAP_DEG = 24.0
CURB_RADIUS = 2.2
CURB_TOP = 0.1
CURB_BOTTOM = -1.1


def build_falls_curb():
    """Cantaria da poca do canto NO (coordenadas do mundo): anel de blocos de pedra sobre a margem,
    aberto no vertedouro; o canal entre duas fiadas de blocos ate o labio; rochas musgosas dos
    dois lados da queda (escondem a emenda entre o chassi e o vale)."""
    p = Piece("kit_falls_curb", bevel=0.04, segments=1, smooth=40.0)
    spill_a = math.atan2(SPILL.z, SPILL.x)
    gap = math.radians(SPILL_GAP_DEG)
    r = random.Random(96)
    count = 20
    for i in range(count):
        a = spill_a + gap + (i + 0.5) * (2.0 * math.pi - 2.0 * gap) / count
        at = POOL + Vector((math.cos(a), 0.0, math.sin(a))) * (CURB_RADIUS + r.uniform(-0.04, 0.04))
        top = CURB_TOP + r.uniform(-0.05, 0.05)
        p.box("kit_stone", (at.x, (top + CURB_BOTTOM) / 2.0, at.z), (0.66, top - CURB_BOTTOM, 0.46),
              rot=(0.0, -math.degrees(a) - 90.0, 0.0))
    yaw = -math.degrees(spill_a) - 90.0
    for sgn in (-1.0, 1.0):
        for k, d in enumerate((2.75, 3.4)):
            at = POOL + SPILL * d + SIDE * (sgn * (bi.SPILL_HALF + 0.3))
            top = CURB_TOP - 0.18 * k + r.uniform(-0.04, 0.04)
            p.box("kit_stone", (at.x, (top + CURB_BOTTOM) / 2.0, at.z), (0.42, top - CURB_BOTTOM, 0.66),
                  rot=(0.0, yaw, 0.0))
        at = POOL + SPILL * 4.15 + SIDE * (sgn * 1.15)
        W.blob(p, "kit_cliff", (at.x, -0.55, at.z), (0.7, 0.6, 0.62), 130 + int(sgn > 0), subdiv=2, jitter=0.28, floor=-1.6)
        at = POOL + SPILL * 5.1 + SIDE * (sgn * 1.05)
        W.blob(p, "kit_cliff", (at.x, -0.95, at.z), (0.42, 0.34, 0.4), 140 + int(sgn > 0), subdiv=2, jitter=0.3, floor=-1.8)
    return [p.build()]


def falls_height(d):
    """Altura da agua a [param d] u do centro da poca pela diagonal: nivel da poca no canal ate o
    labio, depois o leito do riacho do vale (build_valley.py) com a lamina d'agua."""
    at = POOL + SPILL * d
    if bi.island_sd(at.x, at.z) < bi.LIP:
        return bi.WATER_Y
    return min(bi.WATER_Y, bv.height(at.x, at.z) + bv.WATER_LIFT)


def build_falls_sheet():
    """Cortina de agua do vertedouro: do canal (nivel da poca) ate o leito do riacho do vale, com
    a queda no labio. Material fountain_fall (UV v da poca (0) ao pe (1): os fios descem); a ponta
    some suave em cima da fita do riacho (valley_stream)."""
    steps = 16
    rows = []
    for k in range(steps + 1):
        d = 1.6 + 4.2 * k / steps
        centre = POOL + SPILL * d
        y = falls_height(d) + 0.05
        half = bi.SPILL_HALF + 0.05 + 0.25 * max(0.0, (d - 3.4) / 2.4)
        rows.append([centre + SIDE * (half * s) + Vector((0.0, y + 0.03 * (1.0 - abs(s)), 0.0)) for s in (-1.0, 0.0, 1.0)])
    verts, faces, uvs = [], [], []
    for k, row in enumerate(rows):
        for j, v in enumerate(row):
            verts.append(Vector((v.x, -v.z, v.y)))  # Godot -> Blender
            uvs.append((j / 2.0, 1.0 - k / steps))  # glTF vira o v: no Godot UV.y 0 = poca
    for k in range(steps):
        for j in range(2):
            a = k * 3 + j
            faces.append((a, a + 1, a + 4, a + 3))
    mesh = bpy.data.meshes.new("kit_falls_sheet")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(K.material("fountain_fall"))
    layer = mesh.uv_layers.new(name="UVMap")
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            layer.data[li].uv = uvs[mesh.loops[li].vertex_index]
    mesh.shade_smooth()
    mesh.update()
    obj = bpy.data.objects.new("kit_falls_sheet", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mesh.calc_loop_triangles()
    K.TRIS[obj.name] = len(mesh.loop_triangles)
    return [obj]


# --- pinheiro do vale ----------------------------------------------------------------------------

# Saias da copa (altura, raio), de baixo para cima: ~4,6 u como o pine_valley antigo.
FAR_TIERS = ((0.55, 1.5), (1.25, 1.3), (1.95, 1.1), (2.65, 0.88), (3.3, 0.66), (3.85, 0.44), (4.3, 0.24))


def build_pine_far():
    """Pinheiro leve da floresta do vale (2.115 arvores por MultiMesh, visto de longe e de cima):
    so a copa, com poucos cartoes de folha grandes (um material, uma superficie), ~280 triangulos."""
    crown = K.Foliage("kit_pine_far")
    for k, (y, r) in enumerate(FAR_TIERS):
        crown.clump((0.0, y, 0.0), (r, 0.3, r), int(10 + r * 12), 0.85 - 0.06 * k, 500 + k, mat="kit_pine_far", up_bias=0.2)
    return [crown.build()]


GROUPS = {
    "torch": lambda: {"kit_torch": build_torch()},
    "barricade": lambda: {"kit_barricade": build_barricade()},
    "watchtower": lambda: {"kit_watchtower": build_watchtower()},
    "ballista": lambda: {"kit_ballista": build_ballista()},
    "falls": lambda: {"kit_falls_curb": build_falls_curb(), "kit_falls_sheet": build_falls_sheet()},
    "pinefar": lambda: {"kit_pine_far": build_pine_far()},
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
            W.write_import(name, sorted({m.name for o in objects for m in o.data.materials}))
            everything.extend(objects)
        K.save("rim_" + group)
        x = 0.0
        for objects in pieces.values():
            for o in objects:
                o.location.x += x
            x += 6.0
        K.preview("rim_" + group, everything)
        for name in sorted(o.name for o in everything):
            print("  %-28s %6d" % (name, K.TRIS[name]))


if __name__ == "__main__":
    main()
