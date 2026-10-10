extends GutTest
## Vitoria na ordem do GDB §7.2: 1) meta de kills; 2) na morte subita, adversario sem vivos;
## 3) colapso aos 10:00 — maior HP% e, empatado, mais kills na fase 2, mais dano em herois e
## sorteio pela seed. Ninguem conectado = abandoned. Nunca empate (I2).

const GOAL: int = 5
const SEED: int = 4242
const P1: int = 11
const P2: int = 22

var _a: VictoryRules.Contender
var _b: VictoryRules.Contender


func before_each() -> void:
	_a = _contender(P1)
	_b = _contender(P2)


func _contender(peer: int) -> VictoryRules.Contender:
	var c := VictoryRules.Contender.new()
	c.peer = peer
	c.alive = true
	c.connected = true
	c.hp_pct = 1.0
	return c


func _evaluate(sudden_death: bool, collapsed: bool) -> VictoryRules.Verdict:
	return VictoryRules.evaluate(_pair(_a, _b), GOAL, sudden_death, collapsed, SEED)


func _pair(x: VictoryRules.Contender, y: VictoryRules.Contender) -> Array[VictoryRules.Contender]:
	return [x, y]


func test_sem_criterio_a_partida_segue() -> void:
	_a.kills = GOAL - 1
	var verdict := _evaluate(false, false)
	assert_false(verdict.is_over())
	assert_eq(verdict.winner, VictoryRules.NO_WINNER)


func test_meta_de_kills_vence() -> void:
	_b.kills = GOAL
	var verdict := _evaluate(false, false)
	assert_eq(verdict.winner, P2)
	assert_eq(verdict.reason, VictoryRules.KILL_GOAL)


func test_meta_de_kills_vem_antes_da_eliminacao() -> void:
	_a.kills = GOAL
	_a.alive = false
	var verdict := _evaluate(true, false)
	assert_eq(verdict.winner, P1)
	assert_eq(verdict.reason, VictoryRules.KILL_GOAL)


func test_os_dois_na_meta_no_mesmo_tick_nao_empata() -> void:
	_a.kills = GOAL
	_b.kills = GOAL
	_b.damage = 10
	var verdict := _evaluate(false, false)
	assert_eq(verdict.winner, P2, "mais dano")
	assert_eq(verdict.reason, VictoryRules.KILL_GOAL)


func test_morto_fora_da_morte_subita_nao_encerra() -> void:
	_a.alive = false
	assert_false(_evaluate(false, false).is_over())


func test_eliminacao_na_morte_subita() -> void:
	_a.alive = false
	var verdict := _evaluate(true, false)
	assert_eq(verdict.winner, P2)
	assert_eq(verdict.reason, VictoryRules.ELIMINATION)


func test_os_dois_vivos_na_morte_subita_segue() -> void:
	assert_false(_evaluate(true, false).is_over())


func test_os_dois_mortos_na_morte_subita_desempata() -> void:
	_a.alive = false
	_b.alive = false
	_a.hp_pct = 0.0
	_b.hp_pct = 0.0
	_a.kills = 2
	var verdict := _evaluate(true, false)
	assert_eq(verdict.winner, P1, "mais kills")
	assert_eq(verdict.reason, VictoryRules.ELIMINATION)


func test_colapso_maior_hp_percentual_vence() -> void:
	_a.hp_pct = 0.4
	_b.hp_pct = 0.6
	_a.kills = 4
	var verdict := _evaluate(true, true)
	assert_eq(verdict.winner, P2)
	assert_eq(verdict.reason, VictoryRules.COLLAPSE_HP)


func test_colapso_empate_de_hp_desempata_por_kills() -> void:
	_a.hp_pct = 0.5
	_b.hp_pct = 0.5
	_a.kills = 3
	_b.kills = 1
	_b.damage = 900
	var verdict := _evaluate(true, true)
	assert_eq(verdict.winner, P1)
	assert_eq(verdict.reason, VictoryRules.COLLAPSE_KILLS)


func test_colapso_empate_de_hp_e_kills_desempata_por_dano() -> void:
	_a.kills = 2
	_b.kills = 2
	_a.damage = 300
	_b.damage = 301
	var verdict := _evaluate(true, true)
	assert_eq(verdict.winner, P2)
	assert_eq(verdict.reason, VictoryRules.COLLAPSE_DAMAGE)


func test_colapso_empate_total_sorteia_pela_seed() -> void:
	var verdict := _evaluate(true, true)
	assert_true(verdict.winner == P1 or verdict.winner == P2, "sempre um vencedor")
	assert_eq(verdict.reason, VictoryRules.COLLAPSE_DRAW)
	var again := VictoryRules.evaluate(_pair(_b, _a), GOAL, true, true, SEED)
	assert_eq(again.winner, verdict.winner, "mesma seed, mesmo vencedor, qualquer ordem")


func test_sorteio_depende_da_seed() -> void:
	var winners := {}
	for seed_value: int in range(1, 40):
		winners[VictoryRules.evaluate(_pair(_a, _b), GOAL, true, true, seed_value).winner] = true
	assert_eq(winners.size(), 2, "as duas saidas aparecem")


func test_ninguem_conectado_e_abandoned() -> void:
	_a.connected = false
	_b.connected = false
	_a.hp_pct = 0.9
	var verdict := _evaluate(true, true)
	assert_eq(verdict.winner, VictoryRules.NO_WINNER)
	assert_eq(verdict.reason, VictoryRules.ABANDONED)


func test_um_conectado_nao_e_abandoned() -> void:
	_a.connected = false
	_a.hp_pct = 0.9
	_b.hp_pct = 0.1
	var verdict := _evaluate(true, true)
	assert_eq(verdict.winner, P1, "o desconectado ainda pode vencer pelo HP")
	assert_eq(verdict.reason, VictoryRules.COLLAPSE_HP)


func test_ninguem_conectado_so_decide_quando_a_partida_acabaria() -> void:
	_a.connected = false
	_b.connected = false
	assert_false(_evaluate(false, false).is_over())


func test_nunca_empata_em_combinacoes_de_hp_kills_e_dano() -> void:
	for hp_a: float in [0.0, 0.5, 1.0]:
		for kills_a: int in [0, 2]:
			for damage_a: int in [0, 100]:
				_a.hp_pct = hp_a
				_a.kills = kills_a
				_a.damage = damage_a
				var verdict := _evaluate(true, true)
				assert_true(verdict.winner == P1 or verdict.winner == P2)
