class_name SkillRules
extends RefCounted
## Numeros das habilidades a partir de SkillData e dos atributos do heroi (GDB §4). Usado
## pelo servidor e, depois, pela Forja e pelo bestiario.


## Dano (ou escudo) do [param rank]: base + razoes de ATK, INT e HP maximo.
static func amount(skill: SkillData, rank: int, attrs: HeroAttributes) -> float:
	return (
		SkillData.at_rank(skill.base_amount, rank)
		+ skill.attack_ratio * attrs.attack
		+ skill.intelligence_ratio * attrs.intelligence
		+ skill.max_hp_ratio * attrs.max_hp
	)


## Cooldown do [param rank] com CDR da INT (Stats), em ticks.
static func cooldown_ticks(skill: SkillData, rank: int, intelligence: float, tickrate: int) -> int:
	var seconds := Stats.effective_cooldown(SkillData.at_rank(skill.cooldown, rank), intelligence)
	return seconds_to_ticks(seconds, tickrate)


## Arredonda ao tick mais proximo (evita 7,6 s x 30 virar 229 por erro de ponto flutuante).
static func seconds_to_ticks(seconds: float, tickrate: int) -> int:
	return roundi(seconds * tickrate)


## Rank aprendido e nivel do heroi >= o minimo daquele rank.
static func can_use(skill: SkillData, rank: int, hero_level: int) -> bool:
	if rank < 1 or rank > skill.max_rank or skill.required_hero_level.is_empty():
		return false
	var levels := skill.required_hero_level
	return hero_level >= levels[clampi(rank - 1, 0, levels.size() - 1)]
