extends GutTest
## F25: tela de Login (FRONTEND-LAUNCHER §3.2, §8) com AuthService sobre ApiClient falso: abas,
## regra de senha so no cadastro, erro no campo certo, faixa de erro geral, olho da senha e
## envio com Enter.

const SCENE: PackedScene = preload("res://scenes/screens/login.tscn")
const TOKENS: Dictionary = {"accessToken": "acesso", "refreshToken": "refresh"}

var _api: FakeApiClient
var _login: LoginScreen


func before_each() -> void:
	_api = FakeApiClient.new()
	add_child_autofree(_api)
	_login = SCENE.instantiate() as LoginScreen
	add_child_autofree(_login)
	_login.bind(AuthService.new(_api))
	watch_signals(_login)


func _fill(email: String, password: String) -> void:
	_login.email_field().text = email
	_login.password_field().text = password


func test_entrar_com_sucesso_avisa_o_app() -> void:
	_api.reply("POST /auth/login", 200, TOKENS)
	_fill("duelista@rrb.dev", "senha1234")
	await _login.submit()
	assert_signal_emitted(_login, "authenticated")


func test_senha_errada_aparece_no_campo_e_nao_entra() -> void:
	_api.reply("POST /auth/login", 401, {"code": "INVALID_CREDENTIALS"})
	_fill("duelista@rrb.dev", "errada123")
	await _login.submit()
	assert_signal_not_emitted(_login, "authenticated")
	var rows := _login.find_children("*", "FormRow", true, false)
	assert_true((rows[1] as FormRow).has_error(), "erro na linha da senha")
	assert_false((rows[0] as FormRow).has_error())


func test_backend_fora_mostra_a_faixa_de_erro() -> void:
	_fill("duelista@rrb.dev", "senha1234")
	await _login.submit()
	assert_string_contains(_login.error_text(), "fora do ar")
	assert_false(_login.submit_button().disabled, "botao volta depois do erro")


func test_cadastro_mostra_a_regra_e_troca_o_botao() -> void:
	_login.select_mode(LoginScreen.Mode.REGISTER)
	assert_string_contains(_login.submit_button().text, "FORJAR NOVA CONTA")
	var rule := _login.find_children("*", "Label", true, false).filter(
		func(label: Label) -> bool: return label.text.contains("Mínimo de 8")
	)
	assert_eq(rule.size(), 1)
	assert_true((rule[0] as Label).visible)
	_login.select_mode(LoginScreen.Mode.LOGIN)
	assert_false((rule[0] as Label).visible)


func test_cadastro_com_email_em_uso_marca_o_email() -> void:
	_login.select_mode(LoginScreen.Mode.REGISTER)
	_api.reply("POST /auth/register", 409, {"code": "EMAIL_TAKEN"})
	_fill("duelista@rrb.dev", "senha1234")
	await _login.submit()
	var rows := _login.find_children("*", "FormRow", true, false)
	assert_true((rows[0] as FormRow).has_error())


func test_olho_mostra_e_esconde_a_senha() -> void:
	var field := _login.find_children("*", "IconField", true, false)[1] as IconField
	assert_true(field.line_edit.secret)
	field.reveal_button().pressed.emit()
	assert_false(field.line_edit.secret)
	field.reveal_button().pressed.emit()
	assert_true(field.line_edit.secret)


func test_enter_no_email_vai_para_a_senha() -> void:
	await wait_process_frames(1)
	_login.email_field().grab_focus()
	_login.email_field().text_submitted.emit("duelista@rrb.dev")
	assert_true(_login.password_field().has_focus())
	assert_eq(_api.calls.size(), 0)


func test_treino_nao_precisa_de_conta() -> void:
	var practice := _login.find_children("*", "Button", true, false).filter(
		func(button: Button) -> bool: return button.text.contains("Treinar")
	)
	(practice[0] as Button).pressed.emit()
	assert_signal_emitted(_login, "practice_requested")
	assert_eq(_api.calls.size(), 0)
