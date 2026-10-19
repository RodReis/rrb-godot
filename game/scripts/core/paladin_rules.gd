class_name PaladinRules
extends RefCounted
## Regras puras do Paladino Radiante (GDB §4.9, F76): o 1o alvo da faixa do Golpe Consagrado e a
## Retribuicao (quando devolve e quanto).

const NOT_FOUND: int = -1
## A largura da faixa se divide igual dos dois lados da frente.
const HALF: float = 0.5


## Indice do candidato mais perto de [param origin] dentro da faixa a frente ([param forward],
## no plano): ate [param length] adiante e ate metade de [param width] de lado. Centros dos corpos,
## como o arco do basico. NOT_FOUND se ninguem esta na faixa.
static func first_in_strip(
	origin: Vector3, forward: Vector3, points: PackedVector3Array, length: float, width: float
) -> int:
	var ahead := Vector3(forward.x, 0.0, forward.z).normalized()
	var side := Vector3(-ahead.z, 0.0, ahead.x)
	var best := NOT_FOUND
	var best_along := INF
	for i: int in points.size():
		var flat := points[i] - origin
		flat.y = 0.0
		var along := flat.dot(ahead)
		if along < 0.0 or along > length or absf(flat.dot(side)) > width * HALF:
			continue
		if along < best_along:
			best = i
			best_along = along
	return best


## Golpe Consagrado: o chefe so toma o dano; heroi, servo e monstro comum ficam atordoados.
static func stuns(is_boss: bool) -> bool:
	return not is_boss


## A Retribuicao devolve o golpe: ela esta ativa, o golpe e direto (corpo a corpo: nao projetil,
## zona nem pulso) e a origem esta a ate [param reach].
static func reflects(active: bool, direct: bool, distance: float, reach: float) -> bool:
	return active and direct and distance <= reach


## Dano bruto devolvido (a DEF do atacante mitiga depois): [param ratio] do dano que o Paladino
## tomou depois da DEF dele + [param attack_ratio] do ATK.
static func reflected_damage(taken: int, ratio: float, attack: float, attack_ratio: float) -> int:
	return maxi(roundi(maxi(taken, 0) * ratio + attack * attack_ratio), 0)
