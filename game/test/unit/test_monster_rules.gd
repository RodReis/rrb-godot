extends GutTest
## FSM dos monstros nao-boss: parado -> persegue (aggro ou provocado por dano) -> volta (leash)
## -> parado.

var _data: MonsterData


func before_all() -> void:
	_data = MonsterData.new()
	_data.aggro_range = 6.0
	_data.leash_range = 10.0
	_data.melee_range = 1.8


func test_parado_percebe_heroi_no_alcance_de_aggro() -> void:
	assert_eq(
		MonsterRules.next_state(MonsterRules.State.IDLE, _data, 6.0, 0.0), MonsterRules.State.CHASE
	)
	assert_eq(
		MonsterRules.next_state(MonsterRules.State.IDLE, _data, 6.1, 0.0), MonsterRules.State.IDLE
	)


func test_parado_sem_heroi_continua_parado() -> void:
	assert_eq(
		MonsterRules.next_state(MonsterRules.State.IDLE, _data, INF, 0.0), MonsterRules.State.IDLE
	)


func test_perseguindo_alem_do_leash_volta() -> void:
	assert_eq(
		MonsterRules.next_state(MonsterRules.State.CHASE, _data, 1.0, 10.0),
		MonsterRules.State.CHASE
	)
	assert_eq(
		MonsterRules.next_state(MonsterRules.State.CHASE, _data, 1.0, 10.1),
		MonsterRules.State.RESET
	)


func test_perseguindo_sem_alvo_volta() -> void:
	assert_eq(
		MonsterRules.next_state(MonsterRules.State.CHASE, _data, INF, 2.0), MonsterRules.State.RESET
	)


func test_voltando_ignora_heroi_ate_chegar_em_casa() -> void:
	assert_eq(
		MonsterRules.next_state(MonsterRules.State.RESET, _data, 1.0, 3.0), MonsterRules.State.RESET
	)
	assert_eq(
		MonsterRules.next_state(MonsterRules.State.RESET, _data, 1.0, MonsterRules.HOME_REACHED),
		MonsterRules.State.IDLE
	)


func test_alcance_do_golpe_e_corpo_a_corpo_ou_distancia() -> void:
	assert_almost_eq(MonsterRules.attack_reach(_data), 1.8, 0.0001)
	var mage := MonsterData.new()
	mage.melee_range = 1.8
	mage.ranged_range = 7.0
	assert_almost_eq(MonsterRules.attack_reach(mage), 7.0, 0.0001)


## PI 2026-10-12 (F55): ferido por heroi, o monstro parado persegue mesmo fora do aggro.
func test_parado_provocado_persegue_fora_do_aggro() -> void:
	assert_eq(
		MonsterRules.next_state(MonsterRules.State.IDLE, _data, 9.0, 0.0, true),
		MonsterRules.State.CHASE
	)


func test_provocado_alem_do_leash_volta() -> void:
	assert_eq(
		MonsterRules.next_state(MonsterRules.State.CHASE, _data, 9.0, 10.1, true),
		MonsterRules.State.RESET
	)


func test_voltando_ignora_provocacao() -> void:
	assert_eq(
		MonsterRules.next_state(MonsterRules.State.RESET, _data, 9.0, 3.0, true),
		MonsterRules.State.RESET
	)
