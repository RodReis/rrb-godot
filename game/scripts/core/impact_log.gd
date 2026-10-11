class_name ImpactLog
extends RefCounted
## Servidor: impactos ja anunciados aos clientes (VFX, F41; bloco visual regra 2). Ressimular o
## atacante chama Hero._hit de novo para o mesmo tick: so o primeiro anuncio passa. Fica fora do
## estado de rollback, como o HitLedger.

var _seen: Dictionary = {}  # tick (int) -> { Vector3i(atacante, slot, alvo) -> true }


## Primeira vez que o golpe de [param attacker_id] com [param slot] em [param target_id] no
## [param tick] e anunciado.
func first(tick: int, attacker_id: int, slot: int, target_id: int) -> bool:
	if not _seen.has(tick):
		_seen[tick] = {}
	var by_key: Dictionary = _seen[tick]
	var key := Vector3i(attacker_id, slot, target_id)
	if by_key.has(key):
		return false
	by_key[key] = true
	return true


func trim_before(tick: int) -> void:
	for old_tick: int in _seen.keys():
		if old_tick < tick:
			_seen.erase(old_tick)
