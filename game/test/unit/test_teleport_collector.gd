extends GutTest

const PEER: int = 11

var _collector: TeleportCollector
var _pending: bool = false


func before_each() -> void:
	_pending = false
	_collector = TeleportCollector.new()
	_collector.is_pending = func() -> bool: return _pending


func test_aceita_o_primeiro_total_do_peer() -> void:
	assert_true(_collector.accept(PEER, 12))
	assert_true(_collector.has_reported(PEER))


func test_segundo_total_do_mesmo_peer_e_recusado() -> void:
	_collector.accept(PEER, 12)
	assert_false(_collector.accept(PEER, 3))


func test_fora_da_faixa_e_recusado_sem_gastar_o_envio() -> void:
	assert_false(_collector.accept(PEER, -1))
	assert_false(_collector.accept(PEER, TeleportCollector.MAX_TELEPORTS + 1))
	assert_false(_collector.has_reported(PEER))
	assert_true(_collector.accept(PEER, TeleportCollector.MAX_TELEPORTS))


func test_quem_saiu_nao_e_esperado_e_o_envio_tardio_e_recusado() -> void:
	_collector.skip(PEER)
	assert_true(_collector.has_reported(PEER))
	assert_false(_collector.accept(PEER, 4))


func test_zero_e_total_valido() -> void:
	assert_true(_collector.accept(PEER, 0))


func test_espera_acaba_na_hora_quando_nada_falta() -> void:
	var started := Time.get_ticks_msec()
	await _collector.wait(get_tree(), 5.0)
	assert_lt(Time.get_ticks_msec() - started, 500)


func test_espera_acaba_no_prazo_quando_o_total_nao_vem() -> void:
	_pending = true
	var started := Time.get_ticks_msec()
	await _collector.wait(get_tree(), 0.3)
	var elapsed := Time.get_ticks_msec() - started
	assert_gt(elapsed, 100, "esperou mais de um passo")
	assert_lt(elapsed, 2000, "voltou no prazo")


func test_espera_acaba_assim_que_o_total_chega() -> void:
	_pending = true
	get_tree().create_timer(0.25).timeout.connect(func() -> void: _pending = false)
	var started := Time.get_ticks_msec()
	await _collector.wait(get_tree(), 5.0)
	assert_lt(Time.get_ticks_msec() - started, 1500)
