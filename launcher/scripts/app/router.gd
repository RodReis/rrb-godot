class_name Router
extends RefCounted
## Rotas do Launcher (ARCHITECTURE-LAUNCHER §3.4): nome -> cena da tela. So entra rota de tela que
## existe; o menu da barra superior (NAV) so aponta para rota (FRONTEND-LAUNCHER §8.4).

const LOGIN: StringName = &"login"
const LOBBY: StringName = &"lobby"
const SETTINGS: StringName = &"settings"
## Galeria do design system (prova visual dos componentes): so por --gallery, fora do menu.
const GALLERY: StringName = &"gallery"
## Raiz da pilha com sessao (§3.4); sem sessao o App abre no LOGIN.
const HOME: StringName = LOBBY
const ROUTES: Dictionary[StringName, String] = {
	LOGIN: "res://scenes/screens/login.tscn",
	LOBBY: "res://scenes/screens/lobby.tscn",
	SETTINGS: "res://scenes/screens/settings.tscn",
	GALLERY: "res://shared/ui/components/_gallery.tscn",
}
## Menu da barra superior, na ordem: rota -> rotulo (Herois e Historico do prototipo: F27/F26).
const NAV: Dictionary[StringName, String] = {LOBBY: "LOBBY", SETTINGS: "AJUSTES"}


static func has_route(route: StringName) -> bool:
	return ROUTES.has(route)


static func scene(route: StringName) -> PackedScene:
	if not has_route(route):
		push_error("[router] rota desconhecida: %s" % route)
		return null
	return load(ROUTES[route]) as PackedScene


static func scenes() -> Dictionary[StringName, PackedScene]:
	var loaded: Dictionary[StringName, PackedScene] = {}
	for route: StringName in ROUTES:
		loaded[route] = scene(route)
	return loaded
