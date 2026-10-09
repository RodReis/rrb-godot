class_name XpCurve
extends Resource
## Curva de XP (GDB §3.2) e catch-up (GDB §3.3). Nivel maximo = tamanho da curva.

## XP acumulado para atingir cada nivel; indice 0 = nivel 1.
@export var cumulative_xp: PackedInt32Array
## Catch-up vale quando nivel <= nivel do adversario - este valor.
@export var catch_up_level_gap: int
## Bonus de catch-up sobre XP de monstro/objetivo (0.25 = +25 %).
@export var catch_up_bonus: float
