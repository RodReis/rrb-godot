class_name XpTable
extends RefCounted
## Nivel por XP (GDB §3.2), catch-up e XP de abate (GDB §3.3).


static func max_level(curve: XpCurve) -> int:
	return curve.cumulative_xp.size()


static func xp_for_level(curve: XpCurve, level: int) -> int:
	return curve.cumulative_xp[clampi(level, 1, max_level(curve)) - 1]


static func level_for_xp(curve: XpCurve, xp: int) -> int:
	var level := 1
	for i: int in range(1, curve.cumulative_xp.size()):
		if xp >= curve.cumulative_xp[i]:
			level = i + 1
	return level


static func catch_up_multiplier(curve: XpCurve, level: int, opponent_level: int) -> float:
	if level <= opponent_level - curve.catch_up_level_gap:
		return 1.0 + curve.catch_up_bonus
	return 1.0


## XP de monstro/objetivo ja com catch-up, arredondado.
static func monster_xp(curve: XpCurve, base_xp: int, level: int, opponent_level: int) -> int:
	return roundi(base_xp * catch_up_multiplier(curve, level, opponent_level))


static func pvp_kill_xp(rules: MatchRules, is_phase2: bool, target_level: int) -> int:
	if not is_phase2:
		return rules.phase1_kill_xp
	return rules.phase2_kill_xp_base + rules.phase2_kill_xp_per_level * target_level


## Ranks tipicos (Q, E, R) no [param level] (GDB §3.2).
static func typical_ranks(curve: XpCurve, level: int) -> Vector3i:
	var i := clampi(level, 1, max_level(curve)) - 1
	return Vector3i(curve.typical_q_rank[i], curve.typical_e_rank[i], curve.typical_r_rank[i])
