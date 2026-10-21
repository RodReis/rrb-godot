extends SceneTree
## Base do builder da arena (tools/arena/build_arena.gd): paths, eixos da base, enfeite (F40) e
## ambientacao, mais os utilitarios de montagem e geometria. So visual e utilitario: toda regra
## de colisao, marcadores e corredores fica no build_arena.gd, que estende este script.
## Azimute: graus anti-horarios a partir do norte (-Z), vistos de cima (N 0, O 90, S 180, L 270).

const OUT: String = "res://scenes/arena/ilha_arcana.tscn"
const RRB_ARENA: String = "res://shared/assets/rrb/arena/"
## Kit das bases no estilo Eternal Return (ADR-0030, F94): art/arena/build_castle_kit.py.
const KIT: String = RRB_ARENA + "kit/"
## Tecido do time (estandarte, escudo, flamula): ciano no kit; a base B troca pelo dourado
## (SPEC-007 §5).
const CLOTH_A: String = "kit_cloth.tres"
const CLOTH_B: String = "res://shared/resources/materials/kit/kit_cloth_b.tres"
const GATE_SCENE: String = "res://scenes/world/gate.tscn"
const FOUNTAIN_SCENE: String = "res://scenes/world/fountain.tscn"
const MATERIALS: String = "res://shared/resources/materials/"
const SKY_MATERIAL: String = MATERIALS + "abyss_sky.tres"
const AMBIENCE_SCRIPT: String = "res://scripts/world/arena_ambience.gd"
const ENVIRONMENT_SCRIPT: String = "res://scripts/world/arena_environment.gd"
## Gerado por tools/bake-lightmap.ps1 (plugin do LightmapGI: <cena>.lmbake ao lado da cena).
const LIGHTMAP_DATA: String = "res://scenes/arena/ilha_arcana.lmbake"

# Base A (canto SO) em coordenadas locais: s ao longo de centro -> spawn A (-24, +24); l para a
# esquerda de quem esta no spawn olhando o centro. A base B e a rotacao de 180 graus.
const AXIS_A: Vector3 = Vector3(-0.70710678, 0, 0.70710678)
const LATERAL: Vector3 = Vector3(-0.70710678, 0, -0.70710678)
const SPAWN_S: float = 33.941
const GATE_S: float = 21.213

# Lagoa NO (SPEC-046 §2.1) e cratera (§2.2), tambem usadas pela ambientacao.
const LAGOON_A: Vector2 = Vector2(-26, -18)
const CRATER_RADIUS: float = 6.0

# Enfeite (F40), metade A na beira da ilha (fora da area jogavel, sem colisao), em (x, z) do
# mundo nos lados N e O (fora da cortina do castelo); a B e a rotacao.
const RIM: float = 41.3
## Floresta da borda (moldura do F40, PI 2026-10-11): fileiras de pinheiros nos lados N e O da
## metade A (a B e a rotacao), de RIM_SPAN.x a RIM_SPAN.y ao longo do lado, fora dos castelos.
const RIM_FOREST_ROWS: Array[float] = [40.9, 41.9]
## Passo e folga do F96: a copa de cartoes do kit_pine e mais larga que a do pine_dark do F40.
const RIM_FOREST_STEP: float = 2.3
const RIM_SPAN: Vector2 = Vector2(-38.5, 14.0)
## Folga entre pinheiro e enfeite/tocha da borda; poca da cascata tem folga propria.
const RIM_CLEAR: float = 2.4
const FALLS_CLEAR: float = 4.2
## Tochas da borda, a cada RIM_TORCH_STEP ao longo do lado; luz em uma sim, outra nao.
const RIM_TORCH_ROW: float = 40.5
const RIM_TORCH_STEP: float = 9.0
const RIM_CRYSTALS_A: Array[Array] = [
	[Vector2(-41.0, -30), true], [Vector2(2, -41.0), false], [Vector2(-41.0, 5), false]
]
const RIM_BARRICADES_A: Array[Array] = [
	[Vector2(-41.0, -17), 90.0], [Vector2(-13, -41.0), 0.0], [Vector2(13, -41.0), 0.0]
]
const RIM_WATCHTOWER_A: Vector2 = Vector2(-41.6, -9)
const RIM_BALLISTA_A: Vector2 = Vector2(-6, -41.2)
## Cascata de enfeite (decisao do PI 2026-10-10): poca no bastiao do canto NO (e SE, por
## rotacao); desde o F56 (ADR-0012) cai num degrau curto e vira o riacho do vale. No F96 a
## cantaria e a cortina de agua do vertedouro (art/arena/build_rim_kit.py) vem nas coordenadas
## do mundo do canto NO.
const FALLS_A: Vector2 = Vector2(-43.0, -43.0)
const CRYSTAL_MATERIALS: Array[String] = ["magenta", "cyan", "green"]

# Decoracao das bases (F94, ADR-0030; posicoes do spike F84), metade A em (x, z) do mundo; a B e
# a rotacao de 180 graus. Sem colisao: rente a muro e casa, fora do spawn, dos baus, dos monstros
# e da fonte.
const BASE_SPAWN_A: Vector2 = Vector2(-24, 24)
## [asset, (x, z), yaw em graus; NAN = +x virado para o spawn da base].
const BASE_PROPS_A: Array[Array] = [
	["kit_banner", Vector2(-18.66, 13.58), NAN],
	["kit_banner", Vector2(-13.58, 18.66), NAN],
	["kit_lantern", Vector2(-26.87, 12.73), NAN],
	["kit_lantern", Vector2(-12.73, 26.87), NAN],
	["kit_lantern", Vector2(-26.30, 21.78), NAN],
	["kit_lantern", Vector2(-21.78, 26.30), NAN],
	["kit_rack", Vector2(-29.13, 25.45), NAN],
	["kit_rack", Vector2(-25.45, 29.13), NAN],
	["kit_barrel", Vector2(-32.94, 18.37), 0.0],
	["kit_barrel", Vector2(-33.60, 19.10), 40.0],
	["kit_crate", Vector2(-32.70, 17.30), 15.0],
	["kit_barrel", Vector2(-18.37, 32.94), 0.0],
	["kit_crate", Vector2(-17.30, 32.70), -20.0],
	["kit_crate", Vector2(-19.20, 33.70), 35.0],
	["kit_cart", Vector2(-33.20, 32.60), 120.0],
	["kit_banner", Vector2(-29.20, 30.20), NAN],
	["kit_barrel", Vector2(-34.70, 29.00), 10.0],
	["kit_crate", Vector2(-29.00, 34.60), 5.0],
]
## Folhagem solta (x, z): [asset, posicao].
const BASE_FOLIAGE_A: Array[Array] = [
	["kit_shrub", Vector2(-39.0, 21.5)],
	["kit_shrub", Vector2(-21.5, 39.0)],
	["kit_bush", Vector2(-34.0, 34.0)],
	["kit_bush", Vector2(-38.0, 28.5)],
	["kit_bush", Vector2(-28.5, 38.0)],
	["kit_flowers", Vector2(-34.8, 24.3)],
	["kit_flowers", Vector2(-34.9, 30.2)],
	["kit_flowers", Vector2(-31.0, 34.8)],
	["kit_flowers", Vector2(-24.3, 34.8)],
]
## Folhagem rente ao arco por dentro: raio e azimute (graus) a partir da direcao spawn -> centro
## (-80 e a fonte), alternando moita e arbusto alto.
const BASE_RING_RADIUS: float = 11.6
const BASE_RING_DEG: Array[float] = [-46.0, -24.0, 24.0, 46.0, 80.0]
const BASE_RING_ASSETS: Array[String] = ["kit_bush", "kit_shrub"]
## Touceiras floridas em (s, l) da base: ao lado da fonte e dos postes do spawn.
const BASE_FLOWERS_LOCAL: Array[Vector2] = [
	Vector2(33.5, 12.0), Vector2(34.5, 4.2), Vector2(34.5, -4.2)
]
## Escala-base por asset (a touceira florida baixa sumia na camera do jogo; PI 2026-10-20).
const FOLIAGE_SCALE: Dictionary[String, float] = {"kit_flowers": 1.4}
## Vidro da lanterna no espaco do prop (build_castle_kit.py, build_props) e a luz dela.
const LANTERN_GLASS: Vector3 = Vector3(0.55, 2.18, 0.0)
const LANTERN_LIGHT_RANGE: float = 5.5
const LANTERN_LIGHT_ENERGY: float = 1.0

# Ambientacao (cliente): luzes e particulas.
const MAGMA_LIGHT_RANGE: float = 12.0
const TORCH_LIGHT_RANGE: float = 6.0
const RIM_TORCH_LIGHT_ENERGY: float = 1.1
const CRYSTAL_LIGHT_RANGE: float = 7.0
const LAGOON_LIGHT_RANGE: float = 9.0
const EMBERS_AMOUNT: int = 40
## Fumaca do lago de magma (F95): puffs redondos e macios que sobem, crescem e somem.
const SMOKE_AMOUNT: int = 64
const SMOKE_LIFETIME: float = 8.0
const SMOKE_SIZE: float = 3.0
const PUFF_TEXTURE_SIZE: int = 64

# Luz e pos (SPEC-038; valores iniciais do guia, ajuste final na verificacao visual do PI).
# F39 (PI 2026-10-10, sem toon): sombra mais macia, AO mais leve. F40 (PI 2026-10-11, realista e
# sombrio): exposicao e ambiente mais baixos e frios, sol frio mais inclinado (sombra longa),
# neblina mais densa e azulada.
const EXPOSURE: float = 0.92
const SSAO_RADIUS: float = 1.5
const SSAO_INTENSITY: float = 1.4
const AMBIENT_COLOR: Color = Color(0.24, 0.27, 0.36)
const AMBIENT_ENERGY: float = 0.72
const GLOW_THRESHOLD: float = 1.05
const FOG_DENSITY: float = 0.016
const FOG_ALBEDO: Color = Color(0.36, 0.41, 0.5)
## Neblina de distancia (F56, ADR-0012): funde as encostas do vale no fundo e esconde o fim do
## cenario. So em profundidade (o volumetrico nao passa de ~64 u) e fora do toggle de neblina
## volumetrica: a vista fechada nao depende da configuracao grafica. Cor acompanha o dia/noite.
const DISTANCE_FOG_BEGIN: float = 45.0
const DISTANCE_FOG_END: float = 125.0
const DISTANCE_FOG_CURVE: float = 1.3
## No modo depth, fog_density e a forca maxima (1 = some por completo no fim).
const DISTANCE_FOG_DENSITY: float = 1.0
const SUN_COLOR: Color = Color(0.8, 0.85, 0.95)
const SUN_ENERGY: float = 1.05
const SUN_ROTATION_DEG: Vector3 = Vector3(-38, 38, 0)
const SUN_SHADOW_BLUR: float = 3.0
const SUN_SHADOW_DISTANCE: float = 65.0
## Lightmap so com a luz indireta (o sol e direto em tempo real): baixa frequencia, meia
## resolucao do texel do import basta e mantem o .exr versionado pequeno.
const LIGHTMAP_TEXEL_SCALE: float = 0.5
## F49 (ADR-0010): o Sun fica fora do bake (BAKE_DISABLED) porque o sol anda ao longo da partida;
## o indireto vem so de um ceu neutro (nem o dia azul nem a noite cosmica) e dos emissivos.
const LIGHTMAP_SKY_COLOR: Color = Color(0.6, 0.68, 0.85)
const LIGHTMAP_SKY_ENERGY: float = 0.6
## Sonda de reflexo unica cobrindo a ilha (|x|, |z| <= 42 com a beira).
const PROBE_SIZE: Vector3 = Vector3(88, 20, 88)
const PROBE_CENTER: Vector3 = Vector3(0, 6, 0)

var _root: Node3D
var _scenes: Dictionary = {}
var _crystal_count: int = 0
## Vidros das lanternas das bases (mundo); o _build_ambience acende uma luz em cada.
var _lanterns: Array[Vector3] = []

# --- ambiente e luz (F38), enfeite (F40): beira da ilha, sem colisao -------------------------


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = load(SKY_MATERIAL)
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT_COLOR
	env.ambient_light_energy = AMBIENT_ENERGY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = EXPOSURE
	env.ssao_enabled = true
	env.ssao_radius = SSAO_RADIUS
	env.ssao_intensity = SSAO_INTENSITY
	env.ssil_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = GLOW_THRESHOLD
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = FOG_DENSITY
	env.volumetric_fog_albedo = FOG_ALBEDO
	env.volumetric_fog_sky_affect = 0.0  # neblina so na ilha: o abismo/ceu do F40 fica escuro
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = DISTANCE_FOG_BEGIN
	env.fog_depth_end = DISTANCE_FOG_END
	env.fog_depth_curve = DISTANCE_FOG_CURVE
	env.fog_density = DISTANCE_FOG_DENSITY
	env.fog_light_color = FOG_ALBEDO
	env.fog_sky_affect = 0.0
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = env
	world.set_script(load(ENVIRONMENT_SCRIPT))
	_add(_root, world)


## Sol (luz direta em tempo real, sombra nos herois; fora do bake, F49) + LightmapGI (indireta
## bakeada do cenario estatico com ceu neutro; herois e monstros pelas sondas do bake) +
## ReflectionProbe unico (refeito em degraus pelo DayNight). SDFGI nao
## (ADR-0006 D-V6). O bake e passo do tools/bake-lightmap.ps1: aqui so se liga o dado ja bakeado.
func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = SUN_ROTATION_DEG
	sun.light_color = SUN_COLOR
	sun.light_energy = SUN_ENERGY
	sun.light_bake_mode = Light3D.BAKE_DISABLED  # F49: sol 100% dinamico, fora do lightmap
	sun.shadow_enabled = true
	sun.shadow_blur = SUN_SHADOW_BLUR
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = SUN_SHADOW_DISTANCE
	_add(_root, sun)
	var lightmap := LightmapGI.new()
	lightmap.name = "LightmapGI"
	lightmap.generate_probes_subdiv = LightmapGI.GENERATE_PROBES_SUBDIV_8
	lightmap.texel_scale = LIGHTMAP_TEXEL_SCALE
	lightmap.environment_mode = LightmapGI.ENVIRONMENT_MODE_CUSTOM_COLOR
	lightmap.environment_custom_color = LIGHTMAP_SKY_COLOR
	lightmap.environment_custom_energy = LIGHTMAP_SKY_ENERGY
	if ResourceLoader.exists(LIGHTMAP_DATA):
		lightmap.light_data = load(LIGHTMAP_DATA)
	else:
		push_warning("[arena] sem %s: rode tools/bake-lightmap.ps1" % LIGHTMAP_DATA)
	_add(_root, lightmap)
	var probe := ReflectionProbe.new()
	probe.name = "ReflectionProbe"
	probe.position = PROBE_CENTER
	probe.size = PROBE_SIZE
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	_add(_root, probe)


func _build_rim_decor(flip: float) -> void:
	var decor := _group("RimDecor")
	var tag := _team_tag(flip)
	var forest := _rim_forest_points()
	for i: int in range(forest.size()):
		var at := _world(forest[i], flip)
		var pine := _asset(decor, KIT + "kit_pine.glb", "Pine%s%d" % [tag, i])
		var size := 0.9 + 0.5 * fposmod(at.x * 0.73 + at.z * 0.29, 1.0)
		var basis := Basis(Vector3.UP, at.x * 0.37 + at.z * 0.61).scaled(Vector3.ONE * size)
		pine.transform = Transform3D(basis, at)
	var torches := _rim_torch_points()
	for i: int in range(torches.size()):
		var torch := _asset(decor, KIT + "kit_torch.glb", "Torch%s%d" % [tag, i])
		var at := _world(torches[i], flip)
		# Braco da tocha voltado para dentro da arena.
		torch.transform = Transform3D(_tangent_basis(_inward(torches[i]) * flip), at)
	for i: int in range(RIM_CRYSTALS_A.size()):
		var c: Array = RIM_CRYSTALS_A[i]
		var at := _world(c[0], flip)
		_crystal(decor, at, c[1], "Crystal%s%d" % [tag, i], at.x * 0.2)
	for i: int in range(RIM_BARRICADES_A.size()):
		var b: Array = RIM_BARRICADES_A[i]
		var at := _world(b[0], flip)
		var fence := _asset(decor, KIT + "kit_barricade.glb", "Barricade%s%d" % [tag, i])
		fence.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(b[1])), at)
	var turn := Basis() if flip > 0 else Basis(Vector3.UP, PI)
	# Escada da torre (+x do kit) virada para dentro da arena; a B gira junto.
	var tower := _asset(decor, KIT + "kit_watchtower.glb", "Watchtower%s" % tag)
	tower.transform = Transform3D(turn, _world(RIM_WATCHTOWER_A, flip))
	var ballista := _asset(decor, KIT + "kit_ballista.glb", "Ballista%s" % tag)
	var ballista_at := _world(RIM_BALLISTA_A, flip)
	ballista.transform = Transform3D(Basis.looking_at(-ballista_at.normalized()), ballista_at)
	for piece: String in ["kit_falls_curb", "kit_falls_sheet"]:
		var label := "%s%s" % [piece.trim_prefix("kit_").to_pascal_case(), tag]
		_asset(decor, KIT + piece + ".glb", label).transform = Transform3D(turn, Vector3.ZERO)


## Praca, props e folhagem da base de [param flip] (F94): a praca vem em coordenadas do mundo da
## base A e gira 180 graus na B; props com o tecido do time.
func _build_base_dressing(flip: float) -> void:
	var tag := _team_tag(flip)
	var group := _group("BaseDecor")
	var turn := Basis() if flip > 0 else Basis(Vector3.UP, PI)
	_asset(group, KIT + "kit_plaza.glb", "Plaza%s" % tag).transform = Transform3D(
		turn, Vector3.ZERO
	)
	var spawn := BASE_SPAWN_A * flip
	for i: int in range(BASE_PROPS_A.size()):
		var spec: Array = BASE_PROPS_A[i]
		var asset: String = spec[0]
		var at: Vector2 = spec[1] * flip
		var yaw: float = spec[2]
		var angle := (
			_yaw_to(at, spawn) if is_nan(yaw) else deg_to_rad(yaw) + (0.0 if flip > 0 else PI)
		)
		var where := Transform3D(Basis(Vector3.UP, angle), Vector3(at.x, 0, at.y))
		var label := "%s%s%d" % [asset.trim_prefix("kit_").capitalize(), tag, i]
		var prop := _asset(group, KIT + asset + ".glb", label)
		prop.transform = where
		_team_cloth(prop, flip)
		if asset == "kit_lantern":
			_lanterns.append(where * LANTERN_GLASS)
	var spots: Array[Array] = BASE_FOLIAGE_A.duplicate()
	var to_center := (-BASE_SPAWN_A).normalized()
	for i: int in range(BASE_RING_DEG.size()):
		var ring := (
			BASE_SPAWN_A + to_center.rotated(deg_to_rad(BASE_RING_DEG[i])) * BASE_RING_RADIUS
		)
		spots.append([BASE_RING_ASSETS[i % BASE_RING_ASSETS.size()], ring])
	for local: Vector2 in BASE_FLOWERS_LOCAL:
		spots.append(["kit_flowers", _flat(AXIS_A * local.x + LATERAL * local.y)])
	for i: int in range(spots.size()):
		var asset: String = spots[i][0]
		var at: Vector2 = spots[i][1] * flip
		var size := 0.85 + 0.35 * fposmod(absf(at.x) * 0.37 + absf(at.y) * 0.61, 1.0)
		size *= FOLIAGE_SCALE.get(asset, 1.0)
		var basis := Basis(Vector3.UP, at.x * 1.3 + at.y * 0.7).scaled(Vector3.ONE * size)
		var label := "%s%s%d" % [asset.trim_prefix("kit_").capitalize(), tag, i]
		_asset(group, KIT + asset + ".glb", label).transform = Transform3D(
			basis, Vector3(at.x, 0, at.y)
		)


## Yaw que vira o +x do prop (braco da lanterna, frente do estandarte) para [param target].
func _yaw_to(at: Vector2, target: Vector2) -> float:
	var dir := target - at
	return atan2(-dir.y, dir.x)


## Base B: o tecido do time (kit_cloth) vira dourado. Instancia editavel: o override fica gravado
## na cena empacotada.
func _team_cloth(node: Node3D, flip: float) -> void:
	if flip > 0:
		return
	var cloth := load(CLOTH_B) as Material
	var edited := false
	for child: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		for i: int in range(mi.get_surface_override_material_count()):
			var active := mi.get_active_material(i)
			if active != null and active.resource_path.ends_with(CLOTH_A):
				if not edited:
					_root.set_editable_instance(node, true)
					edited = true
				mi.set_surface_override_material(i, cloth)


## Pontos da floresta da borda (metade A): duas fileiras com passo e recuo variados por posicao,
## longe do enfeite, das tochas e da poca da cascata do canto.
func _rim_forest_points() -> PackedVector2Array:
	var avoid := _rim_decor_points()
	avoid.append_array(_rim_torch_points())
	var out := PackedVector2Array()
	for r: int in range(RIM_FOREST_ROWS.size()):
		var row: float = RIM_FOREST_ROWS[r]
		var t := RIM_SPAN.x + RIM_FOREST_STEP * 0.5 * r
		while t <= RIM_SPAN.y:
			var jitter := fposmod(t * 0.618 + row * 1.7, 1.0) - 0.5
			for p: Vector2 in [Vector2(t + jitter * 0.6, -row), Vector2(-row, t + jitter * 0.6)]:
				if p.distance_to(FALLS_A) < FALLS_CLEAR:
					continue
				if Array(avoid).any(func(q: Vector2) -> bool: return p.distance_to(q) < RIM_CLEAR):
					continue
				out.append(p)
			t += RIM_FOREST_STEP
	return out


func _rim_torch_points() -> PackedVector2Array:
	var out := PackedVector2Array()
	var t := RIM_SPAN.x + RIM_TORCH_STEP * 0.5
	while t <= RIM_SPAN.y:
		for p: Vector2 in [Vector2(t, -RIM_TORCH_ROW), Vector2(-RIM_TORCH_ROW, t)]:
			if not Array(_rim_decor_points()).any(
				func(q: Vector2) -> bool: return p.distance_to(q) < RIM_CLEAR
			):
				out.append(p)
		t += RIM_TORCH_STEP
	return out


func _rim_decor_points() -> PackedVector2Array:
	var out := PackedVector2Array([RIM_WATCHTOWER_A, RIM_BALLISTA_A])
	for c: Array in RIM_CRYSTALS_A:
		out.append(c[0])
	for b: Array in RIM_BARRICADES_A:
		out.append(b[0])
	return out


## Normal para dentro da arena no lado da borda de [param p] (metade A: lado N ou O).
func _inward(p: Vector2) -> Vector3:
	return Vector3(0, 0, 1) if absf(p.y) > absf(p.x) else Vector3(1, 0, 0)


## Cristal arcano do kit (F95; a borda desde o F96): material por variante (magenta, ciano,
## verde) em rodizio; so visual.
func _crystal(parent: Node3D, at: Vector3, large: bool, label: String, yaw: float) -> void:
	var size := "large" if large else "small"
	var crystal := _asset(parent, KIT + "kit_crystal_%s.glb" % size, label)
	crystal.transform = Transform3D(Basis(Vector3.UP, yaw), at)
	var variant: String = CRYSTAL_MATERIALS[_crystal_count % CRYSTAL_MATERIALS.size()]
	_crystal_count += 1
	if variant == CRYSTAL_MATERIALS[0]:
		return  # magenta ja vem do .import (use_external)
	# Instancia editavel: o override de superficie fica gravado na cena empacotada.
	_root.set_editable_instance(crystal, true)
	for node: Node in crystal.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for i: int in range(mi.get_surface_override_material_count()):
			var active := mi.get_active_material(i)
			if active != null and active.resource_path.ends_with("arcane_crystal_magenta.tres"):
				mi.set_surface_override_material(
					i, load(MATERIALS + "arcane_crystal_%s.tres" % variant)
				)


# --- ambientacao (cliente): luzes e particulas -------------------------------------------


func _build_ambience() -> void:
	var ambience := Node3D.new()
	ambience.name = "Ambience"
	ambience.set_script(load(AMBIENCE_SCRIPT))
	_add(_root, ambience)
	_light(
		ambience, "MagmaLight", Vector3(0, 1.5, 0), Color(1.0, 0.45, 0.1), MAGMA_LIGHT_RANGE, 2.5
	)
	for flip: float in [1.0, -1.0]:
		var tag := _team_tag(flip)
		var gate_at := _local(Vector2(GATE_S, 0), flip)
		var lateral := _rotate_if(LATERAL, flip)
		var forward := _rotate_if(AXIS_A, flip)
		for side: float in [1.0, -1.0]:
			var at := gate_at + lateral * (3.25 * side) + Vector3.UP * 2.4 - forward * 0.9
			_light(
				ambience,
				"Torch%s%d" % [tag, int(side > 0)],
				at,
				Color(1.0, 0.6, 0.25),
				TORCH_LIGHT_RANGE,
				1.2
			)
		for i: int in range(RIM_CRYSTALS_A.size()):
			var c: Array = RIM_CRYSTALS_A[i]
			var at := _world(c[0], flip) + Vector3.UP * 1.5
			var color := Color(0.85, 0.25, 0.95) if i == 0 else Color(0.2, 0.85, 1.0)
			_light(ambience, "CrystalLight%s%d" % [tag, i], at, color, CRYSTAL_LIGHT_RANGE, 1.0)
		var lagoon_at := _world(LAGOON_A, flip) + Vector3.UP * 1.0
		var lagoon_color := Color(0.3, 0.9, 1.0)
		_light(ambience, "LagoonLight%s" % tag, lagoon_at, lagoon_color, LAGOON_LIGHT_RANGE, 1.1)
		var torches := _rim_torch_points()
		for i: int in range(0, torches.size(), 2):
			var at := _world(torches[i], flip) + Vector3.UP * 2.5 + _inward(torches[i]) * flip * 0.5
			var color := Color(1.0, 0.6, 0.25)
			var label := "RimTorch%s%d" % [tag, i]
			_light(ambience, label, at, color, TORCH_LIGHT_RANGE, RIM_TORCH_LIGHT_ENERGY)
	for i: int in range(_lanterns.size()):
		var color := Color(1.0, 0.66, 0.34)
		var label := "Lantern%d" % i
		_light(ambience, label, _lanterns[i], color, LANTERN_LIGHT_RANGE, LANTERN_LIGHT_ENERGY)
	_lava_smoke(ambience)
	_embers(ambience)


func _light(
	parent: Node3D, label: String, at: Vector3, color: Color, range_u: float, energy: float
) -> void:
	var light := OmniLight3D.new()
	light.name = label
	light.position = at
	light.light_color = color
	light.omni_range = range_u
	light.light_energy = energy
	light.shadow_enabled = false
	_add(parent, light)


func _embers(parent: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Embers"
	particles.position = Vector3(0, 0.3, 0)
	particles.amount = EMBERS_AMOUNT
	particles.lifetime = 3.0
	particles.preprocess = 2.0
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = CRATER_RADIUS - 0.5
	material.direction = Vector3.UP
	material.spread = 15.0
	material.initial_velocity_min = 0.4
	material.initial_velocity_max = 1.0
	material.gravity = Vector3(0, 0.5, 0)
	material.scale_min = 0.6
	material.scale_max = 1.2
	material.color = Color(1.0, 0.55, 0.15)
	particles.process_material = material
	particles.draw_pass_1 = _puff_mesh(0.16, Color(1.0, 0.6, 0.2), true)
	_add(parent, particles)


## Fumaca suave saindo da lava: nasce quente (laranja fraco) sobre o magma, esfria para cinza,
## sobe devagar com turbulencia, cresce e some. Sprite redondo de borda macia, sem quina de quad.
func _lava_smoke(parent: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "LavaSmoke"
	particles.position = Vector3(0, 0.2, 0)
	particles.amount = SMOKE_AMOUNT
	particles.lifetime = SMOKE_LIFETIME
	particles.preprocess = SMOKE_LIFETIME
	particles.visibility_aabb = AABB(Vector3(-8, -1, -8), Vector3(16, 12, 16))
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = CRATER_RADIUS - 1.0
	material.direction = Vector3.UP
	material.spread = 10.0
	material.initial_velocity_min = 0.35
	material.initial_velocity_max = 0.8
	material.gravity = Vector3(0.12, 0.08, 0.06)
	material.damping_min = 0.05
	material.damping_max = 0.15
	material.angle_min = -180.0
	material.angle_max = 180.0
	material.angular_velocity_min = -8.0
	material.angular_velocity_max = 8.0
	material.turbulence_enabled = true
	material.turbulence_noise_strength = 0.5
	material.turbulence_noise_scale = 1.6
	material.scale_min = 0.8
	material.scale_max = 1.3
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.45))
	grow.add_point(Vector2(1.0, 1.9))
	var grow_texture := CurveTexture.new()
	grow_texture.curve = grow
	material.scale_curve = grow_texture
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.55, 1.0])
	ramp.colors = PackedColorArray(
		[
			Color(1.0, 0.5, 0.2, 0.0),
			Color(0.8, 0.45, 0.3, 0.45),
			Color(0.42, 0.38, 0.38, 0.36),
			Color(0.28, 0.28, 0.3, 0.0),
		]
	)
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	material.color_ramp = ramp_texture
	particles.process_material = material
	particles.draw_pass_1 = _puff_mesh(SMOKE_SIZE, Color.WHITE, false)
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(parent, particles)


## Sprite redondo e macio (alpha radial) para fumaca e brasa: [param glow] acende (aditivo,
## emissivo); sem ele a cor vem da rampa da particula e a luz da cena nao interfere (unshaded).
func _puff_mesh(size: float, color: Color, glow: bool) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(size, size)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if glow else BaseMaterial3D.BLEND_MODE_MIX
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	material.albedo_texture = _puff_texture()
	material.disable_receive_shadows = true
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.0
		material.emission_texture = material.albedo_texture
	mesh.material = material
	return mesh


## Alpha radial: branco opaco no centro, transparente na borda (curva suave, sem aresta de quad).
func _puff_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray(
		[Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0)]
	)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = PUFF_TEXTURE_SIZE
	texture.height = PUFF_TEXTURE_SIZE
	return texture


# --- construtores ------------------------------------------------------------------------


func _shape(parent: Node3D, shape: Shape3D, at: Vector3) -> CollisionShape3D:
	var node := CollisionShape3D.new()
	node.shape = shape
	node.position = at
	_add(parent, node)
	return node


func _asset(parent: Node3D, path: String, label: String) -> Node3D:
	var node := _scene(path).instantiate() as Node3D
	node.name = label
	_add(parent, node)
	return node


func _scene(path: String) -> PackedScene:
	if not _scenes.has(path):
		_scenes[path] = load(path)
	return _scenes[path]


func _group(label: String) -> Node3D:
	var existing := _root.get_node_or_null(label) as Node3D
	if existing:
		return existing
	var node := Node3D.new()
	node.name = label
	_add(_root, node)
	return node


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root


# --- geometria ---------------------------------------------------------------------------


## Ponto da base A em (s, l); flip -1 da a base B (rotacao de 180 graus).
func _local(p: Vector2, flip: float) -> Vector3:
	return _rotate_if(AXIS_A * p.x + LATERAL * p.y, flip)


## Ponto (x, z) do mundo da metade A; flip -1 gira para a B.
func _world(p: Vector2, flip: float) -> Vector3:
	return Vector3(p.x, 0, p.y) * flip


func _rotate_if(v: Vector3, flip: float) -> Vector3:
	return Vector3(v.x * flip, v.y, v.z * flip)


func _polar(azimuth_deg: float, r: float) -> Vector3:
	var a := deg_to_rad(azimuth_deg)
	return Vector3(-sin(a), 0, -cos(a)) * r


## Base com +X ao longo de [param along] (horizontal).
func _tangent_basis(along: Vector3) -> Basis:
	var dir := Vector3(along.x, 0, along.z).normalized()
	return Basis(Vector3.UP, atan2(-dir.z, dir.x))


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _team_tag(flip: float) -> String:
	return "A" if flip > 0 else "B"
