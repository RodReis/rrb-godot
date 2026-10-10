extends GutTest
## Integracao headless (F32, CONVENTION §4.7): arena + dois Cavaleiros. Heroi na moita some para
## o adversario fora dela (filtro de replicacao por peer no servidor), aparece na mesma moita e
## por 1,5 s depois de golpear; monstro nao da aggro e o bot nao enxerga heroi escondido.

const ARENA: String = "res://scenes/arena/arena.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const DT: float = 1.0 / 30.0
## Peers dos herois (nome do node = peer_id).
const HIDER: int = 7
const SEEKER: int = 8
## Distancia ate um ponto do lado de fora, colado na borda (u).
const EDGE_OUT: float = 0.1

var _grass: Area3D
var _hider: Hero
var _seeker: Hero
var _tick: int = 100


func before_each() -> void:
	add_child_autofree((load(ARENA) as PackedScene).instantiate())
	_grass = get_tree().get_first_node_in_group(VisibilityRules.GROUP) as Area3D
	_hider = _spawn(HIDER, GateRules.TEAM_A, false)
	_seeker = _spawn(SEEKER, GateRules.TEAM_B, false)
	_hider.global_position = _center()
	_seeker.global_position = _outside()


func _spawn(id: int, team: int, bot: bool) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(id)
	hero.team = team
	hero.is_bot = bot
	if bot:
		hero.get_node("Input").set_script(BotInput)
	add_child_autofree(hero)
	return hero


func _shape() -> CollisionShape3D:
	return _grass.get_child(0) as CollisionShape3D


func _center() -> Vector3:
	var at := _shape().global_position
	at.y = 0.0
	return at


## Ponto do lado de fora, EDGE_OUT alem da face +X da moita.
func _outside() -> Vector3:
	var half := (_shape().shape as BoxShape3D).size.x / 2.0
	return _center() + _shape().global_basis.x.normalized() * (half + EDGE_OUT)


func _step(hero: Hero) -> void:
	_tick += 1
	hero._rollback_tick(DT, _tick, true)


func _concealment(hero: Hero) -> Concealment:
	return hero.get_node(NodePath(Concealment.NODE_NAME)) as Concealment


func _filter(hero: Hero) -> PeerVisibilityFilter:
	return (hero.get_node("RollbackSynchronizer") as RollbackSynchronizer).visibility_filter


func test_arena_tem_moitas_com_caixa() -> void:
	assert_not_null(_grass)
	assert_true(_shape().shape is BoxShape3D)


func test_heroi_na_moita_some_para_quem_esta_fora_colado_na_borda() -> void:
	assert_true(_hider.hidden_from(_seeker))
	assert_false(_seeker.hidden_from(_hider), "quem esta fora segue visivel")


func test_mesma_moita_se_ve() -> void:
	_seeker.global_position = _center() + Vector3(0.5, 0.0, 0.0)
	assert_false(_hider.hidden_from(_seeker))


func test_so_some_do_adversario() -> void:
	var ally := _spawn(9, GateRules.TEAM_A, false)
	ally.global_position = _outside()
	assert_false(_hider.hidden_from(ally))


func test_sem_observador_conta_como_fora() -> void:
	assert_true(_hider.hidden_from(null))
	assert_false(_hider.hidden_from(_hider), "o dono sempre se ve")


func test_golpe_revela_por_1_5_s() -> void:
	_hider.input.attack = true
	_step(_hider)
	_hider.input.attack = false
	assert_eq(_hider.reveal_ticks, 45)
	assert_false(_hider.hidden_from(_seeker))
	for i: int in 44:
		_step(_hider)
	assert_false(_hider.hidden_from(_seeker), "ainda no ultimo tick da revelacao")
	_step(_hider)
	assert_true(_hider.hidden_from(_seeker))


func test_andar_na_moita_nao_revela() -> void:
	_hider.input.movement = Vector3.RIGHT * 0.1
	_step(_hider)
	assert_eq(_hider.reveal_ticks, 0)


func test_servidor_nao_manda_estado_a_quem_nao_ve() -> void:
	var ack := _hider.get_node(NodePath(SpawnAck.NODE_NAME)) as SpawnAck
	ack.confirm(SEEKER)
	ack.confirm(HIDER)
	var changed := _concealment(_hider).refresh(PackedInt32Array([HIDER, SEEKER]))
	assert_eq(changed, PackedInt32Array([SEEKER]))
	assert_false(_filter(_hider).get_visibility_for(SEEKER))
	assert_true(_filter(_hider).get_visibility_for(HIDER), "o dono recebe o proprio estado")
	assert_eq(_filter(_hider).get_visible_peers(), [HIDER] as Array[int])


func test_revelado_volta_a_receber_estado() -> void:
	var ack := _hider.get_node(NodePath(SpawnAck.NODE_NAME)) as SpawnAck
	ack.confirm(SEEKER)
	_concealment(_hider).refresh(PackedInt32Array([SEEKER]))
	_hider.input.attack = true
	_step(_hider)
	var changed := _concealment(_hider).refresh(PackedInt32Array([SEEKER]))
	assert_eq(changed, PackedInt32Array([SEEKER]))
	assert_true(_filter(_hider).get_visibility_for(SEEKER))


func test_sem_mudanca_nao_reenvia() -> void:
	var ack := _hider.get_node(NodePath(SpawnAck.NODE_NAME)) as SpawnAck
	ack.confirm(SEEKER)
	_concealment(_hider).refresh(PackedInt32Array([SEEKER]))
	assert_eq(_concealment(_hider).refresh(PackedInt32Array([SEEKER])), PackedInt32Array())


func test_peer_sem_spawn_confirmado_nao_recebe_aviso() -> void:
	assert_eq(_concealment(_hider).refresh(PackedInt32Array([SEEKER])), PackedInt32Array())
	assert_false(_filter(_hider).get_visibility_for(SEEKER))


func test_monstro_nao_da_aggro_em_heroi_escondido() -> void:
	var director := SpawnDirector.new()
	add_child_autofree(director)
	_seeker.global_position = Vector3(0.0, 0.0, -30.0)  # longe do monstro
	var monster := _monster(director)
	monster.global_position = _outside() + _shape().global_basis.x.normalized()
	monster._home = monster.global_position  # perto de casa: o leash nao decide por nos
	monster._on_network_tick(DT, _tick)
	assert_eq(monster.state, MonsterRules.State.IDLE)
	_hider.input.attack = true
	_step(_hider)
	monster._on_network_tick(DT, _tick)
	assert_eq(monster.state, MonsterRules.State.CHASE, "revelado: entra no aggro")
	_hider.input.attack = false
	for i: int in 45:
		_step(_hider)
	monster._on_network_tick(DT, _tick)
	assert_eq(monster.state, MonsterRules.State.RESET, "escondido de novo: perde o alvo")


func test_bot_nao_enxerga_heroi_escondido() -> void:
	var bot := _spawn(2, GateRules.TEAM_B, true)
	bot.global_position = _outside()
	var brain := bot.input as BotInput
	brain._hero = bot
	assert_null(brain._enemy_hero())
	_hider.input.attack = true
	_step(_hider)
	assert_eq(brain._enemy_hero(), _hider, "revelado")


## Monstro comum (sem o Rei Esqueleto) do SpawnDirector.
func _monster(director: SpawnDirector) -> Monster:
	for node: Node in director.get_children():
		var monster := node as Monster
		if monster != null and monster.data.tier != MonsterData.Tier.BOSS:
			return monster
	return null
