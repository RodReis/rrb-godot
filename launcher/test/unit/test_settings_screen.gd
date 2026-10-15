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
