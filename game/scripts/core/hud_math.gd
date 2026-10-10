class_name HudMath
extends RefCounted
## Contas de exibicao da HUD da fase 1 (DV tela 3) sobre estado ja replicado: nada aqui decide
## regra de jogo, so traduz numero para o que a tela mostra.

## Ultimos segundos de um contador que piscam em aviso (PATTERNS P7).
const WARNING_SECONDS: float = 30.0


## XP dentro do nivel atual: x = ganho no nivel, y = necessario para o proximo; nivel maximo
## volta (1, 1), barra cheia.
static func xp_progress(curve: XpCurve, xp: int) -> Vector2i:
	var level := XpTable.level_for_xp(curve, xp)
	if level >= XpTable.max_level(curve):
		return Vector2i.ONE
	var floor_xp := XpTable.xp_for_level(curve, level)
	return Vector2i(xp - floor_xp, XpTable.xp_for_level(curve, level + 1) - floor_xp)


## Segundos ate [param event_time] (>= 0) no relogio da partida.
static func until(event_time: float, elapsed: float) -> float:
	return maxf(event_time - elapsed, 0.0)


static func is_warning(remaining: float) -> bool:
	return remaining > 0.0 and remaining <= WARNING_SECONDS


## Bonus de catch-up que o heroi recebe agora (0 = nenhum), em fracao.
static func catch_up_bonus(curve: XpCurve, level: int, opponent_level: int) -> float:
	return XpTable.catch_up_multiplier(curve, level, opponent_level) - 1.0
