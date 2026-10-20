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
## A fonte do proprio time cura agora (fase 1, #74).
var can_heal: bool = false
## Fase 2 (a partir dos 5:00): zona ligada, sem fonte e sem respawn de monstro.
var phase2: bool = false
## Distancia do heroi ate a borda da zona (u); negativa = fora. INF sem zona.
var zone_edge: float = INF
## O adversario esta vivo (a morte e aviso global e o respawn tem tempo publico).
var enemy_alive: bool = false
## O adversario esta dentro da zona; sem ve-lo, supoe que sim (a zona o empurra ao centro).
var enemy_in_zone: bool = true
## Folga de nivel do nivel do bot ao medir vantagem (F81); 0 = o bot de antes.
var level_slack: int = 0
## O nivel do bot persegue na fase 2 (F81); o Facil nao.
var can_chase: bool = true
