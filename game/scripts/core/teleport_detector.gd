class_name TeleportDetector
extends RefCounted
## Conta teleportes de heroi por correcao de rede (F29, SPEC-029 §3.2): em cada quadro renderizado
## compara a posicao com a do quadro anterior e descarta o que a velocidade e o tempo do quadro
## explicam. Regra pura; quem alimenta as posicoes e o TeleportMonitor.

var _rules: TeleportRules
## Relogio proprio, somado dos delta dos quadros: o cooldown nao depende de Time.
var _clock: float = 0.0
var _last_position: Dictionary[int, Vector3] = {}
var _last_event: Dictionary[int, float] = {}
var _counts: Dictionary[int, int] = {}


func _init(rules: TeleportRules) -> void:
	_rules = rules


## Um quadro de [param key]. [param expected_speed] (u/s) e a velocidade que explica o
## deslocamento; [param exempt] = avanco, empurrao, respawn ou heroi escondido: so atualiza a
## posicao. Devolve true se contou um teleporte neste quadro.
func observe(
	key: int, position: Vector3, delta: float, expected_speed: float, exempt: bool
) -> bool:
	_clock += delta
	var before: Variant = _last_position.get(key)
	_last_position[key] = position
	if exempt or before == null:
		return false
	var excess := position.distance_to(before as Vector3) - expected_speed * delta
	if excess <= _rules.teleport_threshold_u:
		return false
	if _clock - _last_event.get(key, -INF) < _rules.teleport_cooldown_s:
		return false
	_last_event[key] = _clock
	_counts[key] = count(key) + 1
	return true


func count(key: int) -> int:
	return _counts.get(key, 0)


## Soma de todos os herois vistos.
func total() -> int:
	var sum := 0
	for value: int in _counts.values():
		sum += value
	return sum


## O heroi saiu de cena: o proximo quadro dele so marca a posicao.
func forget(key: int) -> void:
	_last_position.erase(key)
