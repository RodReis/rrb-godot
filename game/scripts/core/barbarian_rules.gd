class_name BarbarianRules
extends RefCounted
## Regras puras do Barbaro (GDB §4.3, F53): dano da Execucao e pulsos do Rodopio.


## Dano bruto da Execucao: [param amount] (base + razoes, SkillRules.amount) + [param ratio] do
## [param missing_hp] do alvo. Antes da DEF: quem mitiga e o alvo.
static func execution_damage(amount: float, ratio: float, missing_hp: int) -> int:
	return roundi(amount + ratio * maxi(missing_hp, 0))


## O Rodopio pulsa no tick [param elapsed] (0 = inicio do giro): mesma cadencia da Chuva de
## Flechas (pulso no inicio e a cada [param interval] ticks, ate [param pulse_count]).
static func is_spin_pulse(elapsed: int, interval: int, pulse_count: int) -> bool:
	return RangerRules.is_rain_pulse(elapsed, interval, pulse_count)
