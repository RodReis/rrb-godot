class_name OccultistRules
extends RefCounted
## Regras puras do Ocultista (GDB §2.2-F e §4.10, F77): DEF efetiva sob a Maldição, soma das marcas
## (teto 3), dano por pulso da Praga e do Círculo Profano e o compasso dos pulsos da Praga no alvo.
## Os dois números da Maldição moram aqui (e não no .tres) porque quem os aplica é o alvo — herói ou
## monstro —, que não tem o OccultistData do atacante; mudar exige mudar o GDB §2.2-F.

## DEF tirada por marca (GDB §2.2-F).
const DEFENSE_PER_STACK: float = 6.0
## Teto de marcas (decisão do PI, 2026-10-18).
const MAX_STACKS: int = 3


## DEF que entra na fórmula A sob [param stacks] marcas: o desconto vem depois dos bônus temporários
## (Grito de Guerra, itens), que o chamador já somou em [param defense]; nunca abaixo de 0.
static func effective_defense(defense: float, stacks: int) -> float:
	return maxf(defense - DEFENSE_PER_STACK * clampi(stacks, 0, MAX_STACKS), 0.0)


## Marcas depois de somar [param marks] a [param stacks], no teto.
static func add_stacks(stacks: int, marks: int) -> int:
	return clampi(stacks + maxi(marks, 0), 0, MAX_STACKS)


## Dano bruto do pulso da Praga que cai agora: o que [param left] ainda falta dividido pelos pulsos
## restantes ([param dot_ticks] no tick do pulso, ver [method is_dot_pulse]); o último leva o resto,
## então os pulsos somam exatamente o total aplicado.
static func pulse_damage(left: int, dot_ticks: int, interval: int) -> int:
	if left <= 0 or not is_dot_pulse(dot_ticks, interval):
		return 0
	@warning_ignore("integer_division")
	var pulses_left := (dot_ticks - 1) / interval + 1
	return roundi(float(left) / pulses_left)


## Dano bruto do pulso [param pulse] (0..[param count] - 1) do Círculo: fatias iguais, com o resto
## distribuído pelo arredondamento acumulado, então os pulsos somam exatamente [param total].
static func circle_pulse_damage(total: int, pulse: int, count: int) -> int:
	if count < 1 or pulse < 0 or pulse >= count or total <= 0:
		return 0
	return _share(total, pulse + 1, count) - _share(total, pulse, count)


## Ticks de vida da Praga ao ser aplicada: [param pulses] pulsos a cada [param interval] ticks.
static func dot_duration_ticks(pulses: int, interval: int) -> int:
	return maxi(pulses, 0) * maxi(interval, 0)


## O tick que vai descontar [param dot_ticks] causa um pulso: o valor depois do desconto é múltiplo
## do intervalo. Aplicada com N pulsos, o 1º cai [param interval] ticks depois do golpe e o último
## fecha a duração.
static func is_dot_pulse(dot_ticks: int, interval: int) -> bool:
	return dot_ticks > 0 and interval >= 1 and (dot_ticks - 1) % interval == 0


## Parte [param n] de [param parts] de [param total], arredondada ao inteiro mais próximo.
static func _share(total: int, n: int, parts: int) -> int:
	return roundi(float(total) * n / parts)
