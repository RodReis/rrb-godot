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


# Fumaca da Ladina (F58, ADR-0013, GDB §7.3): area circular temporaria que vale como moita.

const RADIUS: float = 3.0
const CLOUD: Vector3 = Vector3(5.0, 0.0, 5.0)


func test_ponto_dentro_do_raio_da_nuvem() -> void:
	assert_true(VisibilityRules.smoke_covers(CLOUD, CLOUD + Vector3(2.9, 0.0, 0.0), RADIUS))
	assert_true(VisibilityRules.smoke_covers(CLOUD, CLOUD + Vector3(3.0, 0.0, 0.0), RADIUS))


func test_ponto_fora_do_raio_da_nuvem() -> void:
	assert_false(VisibilityRules.smoke_covers(CLOUD, CLOUD + Vector3(3.1, 0.0, 0.0), RADIUS))


func test_altura_nao_importa_na_nuvem() -> void:
	assert_true(VisibilityRules.smoke_covers(CLOUD, CLOUD + Vector3(0.0, 6.0, 1.0), RADIUS))


func test_cada_nuvem_tem_o_proprio_bit() -> void:
	assert_eq(VisibilityRules.smoke_bit(0), 1)
	assert_eq(VisibilityRules.smoke_bit(1), 2)
	assert_eq(VisibilityRules.smoke_bit(3), 8)


func test_dentro_da_nuvem_some_para_quem_esta_fora() -> void:
	var inside := Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.smoke_bit(0))
	var outside := Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.NO_SMOKE)
	assert_true(VisibilityRules.is_hidden_in(inside, outside, 0))


func test_dois_dentro_da_mesma_nuvem_se_veem() -> void:
	var inside := Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.smoke_bit(0))
	assert_false(VisibilityRules.is_hidden_in(inside, inside, 0))


func test_nuvem_de_outra_ladina_nao_enxerga_esta() -> void:
	var mine := Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.smoke_bit(0))
	var other := Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.smoke_bit(1))
	assert_true(VisibilityRules.is_hidden_in(mine, other, 0))


func test_fora_de_moita_e_nuvem_e_visivel() -> void:
	var none := Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.NO_SMOKE)
	assert_false(VisibilityRules.is_hidden_in(none, none, 0))


func test_revelado_aparece_mesmo_na_nuvem() -> void:
	var inside := Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.smoke_bit(0))
	var outside := Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.NO_SMOKE)
	assert_false(VisibilityRules.is_hidden_in(inside, outside, 1))


func test_moita_sozinha_segue_a_regra_antiga() -> void:
	var in_grass := Vector2i(0, VisibilityRules.NO_SMOKE)
	var outside := Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.NO_SMOKE)
	var other_grass := Vector2i(1, VisibilityRules.NO_SMOKE)
	assert_true(VisibilityRules.is_hidden_in(in_grass, outside, 0))
	assert_false(VisibilityRules.is_hidden_in(in_grass, in_grass, 0))
	assert_true(VisibilityRules.is_hidden_in(in_grass, other_grass, 0))


func test_moita_e_nuvem_ao_mesmo_tempo_conta_nas_duas() -> void:
	# Decisao do PI (2026-10-13): quem esta em qualquer das duas ve e e visto.
	var both := Vector2i(0, VisibilityRules.smoke_bit(0))
	var only_grass := Vector2i(0, VisibilityRules.NO_SMOKE)
	var only_smoke := Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.smoke_bit(0))
	var outside := Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.NO_SMOKE)
	assert_false(VisibilityRules.is_hidden_in(both, only_grass, 0))
	assert_false(VisibilityRules.is_hidden_in(both, only_smoke, 0))
	assert_true(VisibilityRules.is_hidden_in(both, outside, 0))
	assert_false(VisibilityRules.is_hidden_in(only_grass, both, 0), "e o inverso")
	assert_false(VisibilityRules.is_hidden_in(only_smoke, both, 0), "e o inverso")


func test_lancar_a_fumaca_nao_conta_como_acao_da_ladina() -> void:
	var idle := Vector4i(0, 0, 0, 0)
	assert_false(VisibilityRules.acted(idle, Vector4i(0, 0, 420, 0), false), "E isolado")
	assert_true(VisibilityRules.acted(idle, Vector4i(30, 0, 420, 0), false), "basico junto")
	assert_true(VisibilityRules.acted(idle, Vector4i(0, 240, 420, 0), false), "Q junto")
	assert_true(VisibilityRules.acted(idle, Vector4i(0, 0, 0, 1500), false), "R")


func test_o_e_dos_outros_herois_continua_contando() -> void:
	assert_true(VisibilityRules.acted(Vector4i.ZERO, Vector4i(0, 0, 90, 0), true))
	assert_true(VisibilityRules.acted(Vector4i.ZERO, Vector4i(0, 0, 90, 0)), "padrao")
