extends GutTest
## F70: card "Resultado da partida" por cima do lobby. Cinco estados: carregando (espera a partida
## aparecer no historico), vitoria, derrota, interrompida e erro (partida nao apareceu). So dado
## do GET /matches?mine=1 (MatchSummary + MatchTotals); o card nao fala com o backend.

const MATCH: String = "0b7e9f00-1111-4222-8333-444455556666"


func _make_summary(result: String = "win") -> MatchSummary:
	return (
		MatchSummary
		. from_dict(
			{
				"matchId": MATCH,
				"result": result,
				"playedAt": "2026-10-16T12:10:00.000Z",
				"endReason": "kill_goal" if result != "interrupted" else "heartbeat_lost",
				"durationS": 508 if result != "interrupted" else null,
				"me":
				{
					"heroId": "knight",
					"kills": 5,
					"finalLevel": 9,
					"deaths": 3,
					"bossKill": false,
					"setActive": null,
				},
				"opponent": {"heroId": "ranger", "kills": 3, "finalLevel": 8, "nickname": "Rival"},
			}
		)
	)


func _make_totals(wins: int = 14, losses: int = 6) -> MatchTotals:
	return MatchTotals.from_dict({"wins": wins, "losses": losses})


func _make_card() -> MatchResultCard:
	var card := MatchResultCard.new()
	add_child_autofree(card)
	return card


func _all_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts


func test_nasce_escondido_e_ocioso() -> void:
	var card := _make_card()
	assert_false(card.visible)
	assert_eq(card.state(), StateBox.State.IDLE)


func test_carregando_abre_o_card_sem_acoes_de_resultado() -> void:
	var card := _make_card()
	card.show_loading()
	assert_true(card.visible)
	assert_eq(card.state(), StateBox.State.LOADING)
	assert_false(card.play_again_button().visible, "sem resultado ainda: nada de jogar de novo")
	assert_true(card.history_button().visible)


func test_vitoria_mostra_o_cartao_do_duelo_e_o_vd() -> void:
	var card := _make_card()
	card.show_result(_make_summary("win"), _make_totals())
	assert_eq(card.state(), StateBox.State.READY)
	assert_eq(card.result(), MatchCard.WIN)
	var texts := _all_texts(card)
	assert_true(texts.any(func(t: String) -> bool: return t.contains("VITÓRIA")), str(texts))
	assert_true(texts.has("14V — 6D"), str(texts))
	assert_true(texts.has("5  %s  3" % MatchCard.SCORE_SEPARATOR), "placar de kills")
	assert_true(texts.has("#Rival"), "oponente pelo #nickname")
	assert_true(texts.has("Cavaleiro (Você)"), str(texts))
	assert_true(texts.has("5 Kills"))
	assert_true(texts.has("3 Mortes"))
	assert_true(texts.has("08:28 min"), "duracao")
	assert_true(texts.has("Meta de abates"), "motivo de fim")
	assert_true(card.play_again_button().visible)


func test_derrota() -> void:
	var card := _make_card()
	card.show_result(_make_summary("loss"), _make_totals())
	assert_eq(card.result(), MatchCard.LOSS)
	assert_true(_all_texts(card).any(func(t: String) -> bool: return t.contains("DERROTA")))


func test_interrompida_nao_inventa_placar() -> void:
	var card := _make_card()
	card.show_result(_make_summary("interrupted"), _make_totals())
	assert_eq(card.result(), MatchCard.INTERRUPTED)
	var texts := _all_texts(card)
	assert_true(texts.any(func(t: String) -> bool: return t.contains("INTERROMPIDA")), str(texts))
	assert_true(card.play_again_button().visible, "interrompida tambem deixa jogar de novo")


func test_erro_leva_ao_historico() -> void:
	var card := _make_card()
	card.show_error()
	assert_true(card.visible)
	assert_eq(card.state(), StateBox.State.ERROR)
	assert_true(card.history_button().visible)
	assert_false(card.play_again_button().visible)


func test_botoes_emitem_os_sinais() -> void:
	var card := _make_card()
	watch_signals(card)
	card.show_result(_make_summary(), _make_totals())
	card.play_again_button().pressed.emit()
	assert_signal_emit_count(card, "play_again_requested", 1)
	card.history_button().pressed.emit()
	assert_signal_emit_count(card, "history_requested", 1)


func test_foco_comeca_em_jogar_de_novo() -> void:
	var card := _make_card()
	card.show_result(_make_summary(), _make_totals())
	await wait_process_frames(2)
	assert_true(card.play_again_button().has_focus())


func test_esc_fecha() -> void:
	var card := _make_card()
	watch_signals(card)
	card.show_result(_make_summary(), _make_totals())
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	card._unhandled_input(esc)
	assert_signal_emit_count(card, "closed", 1)
	assert_false(card.visible)


func test_esc_com_o_card_fechado_nao_faz_nada() -> void:
	var card := _make_card()
	watch_signals(card)
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	card._unhandled_input(esc)
	assert_signal_not_emitted(card, "closed")


func test_close_esconde_sem_emitir() -> void:
	var card := _make_card()
	watch_signals(card)
	card.show_loading()
	card.close()
	assert_false(card.visible)
	assert_signal_not_emitted(card, "closed")


func test_resultado_novo_troca_o_cartao_anterior() -> void:
	var card := _make_card()
	card.show_result(_make_summary("win"), _make_totals())
	card.show_result(_make_summary("loss"), _make_totals(14, 7))
	await wait_process_frames(2)  # o cartao velho sai no queue_free
	assert_eq(card.find_children("*", "MatchCard", true, false).size(), 1)
	assert_eq(card.result(), MatchCard.LOSS)
	assert_true(_all_texts(card).has("14V — 7D"))


func _caption(card: MatchResultCard) -> Label:
	for node: Node in card.find_children("*", "Label", true, false):
		if (node as Label).text == "V–D DA CONTA":
			return node as Label
	return null


func test_vd_da_conta_so_aparece_com_resultado() -> void:
	var card := _make_card()
	var caption := _caption(card)
	card.show_loading()
	assert_false(caption.visible, "carregando: sem V-D inventado")
	card.show_error()
	assert_false(caption.visible, "erro: idem")
	card.show_result(_make_summary(), _make_totals())
	assert_true(caption.visible)
