class_name ScreenStack
extends Control
## Pilha de telas do Launcher (ARCHITECTURE-LAUNCHER §3.4): push, pop e replace; Esc (ui_cancel) =
## pop. A tela de baixo fica escondida com o estado dela; a que aparece entra com fade (DUR_BASE).

## Rota da tela que ficou no topo (push, pop ou replace).
signal screen_changed(route: StringName)
## Tela recem-criada, para o App ligar os sinais e passar os dados (bind) uma vez.
signal screen_pushed(route: StringName, screen: Control)

## Rota -> cena. O App preenche com Router.scenes(); o teste injeta cenas minimas.
var scenes: Dictionary[StringName, PackedScene] = {}
## Travada (carregando global do App): Esc nao desempilha.
var locked: bool = false

var _screens: Array[Control] = []
var _routes: Array[StringName] = []


func _unhandled_input(event: InputEvent) -> void:
	if not locked and event.is_action_pressed(&"ui_cancel") and pop():
		if is_inside_tree():
			get_viewport().set_input_as_handled()


## Empilha a tela da rota; a mesma rota no topo nao empilha de novo. Sem cena: null.
func push(route: StringName) -> Control:
	if current_route() == route:
		return current()
	var packed: PackedScene = scenes.get(route)
	if packed == null:
		push_error("[stack] rota sem cena: %s" % route)
		return null
	if not _screens.is_empty():
		_screens.back().visible = false
	var screen := packed.instantiate() as Control
	screen.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(screen)
	_screens.append(screen)
	_routes.append(route)
	if screen is LauncherScreen:
		(screen as LauncherScreen).back_requested.connect(_on_screen_back_requested)
	screen_pushed.emit(route, screen)
	_show_top()
	return screen


## Desempilha; na raiz nao faz nada (e devolve false).
func pop() -> bool:
	if _screens.size() <= 1:
		return false
	_drop_top()
	_show_top()
	return true


## Troca a tela do topo (a raiz, se for a unica).
func replace(route: StringName) -> Control:
	if not _screens.is_empty():
		_drop_top()
	return push(route)


func current() -> Control:
	return null if _screens.is_empty() else _screens.back()


func current_route() -> StringName:
	return &"" if _routes.is_empty() else _routes.back()


func depth() -> int:
	return _screens.size()


func _drop_top() -> void:
	var top: Control = _screens.pop_back()
	_routes.pop_back()
	top.queue_free()


func _show_top() -> void:
	for i: int in _screens.size():
		if _screens[i] is LauncherScreen:
			(_screens[i] as LauncherScreen).can_go_back = i > 0
	var top := current()
	if top == null:
		return
	top.visible = true
	top.modulate.a = 0.0
	if is_inside_tree():
		top.create_tween().tween_property(top, ^"modulate:a", 1.0, UiTokens.DUR_BASE)
	else:
		top.modulate.a = 1.0
	screen_changed.emit(current_route())


func _on_screen_back_requested() -> void:
	pop()
