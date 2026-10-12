"""Monta art/monsters/wolf.blend e exporta shared/assets/rrb/monsters/wolf.glb (SPEC-055 §4).

Lobo do campo de canto, estilizado azulado (decisao do PI em 2026-10-12, referencia da issue
#137): cabeca e orelhas grandes, juba de tufos no peito e nas bochechas, rabo volumoso de ponta
clara, patas claras, olhos ciano brilhando. Faces planas, cor-base pelo atlas KayKit; olho em
material liso emissivo. Rig de quadrupede (pesos rigidos por parte; tronco, pescoco e rabo
misturam os vizinhos) e 5 animacoes: Idle-loop, Run-loop, Attack, Hit e Death. Kit comum em
creature_kit.py. Uso (na raiz do repo):
  blender --background --factory-startup --python art/monsters/build_wolf.py -- <repo> [preview_dir]
"""
import math
import os
import sys

import bpy

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import creature_kit as ck  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:]
REPO = argv[0]
PREVIEW = argv[1] if len(argv) > 1 else ""
BLEND = os.path.join(REPO, "art", "monsters", "wolf.blend")
GLB = os.path.join(REPO, "shared", "assets", "rrb", "monsters", "wolf.glb")
ATLAS = os.path.join(REPO, "shared", "assets", "kaykit", "medieval_hexagon", "hexagons_medieval.png")

# Celulas do atlas (coluna, linha): pelagem azul, ventre/juba/patas quase brancos, miolo da orelha
# e ponta do rabo em azul forte.
FUR = (0, 1)
FUR_ACCENT = (1, 1)
FUR_LIGHT = (1, 0)
BLACK = (0, 0)
FLATS = {"wolf_eye": ((0.25, 0.95, 1.0), 3.0)}

BONES = {
    "root": ((0, 0, 0), (0, 0, 0.4), None),
    "hips": ((0, 0.86, -0.45), (0, 0.87, 0.0), "root"),
    "chest": ((0, 0.87, 0.0), (0, 0.96, 0.5), "hips"),
    "neck": ((0, 0.96, 0.5), (0, 1.14, 0.76), "chest"),
    "head": ((0, 1.14, 0.76), (0, 1.2, 1.2), "neck"),
    "jaw": ((0, 1.1, 0.92), (0, 1.08, 1.28), "head"),
    "tail1": ((0, 0.88, -0.8), (0, 0.82, -1.08), "hips"),
    "tail2": ((0, 0.82, -1.08), (0, 0.55, -1.42), "tail1"),
}
for _side, _sx in (("l", 1.0), ("r", -1.0)):
    BONES["front_up." + _side] = ((0.18 * _sx, 0.82, 0.4), (0.18 * _sx, 0.44, 0.45), "chest")
    BONES["front_lo." + _side] = ((0.18 * _sx, 0.44, 0.45), (0.18 * _sx, 0.05, 0.43), "front_up." + _side)
    BONES["back_up." + _side] = ((0.18 * _sx, 0.82, -0.55), (0.18 * _sx, 0.46, -0.72), "hips")
    BONES["back_lo." + _side] = ((0.18 * _sx, 0.46, -0.72), (0.18 * _sx, 0.05, -0.6), "back_up." + _side)


def recolor(cell, normal):
    """Ventre claro (normal no Blender: z para cima)."""
    return FUR_LIGHT if cell == FUR and normal.z < -0.55 else cell


def build_body():
    body = ck.Body()
    torso = [
        ((0, 0.88, -0.86), 0.15, 0.15),
        ((0, 0.87, -0.7), 0.24, 0.25),
        ((0, 0.86, -0.42), 0.25, 0.26),
        ((0, 0.88, -0.12), 0.22, 0.23),
        ((0, 0.88, 0.14), 0.27, 0.32),
        ((0, 0.93, 0.38), 0.28, 0.34),
        ((0, 1.0, 0.56), 0.23, 0.28),
    ]
    body.add(ck.loft(torso, 14), FUR, ck.blend("hips", "chest", 2, -0.3, 0.1))
    neck = [((0, 1.02, 0.56), 0.21, 0.25), ((0, 1.12, 0.7), 0.19, 0.21), ((0, 1.2, 0.8), 0.17, 0.18)]
    body.add(ck.loft(neck, 12, cap_start=False), FUR, ck.blend("neck", "head", 2, 0.62, 0.8))
    head = [
        ((0, 1.25, 0.78), 0.19, 0.18),
        ((0, 1.28, 0.93), 0.19, 0.17),
        ((0, 1.22, 1.05), 0.14, 0.12),
        ((0, 1.18, 1.18), 0.085, 0.08),
        ((0, 1.17, 1.3), 0.055, 0.05),
    ]
    body.add(ck.loft(head, 12), FUR, "head")
    body.add(ck.centered_box((0, 1.19, 1.31), (0.08, 0.06, 0.05)), BLACK, "head")
    # Mascara clara do focinho e da testa (por cima do cranio).
    body.add(ck.loft([((0, 1.25, 0.98), 0.1, 0.08), ((0, 1.21, 1.12), 0.07, 0.06), ((0, 1.19, 1.25), 0.045, 0.04)], 8), FUR_LIGHT, "head")
    jaw = [((0, 1.11, 0.94), 0.1, 0.04), ((0, 1.1, 1.1), 0.07, 0.03), ((0, 1.1, 1.26), 0.045, 0.02)]
    body.add(ck.loft(jaw, 8), FUR_LIGHT, "jaw")
    for sx in (1.0, -1.0):
        # Orelha grande: casca escura e miolo azul.
        x = 0.11 * sx
        body.add(ck.spike((x, 1.38, 0.83), (0.25 * sx, 1.0, -0.15), 0.085, 0.27, n=4), FUR, "head")
        body.add(ck.spike((x, 1.39, 0.86), (0.25 * sx, 1.0, -0.05), 0.05, 0.2, n=3), FUR_LIGHT, "head")
        # Olho amendoado inclinado.
        body.add(ck.spike((0.11 * sx, 1.3, 1.01), (0.6 * sx, 0.25, 0.75), 0.05, 0.045, n=4, twist=0.0), "wolf_eye", "head")
        # Bochechas: 3 tufos para tras e para fora.
        for k, (dy, dz) in enumerate(((0.0, 0.0), (-0.06, -0.04), (0.06, -0.03))):
            body.add(ck.spike((0.15 * sx, 1.18 + dy, 0.92 + dz), (0.8 * sx, -0.2, -0.6), 0.05, 0.13 - 0.02 * k), FUR_LIGHT, "head")
    # Juba do peito: 3 aneis de tufos claros, largos e curtos, para baixo e para fora (babador).
    rings = ((1.04, 0.62, 0.2, 0.24, 0.13), (0.98, 0.52, 0.24, 0.29, 0.14), (0.9, 0.4, 0.26, 0.31, 0.12))
    for ring, (cy, cz, rx, ry, size) in enumerate(rings):
        for k in range(11):
            a = math.radians(195.0 + 150.0 * k / 10.0 + ring * 7.0)
            base = (math.cos(a) * rx, cy + math.sin(a) * ry, cz)
            direction = (math.cos(a) * 0.6, math.sin(a) - 0.9, 0.25)
            body.add(ck.spike(base, direction, 0.1, size), FUR_LIGHT, "neck" if ring == 0 else "chest")
    # Tufos da nuca e do ombro, na cor do corpo.
    for sx in (1.0, -1.0):
        body.add(ck.spike((0.16 * sx, 1.14, 0.62), (0.7 * sx, 0.3, -0.7), 0.09, 0.14), FUR, "neck")
        body.add(ck.spike((0.2 * sx, 1.0, 0.45), (0.8 * sx, 0.1, -0.6), 0.09, 0.13), FUR, "chest")
    for side, sx in (("l", 1.0), ("r", -1.0)):
        x = 0.18 * sx
        body.add(ck.limb([(x, 0.84, 0.4), (x, 0.44, 0.45)], [0.14, 0.09], n=7), FUR, "front_up." + side)
        body.add(ck.spike((x, 0.56, 0.38), (0.0, -0.5, -1.0), 0.07, 0.13), FUR, "front_up." + side)
        body.add(ck.limb([(x, 0.44, 0.45), (x, 0.08, 0.43)], [0.085, 0.07], n=7), FUR_LIGHT, "front_lo." + side)
        body.add(paw(x, 0.45), FUR_LIGHT, "front_lo." + side)
        body.add(ck.limb([(x, 0.86, -0.5), (x, 0.46, -0.72)], [0.18, 0.095], n=7), FUR, "back_up." + side)
        body.add(ck.limb([(x, 0.46, -0.72), (x, 0.08, -0.6)], [0.085, 0.07], n=7), FUR_LIGHT, "back_lo." + side)
        body.add(paw(x, -0.58), FUR_LIGHT, "back_lo." + side)
    tail = ck.blend("tail1", "tail2", 2, -1.0, -1.12)
    body.add(ck.limb([(0, 0.9, -0.8), (0, 0.88, -0.98), (0, 0.8, -1.16), (0, 0.68, -1.3)], [0.07, 0.14, 0.15, 0.12], n=8), FUR, tail)
    body.add(ck.limb([(0, 0.68, -1.3), (0, 0.58, -1.4), (0, 0.5, -1.46)], [0.12, 0.08, 0.0], n=8), FUR_ACCENT, "tail2")
    return body


def paw(x, z):
    """Pata arredondada: tronco curto deitado, da canela para frente."""
    return ck.limb([(x, 0.06, z - 0.06), (x, 0.06, z + 0.04), (x, 0.05, z + 0.12)], [0.075, 0.085, 0.06], n=7, side=(0, 1, 0))


def legs(front_l, front_r, back_l, back_r, knee=0.0):
    """Graus de balanco (positivo = pata para tras); o joelho dobra na volta."""
    pose = {}
    for name, deg in (("front_up.l", front_l), ("front_up.r", front_r), ("back_up.l", back_l), ("back_up.r", back_r)):
        pose[name] = {"rot": [(ck.PITCH, deg)]}
        bend = knee * max(0.0, deg) / 30.0
        pose[name.replace("_up", "_lo")] = {"rot": [(ck.PITCH, -bend if name.startswith("front") else bend)]}
    return pose


def anim_idle(rig):
    def at(t):
        s = math.sin(2.0 * math.pi * t)
        return {
            "chest": {"rot": [(ck.PITCH, 1.5 * s)]},
            "neck": {"rot": [(ck.PITCH, -2.0 * s)]},
            "head": {"rot": [(ck.PITCH, 2.5 * s), (ck.YAW, 5.0 * math.sin(2.0 * math.pi * t + 1.0))]},
            "jaw": {"rot": [(ck.PITCH, 3.0 + 3.0 * s)]},
            "tail1": {"rot": [(ck.YAW, 14.0 * s), (ck.PITCH, -6.0)]},
            "tail2": {"rot": [(ck.YAW, 12.0 * math.sin(2.0 * math.pi * t - 0.8))]},
        }

    return ck.make_action(rig, "Idle-loop", ck.cycle(5, 12, at))


def anim_run(rig):
    """Galope de 16 quadros: dianteiras juntas, traseiras em oposicao, dorso flexiona."""

    def at(t):
        s = math.sin(2.0 * math.pi * t)
        c = math.cos(2.0 * math.pi * t)
        return ck.merge(legs(-38.0 * s, -30.0 * s + 6.0, 34.0 * s, 28.0 * s - 6.0, knee=40.0), {
            "hips": {"rot": [(ck.PITCH, 6.0 * s)], "loc": (0, 0, 0.05 * abs(c))},
            "chest": {"rot": [(ck.PITCH, -8.0 * s)]},
            "neck": {"rot": [(ck.PITCH, 5.0 * s - 8.0)]},
            "head": {"rot": [(ck.PITCH, -4.0 * s + 6.0)]},
            "tail1": {"rot": [(ck.PITCH, -12.0 + 10.0 * c)]},
            "tail2": {"rot": [(ck.PITCH, 8.0 * c)]},
        })

    return ck.make_action(rig, "Run-loop", ck.cycle(5, 4, at))


def anim_attack(rig):
    """Recua, salta com a boca aberta e volta (0,67 s; o golpe do lobo e de 0,9 s)."""
    crouch = ck.merge(legs(-20.0, -20.0, 18.0, 18.0, knee=30.0), {
        "hips": {"rot": [(ck.PITCH, -6.0)], "loc": (0, 0.12, -0.12)},
        "neck": {"rot": [(ck.PITCH, -12.0)]},
        "head": {"rot": [(ck.PITCH, 10.0)]},
        "jaw": {"rot": [(ck.PITCH, 10.0)]},
        "tail1": {"rot": [(ck.PITCH, 15.0)]},
    })
    lunge = ck.merge(legs(35.0, 30.0, -25.0, -25.0, knee=10.0), {
        "hips": {"rot": [(ck.PITCH, 4.0)], "loc": (0, -0.35, 0.08)},
        "chest": {"rot": [(ck.PITCH, 6.0)]},
        "neck": {"rot": [(ck.PITCH, 6.0)]},
        "head": {"rot": [(ck.PITCH, -10.0)]},
        "jaw": {"rot": [(ck.PITCH, 35.0)]},
        "tail1": {"rot": [(ck.PITCH, 20.0)]},
    })
    bite = ck.merge(lunge, {"jaw": {"rot": [(ck.PITCH, -33.0)]}, "head": {"rot": [(ck.PITCH, -6.0)]}})
    return ck.make_action(rig, "Attack", [(1, {}), (5, crouch), (8, lunge), (10, bite), (16, {})])


def anim_hit(rig):
    flinch = {
        "hips": {"loc": (0, 0.08, -0.03)},
        "chest": {"rot": [(ck.PITCH, 6.0), (ck.ROLL, 4.0)]},
        "neck": {"rot": [(ck.PITCH, 14.0)]},
        "head": {"rot": [(ck.PITCH, 12.0), (ck.YAW, 10.0)]},
        "jaw": {"rot": [(ck.PITCH, 15.0)]},
        "tail1": {"rot": [(ck.PITCH, -25.0)]},
    }
    return ck.make_action(rig, "Hit", [(1, {}), (4, flinch), (10, {})])


def anim_death(rig):
    """Cambaleia e tomba de lado; pernas recolhem."""
    stagger = ck.merge(legs(-10.0, -10.0, 10.0, 10.0, knee=20.0), {
        "hips": {"loc": (0, 0, -0.15)},
        "neck": {"rot": [(ck.PITCH, -15.0)]},
        "head": {"rot": [(ck.PITCH, -10.0)]},
    })
    down = ck.merge(legs(-25.0, -15.0, 25.0, 15.0, knee=40.0), {
        "root": {"rot": [(ck.ROLL, 82.0)], "loc": (-0.45, 0, 0.12)},
        "neck": {"rot": [(ck.PITCH, -10.0), (ck.YAW, 15.0)]},
        "head": {"rot": [(ck.PITCH, -15.0)]},
        "jaw": {"rot": [(ck.PITCH, 12.0)]},
        "tail1": {"rot": [(ck.PITCH, -20.0)]},
    })
    return ck.make_action(rig, "Death", [(1, {}), (8, stagger), (20, down), (30, down)])


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = ck.build_mesh("Wolf", build_body(), BONES, ATLAS, FLATS, recolor)
    rig = ck.build_rig("WolfRig", BONES)
    actions = [anim_idle(rig), anim_run(rig), anim_attack(rig), anim_hit(rig), anim_death(rig)]
    ck.save_and_export(rig, obj, actions, BLEND, GLB)
    print("RESULT tris", ck.tris(obj), "bones", len(rig.data.bones), "actions", [a.name for a in actions])
    if PREVIEW:
        shots = (("Idle-loop", 0.0), ("Run-loop", 0.25), ("Run-loop", 0.75), ("Attack", 0.6), ("Hit", 0.3), ("Death", 1.0))
        views = (("side", (3.6, -0.6, 1.3)), ("front", (1.6, -3.0, 2.4)), ("game", (0.0, -5.5, 7.5)))
        ck.preview(rig, shots, views, (0.0, 0.0, 0.8), PREVIEW, "wolf")


main()
