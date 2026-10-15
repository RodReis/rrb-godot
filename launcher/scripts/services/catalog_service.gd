class_name CatalogService
extends RefCounted
## Catalogo do Launcher (ARCHITECTURE-LAUNCHER §3.3): carrega res://shared/data/** — herois,
## itens, bonus de conjunto, monstros e regras — e e a fonte unica dos numeros do Bestiario e da
## Forja (GDB vence o prototipo, ADR-0004). Nada de numero escrito em tela. Sincrono: sao poucos
## .tres locais.

const DATA_DIR: String = "res://shared/data/"
const HEROES_DIR: String = DATA_DIR + "heroes/"
const MONSTERS_DIR: String = DATA_DIR + "monsters/"
const ITEM_CATALOG_PATH: String = DATA_DIR + "items/catalog.tres"
const XP_CURVE_PATH: String = DATA_DIR + "rules/xp_table.tres"
const MATCH_RULES_PATH: String = DATA_DIR + "rules/match_pacing.tres"
## Render da arena e pontos de interesse (F33), gerados por tools/ui/render_arena_map.gd.
const ARENA_MAP_PATH: String = "res://shared/assets/ui/arena_map.tres"
## ResourceLoader.list_directory marca pasta com "/" no fim.
const DIR_MARK: String = "/"

var heroes: Array[HeroData] = []
var monsters: Array[MonsterData] = []
var items: Array[ItemData] = []
var set_bonuses: Array[SetBonusData] = []
var xp_curve: XpCurve
var match_rules: MatchRules
## Pontos de interesse da arena (tela Arena & Mapa); nulo se o arquivo nao carrega.
var arena_map: ArenaMapData

var _loaded: bool = false


## Le tudo de shared/data; chamar de novo nao duplica nada.
func load_all() -> void:
	# Fora da guarda: "Tentar de novo" recupera o mapa mesmo com o resto do catalogo ja carregado.
	if arena_map == null:
		arena_map = load(ARENA_MAP_PATH) as ArenaMapData
	if _loaded:
		return
	heroes.assign(_load_dir(HEROES_DIR))
	monsters.assign(_load_dir(MONSTERS_DIR))
	var catalog := load(ITEM_CATALOG_PATH) as ItemCatalog
	items.assign(catalog.items if catalog != null else [])
	set_bonuses.assign(catalog.set_bonuses if catalog != null else [])
	xp_curve = load(XP_CURVE_PATH) as XpCurve
	match_rules = load(MATCH_RULES_PATH) as MatchRules
	if match_rules != null:
		_sort_heroes()
	_loaded = (
		not heroes.is_empty()
		and not monsters.is_empty()
		and not items.is_empty()
		and not set_bonuses.is_empty()
		and xp_curve != null
		and match_rules != null
	)


## Tudo carregou? Sem isso as telas do compendio mostram o estado de erro.
func is_loaded() -> bool:
	return _loaded


## Nulo se nao existe.
func hero(id: StringName) -> HeroData:
	for data: HeroData in heroes:
		if data.id == id:
			return data
	return null


func monster(id: StringName) -> MonsterData:
	for data: MonsterData in monsters:
		if data.id == id:
			return data
	return null


## Quantas pecas ativam cada conjunto, sem repetir e em ordem (ex.: [3]).
func set_piece_counts() -> PackedInt32Array:
	var counts := PackedInt32Array()
	for bonus: SetBonusData in set_bonuses:
		if not counts.has(bonus.pieces_required):
			counts.append(bonus.pieces_required)
	counts.sort()
	return counts


## O chefe da arena (tier BOSS); o ultimo monstro se nenhum for chefe.
func boss() -> MonsterData:
	for data: MonsterData in monsters:
		if data.tier == MonsterData.Tier.BOSS:
			return data
	return monsters.back()


func item(id: StringName) -> ItemData:
	for data: ItemData in items:
		if data.id == id:
			return data
	return null


func set_bonus(set_id: StringName) -> SetBonusData:
	for bonus: SetBonusData in set_bonuses:
		if bonus.set_id == set_id:
			return bonus
	return null


## Itens do slot, na ordem do catalogo (raridade crescente dentro de cada conjunto).
func items_in_slot(slot: ItemData.Slot) -> Array[ItemData]:
	var found: Array[ItemData] = []
	for data: ItemData in items:
		if data.slot == slot:
			found.append(data)
	return found


func items_of_set(set_id: StringName) -> Array[ItemData]:
	var found: Array[ItemData] = []
	for data: ItemData in items:
		if data.set_id == set_id:
			found.append(data)
	return found


## Um card por especie (a variante de canto divide o do golem), do tier menor ao chefe.
func monster_species() -> Array[MonsterSpecies]:
	var by_id: Dictionary[StringName, MonsterSpecies] = {}
	var ordered: Array[MonsterSpecies] = []
	for data: MonsterData in monsters:
		var key := data.species if not data.species.is_empty() else data.id
		if not by_id.has(key):
			var group := MonsterSpecies.new(key)
			by_id[key] = group
			ordered.append(group)
		by_id[key].add(data)
	# sort_custom nao e estavel: o desempate por id fixa a ordem dos cards.
	ordered.sort_custom(
		func(a: MonsterSpecies, b: MonsterSpecies) -> bool:
			if a.lead().tier != b.lead().tier:
				return a.lead().tier < b.lead().tier
			return String(a.id) < String(b.id)
	)
	return ordered


## Os herois padrao da partida (MatchRules.default_heroes) primeiro, o resto por id.
func _sort_heroes() -> void:
	var defaults := match_rules.default_heroes
	heroes.sort_custom(
		func(a: HeroData, b: HeroData) -> bool:
			var rank_a := defaults.find(a.id) if a.id in defaults else defaults.size()
			var rank_b := defaults.find(b.id) if b.id in defaults else defaults.size()
			if rank_a != rank_b:
				return rank_a < rank_b
			return String(a.id) < String(b.id)
	)


func _load_dir(dir: String) -> Array[Resource]:
	var found: Array[Resource] = []
	for entry: String in ResourceLoader.list_directory(dir):
		if entry.ends_with(DIR_MARK) or not entry.ends_with(".tres"):
			continue
		var resource := load(dir + entry)
		if resource != null:
			found.append(resource)
	return found
