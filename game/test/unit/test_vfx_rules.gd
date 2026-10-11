extends GutTest
## F41: efeito nasce uma vez da borda do estado (ressimulacao restaura o mesmo estado, sem borda
## nova) e a flecha visual anda sozinha, sem voltar atras quando a rede corrige.

const SPEED: float = 20.0
const FRAME: float = 1.0 / 60.0
const END: float = 9.0


func _count_starts(values: Array[int]) -> int:
	var starts := 0
	var previous := values[0]
	for value: int in values:
		if VfxRules.started(previous, value):
			starts += 1
		previous = value
	return starts


func test_recarga_que_sobe_e_um_disparo() -> void:
	assert_true(VfxRules.started(0, 30))
	assert_true(VfxRules.started(3, 30), "recarga reiniciada antes de zerar")


func test_recarga_que_desce_ou_para_nao_dispara() -> void:
	assert_false(VfxRules.started(30, 29))
	assert_false(VfxRules.started(0, 0))


func test_ressimulacao_que_repete_o_estado_dispara_uma_vez() -> void:
	# Cliente: preve o disparo (30), o servidor confirma ticks antigos e o rollback refaz os
	# mesmos valores; o _process ve a mesma sequencia, sem subida nova.
	var frames: Array[int] = [0, 0, 30, 29, 29, 28, 28, 27, 26, 26]
	assert_eq(_count_starts(frames), 1)


func test_dois_disparos_sao_dois_eventos() -> void:
	var frames: Array[int] = [0, 24, 12, 0, 0, 24, 23]
	assert_eq(_count_starts(frames), 2)


func test_flecha_visual_anda_na_velocidade_sem_correcao() -> void:
	var shown := VfxRules.arrow_progress(1.0, 1.0 + SPEED * FRAME, SPEED, FRAME, END)
	assert_almost_eq(shown, 1.0 + SPEED * FRAME, 0.0001)


func test_flecha_visual_nunca_volta_quando_a_rede_recua() -> void:
	# Ressimulacao no cliente: a posicao da rede oscila para tras e para frente.
	var network: Array[float] = [0.3, 0.6, 0.4, 0.9, 0.7, 1.3, 1.1, 1.7, 1.5, 2.1]
	var shown := 0.0
	for value: float in network:
		var next := VfxRules.arrow_progress(shown, value, SPEED, FRAME, END)
		assert_true(next >= shown, "voltou de %f para %f" % [shown, next])
		shown = next


func test_flecha_visual_alcanca_a_rede_atrasada() -> void:
	var shown := 1.0
	var network := 1.5
	for i: int in 12:
		network += SPEED * FRAME
		shown = VfxRules.arrow_progress(shown, network, SPEED, FRAME, END)
	assert_almost_eq(shown, network, 0.05)


func test_flecha_visual_salta_quando_o_erro_e_grande() -> void:
	assert_eq(VfxRules.arrow_progress(0.0, 5.0, SPEED, FRAME, END), 5.0)


func test_flecha_visual_para_no_alcance() -> void:
	assert_eq(VfxRules.arrow_progress(END - 0.01, END, SPEED, FRAME, END), END)
