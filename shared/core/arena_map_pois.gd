class_name ArenaMapPois
extends RefCounted
## Pontos de interesse da tela Arena & Mapa (F33), montados dos marcadores da arena real: nada
## escrito a mao. A ferramenta de render (tools/ui/render_arena_map.gd) le os SpawnMarker da cena,
## chama build() e grava o resultado em shared/assets/ui/arena_map.tres; o Launcher so le esse
## arquivo (nunca carrega cena de arena, ARCHITECTURE-LAUNCHER I9).
##
## Marcador = Dictionary {kind, team, at: Vector2 (x, z), monster_id, chest_kind}; kind segue
## SpawnMarker.Kind (HERO 0, MONSTER 1, CHEST 2, BOSS 3). Cada ponto de interesse tem grupos
## (um por "campo"): {anchor, monsters: {id: n}, chests: {tipo: n}}.

const KIND_HERO: int = 0
const KIND_MONSTER: int = 1
const KIND_CHEST: int = 2
const KIND_BOSS: int = 3
## Marcadores da base: ate esta distancia do proprio spawn (GDB: base e o raio de 12,7 u).
const BASE_RADIUS: float = 13.0
## Marcadores de um mesmo campo ficam a ate esta distancia do vizinho mais proximo.
const FIELD_LINK: float = 7.0
## Campo a ate esta distancia do centro da arena = centro contestado (a ilha, SPEC-046 §2.2).
const CENTER_RADIUS: float = 14.0

const BASE_A: String = "base_a"
const BASE_B: String = "base_b"
const CRATER: String = "crater"
const CENTER_FIELDS: String = "center_fields"
const SIDE_FIELDS: String = "side_fields"
const CORNER_FIELDS: String = "corner_fields"
const RIVER: String = "river"
const BRIDGES: String = "bridges"
const TALL_GRASS: String = "tall_grass"
## Ordem estavel de saida.
const ORDER: Array[String] = [
	BASE_A, BASE_B, CRATER, CENTER_FIELDS, SIDE_FIELDS, CORNER_FIELDS, RIVER, BRIDGES, TALL_GRASS
]
const TEAM_A: int = 1
const TEAM_B: int = 2


## [param bridges], [param grass] e [param lagoons]: centros (x, z) dos elementos de terreno.
static func build(
	markers: Array[Dictionary],
	bridges: Array[Vector2],
	grass: Array[Vector2],
	lagoons: Array[Vector2],
) -> Array[Dictionary]:
	var groups: Dictionary[String, Array] = {}
	for id: String in ORDER:
		groups[id] = []
	var spawns := _spawns(markers)
	var base_members: Dictionary[String, Array] = {BASE_A: [], BASE_B: []}
	var rest: Array[Dictionary] = []
	for marker: Dictionary in markers:
		var kind: int = marker["kind"]
		if kind == KIND_HERO:
			continue
		if kind == KIND_BOSS:
			groups[CRATER].append(_group(marker["at"], [marker]))
			continue
		var base := _base_of(marker, spawns)
		if base.is_empty():
			rest.append(marker)
		else:
			base_members[base].append(marker)
	for team: int in spawns:
		var id := BASE_A if team == TEAM_A else BASE_B
		groups[id].append(_group(spawns[team], base_members[id]))
	_add_fields(groups, rest)
	for at: Vector2 in lagoons:
		groups[RIVER].append(_group(at, []))
	for at: Vector2 in bridges:
		groups[BRIDGES].append(_group(at, []))
	for at: Vector2 in grass:
		groups[TALL_GRASS].append(_group(at, []))
	var pois: Array[Dictionary] = []
	for id: String in ORDER:
		var list: Array = groups[id]
		if list.is_empty():
			continue
		list.sort_custom(_by_position)
		pois.append({"id": id, "groups": list})
	return pois


## Todos os campos do ponto de interesse tem o mesmo conteudo? (a tela mostra o de um e diz "N").
static func is_uniform(poi: Dictionary) -> bool:
	var groups: Array = poi["groups"]
	for group: Dictionary in groups:
		if group["monsters"] != groups[0]["monsters"] or group["chests"] != groups[0]["chests"]:
			return false
	return true


static func _spawns(markers: Array[Dictionary]) -> Dictionary[int, Vector2]:
	var spawns: Dictionary[int, Vector2] = {}
	for marker: Dictionary in markers:
		if marker["kind"] == KIND_HERO:
			spawns[marker["team"]] = marker["at"]
	return spawns


## "base_a" / "base_b" se o marcador e de um time e esta no raio da base dele; senao "".
static func _base_of(marker: Dictionary, spawns: Dictionary[int, Vector2]) -> String:
	var team: int = marker["team"]
	if not spawns.has(team):
		return ""
	var at: Vector2 = marker["at"]
	if at.distance_to(spawns[team]) > BASE_RADIUS:
		return ""
	return BASE_A if team == TEAM_A else BASE_B


## Agrupa os marcadores fora das bases por vizinhanca e classifica cada campo pelo lugar.
static func _add_fields(groups: Dictionary[String, Array], rest: Array[Dictionary]) -> void:
	for cluster: Array in _clusters(rest):
		var anchor := _centroid(cluster)
		var id := CENTER_FIELDS
		if anchor.length() > CENTER_RADIUS:
			id = CORNER_FIELDS if int(cluster[0]["team"]) == 0 else SIDE_FIELDS
		groups[id].append(_group(anchor, cluster))


## Componentes conexos: dois marcadores a FIELD_LINK ou menos estao no mesmo campo.
static func _clusters(markers: Array[Dictionary]) -> Array[Array]:
	var clusters: Array[Array] = []
	var seen: Dictionary[int, bool] = {}
	for i: int in markers.size():
		if seen.has(i):
			continue
		var cluster: Array = []
		var queue: Array[int] = [i]
		seen[i] = true
		while not queue.is_empty():
			var current: int = queue.pop_back()
			cluster.append(markers[current])
			for j: int in markers.size():
				if seen.has(j):
					continue
				var apart: float = (markers[current]["at"] as Vector2).distance_to(markers[j]["at"])
				if apart <= FIELD_LINK:
					seen[j] = true
					queue.append(j)
		clusters.append(cluster)
	return clusters


static func _centroid(markers: Array) -> Vector2:
	var sum := Vector2.ZERO
	for marker: Dictionary in markers:
		sum += marker["at"] as Vector2
	return sum / float(markers.size())


static func _group(anchor: Vector2, members: Array) -> Dictionary:
	var monsters: Dictionary = {}
	var chests: Dictionary = {}
	for marker: Dictionary in members:
		if marker["kind"] == KIND_MONSTER or marker["kind"] == KIND_BOSS:
			var monster_id: String = marker["monster_id"]
			monsters[monster_id] = int(monsters.get(monster_id, 0)) + 1
		elif marker["kind"] == KIND_CHEST:
			var chest: String = marker["chest_kind"]
			chests[chest] = int(chests.get(chest, 0)) + 1
	return {"anchor": anchor, "monsters": monsters, "chests": chests}


## Ordem de saida estavel: de cima para baixo, da esquerda para a direita.
static func _by_position(a: Dictionary, b: Dictionary) -> bool:
	var left: Vector2 = a["anchor"]
	var right: Vector2 = b["anchor"]
	if not is_equal_approx(left.y, right.y):
		return left.y < right.y
	return left.x < right.x
