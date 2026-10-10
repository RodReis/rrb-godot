class_name BotProfile
extends Resource
## Comportamento do bot da fase 1 (PRD §3.7; limiares aprovados pelo PI em 2026-10-09, F12).
## Distancias em u, tempos em s, HP em fracao do maximo.

## Abaixo disso, com perigo perto, o bot recua.
@export var retreat_hp_pct: float
## Heroi inimigo ou monstro vivo a ate esta distancia = perigo.
@export var danger_range: float
## Segundos seguidos sem perigo para sair do recuo.
@export var safe_seconds: float
## Heroi inimigo a ate esta distancia pode virar briga (se o bot tiver vantagem).
@export var fight_range: float
## Contesta o boss so com HP a partir disto; abaixo farma e saqueia (PI 2026-10-10, #74).
@export var contest_hp_pct: float
