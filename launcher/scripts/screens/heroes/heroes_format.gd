class_name HeroesFormat
extends RefCounted
## Textos e numeros da Tela Herois (F71; FRONTEND-LAUNCHER §8.3 regra 2): atributos nos niveis 1
## e 10 pela mesma formula do servidor (Stats.attributes, sem itens), habilidades na ordem da HUD
## e icone de classe. Nada vem do prototipo. Funcoes puras, testaveis sem cena.

const LEVEL_LOW: int = 1
const LEVEL_HIGH: int = 10
const PORTRAITS_DIR: String = "res://shared/assets/ui/heroes/large/"
## Rotulo do ataque basico (o mesmo da HUD do Game: botao direito do mouse).
const BASIC_KEY: String = "RMB"
const STAT_HP: StringName = &"hp"
const STAT_DEFENSE: StringName = &"defense"
const STAT_ATTACK: StringName = &"attack"
const STAT_INTELLIGENCE: StringName = &"intelligence"
const STAT_AGILITY: StringName = &"agility"
const STAT_MOVE_SPEED: StringName = &"move_speed"
## Ordem e rotulo das linhas de atributo (GDB §2.2).
const STAT_LABELS: Dictionary[StringName, String] = {
	STAT_HP: "Vida",
	STAT_DEFENSE: "Defesa",
	STAT_ATTACK: "Ataque",
	STAT_INTELLIGENCE: "Inteligência",
	STAT_AGILITY: "Agilidade",
	STAT_MOVE_SPEED: "Velocidade",
}
## Classe (PRD §4.1) -> glifo. Classe sem glifo usa STARS.
const CLASS_ICONS: Dictionary[String, String] = {
	"Tanque": UiIcons.SHIELD,
	"Ranger": UiIcons.CRISIS_ALERT,
	"Algoz": UiIcons.VISIBILITY_OFF,
	"Mago": UiIcons.BOLT,
	"Engenheiro": UiIcons.SETTINGS,
	"Controle": UiIcons.GRASS,
	"Lutador": UiIcons.SWORDS,
}

static var _id_regex: RegEx = RegEx.create_from_string(HistoryFormat.ID_PATTERN)


## Uma linha de atributo: valor no nivel 1 e no nivel 10.
class StatRow:
	extends RefCounted
	var id: StringName
	var label: String
	var low: float
	var high: float

	func _init(stat_id: StringName, low_value: float, high_value: float) -> void:
		id = stat_id
		label = HeroesFormat.STAT_LABELS[stat_id]
		low = low_value
		high = high_value


## Uma habilidade com a tecla que a aciona; [member ultimate] e o R (a tecla pode ser religada).
class SkillSlot:
	extends RefCounted
	var key: String
	var skill: SkillData
	var ultimate: bool

	func _init(slot_key: String, slot_skill: SkillData, is_ultimate: bool = false) -> void:
		key = slot_key
		skill = slot_skill
		ultimate = is_ultimate


static func stat_rows(hero: HeroData) -> Array[StatRow]:
	var low := _attributes(hero, LEVEL_LOW)
	var high := _attributes(hero, LEVEL_HIGH)
	var rows: Array[StatRow] = []
	for id: StringName in STAT_LABELS:
		rows.append(StatRow.new(id, _stat(low, id), _stat(high, id)))
	return rows


## Maior valor de cada atributo no nivel 10 entre [param heroes]: a escala das barras.
static func maxima(heroes: Array[HeroData]) -> Dictionary[StringName, float]:
	var found: Dictionary[StringName, float] = {}
	for hero: HeroData in heroes:
		for row: StatRow in stat_rows(hero):
			found[row.id] = maxf(found.get(row.id, 0.0), row.high)
	return found


## Ataque basico (botao direito), Q, E e R, na ordem da HUD.
static func skill_slots(hero: HeroData) -> Array[SkillSlot]:
	var keys := InputActions.skill_labels()
	return [
		SkillSlot.new(BASIC_KEY, hero.basic_attack),
		SkillSlot.new(keys[0], hero.skill_q),
		SkillSlot.new(keys[1], hero.skill_e),
		SkillSlot.new(keys[2], hero.skill_r, true),
	]


## 600 -> "600", 71.5 -> "71,5", 1005 -> "1.005".
static func value_text(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return CompendiumFormat.thousands(roundi(value))
	return CompendiumFormat.decimal(snappedf(value, 0.1))


static func class_icon(role: String) -> String:
	return CLASS_ICONS.get(role, UiIcons.STARS)


## Retrato grande do heroi (render dos assets reais, §8.3 regra 3); nulo se nao existir.
static func portrait(hero_id: StringName) -> Texture2D:
	if not _id_regex.search(String(hero_id)):
		return null
	var path := "%s%s.png" % [PORTRAITS_DIR, hero_id]
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


static func _attributes(hero: HeroData, level: int) -> HeroAttributes:
	var no_items: Array[ItemData] = []
	var no_sets: Array[SetBonusData] = []
	return Stats.attributes(hero, level, no_items, no_sets)


static func _stat(attributes: HeroAttributes, id: StringName) -> float:
	match id:
		STAT_HP:
			return float(attributes.max_hp)
		STAT_DEFENSE:
			return attributes.defense
		STAT_ATTACK:
			return attributes.attack
		STAT_INTELLIGENCE:
			return attributes.intelligence
		STAT_AGILITY:
			return attributes.agility
		_:
			return attributes.move_speed
