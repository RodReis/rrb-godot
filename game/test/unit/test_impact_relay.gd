extends GutTest
## F41: o servidor anuncia cada golpe uma vez, mesmo com o atacante ressimulado (o _hit do mesmo
## tick roda de novo), e so para quem ve o alvo (neblina F37). Aqui o processo e o host (peer 1).

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const ROGUE: String = "res://scenes/heroes/rogue.tscn"
const TICK: int = 40
const DAMAGE: int = 10

var _players: Node3D
var _relay: ImpactRelay
var _attacker: Hero
var _target: Hero
## Impactos emitidos (Dictionary: lambda captura local por valor — APRENDIZADOS).
var _seen: Dictionary = {"count": 0, "last": []}
var _smokes: Dictionary = {"count": 0, "last": []}


func before_each() -> void:
	_seen = {"count": 0, "last": []}
	_smokes = {"count": 0, "last": []}
	_players = Node3D.new()
	add_child_autofree(_players)
	_relay = ImpactRelay.new()
	_relay.players = _players
	add_child_autofree(_relay)
	_relay.impacted.connect(_on_impacted)
	_relay.smoke_shown.connect(_on_smoke_shown)
	_attacker = _spawn("1", GateRules.TEAM_A, Vector3.ZERO)
	_target = _spawn("5", GateRules.TEAM_B, Vector3(0, 0, -1.5))


func _spawn(peer: String, team: int, at: Vector3, scene: String = KNIGHT) -> Hero:
	var hero := (load(scene) as PackedScene).instantiate() as Hero
	hero.name = peer
	hero.team = team
	hero.position = at
	_players.add_child(hero)
	return hero


func _on_smoke_shown(caster_id: int, center: Vector3, tick: int) -> void:
	_smokes["count"] += 1
	_smokes["last"] = [caster_id, center, tick]


func _on_impacted(attacker_id: int, slot: int, at: Vector3) -> void:
	_seen["count"] += 1
	_seen["last"] = [attacker_id, slot, at]


func _strike(tick: int) -> void:
	var effect := HitEffect.new(DAMAGE, _attacker.global_position)
	_attacker._hit(_target, tick, HitLedger.Slot.BASIC, effect)


## O VisionDirector do host decide quem o peer 1 ve; aqui, uma vez, pela mesma regra.
func _reveal_target() -> void:
	var concealment := _target.get_node(NodePath(Concealment.NODE_NAME)) as Concealment
	var observers: Array[Hero] = [_attacker]
	concealment.refresh(observers, PackedInt32Array())


func test_golpe_visto_vira_um_impacto_com_atacante_slot_e_posicao() -> void:
	_reveal_target()
	_strike(TICK)
	assert_eq(_seen["count"], 1)
	assert_eq(_seen["last"], [1, HitLedger.Slot.BASIC, _target.global_position])


func test_ressimular_o_atacante_nao_repete_o_impacto() -> void:
	_reveal_target()
	_strike(TICK)
	_strike(TICK)
	_strike(TICK)
	assert_eq(_seen["count"], 1, "mesmo tick, alvo e habilidade")
	_strike(TICK + 1)
	assert_eq(_seen["count"], 2, "tick seguinte e outro golpe")


func test_alvo_que_o_jogador_nao_ve_nao_gera_impacto() -> void:
	_strike(TICK)
	assert_eq(_seen["count"], 0, "neblina: quem nao ve o alvo nao ve o impacto")


# Fumaca da Ladina (F58): chega por evento, uma vez por lancamento, a quem ve o centro dela.


func test_nuvem_no_raio_de_visao_chega_uma_vez() -> void:
	var rogue := _spawn("6", GateRules.TEAM_B, Vector3(0, 0, -8), ROGUE) as Rogue
	rogue.smoked.emit(rogue.global_position, TICK)
	rogue.smoked.emit(rogue.global_position, TICK)
	assert_eq(_smokes["count"], 1, "ressimular nao repete")
	assert_eq(_smokes["last"], [6, Vector3(0, 0, -8), TICK])


func test_nuvem_fora_do_raio_de_visao_nao_chega() -> void:
	var rogue := _spawn("6", GateRules.TEAM_B, Vector3(0, 0, -30), ROGUE) as Rogue
	rogue.smoked.emit(rogue.global_position, TICK)
	assert_eq(_smokes["count"], 0)


func test_nuvem_do_proprio_time_chega_a_qualquer_distancia() -> void:
	var rogue := _spawn("6", GateRules.TEAM_A, Vector3(0, 0, -30), ROGUE) as Rogue
	rogue.smoked.emit(rogue.global_position, TICK)
	assert_eq(_smokes["count"], 1)
