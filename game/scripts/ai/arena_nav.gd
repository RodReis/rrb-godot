class_name ArenaNav
extends NavigationRegion3D
## Navmesh do bot, assado em runtime dos colisores estaticos da arena (chao, muros, rio,
## cratera, borda). O portao do proprio bot fica de fora (ele passa); o do adversario vira
## parede, para o bot nao empurrar o portao atras do jogador. A colisao por time continua no
## Hero (GateRules). So no servidor, quando ha bot. Portoes caidos (5:00): main.gd refaz o
## navmesh sem parede e o bot entra na base do jogador (PI 2026-10-09, #52). Dois bots no mesmo
## processo (soak bot x bot, F19) tem um ArenaNav por time, cada um no proprio mapa (own_map): a
## parede de portao de um nao pode valer para o outro.

const GROUP: StringName = &"arena_nav"

## Capsula do heroi (r 0,4, h 1,8 em knight.tscn) arredondada para cima nas celulas de 0,25 u
## do mapa (o gerador avisa se nao for multiplo); geometria, nao balanceamento.
const AGENT_RADIUS: float = 0.5
const AGENT_HEIGHT: float = 2.0
## Arena plana: sem degrau, o prisma do rio nao vira rampa.
const AGENT_MAX_CLIMB: float = 0.0

## Time do bot dono deste navmesh; o BotInput acha o mapa pelo time do heroi.
var team: int = GateRules.TEAM_NEUTRAL
## Mapa de navegacao proprio em vez do padrao do mundo; ligar antes do 1o bake.
var own_map: bool = false

var _map: RID


func _ready() -> void:
	add_to_group(GROUP)


func _exit_tree() -> void:
	if _map.is_valid():
		NavigationServer3D.free_rid(_map)


## [param blocked_layers]: camadas extras que viram parede (portao do time adversario do bot).
func bake(arena: Node3D, blocked_layers: int = 0) -> void:
	if own_map and not _map.is_valid():
		_create_map()
	var mesh := NavigationMesh.new()
	mesh.agent_radius = AGENT_RADIUS
	mesh.agent_height = AGENT_HEIGHT
	mesh.agent_max_climb = AGENT_MAX_CLIMB
	mesh.cell_size = NavigationServer3D.map_get_cell_size(get_world_3d().navigation_map)
	mesh.cell_height = NavigationServer3D.map_get_cell_height(get_world_3d().navigation_map)
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = PhysicsLayers.WORLD | PhysicsLayers.RIVER | blocked_layers
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, source, arena)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	navigation_mesh = mesh
	print("[bot] navmesh: %d poligonos" % mesh.get_polygon_count())


## Mapa novo, ativo e com as celulas do mapa padrao (o navmesh assado usa o mesmo tamanho).
func _create_map() -> void:
	var world_map := get_world_3d().navigation_map
	_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(_map, NavigationServer3D.map_get_cell_size(world_map))
	NavigationServer3D.map_set_cell_height(_map, NavigationServer3D.map_get_cell_height(world_map))
	NavigationServer3D.map_set_active(_map, true)
	set_navigation_map(_map)
