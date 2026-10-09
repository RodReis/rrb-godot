class_name InputRules
extends RefCounted
## Validacao do input recebido do cliente antes de entrar na simulacao do servidor.

## Direcoes de input (movimento, mira) nunca passam disto.
const MAX_DIRECTION_LENGTH: float = 1.0


## Direcao horizontal com comprimento <= MAX_DIRECTION_LENGTH; valor nao finito vira ZERO.
static func sanitize_direction(v: Vector3) -> Vector3:
	if not v.is_finite():
		return Vector3.ZERO
	return Vector3(v.x, 0.0, v.z).limit_length(MAX_DIRECTION_LENGTH)
