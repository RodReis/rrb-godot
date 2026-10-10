class_name KillTracker
extends RefCounted
## Placar da partida no servidor (GDB §3.3, §7.2): kill so na fase 2 (I3), XP do abate ao
## matador e dano causado em herois por jogador (desempate do colapso; tela de fim no F18). O
## dano sai do registro de cada heroi (Hero.hero_damage_from), que sobrevive a ressimulacao.

var _kills: Dictionary = {}  # peer -> kills na fase 2


## Abate de heroi por [param killer] (0 = monstro ou zona). Verdadeiro se contou kill.
func score(killer: int, state: MatchState.State) -> bool:
	if killer == 0 or not KillRules.counts_kill(state):
		return false
	_kills[killer] = kills(killer) + 1
	return true


func kills(peer: int) -> int:
	return _kills.get(peer, 0)


## XP do matador: fixo na fase 1, 150 + 20 x nivel do alvo na fase 2 (GDB §3.3).
static func reward_xp(rules: MatchRules, state: MatchState.State, victim_level: int) -> int:
	return XpTable.pvp_kill_xp(rules, MatchState.is_phase2(state), victim_level)


func damage_dealt(peer: int, heroes: Array[Hero]) -> int:
	var total := 0
	for hero: Hero in heroes:
		if hero.peer_id != peer:
			total += hero.hero_damage_from(peer)
	return total
