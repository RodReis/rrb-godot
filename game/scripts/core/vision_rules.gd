class_name VisionRules
extends RefCounted
## Neblina de guerra (F37, CONVENTION §4.9, GDB §7.3): cada heroi ve num raio (vision_radius, so
## o plano) — fora dele, heroi adversario e monstros nao sao replicados ao peer, e o bau mostra
## o ultimo estado visto. Dentro do raio o mato alto continua valendo (VisibilityRules). Explorado:
## mascara de celulas que o cliente marca so com a posicao do proprio heroi (nao vaza nada). Regra
## pura; o servidor filtra (VisionDirector, Concealment), o bot pergunta aqui, a neblina desenha.

## Celula da mascara de explorado ainda nao vista / ja vista (valor do byte, canal R da textura).
const UNSEEN: int = 0
const SEEN: int = 255


## [param target] esta no raio de quem esta em [param observer]; a altura nao conta.
static func in_sight(observer: Vector3, target: Vector3, radius: float) -> bool:
	var dx := target.x - observer.x
	var dz := target.z - observer.z
	return dx * dx + dz * dz <= radius * radius


## Heroi adversario aparece: no raio e nao escondido no mato ([param grass_hidden], F32).
static func hero_shown(in_radius: bool, grass_hidden: bool) -> bool:
	return in_radius and not grass_hidden


## Lado (celulas) da mascara quadrada que cobre [-extent, extent] em x e z.
static func mask_side(extent: float, cell: float) -> int:
	return ceili(2.0 * extent / cell)


## Mascara toda UNSEEN; linha = z, coluna = x, a partir de (-extent, -extent).
static func new_mask(extent: float, cell: float) -> PackedByteArray:
	var side := mask_side(extent, cell)
	var mask := PackedByteArray()
	mask.resize(side * side)
	mask.fill(UNSEEN)
	return mask


## Celula (coluna x, linha z) do ponto; pode cair fora da mascara.
static func cell_of(point: Vector3, extent: float, cell: float) -> Vector2i:
	return Vector2i(floori((point.x + extent) / cell), floori((point.z + extent) / cell))


## Copia de [param mask] com SEEN em toda celula cujo centro esta no raio de [param center].
static func explore(
	mask: PackedByteArray, extent: float, cell: float, center: Vector3, radius: float
) -> PackedByteArray:
	var side := mask_side(extent, cell)
	var low := cell_of(center - Vector3(radius, 0.0, radius), extent, cell).clampi(0, side - 1)
	var high := cell_of(center + Vector3(radius, 0.0, radius), extent, cell).clampi(0, side - 1)
	var seen := mask.duplicate()
	for z: int in range(low.y, high.y + 1):
		for x: int in range(low.x, high.x + 1):
			var at := Vector3(-extent + (x + 0.5) * cell, 0.0, -extent + (z + 0.5) * cell)
			if in_sight(center, at, radius):
				seen[z * side + x] = SEEN
	return seen
