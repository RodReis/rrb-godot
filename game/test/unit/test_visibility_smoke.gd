extends GutTest
## VisibilityRules com a fumaca da Ladina (F58, ADR-0013, GDB §7.3): area circular temporaria que
## vale como moita; moita e nuvem juntas contam nas duas; lancar a fumaca nao revela.

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
