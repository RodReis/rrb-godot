class_name RangerRules
extends RefCounted
## Regras puras da Arqueira (GDB §4.2): voo da flecha, perfuracao do Q e Chuva de Flechas do R.


## Fator de dano depois de atravessar [param pierced] alvos: -[param decay] por alvo, nunca abaixo
## de [param minimum] (Q: 100, 85, 70, 55, 40 %...).
static func pierce_factor(pierced: int, decay: float, minimum: float) -> float:
	return maxf(1.0 - decay * maxi(pierced, 0), minimum)


## Quanto a flecha anda neste tick: [param speed] por tick, sem passar do [param max_range].
static func flight_step(speed: float, max_range: float, traveled: float, tickrate: int) -> float:
	return clampf(max_range - traveled, 0.0, speed / tickrate)


## Centro da Chuva: [param distance] (ja validada) na direcao [param aim], ate [param cast_range].
## Sem mira, no proprio heroi.
static func rain_center(
	origin: Vector3, aim: Vector3, distance: float, cast_range: float
) -> Vector3:
	var flat := Vector3(aim.x, 0.0, aim.z)
	if flat.is_zero_approx():
		return origin
	return origin + flat.normalized() * clampf(distance, 0.0, cast_range)


## A Chuva pulsa no tick [param elapsed] (0 = lancamento): a cada [param interval] ticks, ate
## [param pulse_count] pulsos.
static func is_rain_pulse(elapsed: int, interval: int, pulse_count: int) -> bool:
	if elapsed < 0 or interval < 1:
		return false
	return elapsed % interval == 0 and elapsed < interval * pulse_count


## Lentidao de um pulso: dura ate o pulso seguinte. O alvo aplica no tick seguinte e desconta no
## mesmo tick (Hero._rollback_tick), entao precisa de um tick a mais para nao ter buraco.
static func rain_slow_ticks(interval: int) -> int:
	return interval + 1
