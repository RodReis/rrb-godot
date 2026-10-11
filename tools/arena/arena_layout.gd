extends "arena_dressing.gd"
## Medidas do layout da Ilha (SPEC-046) e predicados do rio, separados do builder para o
## terreno (arena_terrain.gd) e a colisao (build_arena.gd) usarem a mesma geometria. So dado
## e geometria: nada aqui monta nodes.

# Escala (SPEC-046 §1): quadrado |x|, |z| <= 40; 4 muros retos em 41.
const ARENA_HALF: float = 40.0
const BORDER_THICKNESS: float = 2.0
const BORDER_HEIGHT: float = 4.0

# Rio (SPEC-046 §2.1): anel 14-18 u + 2 bracos em arco + 2 lagoas. Colisao do anel e dos bracos
# em setores poligonais de 2,5 graus (erro de corda < 1 cm); o anel e recortado pela borda reta
# das 2 pontes, o braco pelo circulo interno do anel (meio-plano por setor).
const RING_IN: float = 14.0
const RING_OUT: float = 18.0
const RING_MID: float = 16.0
const RIVER_HALF: float = 2.0
const RIVER_SECTOR_DEG: float = 2.5
const RIVER_HEIGHT: float = 2.0
## Braco NO: arco de circulo (eixo) de centro ARM_CENTER_A e raio ARM_RADIUS, da juncao com o
## anel (azimute 45, r 16) ate o centro da lagoa NO, barriga para NE. O SE e a rotacao.
const ARM_CENTER_A: Vector2 = Vector2(-22.5, -6.2)
const ARM_RADIUS: float = 12.35
const ARM_JOIN_AZIMUTH: float = 45.0
## Graus a mais no comeco do arco, para dentro do anel, garantindo a juncao sem fresta.
const ARM_OVERLAP_DEG: float = 12.0

const LAGOON_RADIUS: float = 5.0
## Meia largura util das pontes (largura efetiva 5 u; nominal 4 u).
const BRIDGE_HALF: float = 2.5
const BRIDGE_CENTER: float = 16.0
## So na MID: SO (metade A) e NE (metade B).
const BRIDGE_AZIMUTHS: Array[float] = [135.0, 315.0]
const BRIDGE_AZIMUTH_A: float = 135.0

# Cratera (SPEC-046 §2.2 = SPEC-044): 8 pilares no raio 6 u, 4 entradas de 4 u.

const CRATER_ENTRIES: Array[float] = [45.0, 135.0, 225.0, 315.0]
const PILLAR_RADIUS: float = 1.4
const PILLAR_HEIGHT: float = 3.0
## Angulo entre o centro de uma entrada e o pilar vizinho: 12 sin(a) = 4 + 2 x 1,4.
const PILLAR_OFFSET_DEG: float = 34.52

# Base A (canto SO) em coordenadas locais: s ao longo de centro -> spawn A (-24, +24); l para a
# esquerda de quem esta no spawn olhando o centro. A base B e a rotacao de 180 graus.

const GATE_HALF: float = 2.5
const ARC_STEP_DEG: float = 8.0
## Muros de fechamento (SPEC-046 §2.4): dos extremos do arco ate a borda, em (x, z) do mundo.
const CLOSURE_WALLS_A: Array[Array] = [
	[Vector2(-33, 15), Vector2(-40, 15)],
	[Vector2(-15, 33), Vector2(-15, 40)],
]
const BASE_WALLS: Array[Array] = [
	[Vector2(29, -2), Vector2(29, 2)],
	[Vector2(27.5, 6), Vector2(27.5, 10)],
	[Vector2(27.5, -6), Vector2(27.5, -10)],
]
const BASE_T1: Array[Vector2] = [
	Vector2(31, 6), Vector2(31, -6), Vector2(26.5, 4.5), Vector2(26.5, -4.5)
]
const BASE_T2: Vector2 = Vector2(25.2, 0)
const BASE_CHESTS: Array[Vector2] = [
	Vector2(29.5, 8.5),
	Vector2(29.5, -8.5),
	Vector2(33, 9),
	Vector2(33, -9),
	Vector2(24.5, 7.5),
	Vector2(24.5, -7.5),
]
## Fonte no canto esquerdo da base (#74), em (s, l).
const FOUNTAIN_LOCAL: Vector2 = Vector2(32, 11)
## Torres do castelo ao lado do portao (l).
const GATE_TOWER_L: float = 4.0
## Casas de pedra atras do spawn (decisao do PI 2026-10-10: kit novo), em (s, l) com yaw; tem
## colisao (caixa) para o heroi nao atravessar a parede — ficam fora de toda rota.
const HOUSES_LOCAL: Array[Array] = [[Vector2(37.5, 7.0), 0.35], [Vector2(37.5, -7.0), -0.35]]
const HOUSE_HALF: Vector2 = Vector2(1.9, 1.6)
const HOUSE_HEIGHT: float = 3.4
## Torreao no canto da ilha, atras da borda (bastiao do chassi), em (x, z) do mundo.
const KEEP_A: Vector2 = Vector2(-45, 45)
## Escala do torreao e das torres (moldura do F40, PI 2026-10-11: castelos maiores).
const KEEP_SCALE: float = 1.25
const TOWER_SCALE: float = 1.2
## Cortina do castelo ao longo da borda da base ate a face do torreao (so visual: o colisor e o
## muro da borda).
const CURTAIN_A: Array[Array] = [
	[Vector2(-41, 15), Vector2(-41, 43.5)],
	[Vector2(-15, 41), Vector2(-43.5, 41)],
]

# Campos laterais (F36 na SPEC-046 §2.5), metade A em (x, z) do mundo: A-top entre TOP (O) e MID,
# A-bot entre MID e BOT (S). O bolso em volta e dos bolsoes de selva (jungle.json, F40).
const SIDE_FIELDS: Array[Array] = [["Top", Vector2(-26, -4)], ["Bot", Vector2(4, 26)]]
const SIDE_T1_OFFSETS: Array[Vector2] = [Vector2(-2.5, -1.5), Vector2(2.5, -1.5)]
const SIDE_T2_OFFSET: Vector2 = Vector2(0, 1.5)
const SIDE_CHEST_OFFSETS: Array[Vector2] = [Vector2(-3, 2.5), Vector2(3, 2.5)]

# Patio da ponte da metade A (s radial, l lateral): moita de um lado e rocha do outro, fora da
# banda MID de 8 u (|l| > 4; SPEC-046 §2.7 herdava l 4,6 da SPEC-044, que invadiria 2 u).
const YARD_GRASS_LOCAL: Vector2 = Vector2(19.5, 6.5)
## Rocha do patio: fora da rota portao -> BOT (trilha 7 do jungle.json, o builder confere) e a
## 0,5 u da margem do rio; a SPEC-046 §2.7 a punha em (19,5, -4,6), dentro dessa rota.
const YARD_ROCK_LOCAL: Vector2 = Vector2(17.1, -10.0)
const YARD_GRASS_SIZE: Vector2 = Vector2(4, 4)
## Moita de lagoa (SPEC-046 §2.7), em (x, z) do mundo, fora do corredor TOP.
const LAGOON_GRASS_A: Vector2 = Vector2(-30, -26)

# Centro (azimute, raio): campos em 45/225 (equidistantes das pontes); raros em 45/225 e 90/270.
const FIELD_AZIMUTHS: Array[float] = [45.0, 225.0]
const FIELD_RADIUS: float = 10.0
const FIELD_SPREAD_DEG: float = 15.0
const FIELD_CHEST_RADIUS: float = 12.5
const LATERAL_CHESTS: Array[Vector2] = [Vector2(90, 8), Vector2(270, 8)]
const CENTER_ROCKS: Array[Vector2] = [
	Vector2(0, 9.5), Vector2(180, 9.5), Vector2(112, 9.5), Vector2(292, 9.5)
]
const CENTER_GRASS: Array[Vector2] = [Vector2(90, 12), Vector2(270, 12)]
const CENTER_GRASS_SIZE: Vector2 = Vector2(4, 3)

# Corredores livres (SPEC-046 §2.3), retangulos (x0, z0, x1, z1) da metade A; BOT e a rotacao.
# MID: 8 u entre o portao e a ponte; na ilha, 4 u (a largura da entrada da cratera, que a
# propria spec fixa). O rio (pontes de 5 u) fica fora da conferencia da MID.
const CORRIDOR_TOP_A: Array[Rect2] = [
	Rect2(-40, -40, 8, 55),  # O: x -40..-32, z -40..15
	Rect2(-40, -40, 55, 8),  # N: z -40..-32, x -40..15
]
const MID_OUTER_HALF: float = 4.0
const MID_OUTER_RANGE: Vector2 = Vector2(18.0, 20.71)
const MID_ISLAND_HALF: float = 2.0
const MID_ISLAND_RANGE: Vector2 = Vector2(-14.0, 14.0)
## Profundidade de invasao tolerada (u): o fim do arco (extremo em x -33, SPEC-046 §2.4) e o muro
## de fechamento encostam na banda TOP; a largura util fica >= 6,5 u nesse ponto.
const CORRIDOR_TOLERANCE: float = 1.5

# Bloqueios.
const WALL_HEIGHT: float = 2.5
const WALL_THICKNESS: float = 0.8
const ROCK_RADIUS: float = 1.3
const GRASS_HEIGHT: float = 1.2

# --- rio: predicados -------------------------------------------------


func _is_bridge(p: Vector2) -> bool:
	for azimuth: float in BRIDGE_AZIMUTHS:
		var axis := _flat(_polar(azimuth, 1.0))
		var s := p.dot(axis)
		var l := absf(p.dot(Vector2(-axis.y, axis.x)))
		if s > RING_IN - 1.0 and s < RING_OUT + 1.0 and l <= BRIDGE_HALF:
			return true
	return false


## Angulos (rad) do arco do braco NO em torno de ARM_CENTER_A: x = no anel (com a sobra),
## y = no centro da lagoa. O arco e o curto, percorrido de x para y.
func _arm_angles() -> Vector2:
	var join := _flat(_polar(ARM_JOIN_AZIMUTH, RING_MID)) - ARM_CENTER_A
	var end := LAGOON_A - ARM_CENTER_A
	var start := join.angle()
	var sweep := wrapf(end.angle() - start, -PI, PI)
	return Vector2(start - signf(sweep) * deg_to_rad(ARM_OVERLAP_DEG), start + sweep)


func _in_arm(p: Vector2) -> bool:
	var v := p - ARM_CENTER_A
	var d := v.length()
	if d < ARM_RADIUS - RIVER_HALF or d > ARM_RADIUS + RIVER_HALF:
		return false
	var angles := _arm_angles()
	var sweep := angles.y - angles.x
	var t := wrapf(v.angle() - angles.x, -PI, PI)
	return t * signf(sweep) >= 0.0 and absf(t) <= absf(sweep)


func _in_lagoon(p: Vector2) -> bool:
	return p.distance_to(LAGOON_A) <= LAGOON_RADIUS


func _is_river(p: Vector2, with_bridges: bool) -> bool:
	var r := p.length()
	if r <= RING_IN:
		return false
	if r <= RING_OUT:
		return not (with_bridges and _is_bridge(p))
	return _in_arm(p) or _in_arm(-p) or _in_lagoon(p) or _in_lagoon(-p)
