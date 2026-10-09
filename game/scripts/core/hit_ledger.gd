class_name HitLedger
extends RefCounted
## Golpes recebidos por tick, guardados fora do estado de rollback.
## Ressimular o alvo reaplica os golpes (leitura nao consome); ressimular o
## atacante nao duplica (um efeito por fonte = atacante + habilidade, por tick).

## REWARD: XP dado pelo monstro ao matador (nao colide com o golpe do monstro no mesmo tick).
enum Slot { BASIC, Q, E, R, REWARD }

const SLOT_COUNT: int = 5

var _hits: Dictionary = {}  # tick (int) -> { source_key (int) -> HitEffect }


## Chave da fonte: o mesmo atacante pode acertar com habilidades diferentes no mesmo tick.
static func source_key(attacker_id: int, slot: Slot) -> int:
	return attacker_id * SLOT_COUNT + slot


func is_empty() -> bool:
	return _hits.is_empty()


func set_hit(tick: int, source: int, effect: HitEffect) -> void:
	if not _hits.has(tick):
		_hits[tick] = {}
	var by_source: Dictionary = _hits[tick]
	by_source[source] = effect


func has_hit(tick: int, source: int) -> bool:
	return _hits.has(tick) and (_hits[tick] as Dictionary).has(source)


func clear_hit(tick: int, source: int) -> void:
	if not _hits.has(tick):
		return
	var by_source: Dictionary = _hits[tick]
	by_source.erase(source)
	if by_source.is_empty():
		_hits.erase(tick)


func effects_at(tick: int) -> Array[HitEffect]:
	var result: Array[HitEffect] = []
	if _hits.has(tick):
		var by_source: Dictionary = _hits[tick]
		for effect: HitEffect in by_source.values():
			result.append(effect)
	return result


func trim_before(tick: int) -> void:
	for old_tick: int in _hits.keys():
		if old_tick < tick:
			_hits.erase(old_tick)
