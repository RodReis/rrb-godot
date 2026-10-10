class_name KillRules
extends RefCounted
## Morte de heroi conforme a fase (GDB §3.3): se conta kill e tempo de respawn; o XP do matador
## e XpTable.pvp_kill_xp. Respawn desligado na morte subita e do F16.


## Kill so na fase 2 (I3).
static func counts_kill(state: MatchState.State) -> bool:
	return MatchState.is_phase2(state)


static func respawn_seconds(rules: MatchRules, state: MatchState.State) -> float:
	return rules.respawn_phase2 if MatchState.is_phase2(state) else rules.respawn_phase1
