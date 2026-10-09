class_name PhysicsLayers
extends RefCounted
## Camadas de fisica do projeto (bits de collision_layer/mask), iguais a
## layer_names/3d_physics do project.godot.

## Bloqueia tudo (chao, muros, rochas, pilares, borda, herois).
const WORLD: int = 1 << 0
## Bloqueia andar, nao projetil.
const RIVER: int = 1 << 1
const GATE_A: int = 1 << 2
const GATE_B: int = 1 << 3
## Volume da Muralha (E do Cavaleiro) enquanto ativa: projetil que cruza e bloqueado (F14).
const SHIELD: int = 1 << 4
