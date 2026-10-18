class_name BerserkerRules
extends RefCounted
## Regras puras do Berserker (GDB §4.8, F75): fator do Frenesi (§2.2-E), intervalo do basico com ele
## e a cura do roubo de vida.


## f do Frenesi: 0 com HP cheio, cresce linear com o HP perdido e chega a 1 em [param full_at] do
## HP maximo (teto).
static func frenzy(hp: int, max_hp: int, full_at: float) -> float:
	if max_hp <= 0 or full_at >= 1.0:
		return 0.0
	var lost := 1.0 - float(hp) / max_hp
	return clampf(lost / (1.0 - full_at), 0.0, 1.0)


## Intervalo do basico (s) com o Frenesi: [param interval] ja passou pela formula D (AGI); o bonus
## [param bonus] x [param f] entra depois, como velocidade de ataque.
static func attack_interval(interval: float, f: float, bonus: float) -> float:
	return interval / (1.0 + bonus * f)


## Cura do roubo de vida: [param lifesteal] x [param f] do [param dealt] (dano do basico ja depois
## da DEF do alvo).
static func lifesteal_heal(dealt: int, f: float, lifesteal: float) -> int:
	return roundi(maxi(dealt, 0) * lifesteal * f)
