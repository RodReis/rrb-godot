class_name BotView
extends RefCounted
## O que o bot sabe neste tick, montado so com estado replicado (invariante de honestidade,
## CONVENTION §4.6). Entrada pura de BotRules.

var hp_pct: float = 1.0
var level: int = 1
## Ja recuou com este HP baixo; so volta a recuar depois de passar de retreat_hp_pct.
var retreat_spent: bool = false
## Heroi inimigo ou monstro vivo a ate danger_range.
var in_danger: bool = false
## Segundos seguidos sem perigo.
var safe_seconds: float = 0.0
## INF quando nao ha heroi inimigo.
var enemy_distance: float = INF
var enemy_level: int = 0
var enemy_hp_pct: float = 1.0
## Segundos de partida (MatchClock) e o tempo a partir do qual contesta o centro.
var elapsed: float = 0.0
var contest_time: float = 0.0
var base_monsters_left: int = 0
var base_chests_left: int = 0
