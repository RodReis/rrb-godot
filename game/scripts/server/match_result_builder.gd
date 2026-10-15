class_name MatchResultBuilder
extends RefCounted
## Monta o MatchResult que o servidor manda ao backend (POST /internal/matches/:id/result,
## ARCHITECTURE-LAUNCHER §4.2 passo 7) a partir do estado final da partida. Os campos seguem o
## contrato do backend (backend/src/matches/matches.dto.ts). Ficam de fora, por ainda nao existirem
## no Game, `setActive`, `levelAtPhase1End` e `avgPingMs` (todos opcionais la).


## [param users]: conta de cada peer (AuthSession.users). Jogador sem conta ou sem heroi escolhido
## (caiu antes da selecao) nao tem linha: o backend recusa heroId vazio. [param match_seed] vai
## junto para auditoria; o backend ignora.
static func build(
	stats: MatchStats,
	winner: int,
	reason: StringName,
	match_seed: int,
	users: Dictionary[int, String]
) -> Dictionary:
	var players: Array[Dictionary] = []
	for one: MatchStats.Player in stats.players():
		var entry := _player(one, users)
		if not entry.is_empty():
			players.append(entry)
	var winner_user: Variant = null
	if winner != VictoryRules.NO_WINNER and users.has(winner):
		winner_user = users[winner]
	return {
		"winnerUserId": winner_user,
		"endReason": String(reason),
		"durationS": roundi(stats.duration),
		"seed": match_seed,
		"players": players,
	}


static func _player(one: MatchStats.Player, users: Dictionary[int, String]) -> Dictionary:
	var hero := Ids.to_name(one.hero)
	if hero == &"" or not users.has(one.peer):
		return {}
	return {
		"userId": users[one.peer],
		"heroId": String(hero),
		"kills": one.kills,
		"deaths": one.deaths,
		"finalLevel": one.level,
		"damageDealt": one.hero_damage,
		"damageTaken": one.damage_taken,
		"monstersKilled": one.monsters,
		"chestsOpened": one.chests,
		"bossKill": one.boss_killed,
	}
