class_name ZoneController
extends Node
## Zona da fase 2 no servidor (ARCHITECTURE-GAME §3.3, GDB §7.1): uma vez por segundo desde os
## 5:00, registra o dano da zona (ZoneRules) no ledger de cada heroi vivo fora do circulo; o
## heroi aplica no proprio _rollback_tick (HitLedger, §3.2). Desconectado tem input sintetizado
## (F15) e morre pela zona como os outros. Centro = centro da arena. Em todo peer (cliente
## tambem), no mesmo segundo, avisa zone_updated com raio, proximo fechamento e dano, tirados de
## ZoneRules pelo MatchClock replicado: a HUD so consome o sinal (F17).

## Raio e raio do proximo fechamento (u), dano fora (fracao do HP max/s) e segundos ate o
## proximo fechamento (0 = nenhum).
signal zone_updated(radius: float, next_radius: float, damage_pct: float, t_next: float, tick: int)

const CENTER: Vector3 = Vector3.ZERO

@export var rules: MatchRules
@export var clock: MatchClock

## Servidor: ligada na fase 2 pelo MatchController (da TRANSITION ao ENDED).
var active: bool = false


func _ready() -> void:
	NetworkTime.on_tick.connect(_on_network_tick)


## No primeiro tick de cada segundo de partida: aviso a HUD e, no servidor, o pulso de dano.
func update(tick: int, tickrate: int) -> void:
	if not clock.is_started() or (tick - clock.start_tick) % tickrate != 0:
		return
	var t_phase2 := clock.phase2_elapsed(tick)
	if t_phase2 < 0.0:
		return
	var radius := ZoneRules.radius_at(rules, t_phase2)
	var pct := ZoneRules.damage_pct_at(rules, t_phase2)
	var next := ZoneRules.next_radius(rules, t_phase2)
	zone_updated.emit(radius, next, pct, ZoneRules.until_next(rules, t_phase2), tick)
	if not active:
		return
	var source := HitLedger.source_key(0, HitLedger.Slot.ZONE)
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		var hero := node as Hero
		if hero.is_alive() and ZoneRules.is_outside(hero.global_position, CENTER, radius):
			var effect := HitEffect.new()
			effect.true_damage = ZoneRules.damage(hero.attributes.max_hp, pct)
			hero.receive_hit(tick + 1, source, effect)


func _on_network_tick(_delta: float, tick: int) -> void:
	update(tick, NetworkTime.tickrate)
