class_name ArenaNav
extends NavigationRegion3D
## Navmesh do bot, assado em runtime dos colisores estaticos da arena (chao, muros, rio,
## cratera, borda). Portoes ficam de fora (camadas GATE_*): o bot passa pelo proprio portao e
## nao mira a base inimiga na fase 1; a colisao por time continua no Hero (GateRules).
## So no servidor, quando ha bot.

## Capsula do heroi (r 0,4, h 1,8 em knight.tscn) arredondada para cima nas celulas de 0,25 u
## do mapa (o gerador avisa se nao for multiplo); geometria, nao balanceamento.
const AGENT_RADIUS: float = 0.5
const AGENT_HEIGHT: float = 2.0
## Arena plana: sem degrau, o prisma do rio nao vira rampa.
const AGENT_MAX_CLIMB: float = 0.0


func bake(arena: Node3D) -> void:
	var mesh := NavigationMesh.new()
	mesh.agent_radius = AGENT_RADIUS
	mesh.agent_height = AGENT_HEIGHT
	mesh.agent_max_climb = AGENT_MAX_CLIMB
	mesh.cell_size = NavigationServer3D.map_get_cell_size(get_world_3d().navigation_map)
	mesh.cell_height = NavigationServer3D.map_get_cell_height(get_world_3d().navigation_map)
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = PhysicsLayers.WORLD | PhysicsLayers.RIVER
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, source, arena)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	navigation_mesh = mesh
	print("[bot] navmesh: %d poligonos" % mesh.get_polygon_count())
