# gdlint: ignore=max-public-methods
extends GutTest
## F26: tela Historico (FRONTEND-LAUNCHER §3, §6): os 5 estados do StateBox, feed de duelos com o
## destaque na partida mais recente, filtros Todas/Vitorias/Derrotas, textos reais (sem dado de
## exemplo do prototipo) e foco/rolagem por teclado. ApiClient falso.

const SCENE: PackedScene = preload("res://scenes/screens/history.tscn")
const CALL: String = "GET /matches?mine=1"
const ME_RANGER: Dictionary = {
	"heroId": "ranger",
	"kills": 5,
	"finalLevel": 9,
	"deaths": 3,
	"bossKill": true,
	"setActive": "hunter"
}
const ME_KNIGHT: Dictionary = {
	"heroId": "knight",
	"kills": 3,
	"finalLevel": 8,
	"deaths": 5,
	"bossKill": false,
	"setActive": null
}
const ME_NONE: Dictionary = {
	"heroId": null, "kills": 0, "finalLevel": 0, "deaths": 0, "bossKill": false, "setActive": null
}

var _api: FakeApiClient
var _service: HistoryService
var _screen: HistoryScreen


func before_each() -> void:
	_api = FakeApiClient.new()
	add_child_autofree(_api)
	_service = HistoryService.new(_api)


func _match(
	index: int,
	result: String,
	mine: Dictionary,
	rival: Dictionary,
	duration: Variant,
	reason: Variant
) -> Dictionary:
	return {
		"matchId": "0b7e9f00-1111-4222-8333-%012d" % index,
		"result": result,
		"playedAt": "2026-10-15T12:%02d:00.000Z" % (30 - index),
		"endReason": reason,
		"durationS": duration,
		"me": mine,
		"opponent": rival,
	}


func _history() -> Dictionary:
	var knight := {"heroId": "knight", "kills": 3, "finalLevel": 8}
	var ranger := {"heroId": "ranger", "kills": 5, "finalLevel": 9}
	var none := {"heroId": null, "kills": 0, "finalLevel": 0}
	return {
		"totals": {"wins": 2, "losses": 1},
		"matches":
		[
			_match(1, "win", ME_RANGER, knight, 522, "kill_goal"),
			_match(2, "loss", ME_KNIGHT, ranger, 555, "collapse_hp"),
			_match(3, "win", ME_RANGER, knight, 400, "kill_goal"),
			_match(4, "interrupted", ME_NONE, none, null, "heartbeat_lost"),
		],
	}


func _open(status: int = 200, body: Variant = null) -> HistoryScreen:
	_api.reply(CALL, status, _history() if body == null else body)
	_screen = SCENE.instantiate() as HistoryScreen
	add_child_autofree(_screen)
	_screen.bind(_service)
	await wait_process_frames(2)
	return _screen


func _texts(node: Node) -> Array[String]:
	var texts: Array[String] = []
	for label: Node in node.find_children("*", "Label", true, false):
		texts.append((label as Label).text)
	return texts


func _has_text(node: Node, part: String) -> bool:
	return _texts(node).any(func(text: String) -> bool: return text.contains(part))


func test_carregando_antes_da_resposta() -> void:
	var slow := SlowService.new(_api)
	_screen = SCENE.instantiate() as HistoryScreen
	add_child_autofree(_screen)
	_screen.bind(slow)
	await wait_process_frames(1)
	assert_eq(_screen.state(), StateBox.State.LOADING)
	assert_eq(_screen.record_text(), "—", "sem dado, nada de 0V — 0D")
	assert_eq(_screen.filter_chip(HistoryScreen.Filter.ALL).count_text(), "")
	_api.reply(CALL, 200, _history())
	slow.release.emit()
	await wait_process_frames(2)
	assert_eq(_screen.state(), StateBox.State.READY)


func test_pronto_lista_as_partidas_e_conta_nos_chips() -> void:
	await _open()
	assert_eq(_screen.state(), StateBox.State.READY)
	assert_eq(_screen.cards().size(), 4)
	assert_eq(_screen.filter_chip(HistoryScreen.Filter.ALL).count_text(), "4")
	assert_eq(_screen.filter_chip(HistoryScreen.Filter.WINS).count_text(), "2")
	assert_eq(_screen.filter_chip(HistoryScreen.Filter.LOSSES).count_text(), "1")
	assert_eq(_screen.record_text(), "2V — 1D")
	assert_eq(_screen.footer_text(), "Mostrando 4 partidas")


func test_so_a_partida_mais_recente_e_destaque() -> void:
	await _open()
	var cards := _screen.cards()
	assert_true(cards[0].highlighted)
	for i: int in range(1, cards.size()):
		assert_false(cards[i].highlighted, "cartao %d" % i)


func test_vazio_sem_nenhuma_partida() -> void:
	await _open(200, {"totals": {"wins": 0, "losses": 0}, "matches": []})
	assert_eq(_screen.state(), StateBox.State.EMPTY)
	assert_eq(_screen.record_text(), "0V — 0D")
	assert_eq(_screen.footer_text(), "Mostrando 0 partidas")


func test_erro_com_backend_fora_e_tentar_de_novo() -> void:
	_screen = SCENE.instantiate() as HistoryScreen
	add_child_autofree(_screen)
	_screen.bind(_service)
	await wait_process_frames(2)
	assert_eq(_screen.state(), StateBox.State.ERROR)
	assert_eq(_screen.record_text(), "—")
	assert_eq(_screen.filter_chip(HistoryScreen.Filter.WINS).count_text(), "")
	_api.reply(CALL, 200, _history())
	var state_box := _screen.find_children("*", "StateBox", true, false)[0] as StateBox
	state_box.retry_requested.emit()
	await wait_process_frames(2)
	assert_eq(_screen.state(), StateBox.State.READY)
	assert_eq(_api.calls.size(), 2)


func test_erro_do_backend_sem_ser_rede_tem_mensagem_geral() -> void:
	_api.reply(CALL, 500, {"statusCode": 500, "code": "INTERNAL_ERROR", "message": "x"})
	_screen = SCENE.instantiate() as HistoryScreen
	add_child_autofree(_screen)
	_screen.bind(_service)
	await wait_process_frames(2)
	assert_eq(_screen.state(), StateBox.State.ERROR)
	var state_box := _screen.find_children("*", "StateBox", true, false)[0] as StateBox
	assert_true(_has_text(state_box, "Não foi possível carregar o histórico."))


func test_filtro_vitorias_e_derrotas() -> void:
	await _open()
	_screen.select_filter(HistoryScreen.Filter.WINS)
	assert_eq(_screen.visible_cards().size(), 2)
	assert_eq(_screen.footer_text(), "Mostrando 2 partidas")
	_screen.select_filter(HistoryScreen.Filter.LOSSES)
	assert_eq(_screen.visible_cards().size(), 1)
	assert_eq(_screen.footer_text(), "Mostrando 1 partida")
	assert_eq(_screen.visible_cards()[0].result, "loss")
	_screen.select_filter(HistoryScreen.Filter.ALL)
	assert_eq(_screen.visible_cards().size(), 4, "interrompida so aparece em Todas")


func test_filtro_sem_resultado_mostra_vazio_e_volta() -> void:
	var only_wins := _history()
	only_wins["matches"] = [only_wins["matches"][0]]
	await _open(200, only_wins)
	_screen.select_filter(HistoryScreen.Filter.LOSSES)
	assert_eq(_screen.state(), StateBox.State.EMPTY)
	_screen.select_filter(HistoryScreen.Filter.ALL)
	assert_eq(_screen.state(), StateBox.State.READY)


func test_chip_ativo_e_so_um() -> void:
	await _open()
	assert_true(_screen.filter_chip(HistoryScreen.Filter.ALL).button_pressed)
	_screen.select_filter(HistoryScreen.Filter.WINS)
	assert_false(_screen.filter_chip(HistoryScreen.Filter.ALL).button_pressed)
	assert_true(_screen.filter_chip(HistoryScreen.Filter.WINS).button_pressed)


func test_destaque_mostra_placar_herois_e_fatos() -> void:
	await _open()
	var card := _screen.cards()[0]
	var texts := _texts(card)
	assert_true(texts.has("5  %s  3" % UiIcons.SWORDS), str(texts))
	assert_true(texts.has("Arqueira (Você)"), str(texts))
	assert_true(texts.has("Cavaleiro"), str(texts))
	assert_true(texts.has("5 Kills"))
	assert_true(texts.has("3 Mortes"))
	assert_true(texts.has("3 Kills"))
	assert_true(texts.has("08:42 min"))
	assert_true(_has_text(card, "VITÓRIA"))
	assert_true(_has_text(card, "Duelo #0B7E9F00"))
	assert_true(texts.has("Meta de abates"))
	assert_true(_has_text(card, "Abatido"))
	assert_true(texts.has("Caçador"), "conjunto ativo pelo nome do bonus")
	assert_true(texts.has("Nv 9") and texts.has("Nv 8"))


func test_linha_compacta_de_derrota() -> void:
	await _open()
	var card := _screen.cards()[1]
	assert_eq(card.theme_type_variation, &"LnMatchCardLoss")
	assert_true(_has_text(card, "DERROTA"))
	assert_true(_has_text(card, "Colapso: mais vida"))
	assert_true(_has_text(card, "09:15 min"))
	assert_false(_has_text(card, "BOSS"), "fatos so no destaque")


func test_partida_interrompida() -> void:
	await _open()
	var card := _screen.cards()[3]
	assert_eq(card.theme_type_variation, &"LnMatchCardNone")
	assert_true(_has_text(card, "PARTIDA INTERROMPIDA"))
	assert_true(_has_text(card, "Servidor sem sinal"))
	assert_false(_has_text(card, "Kills"))
	assert_false(_has_text(card, " min"), "sem duracao")


func test_nenhum_dado_de_exemplo_do_prototipo() -> void:
	await _open()
	var all := _texts(_screen)
	# Palavra inteira: "ELO" aparece dentro de "DUELOS".
	for word: String in ["ELO", "KDA"]:
		assert_false(all.any(func(text: String) -> bool: return text.split(" ").has(word)), word)
	for part: String in ["Duelista", "Auditoria", "Replay", "Detalhes", "Catch"]:
		assert_false(all.any(func(text: String) -> bool: return text.contains(part)), part)


func test_foco_inicial_no_filtro_todas() -> void:
	await _open()
	await wait_process_frames(2)
	assert_true(_screen.filter_chip(HistoryScreen.Filter.ALL).has_focus())


func test_mais_de_50_partidas_avisa_que_o_feed_e_so_das_recentes() -> void:
	var cut := _history()
	cut["totals"] = {"wins": 70, "losses": 30}
	await _open(200, cut)
	assert_eq(_screen.record_text(), "70V — 30D")
	assert_string_contains(_screen.footer_text(), "só as mais recentes")


func test_com_filtro_o_destaque_continua_sendo_a_mais_recente() -> void:
	await _open()
	_screen.select_filter(HistoryScreen.Filter.LOSSES)
	assert_false(_screen.visible_cards()[0].highlighted, "a mais recente (vitoria) esta escondida")


func test_tela_escondida_nao_rola_com_o_teclado() -> void:
	var many := _history()
	many["matches"] = []
	for i: int in 30:
		many["matches"].append(
			_match(
				i,
				"win",
				ME_RANGER,
				{"heroId": "knight", "kills": 3, "finalLevel": 8},
				500,
				"kill_goal"
			)
		)
	await _open(200, many)
	_screen.visible = false
	_screen._unhandled_key_input(_action(&"ui_page_down"))
	assert_eq(_screen.scroll_position(), 0)


func test_setas_e_paginas_rolam_o_feed() -> void:
	var many := _history()
	many["matches"] = []
	for i: int in 30:
		many["matches"].append(
			_match(
				i,
				"win",
				ME_RANGER,
				{"heroId": "knight", "kills": 3, "finalLevel": 8},
				500,
				"kill_goal"
			)
		)
	await _open(200, many)
	assert_eq(_screen.scroll_position(), 0)
	_screen._unhandled_key_input(_action(&"ui_down"))
	var after_arrow := _screen.scroll_position()
	assert_gt(after_arrow, 0, "seta para baixo rola")
	_screen._unhandled_key_input(_action(&"ui_page_down"))
	assert_gt(_screen.scroll_position(), after_arrow, "page down rola mais")
	_screen._unhandled_key_input(_action(&"ui_page_up"))
	_screen._unhandled_key_input(_action(&"ui_up"))
	assert_lt(_screen.scroll_position(), after_arrow + 1, "voltar rola para cima")


func test_voltar_so_com_pilha() -> void:
	await _open()
	watch_signals(_screen)
	var header := _screen.find_children("*", "ScreenHeader", true, false)[0] as ScreenHeader
	var back := header.find_children("*", "Button", true, false)[0] as Button
	assert_false(back.visible)
	_screen.can_go_back = true
	assert_true(back.visible)
	back.pressed.emit()
	assert_signal_emitted(_screen, "back_requested")


func test_reabrir_usa_o_cache_da_sessao() -> void:
	await _open()
	var again := SCENE.instantiate() as HistoryScreen
	add_child_autofree(again)
	again.bind(_service)
	await wait_process_frames(2)
	assert_eq(_api.calls.size(), 1)
	assert_eq(again.state(), StateBox.State.READY)


func _action(name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	return event


class SlowService:
	extends HistoryService

	signal release

	func fetch(force: bool = false) -> bool:
		await release
		return await super.fetch(force)
