"""Kit do castelo e das bases no estilo Eternal Return (ADR-0030; nasceu no spike F84, oficial no F94).

Feito por script no Blender (ADR-0005): muralha, mureta, torre, portao com folhas, torreao, casas,
galpao, fonte, praca, props e folhagem por cartoes. O builder da arena (tools/arena/build_arena.gd)
monta as pecas nas duas bases (a B pela rotacao de 180 graus), com a origem e as medidas das pecas
antigas (art/arena/build_island.py e build_megakit.py), cobrindo a colisao do builder (SPEC-046),
nunca menor. A praca (kit_plaza) vem em coordenadas do mundo da base A.

Direcao (ADR-0030): proporcoes reais, bevel nas quinas, blocos e tabuas onde a camera ve, PBR CC0
(shared/assets/textures/kit/) por UV planar por face em metros, e cor de vertice com sujeira de
chao e variacao por bloco (o material do Godot multiplica). Os .glb saem sem imagem: o import troca
cada material pelo .tres de shared/resources/materials/kit/. Nenhuma malha traz colisao.
Orcamento: ate 1.600 triangulos por objeto.

Geometria escrita em coordenadas do Godot (x leste, y para cima, z sul) e girada para o Blender
no fim (x, -z, y), para o .glb cair no lugar sem transformacao.
Uso (na raiz do repo):
  blender --background --factory-startup --python art/arena/build_castle_kit.py -- <repo> [grupo ...]
Saida: art/arena/kit_<grupo>.blend, art/arena/preview_kit_<grupo>.png e
shared/assets/rrb/arena/kit/*.glb.
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector, noise

argv = sys.argv[sys.argv.index("--") + 1:]
REPO = argv[0]
ONLY = set(argv[1:])
ART = os.path.join(REPO, "art", "arena")
OUT = os.path.join(REPO, "shared", "assets", "rrb", "arena", "kit")
TEX = os.path.join(REPO, "shared", "assets", "textures", "kit")
MAX_TRIS = 1600

# Material -> (pasta da textura, metros por repeticao, cor de previa). Sem pasta = cor lisa no Godot.
MATERIALS = {
    "kit_stone": ("stone", 2.8, None),
    "kit_rubble": ("rubble", 2.0, None),
    "kit_roof": ("roof", 1.8, None),
    "kit_plaster": ("plaster", 2.5, None),
    "kit_door": ("door", 1.4, None),
    "kit_planks": ("planks", 1.6, None),
    "kit_cobble": ("cobble", 2.6, None),
    "kit_metal": ("metal", 0.8, None),
    "kit_cloth": (None, 1.0, (0.05, 0.55, 0.62)),
    "kit_hay": (None, 1.0, (0.78, 0.64, 0.32)),
    "kit_glow": (None, 1.0, (1.0, 0.7, 0.35)),
    "fountain_water": (None, 1.0, (0.16, 0.42, 0.42)),
    "kit_foliage": ("leaves", 1.0, None),
    "kit_blossom": ("blossom", 1.0, None),
}
# Materiais com sujeira de chao na cor de vertice (escurece ate ~1,5 m).
GRIMY = {"kit_stone", "kit_rubble", "kit_plaster", "kit_planks", "kit_door"}
# Tinta para recesso escuro (seteira, vao de janela).
DARK = 0.12
TRIS = {}
_materials = {}
_rng = random.Random(84)


# --- matrizes e primitivas (coordenadas do Godot) ------------------------------------------


def mat4(at=(0.0, 0.0, 0.0), size=(1.0, 1.0, 1.0), rot=(0.0, 0.0, 0.0)):
    """Translacao @ rotacao (graus; pitch X, roll Z, depois yaw Y) @ escala."""
    r = Euler((math.radians(rot[0]), math.radians(rot[1]), math.radians(rot[2])), "XZY")
    return Matrix.Translation(Vector(at)) @ r.to_matrix().to_4x4() @ Matrix.Diagonal((*size, 1.0))


def up_axis():
    """create_cone/cylinder crescem em +Z; no Godot o alto e +Y."""
    return Matrix.Rotation(math.radians(-90.0), 4, "X")


def smoothstep(e0, e1, x):
    t = min(max((x - e0) / (e1 - e0), 0.0), 1.0)
    return t * t * (3.0 - 2.0 * t)


class Piece:
    """Um objeto do kit: bmesh em coordenadas do Godot, material e tinta por face, peso de bevel
    por aresta (1 = chanfra; pecas que emendam com a vizinha, como o corpo da muralha, ficam 0)."""

    def __init__(self, name, bevel=0.035, segments=1, closed=True, smooth=38.0):
        self.name = name
        self.smooth = smooth
        self.bevel = bevel
        self.segments = segments
        self.closed = closed
        self.bm = bmesh.new()
        self.mats = []
        self.tint = self.bm.faces.layers.float.new("tint")
        self.weight = self.bm.edges.layers.float.new("bevel_weight_edge")

    def _take(self, verts, mat, tint, bevel):
        if mat not in self.mats:
            self.mats.append(mat)
        index = self.mats.index(mat)
        if tint is None:
            tint = 1.0 + _rng.uniform(-0.09, 0.06)
        faces = {f for v in verts for f in v.link_faces}
        for f in faces:
            f.material_index = index
            f[self.tint] = tint
        if bevel:
            for e in {e for v in verts for e in v.link_edges}:
                e[self.weight] = 1.0
        return verts

    def box(self, mat, at, size, rot=(0.0, 0.0, 0.0), bevel=True, tint=None, matrix=None):
        m = matrix if matrix is not None else mat4(at, size, rot)
        verts = bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)["verts"]
        return self._take(verts, mat, tint, bevel)

    def cyl(self, mat, base, r1, r2, h, segs, yaw=0.0, bevel=False, tint=None, axis="y"):
        """Tronco de cone (r2 0 = cone) de [param base] ate base + h no [param axis]."""
        turn = {"y": up_axis(), "z": Matrix.Identity(4), "x": Matrix.Rotation(math.radians(90.0), 4, "Y")}[axis]
        m = (Matrix.Translation(Vector(base)) @ Matrix.Rotation(math.radians(yaw), 4, "Y") @ turn
             @ Matrix.Translation((0.0, 0.0, h / 2.0)))
        verts = bmesh.ops.create_cone(
            self.bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h, matrix=m
        )["verts"]
        return self._take(verts, mat, tint, bevel)

    def prism(self, mat, pts, axis, a0, a1, bevel=False, tint=None):
        """Poligono 2D (u, v) extrudado de a0 a a1 no eixo: 'z' -> (x, y), 'x' -> (z, y),
        'y' -> (x, z). Pontos em sentido anti-horario vistos do lado + do eixo."""

        def p3(u, v, a):
            if axis == "z":
                return (u, v, a)
            if axis == "x":
                return (a, v, u)
            return (u, a, v)

        bottom = [self.bm.verts.new(p3(u, v, a0)) for u, v in pts]
        top = [self.bm.verts.new(p3(u, v, a1)) for u, v in pts]
        self.bm.faces.new(list(reversed(bottom)))
        self.bm.faces.new(top)
        n = len(pts)
        for i in range(n):
            j = (i + 1) % n
            self.bm.faces.new((bottom[i], bottom[j], top[j], top[i]))
        return self._take(bottom + top, mat, tint, bevel)

    def lathe(self, mat, profile, segs, center=(0.0, 0.0, 0.0), tint=None):
        """Superficie de revolucao do perfil (r, y), de baixo para cima; r 0 fecha no eixo."""
        cx, cy, cz = center
        rings = []
        for r, y in profile:
            if r <= 1e-5:
                rings.append([self.bm.verts.new((cx, cy + y, cz))])
                continue
            ring = []
            for i in range(segs):
                a = 2.0 * math.pi * i / segs
                ring.append(self.bm.verts.new((cx + math.cos(a) * r, cy + y, cz + math.sin(a) * r)))
            rings.append(ring)
        for lo, hi in zip(rings, rings[1:]):
            for i in range(segs):
                j = (i + 1) % segs
                if len(lo) == 1:
                    self.bm.faces.new((lo[0], hi[j], hi[i]))
                elif len(hi) == 1:
                    self.bm.faces.new((lo[i], lo[j], hi[0]))
                else:
                    self.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
        verts = [v for ring in rings for v in ring]
        return self._take(verts, mat, tint, False)

    def build(self):
        """bmesh -> objeto: bevel por peso, UV planar por face, cor de vertice, sombreamento por
        angulo e giro para o espaco do Blender."""
        if self.closed:
            bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for name in self.mats:
            mesh.materials.append(material(name))
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        if self.bevel > 0.0:
            mod = obj.modifiers.new("Bevel", "BEVEL")
            mod.width = self.bevel
            mod.segments = self.segments
            mod.limit_method = "WEIGHT"
            mod.use_clamp_overlap = True
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.modifier_apply(modifier="Bevel")
        mesh = obj.data
        paint(mesh)
        unwrap(mesh)
        mesh.shade_smooth()
        mesh.set_sharp_from_angle(angle=math.radians(self.smooth))
        mesh.transform(Matrix.Rotation(math.radians(90.0), 4, "X"))
        mesh.update()
        mesh.calc_loop_triangles()
        TRIS[self.name] = len(mesh.loop_triangles)
        if TRIS[self.name] > MAX_TRIS:
            print("  AVISO %s: %d triangulos (> %d)" % (self.name, TRIS[self.name], MAX_TRIS))
        return obj


def _face_axes(n):
    """Eixos (u, v) do plano da face: u horizontal ao longo da face, v subindo por ela; face
    deitada usa x e z do mundo (praca e topo de muro alinhados)."""
    if abs(n.y) > 0.92:
        return Vector((1.0, 0.0, 0.0)), Vector((0.0, 0.0, 1.0))
    u = Vector((0.0, 1.0, 0.0)).cross(n).normalized()
    v = n.cross(u).normalized()
    return u, v


def unwrap(mesh):
    """UV planar por face em metros (repeticao do material), com deslocamento pela tinta da
    face para blocos vizinhos nao repetirem o mesmo trecho da textura."""
    uv = mesh.uv_layers.new(name="UVMap")
    tint = mesh.attributes["tint"].data
    for poly in mesh.polygons:
        name = mesh.materials[poly.material_index].name
        tile = MATERIALS[name][1]
        u_axis, v_axis = _face_axes(poly.normal)
        shift = tint[poly.index].value * 37.0
        offset = (shift % 1.0, (shift * 1.7) % 1.0)
        for li in poly.loop_indices:
            co = mesh.vertices[mesh.loops[li].vertex_index].co
            uv.data[li].uv = (co.dot(u_axis) / tile + offset[0], co.dot(v_axis) / tile + offset[1])


def paint(mesh):
    """Cor de vertice (multiplica o albedo no Godot): tinta da face, sujeira perto do chao,
    baixo escuro (oclusao) e topo de pedra mais claro (a folhagem pinta a sua: Foliage)."""
    col = mesh.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
    tint = mesh.attributes["tint"].data
    for poly in mesh.polygons:
        name = mesh.materials[poly.material_index].name
        n = poly.normal
        for li in poly.loop_indices:
            co = mesh.vertices[mesh.loops[li].vertex_index].co
            c = tint[poly.index].value
            if name in GRIMY:
                c *= 0.74 + 0.26 * smoothstep(0.0, 1.5, co.y)
            if n.y < -0.5:
                c *= 0.6
            elif n.y > 0.8 and name in ("kit_stone", "kit_rubble"):
                c *= 1.06
            c = min(max(c, 0.0), 1.0)
            col.data[li].color = (c, c, c, 1.0)
    mesh.color_attributes.active_color = col


def tex_file(folder, kind):
    """Textura do kit: .jpg (PBR do Poly Haven) ou .png (folhas com alpha)."""
    for ext in (".jpg", ".png"):
        path = os.path.join(TEX, folder, "%s_%s%s" % (folder, kind, ext))
        if os.path.exists(path):
            return path
    return os.path.join(TEX, folder, "%s_%s.jpg" % (folder, kind))


def material(name):
    """Material do Blender com as texturas do kit (so para a previa; o .glb sai sem imagem e o
    import do Godot troca pelo .tres de mesmo nome)."""
    if name in _materials:
        return _materials[name]
    folder, _tile, flat = MATERIALS[name]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    vcol = nodes.new("ShaderNodeVertexColor")
    vcol.layer_name = "Col"
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    links.new(vcol.outputs["Color"], mix.inputs["B"])
    links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    if folder:
        albedo = nodes.new("ShaderNodeTexImage")
        albedo.image = bpy.data.images.load(tex_file(folder, "albedo"), check_existing=True)
        links.new(albedo.outputs["Color"], mix.inputs["A"])
        if name in ("kit_foliage", "kit_blossom"):
            links.new(albedo.outputs["Alpha"], bsdf.inputs["Alpha"])
        rough = nodes.new("ShaderNodeTexImage")
        if os.path.exists(tex_file(folder, "rough")):
            rough.image = bpy.data.images.load(tex_file(folder, "rough"), check_existing=True)
            rough.image.colorspace_settings.name = "Non-Color"
            links.new(rough.outputs["Color"], bsdf.inputs["Roughness"])
        normal = nodes.new("ShaderNodeTexImage")
        normal.image = bpy.data.images.load(tex_file(folder, "normal"), check_existing=True)
        normal.image.colorspace_settings.name = "Non-Color"
        nmap = nodes.new("ShaderNodeNormalMap")
        links.new(normal.outputs["Color"], nmap.inputs["Color"])
        links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
        nodes.active = albedo
    else:
        mix.inputs["A"].default_value = (*flat, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.85
        if name == "kit_glow":
            bsdf.inputs["Emission Color"].default_value = (*flat, 1.0)
            bsdf.inputs["Emission Strength"].default_value = 4.0
        if name == "fountain_water":
            bsdf.inputs["Roughness"].default_value = 0.05
    _materials[name] = mat
    return mat


# --- pecas: muralha, torre, portao ---------------------------------------------------------


def build_wall():
    """Modulo de muralha de 2 u (x -1..1, como o castle_wall): plinto de cantaria rustica, corpo
    de silhar, cornija, adarve com parapeito e 2 ameias por lado (ritmo continuo entre modulos) e
    contraforte no meio. Simetrico na espessura: o arco usa o modulo nos dois sentidos. Cobre a
    colisao do builder (0,8 x 2,5)."""
    p = Piece("kit_wall", bevel=0.05, segments=2)
    p.box("kit_rubble", (0.0, 0.35, 0.0), (2.0, 0.7, 1.24), bevel=False)
    p.box("kit_stone", (0.0, 1.7, 0.0), (2.0, 2.0, 1.0), bevel=False)
    p.box("kit_stone", (0.0, 2.79, 0.0), (2.0, 0.18, 1.16), bevel=False)
    for side in (1.0, -1.0):
        p.box("kit_stone", (0.0, 3.02, side * 0.45), (2.0, 0.28, 0.26), bevel=False)
        for x in (-0.5, 0.5):
            p.box("kit_stone", (x, 3.46, side * 0.45), (0.64, 0.6, 0.3))
        p.box("kit_stone", (0.0, 1.35, side * 0.56), (0.42, 2.3, 0.2))
        p.box("kit_stone", (0.0, 2.5, side * 0.52), (0.42, 0.5, 0.14), rot=(side * -28.0, 0.0, 0.0))
    return [p.build()]


def build_wall_low():
    """Mureta interna da base (os 3 muros curtos da SPEC-046 em volta do T2): mesmo modulo de
    2 u, mais baixa e sem ameias, com capeamento em duas aguas; cobre a colisao (0,8 x 2,5)."""
    p = Piece("kit_wall_low", bevel=0.04)
    p.box("kit_rubble", (0.0, 0.3, 0.0), (2.0, 0.6, 1.2), bevel=False)
    p.box("kit_stone", (0.0, 1.5, 0.0), (2.0, 1.8, 0.96), bevel=False)
    p.box("kit_stone", (0.0, 2.48, 0.0), (2.0, 0.16, 1.12), bevel=False)
    for side in (1.0, -1.0):
        p.box("kit_stone", (0.0, 2.62, side * 0.27), (2.0, 0.08, 0.62), rot=(side * 14.0, 0.0, 0.0), bevel=False, tint=1.04)
        p.box("kit_stone", (0.0, 1.2, side * 0.53), (0.4, 2.0, 0.16))
    return [p.build()]


def build_tower():
    """Torre redonda (o builder escala 1,2): plinto rustico, fuste de silhar com cinta, mata-caes,
    parapeito, telhado conico de telha com pinaculo e flamula do time, seteiras."""
    body = Piece("kit_tower_body", bevel=0.03, segments=2)
    body.cyl("kit_rubble", (0, 0, 0), 1.45, 1.36, 0.7, 20)
    body.cyl("kit_stone", (0, 0.7, 0), 1.3, 1.24, 3.9, 20)
    body.cyl("kit_stone", (0, 2.4, 0), 1.33, 1.33, 0.16, 20)
    body.cyl("kit_stone", (0, 4.75, 0), 1.44, 1.44, 0.6, 20)
    for i in range(10):
        a = 360.0 * i / 10
        at = Matrix.Rotation(math.radians(a), 4, "Y") @ Vector((0.0, 4.58, 1.3))
        body.box("kit_stone", at, (0.26, 0.34, 0.3), rot=(0.0, a, 0.0))
    for i, y in enumerate((1.6, 3.4)):
        for k in range(2):
            a = 45.0 + 180.0 * k + 90.0 * i
            at = Matrix.Rotation(math.radians(a), 4, "Y") @ Vector((0.0, y, 1.24))
            body.box("kit_rubble", at, (0.14, 0.7, 0.1), rot=(0.0, a, 0.0), bevel=False, tint=DARK)
    roof = Piece("kit_tower_roof", bevel=0.0)
    roof.cyl("kit_roof", (0, 5.25, 0), 1.66, 0.0, 2.9, 20)
    roof.cyl("kit_stone", (0, 5.2, 0), 1.5, 1.5, 0.1, 20)
    roof.cyl("kit_metal", (0, 7.9, 0), 0.05, 0.03, 0.9, 6)
    roof.box("kit_cloth", (0.34, 8.5, 0.0), (0.6, 0.3, 0.03), tint=1.0)
    return [body.build(), roof.build()]


def arch_points(radius, center_y, half_width, steps):
    """Pontos (x, y) do arco abatido de x -half_width a +half_width."""
    a0 = math.asin(half_width / radius)
    out = []
    for i in range(steps + 1):
        a = -a0 + 2.0 * a0 * i / steps
        out.append((math.sin(a) * radius, center_y + math.cos(a) * radius))
    return out


# Arco do portao: vao de 5 u (folhas ate y 2,9), nascenca em 2,95, flecha 0,65.
GATE_HALF = 2.5
GATE_SPRING = 2.95
GATE_RISE = 0.65
GATE_R = (GATE_HALF ** 2 + GATE_RISE ** 2) / (2.0 * GATE_RISE)
GATE_CY = GATE_SPRING + GATE_RISE - GATE_R
GATE_DEPTH = 0.95


def build_gate():
    """Portal do portao (origem no centro do vao, como o castle_gate): pilares de silhar com
    plinto, arco abatido de aduelas com fecho, timpano de madeira sobre as folhas, cornija, adarve
    com ameias nas duas faces, estandartes do time e lanternas."""
    frame = Piece("kit_gate_frame", bevel=0.05, segments=1)
    for sx in (-1.0, 1.0):
        frame.box("kit_stone", (sx * 2.95, 2.3, 0.0), (0.9, 4.6, 1.9))
        frame.box("kit_rubble", (sx * 2.95, 0.35, 0.0), (1.12, 0.7, 2.12))
    extra = 0.55
    outer = arch_points(GATE_R + extra, GATE_CY, GATE_HALF, 10)
    spandrel = [(GATE_HALF, 4.6)] + outer[::-1] + [(-GATE_HALF, 4.6)]
    frame.prism("kit_stone", list(reversed(spandrel)), "z", -0.85, 0.85)
    frame.box("kit_stone", (0.0, 4.7, 0.0), (6.9, 0.2, 2.06), bevel=False)
    for side in (1.0, -1.0):
        frame.box("kit_stone", (0.0, 4.95, side * 0.84), (6.8, 0.3, 0.32), bevel=False)
        for x in (-3.0, -1.8, -0.6, 0.6, 1.8, 3.0):
            frame.box("kit_stone", (x, 5.42, side * 0.84), (0.7, 0.64, 0.34))
    arch = Piece("kit_gate_arch", bevel=0.04)
    a0 = math.asin(GATE_HALF / GATE_R)
    count = 9
    for i in range(count):
        a = -a0 + 2.0 * a0 * (i + 0.5) / count
        r_mid = GATE_R + extra / 2.0
        chord = 2.0 * r_mid * math.sin(a0 / count) * 0.94
        key = i == count // 2
        at = (math.sin(a) * r_mid, GATE_CY + math.cos(a) * r_mid + (0.05 if key else 0.0), 0.0)
        size = (chord * (1.25 if key else 1.0), extra + (0.12 if key else 0.0), 2.0 if key else GATE_DEPTH * 2.0)
        arch.box("kit_stone", at, size, rot=(0.0, 0.0, -math.degrees(a)), tint=1.05 if key else None)
    inner = arch_points(GATE_R, GATE_CY, GATE_HALF, 10)
    lunette = [(-GATE_HALF, 2.92), (GATE_HALF, 2.92)] + inner[::-1]
    arch.prism("kit_door", lunette, "z", -0.1, 0.1, tint=0.55)
    # Escudo do time sobre o fecho, nas duas faces (os pilares ficam dentro das torres do portao).
    for z_cloth, z_ring in ((0.86, 0.84), (-0.92, -0.88)):
        arch.cyl("kit_cloth", (0.0, 4.25, z_cloth), 0.3, 0.3, 0.06, 12, tint=1.0, axis="z")
        arch.cyl("kit_metal", (0.0, 4.25, z_ring), 0.36, 0.36, 0.04, 12, axis="z")
    return [frame.build(), arch.build()]


def build_door(side):
    """Folha do portao com a origem na dobradica (o gate.gd gira a folha): 'l' cobre x 0..2,4 e
    'r' x -2,4..0, y 0,05..2,9; tabuas verticais, 3 ferragens e argola."""
    p = Piece("kit_door_%s" % side, bevel=0.015, segments=1)
    sign = 1.0 if side == "l" else -1.0
    for k in range(4):
        x = sign * (0.3 + 0.6 * k)
        p.box("kit_door", (x, 1.475, 0.0), (0.58, 2.85, 0.16))
    for y in (0.45, 1.45, 2.45):
        p.box("kit_metal", (sign * 1.2, y, 0.0), (2.4, 0.12, 0.22))
    for z in (0.08, -0.12):
        p.cyl("kit_metal", (sign * 2.0, 1.3, z), 0.13, 0.13, 0.04, 8, axis="z")
    return [p.build()]


# --- torreao e casas -----------------------------------------------------------------------


def roof_pair(p, ridge, half_span, length, axis, slope_deg, overhang=0.4, thick=0.16):
    """Duas aguas de telha: cumeeira em [param ridge], ao longo de 'x' ou 'z'; cada agua desce
    half_span na horizontal (+ beiral) com a inclinacao dada."""
    a = math.radians(slope_deg)
    run = half_span / math.cos(a) + overhang
    for sign in (1.0, -1.0):
        yaw = 0.0 if axis == "x" else 90.0
        yaw += 0.0 if sign > 0 else 180.0
        m = (Matrix.Translation(Vector(ridge)) @ Matrix.Rotation(math.radians(yaw), 4, "Y")
             @ Matrix.Rotation(a, 4, "X") @ Matrix.Translation((0.0, -thick / 2.0, run / 2.0))
             @ Matrix.Diagonal((length, thick, run, 1.0)))
        p.box("kit_roof", None, None, matrix=m, bevel=False)
    size = (length + 0.1, 0.2, 0.34) if axis == "x" else (0.34, 0.2, length + 0.1)
    p.box("kit_roof", (ridge[0], ridge[1] + 0.02, ridge[2]), size, rot=(45.0 if axis == "x" else 0.0, 0.0, 0.0 if axis == "x" else 45.0), bevel=False, tint=0.8)


def window(p, at, yaw, w=0.6, h=0.9, shutters=True, glow=False, flowers=False, planters=None):
    """Janela numa face: vao escuro, peitoril e verga de pedra, portadas abertas e floreira (a
    caixa entra em [param p]; as plantas, em [param planters], para a folhagem da casa)."""
    rot = Matrix.Rotation(math.radians(yaw), 4, "Y")
    base = Vector(at)

    def put(local, size, mat, tint=None, bevel=True):
        p.box(mat, base + rot @ Vector(local), size, rot=(0.0, yaw, 0.0), tint=tint, bevel=bevel)

    put((0.0, 0.0, 0.0), (w, h, 0.12), "kit_glow" if glow else "kit_rubble", tint=1.0 if glow else DARK, bevel=False)
    put((0.0, -h / 2 - 0.06, 0.06), (w + 0.2, 0.1, 0.16), "kit_stone")
    put((0.0, h / 2 + 0.07, 0.04), (w + 0.24, 0.14, 0.12), "kit_planks", tint=0.6)
    if shutters:
        for sx in (-1.0, 1.0):
            put((sx * (w / 2 + 0.17), 0.0, 0.05), (0.3, h, 0.05), "kit_planks", tint=0.75)
    if flowers:
        put((0.0, -h / 2 - 0.22, 0.2), (w + 0.1, 0.22, 0.22), "kit_planks", tint=0.7)
        if planters is not None:
            planters.append((base + rot @ Vector((0.0, -h / 2 - 0.1, 0.2)), yaw, w + 0.05))


# --- folhagem: cartoes de folha com balanco de vento ---------------------------------------

# Atlas CC0 do ambientCG (shared/assets/textures/kit/leaves e blossom): LeafSet024 em 3x3
# com a ponta para cima; LeafSet028 em 4x4 com a ponta para a direita.
LEAF_CELLS = 3
BLOSSOM_CELLS = 4


class Foliage:
    """Folhagem por cartoes: cada cartao e uma folha do atlas (2 triangulos), espalhada na casca
    de elipsoides. Normal de cada vertice puxada para fora do centro da touceira (luz macia, sem
    cara de plano), cor de vertice com sombra por dentro e por baixo e, no alpha, o peso do
    balanco (0 no pe, 1 na ponta) que o foliage_wind.gdshader usa para o vento."""

    def __init__(self, name):
        self.name = name
        self.verts = []
        self.faces = []
        self.uvs = []
        self.cols = []
        self.normals = []
        self.mats = []
        self.face_mats = []

    def _card(self, mat, base, out, along, length, width, cell, cells, tip_up, center, height, rng):
        side = out.cross(along).normalized()
        tip = base + along * length
        corners = [base - side * width / 2, base + side * width / 2, tip + side * width / 2, tip - side * width / 2]
        cx, cy = cell
        u0, u1 = cx / cells, (cx + 1) / cells
        v0, v1 = 1.0 - (cy + 1) / cells, 1.0 - cy / cells
        if tip_up:
            uv = [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]
        else:  # ponta para a direita: o comprimento corre em u
            uv = [(u0, v1), (u0, v0), (u1, v0), (u1, v1)]
        if mat not in self.mats:
            self.mats.append(mat)
        start = len(self.verts)
        shade = 0.85 + 0.15 * rng.random()
        warm = rng.uniform(-0.07, 0.07)
        for k, p in enumerate(corners):
            radial = p - Vector(center)
            n = (radial.normalized() * 0.75 + out * 0.25).normalized()
            depth = min(radial.length / max(height, 0.01), 1.0)
            lift = min(max((p.y - center[1] + height * 0.5) / height, 0.0), 1.0)
            ao = (0.45 + 0.55 * depth) * (0.65 + 0.35 * lift) * shade
            sway = min(max(p.y / max(height * 1.6, 0.01), 0.0), 1.0) * (0.4 + 0.6 * depth)
            self.verts.append(p)
            self.normals.append(n)
            self.uvs.append(uv[k])
            self.cols.append((ao * (1.0 + warm), ao, ao * (1.0 - warm), sway))
        self.faces.append((start, start + 1, start + 2, start + 3))
        self.face_mats.append(self.mats.index(mat))

    def clump(self, center, radii, count, size, seed, mat="kit_foliage", up_bias=0.5):
        """[param count] folhas na casca do elipsoide [param radii] em volta de [param center]."""
        rng = random.Random(seed)
        c = Vector(center)
        cells = LEAF_CELLS if mat == "kit_foliage" else BLOSSOM_CELLS
        for _ in range(count):
            d = Vector((rng.gauss(0, 1), abs(rng.gauss(0, 1)) * 0.8 + 0.15, rng.gauss(0, 1))).normalized()
            shell = 0.62 + 0.38 * rng.random() ** 0.5
            base = c + Vector((d.x * radii[0], d.y * radii[1], d.z * radii[2])) * shell
            out = (d + Vector((0.0, up_bias, 0.0)) + Vector((rng.gauss(0, 0.35), rng.gauss(0, 0.35), rng.gauss(0, 0.35)))).normalized()
            tangent = (d - out * d.dot(out))
            if tangent.length < 1e-3:
                tangent = Vector((1.0, 0.0, 0.0))
            twist = Matrix.Rotation(rng.uniform(-0.9, 0.9), 3, out)
            along = (twist @ tangent.normalized()).normalized()
            s = size * rng.uniform(0.75, 1.25)
            cell = (rng.randrange(cells), rng.randrange(cells))
            self._card(mat, base - along * s * 0.15, out, along, s, s * 0.78, cell, cells,
                       mat == "kit_foliage", center, max(radii), rng)

    def build(self):
        g2b = lambda v: Vector((v.x, -v.z, v.y))  # Godot -> Blender
        mesh = bpy.data.meshes.new(self.name)
        mesh.from_pydata([g2b(v) for v in self.verts], [], self.faces)
        for name in self.mats:
            mesh.materials.append(material(name))
        for poly, mi in zip(mesh.polygons, self.face_mats):
            poly.material_index = mi
        uv = mesh.uv_layers.new(name="UVMap")
        col = mesh.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
        loop_normals = []
        for poly in mesh.polygons:
            for li in poly.loop_indices:
                vi = mesh.loops[li].vertex_index
                uv.data[li].uv = self.uvs[vi]
                col.data[li].color = self.cols[vi]
                loop_normals.append(g2b(self.normals[vi]))
        mesh.color_attributes.active_color = col
        mesh.shade_smooth()
        mesh.normals_split_custom_set(loop_normals)
        mesh.update()
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        mesh.calc_loop_triangles()
        TRIS[self.name] = len(mesh.loop_triangles)
        if TRIS[self.name] > MAX_TRIS:
            print("  AVISO %s: %d triangulos (> %d)" % (self.name, TRIS[self.name], MAX_TRIS))
        return obj


def planter_plants(name, planters, seed):
    """Plantas das floreiras: folhas pendendo da caixa e flores por cima."""
    f = Foliage(name)
    for i, (at, yaw, w) in enumerate(planters):
        across = Matrix.Rotation(math.radians(yaw), 3, "Y") @ Vector((1.0, 0.0, 0.0))
        for k in range(3):
            c = at + across * (k - 1) * w * 0.3 + Vector((0.0, 0.08, 0.0))
            f.clump(c, (w * 0.22, 0.16, 0.15), 44, 0.09, seed + i * 7 + k, up_bias=0.2)
            f.clump(c + Vector((0.0, 0.08, 0.0)), (w * 0.18, 0.09, 0.11), 9, 0.075, seed + i * 11 + k,
                    mat="kit_blossom", up_bias=1.0)
    return f.build()


def build_keep():
    """Torreao do canto (o builder escala 1,25; origem no centro, portal na face +z): bloco de
    silhar com plinto, cintas e janelas, mata-caes e ameias, guaritas de canto com cone, andar de
    cima com telhado de quatro aguas e bandeira do time."""
    h = 3.2
    body = Piece("kit_keep_body", bevel=0.06)
    deco = Piece("kit_keep_windows", bevel=0.02)
    body.box("kit_rubble", (0, 0.45, 0), (6.9, 0.9, 6.9))
    body.box("kit_stone", (0, 3.85, 0), (6.4, 6.3, 6.4))
    for y in (2.6, 5.2):
        body.box("kit_stone", (0, y, 0), (6.56, 0.18, 6.56), bevel=False)
    for yaw in (0.0, 90.0, 180.0, 270.0):
        rot = Matrix.Rotation(math.radians(yaw), 4, "Y")
        for x in (-1.6, 1.6):
            if yaw == 0.0:
                continue
            window(deco, rot @ Vector((x, 3.9, h + 0.02)), yaw, w=0.4, h=1.0, shutters=False, glow=(x > 0))
        window(deco, rot @ Vector((0.0, 6.2, h + 0.02)), yaw, w=0.4, h=0.9, shutters=False)
    # Portal na face +z: ombreiras, arco de verga, porta de madeira.
    for sx in (-1.0, 1.0):
        body.box("kit_stone", (sx * 1.25, 1.5, h + 0.15), (0.5, 3.0, 0.5))
    body.box("kit_stone", (0.0, 3.25, h + 0.15), (3.0, 0.5, 0.55))
    body.box("kit_door", (0.0, 1.42, h + 0.06), (2.0, 2.8, 0.14), tint=0.8)
    body.box("kit_metal", (0.0, 0.9, h + 0.14), (2.0, 0.1, 0.06), bevel=False)
    body.box("kit_metal", (0.0, 2.1, h + 0.14), (2.0, 0.1, 0.06), bevel=False)
    top = Piece("kit_keep_top", bevel=0.05)
    top.box("kit_stone", (0, 7.2, 0), (6.9, 0.4, 6.9))
    for sx in (1.0, -1.0):
        top.box("kit_stone", (0, 7.6, sx * 3.25), (6.9, 0.4, 0.4), bevel=False)
        top.box("kit_stone", (sx * 3.25, 7.6, 0), (0.4, 0.4, 6.9), bevel=False)
        for t in (-1.8, -0.6, 0.6, 1.8):
            top.box("kit_stone", (t, 8.08, sx * 3.25), (0.62, 0.56, 0.42))
            top.box("kit_stone", (sx * 3.25, 8.08, t), (0.42, 0.56, 0.62))
    top.box("kit_stone", (0, 8.9, 0), (3.6, 3.0, 3.6))
    window(deco, (0.0, 9.0, 1.82), 0.0, w=0.45, h=0.8, shutters=False, glow=True)
    window(deco, (1.82, 9.0, 0.0), 90.0, w=0.45, h=0.8, shutters=False)
    turrets = Piece("kit_keep_turrets", bevel=0.0)
    for sx in (-1.0, 1.0):
        for sz in (-1.0, 1.0):
            c = (sx * h, 0.0, sz * h)
            turrets.cyl("kit_stone", (c[0], 4.4, c[2]), 0.25, 1.0, 0.9, 14)
            turrets.cyl("kit_stone", (c[0], 5.3, c[2]), 1.0, 1.0, 3.3, 14)
            turrets.cyl("kit_stone", (c[0], 8.6, c[2]), 1.12, 1.12, 0.22, 14)
            turrets.cyl("kit_roof", (c[0], 8.8, c[2]), 1.22, 0.0, 2.2, 14)
    roof = Piece("kit_keep_roof", bevel=0.0)
    roof.cyl("kit_roof", (0, 10.35, 0), 2.95, 0.0, 2.6, 4, yaw=45.0)
    roof.cyl("kit_metal", (0, 12.8, 0), 0.06, 0.04, 2.6, 6)
    roof.box("kit_cloth", (0.8, 14.7, 0.0), (1.5, 0.85, 0.04), tint=1.0)
    return [body.build(), deco.build(), top.build(), turrets.build(), roof.build()]


def timber_face(p, axis, at, half, y0, y1, posts, braces=True):
    """Enxaimel numa face plana: postes, frechal, travessa e mao-francesa. axis 'x' = face
    perpendicular a x (corre em z), 'z' = face perpendicular a z (corre em x)."""

    def put(along, y, size_along, size_y, rot=0.0):
        if axis == "x":
            p.box("kit_planks", (at, y, along), (0.12, size_y, size_along), rot=(rot, 0.0, 0.0), bevel=False, tint=0.42)
        else:
            p.box("kit_planks", (along, y, at), (size_along, size_y, 0.12), rot=(0.0, 0.0, rot), bevel=False, tint=0.42)

    span = 2.0 * half
    put(0.0, y1 - 0.08, span, 0.16)
    put(0.0, (y0 + y1) / 2.0, span, 0.12)
    for k in range(posts):
        t = -half + span * k / (posts - 1)
        put(t, (y0 + y1) / 2.0, 0.16, y1 - y0)
    if braces:
        step = span / (posts - 1)
        for k in range(posts - 1):
            t = -half + step * (k + 0.5)
            ang = math.degrees(math.atan2(y1 - y0, step)) * (1.0 if k % 2 == 0 else -1.0)
            length = math.hypot(step, y1 - y0) * 0.9
            put(t, (y0 + y1) / 2.0, length, 0.11, rot=ang if axis == "z" else -ang)


def build_house_stone():
    """Casa de pedra atras do spawn (substitui stone_house; cobre a caixa 3,8 x 3,2 x 3,4):
    terreo de silhar, empenas de reboco com enxaimel, telhado de telha, chamine, porta e janelas
    na face +z com floreiras."""
    walls = Piece("kit_house_stone_walls", bevel=0.04)
    deco = Piece("kit_house_stone_deco", bevel=0.02)
    plants = []
    walls.box("kit_rubble", (0, 0.25, 0), (4.24, 0.5, 3.64))
    walls.box("kit_stone", (0, 1.5, 0), (4.0, 2.9, 3.4), bevel=False)
    gable = [(-1.75, 2.95), (1.75, 2.95), (0.0, 4.45)]
    walls.prism("kit_plaster", gable, "x", -2.0, 2.0)
    for sx in (1.0, -1.0):
        x = sx * 2.0
        walls.box("kit_planks", (x, 3.0, 0), (0.14, 0.16, 3.5), bevel=False, tint=0.42)
        walls.box("kit_planks", (x, 3.6, 0), (0.14, 1.3, 0.14), bevel=False, tint=0.42)
        for sz in (1.0, -1.0):
            walls.box("kit_planks", (x, 3.55, sz * 0.75), (0.14, 0.11, 1.4), rot=(sz * 32.0, 0.0, 0.0), bevel=False, tint=0.42)
    walls.box("kit_planks", (0.0, 1.15, 1.72), (1.15, 2.3, 0.14), bevel=False, tint=0.45)
    walls.box("kit_door", (0.0, 1.05, 1.74), (0.95, 2.1, 0.12), tint=0.9)
    walls.box("kit_planks", (0.0, 2.45, 1.95), (1.4, 0.1, 0.55), rot=(-18.0, 0.0, 0.0), tint=0.6)
    window(deco, (1.3, 1.6, 1.72), 0.0, flowers=True, planters=plants)
    window(deco, (-1.3, 1.6, 1.72), 0.0, flowers=True, planters=plants, glow=True)
    window(deco, (0.0, 1.6, -1.72), 180.0)
    roof = Piece("kit_house_stone_roof", bevel=0.0)
    roof_pair(roof, (0.0, 4.55, 0.0), 1.85, 4.7, "x", math.degrees(math.atan2(1.5, 1.75)))
    roof.box("kit_stone", (-1.2, 4.4, -0.7), (0.6, 2.0, 0.6), bevel=False)
    roof.box("kit_stone", (-1.2, 5.45, -0.7), (0.72, 0.14, 0.72), bevel=False)
    return [walls.build(), deco.build(), roof.build()], planter_plants("kit_house_stone_plants", plants, 21)


def build_house_long():
    """Sobrado do patio (substitui megakit_house_long; caixa x -2..2, z -3..3, h 6,24; frente em
    +x): terreo de silhar, andar em balanco de reboco com enxaimel, empenas nas pontas z, telhado
    de telha, chamine, porta em arco e janelas com floreiras na frente."""
    walls = Piece("kit_house_long_walls", bevel=0.04)
    deco = Piece("kit_house_long_deco", bevel=0.02)
    plants = []
    walls.box("kit_rubble", (0, 0.25, 0), (4.24, 0.5, 6.24))
    walls.box("kit_stone", (0, 1.45, 0), (4.0, 2.9, 6.0), bevel=False)
    walls.box("kit_plaster", (0, 4.12, 0), (4.3, 2.4, 6.3), bevel=False)
    gable = [(-2.15, 5.3), (2.15, 5.3), (0.0, 7.2)]
    walls.prism("kit_plaster", [(z, y) for z, y in gable], "z", -3.15, 3.15)
    walls.box("kit_door", (2.02, 1.1, 0.0), (0.12, 2.2, 1.1), tint=0.9)
    walls.box("kit_stone", (2.06, 2.35, 0.0), (0.2, 0.3, 1.5))
    for z in (-1.9, 1.9):
        window(deco, (2.02, 1.55, z), 90.0, w=0.7, h=0.9)
    for z in (-2.0, 0.0, 2.0):
        window(deco, (2.17, 4.1, z), 90.0, w=0.6, h=0.9, flowers=True, planters=plants, glow=(z == 0.0))
        window(walls, (-2.17, 4.1, z), -90.0, w=0.6, h=0.9)
    timber = Piece("kit_house_long_timber", bevel=0.0)
    timber.box("kit_planks", (0, 2.95, 0), (4.4, 0.22, 6.4), bevel=False, tint=0.42)
    for sx in (1.0, -1.0):
        timber_face(timber, "x", sx * 2.16, 3.15, 3.05, 5.3, 5)
        timber_face(timber, "z", sx * 3.16, 2.15, 3.05, 5.3, 3, braces=False)
    roof = Piece("kit_house_long_roof", bevel=0.0)
    roof_pair(roof, (0.0, 7.3, 0.0), 2.2, 7.1, "z", math.degrees(math.atan2(1.9, 2.15)))
    roof.box("kit_stone", (1.1, 7.3, -2.2), (0.7, 2.4, 0.7), bevel=False)
    roof.box("kit_stone", (1.1, 8.55, -2.2), (0.84, 0.14, 0.84), bevel=False)
    return [walls.build(), deco.build(), timber.build(), roof.build()], planter_plants("kit_house_long_plants", plants, 31)


def build_house_small():
    """Casinha do patio (substitui megakit_house_small; caixa x -2..2, z -2..2, h 3,12; frente
    em +x): reboco com enxaimel sobre plinto, empenas em z, telhado de telha, porta e janela."""
    walls = Piece("kit_house_small_walls", bevel=0.04)
    deco = Piece("kit_house_small_deco", bevel=0.02)
    plants = []
    walls.box("kit_rubble", (0, 0.3, 0), (4.24, 0.6, 4.24))
    walls.box("kit_plaster", (0, 1.65, 0), (4.0, 2.7, 4.0), bevel=False)
    walls.prism("kit_plaster", [(-2.0, 3.0), (2.0, 3.0), (0.0, 4.5)], "z", -2.0, 2.0)
    walls.box("kit_door", (2.02, 1.15, -0.8), (0.12, 2.0, 0.95), tint=0.9)
    window(deco, (2.02, 1.7, 0.9), 90.0, flowers=True, planters=plants)
    window(deco, (-2.02, 1.7, 0.0), -90.0)
    for sx in (1.0, -1.0):
        timber_face(deco, "x", sx * 2.03, 2.0, 0.6, 3.0, 4)
        timber_face(deco, "z", sx * 2.03, 2.0, 0.6, 3.0, 3, braces=False)
    roof = Piece("kit_house_small_roof", bevel=0.0)
    roof_pair(roof, (0.0, 4.6, 0.0), 2.05, 4.8, "z", math.degrees(math.atan2(1.6, 2.0)))
    return [walls.build(), deco.build(), roof.build()], planter_plants("kit_house_small_plants", plants, 41)


def build_yard():
    """Galpao do canto (substitui megakit_yard_corner; caixa x 0,6..4, z -4..-0,6, h 1,4):
    alpendre de madeira com telhado de telha, paredes de tabua nos lados da borda, cerca nos lados
    abertos, fardos, caixotes e barris por dentro."""
    shed = Piece("kit_yard_shed", bevel=0.02)
    x0, x1, z0, z1 = 0.6, 4.0, -4.0, -0.6
    for x, z, h in ((x0, z0, 2.6), (x0, z1, 2.6), (x1, z0, 2.1), (x1, z1, 2.1)):
        shed.box("kit_planks", (x, h / 2, z), (0.18, h, 0.18), tint=0.5)
    shed.box("kit_planks", (x0 - 0.05, 1.1, (z0 + z1) / 2), (0.1, 2.2, z1 - z0), bevel=False, tint=0.7)
    shed.box("kit_planks", ((x0 + x1) / 2, 1.1, z1 + 0.05), (x1 - x0, 2.2, 0.1), bevel=False, tint=0.7)
    for y in (0.45, 1.1):
        shed.box("kit_planks", (x1 + 0.05, y, (z0 + z1) / 2), (0.08, 0.12, z1 - z0), tint=0.6)
        shed.box("kit_planks", ((x0 + x1) / 2, y, z0 - 0.05), (x1 - x0, 0.12, 0.08), tint=0.6)
    slope = math.degrees(math.atan2(0.5, x1 - x0))
    m = (Matrix.Translation(((x0 + x1) / 2, 2.45, (z0 + z1) / 2)) @ Matrix.Rotation(math.radians(slope), 4, "Z")
         @ Matrix.Diagonal((x1 - x0 + 0.7, 0.14, z1 - z0 + 0.6, 1.0)))
    shed.box("kit_roof", None, None, matrix=m, bevel=False)
    stock = Piece("kit_yard_stock", bevel=0.03)
    for at, size in (((1.4, 0.35, -3.2), (1.2, 0.7, 0.8)), ((1.4, 1.0, -3.2), (1.1, 0.6, 0.75)),
                     ((1.3, 0.35, -2.1), (1.1, 0.7, 0.8))):
        stock.box("kit_hay", at, size, tint=1.0)
    for at in ((2.9, 0.0, -1.3), (3.4, 0.0, -1.9)):
        barrel(stock, at)
    stock.box("kit_planks", (2.6, 0.32, -3.3), (0.64, 0.64, 0.64), rot=(0.0, 12.0, 0.0))
    stock.box("kit_planks", (3.3, 0.28, -3.1), (0.56, 0.56, 0.56), rot=(0.0, -20.0, 0.0), tint=0.8)
    return [shed.build(), stock.build()]


# --- fonte, praca e props ------------------------------------------------------------------

# Spray do fountain.tscn: jato em y 1,42, transbordo no anel r 0,41 em y 1,18, respingo em r 0,4-0,5
# em y 0,59. A fonte nova mantem a taca e a bacia nessas alturas.
FOUNTAIN_WATER = ((1.1, 0.58), (0.38, 1.15))


def build_fountain():
    """Fonte de cura (substitui fountain.glb dentro da FountainA; colisao r 0,85 h 1,2):
    bacia octogonal com degrau, borda de cantaria e pilaretes, coluna, taca e pinaculo."""
    p = Piece("kit_fountain", bevel=0.03)
    p.cyl("kit_rubble", (0, 0, 0), 1.45, 1.42, 0.12, 8, yaw=22.5, bevel=True)
    p.cyl("kit_stone", (0, 0.12, 0), 1.2, 1.17, 0.4, 8, yaw=22.5)
    side = 2.0 * 1.18 * math.tan(math.radians(22.5))
    for i in range(8):
        a = 45.0 * i
        at = Matrix.Rotation(math.radians(a), 4, "Y") @ Vector((0.0, 0.62, 1.12))
        p.box("kit_stone", at, (side + 0.06, 0.22, 0.24), rot=(0.0, a, 0.0))
        corner = Matrix.Rotation(math.radians(a + 22.5), 4, "Y") @ Vector((0.0, 0.83, 1.21))
        p.box("kit_stone", corner, (0.2, 0.22, 0.2), rot=(0.0, a + 22.5, 0.0))
    p.cyl("kit_stone", (0, 0.5, 0), 0.26, 0.17, 0.5, 8, yaw=22.5)
    p.cyl("kit_stone", (0, 0.98, 0), 0.14, 0.46, 0.2, 12)
    p.cyl("kit_stone", (0, 1.15, 0), 0.08, 0.06, 0.2, 8)
    p.cyl("kit_stone", (0, 1.33, 0), 0.11, 0.0, 0.12, 8)
    for r, y in FOUNTAIN_WATER:
        p.cyl("fountain_water", (0, y - 0.02, 0), r, r, 0.02, 8 if r > 0.5 else 12, yaw=22.5, tint=1.0)
    return [p.build()]


# Praca da base A, em coordenadas do mundo: disco em volta do spawn (-24, 24) que cabe dentro do
# arco da muralha (raio 12,73) e dos muros de fechamento; meio-fio no lado de tras (o da frente
# fica sob a muralha) e anel de lajes em volta do spawn.
SPAWN_A = (-24.0, 24.0)
PLAZA_R = 12.25
PLAZA_Y = 0.02
# Direcao spawn -> centro da arena (frente da base).
TO_CENTER = (0.70710678, -0.70710678)


def build_plaza():
    """Praca de calcamento (sujeira e musgo na borda pela cor de vertice), meio-fio e anel de
    lajes do spawn."""
    floor = Piece("kit_plaza_floor", bevel=0.0, closed=False)
    cx, cz = SPAWN_A
    segs = 48
    radii = (0.0, 2.6, 5.0, 7.5, 10.0, PLAZA_R)
    rings = []
    for r in radii:
        if r == 0.0:
            rings.append([floor.bm.verts.new((cx, PLAZA_Y, cz))])
            continue
        rings.append([floor.bm.verts.new((cx + math.cos(2 * math.pi * i / segs) * r, PLAZA_Y,
                                          cz + math.sin(2 * math.pi * i / segs) * r)) for i in range(segs)])
    for lo, hi in zip(rings, rings[1:]):
        for i in range(segs):
            j = (i + 1) % segs
            if len(lo) == 1:
                floor.bm.faces.new((lo[0], hi[j], hi[i]))
            else:
                floor.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    for f in floor.bm.faces:
        f.normal_update()
        if f.normal.y < 0.0:
            f.normal_flip()
    floor._take([v for ring in rings for v in ring], "kit_cobble", 1.0, False)
    obj = floor.build()
    # Borda suja e manchas: escurece perto do raio da praca e por ruido.
    mesh = obj.data
    col = mesh.color_attributes["Col"]
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            co = mesh.vertices[mesh.loops[li].vertex_index].co  # ja no espaco do Blender
            r = math.hypot(co.x - cx, -co.y - cz)
            c = 1.0 - 0.38 * smoothstep(PLAZA_R - 3.0, PLAZA_R, r)
            c *= 0.9 + 0.12 * noise.noise(Vector((co.x * 0.23, co.y * 0.23, 0.0)))
            col.data[li].color = (c, c, c, 1.0)
    curb = Piece("kit_plaza_curb", bevel=0.03)
    front = math.degrees(math.atan2(TO_CENTER[1], TO_CENTER[0]))
    count = 30
    for i in range(count):
        a = front + 90.0 + 180.0 * (i + 0.5) / count
        rad = math.radians(a)
        at = (cx + math.cos(rad) * (PLAZA_R + 0.18), 0.06, cz + math.sin(rad) * (PLAZA_R + 0.18))
        length = 2.0 * (PLAZA_R + 0.18) * math.sin(math.radians(90.0 / count)) * 0.96
        curb.box("kit_stone", at, (0.36, 0.16, length), rot=(0.0, -a, 0.0))
    inlay = Piece("kit_plaza_inlay", bevel=0.025)
    count = 16
    for i in range(count):
        a = 360.0 * (i + 0.5) / count
        rad = math.radians(a)
        at = (cx + math.cos(rad) * 2.1, 0.035, cz + math.sin(rad) * 2.1)
        length = 2.0 * 2.1 * math.sin(math.radians(180.0 / count)) * 0.95
        inlay.box("kit_stone", at, (0.5, 0.05, length), rot=(0.0, -a, 0.0), tint=1.08 if i % 2 else 0.92)
    return [obj, curb.build(), inlay.build()]


def barrel(p, at, tint=None):
    """Barril (perfil abaulado de tabuas) com 2 aros de ferro."""
    x, y, z = at
    p.lathe("kit_planks", [(0.0, 0.0), (0.27, 0.0), (0.32, 0.22), (0.34, 0.45), (0.32, 0.68),
                             (0.27, 0.9), (0.0, 0.9)], 12, center=(x, y, z), tint=tint)
    for hy in (0.2, 0.7):
        p.cyl("kit_metal", (x, y + hy, z), 0.335, 0.335, 0.05, 12)


def foliage_layers(name, plan, seed, layers=2):
    """Folhagem densa em [param layers] objetos intercalados (cada um no teto de triangulos):
    a mesma forma com sementes diferentes, no mesmo .glb."""
    out = []
    for layer in range(layers):
        f = Foliage(name if layer == 0 else "%s_%d" % (name, layer + 1))
        plan(f, seed + 1000 * layer)
        out.append(f.build())
    return out


def build_props():
    """Props do canto (origem no chao): barril, caixote, estandarte do time, poste de lanterna,
    moita, carroca e suporte de armas."""
    out = {}
    b = Piece("kit_barrel", bevel=0.0)
    barrel(b, (0.0, 0.0, 0.0))
    out[b.name] = [b.build()]
    c = Piece("kit_crate", bevel=0.02)
    c.box("kit_planks", (0, 0.35, 0), (0.7, 0.7, 0.7))
    for sx in (-1.0, 1.0):
        for sz in (-1.0, 1.0):
            c.box("kit_planks", (sx * 0.33, 0.35, sz * 0.33), (0.08, 0.72, 0.08), tint=0.55)
    c.box("kit_planks", (0.1, 0.92, -0.05), (0.5, 0.44, 0.5), rot=(0.0, 18.0, 0.0), tint=0.85)
    out[c.name] = [c.build()]
    s = Piece("kit_banner", bevel=0.01)
    s.cyl("kit_planks", (0, 0, 0), 0.06, 0.05, 3.3, 8, tint=0.45)
    s.box("kit_planks", (0, 3.05, 0), (1.0, 0.07, 0.07), tint=0.45)
    s.cyl("kit_metal", (0, 3.3, 0), 0.08, 0.0, 0.25, 6)
    s.prism("kit_cloth", [(-0.42, 3.0), (-0.42, 1.25), (0.0, 1.5), (0.42, 1.25), (0.42, 3.0)], "z", -0.015, 0.015, tint=1.0)
    s.box("kit_metal", (0, 2.2, 0.02), (0.3, 0.3, 0.02), rot=(0.0, 0.0, 45.0), tint=1.0)
    out[s.name] = [s.build()]
    lp = Piece("kit_lantern", bevel=0.015)
    lp.box("kit_rubble", (0, 0.15, 0), (0.4, 0.3, 0.4))
    lp.box("kit_planks", (0, 1.4, 0), (0.16, 2.6, 0.16), tint=0.4)
    lp.box("kit_planks", (0.3, 2.55, 0), (0.7, 0.1, 0.1), tint=0.4)
    lp.box("kit_metal", (0.55, 2.42, 0), (0.04, 0.16, 0.04), bevel=False)
    lp.box("kit_glow", (0.55, 2.18, 0), (0.2, 0.3, 0.2), tint=1.0)
    lp.cyl("kit_metal", (0.55, 2.32, 0), 0.17, 0.02, 0.14, 4, yaw=45.0)
    lp.box("kit_metal", (0.55, 2.02, 0), (0.24, 0.04, 0.24), bevel=False)
    out[lp.name] = [lp.build()]
    # Moita redonda (~1,1 m): 3 touceiras sobrepostas, uma mais alta atras; 2 camadas.
    def bush(f, seed):
        for k, (c, r) in enumerate((((0.0, 0.45, 0.0), (0.55, 0.45, 0.55)), ((0.32, 0.36, 0.22), (0.4, 0.36, 0.4)),
                                    ((-0.28, 0.6, -0.18), (0.42, 0.42, 0.42)))):
            f.clump(c, r, 230, 0.2, seed + k)
    out["kit_bush"] = foliage_layers("kit_bush", bush, 70)
    # Arbusto alto (~1,7 m), para os cantos e o pe das torres.
    def shrub(f, seed):
        for k, (c, r) in enumerate((((0.0, 0.55, 0.0), (0.45, 0.5, 0.45)), ((0.05, 1.15, 0.0), (0.38, 0.5, 0.38)),
                                    ((-0.04, 1.55, 0.04), (0.26, 0.3, 0.26)))):
            f.clump(c, r, 240, 0.19, seed + k, up_bias=0.8)
    out["kit_shrub"] = foliage_layers("kit_shrub", shrub, 90)
    # Touceira florida (~0,6 m), para beira de casa, fonte e poste.
    def flowers(f, seed):
        for k, (c, r) in enumerate((((0.0, 0.26, 0.0), (0.56, 0.28, 0.5)), ((0.42, 0.2, 0.3), (0.36, 0.2, 0.36)))):
            f.clump(c, r, 200, 0.16, seed + k, up_bias=0.6)
            f.clump((c[0], c[1] + 0.14, c[2]), (r[0] * 0.9, r[1] * 0.6, r[2] * 0.9), 40, 0.1, seed + 10 + k,
                    mat="kit_blossom", up_bias=1.2)
    out["kit_flowers"] = foliage_layers("kit_flowers", flowers, 110)
    cart = Piece("kit_cart", bevel=0.02)
    cart.box("kit_planks", (0, 0.75, 0), (1.3, 0.1, 2.0))
    for sx in (-1.0, 1.0):
        cart.box("kit_planks", (sx * 0.62, 0.95, 0), (0.06, 0.32, 2.0), tint=0.8)
        cart.cyl("kit_planks", (sx * 0.72 - 0.05, 0.5, 0.1), 0.48, 0.48, 0.1, 12, tint=0.55, axis="x")
        cart.box("kit_planks", (sx * 0.35, 0.55, 1.7), (0.08, 0.08, 1.6), rot=(-14.0, 0.0, 0.0), tint=0.6)
    cart.box("kit_planks", (0, 0.5, 0.1), (1.5, 0.1, 0.1), tint=0.5)
    barrel(cart, (0.25, 0.8, -0.45))
    cart.box("kit_hay", (-0.3, 0.98, 0.3), (0.6, 0.36, 0.9), tint=1.0)
    out[cart.name] = [cart.build()]
    rack = Piece("kit_rack", bevel=0.015)
    for x in (-0.7, 0.7):
        rack.box("kit_planks", (x, 0.8, 0), (0.1, 1.6, 0.1), tint=0.5)
    rack.box("kit_planks", (0, 1.45, 0), (1.6, 0.08, 0.12), tint=0.5)
    rack.box("kit_planks", (0, 0.35, 0), (1.6, 0.08, 0.3), tint=0.5)
    for k, x in enumerate((-0.45, -0.15, 0.15)):
        rack.cyl("kit_planks", (x, 0.3, -0.06), 0.025, 0.025, 1.6, 6, tint=0.5)
        rack.cyl("kit_metal", (x, 1.9, -0.06), 0.05, 0.0, 0.22, 4)
    rack.cyl("kit_cloth", (0.5, 0.95, 0.08), 0.32, 0.32, 0.06, 12, tint=1.0, axis="z")
    out[rack.name] = [rack.build()]
    return out


# --- saida -------------------------------------------------------------------------------


def reset_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for mesh in list(bpy.data.meshes):
        bpy.data.meshes.remove(mesh)


def export(objects, name):
    for o in bpy.context.scene.objects:
        o.select_set(False)
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUT, name + ".glb"),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_animations=False,
        export_image_format="NONE",
        export_vertex_color="ACTIVE",
    )


def save(name):
    os.makedirs(ART, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ART, "kit_" + name + ".blend"), relative_remap=True)


def preview(name, objects):
    """Previa EEVEE com sol e ceu: camera de 3/4 enquadrando os objetos."""
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 960
    scene.render.resolution_y = 720
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("preview") if scene.world is None else scene.world
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.62, 0.72, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    bpy.context.view_layer.update()  # matrix_world com o deslocamento lado a lado de main()
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objects:
        for corner in o.bound_box:
            w = o.matrix_world @ Vector(corner)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    center = (lo + hi) / 2.0
    size = max((hi - lo).length, 1.0)
    sun_data = bpy.data.lights.new("sun", "SUN")
    sun_data.energy = 3.5
    sun = bpy.data.objects.new("sun", sun_data)
    sun.rotation_euler = Euler((math.radians(50), 0.0, math.radians(35)))
    scene.collection.objects.link(sun)
    cam_data = bpy.data.cameras.new("cam")
    cam_data.lens = 40
    cam = bpy.data.objects.new("cam", cam_data)
    cam.location = center + Vector((0.8, -1.1, 0.75)).normalized() * size * 1.15
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(cam)
    scene.camera = cam
    scene.render.filepath = os.path.join(ART, "preview_kit_%s.png" % name)
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    bpy.data.objects.remove(sun, do_unlink=True)


def houses_kit():
    """Casas e galpao; as plantas das floreiras de cada casa saem num .glb proprio (folhagem com
    vento, sem lightmap), posto pelo builder no mesmo transform da casa."""
    out = {}
    for name, make in (("kit_house_stone", build_house_stone), ("kit_house_long", build_house_long),
                       ("kit_house_small", build_house_small)):
        objects, plants = make()
        out[name] = objects
        out[name + "_plants"] = [plants]
    out["kit_yard"] = build_yard()
    return out


GROUPS = {
    "wall": lambda: {"kit_wall": build_wall(), "kit_wall_low": build_wall_low()},
    "tower": lambda: {"kit_tower": build_tower()},
    "gate": lambda: {"kit_gate": build_gate(), "kit_door_l": build_door("l"), "kit_door_r": build_door("r")},
    "keep": lambda: {"kit_keep": build_keep()},
    "houses": lambda: houses_kit(),
    "fountain": lambda: {"kit_fountain": build_fountain()},
    "plaza": lambda: {"kit_plaza": build_plaza()},
    "props": build_props,
}


def main():
    for group, make in GROUPS.items():
        if ONLY and group not in ONLY:
            continue
        reset_scene()
        pieces = make()
        everything = []
        for name, objects in pieces.items():
            export(objects, name)
            everything.extend(objects)
        save(group)
        if group != "plaza":
            # Lado a lado para a previa: cada .glb deslocado em x (so na cena, depois do export).
            x = 0.0
            for objects in pieces.values():
                for o in objects:
                    o.location.x += x
                x += 9.0
        preview(group, everything)
        for name in sorted(o.name for o in everything):
            print("  %-28s %6d" % (name, TRIS[name]))


main()
