class_name MatchResultBuilder
extends RefCounted
## Monta o MatchResult que o servidor manda ao backend (POST /internal/matches/:id/result,
## ARCHITECTURE-LAUNCHER §4.2 passo 7) a partir do estado final da partida. Os campos seguem o
## contrato do backend (backend/src/matches/matches.dto.ts). `setActive`, `levelAtPhase1End`,
## `avgPingMs` e `teleportCount` (F29) so entram quando o servidor tem o valor: sao opcionais la.


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
	var entry := {
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
	_add_telemetry(entry, one)
	return entry


## Telemetria do F29: campo sem valor fica fora do resultado (o backend grava nulo).
static func _add_telemetry(entry: Dictionary, one: MatchStats.Player) -> void:
	if one.level_at_phase1_end != MatchStats.NO_VALUE:
		entry["levelAtPhase1End"] = one.level_at_phase1_end
	if one.avg_ping_ms != MatchStats.NO_VALUE:
		entry["avgPingMs"] = one.avg_ping_ms
	if one.teleports != MatchStats.NO_VALUE:
		entry["teleportCount"] = one.teleports
	if one.set_active != &"":
		entry["setActive"] = String(one.set_active)
