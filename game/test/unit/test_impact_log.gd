extends GutTest
## F41: o servidor anuncia cada impacto uma vez; ressimular o atacante chama _hit de novo para o
## mesmo tick, alvo e habilidade.


func test_primeiro_anuncio_passa_e_o_repetido_nao() -> void:
	var impacts := ImpactLog.new()
	assert_true(impacts.first(10, 7, HitLedger.Slot.BASIC, -3))
	assert_false(impacts.first(10, 7, HitLedger.Slot.BASIC, -3), "ressimulacao do mesmo tick")


func test_alvo_habilidade_e_tick_diferentes_sao_impactos_diferentes() -> void:
	var impacts := ImpactLog.new()
	assert_true(impacts.first(10, 7, HitLedger.Slot.BASIC, -3))
	assert_true(impacts.first(10, 7, HitLedger.Slot.BASIC, -4))
	assert_true(impacts.first(10, 7, HitLedger.Slot.Q, -3))
	assert_true(impacts.first(11, 7, HitLedger.Slot.BASIC, -3))
	assert_true(impacts.first(10, 8, HitLedger.Slot.BASIC, -3))


func test_trim_esquece_ticks_antigos() -> void:
	var impacts := ImpactLog.new()
	impacts.first(5, 7, HitLedger.Slot.R, 2)
	impacts.first(9, 7, HitLedger.Slot.R, 2)
	impacts.trim_before(8)
	assert_true(impacts.first(5, 7, HitLedger.Slot.R, 2), "tick 5 saiu da janela")
	assert_false(impacts.first(9, 7, HitLedger.Slot.R, 2))
