class_name TeleportCollector
extends RefCounted
## Servidor: recebe o total de teleportes que cada cliente conta e manda no fim da partida (F29,
## SPEC-029 §3.1). Dado do cliente, nao confiavel: um envio por peer, de 0 a MAX_TELEPORTS. Quem
## decide de quem falta o total e o MatchController, pelo is_pending.

## Maior total aceito de um cliente.
const MAX_TELEPORTS: int = 10000
const WAIT_STEP: float = 0.1

## Callable() -> bool: ainda falta o total de algum cliente conectado.
var is_pending: Callable

var _reported: Dictionary[int, bool] = {}


## Aceita o total de [param peer] se o valor esta na faixa e e o primeiro dele. Recusa nao gasta o
## unico envio.
func accept(peer: int, count: int) -> bool:
	if _reported.has(peer) or count < 0 or count > MAX_TELEPORTS:
		return false
	_reported[peer] = true
	return true


## [param peer] saiu: nao ha total a esperar dele, e um envio tardio e recusado.
func skip(peer: int) -> void:
	_reported[peer] = true


func has_reported(peer: int) -> bool:
	return _reported.has(peer)


## Depois do match_ended: espera os totais, no maximo [param timeout] segundos. Quem nao mandou
## fica sem valor no resultado.
func wait(tree: SceneTree, timeout: float) -> void:
	var waited := 0.0
	while waited < timeout and is_pending.call():
		await tree.create_timer(WAIT_STEP).timeout
		waited += WAIT_STEP
