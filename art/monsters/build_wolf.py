"""Monta art/monsters/wolf.blend e exporta shared/assets/rrb/monsters/wolf.glb (SPEC-055 §4).

Lobo do campo de canto: arte propria no estilo KayKit (faces planas, cor-base pelo atlas
hexagons_medieval.png), rig de quadrupede com pesos rigidos por parte (o tronco, o pescoco e o
rabo misturam os 2 ossos vizinhos) e 5 animacoes em keyframe: Idle-loop, Run-loop, Attack, Hit e
Death (-loop = laco no importador do Godot, que tira o sufixo). Geometria escrita em coordenadas
do Godot (x leste, y para cima, z sul) com o lobo olhando para +z, como o golem.glb: a cena do
monstro gira o Model 180 graus. Uso (na raiz do repo):
  blender --background --factory-startup --python art/monsters/build_wolf.py -- <repo> [preview_dir]
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
REPO = argv[0]
PREVIEW = argv[1] if len(argv) > 1 else ""
BLEND = os.path.join(REPO, "art", "monsters", "wolf.blend")
GLB = os.path.join(REPO, "shared", "assets", "rrb", "monsters", "wolf.glb")
ATLAS = os.path.join(REPO, "shared", "assets", "kaykit", "medieval_hexagon", "hexagons_medieval.png")
FPS = 24

# Celulas do atlas KayKit (coluna, linha; linha 0 = topo).
FUR_DARK = (3, 0)
FUR = (6, 1)
FUR_LIGHT = (5, 2)
BLACK = (0, 0)
EYE = (2, 3)
EYE_GLOW = (1.0, 0.62, 0.15)

# Ossos: nome -> (cabeca, cauda, pai) em coordenadas do Godot.
BONES = {
    "root": ((0, 0, 0), (0, 0, 0.4), None),
    "hips": ((0, 0.82, -0.45), (0, 0.84, 0.0), "root"),
    "chest": ((0, 0.84, 0.0), (0, 0.92, 0.5), "hips"),
    "neck": ((0, 0.92, 0.5), (0, 1.08, 0.74), "chest"),
    "head": ((0, 1.08, 0.74), (0, 1.08, 1.12), "neck"),
    "jaw": ((0, 1.0, 0.86), (0, 0.98, 1.2), "head"),
    "tail1": ((0, 0.86, -0.78), (0, 0.78, -1.05), "hips"),
    "tail2": ((0, 0.78, -1.05), (0, 0.62, -1.32), "tail1"),
}
for side, sx in (("l", 1.0), ("r", -1.0)):
    BONES["front_up." + side] = ((0.17 * sx, 0.78, 0.4), (0.17 * sx, 0.42, 0.44), "chest")
    BONES["front_lo." + side] = ((0.17 * sx, 0.42, 0.44), (0.17 * sx, 0.04, 0.42), "front_up." + side)
    BONES["back_up." + side] = ((0.17 * sx, 0.78, -0.55), (0.17 * sx, 0.45, -0.7), "hips")
    BONES["back_lo." + side] = ((0.17 * sx, 0.45, -0.7), (0.17 * sx, 0.04, -0.6), "back_up." + side)


def to_blender(p):
    return Vector((p[0], -p[2], p[1]))


# --- malha -----------------------------------------------------------------------------------


class Body:
    """Vertices (Godot), faces, celula do atlas por face e pesos [(osso, peso)] por vertice."""

    def __init__(self):
        self.verts, self.faces, self.cells, self.glow, self.weights = [], [], [], set(), []

    def add(self, verts, faces, cell, weight, glow=False):
        base = len(self.verts)
        self.verts.extend(verts)
        for v in verts:
            self.weights.append(weight(v) if callable(weight) else [(weight, 1.0)])
        for f in faces:
            if glow:
                self.glow.add(len(self.faces))
            self.faces.append(tuple(base + i for i in f))
            self.cells.append(cell)


def loft(sections, n, phase=0.0, cap_start=True, cap_end=True):
    """Aneis elipticos ao longo da lista [(centro (x, y, z), rx, ry)], no plano xy (eixo z)."""
    verts, faces = [], []
    for center, rx, ry in sections:
        for i in range(n):
            a = math.radians(phase + 360.0 * i / n)
            verts.append((center[0] + math.cos(a) * rx, center[1] + math.sin(a) * ry, center[2]))
    for s in range(len(sections) - 1):
        for i in range(n):
            j = (i + 1) % n
            faces.append((s * n + i, s * n + j, (s + 1) * n + j, (s + 1) * n + i))
    if cap_start:
        faces.append(tuple(range(n - 1, -1, -1)))
    if cap_end:
        last = (len(sections) - 1) * n
        faces.append(tuple(range(last, last + n)))
    return verts, faces


def limb(points, radii, n=5):
    """Tronco de n lados por uma polilinha (x, y, z) com raio por ponto (perna, rabo)."""
    verts, faces = [], []
    for k, (p, r) in enumerate(zip(points, radii)):
        nxt = points[min(k + 1, len(points) - 1)]
        prv = points[max(k - 1, 0)]
        d = (Vector(nxt) - Vector(prv)).normalized()
        side = Vector((1, 0, 0))
        up = d.cross(side).normalized()
        side = up.cross(d).normalized()
        for i in range(n):
            a = 2.0 * math.pi * i / n
            q = Vector(p) + (side * math.cos(a) + up * math.sin(a)) * r
            verts.append(tuple(q))
    m = len(points)
    for s in range(m - 1):
        for i in range(n):
            j = (i + 1) % n
            faces.append((s * n + i, (s + 1) * n + i, (s + 1) * n + j, s * n + j))
    faces.append(tuple(range(n)))
    faces.append(tuple(range((m - 1) * n + n - 1, (m - 1) * n - 1, -1)))
    return verts, faces


def pyramid(base, apex):
    verts = list(base) + [apex]
    n = len(base)
    faces = [(i, (i + 1) % n, n) for i in range(n)] + [tuple(range(n - 1, -1, -1))]
    return verts, faces


def box(x0, y0, z0, sx, sy, sz):
    v = [(x0, y0, z0), (x0 + sx, y0, z0), (x0 + sx, y0, z0 + sz), (x0, y0, z0 + sz),
         (x0, y0 + sy, z0), (x0 + sx, y0 + sy, z0), (x0 + sx, y0 + sy, z0 + sz), (x0, y0 + sy, z0 + sz)]
    f = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    return v, f


def blend(a, b, z0, z1):
    """Peso que passa de [param a] para [param b] ao longo de z entre z0 e z1."""

    def fn(v):
        t = min(1.0, max(0.0, (v[2] - z0) / (z1 - z0)))
        return [(a, 1.0 - t), (b, t)]

    return fn


def build_body():
    body = Body()
    # Tronco: garupa -> cintura -> peito fundo -> ombros; ventre mais alto na cintura.
    torso = [
        ((0, 0.84, -0.86), 0.12, 0.12),
        ((0, 0.83, -0.7), 0.19, 0.2),
        ((0, 0.83, -0.42), 0.2, 0.21),
        ((0, 0.86, -0.12), 0.18, 0.19),
        ((0, 0.84, 0.14), 0.22, 0.27),
        ((0, 0.88, 0.38), 0.22, 0.28),
        ((0, 0.95, 0.56), 0.17, 0.22),
    ]
    tv, tf = loft(torso, 10, phase=-90.0)
    body.add(tv, tf, FUR, blend("hips", "chest", -0.3, 0.1))
    # Pescoco + juba: aneis inclinados ate a nuca.
    neck = [((0, 0.97, 0.56), 0.17, 0.2), ((0, 1.04, 0.68), 0.16, 0.18), ((0, 1.1, 0.78), 0.14, 0.16)]
    nv, nf = loft(neck, 10, phase=-90.0, cap_start=False)
    body.add(nv, nf, FUR, blend("neck", "head", 0.6, 0.78))
    # Cabeca: cranio -> focinho -> trufa (maxilar superior).
    head = [
        ((0, 1.12, 0.76), 0.15, 0.15),
        ((0, 1.13, 0.9), 0.14, 0.13),
        ((0, 1.08, 1.02), 0.09, 0.08),
        ((0, 1.06, 1.16), 0.06, 0.05),
    ]
    hv, hf = loft(head, 8, phase=-90.0)
    body.add(hv, hf, FUR, "head")
    body.add(*box(-0.035, 1.07, 1.15, 0.07, 0.05, 0.04), BLACK, "head")
    # Mandibula: cunha sob o focinho, gira no osso jaw.
    jaw = [((0, 1.01, 0.86), 0.08, 0.035), ((0, 1.0, 1.0), 0.06, 0.03), ((0, 0.99, 1.13), 0.04, 0.02)]
    jv, jf = loft(jaw, 6, phase=-90.0)
    body.add(jv, jf, FUR_LIGHT, "jaw")
    # Orelhas e olhos.
    for sx in (1.0, -1.0):
        base = [(0.05 * sx, 1.22, 0.78), (0.13 * sx, 1.2, 0.8), (0.11 * sx, 1.21, 0.86), (0.05 * sx, 1.23, 0.85)]
        body.add(*pyramid(base, (0.1 * sx, 1.38, 0.8)), FUR_DARK, "head")
        body.add(*box(0.08 * sx - 0.025, 1.15, 0.93, 0.05, 0.035, 0.03), EYE, "head", glow=True)
    # Pernas: coxa larga, canela fina, pata.
    for side, sx in (("l", 1.0), ("r", -1.0)):
        x = 0.17 * sx
        fv, ff = limb([(x, 0.8, 0.4), (x, 0.42, 0.44)], [0.1, 0.065])
        body.add(fv, ff, FUR, "front_up." + side)
        fv, ff = limb([(x, 0.42, 0.44), (x, 0.06, 0.42)], [0.06, 0.045])
        body.add(fv, ff, FUR, "front_lo." + side)
        body.add(*box(x - 0.055, 0.0, 0.38, 0.11, 0.07, 0.15), FUR_DARK, "front_lo." + side)
        bv, bf = limb([(x, 0.82, -0.52), (x, 0.45, -0.7)], [0.13, 0.07])
        body.add(bv, bf, FUR, "back_up." + side)
        bv, bf = limb([(x, 0.45, -0.7), (x, 0.06, -0.6)], [0.06, 0.045])
        body.add(bv, bf, FUR, "back_lo." + side)
        body.add(*box(x - 0.055, 0.0, -0.64, 0.11, 0.07, 0.15), FUR_DARK, "back_lo." + side)
    # Rabo espesso, ponta escura.
    rv, rf = limb([(0, 0.86, -0.8), (0, 0.8, -1.02), (0, 0.7, -1.2), (0, 0.6, -1.34)], [0.07, 0.11, 0.09, 0.03], n=6)
    body.add(rv, rf, FUR_DARK, blend("tail1", "tail2", -1.0, -1.1))
    return body


def atlas_material():
    mat = bpy.data.materials.new("kaykit_atlas")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.85
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ATLAS, check_existing=True)
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def glow_material():
    mat = bpy.data.materials.new("wolf_eye")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*EYE_GLOW, 1.0)
    bsdf.inputs["Emission Color"].default_value = (*EYE_GLOW, 1.0)
    bsdf.inputs["Emission Strength"].default_value = 2.0
    return mat


def uv_of(cell, normal_up):
    """Centro da celula; o degrade vertical do atlas clareia as faces de cima."""
    col, row = cell
    t = 0.75 if normal_up > 0.3 else (0.3 if normal_up < -0.3 else 0.5)
    return ((col + 0.5) / 8.0, 1.0 - (row + 1.0 - t) / 4.0)


def build_mesh(body):
    mesh = bpy.data.meshes.new("Wolf")
    mesh.from_pydata([tuple(to_blender(v)) for v in body.verts], [], body.faces)
    mesh.validate()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(atlas_material())
    mesh.materials.append(glow_material())
    uv = mesh.uv_layers.new(name="UVMap")
    for poly in mesh.polygons:
        cell = body.cells[poly.index]
        # Ventre e queixo claros; dorso escuro (faces viradas para cima do tronco).
        if cell == FUR and poly.normal.z < -0.45:
            cell = FUR_LIGHT
        elif cell == FUR and poly.normal.z > 0.7:
            cell = FUR_DARK
        if poly.index in body.glow:
            poly.material_index = 1
        for li in poly.loop_indices:
            uv.data[li].uv = uv_of(cell, poly.normal.z)
    obj = bpy.data.objects.new("Wolf", mesh)
    bpy.context.scene.collection.objects.link(obj)
    for name in BONES:
        obj.vertex_groups.new(name=name)
    for i, weights in enumerate(body.weights):
        for bone, w in weights:
            if w > 0.0:
                obj.vertex_groups[bone].add([i], w, "REPLACE")
    return obj


# --- rig -------------------------------------------------------------------------------------


def build_rig():
    arm_data = bpy.data.armatures.new("WolfRig")
    rig = bpy.data.objects.new("WolfRig", arm_data)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (head, tail, parent) in BONES.items():
        eb = arm_data.edit_bones.new(name)
        eb.head = to_blender(head)
        eb.tail = to_blender(tail)
        eb.roll = 0.0
        if parent is not None:
            eb.parent = arm_data.edit_bones[parent]
            eb.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


# --- animacao: rotacoes no espaco do rig (Blender), convertidas para o local do osso ------------

# Eixos no espaco do rig (Blender: x lado, -y frente, z cima). PITCH positivo levanta a ponta de
# um osso que aponta para frente (e leva para tras a ponta de um osso que aponta para baixo).
PITCH = Vector((1, 0, 0))
YAW = Vector((0, 0, 1))
ROLL = Vector((0, 1, 0))


def local_rotation(rig, bone, rotations):
    """[(eixo do rig, graus)] -> quaternion no espaco local do osso em repouso."""
    rest = rig.data.bones[bone].matrix_local.to_quaternion()
    q = Quaternion()
    for axis, deg in rotations:
        q = Quaternion(axis, math.radians(deg)) @ q
    return rest.inverted() @ q @ rest


def local_offset(rig, bone, offset):
    rest = rig.data.bones[bone].matrix_local.to_quaternion()
    return rest.inverted() @ Vector(offset)


def key_pose(rig, frame, pose):
    """pose: osso -> {"rot": [(eixo, graus)], "loc": (x, y, z) no rig}. Osso ausente volta ao repouso."""
    for pb in rig.pose.bones:
        spec = pose.get(pb.name, {})
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = local_rotation(rig, pb.name, spec.get("rot", []))
        pb.location = local_offset(rig, pb.name, spec.get("loc", (0, 0, 0)))
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        pb.keyframe_insert("location", frame=frame)


def legs(front_l, front_r, back_l, back_r, knee=0.0):
    """Graus de balanco (positivo = pata para tras) das 4 pernas; o joelho dobra na volta."""
    pose = {}
    for name, deg in (("front_up.l", front_l), ("front_up.r", front_r), ("back_up.l", back_l), ("back_up.r", back_r)):
        pose[name] = {"rot": [(PITCH, deg)]}
        lower = name.replace("_up", "_lo")
        bend = knee * max(0.0, deg) / 30.0
        pose[lower] = {"rot": [(PITCH, -bend if name.startswith("front") else bend)]}
    return pose


def merge(*poses):
    out = {}
    for p in poses:
        for bone, spec in p.items():
            cur = out.setdefault(bone, {"rot": [], "loc": (0, 0, 0)})
            cur["rot"] = cur["rot"] + spec.get("rot", [])
            loc = spec.get("loc", (0, 0, 0))
            cur["loc"] = tuple(a + b for a, b in zip(cur["loc"], loc))
    return out


def make_action(rig, name, frames):
    """[(quadro, pose)] -> action com o nome [param name]."""
    ad = rig.animation_data_create()
    action = bpy.data.actions.new(name)
    ad.action = action
    for frame, pose in frames:
        key_pose(rig, frame, pose)
    ad.action = None
    return action


def anim_idle(rig):
    frames = []
    for i in range(5):
        t = i / 4.0
        s = math.sin(2.0 * math.pi * t)
        frames.append((1 + i * 12, {
            "chest": {"rot": [(PITCH, 1.5 * s)]},
            "neck": {"rot": [(PITCH, -2.0 * s)]},
            "head": {"rot": [(PITCH, 2.5 * s), (YAW, 4.0 * math.sin(2.0 * math.pi * t + 1.0))]},
            "tail1": {"rot": [(YAW, 14.0 * s), (PITCH, -8.0)]},
            "tail2": {"rot": [(YAW, 10.0 * math.sin(2.0 * math.pi * t - 0.8))]},
        }))
    return make_action(rig, "Idle-loop", frames)


def anim_run(rig):
    """Galope de 16 quadros: dianteiras juntas, traseiras em oposicao, dorso flexiona."""
    frames = []
    for i in range(5):
        t = i / 4.0
        s = math.sin(2.0 * math.pi * t)
        c = math.cos(2.0 * math.pi * t)
        pose = merge(
            legs(-38.0 * s, -30.0 * s + 6.0, 34.0 * s, 28.0 * s - 6.0, knee=40.0),
            {
                "hips": {"rot": [(PITCH, 6.0 * s)], "loc": (0, 0, 0.05 * abs(c))},
                "chest": {"rot": [(PITCH, -8.0 * s)]},
                "neck": {"rot": [(PITCH, 5.0 * s - 8.0)]},
                "head": {"rot": [(PITCH, -4.0 * s + 6.0)]},
                "tail1": {"rot": [(PITCH, -12.0 + 10.0 * c)]},
                "tail2": {"rot": [(PITCH, 8.0 * c)]},
            },
        )
        frames.append((1 + i * 4, pose))
    return make_action(rig, "Run-loop", frames)


def anim_attack(rig):
    """Recua, salta com a boca aberta e volta (0,67 s; o golpe do lobo e de 0,9 s)."""
    crouch = merge(legs(-20.0, -20.0, 18.0, 18.0, knee=30.0), {
        "hips": {"rot": [(PITCH, -6.0)], "loc": (0, 0.12, -0.12)},
        "neck": {"rot": [(PITCH, -12.0)]},
        "head": {"rot": [(PITCH, 10.0)]},
        "jaw": {"rot": [(PITCH, -10.0)]},
        "tail1": {"rot": [(PITCH, 15.0)]},
    })
    lunge = merge(legs(35.0, 30.0, -25.0, -25.0, knee=10.0), {
        "hips": {"rot": [(PITCH, 4.0)], "loc": (0, -0.35, 0.08)},
        "chest": {"rot": [(PITCH, 6.0)]},
        "neck": {"rot": [(PITCH, 6.0)]},
        "head": {"rot": [(PITCH, -10.0)]},
        "jaw": {"rot": [(PITCH, -35.0)]},
        "tail1": {"rot": [(PITCH, 20.0)]},
    })
    bite = merge(lunge, {"jaw": {"rot": [(PITCH, 33.0)]}, "head": {"rot": [(PITCH, -6.0)]}})
    return make_action(rig, "Attack", [(1, {}), (5, crouch), (8, lunge), (10, bite), (16, {})])


def anim_hit(rig):
    flinch = {
        "hips": {"loc": (0, 0.08, -0.03)},
        "chest": {"rot": [(PITCH, 6.0), (ROLL, 4.0)]},
        "neck": {"rot": [(PITCH, 14.0)]},
        "head": {"rot": [(PITCH, 12.0), (YAW, 10.0)]},
        "jaw": {"rot": [(PITCH, -15.0)]},
        "tail1": {"rot": [(PITCH, -25.0)]},
    }
    return make_action(rig, "Hit", [(1, {}), (4, flinch), (10, {})])


def anim_death(rig):
    """Cambaleia e tomba de lado; pernas recolhem."""
    stagger = merge(legs(-10.0, -10.0, 10.0, 10.0, knee=20.0), {
        "hips": {"loc": (0, 0, -0.15)},
        "neck": {"rot": [(PITCH, -15.0)]},
        "head": {"rot": [(PITCH, -10.0)]},
    })
    down = merge(legs(-25.0, -15.0, 25.0, 15.0, knee=40.0), {
        "root": {"rot": [(ROLL, 82.0)], "loc": (-0.42, 0, 0.12)},
        "neck": {"rot": [(PITCH, -10.0), (YAW, 15.0)]},
        "head": {"rot": [(PITCH, -15.0)]},
        "jaw": {"rot": [(PITCH, -12.0)]},
        "tail1": {"rot": [(PITCH, -20.0)]},
    })
    return make_action(rig, "Death", [(1, {}), (8, stagger), (20, down), (30, down)])


# --- montagem --------------------------------------------------------------------------------


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.fps = FPS
    body = build_body()
    obj = build_mesh(body)
    rig = build_rig()
    obj.parent = rig
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    actions = [anim_idle(rig), anim_run(rig), anim_attack(rig), anim_hit(rig), anim_death(rig)]
    ad = rig.animation_data_create()
    for action in actions:
        track = ad.nla_tracks.new()
        track.name = action.name
        strip = track.strips.new(action.name, int(action.frame_range[0]), action)
        if hasattr(strip, "action_slot") and len(action.slots) > 0:
            strip.action_slot = action.slots[0]
        track.mute = True
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    bpy.ops.export_scene.gltf(
        filepath=GLB,
        export_format="GLB",
        export_animation_mode="NLA_TRACKS",
        export_force_sampling=True,
        export_yup=True,
    )
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    print("RESULT tris", tris, "bones", len(rig.data.bones), "actions", [a.name for a in actions])
    if PREVIEW:
        preview(rig, actions)


def preview(rig, actions):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x = 480
    scene.render.resolution_y = 480
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    ad = rig.animation_data
    for track in ad.nla_tracks:
        track.mute = True
    shots = (("Idle-loop", 0.0), ("Run-loop", 0.25), ("Run-loop", 0.75), ("Attack", 0.5), ("Hit", 0.3), ("Death", 1.0))
    for view, loc in (("side", (3.4, -0.6, 1.2)), ("front", (1.6, -3.0, 2.4)), ("game", (0.0, -5.5, 7.5))):
        cam.location = loc
        cam.rotation_euler = (Vector((0.0, 0.0, 0.7)) - cam.location).to_track_quat("-Z", "Y").to_euler()
        for name, frac in shots:
            action = bpy.data.actions[name]
            ad.action = action
            if hasattr(ad, "action_slot") and len(action.slots) > 0:
                ad.action_slot = action.slots[0]
            start, end = action.frame_range
            scene.frame_set(int(start + (end - start) * frac))
            scene.render.filepath = os.path.join(PREVIEW, "%s_%s_%d.png" % (view, name, int(frac * 100)))
            bpy.ops.render.render(write_still=True)
    ad.action = None


main()
