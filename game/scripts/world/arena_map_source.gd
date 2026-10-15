class_name ArenaMapSource
extends RefCounted
## Le a arena (ilha_arcana.tscn) e entrega os pontos de interesse da tela Arena & Mapa do Launcher
## (F33): marcadores, pontes e moitas da propria cena, mais as 2 lagoas (sem no proprio). Usado
## pela ferramenta tools/ui/render_arena_map.gd, que grava shared/assets/ui/arena_map.tres, e pelo
## teste que confere que o arquivo gravado ainda bate com a cena.

## Lagoa NO (SPEC-046 §2.1, tools/arena/arena_dressing.gd LAGOON_A); a SE e a rotacao de 180 graus.
const LAGOON_A: Vector2 = Vector2(-26, -18)


## Pontos de interesse (ArenaMapPois.build) da arena instanciada em [param arena].
static func pois(arena: Node3D) -> Array[Dictionary]:
	var lagoons: Array[Vector2] = [LAGOON_A, -LAGOON_A]
	return ArenaMapPois.build(
		markers(arena),
		ground_of(arena.get_node("Bridges")),
		ground_of(arena.get_node("TallGrass")),
		lagoons
	)


## Marcadores da arena como Dictionaries puros (o que ArenaMapPois.build espera).
static func markers(arena: Node3D) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for node: Node in arena.find_children("*", "Marker3D", true, false):
		var marker := node as SpawnMarker
		if marker == null:
			continue
		var at := marker.global_position
		var entry: Dictionary = {
			"kind": int(marker.kind),
			"team": marker.team,
			"at": Vector2(at.x, at.z),
			"monster_id": String(marker.monster_id),
			"chest_kind": String(ChestRules.Kind.keys()[marker.chest_kind]).to_lower(),
		}
		found.append(entry)
	return found


## Centro (x, z) de cada filho 3D de [param parent].
static func ground_of(parent: Node) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for child: Node in parent.get_children():
		var node := child as Node3D
		if node == null:
			continue
		points.append(Vector2(node.global_position.x, node.global_position.z))
	return points
