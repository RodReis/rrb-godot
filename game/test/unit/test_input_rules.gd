extends GutTest

const EPS: Vector3 = Vector3(0.0001, 0.0001, 0.0001)


func test_componente_vertical_e_zerada() -> void:
	assert_almost_eq(InputRules.sanitize_direction(Vector3(1, 5, 0)), Vector3(1, 0, 0), EPS)


func test_vetor_longo_e_limitado_a_comprimento_1() -> void:
	assert_almost_eq(InputRules.sanitize_direction(Vector3(3, 0, 4)), Vector3(0.6, 0, 0.8), EPS)


func test_vetor_curto_e_preservado() -> void:
	assert_almost_eq(InputRules.sanitize_direction(Vector3(0.5, 0, 0)), Vector3(0.5, 0, 0), EPS)


func test_zero_continua_zero() -> void:
	assert_eq(InputRules.sanitize_direction(Vector3.ZERO), Vector3.ZERO)


func test_nan_vira_zero() -> void:
	assert_eq(InputRules.sanitize_direction(Vector3(NAN, 0, 1)), Vector3.ZERO)


func test_infinito_vira_zero() -> void:
	assert_eq(InputRules.sanitize_direction(Vector3(INF, 0, 0)), Vector3.ZERO)
