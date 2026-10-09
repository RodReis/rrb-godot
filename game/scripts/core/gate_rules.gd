class_name GateRules
extends RefCounted
## Portao de base (PRD §3.1, SPEC-007 §4): na fase 1 so o time dono passa; depois de
## gates_fallen todos passam. Camadas de fisica em PhysicsLayers.

const TEAM_NEUTRAL: int = 0
const TEAM_A: int = 1
const TEAM_B: int = 2

const LAYER_WORLD: int = PhysicsLayers.WORLD
const LAYER_RIVER: int = PhysicsLayers.RIVER
const LAYER_GATE_A: int = PhysicsLayers.GATE_A
const LAYER_GATE_B: int = PhysicsLayers.GATE_B


static func can_pass(hero_team: int, gate_team: int, gates_fallen: bool) -> bool:
	return gates_fallen or hero_team == gate_team


static func gate_layer(gate_team: int) -> int:
	return LAYER_GATE_A if gate_team == TEAM_A else LAYER_GATE_B


## Mascara de colisao do heroi: mundo, rio e os portoes que o barram na fase 1.
## Portao caido desliga a propria colisao; a mascara nao muda.
static func hero_mask(hero_team: int) -> int:
	var mask := LAYER_WORLD | LAYER_RIVER
	for gate_team: int in [TEAM_A, TEAM_B]:
		if not can_pass(hero_team, gate_team, false):
			mask |= gate_layer(gate_team)
	return mask
