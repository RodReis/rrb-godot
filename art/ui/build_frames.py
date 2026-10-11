"""Molduras 9-slice da HUD v2 (F43, TOKENS v2): metal escuro com cantos dourados.

Monta a cena, salva art/ui/frames.blend e renderiza os PNG em shared/ui/theme/frames/.
1 unidade = 1 px; camera ortografica de cima, filme transparente, view transform Standard
(o centro emissivo sai com a cor exata do token).

    blender -b --factory-startup -P art/ui/build_frames.py
"""
import math
import os

import bpy

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "shared", "ui", "theme", "frames")
BLEND = os.path.join(ROOT, "art", "ui", "frames.blend")

# Tokens (TOKENS.md §1): cor sRGB e alfa do fundo dos paineis.
BG_PANEL = ((0x17, 0x1F, 0x33), 0.90)
BG_SURFACE = ((0x0B, 0x13, 0x26), 0.95)

METAL = (0.075, 0.080, 0.092)
METAL_LIGHT = (0.16, 0.17, 0.19)
GOLD = (0.83, 0.55, 0.16)


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def reset() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 128
    scene.cycles.use_denoising = False
    scene.cycles.pixel_filter_type = "BOX"
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    world = bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.35, 0.36, 0.40, 1.0)
    bg.inputs["Strength"].default_value = 0.6
    sun = bpy.data.objects.new("Key", bpy.data.lights.new("Key", "SUN"))
    sun.data.energy = 3.0
    sun.data.angle = math.radians(8.0)
    sun.rotation_euler = (math.radians(40.0), math.radians(-25.0), math.radians(-35.0))
    scene.collection.objects.link(sun)


def metal_mat(name: str, color: tuple, roughness: float) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def fill_mat(name: str, srgb: tuple, alpha: float) -> bpy.types.Material:
    """Emissivo com a cor do token e transparencia do alfa do token."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    emit = nodes.new("ShaderNodeEmission")
    emit.inputs["Color"].default_value = (*[srgb_to_linear(c / 255.0) for c in srgb], 1.0)
    clear = nodes.new("ShaderNodeBsdfTransparent")
    mix = nodes.new("ShaderNodeMixShader")
    mix.inputs["Fac"].default_value = alpha
    links.new(clear.outputs[0], mix.inputs[1])
    links.new(emit.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], out.inputs["Surface"])
    return mat


def box(name: str, size_x: float, size_y: float, height: float, center: tuple,
        mat: bpy.types.Material, bevel: float, rot_z: float = 0.0) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(center[0], center[1], height / 2.0))
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = (size_x, size_y, height)
    obj.rotation_euler.z = rot_z
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    if bevel > 0.0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        mod.limit_method = "ANGLE"
    obj.data.materials.append(mat)
    return obj


def ring(name: str, size: float, band: float, height: float,
         mat: bpy.types.Material, bevel: float) -> None:
    """Quatro barras formando a moldura; centro do quadro na origem."""
    half = size / 2.0
    box(name + "_n", size, band, height, (0.0, half - band / 2.0), mat, bevel)
    box(name + "_s", size, band, height, (0.0, -half + band / 2.0), mat, bevel)
    inner = size - 2.0 * band
    box(name + "_e", band, inner, height, (half - band / 2.0, 0.0), mat, bevel)
    box(name + "_w", band, inner, height, (-half + band / 2.0, 0.0), mat, bevel)


def corners(name: str, size: float, stud: float, inset: float, height: float,
            mat: bpy.types.Material) -> None:
    """Losango dourado em cada canto, centrado a [param inset] px da quina."""
    offset = size / 2.0 - inset
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            box(name, stud, stud, height, (sx * offset, sy * offset), mat,
                stud * 0.22, math.radians(45.0))


def camera(size: float) -> None:
    scene = bpy.context.scene
    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = size
    cam.location = (0.0, 0.0, 100.0)
    scene.collection.objects.link(cam)
    scene.camera = cam
    scene.render.resolution_x = int(size)
    scene.render.resolution_y = int(size)
    scene.render.resolution_percentage = 100


def render(name: str) -> None:
    bpy.context.scene.render.filepath = os.path.join(OUT, name + ".png")
    bpy.ops.render.render(write_still=True)


def clear_meshes() -> None:
    for obj in list(bpy.data.objects):
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)


def panel(name: str, fill: tuple) -> None:
    """Painel 96 px: banda de metal 10 px, losangos nos cantos (margem 9-slice 24)."""
    clear_meshes()
    size = 96.0
    camera(size)
    ring("Metal", size - 2.0, 10.0, 4.0, metal_mat("Metal", METAL, 0.42), 1.5)
    corners("Gold", size - 2.0, 15.0, 9.0, 7.0, metal_mat("Gold", GOLD, 0.28))
    # Centro com a cor do token, sob o metal (sem fresta entre banda e fundo).
    box("Fill", size - 8.0, size - 8.0, 0.5, (0.0, 0.0), fill_mat(name, *fill), 0.0)
    render(name)


def skill(name: str, ring_color: tuple) -> None:
    """Moldura do SkillButton 72 px: anel 5 px, centro vazio (por cima do icone)."""
    clear_meshes()
    size = 72.0
    camera(size)
    ring("Metal", size - 1.0, 5.0, 3.0, metal_mat("Ring", ring_color, 0.35), 1.0)
    corners("Gold", size - 1.0, 9.0, 5.0, 5.0, metal_mat("Gold", GOLD, 0.28))
    render(name)


def badge(name: str) -> None:
    """Badge da tecla 24 px: placa de metal com aro dourado (margem 9-slice 8)."""
    clear_meshes()
    size = 24.0
    camera(size)
    box("Rim", size - 2.0, size - 2.0, 3.0, (0.0, 0.0), metal_mat("Gold", GOLD, 0.3), 1.2)
    box("Plate", size - 6.0, size - 6.0, 3.6, (0.0, 0.0),
        metal_mat("Plate", METAL_LIGHT, 0.45), 0.8)
    render(name)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    reset()
    panel("frame_panel", BG_PANEL)
    panel("frame_surface", BG_SURFACE)
    skill("frame_skill", METAL)
    skill("frame_skill_gold", GOLD)
    badge("badge_key")
    # Fica salvo o ultimo estado (badge); os outros saem rodando o script de novo.
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)


main()
