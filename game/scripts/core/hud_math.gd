class_name HudMath
extends RefCounted
## Contas de exibicao das HUDs (DV telas 3 e 4) sobre estado ja replicado: nada aqui decide
## regra de jogo, so traduz numero para o que a tela mostra.

## Ultimos segundos de um contador que piscam em aviso (PATTERNS P7).
const WARNING_SECONDS: float = 30.0
## Vinheta de dano (PI 2026-10-22, "suave"): pico do flash; abaixo de LOW_HP_RATIO do HP fica um
## piso continuo de LOW_HP_FLOOR (no limiar) ate LOW_HP_PEAK (quase morto).
const DAMAGE_FLASH_PEAK: float = 0.55
const LOW_HP_RATIO: float = 0.25
const LOW_HP_FLOOR: float = 0.15
const LOW_HP_PEAK: float = 0.45
## Piso do tempo de apagar do flash (evita dividir por zero).
const MIN_FADE_SECONDS: float = 0.001


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


## Vinheta da zona (PATTERNS P8): dano/s atual sobre o maior dano da tabela (0-1), so com o flag
## do servidor ([param zone_ticks] > 0, Hero.zone_ticks); some nos ultimos [param fade_ticks].
static func zone_vignette(
	rules: MatchRules, damage_pct: float, zone_ticks: int, fade_ticks: int
) -> float:
	var peak := 0.0
	for pct: float in rules.zone_damage_pct:
		peak = maxf(peak, pct)
	if zone_ticks <= 0 or peak <= 0.0:
		return 0.0
	var fade := clampf(float(zone_ticks) / maxi(fade_ticks, 1), 0.0, 1.0)
	return clampf(damage_pct / peak, 0.0, 1.0) * fade


## Alerta de dano nas laterais (PI 2026-10-22): [param prev] (0-1) acende em 1 quando o HP caiu
## neste quadro e apaga linear em [param fade_seconds].
static func damage_flash(prev: float, hp_dropped: bool, delta: float, fade_seconds: float) -> float:
	if hp_dropped:
		return 1.0
	return maxf(prev - delta / maxf(fade_seconds, MIN_FADE_SECONDS), 0.0)


## Intensidade da vinheta de dano: o flash ate DAMAGE_FLASH_PEAK (suave) e, com HP abaixo de
## LOW_HP_RATIO, um piso que cresce ate LOW_HP_PEAK quanto menor o HP. Morto: nada.
static func damage_vignette(flash: float, hp_ratio: float, alive: bool) -> float:
	if not alive:
		return 0.0
	var low := 0.0
	if hp_ratio < LOW_HP_RATIO:
		low = lerpf(LOW_HP_FLOOR, LOW_HP_PEAK, 1.0 - clampf(hp_ratio / LOW_HP_RATIO, 0.0, 1.0))
	return maxf(flash * DAMAGE_FLASH_PEAK, low)


## Raio da zona como fracao do primeiro raio (a arena inteira = 1).
static func zone_fraction(rules: MatchRules, radius: float) -> float:
	return radius / rules.zone_radius[0]


## Como [method decimal], sem a casa quando inteiro: 6 -> "6", 3,5 -> "3,5" (paineis enxutos).
static func short(value: float) -> String:
	var text := decimal(value)
	return text.trim_suffix(",0")


## Uma casa decimal com virgula (pt-BR).
static func decimal(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")
