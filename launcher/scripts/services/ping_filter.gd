class_name PingFilter
extends RefCounted
## Ping mostrado ao jogador (#233): o menor das ultimas WINDOW amostras. A 1a requisicao depois de
## reconectar costuma ser mais lenta e nao pode ficar na tela; uma subida real aparece em WINDOW
## medidas. Falha esquece o historico (reset).

const WINDOW: int = 3

var _samples: Array[int] = []


## Entra a amostra (ms) e devolve o ping a mostrar.
func add(ms: int) -> int:
	_samples.append(ms)
	if _samples.size() > WINDOW:
		_samples.pop_front()
	return _samples.min()


func reset() -> void:
	_samples.clear()
