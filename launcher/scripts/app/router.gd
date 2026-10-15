class_name Router
extends RefCounted
## Rotas do Launcher (ARCHITECTURE-LAUNCHER §3.4): nome -> cena da tela. So entra rota de tela que
## existe; o menu da barra superior (NAV) so aponta para rota (FRONTEND-LAUNCHER §8.4).

const LOGIN: StringName = &"login"
const LOBBY: StringName = &"lobby"
const HISTORY: StringName = &"history"
const BESTIARY: StringName = &"bestiary"
const FORGE: StringName = &"forge"
const SETTINGS: StringName = &"settings"
## Galeria do design system (prova visual dos componentes): so por --gallery, fora do menu.
const GALLERY: StringName = &"gallery"
## Raiz da pilha com sessao (§3.4); sem sessao o App abre no LOGIN.
const HOME: StringName = LOBBY
const ROUTES: Dictionary[StringName, String] = {
	LOGIN: "res://scenes/screens/login.tscn",
	LOBBY: "res://scenes/screens/lobby.tscn",
	HISTORY: "res://scenes/screens/history.tscn",
	BESTIARY: "res://scenes/screens/bestiary.tscn",
	FORGE: "res://scenes/screens/forge.tscn",
	SETTINGS: "res://scenes/screens/settings.tscn",
	GALLERY: "res://shared/ui/components/_gallery.tscn",
}
## Menu da barra superior, na ordem: rota -> rotulo (Herois do prototipo: ainda sem tela).
const NAV: Dictionary[StringName, String] = {
	LOBBY: "LOBBY", BESTIARY: "GUIA & BESTIÁRIO", HISTORY: "HISTÓRICO", SETTINGS: "AJUSTES"
}
## Telas que o menu destaca pelo item de outra rota: a Forja e a aba do Guia & Bestiario.
const NAV_PARENT: Dictionary[StringName, StringName] = {FORGE: BESTIARY}


## Item do menu que representa a rota (ela mesma, ou o pai: a Forja destaca o Guia & Bestiario).
static func nav_route(route: StringName) -> StringName:
	return NAV_PARENT.get(route, route)


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
