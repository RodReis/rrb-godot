extends CarrascoTestBase
## Correntes do Julgamento do Carrasco (GDB §4.11, F98; SPEC-098 §6 item 1): projetil (6 u) que passa
## por monstro e para no 1o heroi: dano, raiz e raio de luz de 2,5 u pela duracao da raiz; o heroi
## preso dentro da luz com HP < 25 % e executado (kill do Carrasco); a Bencao Inviolavel bloqueia;
## o Ragnarok impede a raiz, nao a execucao.

const LEVEL: int = 6
const RANKS: Vector3i = Vector3i(1, 1, 1)
const ROOT_TICKS: int = 38  # 1,25 s a 30/s


func _cast_chains() -> void:
	_carrasco.input.skill_r = true
	_run(START, 1)


func test_correntes_ferem_prendem_e_acendem_a_luz() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 4.0, VICTIM, LEVEL)
	var hp := knight.hp
	_cast_chains()
	_run(START + 1, 10)
	var r := _carrasco.hero_data.skill_r
	var raw := roundi(SkillRules.amount(r, 1, _carrasco.attributes))
	assert_eq(raw, roundi(120 + 1.0 * _carrasco.attributes.intelligence))
	assert_eq(hp - knight.hp, CombatRules.mitigated(raw, knight._defense()))
	assert_almost_eq(knight.slow_pct, 1.0, 0.001, "raiz")
	assert_true(_carrasco.light_on())
	assert_eq(_carrasco.light_target, knight.combat_id())
	assert_almost_eq(Vector2(_carrasco.light_at.x, _carrasco.light_at.z).length(), 4.0, 0.5)


func test_passa_pelo_monstro() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var golem := _spawn_monster(GOLEM, 900, AHEAD * 2.0)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 4.5, VICTIM, LEVEL)
	var hp := knight.hp
	_cast_chains()
	_run(START + 1, 10)
	assert_eq(golem.hp, GOLEM_HP, "monstro nao e alvo")
	assert_lt(knight.hp, hp)


func test_nao_alcanca_alem_de_6_u() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 7.5, VICTIM, LEVEL)
	var hp := knight.hp
	_cast_chains()
	_run(START + 1, 20)
	assert_eq(knight.hp, hp)
	assert_false(_carrasco.light_on())


func test_executa_abaixo_de_25_por_cento_na_luz() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 3.0, VICTIM, LEVEL)
	var r := _carrasco.hero_data.skill_r
	var raw := roundi(SkillRules.amount(r, 1, _carrasco.attributes))
	# Depois das Correntes fica com ~20 % do HP maximo: abaixo de 25 %.
	knight.hp = CombatRules.mitigated(raw, knight._defense()) + int(knight.attributes.max_hp * 0.2)
	_cast_chains()
	_run(START + 1, 15)
	assert_false(knight.is_alive(), "executado")
	assert_eq(knight.killer_id, _carrasco.peer_id, "kill do Carrasco")


func test_acima_de_25_por_cento_sobrevive() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 3.0, VICTIM, LEVEL)
	_cast_chains()
	_run(START + 1, ROOT_TICKS + 5)
	assert_true(knight.is_alive())
	assert_false(_carrasco.light_on(), "a luz apaga com a raiz")


func test_cai_abaixo_de_25_por_cento_ainda_na_luz_e_executado() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 3.0, VICTIM, LEVEL)
	_cast_chains()
	_run(START + 1, 10)
	assert_true(knight.is_alive())
	knight.hp = int(knight.attributes.max_hp * 0.2)  # outro golpe o derrubou
	_run(START + 11, 3)
	assert_false(knight.is_alive())


func test_fora_da_luz_nao_executa() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 3.0, VICTIM, LEVEL)
	_cast_chains()
	_run(START + 1, 8)
	knight.global_position = AHEAD * 6.5  # empurrado para fora da luz
	_run(START + 9, 1)  # a marca do tick em que ainda estava dentro sai com o HP alto
	knight.hp = int(knight.attributes.max_hp * 0.2)
	_run(START + 10, 4)
	assert_true(knight.is_alive())


func test_bencao_inviolavel_bloqueia_a_execucao() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var paladin := _spawn_enemy(PALADIN, AHEAD * 3.0, VICTIM, LEVEL)
	paladin.hp = int(paladin.attributes.max_hp * 0.1)
	paladin.invuln_ticks = 200
	_cast_chains()
	_run(START + 1, 15)
	assert_true(paladin.is_alive())


func test_ragnarok_impede_a_raiz_mas_nao_a_execucao() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var berserker := _spawn_enemy(BERSERKER, AHEAD * 3.0, VICTIM, LEVEL)
	berserker.cc_immune_ticks = 200
	_cast_chains()
	_run(START + 1, 3)
	assert_eq(berserker.slow_ticks, 0, "imune a raiz")
	berserker.hp = int(berserker.attributes.max_hp * 0.2)
	_run(START + 4, 3)
	assert_false(berserker.is_alive(), "parado na luz: executado")

