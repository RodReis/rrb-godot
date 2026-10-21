extends GutTest
## F24: tela Configuracoes — remapear tecla (troca sem conflito, Esc cancela), salvar grava o
## rascunho pelo SettingsStore, restaurar volta aos padroes e a aba Creditos troca o corpo.

const SCENE: PackedScene = preload("res://scenes/screens/settings.tscn")
const TMP_PATH: String = "user://test_f24_screen.cfg"

var _store: SettingsStore
var _screen: SettingsScreen


func before_each() -> void:
	_store = SettingsStore.new(TMP_PATH)
	_store.load_values()
	_screen = add_child_autofree(SCENE.instantiate())
	_screen.bind(_store)
	await wait_process_frames(1)


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_PATH))


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event


func _keycap(text: String) -> Button:
	for button: Node in _screen.find_children("*", "Button", true, false):
		if (button as Button).text == text and (button as Button).toggle_mode:
			return button as Button
	return null


## F79: o seletor "Tipo de tela" tem as 3 opcoes; a resolucao so vale em Modo Janela.
func _picker_with(first_item: String) -> OptionButton:
	for node: Node in _screen.find_children("*", "OptionButton", true, false):
		var picker := node as OptionButton
		if picker.item_count > 0 and picker.get_item_text(0) == first_item:
			return picker
	return null


func _window_mode() -> String:
	return _screen.draft()[UserSettings.VIDEO][UserSettings.WINDOW_MODE]


func test_tipo_de_tela_lista_as_tres_opcoes() -> void:
	var picker := _picker_with("Modo Janela")
	assert_not_null(picker, "seletor Tipo de tela")
	var texts: Array[String] = []
	for i: int in picker.item_count:
		texts.append(picker.get_item_text(i))
	assert_eq(texts, ["Modo Janela", "Janela sem Borda", "Tela Cheia Exclusiva"] as Array[String])
	assert_eq(picker.selected, 1, "padrao: janela sem borda")


func test_escolher_o_tipo_de_tela_grava_no_rascunho_e_desabilita_a_resolucao() -> void:
	var mode := _picker_with("Modo Janela")
	var resolution := _picker_with("1280 x 720")
	assert_not_null(resolution, "seletor de resolucao")
	assert_true(resolution.disabled, "janela sem borda (padrao) nao usa a resolucao")
	mode.item_selected.emit(0)
	assert_eq(_window_mode(), UserSettings.WINDOWED)
	assert_false(resolution.disabled, "modo janela usa a resolucao")
	mode.item_selected.emit(2)
	assert_eq(_window_mode(), UserSettings.EXCLUSIVE)
	assert_true(resolution.disabled, "tela cheia exclusiva nao usa a resolucao")


func test_tipo_de_tela_salvo_volta_selecionado() -> void:
	var values := UserSettings.defaults()
	values[UserSettings.VIDEO][UserSettings.WINDOW_MODE] = UserSettings.EXCLUSIVE
	_store.save(values)
	_screen.bind(_store)
	await wait_process_frames(1)
	assert_eq(_picker_with("Modo Janela").selected, 2)


func test_remapear_tecla_troca_no_rascunho() -> void:
	_keycap("Q").pressed.emit()
	_screen._input(_key(KEY_E))
	assert_eq(UserSettings.keycode(_screen.draft(), InputActions.SKILL_Q), KEY_E)
	assert_eq(UserSettings.keycode(_screen.draft(), InputActions.SKILL_E), KEY_Q, "troca")


func test_esc_cancela_o_remapeamento() -> void:
	_keycap("Q").pressed.emit()
	_screen._input(_key(KEY_ESCAPE))
	assert_eq(UserSettings.keycode(_screen.draft(), InputActions.SKILL_Q), KEY_Q)
	assert_not_null(_keycap("Q"), "tecla volta a mostrar Q")


func test_salvar_grava_o_rascunho() -> void:
	_keycap("F").pressed.emit()
	_screen._input(_key(KEY_G))
	var save := _screen.find_children("*", "Button", true, false).filter(
		func(node: Node) -> bool: return (node as Button).theme_type_variation == &"LnButtonPrimary"
	)
	(save[0] as Button).pressed.emit()
	var saved := SettingsStore.new(TMP_PATH).load_values()
	assert_eq(UserSettings.keycode(saved, InputActions.INTERACT), KEY_G)


func test_restaurar_padroes_grava_e_redesenha() -> void:
	var values := UserSettings.rebind(UserSettings.defaults(), InputActions.DODGE, KEY_C)
	_store.save(values)
	_screen.bind(_store)
	_screen.restore_defaults()
	assert_eq(_screen.draft(), UserSettings.defaults())
	assert_eq(SettingsStore.new(TMP_PATH).load_values(), UserSettings.defaults())


func test_aba_creditos_mostra_os_creditos() -> void:
	_screen.select_tab(SettingsScreen.Tab.CREDITS)
	var credits := _screen.find_children("*", "CreditsView", true, false)
	assert_eq(credits.size(), 1)
	assert_true((credits[0] as Control).visible)
	_screen.select_tab(SettingsScreen.Tab.CONTROLS)
	assert_false((credits[0] as Control).visible)


func test_creditos_trazem_a_licenca_do_godot() -> void:
	assert_string_contains(CreditsView.license_text(), "Godot Engine")


func test_clicar_de_novo_na_tecla_cancela_a_escuta() -> void:
	var keycap := _keycap("Q")
	keycap.pressed.emit()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_screen._input(click)
	keycap.pressed.emit()  # o toggle chega no release
	_screen._input(_key(KEY_Z))
	assert_eq(UserSettings.keycode(_screen.draft(), InputActions.SKILL_Q), KEY_Q)


func test_aba_de_controles_lista_e_remapeia_o_zoom_da_camera() -> void:
	assert_not_null(_keycap("="), "zoom in mostra a tecla padrao")
	assert_not_null(_keycap("-"), "zoom out mostra a tecla padrao")
	_keycap("=").pressed.emit()
	_screen._input(_key(KEY_Z))
	assert_eq(UserSettings.keycode(_screen.draft(), InputActions.CAMERA_ZOOM_IN), KEY_Z)
	assert_not_null(_keycap("Z"))


## SPEC-097 (ADR-0031): "Tamanho da interface na partida" vai de 70 a 100 %, abre em 85 % e
## grava [ui] hud_scale ao salvar; restaurar padroes volta a 85 % (test_restaurar_padroes).
func test_tamanho_da_interface_grava_a_escala_ao_salvar() -> void:
	var sliders := _screen.find_children("*", "HSlider", true, false).filter(
		func(node: Node) -> bool: return (node as HSlider).min_value == UserSettings.HUD_SCALE_MIN
	)
	assert_eq(sliders.size(), 1, "um slider de tamanho da interface")
	var slider := sliders[0] as HSlider
	assert_eq(slider.max_value, UserSettings.HUD_SCALE_MAX)
	assert_almost_eq(slider.value, 0.85, 0.0001)
	slider.value = 0.7
	assert_almost_eq(_screen.draft()[UserSettings.UI][UserSettings.HUD_SCALE], 0.7, 0.0001)
	var labels := _screen.find_children("*", "Label", true, false).filter(
		func(node: Node) -> bool: return (node as Label).text == "70%"
	)
	assert_eq(labels.size(), 1, "valor em %")
	var save := _screen.find_children("*", "Button", true, false).filter(
		func(node: Node) -> bool: return (node as Button).theme_type_variation == &"LnButtonPrimary"
	)
	(save[0] as Button).pressed.emit()
	var saved := SettingsStore.new(TMP_PATH).load_values()
	assert_almost_eq(saved[UserSettings.UI][UserSettings.HUD_SCALE], 0.7, 0.0001)


func test_salvar_nao_mexe_na_distancia_da_camera_do_rascunho() -> void:
	var values := UserSettings.defaults()
	values[UserSettings.CAMERA][UserSettings.DISTANCE] = 9.0
	_store.save(values)
	_screen.bind(_store)
	assert_eq(_screen.draft()[UserSettings.CAMERA][UserSettings.DISTANCE], 9.0)
