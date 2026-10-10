extends GutTest
## Zona da fase 2 (GDB §7.1, ADR-0004 N4): raio interpolado entre os pontos de zone_times /
## zone_radius e dano em degrau por minuto de zone_damage_pct; tempo contado da fase 2 (5:00).

const RULES: String = "res://shared/data/rules/match_pacing.tres"

var _rules: MatchRules


func before_all() -> void:
	_rules = load(RULES) as MatchRules


func test_raio_em_cada_ponto_da_tabela() -> void:
	var expected: Array[float] = [35.0, 26.0, 17.5, 8.75, 3.5, 0.0]
	for i: int in expected.size():
		assert_almost_eq(ZoneRules.radius_at(_rules, 60.0 * i), expected[i], 0.001, "minuto %d" % i)


func test_raio_entre_pontos_e_linear() -> void:
	assert_almost_eq(ZoneRules.radius_at(_rules, 30.0), 30.5, 0.001, "0:30")
	assert_almost_eq(ZoneRules.radius_at(_rules, 90.0), 21.75, 0.001, "1:30")
	assert_almost_eq(ZoneRules.radius_at(_rules, 270.0), 1.75, 0.001, "4:30")


func test_raio_fora_da_tabela_fica_nas_pontas() -> void:
	assert_almost_eq(ZoneRules.radius_at(_rules, -5.0), 35.0, 0.001, "transicao antes do 0")
	assert_almost_eq(ZoneRules.radius_at(_rules, 400.0), 0.0, 0.001, "depois do colapso")


func test_dano_em_cada_ponto_da_tabela() -> void:
	var expected: Array[float] = [0.01, 0.02, 0.03, 0.04, 0.05, 0.05]
	for i: int in expected.size():
		assert_almost_eq(
			ZoneRules.damage_pct_at(_rules, 60.0 * i), expected[i], 0.0001, "minuto %d" % i
		)


func test_dano_entre_pontos_e_degrau_do_minuto_anterior() -> void:
	assert_almost_eq(ZoneRules.damage_pct_at(_rules, 59.9), 0.01, 0.0001)
	assert_almost_eq(ZoneRules.damage_pct_at(_rules, 90.0), 0.02, 0.0001)
	assert_almost_eq(ZoneRules.damage_pct_at(_rules, 239.9), 0.04, 0.0001)
	assert_almost_eq(ZoneRules.damage_pct_at(_rules, 270.0), 0.05, 0.0001)


func test_dano_antes_do_0_e_o_primeiro_degrau() -> void:
	assert_almost_eq(ZoneRules.damage_pct_at(_rules, -1.0), 0.01, 0.0001)


func test_fora_do_circulo_pela_distancia_no_plano() -> void:
	assert_false(ZoneRules.is_outside(Vector3(3.0, 0.0, 4.0), Vector3.ZERO, 5.0), "na borda")
	assert_true(ZoneRules.is_outside(Vector3(3.0, 0.0, 4.1), Vector3.ZERO, 5.0))
	assert_false(ZoneRules.is_outside(Vector3(0.0, 50.0, 0.0), Vector3.ZERO, 1.0), "altura conta 0")
	assert_true(ZoneRules.is_outside(Vector3(0.1, 0.0, 0.0), Vector3.ZERO, 0.0), "colapso")


func test_pulso_de_dano_e_fracao_do_hp_maximo() -> void:
	assert_eq(ZoneRules.damage(600, 0.01), 6)
	assert_eq(ZoneRules.damage(1005, 0.05), 50)
	assert_eq(ZoneRules.damage(40, 0.01), 1, "ao menos 1")


## Proximo fechamento (F17, HUD): o proximo ponto da tabela estritamente depois de agora.
func test_proximo_ponto_e_o_seguinte_ao_tempo_atual() -> void:
	assert_eq(ZoneRules.next_point(_rules, 0.0), 1, "5:00 -> 6:00")
	assert_eq(ZoneRules.next_point(_rules, 135.0), 3, "7:15 -> 8:00")
	assert_eq(ZoneRules.next_point(_rules, 299.9), 5, "9:59 -> 10:00")
	assert_eq(ZoneRules.next_point(_rules, 300.0), -1, "colapso: nenhum")


func test_tempo_ate_o_proximo_fechamento() -> void:
	assert_almost_eq(ZoneRules.until_next(_rules, 0.0), 60.0, 0.001)
	assert_almost_eq(ZoneRules.until_next(_rules, 135.0), 45.0, 0.001)
	assert_eq(ZoneRules.until_next(_rules, 300.0), 0.0, "depois do ultimo ponto")


func test_raio_do_proximo_fechamento() -> void:
	assert_almost_eq(ZoneRules.next_radius(_rules, 0.0), 26.0, 0.001)
	assert_almost_eq(ZoneRules.next_radius(_rules, 135.0), 8.75, 0.001)
	assert_almost_eq(ZoneRules.next_radius(_rules, 300.0), 0.0, 0.001, "fica no ultimo")
