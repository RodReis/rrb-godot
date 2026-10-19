extends GutTest
## #233: o ping mostrado e o menor das ultimas amostras; o custo da 1a requisicao depois de
## reconectar nao fica na tela. Falha esquece o historico.


func test_primeira_amostra_vira_o_valor() -> void:
	var filter := PingFilter.new()
	assert_eq(filter.add(80), 80)


func test_mostra_o_menor_das_ultimas_amostras() -> void:
	var filter := PingFilter.new()
	filter.add(80)  # 1a requisicao da conexao nova: mais lenta
	assert_eq(filter.add(36), 36)
	assert_eq(filter.add(40), 36)
	assert_eq(filter.add(38), 36)


func test_amostra_velha_sai_da_janela() -> void:
	var filter := PingFilter.new()
	filter.add(10)
	filter.add(50)
	filter.add(52)
	assert_eq(filter.add(54), 50, "a de 10 ms saiu da janela de %d" % PingFilter.WINDOW)


func test_subida_real_aparece_em_vez_de_ficar_presa() -> void:
	var filter := PingFilter.new()
	for i: int in PingFilter.WINDOW:
		filter.add(20)
	var shown := 0
	for i: int in PingFilter.WINDOW:
		shown = filter.add(120)
	assert_eq(shown, 120)


func test_falha_esquece_o_historico() -> void:
	var filter := PingFilter.new()
	filter.add(20)
	filter.reset()
	assert_eq(filter.add(90), 90)
