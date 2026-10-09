extends GutTest


func test_time_dono_passa_pelo_proprio_portao() -> void:
	assert_true(GateRules.can_pass(GateRules.TEAM_A, GateRules.TEAM_A, false))


func test_adversario_nao_passa_antes_da_queda() -> void:
	assert_false(GateRules.can_pass(GateRules.TEAM_B, GateRules.TEAM_A, false))


func test_todos_passam_depois_de_gates_fallen() -> void:
	assert_true(GateRules.can_pass(GateRules.TEAM_B, GateRules.TEAM_A, true))


func test_cada_portao_tem_sua_camada() -> void:
	assert_eq(GateRules.gate_layer(GateRules.TEAM_A), GateRules.LAYER_GATE_A)
	assert_eq(GateRules.gate_layer(GateRules.TEAM_B), GateRules.LAYER_GATE_B)


func test_mascara_do_heroi_inclui_mundo_rio_e_portao_adversario() -> void:
	var mask := GateRules.hero_mask(GateRules.TEAM_A)
	assert_true(mask & GateRules.LAYER_WORLD != 0)
	assert_true(mask & GateRules.LAYER_RIVER != 0)
	assert_true(mask & GateRules.LAYER_GATE_B != 0)
	assert_eq(mask & GateRules.LAYER_GATE_A, 0)


func test_mascara_do_time_b_ignora_o_proprio_portao() -> void:
	var mask := GateRules.hero_mask(GateRules.TEAM_B)
	assert_true(mask & GateRules.LAYER_GATE_A != 0)
	assert_eq(mask & GateRules.LAYER_GATE_B, 0)
