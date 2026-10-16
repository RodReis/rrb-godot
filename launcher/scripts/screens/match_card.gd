class_name MatchCard
extends PanelContainer
## Cartao de duelo do feed do Historico (prototipo "Historico de Partidas — Duelos", F26). A
## partida mais recente e o destaque (cartao grande, placar em moldura, fatos do fim); as demais
## sao linhas compactas. Faixa lateral e selo seguem o resultado: vitoria dourada, derrota
## vermelha, interrompida cinza. So dado real do backend (§8.3): herois dos dois lados, placar de
## kills, nivel final, duracao, motivo de fim, boss e conjunto ativo; sem ELO, KDA de exemplo nem
## itens (o Game nao grava item final). Texto de heroi e conjunto vem de shared/data.

const WIN: String = "win"
const LOSS: String = "loss"
const INTERRUPTED: String = "interrupted"
## Sufixo dos tipos do Theme (LnMatchCard<Sufixo>, LnResult<Sufixo>) por resultado.
const KEYS: Dictionary[String, String] = {WIN: "Win", LOSS: "Loss", INTERRUPTED: "None"}
const BADGE_TEXTS: Dictionary[String, String] = {
	WIN: "VITÓRIA", LOSS: "DERROTA", INTERRUPTED: "PARTIDA INTERROMPIDA"
}
const BADGE_ICONS: Dictionary[String, String] = {
	WIN: UiIcons.EMOJI_EVENTS, LOSS: UiIcons.CLOSE, INTERRUPTED: UiIcons.WARNING
}
## w-16 h-16 do destaque e w-12 h-12 da linha compacta.
const PORTRAIT_LG: Vector2 = Vector2(64, 64)
const PORTRAIT_SM: Vector2 = Vector2(48, 48)
## Os dois lados do duelo dividem a largura (md:col-span-5 / 1 / 5 do prototipo).
const SIDE_RATIO: float = 5.0
const SCORE_SEPARATOR: String = UiIcons.SWORDS
## Lado do duelo guarda a coluna de texto aqui, para o placar de kills entrar depois do nome.
const INFO_META: StringName = &"info"
## O backend nao devolve as mortes do rival.
const NO_DEATHS: int = -1

var match_id: String = ""
var result: String = ""
var highlighted: bool = false


## [param summary] a partida; [param highlight] true = cartao de destaque (o mais recente).
func bind(summary: MatchSummary, highlight: bool) -> void:
	match_id = summary.match_id
	result = summary.result
	highlighted = highlight
	for child: Node in get_children():
		child.queue_free()
	var key: String = KEYS.get(summary.result, "None")
	theme_type_variation = StringName("LnMatchCard%s%s" % [key, "Lg" if highlight else ""])
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd" if highlight else &"LnVGapSm"
	add_child(column)
	column.add_child(_header(summary, key))
	if summary.result == INTERRUPTED:
		column.add_child(_interrupted_text(summary))
	elif highlight:
		var board := PanelContainer.new()
		board.theme_type_variation = &"LnMatchBoard"
		board.add_child(_duel(summary, PORTRAIT_LG))
		column.add_child(board)
		column.add_child(_facts(summary))
	else:
		column.add_child(_duel(summary, PORTRAIT_SM))


## Selo, "Duelo #ID", data e a direita a duracao (chip no destaque, texto na linha compacta).
func _header(summary: MatchSummary, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	var badge := Label.new()
	badge.theme_type_variation = StringName("LnResult%s%s" % [key, "Lg" if highlighted else ""])
	badge.text = "%s  %s" % [BADGE_ICONS.get(summary.result, ""), tr(BADGE_TEXTS[summary.result])]
	badge.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(badge)
	row.add_child(
		_label(tr("Duelo %s") % HistoryFormat.short_id(summary.match_id), &"LnHeadlineSm")
	)
	var when := HistoryFormat.played_at(summary.played_at)
	if not when.is_empty():
		row.add_child(_label("• " + when, &"LnNum"))
	row.add_child(_spacer())
	var duration := HistoryFormat.duration(summary.duration_s)
	if not highlighted and summary.result != INTERRUPTED:
		var reason := HistoryFormat.end_reason(summary.end_reason)
		if not reason.is_empty():
			row.add_child(_label(tr(reason), &"LnNumCyan"))
	if not duration.is_empty():
		row.add_child(_duration(duration))
	return row


func _duration(text: String) -> Control:
	if not highlighted:
		return _label(text, &"LnNum")
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"LnChipLowest"
	chip.size_flags_vertical = SIZE_SHRINK_CENTER
	var inner := HBoxContainer.new()
	inner.theme_type_variation = &"LnHGapXs"
	chip.add_child(inner)
	inner.add_child(_label(UiIcons.TIMER, &"LnIconSmCyan"))
	inner.add_child(_label(text, &"LnNum"))
	return chip


## Heroi, placar e heroi do oponente ("VS INIMIGO"): [eu | placar | rival].
func _duel(summary: MatchSummary, portrait: Vector2) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	var mine := _side(summary.me.hero_id, summary.me.final_level, portrait, true)
	_add_stats(mine.get_meta(INFO_META), summary.me.kills, summary.me.deaths)
	mine.size_flags_horizontal = SIZE_EXPAND_FILL
	mine.size_flags_stretch_ratio = SIDE_RATIO
	row.add_child(mine)
	row.add_child(_score(summary))
	var rival := _side(
		summary.opponent.hero_id,
		summary.opponent.final_level,
		portrait,
		false,
		summary.opponent.nickname
	)
	_add_stats(rival.get_meta(INFO_META), summary.opponent.kills, NO_DEATHS)
	rival.size_flags_horizontal = SIZE_EXPAND_FILL
	rival.size_flags_stretch_ratio = SIDE_RATIO
	row.add_child(rival)
	return row


## Retrato + coluna de texto. Meu lado: retrato a esquerda; o do rival espelhado (texto a direita).
## `nickname`: so o rival ("" = conta anterior ao F35 ou partida sem oponente: fica so o heroi).
func _side(
	hero_id: String, level: int, portrait: Vector2, mine: bool, nickname: String = ""
) -> HBoxContainer:
	var side := HBoxContainer.new()
	side.theme_type_variation = &"LnHGapMd"
	var info := VBoxContainer.new()
	info.theme_type_variation = &"LnVGapXs"
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	info.size_flags_vertical = SIZE_SHRINK_CENTER
	if not nickname.is_empty():
		# F35: o oponente e identificado pelo #nickname (nunca pelo e-mail) e, abaixo, pelo heroi.
		var tag := _label(NicknameRules.display(nickname), &"LnNumGold")
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if mine else HORIZONTAL_ALIGNMENT_RIGHT
		info.add_child(tag)
	var title := HBoxContainer.new()
	title.theme_type_variation = &"LnHGapXs"
	title.alignment = BoxContainer.ALIGNMENT_BEGIN if mine else BoxContainer.ALIGNMENT_END
	var hero_name := tr(HistoryFormat.hero_name(hero_id))
	if mine:
		hero_name = tr("%s (Você)") % hero_name
	title.add_child(_label(hero_name, &"LnHeadlineSmGold" if mine else &"LnHeadlineSm"))
	var role := HistoryFormat.hero_role(hero_id)
	if not role.is_empty():
		var badge := _label(tr(role), &"LnBadgeRoleMe" if mine else &"LnBadgeRoleRival")
		badge.size_flags_vertical = SIZE_SHRINK_CENTER
		title.add_child(badge)
	info.add_child(title)
	side.set_meta(INFO_META, info)
	var frame := _portrait(hero_id, level, portrait, mine)
	if mine:
		side.add_child(frame)
		side.add_child(info)
	else:
		side.add_child(info)
		side.add_child(frame)
	return side


## "5 Kills / 3 Mortes" (mortes so no meu lado: o backend nao devolve as do rival).
func _add_stats(info: VBoxContainer, kills: int, deaths: int) -> void:
	var line := HBoxContainer.new()
	line.theme_type_variation = &"LnHGapXs"
	var mine := deaths != NO_DEATHS
	line.alignment = BoxContainer.ALIGNMENT_BEGIN if mine else BoxContainer.ALIGNMENT_END
	line.add_child(_label(tr("%d Kills") % kills, &"LnNumText"))
	if mine:
		line.add_child(_label("/", &"LnNumOutline"))
		line.add_child(_label(tr("%d Mortes") % deaths, &"LnNumError"))
	info.add_child(line)


## Placar "5 ⚔ 3" em moldura e, no destaque, a legenda FINAL.
func _score(summary: MatchSummary) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.theme_type_variation = &"LnVGapXs"
	box.size_flags_vertical = SIZE_SHRINK_CENTER
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"LnScoreChip"
	chip.size_flags_horizontal = SIZE_SHRINK_CENTER
	var text := _label(
		"%d  %s  %d" % [summary.me.kills, SCORE_SEPARATOR, summary.opponent.kills],
		&"LnHeadlineSmGold"
	)
	text.name = "Score"
	chip.add_child(text)
	box.add_child(chip)
	if highlighted:
		var caption := _label(tr("FINAL"), &"LnNum")
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(caption)
	return box


## Moldura do retrato (rounded-xl, recorta a imagem) com a etiqueta de nivel no canto.
func _portrait(hero_id: String, level: int, size: Vector2, mine: bool) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.theme_type_variation = &"LnPortrait"
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	frame.size_flags_vertical = SIZE_SHRINK_CENTER
	frame.custom_minimum_size = size
	var holder := Control.new()
	holder.custom_minimum_size = size
	frame.add_child(holder)
	var texture := HistoryFormat.portrait(hero_id)
	if texture != null:
		var image := TextureRect.new()
		image.texture = texture
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		holder.add_child(image)
	else:
		var person := _label(UiIcons.PERSON, &"LnIconMuted")
		person.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		person.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		person.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		holder.add_child(person)
	if level > 0:
		var tag := _label(tr("Nv %d") % level, &"LnTagLevelMe" if mine else &"LnTagLevelRival")
		tag.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
		tag.grow_horizontal = GROW_DIRECTION_BEGIN
		tag.grow_vertical = GROW_DIRECTION_BEGIN
		holder.add_child(tag)
	return frame


## Fatos do fim da partida (destaque): motivo, boss neutro e, se o Game informou, o conjunto ativo.
func _facts(summary: MatchSummary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	var reason := HistoryFormat.end_reason(summary.end_reason)
	if not reason.is_empty():
		row.add_child(_fact(tr("MOTIVO DE FIM"), tr(reason), &"LnNumMd"))
	var boss := (
		"%s  %s" % [UiIcons.SKULL, tr("Abatido")] if summary.me.boss_kill else tr("Não abatido")
	)
	row.add_child(
		_fact(tr("BOSS NEUTRO"), boss, &"LnNumMdGold" if summary.me.boss_kill else &"LnNumMd")
	)
	var set_name := HistoryFormat.active_set_name(summary.me.set_active)
	if not set_name.is_empty():
		row.add_child(_fact(tr("CONJUNTO ATIVO"), tr(set_name), &"LnNumMdCyan"))
	return row


func _fact(
	caption: String, value: String, value_type: StringName, icon: String = ""
) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.theme_type_variation = &"LnCell"
	var box := VBoxContainer.new()
	box.theme_type_variation = &"LnVGapXs"
	cell.add_child(box)
	box.add_child(_label(caption, &"LnNum"))
	var line := HBoxContainer.new()
	line.theme_type_variation = &"LnHGapXs"
	if not icon.is_empty():
		line.add_child(_label(icon, &"LnIconSmGold"))
	line.add_child(_label(value, value_type))
	box.add_child(line)
	return cell


func _interrupted_text(summary: MatchSummary) -> Label:
	var reason := HistoryFormat.end_reason(summary.end_reason)
	var text := tr("A partida não terminou e não tem resultado.")
	if not reason.is_empty():
		text += " " + tr("Motivo: %s.") % tr(reason)
	return _label(text, &"LnBodyMuted")


func _label(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text
	return label


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	return spacer
