class_name VictoryRules
extends RefCounted
## Fim da partida 1x1 na ordem do GDB §7.2 (CONVENTION §4.4): 1) meta de kills; 2) na morte
## subita (respawn desligado), quem fica sem vivos perde; 3) no colapso (10:00), resolucao na
## hora: maior HP% vence; empatado, mais kills na fase 2, mais dano causado em herois e sorteio
## deterministico pela seed da partida. Quando a partida acabaria e ninguem esta conectado, o fim
## e abandoned. Nunca empate (I2): todo desempate termina no sorteio.

const NO_WINNER: int = 0
const KILL_GOAL: StringName = &"kill_goal"
const ELIMINATION: StringName = &"elimination"
const COLLAPSE_HP: StringName = &"collapse_hp"
const COLLAPSE_KILLS: StringName = &"collapse_kills"
const COLLAPSE_DAMAGE: StringName = &"collapse_damage"
const COLLAPSE_DRAW: StringName = &"collapse_draw"
const ABANDONED: StringName = &"abandoned"


## Um jogador na avaliacao.
class Contender:
	extends RefCounted
	var peer: int = 0
	var alive: bool = true
	var connected: bool = true
	## HP / HP max (0 morto).
	var hp_pct: float = 0.0
	## Kills na fase 2.
	var kills: int = 0
	## Dano causado em herois na partida.
	var damage: int = 0


## reason vazio = a partida segue.
class Verdict:
	extends RefCounted
	var winner: int = NO_WINNER
	var reason: StringName = &""

	func is_over() -> bool:
		return reason != &""


static func evaluate(
	contenders: Array[Contender],
	kill_goal: int,
	sudden_death: bool,
	collapsed: bool,
	match_seed: int
) -> Verdict:
	var verdict := Verdict.new()
	var at_goal := contenders.filter(func(c: Contender) -> bool: return c.kills >= kill_goal)
	if not at_goal.is_empty():
		_decide(at_goal, match_seed, verdict)
		verdict.reason = KILL_GOAL
	elif sudden_death and _eliminated(contenders):
		var alive := contenders.filter(func(c: Contender) -> bool: return c.alive)
		_decide(alive if alive.size() == 1 else contenders, match_seed, verdict)
		verdict.reason = ELIMINATION
	elif collapsed:
		_decide(contenders, match_seed, verdict)
	if verdict.is_over() and not contenders.any(func(c: Contender) -> bool: return c.connected):
		verdict.winner = NO_WINNER
		verdict.reason = ABANDONED
	return verdict


## Alguem morreu e sobrou no maximo um vivo.
static func _eliminated(contenders: Array[Contender]) -> bool:
	var alive := contenders.filter(func(c: Contender) -> bool: return c.alive).size()
	return alive < contenders.size() and alive <= 1


## Vencedor do [param pool] por HP%, kills e dano, nessa ordem, e sorteio; o reason e o
## criterio que decidiu (o do colapso).
static func _decide(pool: Array, match_seed: int, verdict: Verdict) -> void:
	if pool.is_empty():
		verdict.reason = ABANDONED
		return
	var criteria: Array = [
		[COLLAPSE_HP, func(c: Contender) -> float: return c.hp_pct],
		[COLLAPSE_KILLS, func(c: Contender) -> float: return c.kills],
		[COLLAPSE_DAMAGE, func(c: Contender) -> float: return c.damage],
	]
	verdict.reason = COLLAPSE_DRAW
	for criterion: Array in criteria:
		pool = _best(pool, criterion[1])
		if pool.size() == 1:
			verdict.reason = criterion[0]
			break
	verdict.winner = _draw(pool, match_seed).peer


## Quem tem o maior valor de [param key] (todos os empatados).
static func _best(pool: Array, key: Callable) -> Array:
	var top: float = pool.map(key).max()
	return pool.filter(func(c: Contender) -> bool: return key.call(c) == top)


## Sorteio deterministico pela seed, independente da ordem de entrada.
static func _draw(pool: Array, match_seed: int) -> Contender:
	if pool.size() == 1:
		return pool[0]
	var ordered := pool.duplicate()
	ordered.sort_custom(func(x: Contender, y: Contender) -> bool: return x.peer < y.peer)
	var rng := RandomNumberGenerator.new()
	rng.seed = match_seed
	return ordered[rng.randi_range(0, ordered.size() - 1)]
