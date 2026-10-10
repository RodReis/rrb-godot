extends GutTest
## VisibilityRules (F32, CONVENTION §4.7, GDB §7.3): mato alto esconde quem esta dentro de quem
## esta fora; mesma moita se ve; atacar ou usar skill revela por 1,5 s; sem revelacao por
## proximidade.

const RULES: MatchRules = preload("res://shared/data/rules/match_pacing.tres")
const TICKRATE: int = 30

## Moita 4 x 4 girada 45 graus em (10, 0, 0), com a caixa de colisao 1,2 u acima (como na arena).
var _boxes: Array[Transform3D] = []


func before_each() -> void:
	var area := Transform3D(Basis(Vector3.UP, PI / 4.0), Vector3(10.0, 0.0, 0.0))
	var shape := area * Transform3D(Basis.IDENTITY, Vector3(0.0, 1.2, 0.0))
	var far := Transform3D(Basis.IDENTITY, Vector3(-10.0, 0.0, 0.0))
	_boxes = [
		VisibilityRules.grass_box(shape, Vector3(4.0, 2.4, 4.0)),
		VisibilityRules.grass_box(far, Vector3(4.0, 2.4, 3.0)),
	]


func test_ponto_no_centro_da_moita_esta_nela() -> void:
	assert_eq(VisibilityRules.grass_at(Vector3(10.0, 0.0, 0.0), _boxes), 0)
	assert_eq(VisibilityRules.grass_at(Vector3(-10.0, 0.0, 0.0), _boxes), 1)


func test_moita_girada_usa_a_caixa_orientada() -> void:
	# Canto da caixa sem giro (10+1,9; 1,9) fica fora da moita girada 45 graus.
	assert_eq(VisibilityRules.grass_at(Vector3(11.9, 0.0, 1.9), _boxes), VisibilityRules.NO_GRASS)
	# Ao longo do eixo girado, a 1,9 u do centro, ainda esta dentro.
	var inside := Vector3(10.0, 0.0, 0.0) + Basis(Vector3.UP, PI / 4.0) * Vector3(1.9, 0.0, 0.0)
	assert_eq(VisibilityRules.grass_at(inside, _boxes), 0)


func test_altura_nao_importa() -> void:
	assert_eq(VisibilityRules.grass_at(Vector3(10.0, 5.0, 0.0), _boxes), 0)


func test_fora_de_toda_moita() -> void:
	assert_eq(VisibilityRules.grass_at(Vector3.ZERO, _boxes), VisibilityRules.NO_GRASS)
	assert_eq(VisibilityRules.grass_at(Vector3.ZERO, []), VisibilityRules.NO_GRASS)


func test_fora_da_moita_e_visivel() -> void:
	assert_false(VisibilityRules.is_hidden(VisibilityRules.NO_GRASS, VisibilityRules.NO_GRASS, 0))
	assert_false(VisibilityRules.is_hidden(VisibilityRules.NO_GRASS, 0, 0))


func test_dentro_da_moita_some_para_quem_esta_fora() -> void:
	assert_true(VisibilityRules.is_hidden(0, VisibilityRules.NO_GRASS, 0))


func test_mesma_moita_se_ve() -> void:
	assert_false(VisibilityRules.is_hidden(0, 0, 0))


func test_outra_moita_nao_ve() -> void:
	assert_true(VisibilityRules.is_hidden(0, 1, 0))


func test_sem_revelacao_por_proximidade() -> void:
	# Observador colado na borda, do lado de fora (0,1 u alem da face): continua sem ver.
	var edge := Vector3(10.0, 0.0, 0.0) + Basis(Vector3.UP, PI / 4.0) * Vector3(2.1, 0.0, 0.0)
	var observer := VisibilityRules.grass_at(edge, _boxes)
	assert_eq(observer, VisibilityRules.NO_GRASS)
	assert_true(VisibilityRules.is_hidden(0, observer, 0))


func test_revelado_aparece_mesmo_dentro() -> void:
	assert_false(VisibilityRules.is_hidden(0, VisibilityRules.NO_GRASS, 1))


func test_revelacao_de_1_5_s_vem_do_tres() -> void:
	assert_almost_eq(RULES.grass_reveal_time, 1.5, 0.0001)
	assert_eq(VisibilityRules.reveal_ticks(RULES, TICKRATE), 45)


func test_atacar_e_usar_skill_contam_como_acao() -> void:
	var idle := Vector4i(0, 3, 0, 0)
	assert_false(VisibilityRules.acted(idle, idle))
	assert_true(VisibilityRules.acted(idle, Vector4i(20, 3, 0, 0)), "basico")
	assert_true(VisibilityRules.acted(idle, Vector4i(0, 3, 90, 0)), "skill E")
	assert_true(VisibilityRules.acted(idle, Vector4i(0, 3, 0, 300)), "skill R")


func test_rolamento_zera_o_basico_mas_conta_pela_skill() -> void:
	assert_true(VisibilityRules.acted(Vector4i(10, 0, 0, 0), Vector4i(0, 0, 150, 0)))


func test_recarga_correndo_nao_e_acao() -> void:
	assert_false(VisibilityRules.acted(Vector4i(10, 5, 0, 0), Vector4i(9, 4, 0, 0)))


func test_cliente_mostra_so_com_estado_novo_depois_da_revelacao() -> void:
	assert_false(VisibilityRules.shown_on_client(true, 0, 500), "escondido")
	assert_false(
		VisibilityRules.shown_on_client(false, 600, 590), "estado velho, de antes da moita"
	)
	assert_true(VisibilityRules.shown_on_client(false, 600, 600))
	assert_true(VisibilityRules.shown_on_client(false, 0, 0), "nunca escondido")
