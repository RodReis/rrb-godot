class_name Stats
extends RefCounted
## Formulas de atributos e combate do GDB §2.2. Fonte unica para servidor e Forja (I5).

## Dano recebido = bruto x DEFENSE_SCALE / (DEFENSE_SCALE + DEF).
const DEFENSE_SCALE: float = 100.0
const CDR_PER_INTELLIGENCE: float = 0.5
const CDR_CAP_PERCENT: float = 30.0
## Percentual por ponto de AGI na velocidade de movimento e de ataque.
const MOVE_SPEED_PER_AGILITY: float = 0.4
const ATTACK_SPEED_PER_AGILITY: float = 0.6
const PERCENT: float = 100.0


static func mitigation(defense: float) -> float:
	var def := maxf(defense, 0.0)
	return def / (DEFENSE_SCALE + def)


static func damage_after_defense(raw_damage: float, defense: float) -> float:
	return raw_damage * (1.0 - mitigation(defense))


static func cdr_percent(intelligence: float) -> float:
	return minf(CDR_CAP_PERCENT, maxf(intelligence, 0.0) * CDR_PER_INTELLIGENCE)


static func effective_cooldown(base_cooldown: float, intelligence: float) -> float:
	return base_cooldown * (1.0 - cdr_percent(intelligence) / PERCENT)


## [param bonus_pct] (conjunto Cacador) multiplica o valor final (decisao do PI 2026-10-09).
static func move_speed(base_speed: float, agility: float, bonus_pct: float) -> float:
	return base_speed * (1.0 + agility * MOVE_SPEED_PER_AGILITY / PERCENT) * (1.0 + bonus_pct)


static func attack_interval(base_interval: float, agility: float, bonus_pct: float) -> float:
	return base_interval / (1.0 + agility * ATTACK_SPEED_PER_AGILITY / PERCENT) / (1.0 + bonus_pct)


## Atributos finais. AGI% dos itens multiplica (base + AGI plana); HP max arredonda ao
## inteiro (decisao do PI 2026-10-09). Nivel < 1 conta como 1.
static func attributes(
	hero: HeroData, level: int, items: Array[ItemData], set_bonuses: Array[SetBonusData]
) -> HeroAttributes:
	var growth := float(maxi(level, 1) - 1)
	var hp := hero.base_hp + hero.hp_per_level * growth
	var defense := hero.base_defense + hero.defense_per_level * growth
	var attack := hero.base_attack + hero.attack_per_level * growth
	var intelligence := hero.base_intelligence + hero.intelligence_per_level * growth
	var agility := hero.base_agility + hero.agility_per_level * growth
	var agility_pct := 0.0
	for item: ItemData in items:
		hp += item.hp
		defense += item.defense
		attack += item.attack
		intelligence += item.intelligence
		agility += item.agility
		agility_pct += item.agility_pct
	var hp_pct := 0.0
	var attack_speed_pct := 0.0
	var move_speed_pct := 0.0
	for bonus: SetBonusData in SetBonus.active(items, set_bonuses):
		hp_pct += bonus.max_hp_pct
		defense += bonus.defense
		attack_speed_pct += bonus.attack_speed_pct
		move_speed_pct += bonus.move_speed_pct

	var a := HeroAttributes.new()
	a.max_hp = roundi(hp * (1.0 + hp_pct))
	a.defense = defense
	a.attack = attack
	a.intelligence = intelligence
	a.agility = agility * (1.0 + agility_pct)
	a.move_speed = move_speed(hero.base_move_speed, a.agility, move_speed_pct)
	var base_interval := SkillData.at_rank(hero.basic_attack.cooldown, 1)
	a.attack_interval = attack_interval(base_interval, a.agility, attack_speed_pct)
	a.cdr_percent = cdr_percent(intelligence)
	a.mitigation = mitigation(defense)
	return a
