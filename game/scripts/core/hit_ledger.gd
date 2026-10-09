class_name HitLedger
extends RefCounted
## Golpes recebidos por tick, guardados fora do estado de rollback.
## Ressimular o alvo reaplica os golpes (leitura nao consome); ressimular o
## atacante nao duplica (um golpe por atacante por tick).

var _hits: Dictionary = {}  # tick (int) -> { attacker_id (int) -> damage (int) }

func is_empty() -> bool:
	return _hits.is_empty()

func set_hit(tick: int, attacker_id: int, damage: int) -> void:
	if not _hits.has(tick):
		_hits[tick] = {}
	var by_attacker: Dictionary = _hits[tick]
	by_attacker[attacker_id] = damage

func clear_hit(tick: int, attacker_id: int) -> void:
	if not _hits.has(tick):
		return
	var by_attacker: Dictionary = _hits[tick]
	by_attacker.erase(attacker_id)
	if by_attacker.is_empty():
		_hits.erase(tick)

func damages_at(tick: int) -> Array[int]:
	var result: Array[int] = []
	if _hits.has(tick):
		var by_attacker: Dictionary = _hits[tick]
		for damage: int in by_attacker.values():
			result.append(damage)
	return result

func trim_before(tick: int) -> void:
	for old_tick: int in _hits.keys():
		if old_tick < tick:
			_hits.erase(old_tick)
