class_name VisibilityRules
extends RefCounted
## Mato alto (F32, CONVENTION §4.7, GDB §7.3): heroi dentro de uma moita some para quem esta fora
## dela, a qualquer distancia (sem revelacao por proximidade); quem esta na mesma moita ve.
## Atacar ou usar skill revela por grass_reveal_time. Regra pura; o servidor filtra a replicacao
## (Concealment), o monstro e o bot perguntam aqui antes de mirar (invariante de honestidade).

## Grupo das Area3D das moitas (SPEC-007 §2), cada uma com um CollisionShape3D de BoxShape3D.
const GROUP: StringName = &"tall_grass"
## Fora de toda moita.
const NO_GRASS: int = -1
## Fora de toda nuvem de fumaca (mascara de bits, um por Ladina).
const NO_SMOKE: int = 0
## Meia aresta da caixa unitaria de grass_box.
const HALF: float = 0.5


## Transformacao que leva o mundo para a caixa unitaria da moita: dentro dela, |x| e |z| <= 0,5.
## [param shape_xform] = global_transform do CollisionShape3D; [param size] = tamanho do box.
static func grass_box(shape_xform: Transform3D, size: Vector3) -> Transform3D:
	return shape_xform.scaled_local(size).affine_inverse()


## Indice da moita (em [param boxes], de grass_box) que contem [param point] no plano, ou NO_GRASS.
## A altura nao conta: a moita vale do chao ao ceu.
static func grass_at(point: Vector3, boxes: Array[Transform3D]) -> int:
	for i: int in boxes.size():
		var local := boxes[i] * point
		if absf(local.x) <= HALF and absf(local.z) <= HALF:
			return i
	return NO_GRASS


## Heroi na moita [param grass] some para quem esta em [param observer_grass], a nao ser na mesma
## moita ou revelado ([param reveal_ticks] > 0).
static func is_hidden(grass: int, observer_grass: int, reveal_ticks: int) -> bool:
	return grass != NO_GRASS and grass != observer_grass and reveal_ticks <= 0


## Fumaca da Ladina (F58, ADR-0013): a nuvem de [param center] e [param radius] cobre
## [param point], no plano (a altura nao conta, como na moita).
static func smoke_covers(center: Vector3, point: Vector3, radius: float) -> bool:
	return CombatRules.in_radius(center, point, radius)


## Bit da nuvem [param index] na mascara de fumaca de um ponto.
static func smoke_bit(index: int) -> int:
	return 1 << index


## Como is_hidden com moita e fumaca: cada lado e (moita, mascara de nuvens) em um Vector2i. A nuvem
## vale como moita; quem esta dentro de uma moita e de uma nuvem conta nas duas (decisao do PI em
## 2026-10-13): some para quem nao esta em nenhuma delas, e quem esta em qualquer uma o ve.
static func is_hidden_in(zones: Vector2i, observer_zones: Vector2i, reveal_ticks: int) -> bool:
	var in_grass := zones.x != NO_GRASS
	var covered := in_grass or zones.y != NO_SMOKE
	var shares := (in_grass and zones.x == observer_zones.x) or (zones.y & observer_zones.y) != 0
	return covered and not shares and reveal_ticks <= 0


static func reveal_ticks(rules: MatchRules, tickrate: int) -> int:
	return SkillRules.seconds_to_ticks(rules.grass_reveal_time, tickrate)


## Atacou ou usou skill no tick: alguma recarga (basico, Q, E, R) subiu. O Rolamento zera o
## basico, mas sobe a do E. [param counts_e] falso: a subida do E nao conta (lancar a Bomba de
## Fumaca nao revela a Ladina, ADR-0013); basico, Q e R contam normalmente.
static func acted(before: Vector4i, after: Vector4i, counts_e: bool = true) -> bool:
	var e_up := counts_e and after.z > before.z
	return after.x > before.x or after.y > before.y or e_up or after.w > before.w


## Cliente: o heroi remoto aparece se o servidor nao o esconde deste peer e ja chegou estado
## de [param shown_tick] em diante — antes disso o node ainda tem a posicao de quando sumiu.
static func shown_on_client(hidden: bool, shown_tick: int, last_state_tick: int) -> bool:
	return not hidden and last_state_tick >= shown_tick
