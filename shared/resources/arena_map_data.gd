class_name ArenaMapData
extends Resource
## Dados da tela Arena & Mapa (F33), gerados junto com a imagem por tools/ui/render_arena_map.gd
## (shared/assets/ui/arena_map.tres + arena_map.png). O Launcher le este arquivo e nunca carrega
## cena de arena (ARCHITECTURE-LAUNCHER I9). Edite o gerador, nao este arquivo.

## Enquadramento da imagem (copia das constantes de ArenaMapView no momento do render: um teste
## falha se elas mudarem e a imagem nao for regerada).
@export var view_pitch_degrees: float = 0.0
@export var view_height: float = 0.0
@export var view_aspect: float = 0.0
@export var image_size: Vector2i = Vector2i.ZERO
## Pontos de interesse (ArenaMapPois.build): [{id, groups: [{anchor, monsters, chests}]}].
@export var pois: Array[Dictionary] = []


## O ponto de interesse com o id (ArenaMapPois.BASE_A...), ou {} se nao existe.
func poi(id: String) -> Dictionary:
	for entry: Dictionary in pois:
		if entry["id"] == id:
			return entry
	return {}


## O enquadramento gravado e o de ArenaMapView? Falso = a imagem esta velha.
func matches_view() -> bool:
	return (
		is_equal_approx(view_pitch_degrees, ArenaMapView.PITCH_DEGREES)
		and is_equal_approx(view_height, ArenaMapView.VIEW_HEIGHT)
		and is_equal_approx(view_aspect, ArenaMapView.ASPECT)
	)
