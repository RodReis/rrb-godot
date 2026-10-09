class_name XpCurve
extends Resource
## Curva de XP (GDB §3.2) e catch-up (GDB §3.3). Nivel maximo = tamanho da curva.

## XP acumulado para atingir cada nivel; indice 0 = nivel 1.
@export var cumulative_xp: PackedInt32Array
## Catch-up vale quando nivel <= nivel do adversario - este valor.
@export var catch_up_level_gap: int
## Bonus de catch-up sobre XP de monstro/objetivo (0.25 = +25 %).
@export var catch_up_bonus: float
## Ranks tipicos de Q, E e R em cada nivel (coluna "Nivel de Habilidade Tipico" do GDB §3.2);
## indice 0 = nivel 1. Usado pelo argumento de dev --level ate a alocacao de pontos (F9).
@export var typical_q_rank: PackedInt32Array
@export var typical_e_rank: PackedInt32Array
@export var typical_r_rank: PackedInt32Array
