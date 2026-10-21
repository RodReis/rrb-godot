class_name CarrascoRules
extends RefCounted
## Regras puras do Carrasco (GDB §4.11, F98, SPEC-098): fator do dano tomado (Couraca e Penitencia),
## Dor, raiz x lentidao da explosao, cura distribuida, execucao e o toque que dispara o recast.


## Fator do dano tomado depois da DEF: a Couraca so no basico de heroi; canalizando a Penitencia,
## tudo perde [param mitigation] (os dois se multiplicam).
static func taken_factor(
	hero_basic: bool, cuirass: float, channeling: bool, mitigation: float
) -> float:
	var factor := cuirass if hero_basic else 1.0
	if channeling:
		factor *= 1.0 - mitigation
	return factor


## [param damage] (ja depois da DEF) vezes [param factor], arredondado e nunca negativo.
static func taken(damage: int, factor: float) -> int:
	return maxi(roundi(maxi(damage, 0) * factor), 0)


## Dor depois de ganhar [param gain], no maximo [param pain_max].
static func gain_pain(pain: int, gain: int, pain_max: int) -> int:
	return mini(pain + maxi(gain, 0), pain_max)


## Tick [param elapsed] da canalizacao (0 = o do inicio) ganha Dor: a cada [param interval] ticks.
static func is_pain_pulse(elapsed: int, interval: int) -> bool:
	return interval > 0 and elapsed > 0 and elapsed % interval == 0


## A explosao da Penitencia prende (raiz) com Dor >= [param min_pain]; senao, deixa lento.
static func explosion_roots(pain: int, min_pain: int) -> bool:
	return pain >= min_pain


## Valor da Penitencia (cura total ou dano da explosao): base + fracao do ATK + [param per_pain] por
## ponto de Dor.
static func with_pain(base: float, ratio: float, attack: float, per_pain: float, pain: int) -> int:
	return roundi(base + ratio * attack + per_pain * pain)


## Cura ja devida depois de [param elapsed] dos [param total_ticks] da canalizacao (distribuida por
## igual, arredondada para baixo; no ultimo tick, o total).
static func heal_due(total: int, elapsed: int, total_ticks: int) -> int:
	if total_ticks <= 0:
		return 0
	return total * mini(elapsed, total_ticks) / total_ticks


## Correntes do Julgamento: [param hp] abaixo de [param ratio] do HP maximo morre; imunidade a dano
## (Bencao Inviolavel) bloqueia.
static func executes(hp: int, max_hp: int, ratio: float, immune: bool) -> bool:
	return not immune and hp > 0 and hp < max_hp * ratio


## Botao apertado neste tick e solto no anterior (o input chega segurado, nao como toque).
static func pressed(now: bool, held_before: bool) -> bool:
	return now and not held_before


## O toque de Q lanca o projetil dos Espinhos se a janela do recast esta aberta.
static func recasts(window_ticks: int, tapped: bool) -> bool:
	return tapped and window_ticks > 0
