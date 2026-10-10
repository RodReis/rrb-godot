extends GutTest
## Tela de fim de partida (F18, DV tela 7, ARCHITECTURE-GAME §3.6/§3.7): so exibe o que chegou
## no match_ended (MatchStats do servidor); quem joga fica a esquerda; os dois botoes pedem o fim
## do processo por sinal (o Game nao tem fila).

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


func _text(path: String) -> String:
	return (_end.get_node(path) as Label).text


func _cells(grid: String) -> PackedStringArray:
	var texts := PackedStringArray()
	for child: Node in _end.get_node(grid).get_children():
		texts.append((child as Label).text)
	return texts


func test_escondida_ate_o_fim() -> void:
	assert_false(_end.visible)


func test_vitoria_pela_meta_de_kills() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	assert_true(_end.visible)
	assert_eq(_text("%Title"), "VITÓRIA")
	assert_eq(_text("%Reason"), "META DE %d KILLS ATINGIDA" % RULES.kill_goal)
	assert_eq(_text("%Duration"), "Duração da partida: 07:48")
	assert_eq((_end.get_node("%MeCard") as PanelCard).accent, PanelCard.Accent.GOLD)
	assert_eq((_end.get_node("%ThemCard") as PanelCard).accent, PanelCard.Accent.RED)


func test_derrota_mostra_quem_joga_a_esquerda() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), THEM)
	assert_eq(_text("%Title"), "DERROTA")
	assert_eq(_text("%MeHeader"), "VOCÊ · ARQUEIRA")
	assert_eq(_text("%ThemHeader"), "OPONENTE · CAVALEIRO")
	assert_eq((_end.get_node("%MeCard") as PanelCard).accent, PanelCard.Accent.RED)


func test_tabela_lado_a_lado_com_comparacao() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	assert_eq(_text("%MeHeader"), "VOCÊ · CAVALEIRO")
	var me := _cells("%MeStats")
	var them := _cells("%ThemStats")
	assert_eq(me.size(), MatchEnd.ROWS.size())
	assert_eq(
		Array(me),
		["5", "3", "9", "4250", "4800", "7", "5", "Abatido", "Guarda 1/3"],
	)
	assert_eq(
		Array(them),
		["3", "5", "9", "3820", "4900", "4", "5", "Não abatido", "Sem conjunto"],
	)
	assert_eq(Array(_cells("%Compare")), [">", "<", "=", ">", "<", ">", "=", ">", ""])


func test_comparacao_colore_o_que_e_bom_para_quem_joga() -> void:
	_end.present(ME, VictoryRules.KILL_GOAL, _stats(), ME)
	var glyphs := _end.get_node("%Compare").get_children()
	assert_eq((glyphs[0] as Label).theme_type_variation, &"LabelCounterAlly", "mais kills")
	assert_eq((glyphs[1] as Label).theme_type_variation, &"LabelCounterAlly", "menos mortes")
	assert_eq((glyphs[2] as Label).theme_type_variation, &"LabelCounter", "empate")
	assert_eq((glyphs[4] as Label).theme_type_variation, &"LabelCounterAlly", "sofreu menos")


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


func test_eliminacao_e_abandono() -> void:
	_end.present(ME, VictoryRules.ELIMINATION, _stats(), ME)
	assert_eq(_text("%Reason"), "ELIMINAÇÃO NA MORTE SÚBITA")
	_end.present(MatchController.NO_WINNER, VictoryRules.ABANDONED, MatchStats.new(), ME)
	assert_eq(_text("%Title"), "SEM VENCEDOR")
	assert_eq(_text("%Reason"), "PARTIDA ABANDONADA")
	assert_eq((_end.get_node("%MeCard") as PanelCard).accent, PanelCard.Accent.NONE)
	assert_eq(_text("%MeHeader"), "VOCÊ")
	assert_eq(_cells("%ThemStats")[0], "0", "sem dado do oponente: zeros")


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
