class_name ArenaMapTexts
extends RefCounted
## Textos da tela Arena & Mapa (F33; FRONTEND-LAUNCHER §8.3 regra 2): todo numero, nome e contagem
## sai de shared/data (MatchRules, MonsterData) ou dos dados gerados da arena real (ArenaMapData),
## nunca do prototipo. A parte qualitativa vem da CONVENTION §4 e do GDB §5-§7. Funcoes puras,
## testaveis sem cena. Formato pt-BR: CompendiumFormat.

const SECONDS_PER_MINUTE: float = 60.0
const ACCENT_GOLD: StringName = &"gold"
const ACCENT_CYAN: StringName = &"cyan"
const ACCENT_ERROR: StringName = &"error"
const ACCENT_MUTED: StringName = &"muted"
## Pino do mapa por ponto de interesse: icone, rotulo curto, acento e se e um marco grande.
const PIN_STYLE: Dictionary[String, Array] = {
	ArenaMapPois.BASE_A: [UiIcons.SHIELD, "BASE A", ACCENT_CYAN, true],
	ArenaMapPois.BASE_B: [UiIcons.FORT, "BASE B", ACCENT_ERROR, true],
	ArenaMapPois.CRATER: [UiIcons.SKULL, "BOSS", ACCENT_GOLD, true],
	ArenaMapPois.CENTER_FIELDS: [UiIcons.SWORDS, "CENTRO", ACCENT_GOLD, false],
	ArenaMapPois.SIDE_FIELDS: [UiIcons.SWORDS, "CAMPO LATERAL", ACCENT_GOLD, false],
	ArenaMapPois.CORNER_FIELDS: [UiIcons.INVENTORY_2, "CAMPO DE CANTO", ACCENT_GOLD, false],
	ArenaMapPois.RIVER: [UiIcons.WATER_DROP, "RIO", ACCENT_CYAN, false],
	ArenaMapPois.BRIDGES: [UiIcons.ALT_ROUTE, "PONTE", ACCENT_MUTED, false],
	ArenaMapPois.TALL_GRASS: [UiIcons.GRASS, "MATO ALTO", ACCENT_CYAN, false],
}
## Chave do baú no marcador -> nome.
const CHEST_NAMES: Dictionary[String, String] = {
	"common": "baú comum", "reinforced": "baú reforçado", "rare": "baú raro"
}
const CHEST_PLURALS: Dictionary[String, String] = {
	"common": "baús comuns", "reinforced": "baús reforçados", "rare": "baús raros"
}


## Uma linha de regra do card de fase: icone, destaque em negrito e texto.
class Rule:
	extends RefCounted
	var icon: String = ""
	var title: String = ""
	var text: String = ""
	## Cor do icone: gold, cyan ou error.
	var accent: StringName = ACCENT_CYAN

	func _init(
		new_icon: String, new_title: String, new_text: String, new_accent: StringName
	) -> void:
		icon = new_icon
		title = new_title
		text = new_text
		accent = new_accent


## Card de detalhe de um ponto de interesse.
class PoiInfo:
	extends RefCounted
	var id: String = ""
	var tag: String = ""
	var title: String = ""
	var text: String = ""
	var icon: String = ""
	var accent: StringName = ACCENT_GOLD
	## Pares [rotulo, valor] (chips do canto direito do card).
	var facts: Array[PackedStringArray] = []


## Titulo e descricao do cabecalho; os minutos das duas fases vem de MatchRules.
static func header_title() -> String:
	return _t("Arena do Vale: Duelo 1v1")


static func header_description(rules: MatchRules) -> String:
	var farm := rules.phase1_duration / SECONDS_PER_MINUTE
	var zone := (rules.max_match_duration - rules.phase1_duration) / SECONDS_PER_MINUTE
	return (
		_t("Floresta, rio e cratera central • Duas fases: %s min de farm e %s min de zona mortal")
		% [CompendiumFormat.decimal(farm), CompendiumFormat.decimal(zone)]
	)


## "00:00 — 05:00".
static func phase_one_window(rules: MatchRules) -> String:
	return "%s — %s" % [CompendiumFormat.clock(0.0), CompendiumFormat.clock(rules.phase1_duration)]


static func phase_two_window(rules: MatchRules) -> String:
	return (
		"%s — %s"
		% [
			CompendiumFormat.clock(rules.phase1_duration),
			CompendiumFormat.clock(rules.max_match_duration)
		]
	)


## Fita do topo: [rotulo, valor, unidade, tipo do valor].
static func header_chips(rules: MatchRules) -> Array[Array]:
	return [
		[
			_t("DURAÇÃO MÁXIMA"),
			CompendiumFormat.clock(rules.max_match_duration),
			_t("2 tempos"),
			&"LnNumLgGold"
		],
		[
			_t("ZONA INICIAL"),
			CompendiumFormat.decimal(rules.zone_radius[0]),
			_t("u de raio"),
			&"LnNumLgCyan"
		],
		[_t("META DE KILLS"), str(rules.kill_goal), _t("1v1"), &"LnNumLgError"],
	]


## Faixa de rodape: [rotulo, valor, icone, acento]; totais contados da arena real e do catalogo.
static func strip_stats(data: ArenaMapData, catalog: CatalogService) -> Array[Array]:
	var chests := _sum(chest_totals(data))
	return [
		[_t("MONSTROS"), str(monster_total(data)), UiIcons.SWORDS, ACCENT_GOLD],
		[_t("BAÚS"), str(chests), UiIcons.INVENTORY_2, ACCENT_CYAN],
		[
			_t("MATO ALTO"),
			str(_group_count(data, ArenaMapPois.TALL_GRASS)),
			UiIcons.GRASS,
			ACCENT_CYAN
		],
		[
			_t("BOSS NEUTRO"),
			"1 %s" % catalog.boss().display_name,
			UiIcons.SKULL,
			ACCENT_ERROR,
		],
	]


## Baús do mapa por tipo (common, reinforced, rare), somando todos os campos.
static func chest_totals(data: ArenaMapData) -> Dictionary[String, int]:
	var totals: Dictionary[String, int] = {}
	for poi: Dictionary in data.pois:
		for group: Dictionary in poi["groups"]:
			var chests: Dictionary = group["chests"]
			for kind: String in chests:
				totals[kind] = int(totals.get(kind, 0)) + int(chests[kind])
	return totals


## Monstros da arena (o chefe incluso), somando todos os campos.
static func monster_total(data: ArenaMapData) -> int:
	var total := 0
	for poi: Dictionary in data.pois:
		for group: Dictionary in poi["groups"]:
			var monsters: Dictionary = group["monsters"]
			for id: String in monsters:
				total += int(monsters[id])
	return total


static func phase_one_rules(rules: MatchRules, data: ArenaMapData) -> Array[Rule]:
	var totals := chest_totals(data)
	var list: Array[Rule] = [
		Rule.new(
			UiIcons.LOCK,
			_t("Portões das bases fechados:"),
			(
				_t("só o time dono passa até as %s. O centro (ilha e anel) é disputado desde %s.")
				% [CompendiumFormat.clock(rules.phase1_duration), CompendiumFormat.clock(0.0)]
			),
			ACCENT_CYAN
		),
		Rule.new(
			UiIcons.INVENTORY_2,
			_t("%d baús no mapa:") % _sum(totals),
			(
				_t("%s; cada um oferece itens e você escolhe um. Não reabrem.")
				% _chest_summary(totals)
			),
			ACCENT_CYAN
		),
		Rule.new(
			UiIcons.SWORDS,
			_t("Morte na fase 1:"),
			(
				_t("renasce em %s s na própria base e não conta kill; quem matou ganha %d XP.")
				% [CompendiumFormat.decimal(rules.respawn_phase1), rules.phase1_kill_xp]
			),
			ACCENT_GOLD
		),
		Rule.new(
			UiIcons.SCHEDULE,
			_t("Rei Esqueleto:"),
			(
				_t("aviso global aos %s e surge aos %s na cratera central.")
				% [
					CompendiumFormat.clock(rules.boss_warning_time),
					CompendiumFormat.clock(rules.boss_spawn_time)
				]
			),
			ACCENT_GOLD
		),
	]
	return list


static func phase_two_rules(rules: MatchRules) -> Array[Rule]:
	var last := rules.zone_radius.size() - 2
	var damage_max := 0.0
	for fraction: float in rules.zone_damage_pct:
		damage_max = maxf(damage_max, fraction)
	var respawn_off := rules.phase1_duration + rules.respawn_off_at
	var list: Array[Rule] = [
		Rule.new(
			UiIcons.LOCK_OPEN,
			_t("Queda dos portões:"),
			(
				_t("às %s, com aviso de %s s; a transição já conta como fase 2.")
				% [
					CompendiumFormat.clock(rules.phase1_duration),
					CompendiumFormat.decimal(rules.transition_duration)
				]
			),
			ACCENT_ERROR
		),
		Rule.new(
			UiIcons.CRISIS_ALERT,
			_t("Zona de gás:"),
			(
				_t(
					(
						"círculo de %s u que encolhe até %s u; fora dele o dano vai de %s a %s do"
						+ " HP máx por segundo."
					)
				)
				% [
					CompendiumFormat.decimal(rules.zone_radius[0]),
					CompendiumFormat.decimal(rules.zone_radius[last]),
					CompendiumFormat.percent(rules.zone_damage_pct[0]),
					CompendiumFormat.percent(damage_max)
				]
			),
			ACCENT_ERROR
		),
		Rule.new(
			UiIcons.HEART_BROKEN,
			_t("Respawn:"),
			(
				_t("%s s até as %s; depois, morte súbita.")
				% [
					CompendiumFormat.decimal(rules.respawn_phase2),
					CompendiumFormat.clock(respawn_off)
				]
			),
			ACCENT_ERROR
		),
		Rule.new(
			UiIcons.EMOJI_EVENTS,
			_t("Vitória:"),
			(
				_t("quem fizer %d kills primeiro; às %s vence quem tem mais vida percentual.")
				% [rules.kill_goal, CompendiumFormat.clock(rules.max_match_duration)]
			),
			ACCENT_GOLD
		),
	]
	return list


## Rodape da fase 1: [rotulo, valor].
static func phase_one_note(rules: MatchRules) -> PackedStringArray:
	return PackedStringArray([_t("XP DO ABATE DE HERÓI"), "%d XP" % rules.phase1_kill_xp])


## Passos da zona da fase 2 para a barra: [instante do jogo "05:00", percentual da arena "74%",
## raio em u]. O ultimo ponto (raio 0) e a resolucao imediata, nao um passo.
static func zone_steps(rules: MatchRules) -> Array[PackedStringArray]:
	var steps: Array[PackedStringArray] = []
	var full := rules.zone_radius[0]
	for i: int in rules.zone_radius.size():
		if rules.zone_radius[i] <= 0.0:
			continue
		(
			steps
			. append(
				PackedStringArray(
					[
						CompendiumFormat.clock(rules.phase1_duration + rules.zone_times[i]),
						"%d%%" % roundi(rules.zone_radius[i] / full * CompendiumFormat.PERCENT),
						CompendiumFormat.decimal(rules.zone_radius[i]),
					]
				)
			)
		)
	return steps


## Card do ponto de interesse [param id]; vazio (id "") se o dado nao o tem.
static func poi_info(id: String, data: ArenaMapData, catalog: CatalogService) -> PoiInfo:
	var poi := data.poi(id)
	var info := PoiInfo.new()
	if poi.is_empty():
		return info
	var style: Array = PIN_STYLE[id]
	info.id = id
	info.icon = style[0]
	info.accent = style[2]
	var groups: Array = poi["groups"]
	var rules := catalog.match_rules
	match id:
		ArenaMapPois.BASE_A, ArenaMapPois.BASE_B:
			_base(info, id, groups[0], catalog)
		ArenaMapPois.CRATER:
			_crater(info, catalog)
		ArenaMapPois.CENTER_FIELDS:
			_center(info, groups, catalog)
		ArenaMapPois.SIDE_FIELDS:
			_side(info, groups, catalog)
		ArenaMapPois.CORNER_FIELDS:
			_corner(info, groups, catalog)
		ArenaMapPois.RIVER:
			_river(info, groups.size())
		ArenaMapPois.BRIDGES:
			_bridges(info, groups.size())
		ArenaMapPois.TALL_GRASS:
			_grass(info, groups.size(), rules)
	return info


## Rotulo do pino no mapa; o chefe leva a hora em que surge.
static func pin_label(id: String, rules: MatchRules) -> String:
	var label: String = PIN_STYLE[id][1]
	if id == ArenaMapPois.CRATER:
		return "%s %s" % [_t(label), CompendiumFormat.clock(rules.boss_spawn_time)]
	return _t(label)


static func _base(info: PoiInfo, id: String, group: Dictionary, catalog: CatalogService) -> void:
	var rules := catalog.match_rules
	var letter := "A" if id == ArenaMapPois.BASE_A else "B"
	info.tag = _t("SPAWN • TIME %s") % letter
	info.title = _t("Base %s") % letter
	info.text = (
		_t(
			(
				"Seu herói nasce e renasce aqui. O portão só deixa passar o time dono até as %s. A "
				+ "fonte cura %s do HP máx por segundo num raio de %s u, só na fase 1. Dentro dos "
				+ "muros: %s."
			)
		)
		% [
			CompendiumFormat.clock(rules.phase1_duration),
			CompendiumFormat.percent(rules.fountain_heal_pct),
			CompendiumFormat.decimal(rules.fountain_radius),
			_composition(group, catalog)
		]
	)
	info.facts = [
		PackedStringArray(
			[_t("PORTÃO"), _t("CAI ÀS %s") % CompendiumFormat.clock(rules.phase1_duration)]
		),
		PackedStringArray([_t("BAÚS"), _chests_text(group["chests"])]),
	]


static func _crater(info: PoiInfo, catalog: CatalogService) -> void:
	var rules := catalog.match_rules
	var boss := catalog.boss()
	info.tag = _t("ZONA CRÍTICA NEUTRA")
	info.title = _t("Cratera Central & %s") % boss.display_name
	info.text = (
		_t(
			(
				"Área de maior tensão da partida. O %s (%s HP, %s XP) surge aos %s, com aviso global "
				+ "aos %s, e derruba um item épico garantido. Se estiver vivo às %s, sai do mapa sem "
				+ "drop. Na fase 2, o centro é o último ponto da zona."
			)
		)
		% [
			boss.display_name,
			CompendiumFormat.thousands(roundi(boss.hp)),
			boss.xp,
			CompendiumFormat.clock(rules.boss_spawn_time),
			CompendiumFormat.clock(rules.boss_warning_time),
			CompendiumFormat.clock(rules.phase1_duration)
		]
	)
	info.facts = [
		PackedStringArray(
			[_t("DROP"), _t("ITEM ÉPICO (%s)") % CompendiumFormat.percent(boss.drop_epic_chance)]
		),
		PackedStringArray([_t("SURGE"), CompendiumFormat.clock(rules.boss_spawn_time)]),
	]


static func _center(info: PoiInfo, groups: Array, catalog: CatalogService) -> void:
	var rules := catalog.match_rules
	info.tag = _t("CENTRO CONTESTADO")
	info.title = _t("Ilha Central")
	info.text = (
		_t(
			(
				"Disputada pelos dois times desde %s: %d acampamentos com %s e baús raros (%s). Só as"
				+ " pontes dão acesso à ilha."
			)
		)
		% [
			CompendiumFormat.clock(0.0),
			groups.size(),
			_composition(groups[0], catalog),
			_rare_chance(rules)
		]
	)
	info.facts = [
		PackedStringArray([_t("CAMPOS"), str(groups.size())]),
		PackedStringArray([_t("BAÚS"), _chests_text(_merged(groups, "chests"))]),
	]


static func _side(info: PoiInfo, groups: Array, catalog: CatalogService) -> void:
	var rules := catalog.match_rules
	info.tag = _t("FARM DA METADE")
	info.title = _t("Campos Laterais")
	info.text = (
		_t(
			(
				"%d campos, dois em cada metade do mapa, cada um com %s e %s. Os monstros comuns "
				+ "renascem %s s depois de morrer, só na fase 1."
			)
		)
		% [
			groups.size(),
			_composition(groups[0], catalog),
			_chests_text(groups[0]["chests"]),
			CompendiumFormat.decimal(rules.monster_respawn_phase1)
		]
	)
	info.facts = [
		PackedStringArray([_t("CAMPOS"), str(groups.size())]),
		PackedStringArray(
			[_t("RESPAWN"), "%s s" % CompendiumFormat.decimal(rules.monster_respawn_phase1)]
		),
	]


static func _corner(info: PoiInfo, groups: Array, catalog: CatalogService) -> void:
	var rules := catalog.match_rules
	info.tag = _t("FARM NEUTRO")
	info.title = _t("Campos de Canto")
	info.text = (
		_t(
			(
				"%d campos neutros nas curvas das rotas de cima e de baixo, alcançáveis pelos dois "
				+ "times: %s e %s (%s raro, %s comum)."
			)
		)
		% [
			groups.size(),
			_composition(groups[0], catalog),
			_chests_text(groups[0]["chests"]),
			CompendiumFormat.percent(rules.reinforced_chest_rare_chance),
			CompendiumFormat.percent(rules.reinforced_chest_common_chance)
		]
	)
	info.facts = [
		PackedStringArray([_t("CAMPOS"), str(groups.size())]),
		PackedStringArray(
			[_t("RESPAWN"), "%s s" % CompendiumFormat.decimal(rules.monster_respawn_phase1)]
		),
	]


static func _river(info: PoiInfo, lagoons: int) -> void:
	info.tag = _t("BARREIRA")
	info.title = _t("Rio")
	info.text = (
		_t(
			(
				"O rio contorna a cratera e corre até %d lagoas. Ele bloqueia o movimento a pé; "
				+ "projéteis atravessam."
			)
		)
		% lagoons
	)
	info.facts = [PackedStringArray([_t("LAGOAS"), str(lagoons)])]


static func _bridges(info: PoiInfo, count: int) -> void:
	info.tag = _t("TRAVESSIA")
	info.title = _t("Pontes")
	info.text = (
		_t(
			(
				"As %d pontes são a única travessia do anel do rio, uma por metade: dão acesso à ilha"
				+ " central. As rotas de cima e de baixo contornam as lagoas por fora."
			)
		)
		% count
	)
	info.facts = [PackedStringArray([_t("PONTES"), str(count)])]


static func _grass(info: PoiInfo, count: int, rules: MatchRules) -> void:
	info.tag = _t("VISÃO")
	info.title = _t("Mato Alto")
	info.text = (
		_t(
			(
				"Quem está dentro de uma moita some para o adversário que está fora dela, a qualquer "
				+ "distância; quem está na mesma moita se vê. Atacar ou usar habilidade de dentro "
				+ "revela o herói por %s s. O raio de visão é de %s u."
			)
		)
		% [
			CompendiumFormat.decimal(rules.grass_reveal_time),
			CompendiumFormat.decimal(rules.vision_radius)
		]
	)
	info.facts = [
		PackedStringArray([_t("MOITAS"), str(count)]),
		PackedStringArray(
			[_t("REVELA"), "%s s" % CompendiumFormat.decimal(rules.grass_reveal_time)]
		),
	]


## "4 Esqueletos, 1 Esqueleto Guerreiro": monstros do campo pelo nome do catalogo.
static func _composition(group: Dictionary, catalog: CatalogService) -> String:
	var parts := PackedStringArray()
	var monsters: Dictionary = group["monsters"]
	var ids: Array = monsters.keys()
	ids.sort()
	for id: String in ids:
		var data := catalog.monster(StringName(id))
		var name := data.display_name if data != null else id
		parts.append("%d× %s" % [monsters[id], name])
	return ", ".join(parts)


## "6 baús comuns" / "2 baús reforçados"; vazio vira "sem baús".
static func _chests_text(chests: Dictionary) -> String:
	if chests.is_empty():
		return _t("sem baús")
	var parts := PackedStringArray()
	var kinds: Array = chests.keys()
	kinds.sort()
	for kind: String in kinds:
		var names: Dictionary[String, String] = CHEST_PLURALS if chests[kind] > 1 else CHEST_NAMES
		parts.append("%d %s" % [chests[kind], _t(names.get(kind, kind))])
	return ", ".join(parts)


static func _chest_summary(totals: Dictionary[String, int]) -> String:
	return _chests_text(totals)


## tr() e de instancia; os textos daqui sao estaticos e passam pelo servidor de traducao.
static func _t(text: String) -> String:
	return TranslationServer.translate(text)


static func _rare_chance(rules: MatchRules) -> String:
	return (
		_t("%s raro, %s comum, %s épico")
		% [
			CompendiumFormat.percent(rules.rare_chest_rare_chance),
			CompendiumFormat.percent(rules.rare_chest_common_chance),
			CompendiumFormat.percent(rules.rare_chest_epic_chance)
		]
	)


## Soma os conteudos (monsters ou chests) de todos os grupos em um so Dictionary.
static func _merged(groups: Array, key: String) -> Dictionary:
	var merged: Dictionary = {}
	for group: Dictionary in groups:
		var content: Dictionary = group[key]
		for item: String in content:
			merged[item] = int(merged.get(item, 0)) + int(content[item])
	return merged


static func _sum(counts: Dictionary[String, int]) -> int:
	var total := 0
	for kind: String in counts:
		total += counts[kind]
	return total


static func _group_count(data: ArenaMapData, id: String) -> int:
	return (data.poi(id).get("groups", []) as Array).size()
