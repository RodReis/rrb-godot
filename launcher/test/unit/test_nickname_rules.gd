extends GutTest
## F35: NicknameRules espelha o SetNicknameDto do backend (CONVENTION §4.8): 3-16 caracteres
## A-Z a-z 0-9 _; o "#" e so de exibicao e nunca faz parte do nome.


func test_aceita_o_formato_da_regra() -> void:
	for nick: String in ["abc", "Rod_Reis", "a1b2c3d4e5f6g7h8", "___", "123", "RodReis"]:
		assert_true(NicknameRules.is_valid(nick), nick)


func test_recusa_curto_e_longo() -> void:
	assert_false(NicknameRules.is_valid(""))
	assert_false(NicknameRules.is_valid("ab"))
	assert_false(NicknameRules.is_valid("a".repeat(17)))
	assert_true(NicknameRules.is_valid("a".repeat(16)))


func test_recusa_caractere_fora_de_az_09_underscore() -> void:
	for nick: String in ["rod reis", "rod-reis", "ródrigo", "#RodReis", "rod.reis", "ｒｏｄｒｅｉｓ"]:
		assert_false(NicknameRules.is_valid(nick), nick)


func test_quebra_de_linha_no_fim_nao_passa() -> void:
	assert_false(NicknameRules.is_valid("RodReis\n"), "o $ do PCRE aceitaria; o \\z nao")
	assert_false(NicknameRules.is_valid("\nRodReis"))


func test_exibicao_poe_o_prefixo_so_na_tela() -> void:
	assert_eq(NicknameRules.display("RodReis"), "#RodReis")
	assert_eq(NicknameRules.display(""), "", "sem nickname nao aparece so o #")
