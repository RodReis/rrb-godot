class_name ZoneController
extends Node
## Zona da fase 2 no servidor (ARCHITECTURE-GAME §3.3, GDB §7.1): uma vez por segundo desde os
## 5:00, registra o dano da zona (ZoneRules) no ledger de cada heroi vivo fora do circulo; o
## heroi aplica no proprio _rollback_tick (HitLedger, §3.2). Desconectado tem input sintetizado
## (F15) e morre pela zona como os outros. Centro = centro da arena. Raio e dano para a HUD saem
## de ZoneRules com o mesmo MatchClock, no cliente (F17).

const CENTER: Vector3 = Vector3.ZERO

@export var rules: MatchRules
@export var clock: MatchClock

## Servidor: ligada na fase 2 pelo MatchController (da TRANSITION ao ENDED).
var active: bool = false


func _ready() -> void:
	NetworkTime.on_tick.connect(_on_network_tick)


## Servidor: pulso de dano no primeiro tick de cada segundo de partida.
func update(tick: int, tickrate: int) -> void:
	if not active or not clock.is_started() or (tick - clock.start_tick) % tickrate != 0:
		return
	var t_phase2 := clock.phase2_elapsed(tick)
	if t_phase2 < 0.0:
		return
	var radius := ZoneRules.radius_at(rules, t_phase2)
	var pct := ZoneRules.damage_pct_at(rules, t_phase2)
	var source := HitLedger.source_key(0, HitLedger.Slot.ZONE)
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		var hero := node as Hero
		if hero.is_alive() and ZoneRules.is_outside(hero.global_position, CENTER, radius):
			var effect := HitEffect.new()
			effect.true_damage = ZoneRules.damage(hero.attributes.max_hp, pct)
			hero.receive_hit(tick + 1, source, effect)


func _on_network_tick(_delta: float, tick: int) -> void:
	update(tick, NetworkTime.tickrate)
