extends GutTest
## Integracao headless da neblina de guerra no servidor (F37, CONVENTION §4.9): arena +
## SpawnDirector + dois Cavaleiros. O estado de heroi adversario, monstro e bau so vai a quem os
## tem no raio de 12 u; o dono sempre recebe o proprio; o VisionDirector percorre todos os alvos.

const ARENA: String = "res://scenes/arena/arena.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
## Peers dos herois (nome do node = peer_id). LOCAL = o jogador deste processo (host).
const LOCAL: int = 1
const REMOTE: int = 8
## Longe de tudo na arena, sem moita perto (a moita mais proxima fica a > 12 u).
const FAR_SPOT: Vector3 = Vector3(0.0, 0.0, -30.0)

var _director: SpawnDirector
var _me: Hero
var _other: Hero


func before_each() -> void:
	add_child_autofree((load(ARENA) as PackedScene).instantiate())
	_director = SpawnDirector.new()
	_director.loot_seed = 37
	add_child_autofree(_director)
	_me = _spawn(LOCAL, GateRules.TEAM_A)
	_other = _spawn(REMOTE, GateRules.TEAM_B)


func _spawn(id: int, team: int) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(id)
	hero.team = team
	add_child_autofree(hero)
	return hero


func _concealment(node: Node) -> Concealment:
	return node.get_node(NodePath(Concealment.NODE_NAME)) as Concealment


func _observers() -> Array[Hero]:
	return [_me, _other]


func _remote() -> PackedInt32Array:
	return PackedInt32Array([REMOTE])


## Monstro comum (sem o Rei Esqueleto) e um bau do SpawnDirector.
func _monster() -> Monster:
	for node: Node in _director.get_children():
		var monster := node as Monster
		if monster != null and monster.data.tier != MonsterData.Tier.BOSS:
			return monster
	return null


func _chest() -> Chest:
	for node: Node in _director.get_children():
		if node is Chest:
			return node as Chest
	return null


## Ponto a [param distance] u de [param from] no plano.
func _beside(from: Vector3, distance: float) -> Vector3:
	return Vector3(from.x + distance, 0.0, from.z)


func test_adversario_longe_nao_ve_o_heroi() -> void:
	_me.global_position = FAR_SPOT
	_other.global_position = _beside(FAR_SPOT, 12.5)
	assert_false(_me.seen_by(_other))
	assert_false(_other.seen_by(_me))


func test_adversario_no_raio_ve_o_heroi() -> void:
	_me.global_position = FAR_SPOT
	_other.global_position = _beside(FAR_SPOT, 11.5)
	assert_true(_me.seen_by(_other))


func test_proprio_e_aliado_sempre_veem() -> void:
	var ally := _spawn(9, GateRules.TEAM_A)
	_me.global_position = FAR_SPOT
	ally.global_position = _beside(FAR_SPOT, 40.0)
	assert_true(_me.seen_by(_me))
	assert_true(_me.seen_by(ally))
	assert_false(_me.seen_by(null), "sem heroi (selecao) nao ve nada")


func test_dono_recebe_o_proprio_estado_desde_o_spawn() -> void:
	var ack := _other.get_node(NodePath(SpawnAck.NODE_NAME)) as SpawnAck
	ack.confirm(REMOTE)
	var filter := (_other.get_node("RollbackSynchronizer") as RollbackSynchronizer).visibility_filter
	assert_true(filter.get_visibility_for(REMOTE))


func test_heroi_fora_da_visao_nao_vai_ao_adversario_e_volta_ao_entrar() -> void:
	var ack := _me.get_node(NodePath(SpawnAck.NODE_NAME)) as SpawnAck
	ack.confirm(REMOTE)
	var filter := (_me.get_node("RollbackSynchronizer") as RollbackSynchronizer).visibility_filter
	_me.global_position = FAR_SPOT
	_other.global_position = _beside(FAR_SPOT, 20.0)
	assert_eq(_concealment(_me).refresh(_observers(), _remote()), PackedInt32Array())
	assert_false(filter.get_visibility_for(REMOTE), "comeca escondido de quem nao e dono")
	_other.global_position = _beside(FAR_SPOT, 10.0)
	assert_eq(_concealment(_me).refresh(_observers(), _remote()), PackedInt32Array([REMOTE]))
	assert_true(filter.get_visibility_for(REMOTE))
	_other.global_position = _beside(FAR_SPOT, 13.0)
	assert_eq(_concealment(_me).refresh(_observers(), _remote()), PackedInt32Array([REMOTE]))
	assert_false(filter.get_visibility_for(REMOTE))


## Input atrasado faz o servidor ressimular ticks passados e retransmitir cada um: o que foi
## gravado antes da revelacao nao sai para quem acabou de passar a ver.
func test_ressimulacao_nao_retransmite_o_periodo_escondido() -> void:
	var ack := _me.get_node(NodePath(SpawnAck.NODE_NAME)) as SpawnAck
	ack.confirm(REMOTE)
	var concealment := _concealment(_me)
	_me.global_position = FAR_SPOT
	_other.global_position = _beside(FAR_SPOT, 10.0)
	var changed := concealment.refresh(_observers(), _remote())
	concealment.announce(changed, PackedInt32Array(), 100)
	NetworkRollback._is_rollback = true
	NetworkRollback._tick = 98  # grava o tick 99, de quando estava escondido
	var before: bool = concealment._visible_to(REMOTE)
	NetworkRollback._tick = 100  # grava o 101, depois da revelacao
	var after: bool = concealment._visible_to(REMOTE)
	NetworkRollback._is_rollback = false
	assert_false(before)
	assert_true(after)
	assert_true(concealment._visible_to(REMOTE), "fora do rollback vale a decisao do tick")


func test_monstro_so_vai_a_quem_o_tem_no_raio() -> void:
	var monster := _monster()
	var filter := (monster.get_node("StateSynchronizer") as StateSynchronizer).visibility_filter
	_other.global_position = _beside(monster.global_position, 12.5)
	_concealment(monster).refresh(_observers(), _remote())
	assert_false(filter.get_visibility_for(REMOTE))
	_other.global_position = _beside(monster.global_position, 11.5)
	_concealment(monster).refresh(_observers(), _remote())
	assert_true(filter.get_visibility_for(REMOTE))


func test_bau_avisa_quem_passa_a_ver() -> void:
	var chest := _chest()
	var seen: Array[int] = []
	_concealment(chest).sight_changed.connect(
		func(peer: int, shown: bool, _tick: int) -> void: seen.append(peer if shown else -peer)
	)
	_me.global_position = FAR_SPOT
	_other.global_position = _beside(chest.global_position, 3.0)
	var changed := _concealment(chest).refresh(_observers(), _remote())
	_concealment(chest).announce(changed, PackedInt32Array(), 10)
	assert_eq(seen, [REMOTE] as Array[int])
	assert_true(_concealment(chest).shown_to(REMOTE))
	assert_false(_concealment(chest).shown_to(LOCAL))


func test_bau_no_host_mostra_o_ultimo_estado_visto() -> void:
	var chest := _chest()
	_me.global_position = _beside(chest.global_position, 30.0)
	chest._show(50, true, Ids.NONE)  # aberto pelo adversario fora da visao do jogador local
	assert_true(chest.opened)
	assert_false(chest.shown_opened, "o jogador local nao viu abrir")
	_me.global_position = _beside(chest.global_position, 5.0)
	var changed := _concealment(chest).refresh(_observers(), PackedInt32Array())
	_concealment(chest).announce(changed, PackedInt32Array(), 60)
	assert_true(chest.shown_opened, "ao ver, a tampa abre")


func test_diretor_percorre_todos_os_alvos() -> void:
	var vision := VisionDirector.new()
	add_child_autofree(vision)
	var monster := _monster()
	_me.global_position = _beside(monster.global_position, 2.0)
	_other.global_position = FAR_SPOT
	assert_gt(vision.update(100), 0)
	assert_true(_concealment(monster).shown_to(LOCAL))
	assert_false(_concealment(monster).shown_to(REMOTE))
	assert_true(_concealment(monster).is_shown(), "no host o jogador local ve pela regra")
	assert_eq(vision.update(101), 0, "sem movimento, nada muda")


func test_aviso_conta_estado_recebido_escondido() -> void:
	var concealment := _concealment(_monster())
	var leaks := Concealment.state_leaks
	var cycles := Concealment.hidden_cycles
	concealment._hidden_here = false
	concealment._set_hidden(true, 100)
	concealment._first_after_hide = 103  # estado do tick 103 chegou com o alvo escondido
	concealment._set_hidden(false, 110)
	assert_eq(Concealment.hidden_cycles, cycles + 1)
	assert_eq(Concealment.state_leaks, leaks + 1)
	concealment._set_hidden(true, 200)
	concealment._first_after_hide = 230  # so estado de depois da revelacao (230 >= 220)
	concealment._set_hidden(false, 220)
	assert_eq(Concealment.state_leaks, leaks + 1)
