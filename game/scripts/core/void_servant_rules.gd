class_name VoidServantRules
extends RefCounted
## Regras puras do Servo do Vazio (R do Ocultista, GDB §4.10, F78): HP e dano pelo rank e pela INT
## do Ocultista, prioridade do alvo, ponto de nascimento e compasso da reavaliacao do alvo.

## Quem o servo escolheu (choose): nenhum (segue o Ocultista), o alvo travado do Ocultista, um
## heroi inimigo ou um monstro.
enum Pick { NONE, LOCKED, HERO, MONSTER }


static func max_hp(data: ServantData, rank: int, intelligence: float) -> int:
	return roundi(SkillData.at_rank(data.base_hp, rank) + data.hp_intelligence_ratio * intelligence)


static func damage(data: ServantData, rank: int, intelligence: float) -> int:
	return roundi(
		SkillData.at_rank(data.base_damage, rank) + data.damage_intelligence_ratio * intelligence
	)


## (Pick, indice) a partir de [param from], tudo no plano e a ate [param reach]: o alvo travado em
## [param locked_at] (se [param has_locked]); senao o heroi mais perto de [param heroes]; senao o
## monstro mais perto de [param monsters]. Quem chama ja filtrou vivos e vistos pelo Ocultista.
static func choose(
	from: Vector3,
	has_locked: bool,
	locked_at: Vector3,
	heroes: PackedVector3Array,
	monsters: PackedVector3Array,
	reach: float
) -> Vector2i:
	if has_locked and EngineerRules.nearest(from, [locked_at], reach) == 0:
		return Vector2i(Pick.LOCKED, 0)
	var hero := EngineerRules.nearest(from, heroes, reach)
	if hero >= 0:
		return Vector2i(Pick.HERO, hero)
	var monster := EngineerRules.nearest(from, monsters, reach)
	if monster >= 0:
		return Vector2i(Pick.MONSTER, monster)
	return Vector2i(Pick.NONE, -1)


## Onde o servo [param index] (0 ou 1) nasce: [param offset] a direita (0) ou a esquerda (1) de
## [param center].
static func side_point(center: Vector3, right: Vector3, offset: float, index: int) -> Vector3:
	return center + right * (offset if index == 0 else -offset)


## Reavalia o alvo no tick [param elapsed] desde a invocacao (0 = invocacao).
static func is_retarget_tick(elapsed: int, interval: int) -> bool:
	return interval <= 1 or elapsed % interval == 0
