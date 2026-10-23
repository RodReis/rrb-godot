class_name TeleportRules
extends Resource
## Detecao de teleporte no cliente (F29, SPEC-029 §3.2): salto visual de heroi por correcao de
## rede. Valores provisorios, calibrados nos cenarios A, B e C do net-measure (ADR-0001).

## Deslocamento (u) por quadro, alem do que a velocidade explica, acima do qual conta 1 teleporte.
@export var teleport_threshold_u: float
## Intervalo minimo (s) entre dois teleportes do mesmo heroi: o mesmo salto nao conta duas vezes.
@export var teleport_cooldown_s: float
