class_name FountainRules
extends RefCounted
## Fonte da base (PI 2026-10-10, #74): cura uma vez por segundo, so na fase 1, so o time dono, so
## vivo e sem dano recente.


## Cura de um pulso (1 por segundo): fracao do HP max, ao menos 1.
static func heal_amount(max_hp: int, heal_pct: float) -> int:
	return maxi(roundi(max_hp * heal_pct), 1)


static func can_heal(open: bool, alive: bool, pause_ticks: int, in_area: bool) -> bool:
	return open and alive and pause_ticks == 0 and in_area
