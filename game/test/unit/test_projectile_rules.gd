extends GutTest
## Geometria do projetil (F14): acerto no corpo do alvo, bloqueio da Muralha e lentidao.


func test_flecha_acerta_o_circulo_no_ponto_de_entrada() -> void:
	# Segmento de x=0 a x=10 em z=0; alvo em x=5 com raio 1: entra em t = 0,4.
	var t := CombatRules.segment_circle_fraction(
		Vector3.ZERO, Vector3(10, 0, 0), Vector3(5, 0, 0), 1.0
	)
	assert_almost_eq(t, 0.4, 0.0001)


func test_flecha_que_passa_de_lado_nao_acerta() -> void:
	var t := CombatRules.segment_circle_fraction(
		Vector3.ZERO, Vector3(10, 0, 0), Vector3(5, 0, 2), 1.0
	)
	assert_eq(t, CombatRules.NO_HIT)


func test_flecha_que_para_antes_do_alvo_nao_acerta() -> void:
	var t := CombatRules.segment_circle_fraction(
		Vector3.ZERO, Vector3(3, 0, 0), Vector3(5, 0, 0), 1.0
	)
	assert_eq(t, CombatRules.NO_HIT)


func test_flecha_que_comeca_dentro_do_alvo_acerta_na_hora() -> void:
	var t := CombatRules.segment_circle_fraction(
		Vector3.ZERO, Vector3(3, 0, 0), Vector3(0.2, 0, 0), 1.0
	)
	assert_eq(t, 0.0)


func test_acerto_da_flecha_ignora_altura() -> void:
	var t := CombatRules.segment_circle_fraction(
		Vector3(0, 1, 0), Vector3(10, 1, 0), Vector3(5, 0, 0), 1.0
	)
	assert_almost_eq(t, 0.4, 0.0001)


func test_flecha_cruza_a_muralha_no_meio() -> void:
	# Muralha de z=-1 a z=1 em x=4: a flecha de x=0 a x=10 cruza em t = 0,4.
	var t := CombatRules.segment_cross_fraction(
		Vector3.ZERO, Vector3(10, 0, 0), Vector3(4, 0, -1), Vector3(4, 0, 1)
	)
	assert_almost_eq(t, 0.4, 0.0001)


func test_flecha_que_passa_ao_lado_da_muralha_segue() -> void:
	var t := CombatRules.segment_cross_fraction(
		Vector3.ZERO, Vector3(10, 0, 0), Vector3(4, 0, 0.5), Vector3(4, 0, 2)
	)
	assert_eq(t, CombatRules.NO_HIT)


func test_flecha_paralela_a_muralha_segue() -> void:
	var t := CombatRules.segment_cross_fraction(
		Vector3.ZERO, Vector3(10, 0, 0), Vector3(0, 0, 1), Vector3(10, 0, 1)
	)
	assert_eq(t, CombatRules.NO_HIT)


func test_lentidao_de_25_por_cento() -> void:
	assert_almost_eq(CombatRules.slowed(6.0, 0.25), 4.5, 0.0001)
	assert_almost_eq(CombatRules.slowed(6.0, 0.0), 6.0, 0.0001)
