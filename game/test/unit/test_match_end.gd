# gdlint: ignore=max-public-methods
extends GutTest
## Tela de fim de partida (F18 + F52, protótipo "Destaques da Tela de Fim de Partida"): só exibe o
## que chegou no match_ended (MatchStats do servidor); quem joga fica à esquerda; o tom da tela
## (vitória, derrota, sem vencedor) vai por tipos do Theme; os dois botões pedem o fim do
## processo por sinal (o Game não tem fila).

const SCENE: PackedScene = preload("res://scenes/ui/match_end.tscn")
const RULES: MatchRules = preload("res://shared/data/rules/match_pacing.tres")
const ROSTER: Array[HeroData] = [
	preload("res://shared/data/heroes/knight.tres"),
	preload("res://shared/data/heroes/ranger.tres"),
]
const ME: int = 11
const THEM: int = 22

var _match: MatchController
var _end: MatchEnd
var _theme: Theme = preload("res://shared/ui/theme/theme_moba.tres")


func before_each() -> void:
	_match = MatchController.new()
	_match.rules = RULES
	add_child_autofree(_match)
	_end = add_child_autofree(SCENE.instantiate())
	_end.bind(_match, ROSTER)


func _stats() -> MatchStats:
	var stats := MatchStats.new()
	stats.duration = 468.9
	var me := stats.player(ME)
	me.hero = Ids.to_int(&"knight")
	me.kills = 5
	me.deaths = 3
	me.level = 9
	me.hero_damage = 4250
	me.damage_taken = 4800
	me.monsters = 7
	me.chests = 5
	me.boss_killed = true
	var guard := Ids.to_int(&"guard_helm_t1")
	me.equipment = Vector4i(Ids.NONE, guard, Ids.NONE, Ids.NONE)
	var them := stats.player(THEM)
	them.hero = Ids.to_int(&"ranger")
	them.kills = 3
	them.deaths = 5
	them.level = 9
	them.hero_damage = 3820
	them.damage_taken = 4900
	them.monsters = 4
	them.chests = 5
	return stats


func _label(path: String) -> Label:
	return _end.get_node(path) as Label


func _text(path: String) -> String:
	return _label(path).text


func _type(path: String) -> StringName:
	return (_end.get_node(path) as Control).theme_type_variation


func _me() -> MatchEndCard:
	return _end.get_node("%MeCard") as MatchEndCard


func _them() -> MatchEndCard:
	return _end.get_node("%ThemCard") as MatchEndCard


func _values(card: MatchEndCard) -> Array[String]:
	var texts: Array[String] = []
	for row: MatchEndRow in card.rows:
		texts.append(row.value_label.text)
	return texts


## Círculo e texto do comparador da linha [param index].
func _glyph(index: int) -> Control:
	return _end.get_node("%Compare").get_child(index).get_child(0) as Control


func _glyph_text(index: int) -> String:
	return (_glyph(index).get_child(0) as Label).text


func test_escondida_ate_o_fim() -> void:
	assert_false(_end.visible)


func test_vitoria_pela_meta_de_kills() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	assert_true(_end.visible)
	assert_eq(_text("%Title"), "VITÓRIA")
	assert_eq(_type("%Title"), &"LabelEndTitleWin")
	assert_eq(_text("%Reason"), "META DE %d KILLS ATINGIDA" % RULES.kill_goal)
	assert_eq(_type("%ReasonPill"), &"EndReasonWin")
	assert_eq(_text("%DurationValue"), "07:48")
	assert_eq(_text("%ModeValue"), "DUELO 1V1")
	assert_eq(_type("%MeCard"), &"EndCardWin")
	assert_eq(_type("%ThemCard"), &"EndCardLose")
	assert_eq(_type("%PlayAgain"), &"ButtonEndPrimary")


func test_derrota_mostra_quem_joga_a_esquerda() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), THEM)
	assert_eq(_text("%Title"), "DERROTA")
	assert_eq(_type("%Title"), &"LabelEndTitleLose")
	assert_eq(_me().name_label.text, "VOCÊ")
	assert_eq(_me().hero_label.text, "— ARQUEIRO")
	assert_eq(_them().name_label.text, "OPONENTE")
	assert_eq(_them().hero_label.text, "— CAVALEIRO")
	assert_eq(_type("%MeCard"), &"EndCardLose")
	assert_eq(_type("%ThemCard"), &"EndCardWin")
	assert_eq(_type("%ReasonPill"), &"EndReasonLose")
	assert_eq(_type("%PlayAgain"), &"ButtonEndDanger")


func test_cabecalho_dos_cartoes_diz_lado_e_resultado() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	assert_eq(_me().side_label.text, "ALIADO")
	assert_eq(_them().side_label.text, "INIMIGO")
	assert_eq(_me().tag_label.text, "VENCEDOR")
	assert_eq(_them().tag_label.text, "DERROTADO")
	assert_eq(_me().tag_label.theme_type_variation, &"LabelEndTagWin")
	assert_eq(_them().tag_label.theme_type_variation, &"LabelEndTagLose")
	assert_eq(_me().level_label.text, "NV.9")
	assert_eq(_me().level_label.theme_type_variation, &"LabelEndLevelWin")
	assert_eq(_them().level_label.theme_type_variation, &"LabelEndLevelLose")


func test_icone_do_cartao_e_o_do_basico_do_heroi() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	var knight: HeroData = ROSTER[0]
	var ranger: HeroData = ROSTER[1]
	assert_eq(_me().icon_rect.texture, knight.basic_attack.icon)
	assert_eq(_them().icon_rect.texture, ranger.basic_attack.icon)


func test_tabela_lado_a_lado_com_comparacao() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	assert_eq(_me().name_label.text, "VOCÊ")
	assert_eq(_me().hero_label.text, "— CAVALEIRO")
	assert_eq(_me().rows.size(), MatchEnd.ROWS.size())
	assert_eq(MatchEnd.BETTER.size(), MatchEnd.ROWS.size(), "uma regra de comparacao por linha")
	assert_eq(
		_values(_me()),
		["5", "3", "Nv. 9", "4.250", "4.800", "7", "5", "Abatido", "Guarda 1/3"],
	)
	assert_eq(
		_values(_them()),
		["3", "5", "Nv. 9", "3.820", "4.900", "4", "5", "Não abatido", "Sem conjunto"],
	)
	for i: int in MatchEnd.ROWS.size():
		assert_eq(_me().rows[i].name_label.text, MatchEnd.ROWS[i])
	var glyphs: Array[String] = []
	for i: int in MatchEnd.ROWS.size():
		glyphs.append(_glyph_text(i) if _glyph(i).visible else "")
	assert_eq(glyphs, [">", "<", "=", ">", "<", ">", "=", ">", ""])


func test_constantes_paralelas_tem_o_mesmo_tamanho() -> void:
	var rows := MatchEnd.ROWS.size()
	assert_eq(MatchEnd.ICONS.size(), rows)
	assert_eq(MatchEnd.ICON_TOKENS.size(), MatchEnd.NUMBER_ROWS)
	assert_eq(MatchEnd.VALUE_TOKENS.size(), MatchEnd.NUMBER_ROWS)
	assert_eq(MatchEnd.NUMBER_ROWS, MatchEnd.BOSS_ROW, "o boss vem logo depois das contagens")
	assert_eq(MatchEnd.SET_ROW, rows - 1)
	var tokens: Array[StringName] = []
	tokens.append_array(MatchEnd.ICON_TOKENS)
	tokens.append_array(MatchEnd.VALUE_TOKENS)
	for token: StringName in tokens:
		assert_has(UiTokens.COLORS.keys(), token)


## O comparador alinha com as linhas: cada círculo fica à altura da sua linha.
func test_comparador_alinha_com_as_linhas() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	await wait_process_frames(2)
	for i: int in MatchEnd.ROWS.size():
		var row := _me().rows[i]
		var holder := _glyph(i).get_parent() as Control
		assert_almost_eq(holder.global_position.y, row.global_position.y, 0.5, "linha %d" % i)
		assert_almost_eq(holder.size.y, row.size.y, 0.5, "altura da linha %d" % i)


## Todo tipo de Theme que a tela de fim usa existe (cartão, linha, valor, tom).
func test_tipos_usados_existem_no_theme() -> void:
	var types := _theme.get_type_list()
	var used: Array[StringName] = [&"EndGlyph", &"LabelEndGlyph", &"EndVs", &"EndFooter", &"EndKey"]
	used.append_array([&"EndKeyDark", &"LabelEndButton", &"LabelEndButtonDark", &"ButtonEnd"])
	used.append_array([&"LabelEndPillGold", &"LabelEndPillMuted", MatchEndRow.PLAIN_STYLE])
	used.append(MatchEndRow.HOVER_STYLE)
	for token: StringName in MatchEnd.VALUE_TOKENS:
		used.append(StringName("LabelEndValue%s" % String(token).to_pascal_case()))
	for type: StringName in used:
		assert_has(types, type, "tipo %s fora do Theme" % type)


func test_formata_milhar_com_ponto() -> void:
	assert_eq(MatchEnd.format_number(0), "0")
	assert_eq(MatchEnd.format_number(999), "999")
	assert_eq(MatchEnd.format_number(1000), "1.000")
	assert_eq(MatchEnd.format_number(4820), "4.820")
	assert_eq(MatchEnd.format_number(1234567), "1.234.567")


func test_lado_melhor_ganha_o_acento_da_linha_e_o_pior_apaga() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	var mine := _me().rows
	var theirs := _them().rows
	assert_eq(mine[0].value_label.theme_type_variation, &"LabelEndValueText", "mais kills")
	_assert_color(mine[0].icon_rect.modulate, UiTokens.GOLD)
	assert_eq(theirs[0].value_label.theme_type_variation, &"LabelEndValueTextMuted")
	_assert_color(theirs[0].icon_rect.modulate, UiTokens.TEXT_MUTED)
	assert_eq(mine[1].value_label.theme_type_variation, &"LabelEndValueGreen", "menos mortes")
	_assert_color(theirs[1].icon_rect.modulate, UiTokens.RED, "mais mortes: ícone vermelho")
	assert_eq(theirs[1].value_label.theme_type_variation, &"LabelEndValueTextMuted")
	assert_eq(mine[2].value_label.theme_type_variation, &"LabelEndValueCyan", "empate no nível")
	assert_eq(theirs[2].value_label.theme_type_variation, &"LabelEndValueCyan")
	_assert_color(mine[4].icon_rect.modulate, UiTokens.TEXT_MUTED, "sofreu menos: ícone neutro")
	_assert_color(theirs[4].icon_rect.modulate, UiTokens.RED, "sofreu mais")


func test_comparacao_vale_para_quem_joga() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), THEM)
	assert_eq(_glyph_text(0), "<", "o jogador local é o outro: menos kills")
	assert_eq(_glyph_text(1), ">")
	assert_eq(_me().rows[0].value_label.theme_type_variation, &"LabelEndValueTextMuted")
	assert_eq(_them().rows[0].value_label.theme_type_variation, &"LabelEndValueText")


func test_rei_esqueleto_e_conjunto_destacam_so_quando_conquistados() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	var boss := MatchEnd.BOSS_ROW
	var set_row := MatchEnd.SET_ROW
	assert_eq(_me().rows[boss].style, &"EndRowBoss")
	assert_eq(_me().rows[boss].value_label.theme_type_variation, &"LabelEndPillGold")
	assert_eq(_them().rows[boss].style, &"EndRowMuted")
	assert_eq(_them().rows[boss].value_label.theme_type_variation, &"LabelEndPillMuted")
	assert_eq(_me().rows[set_row].style, &"EndRowSet")
	assert_eq(_me().rows[set_row].value_label.theme_type_variation, &"LabelHeroAccent")
	assert_eq(_them().rows[set_row].style, &"EndRowMuted")
	assert_eq(_them().rows[set_row].value_label.theme_type_variation, &"LabelMuted")
	assert_eq(_me().rows[0].style, &"EndRow")


func test_condicao_do_colapso_diz_o_criterio() -> void:
	var collapse := TimerLabel.format_seconds(RULES.max_match_duration, TimerLabel.Format.MM_SS)
	var cases := {
		VictoryRules.COLLAPSE_HP: "MAIOR VIDA",
		VictoryRules.COLLAPSE_KILLS: "MAIS KILLS NA FASE 2",
		VictoryRules.COLLAPSE_DAMAGE: "MAIS DANO EM HERÓIS",
		VictoryRules.COLLAPSE_DRAW: "SORTEIO",
	}
	for reason: StringName in cases:
		_end.present(ME, reason, _stats(), ME)
		assert_eq(_text("%Reason"), "COLAPSO DA ZONA AOS %s · %s" % [collapse, cases[reason]])


## F80 / ADR-0020: quem fica ve a vitoria com o motivo dito claramente (nao o texto de partida sem
## ninguem). O motivo left ja tem texto proprio: sem aviso de motivo desconhecido.
func test_adversario_abandonou_a_partida() -> void:
	_end.present(ME, VictoryRules.LEFT, _stats(), ME)
	assert_eq(_text("%Title"), "VITÓRIA")
	assert_eq(_text("%Reason"), "ADVERSÁRIO ABANDONOU A PARTIDA")


func test_eliminacao_e_abandono() -> void:
	_end.present(ME, VictoryRules.ELIMINATION, _stats(), ME)
	assert_eq(_text("%Reason"), "ELIMINAÇÃO NA MORTE SÚBITA")
	_end.present(MatchController.NO_WINNER, VictoryRules.ABANDONED, MatchStats.new(), ME)
	assert_eq(_text("%Title"), "SEM VENCEDOR")
	assert_eq(_type("%Title"), &"LabelEndTitleDraw")
	assert_eq(_text("%Reason"), "PARTIDA ABANDONADA")
	assert_eq(_type("%MeCard"), &"EndCardDraw")
	assert_eq(_type("%ThemCard"), &"EndCardDraw")
	assert_eq(_type("%PlayAgain"), &"ButtonEndPrimary")
	assert_eq(_me().name_label.text, "VOCÊ")
	assert_eq(_me().hero_label.text, "", "sem herói: só o papel")
	assert_false(_me().tag_label.visible, "sem vencedor, sem selo")
	assert_false(_me().level_label.visible, "sem herói, sem nível")
	assert_eq(_values(_them())[0], "0", "sem dado do oponente: zeros")


func test_chega_pelo_sinal_do_servidor() -> void:
	_match.match_ended.emit(ME, VictoryRules.KILL_GOAL, _stats(), 900)
	assert_true(_end.visible)


func test_botoes_pedem_o_fim_e_comecam_com_foco() -> void:
	watch_signals(_end)
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	var again := _end.get_node("%PlayAgain") as Button
	assert_true(again.has_focus())
	again.pressed.emit()
	assert_signal_emitted(_end, "play_again_requested")
	(_end.get_node("%Back") as Button).pressed.emit()
	assert_signal_emitted(_end, "back_requested")


func test_esc_volta() -> void:
	watch_signals(_end)
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	_end._unhandled_input(esc)
	assert_signal_emitted(_end, "back_requested")


func test_botao_voltar_diz_voltar_ao_lobby() -> void:
	var label := _end.get_node("Root/Layout/Footer/Actions/Back/Content/Row/Label") as Label
	assert_eq(label.text, "VOLTAR AO LOBBY")


func test_contagem_comeca_em_15_s_e_fica_visivel() -> void:
	var countdown := _end.get_node("%Countdown") as Label
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	assert_eq(MatchEnd.AUTO_CLOSE_SECONDS, 15.0)
	assert_eq(_end.seconds_left(), 15.0)
	assert_true(countdown.is_visible_in_tree())
	assert_eq(countdown.text, "Fechando em 15 s")


func test_contagem_desce_com_o_tempo() -> void:
	var countdown := _end.get_node("%Countdown") as Label
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	_end._process(4.5)
	assert_almost_eq(_end.seconds_left(), 10.5, 0.001)
	# Arredonda para cima: nunca mostra 0 antes de fechar.
	assert_eq(countdown.text, "Fechando em 11 s")


func test_ao_zerar_fecha_sozinha_uma_vez() -> void:
	watch_signals(_end)
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	_end._process(14.9)
	assert_signal_not_emitted(_end, "back_requested")
	_end._process(0.2)
	assert_signal_emit_count(_end, "back_requested", 1)
	assert_eq(_end.seconds_left(), 0.0)
	assert_false(_end.is_processing(), "parada: nao emite de novo")


func test_nao_conta_antes_de_apresentar() -> void:
	assert_false(_end.is_processing())
	assert_eq(_end.seconds_left(), 0.0)


func test_apresentar_de_novo_reinicia_a_contagem() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	_end._process(10.0)
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	assert_eq(_end.seconds_left(), 15.0)


func test_botao_principal_pulsa_so_na_vitoria() -> void:
	var again := _end.get_node("%PlayAgain") as Button
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	assert_true(_end.is_pulsing(), "vitória: pulso do protótipo (pulse-subtle)")
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), THEM)
	assert_false(_end.is_pulsing(), "derrota: sem pulso")
	assert_eq(again.modulate.a, 1.0)


func _assert_color(got: Color, expected: Color, text: String = "") -> void:
	assert_true(got.is_equal_approx(expected), "%s esperado %s, veio %s" % [text, expected, got])
