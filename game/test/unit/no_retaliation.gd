class_name NoRetaliation
extends RefCounted
## Vitima passiva dos testes de dano: o revide (TargetRules.retaliate) faria o alvo bater de volta
## e somaria dano ao que o teste mede. Recarga do basico gigante = o auto-ataque nunca sai.

const COOLDOWN_TICKS: int = 1 << 20


static func mute(hero: Hero) -> Hero:
	hero.basic_cooldown = COOLDOWN_TICKS
	return hero
