class_name CompendiumFormat
extends RefCounted
## Textos do Bestiario e da Forja (F27; FRONTEND-LAUNCHER §8.3 regra 2): numero, nome e raridade
## saem dos Resources de shared/data — nunca do prototipo. Funcoes puras, testaveis sem cena.
## Formato pt-BR: virgula decimal, ponto de milhar.

const PERCENT: float = 100.0
const SECONDS_PER_MINUTE: int = 60
const THOUSAND_STEP: int = 3
const DECIMALS: int = 2
## Indice = MonsterData.Tier.
const TIER_NAMES: Array[String] = ["Tier 1", "Tier 2", "Tier 3", "Chefe"]
## Indice = ItemData.Slot.
const SLOT_NAMES: Array[String] = ["Arma", "Elmo", "Peitoral", "Botas"]
const NO_DROP: String = "—"
## Efeito da passiva por id (GDB §6.1); %s recebe o valor de ItemData.passive_value em percentual.
const PASSIVE_EFFECTS: Dictionary[StringName, String] = {
	&"fury": "ataques básicos causam +%s do HP restante do alvo como dano bônus"
}


## 1,5 / 2 / 0,9: duas casas no maximo, sem zero sobrando.
static func decimal(value: float) -> String:
	var text := String.num(value, DECIMALS)
	if text.contains("."):
		text = text.rstrip("0").rstrip(".")
	return text.replace(".", ",")


## 1800 -> "1.800".
static func thousands(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	for i: int in digits.length():
		if i > 0 and (digits.length() - i) % THOUSAND_STEP == 0:
			out += "."
		out += digits[i]
	return ("-" if value < 0 else "") + out


## Segundos -> "03:30".
static func clock(seconds: float) -> String:
	var total := roundi(seconds)
	return "%02d:%02d" % [floori(float(total) / SECONDS_PER_MINUTE), total % SECONDS_PER_MINUTE]


## Fracao -> percentual ("0,15" -> "15%").
static func percent(fraction: float) -> String:
	return decimal(fraction * PERCENT) + "%"


static func tier_name(tier: MonsterData.Tier) -> String:
	return TIER_NAMES[tier]


static func slot_name(slot: ItemData.Slot) -> String:
	return SLOT_NAMES[slot]


static func rarity_name(rarity: ItemData.Rarity) -> String:
	return ItemData.RARITY_NAMES[rarity]


## Atributos que o item soma, na ordem do GDB §6.1: ["+110 HP", "+12 DEF"].
static func item_stats(item: ItemData) -> PackedStringArray:
	var lines := PackedStringArray()
	var flat: Array[Array] = [
		[item.hp, "HP"],
		[item.defense, "DEF"],
		[item.attack, "ATQ"],
		[item.intelligence, "INT"],
		[item.agility, "AGI"],
	]
	for stat: Array in flat:
		if stat[0] > 0.0:
			lines.append("+%s %s" % [decimal(stat[0]), stat[1]])
	if item.agility_pct > 0.0:
		lines.append("+%s AGI" % percent(item.agility_pct))
	return lines


## "+15% HP máximo · +10 DEF": o que o conjunto completo soma.
static func bonus_text(bonus: SetBonusData) -> String:
	var parts := PackedStringArray()
	if bonus.max_hp_pct > 0.0:
		parts.append("+%s HP máximo" % percent(bonus.max_hp_pct))
	if bonus.defense > 0.0:
		parts.append("+%s DEF" % decimal(bonus.defense))
	if bonus.attack_speed_pct > 0.0:
		parts.append("+%s vel. de ataque" % percent(bonus.attack_speed_pct))
	if bonus.move_speed_pct > 0.0:
		parts.append("+%s vel. de movimento" % percent(bonus.move_speed_pct))
	return " · ".join(parts)


## "Fúria: ataques básicos causam +6% ..." ou "" (item sem passiva).
static func passive_text(item: ItemData) -> String:
	if item.passive.is_empty():
		return ""
	var effect: String = PASSIVE_EFFECTS.get(item.passive, "")
	if effect.is_empty():
		return item.passive_name
	return "%s: %s" % [item.passive_name, effect % percent(item.passive_value)]


## "Comum 35% · Raro 65%" ou "—".
static func drop_text(monster: MonsterData) -> String:
	var chances: Array[float] = [
		monster.drop_common_chance, monster.drop_rare_chance, monster.drop_epic_chance
	]
	var parts := PackedStringArray()
	for rarity: int in chances.size():
		if chances[rarity] > 0.0:
			parts.append("%s %s" % [ItemData.RARITY_NAMES[rarity], percent(chances[rarity])])
	return " · ".join(parts) if not parts.is_empty() else NO_DROP


## Alcance do golpe: a distancia, se o monstro ataca de longe; senao o corpo a corpo.
static func reach_text(monster: MonsterData) -> String:
	if monster.ranged_range > 0.0:
		return "À distância %s u" % decimal(monster.ranged_range)
	return "Corpo a corpo %s u" % decimal(monster.melee_range)


## "Alvo único" ou "Em área, raio 2,5 u" (e o empurrao, se houver).
static func strike_text(monster: MonsterData) -> String:
	var parts := PackedStringArray()
	parts.append(
		"Em área, raio %s u" % decimal(monster.area_radius) if monster.area_attack else "Alvo único"
	)
	if monster.knockback > 0.0:
		parts.append("empurra %s u" % decimal(monster.knockback))
	return " · ".join(parts)


## Onde o item de uma raridade aparece, com as chances de MatchRules e do chefe (GDB §6.2).
static func chest_sources(rarity: ItemData.Rarity, rules: MatchRules, boss: MonsterData) -> String:
	match rarity:
		ItemData.Rarity.COMMON:
			return (
				"Baús comuns (%d por base): %s de item comum"
				% [rules.common_chests_per_base, percent(rules.common_chest_item_chance)]
			)
		ItemData.Rarity.RARE:
			return (
				"Baús raros (%d no centro): %s · baús reforçados: %s"
				% [
					rules.rare_chests,
					percent(rules.rare_chest_rare_chance),
					percent(rules.reinforced_chest_rare_chance),
				]
			)
	return (
		"%s: %s garantido · baús raros: %s"
		% [
			boss.display_name,
			percent(boss.drop_epic_chance),
			percent(rules.rare_chest_epic_chance),
		]
	)
