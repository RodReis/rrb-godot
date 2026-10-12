"""Monta art/monsters/stone_golem.blend e exporta shared/assets/rrb/monsters/stone_golem.glb.

Golem de Pedra proprio (decisao do PI em 2026-10-12, F55; referencia: "The Golem" do KayKit
Skeletons, so como inspiracao): cranio com chifres e olhos ciano, armadura de pedra em placas,
ombreiras com espinhos, cinto laranja com fivela, tanga roxa e punhos grandes. Serve ao Golem do
centro e ao Golem de canto (troca o "Lava Golem" CC-BY). ~2,6 u de altura. Faces planas, cor-base
pelo atlas KayKit; olho e pano em material liso. Rig bipede (pesos rigidos por parte) e 5
animacoes: Idle-loop, Run-loop, Attack (golpe em area com os dois punhos), Hit e Death. Kit comum
em creature_kit.py. Uso (na raiz do repo):
  blender --background --factory-startup --python art/monsters/build_golem.py -- <repo> [preview_dir]
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
BLEND = os.path.join(REPO, "art", "monsters", "stone_golem.blend")
GLB = os.path.join(REPO, "shared", "assets", "rrb", "monsters", "stone_golem.glb")
ATLAS = os.path.join(REPO, "shared", "assets", "kaykit", "medieval_hexagon", "hexagons_medieval.png")

# Celulas do atlas: pedra clara (corpo), pedra azulada (placas), pedra escura (juntas), osso
# (cranio e chifres), laranja (cinto), cinza (fivela).
STONE = (1, 0)
PLATE = (2, 0)
JOINT = (3, 0)
BONE = (5, 2)
BELT = (7, 0)
METAL = (6, 1)
FLATS = {"golem_eye": ((0.3, 0.95, 1.0), 4.0), "golem_cloth": ((0.36, 0.3, 0.62), 0.0)}

BONES = {
    "root": ((0, 0, 0), (0, 0, 0.4), None),
    "hips": ((0, 1.0, 0), (0, 1.3, 0), "root"),
    "chest": ((0, 1.3, 0), (0, 2.0, 0.05), "hips"),
    "head": ((0, 2.02, 0.12), (0, 2.5, 0.16), "chest"),
    "jaw": ((0, 2.02, 0.2), (0, 1.98, 0.45), "head"),
}
for _side, _sx in (("l", 1.0), ("r", -1.0)):
    BONES["shoulder." + _side] = ((0.3 * _sx, 1.85, 0.0), (0.62 * _sx, 1.88, 0.0), "chest")
    BONES["arm_up." + _side] = ((0.72 * _sx, 1.82, 0.0), (0.8 * _sx, 1.35, 0.04), "shoulder." + _side)
    BONES["arm_lo." + _side] = ((0.8 * _sx, 1.35, 0.04), (0.84 * _sx, 0.85, 0.12), "arm_up." + _side)
    BONES["leg_up." + _side] = ((0.27 * _sx, 1.0, 0.0), (0.29 * _sx, 0.55, 0.04), "hips")
    BONES["leg_lo." + _side] = ((0.29 * _sx, 0.55, 0.04), (0.29 * _sx, 0.0, 0.04), "leg_up." + _side)


def side_parts(sx, side):
    """Pecas de um lado ([param sx] = 1 esquerda, -1 direita)."""
    parts = []
    # Ombreira: bloco inclinado com 3 espinhos de osso.
    parts.append((ck.limb([(0.48 * sx, 1.98, 0.0), (0.92 * sx, 1.9, 0.0)], [0.3, 0.26], n=6), PLATE, "shoulder." + side))
    for k, (dx, dz) in enumerate(((0.55, -0.08), (0.72, 0.06), (0.86, -0.04))):
        parts.append((ck.spike((dx * sx, 2.17 - 0.03 * k, dz), (0.3 * sx, 1.0, 0.0), 0.08, 0.22 - 0.03 * k), BONE, "shoulder." + side))
    # Braco: biceps de pedra, cotovelo escuro, antebraco largo (manopla) e punho.
    parts.append((ck.limb([(0.74 * sx, 1.8, 0.0), (0.8 * sx, 1.38, 0.04)], [0.18, 0.15], n=6), STONE, "arm_up." + side))
    parts.append((ck.centered_box((0.8 * sx, 1.36, 0.04), (0.26, 0.16, 0.26)), JOINT, "arm_lo." + side))
    parts.append((ck.limb([(0.8 * sx, 1.3, 0.05), (0.84 * sx, 0.98, 0.1)], [0.2, 0.25], n=6), PLATE, "arm_lo." + side))
    parts.append((ck.centered_box((0.85 * sx, 0.8, 0.12), (0.42, 0.36, 0.42)), STONE, "arm_lo." + side))
    for k in range(3):
        parts.append((ck.centered_box((0.85 * sx + (k - 1) * 0.12, 0.8, 0.34), (0.1, 0.12, 0.06)), JOINT, "arm_lo." + side))
    parts.append((ck.limb([(0.84 * sx, 1.15, -0.12), (0.86 * sx, 1.05, -0.3)], [0.07, 0.0], n=4), BONE, "arm_lo." + side))
    # Perna curta e grossa, bota de pedra e pe.
    parts.append((ck.limb([(0.27 * sx, 1.0, 0.0), (0.29 * sx, 0.58, 0.04)], [0.22, 0.2], n=6), STONE, "leg_up." + side))
    parts.append((ck.limb([(0.29 * sx, 0.58, 0.04), (0.29 * sx, 0.12, 0.04)], [0.24, 0.28], n=6), PLATE, "leg_lo." + side))
    parts.append((ck.centered_box((0.29 * sx, 0.08, 0.1), (0.42, 0.16, 0.56)), JOINT, "leg_lo." + side))
    # Chifre: sai do lado do cranio, curva para cima e para tras.
    horn = [(0.24 * sx, 2.36, 0.12), (0.42 * sx, 2.48, 0.08), (0.52 * sx, 2.68, 0.0), (0.5 * sx, 2.86, -0.1)]
    parts.append((ck.limb(horn, [0.1, 0.085, 0.06, 0.0], n=6), BONE, "head"))
    parts.append((ck.limb(horn[:2], [0.115, 0.115], n=6), PLATE, "head"))
    # Olho: brilho ciano numa orbita escura.
    parts.append((ck.centered_box((0.12 * sx, 2.27, 0.42), (0.16, 0.12, 0.05)), JOINT, "head"))
    parts.append((ck.centered_box((0.12 * sx, 2.27, 0.45), (0.1, 0.07, 0.03)), "golem_eye", "head"))
    return parts


def build_body():
    body = ck.Body()
    chest_w = ck.blend("hips", "chest", 1, 1.2, 1.45)
    torso = [
        ((0, 1.12, 0.0), 0.44, 0.34),
        ((0, 1.4, 0.02), 0.5, 0.4),
        ((0, 1.75, 0.05), 0.62, 0.48),
        ((0, 2.0, 0.02), 0.56, 0.42),
        ((0, 2.08, 0.0), 0.36, 0.3),
    ]
    # Tronco deitado no eixo y: loft no plano xz (aneis por altura).
    verts, faces = ck.loft([((0, 0, y), rx, rz) for (_, y, _), rx, rz in torso], 8, phase=22.5)
    verts = [(x, z, y) for x, y, z in verts]
    body.add((verts, [tuple(reversed(f)) for f in faces]), STONE, chest_w)
    # Placas do peito e do abdomen.
    for sx in (1.0, -1.0):
        body.add(ck.centered_box((0.22 * sx, 1.78, 0.46), (0.36, 0.34, 0.12)), PLATE, "chest")
    body.add(ck.centered_box((0, 1.45, 0.38), (0.42, 0.22, 0.1)), PLATE, "chest")
    body.add(ck.centered_box((0, 1.82, -0.44), (0.7, 0.4, 0.1)), PLATE, "chest")
    # Cinto, fivela e tanga roxa (frente e tras).
    belt = [((0, 0, 0.98), 0.5, 0.4), ((0, 0, 1.16), 0.52, 0.42)]
    bv, bf = ck.loft(belt, 8, phase=22.5)
    body.add(([(x, z, y) for x, y, z in bv], [tuple(reversed(f)) for f in bf]), BELT, "hips")
    body.add(ck.centered_box((0, 1.07, 0.43), (0.2, 0.18, 0.06)), METAL, "hips")
    body.add(ck.box(-0.24, 0.55, 0.36, 0.48, 0.45, 0.06), "golem_cloth", "hips")
    body.add(ck.box(-0.3, 0.6, -0.42, 0.6, 0.4, 0.06), "golem_cloth", "hips")
    # Cranio: abobada + face achatada; mandibula com dentes.
    skull = [((0, 2.12, 0.14), 0.26, 0.2), ((0, 2.3, 0.18), 0.3, 0.27), ((0, 2.48, 0.14), 0.26, 0.23), ((0, 2.56, 0.08), 0.14, 0.12)]
    sv, sf = ck.loft([((0, z, y), rx, rz) for (_, y, z), rx, rz in skull], 8, phase=22.5)
    body.add(([(x, z, y) for x, y, z in sv], [tuple(reversed(f)) for f in sf]), BONE, "head")
    body.add(ck.centered_box((0, 2.16, 0.34), (0.08, 0.06, 0.06)), JOINT, "head")
    body.add(ck.centered_box((0, 2.0, 0.32), (0.4, 0.12, 0.22)), BONE, "jaw")
    for k in range(4):
        body.add(ck.centered_box(((k - 1.5) * 0.08, 2.09, 0.42), (0.05, 0.06, 0.03)), STONE, "jaw")
    for sx, side in ((1.0, "l"), (-1.0, "r")):
        for geometry, cell, bone in side_parts(sx, side):
            body.add(geometry, cell, bone)
    return body


def anim_idle(rig):
    def at(t):
        s = math.sin(2.0 * math.pi * t)
        return {
            "hips": {"loc": (0, 0, -0.02 * (1 + s))},
            "chest": {"rot": [(ck.PITCH, -2.0 * s)]},
            "head": {"rot": [(ck.PITCH, 3.0 * s), (ck.YAW, 6.0 * math.sin(2.0 * math.pi * t + 1.2))]},
            "jaw": {"rot": [(ck.PITCH, 4.0 + 3.0 * s)]},
            "arm_up.l": {"rot": [(ck.ROLL, 4.0 + 2.0 * s)]},
            "arm_up.r": {"rot": [(ck.ROLL, -4.0 - 2.0 * s)]},
        }

    return ck.make_action(rig, "Idle-loop", ck.cycle(5, 15, at))


def anim_run(rig):
    """Passo pesado de 24 quadros: pernas e bracos em oposicao, tronco balanca."""

    def at(t):
        s = math.sin(2.0 * math.pi * t)
        c = math.cos(2.0 * math.pi * t)
        return {
            "hips": {"rot": [(ck.YAW, 6.0 * s)], "loc": (0, 0, -0.06 * abs(c))},
            "chest": {"rot": [(ck.PITCH, 10.0), (ck.YAW, -8.0 * s), (ck.ROLL, 4.0 * s)]},
            "head": {"rot": [(ck.PITCH, 8.0)]},
            "leg_up.l": {"rot": [(ck.PITCH, -28.0 * s)]},
            "leg_up.r": {"rot": [(ck.PITCH, 28.0 * s)]},
            "leg_lo.l": {"rot": [(ck.PITCH, 30.0 * max(0.0, s))]},
            "leg_lo.r": {"rot": [(ck.PITCH, 30.0 * max(0.0, -s))]},
            "arm_up.l": {"rot": [(ck.PITCH, 30.0 * s), (ck.ROLL, 6.0)]},
            "arm_up.r": {"rot": [(ck.PITCH, -30.0 * s), (ck.ROLL, -6.0)]},
            "arm_lo.l": {"rot": [(ck.PITCH, -20.0)]},
            "arm_lo.r": {"rot": [(ck.PITCH, -20.0)]},
        }

    return ck.make_action(rig, "Run-loop", ck.cycle(5, 6, at))


def anim_attack(rig):
    """Ergue os dois punhos e bate no chao a frente (golpe em area); 22 quadros (~0,9 s)."""
    raise_up = {
        "hips": {"loc": (0, 0.08, 0.04)},
        "chest": {"rot": [(ck.PITCH, -14.0)]},
        "head": {"rot": [(ck.PITCH, -10.0)]},
        "jaw": {"rot": [(ck.PITCH, 20.0)]},
        "arm_up.l": {"rot": [(ck.PITCH, -165.0), (ck.ROLL, -10.0)]},
        "arm_up.r": {"rot": [(ck.PITCH, -165.0), (ck.ROLL, 10.0)]},
        "arm_lo.l": {"rot": [(ck.PITCH, -20.0)]},
        "arm_lo.r": {"rot": [(ck.PITCH, -20.0)]},
    }
    slam = {
        "hips": {"loc": (0, -0.15, -0.22)},
        "chest": {"rot": [(ck.PITCH, 32.0)]},
        "head": {"rot": [(ck.PITCH, 6.0)]},
        "jaw": {"rot": [(ck.PITCH, 10.0)]},
        "leg_up.l": {"rot": [(ck.PITCH, -30.0)]},
        "leg_up.r": {"rot": [(ck.PITCH, -30.0)]},
        "leg_lo.l": {"rot": [(ck.PITCH, 40.0)]},
        "leg_lo.r": {"rot": [(ck.PITCH, 40.0)]},
        "arm_up.l": {"rot": [(ck.PITCH, -55.0), (ck.ROLL, -8.0)]},
        "arm_up.r": {"rot": [(ck.PITCH, -55.0), (ck.ROLL, 8.0)]},
        "arm_lo.l": {"rot": [(ck.PITCH, -10.0)]},
        "arm_lo.r": {"rot": [(ck.PITCH, -10.0)]},
    }
    return ck.make_action(rig, "Attack", [(1, {}), (9, raise_up), (12, raise_up), (14, slam), (18, slam), (24, {})])


def anim_hit(rig):
    flinch = {
        "hips": {"loc": (0, 0.06, 0)},
        "chest": {"rot": [(ck.PITCH, -10.0), (ck.YAW, 8.0)]},
        "head": {"rot": [(ck.PITCH, -14.0)]},
        "jaw": {"rot": [(ck.PITCH, 18.0)]},
        "arm_up.l": {"rot": [(ck.ROLL, 14.0)]},
        "arm_up.r": {"rot": [(ck.ROLL, -14.0)]},
    }
    return ck.make_action(rig, "Hit", [(1, {}), (4, flinch), (12, {})])


def anim_death(rig):
    """Cai de joelhos e tomba para tras."""
    knees = {
        "root": {"loc": (0, 0, -0.35)},
        "leg_up.l": {"rot": [(ck.PITCH, -60.0)]},
        "leg_up.r": {"rot": [(ck.PITCH, -55.0)]},
        "leg_lo.l": {"rot": [(ck.PITCH, 95.0)]},
        "leg_lo.r": {"rot": [(ck.PITCH, 90.0)]},
        "chest": {"rot": [(ck.PITCH, -15.0)]},
        "head": {"rot": [(ck.PITCH, -15.0)]},
        "arm_up.l": {"rot": [(ck.ROLL, 10.0)]},
        "arm_up.r": {"rot": [(ck.ROLL, -10.0)]},
    }
    down = ck.merge(knees, {
        "root": {"rot": [(ck.PITCH, -78.0)], "loc": (0, 0.9, -0.25)},
        "head": {"rot": [(ck.PITCH, -10.0), (ck.YAW, 20.0)]},
        "jaw": {"rot": [(ck.PITCH, 20.0)]},
        "arm_up.l": {"rot": [(ck.ROLL, 40.0)]},
        "arm_up.r": {"rot": [(ck.ROLL, -40.0)]},
    })
    return ck.make_action(rig, "Death", [(1, {}), (10, knees), (24, down), (36, down)])


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = ck.build_mesh("StoneGolem", build_body(), BONES, ATLAS, FLATS)
    rig = ck.build_rig("StoneGolemRig", BONES)
    actions = [anim_idle(rig), anim_run(rig), anim_attack(rig), anim_hit(rig), anim_death(rig)]
    ck.save_and_export(rig, obj, actions, BLEND, GLB)
    print("RESULT tris", ck.tris(obj), "bones", len(rig.data.bones), "actions", [a.name for a in actions])
    if PREVIEW:
        shots = (("Idle-loop", 0.0), ("Run-loop", 0.25), ("Attack", 0.45), ("Attack", 0.6), ("Hit", 0.25), ("Death", 1.0))
        views = (("front", (2.6, -5.0, 2.6)), ("side", (6.0, 0.0, 1.8)), ("game", (0.0, -7.0, 9.5)))
        ck.preview(rig, shots, views, (0.0, 0.0, 1.3), PREVIEW, "golem")


main()
