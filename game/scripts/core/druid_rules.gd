class_name DruidRules
extends RefCounted
## Regras puras do Protetor da Selva (GDB §4.7, F74): cura da Pocao Verde por pulso e o pulso das
## duas zonas (mesmo compasso da Chuva de Flechas).


## Cura do pulso [param pulse] (0..[param pulse_count] - 1) de uma cura total de [param total]:
## fatias iguais, com o resto distribuido pelo arredondamento acumulado, entao os pulsos somam
## exatamente [param total]. Pulso fora da faixa cura 0.
static func pulse_heal(total: int, pulse: int, pulse_count: int) -> int:
	if pulse_count < 1 or pulse < 0 or pulse >= pulse_count or total <= 0:
		return 0
	return _share(total, pulse + 1, pulse_count) - _share(total, pulse, pulse_count)


## A zona pulsa no tick [param elapsed] desde o lancamento (0 = o 1o tick depois dele): a cada
## [param interval] ticks, ate [param pulse_count] pulsos.
static func is_pulse(elapsed: int, interval: int, pulse_count: int) -> bool:
	return RangerRules.is_rain_pulse(elapsed, interval, pulse_count)


## Indice do pulso no tick [param elapsed] (0..pulse_count - 1); -1 se nao e tick de pulso.
static func pulse_index(elapsed: int, interval: int, pulse_count: int) -> int:
	if not is_pulse(elapsed, interval, pulse_count):
		return -1
	return elapsed / interval


## Raizes Vivas: o chefe so toma o dano; heroi e monstro comum ficam enraizados.
static func roots(is_boss: bool) -> bool:
	return not is_boss


## Parte [param n] de [param parts] de [param total], arredondada ao inteiro mais proximo.
static func _share(total: int, n: int, parts: int) -> int:
	return roundi(float(total) * n / parts)
