class_name App
extends Control
## Raiz do Launcher (ARCHITECTURE-LAUNCHER §3.1): barra superior, pilha de telas, rodape e os
## overlays globais (toast, modal, carregando). Le o settings.cfg no boot e aplica video e audio no
## proprio Launcher; reaplica a cada gravacao. Telas emitem; quem navega e confirma e o App.
## --gallery (depois do --) abre a galeria do design system, a prova visual dos componentes.

const GALLERY_ARG: String = "--gallery"
## Toast no canto inferior direito, acima do rodape.
const TOAST_WIDTH: float = 360.0

var settings: SettingsStore = SettingsStore.new()

var _bar: AppBar = AppBar.new()
var _stack: ScreenStack = ScreenStack.new()
var _footer: ScreenFooter = ScreenFooter.new()
var _toast: Toast = Toast.new()
var _modal: ModalDialog = ModalDialog.new()
var _loading: Control = Control.new()
var _loading_box: StateBox = StateBox.new()


func _ready() -> void:
	settings.load_values()
	_apply(settings.values)
	settings.saved.connect(_apply)
	_build()
	_stack.scenes = Router.scenes()
	_stack.screen_pushed.connect(_on_stack_screen_pushed)
	_stack.screen_changed.connect(_on_stack_screen_changed)
	_bar.navigate_requested.connect(_on_bar_navigate_requested)
	_bar.quit_requested.connect(_on_bar_quit_requested)
	var gallery := GALLERY_ARG in OS.get_cmdline_user_args()
	_stack.push(Router.GALLERY if gallery else Router.HOME)


func show_toast(text: String, kind: Toast.Kind = Toast.Kind.INFO) -> void:
	_toast.show_message(text, kind)


## Confirmacao modal: devolve o indice do botao (ModalDialog.CANCELLED com Esc).
func confirm(title: String, body: String, actions: Array[DialogAction]) -> int:
	return await _modal.open(title, body, actions)


## Bloqueia a tela com o spinner (login, fila; F25+).
func show_loading(message: String = "") -> void:
	_loading.visible = true
	_stack.locked = true
	_loading_box.set_state(StateBox.State.LOADING, message)


func hide_loading() -> void:
	_loading.visible = false
	_stack.locked = false
	_loading_box.set_state(StateBox.State.IDLE)


func _build() -> void:
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	page.add_theme_constant_override(&"separation", 0)
	add_child(page)
	page.add_child(_bar)
	_stack.size_flags_vertical = SIZE_EXPAND_FILL
	page.add_child(_stack)
	_footer.bind([], "", AppBar.BRAND)
	page.add_child(_footer)
	_toast.theme_type_variation = &"LnToast"
	_toast.message_variation = &"LnBody"
	_toast.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	_toast.custom_minimum_size.x = TOAST_WIDTH
	_toast.grow_horizontal = GROW_DIRECTION_BEGIN
	_toast.grow_vertical = GROW_DIRECTION_BEGIN
	_toast.position -= Vector2(UiTokens.SPACE_MARGIN, UiTokens.SIZE_FOOTER + UiTokens.SPACE_MARGIN)
	add_child(_toast)
	_loading.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_loading.mouse_filter = MOUSE_FILTER_STOP
	_loading.visible = false
	var dim := ColorRect.new()
	dim.color = ModalDialog.DIM
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_loading.add_child(dim)
	_loading_box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_loading.add_child(_loading_box)
	add_child(_loading)
	add_child(_modal)


func _apply(values: Dictionary) -> void:
	SettingsApplier.apply_video(values, get_window())
	SettingsApplier.apply_audio(values)


func _on_stack_screen_pushed(_route: StringName, screen: Control) -> void:
	var settings_screen := screen as SettingsScreen
	if settings_screen == null:
		return
	settings_screen.bind(settings)
	settings_screen.reset_requested.connect(_on_settings_reset_requested.bind(settings_screen))
	settings_screen.save_failed.connect(show_toast.bind(Toast.Kind.ERROR))


func _on_stack_screen_changed(route: StringName) -> void:
	_bar.set_current(route)
	var hints: Array[HotkeyHint] = []
	if _stack.depth() > 1:
		hints.append(HotkeyHint.make("ESC", tr("Voltar")))
	_footer.bind(hints, "", AppBar.BRAND)


func _on_bar_navigate_requested(route: StringName) -> void:
	_stack.push(route)


func _on_bar_quit_requested() -> void:
	var actions: Array[DialogAction] = [
		DialogAction.make(tr("CANCELAR")),
		DialogAction.make(tr("SAIR DO JOGO"), DialogAction.Kind.DANGER),
	]
	if await confirm(tr("Sair do jogo?"), tr("O Launcher será fechado."), actions) == 1:
		get_tree().quit()


func _on_settings_reset_requested(screen: SettingsScreen) -> void:
	var actions: Array[DialogAction] = [
		DialogAction.make(tr("CANCELAR")),
		DialogAction.make(tr("RESTAURAR"), DialogAction.Kind.DANGER),
	]
	var body := tr("Vídeo, áudio, controles e gráficos voltam ao padrão e são gravados agora.")
	if await confirm(tr("Restaurar padrões?"), body, actions) == 1:
		screen.restore_defaults()
