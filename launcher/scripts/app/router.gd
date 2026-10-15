class_name Router
extends RefCounted
## Rotas do Launcher (ARCHITECTURE-LAUNCHER §3.4): nome -> cena da tela. So entra rota de tela que
## existe; o menu da barra superior (NAV) so aponta para rota (FRONTEND-LAUNCHER §8.4).

const SETTINGS: StringName = &"settings"
## Galeria do design system (prova visual dos componentes): so por --gallery, fora do menu.
const GALLERY: StringName = &"gallery"
## Tela da raiz da pilha. Configuracoes ate o lobby existir (F25), que passa a ser a raiz.
const HOME: StringName = SETTINGS
const ROUTES: Dictionary[StringName, String] = {
	SETTINGS: "res://scenes/screens/settings.tscn",
	GALLERY: "res://shared/ui/components/_gallery.tscn",
}
## Menu da barra superior, na ordem: rota -> rotulo.
const NAV: Dictionary[StringName, String] = {SETTINGS: "AJUSTES"}


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
