class_name TargetInfo
extends RefCounted
## O que a moldura do alvo travado mostra (F66, SPEC-066 §4): nome, etiqueta e HP do heroi
## adversario (nome do heroi, nivel) ou do monstro (nome, tier). Alvo desconhecido volta vazio.


static func name_of(target: Combatant) -> String:
	if target is Hero:
		return (target as Hero).hero_data.display_name
	if target is Monster:
		return (target as Monster).data.display_name
	return ""


## Nivel do heroi ("Nv 3"); tier do monstro (T1 a T3, CHEFE para o boss).
static func tag_of(target: Combatant) -> String:
	if target is Hero:
		return TranslationServer.translate("Nv %d") % (target as Hero).level
	if target is Monster:
		var tier := (target as Monster).data.tier
		if tier == MonsterData.Tier.BOSS:
			return TranslationServer.translate("CHEFE")
		return "T%d" % (tier + 1)
	return ""


## HP atual e maximo.
static func hp_of(target: Combatant) -> Vector2i:
	if target is Hero:
		var hero := target as Hero
		return Vector2i(hero.hp, hero.attributes.max_hp)
	if target is Monster:
		var monster := target as Monster
		return Vector2i(monster.hp, roundi(monster.data.hp))
	return Vector2i.ZERO
