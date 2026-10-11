class_name DayNightRules
extends RefCounted
## Ciclo dia/noite (F49, SPEC-049 §2): a luz e funcao pura do tempo da partida. `progress` vem do
## relogio (MatchClock.elapsed), o sentido (dia -> noite ou noite -> dia) e sorteado pela seed e
## `night_amount` junta os dois numa unica curva: 0 = dia, 1 = noite. Sem efeito de jogo.


## Fracao da partida decorrida, em [0, 1]. Antes de comecar (selecao) e 0; passados os 600 s
## (morte subita) e 1; partida que acaba antes congela onde estava (o relogio para de contar).
static func progress(elapsed: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0
	return clampf(elapsed / duration, 0.0, 1.0)


## 0 = dia, 1 = noite. Dia -> noite sobe com o progresso; noite -> dia desce.
static func night_amount(p: float, day_to_night: bool) -> float:
	return p if day_to_night else 1.0 - p


## Verdadeiro se a partida comeca de dia (e termina de noite). [param forced] e o valor de
## `--daynight`: "day" e "night" vencem a seed; qualquer outro valor sorteia 50/50 por ela.
static func starts_at_day(match_seed: int, forced: String = LaunchArgs.DAYNIGHT_AUTO) -> bool:
	if forced == LaunchArgs.DAYNIGHT_DAY:
		return true
	if forced == LaunchArgs.DAYNIGHT_NIGHT:
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = match_seed
	return (rng.randi() & 1) == 0
