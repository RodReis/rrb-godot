extends "arena_vegetation.gd"
## Margem do rio e borda da cratera (F95, ADR-0030): pedras soltas e juncos ao longo da agua
## visual (anel, bracos e lagoas) e o anel de basalto do lago de magma. So visual, sem colisao nem
## navmesh. Posicoes por hash da posicao (sem RNG): a cena sai igual a cada rodada. Nada nasce na
## ponte, nas bases, sob as rochas dos bolsoes nem dentro da folga do mato alto (a regra de jogo
## F32 mantem o vazio em volta da moita).

const BANK_STONES: String = KIT + "kit_bank_stones.glb"
const REEDS: String = KIT + "kit_reeds.glb"
const CRATER_RIMS: Array[String] = [KIT + "kit_crater_rim_a.glb", KIT + "kit_crater_rim_b.glb"]
## Um candidato por celula da grade (u), com jitter.
const BANK_GRID: float = 0.8
## Faixa (u) da distancia ate a borda da agua visual: pedras na margem, juncos na beira e no raso
## (negativo = dentro da agua).
const STONE_BAND: Vector2 = Vector2(0.05, 1.0)
const REED_BAND: Vector2 = Vector2(-0.45, 0.35)
const STONE_CHANCE: float = 0.16
const REED_CHANCE: float = 0.2
const STONE_SCALE: Vector2 = Vector2(0.7, 1.5)
const REED_SCALE: Vector2 = Vector2(0.8, 1.3)
## Perfil da margem (art/arena/build_island.py): terreno plano ate BANK_WIDTH da agua, leito a
## GROOVE_DEPTH.
const BANK_WIDTH: float = 0.8
const GROOVE_DEPTH: float = -1.0
## Folga em volta da ponte (u, alem da meia largura) e da borda da arena.
const BRIDGE_CLEAR: float = 1.2
const EDGE_CLEAR: float = 2.0


func _build_river_dressing() -> void:
	var group := _group("RiverBank")
	var boxes := _tall_grass_boxes()
	var walls := _polylines("walls")
	var cells := ceili(ARENA_HALF * 2 / BANK_GRID)
	var count := 0
	for row: int in range(cells):
		for col: int in range(cells):
			var cell := Vector2(col, row) * BANK_GRID - Vector2.ONE * ARENA_HALF
			var jitter := Vector2(_hash(cell + Vector2(1.3, 4.1)), _hash(cell + Vector2(6.7, 2.9)))
			var p := cell + jitter * BANK_GRID
			var d := _water_distance(p)
			if d > STONE_BAND.y or d < REED_BAND.x:
				continue
			if maxf(absf(p.x), absf(p.y)) > ARENA_HALF - EDGE_CLEAR or _in_base(p):
				continue
			if _on_bridge(p) or _under_rocks(p, walls) or _near_tall_grass(p, boxes):
				continue
			var roll := _hash(p + Vector2(9.1, 3.3))
			var model := ""
			var scale_range := STONE_SCALE
			if d >= STONE_BAND.x and roll < STONE_CHANCE:
				model = BANK_STONES
			elif d <= REED_BAND.y and roll > 1.0 - REED_CHANCE:
				model = REEDS
				scale_range = REED_SCALE
			if model.is_empty():
				continue
			var s := lerpf(scale_range.x, scale_range.y, _hash(p + Vector2(2.2, 8.8)))
			var piece := _asset(group, model, "Bank%d" % count)
			var basis := Basis(Vector3.UP, TAU * _hash(p + Vector2(5.5, 1.1))).scaled(Vector3.ONE * s)
			piece.transform = Transform3D(basis, Vector3(p.x, _bank_height(d), p.y))
			count += 1
	print("[arena] margem do rio: %d pedras e juncos" % count)


## Anel de basalto em volta do lago de magma (as duas metades do kit ja vem na posicao do mundo).
func _build_crater_rim() -> void:
	var group := _group("CraterRim")
	for i: int in range(CRATER_RIMS.size()):
		_asset(group, CRATER_RIMS[i], "Rim%d" % i)


## Distancia (u) do ponto ate a borda da agua visual; negativa dentro dela. Mesma conta do chassi
## (art/arena/build_island.py, groove_distance): anel, bracos (so fora do anel) e lagoas.
func _water_distance(p: Vector2) -> float:
	var d := absf(p.length() - RING_MID) - WATER_HALF_VISUAL
	for flip: float in [1.0, -1.0]:
		var q := p * flip
		if p.length() > RING_IN and _in_arm_fan(q):
			d = minf(d, absf(q.distance_to(ARM_CENTER_A) - ARM_RADIUS) - WATER_HALF_VISUAL)
		d = minf(d, q.distance_to(LAGOON_A) - LAGOON_WATER_VISUAL)
	return d


## Altura do chao a [param d] da agua: plano na margem, rampa ate o leito (build_island.py).
static func _bank_height(d: float) -> float:
	if d <= 0.0:
		return GROOVE_DEPTH
	return GROOVE_DEPTH * (1.0 - d / BANK_WIDTH) if d < BANK_WIDTH else 0.0


func _on_bridge(p: Vector2) -> bool:
	for azimuth: float in BRIDGE_AZIMUTHS:
		var axis := _flat(_polar(azimuth, 1.0))
		var s := p.dot(axis)
		var l := absf(p.dot(Vector2(-axis.y, axis.x)))
		if s > RING_IN - BRIDGE_CLEAR and s < RING_OUT + BRIDGE_CLEAR and l <= BRIDGE_HALF + BRIDGE_CLEAR:
			return true
	return false
