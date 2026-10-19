extends GutTest
## PaladinRules (GDB §4.9, F76): 1o alvo da faixa do Golpe Consagrado, quando a Retribuicao devolve
## e quanto devolve.

const AHEAD: Vector3 = Vector3(0, 0, -1)
const LENGTH: float = 2.5
const WIDTH: float = 1.0


func _first(points: Array[Vector3]) -> int:
	return PaladinRules.first_in_strip(
		Vector3.ZERO, AHEAD, PackedVector3Array(points), LENGTH, WIDTH
	)


func test_pega_o_mais_perto_na_faixa() -> void:
	assert_eq(_first([Vector3(0, 0, -2.0), Vector3(0.2, 0, -1.0)]), 1)


func test_fora_da_largura_nao_conta() -> void:
	assert_eq(_first([Vector3(0.6, 0, -1.0), Vector3(0, 0, -2.0)]), 1, "0,6 u de lado: fora")
	assert_eq(_first([Vector3(0.5, 0, -1.0)]), 0, "borda da largura (0,5 u) conta")


func test_alem_do_comprimento_ou_atras_nao_conta() -> void:
	assert_eq(_first([Vector3(0, 0, -2.6)]), PaladinRules.NOT_FOUND)
	assert_eq(_first([Vector3(0, 0, -2.5)]), 0, "borda do comprimento conta")
	assert_eq(_first([Vector3(0, 0, 1.0)]), PaladinRules.NOT_FOUND, "atras")


func test_altura_nao_importa() -> void:
	assert_eq(_first([Vector3(0, 3.0, -1.0)]), 0)


func test_faixa_segue_a_frente() -> void:
	var first := PaladinRules.first_in_strip(
		Vector3(5, 0, 5), Vector3(1, 0, 0), PackedVector3Array([Vector3(7, 0, 5)]), LENGTH, WIDTH
	)
	assert_eq(first, 0)


func test_sem_candidato() -> void:
	assert_eq(_first([]), PaladinRules.NOT_FOUND)


func test_chefe_so_toma_o_dano() -> void:
	assert_true(PaladinRules.stuns(false))
	assert_false(PaladinRules.stuns(true))


func test_retribuicao_so_golpe_direto_de_perto_e_ativa() -> void:
	assert_true(PaladinRules.reflects(true, true, 2.9, 3.0))
	assert_true(PaladinRules.reflects(true, true, 3.0, 3.0), "borda de 3 u conta")
	assert_false(PaladinRules.reflects(true, true, 3.1, 3.0), "longe")
	assert_false(PaladinRules.reflects(true, false, 1.0, 3.0), "projetil, zona, pulso")
	assert_false(PaladinRules.reflects(false, true, 1.0, 3.0), "sem Retribuicao")


func test_dano_devolvido() -> void:
	# 25 % de 40 tomados + 20 % de 38 de ATK = 10 + 7,6.
	assert_eq(PaladinRules.reflected_damage(40, 0.25, 38.0, 0.2), 18)
	assert_eq(PaladinRules.reflected_damage(0, 0.45, 50.0, 0.2), 10, "imune: so o ATK")
	assert_eq(PaladinRules.reflected_damage(-5, 0.45, 0.0, 0.2), 0, "nunca negativo")
