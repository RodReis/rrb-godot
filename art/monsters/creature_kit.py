"""Kit comum dos monstros proprios (lobo e golem do F55): malha por partes com pesos rigidos, rig,
animacao em keyframe no espaco do rig, export glTF com NLA e previa Workbench (ADR-0005/0006).

Geometria em coordenadas do Godot (x leste, y para cima, z sul), criatura olhando para +z como o
golem.glb antigo: a cena do monstro gira o Model 180 graus. Cor-base pelo atlas KayKit
(hexagons_medieval.png, faces planas); detalhe sem cor no atlas (olho, pano) em material liso.
"""
import math
import os

import bmesh
import bpy
from mathutils import Quaternion, Vector

FPS = 24
# Eixos no espaco do rig (Blender: x lado, -y frente, z cima). PITCH positivo leva a ponta do osso
# para tras se ele aponta para baixo, para baixo se aponta para frente e para frente se aponta para
# cima (inclina o tronco para frente, abre a mandibula).
PITCH = Vector((1, 0, 0))
YAW = Vector((0, 0, 1))
ROLL = Vector((0, 1, 0))


def to_blender(p):
    return Vector((p[0], -p[2], p[1]))


# --- malha -----------------------------------------------------------------------------------


class Body:
    """Vertices (Godot), faces, celula do atlas ou material liso por face e pesos por vertice."""

    def __init__(self):
        self.verts, self.faces, self.cells, self.weights = [], [], [], []

    def add(self, geometry, cell, weight):
        """[param cell]: (coluna, linha) do atlas ou nome de material liso (flat_materials)."""
        verts, faces = geometry
        base = len(self.verts)
        self.verts.extend(verts)
        for v in verts:
            self.weights.append(weight(v) if callable(weight) else [(weight, 1.0)])
        for f in faces:
            self.faces.append(tuple(base + i for i in f))
            self.cells.append(cell)


def loft(sections, n, phase=-90.0, cap_start=True, cap_end=True):
    """Aneis elipticos ao longo de [(centro (x, y, z), rx, ry)], no plano xy."""
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


def limb(points, radii, n=6, side=(1, 0, 0)):
    """Tronco de n lados por uma polilinha com raio por ponto (perna, braco, rabo, chifre)."""
    verts, faces = [], []
    for k, (p, r) in enumerate(zip(points, radii)):
        d = (Vector(points[min(k + 1, len(points) - 1)]) - Vector(points[max(k - 1, 0)])).normalized()
        up = d.cross(Vector(side)).normalized()
        if up.length < 1e-4:
            up = d.cross(Vector((0, 0, 1))).normalized()
        across = up.cross(d).normalized()
        for i in range(n):
            a = 2.0 * math.pi * i / n
            verts.append(tuple(Vector(p) + (across * math.cos(a) + up * math.sin(a)) * max(r, 1e-3)))
    m = len(points)
    for s in range(m - 1):
        for i in range(n):
            j = (i + 1) % n
            faces.append((s * n + i, (s + 1) * n + i, (s + 1) * n + j, s * n + j))
    faces.append(tuple(range(n)))
    faces.append(tuple(range((m - 1) * n + n - 1, (m - 1) * n - 1, -1)))
    return verts, faces


def spike(base_center, direction, radius, length, n=4, twist=45.0):
    """Ponta de n lados (tufo de pelo, espinho) saindo de [param base_center] na [param direction]."""
    d = Vector(direction).normalized()
    ref = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
    u = d.cross(ref).normalized()
    w = d.cross(u).normalized()
    c = Vector(base_center)
    verts = []
    for i in range(n):
        a = math.radians(twist + 360.0 * i / n)
        verts.append(tuple(c + (u * math.cos(a) + w * math.sin(a)) * radius))
    verts.append(tuple(c + d * length))
    faces = [(i, (i + 1) % n, n) for i in range(n)] + [tuple(range(n - 1, -1, -1))]
    return verts, faces


def box(x0, y0, z0, sx, sy, sz):
    v = [(x0, y0, z0), (x0 + sx, y0, z0), (x0 + sx, y0, z0 + sz), (x0, y0, z0 + sz),
         (x0, y0 + sy, z0), (x0 + sx, y0 + sy, z0), (x0 + sx, y0 + sy, z0 + sz), (x0, y0 + sy, z0 + sz)]
    f = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    return v, f


def centered_box(center, size):
    return box(center[0] - size[0] / 2, center[1] - size[1] / 2, center[2] - size[2] / 2, *size)


def blend(a, b, axis, lo, hi):
    """Peso que passa do osso [param a] para o [param b] ao longo do eixo (0 x, 1 y, 2 z)."""

    def fn(v):
        t = min(1.0, max(0.0, (v[axis] - lo) / (hi - lo)))
        return [(a, 1.0 - t), (b, t)]

    return fn


def mirror_x(geometry):
    """Espelha no plano x = 0 (lado direito a partir do esquerdo), mantendo a orientacao das faces."""
    verts, faces = geometry
    return [(-x, y, z) for x, y, z in verts], [tuple(reversed(f)) for f in faces]


def atlas_material(atlas):
    mat = bpy.data.materials.new("kaykit_atlas")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.85
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(atlas, check_existing=True)
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def flat_material(name, color, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.6
    if emission > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def uv_of(cell, normal_up):
    """Centro da celula; o degrade vertical do atlas clareia as faces de cima."""
    col, row = cell
    t = 0.75 if normal_up > 0.3 else (0.3 if normal_up < -0.3 else 0.5)
    return ((col + 0.5) / 8.0, 1.0 - (row + 1.0 - t) / 4.0)


def build_mesh(name, body, bones, atlas, flats, recolor=None):
    """Objeto com o atlas no slot 0 e os materiais lisos [param flats] {nome: (cor, emissao)}.
    [param recolor](cell, normal) troca a celula pela orientacao da face (dorso, ventre)."""
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([tuple(to_blender(v)) for v in body.verts], [], body.faces)
    mesh.validate()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(atlas_material(atlas))
    slots = {}
    for flat_name, (color, emission) in flats.items():
        mesh.materials.append(flat_material(flat_name, color, emission))
        slots[flat_name] = len(mesh.materials) - 1
    uv = mesh.uv_layers.new(name="UVMap")
    for poly in mesh.polygons:
        cell = body.cells[poly.index]
        if isinstance(cell, str):
            poly.material_index = slots[cell]
            continue
        if recolor is not None:
            cell = recolor(cell, poly.normal)
        for li in poly.loop_indices:
            uv.data[li].uv = uv_of(cell, poly.normal.z)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for bone in bones:
        obj.vertex_groups.new(name=bone)
    for i, weights in enumerate(body.weights):
        for bone, w in weights:
            if w > 0.0:
                obj.vertex_groups[bone].add([i], w, "REPLACE")
    return obj


def tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# --- rig e animacao --------------------------------------------------------------------------


def build_rig(name, bones):
    """[param bones]: nome -> (cabeca, cauda, pai) em coordenadas do Godot."""
    arm_data = bpy.data.armatures.new(name)
    rig = bpy.data.objects.new(name, arm_data)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for bone, (head, tail, parent) in bones.items():
        eb = arm_data.edit_bones.new(bone)
        eb.head = to_blender(head)
        eb.tail = to_blender(tail)
        eb.roll = 0.0
        if parent is not None:
            eb.parent = arm_data.edit_bones[parent]
            eb.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


def _local_rotation(rig, bone, rotations):
    """[(eixo do rig, graus)] -> quaternion no espaco local do osso em repouso."""
    rest = rig.data.bones[bone].matrix_local.to_quaternion()
    q = Quaternion()
    for axis, deg in rotations:
        q = Quaternion(axis, math.radians(deg)) @ q
    return rest.inverted() @ q @ rest


def _key_pose(rig, frame, pose):
    """pose: osso -> {"rot": [(eixo, graus)], "loc": (x, y, z) no rig}. Ausente = repouso."""
    for pb in rig.pose.bones:
        spec = pose.get(pb.name, {})
        rest = rig.data.bones[pb.name].matrix_local.to_quaternion()
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = _local_rotation(rig, pb.name, spec.get("rot", []))
        pb.location = rest.inverted() @ Vector(spec.get("loc", (0, 0, 0)))
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        pb.keyframe_insert("location", frame=frame)


def merge(*poses):
    out = {}
    for p in poses:
        for bone, spec in p.items():
            cur = out.setdefault(bone, {"rot": [], "loc": (0, 0, 0)})
            cur["rot"] = cur["rot"] + spec.get("rot", [])
            cur["loc"] = tuple(a + b for a, b in zip(cur["loc"], spec.get("loc", (0, 0, 0))))
    return out


def make_action(rig, name, frames):
    """[(quadro, pose)] -> action [param name] (-loop no nome = laco no importador do Godot)."""
    ad = rig.animation_data_create()
    action = bpy.data.actions.new(name)
    ad.action = action
    for frame, pose in frames:
        _key_pose(rig, frame, pose)
    ad.action = None
    return action


def cycle(count, step, pose_at):
    """Laco de [param count] quadros-chave a cada [param step] quadros; pose_at(t em 0..1)."""
    return [(1 + i * step, pose_at(i / (count - 1))) for i in range(count)]


def save_and_export(rig, mesh_obj, actions, blend_path, glb_path):
    bpy.context.scene.render.fps = FPS
    mesh_obj.parent = rig
    mod = mesh_obj.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    ad = rig.animation_data_create()
    for action in actions:
        track = ad.nla_tracks.new()
        track.name = action.name
        strip = track.strips.new(action.name, int(action.frame_range[0]), action)
        if hasattr(strip, "action_slot") and len(action.slots) > 0:
            strip.action_slot = action.slots[0]
        track.mute = True
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format="GLB",
        export_animation_mode="NLA_TRACKS",
        export_force_sampling=True,
        export_yup=True,
    )


def preview(rig, shots, views, target, out_dir, prefix):
    """Previa Workbench de cada (acao, fracao) em cada (vista, posicao da camera)."""
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
    for view, loc in views:
        cam.location = loc
        cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()
        for name, frac in shots:
            action = bpy.data.actions[name]
            ad.action = action
            if hasattr(ad, "action_slot") and len(action.slots) > 0:
                ad.action_slot = action.slots[0]
            start, end = action.frame_range
            scene.frame_set(int(start + (end - start) * frac))
            scene.render.filepath = os.path.join(out_dir, "%s_%s_%s_%d.png" % (prefix, view, name, int(frac * 100)))
            bpy.ops.render.render(write_still=True)
    ad.action = None
    bpy.data.objects.remove(cam, do_unlink=True)
