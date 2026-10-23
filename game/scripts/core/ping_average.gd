class_name PingAverage
extends RefCounted
## Media de RTT por peer ao longo da partida (F29, SPEC-029 §3.1). O servidor amostra a cada 1 s;
## aqui so se acumula. Sem amostra valida, NONE (vira nulo no resultado).

const NONE: int = -1

var _sum: Dictionary[int, int] = {}
var _count: Dictionary[int, int] = {}


## RTT negativo (sem conexao) e ignorado.
func add(peer: int, rtt_ms: int) -> void:
	if rtt_ms < 0:
		return
	_sum[peer] = _sum.get(peer, 0) + rtt_ms
	_count[peer] = _count.get(peer, 0) + 1


## Media arredondada ao inteiro mais proximo, ou NONE.
func average(peer: int) -> int:
	var samples: int = _count.get(peer, 0)
	if samples == 0:
		return NONE
	return roundi(float(_sum[peer]) / samples)
