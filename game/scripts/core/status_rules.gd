class_name StatusRules
extends RefCounted
## Qual status de controle a animacao sobre a cabeca mostra (PI 2026-10-22): um so por vez, o que
## mais tira do jogador. Preso = lentidao de 100 % (Penitencia do Carrasco). Regra pura sobre o
## estado replicado; a Maldicao e a Praga tem marcas proprias (CurseIndicator).

enum Status { NONE, STUN, ROOT, SLOW }


static func shown(stun_ticks: int, slow_ticks: int, slow_pct: float) -> Status:
	if stun_ticks > 0:
		return Status.STUN
	if slow_ticks > 0 and slow_pct >= 1.0:
		return Status.ROOT
	if slow_ticks > 0 and slow_pct > 0.0:
		return Status.SLOW
	return Status.NONE
