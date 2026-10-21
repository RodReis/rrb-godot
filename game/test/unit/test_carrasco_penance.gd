extends CarrascoTestBase
## Penitencia do Carrasco (GDB §4.11, F98; SPEC-098 §6 item 1): canaliza ate 2 s imovel, mitiga 40
## %, +1 Dor a cada 0,5 s, cura distribuida; explode em 3 u com raiz 1 s (Dor >= 4) ou lentidao 40 %
## por 1,5 s; E de novo encerra antes; atordoamento cancela sem explosao (a cura dada fica).

const LEVEL: int = 2
const RANKS: Vector3i = Vector3i(1, 1, 0)
const CHANNEL_TICKS: int = 60


func _start_penance() -> void:
	_carrasco.input.skill_e = true
	_run(START, 1)


func test_canaliza_imovel_e_sem_basico() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 1.5)
	_start_penance()
	assert_true(_carrasco.is_channeling())
	assert_gt(_carrasco.e_cooldown, 0, "recarga no inicio: revela no mato")
	_carrasco.input.movement = Vector3(1, 0, 0)
	_carrasco.input.attack = true
	_run(START + 1, 5)
	assert_almost_eq(_carrasco.global_position.x, 0.0, EPS, "nao anda")
	assert_eq(knight.hp, KNIGHT_HP, "nao ataca")


func test_mitiga_40_por_cento_canalizando() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	_start_penance()
	_carrasco.hp = 300  # longe do teto: a cura do tick nao esconde o dano
	var hp := _carrasco.hp
	_strike_carrasco(START + 1, 9, HitEffect.new(200, AHEAD), HitLedger.Slot.Q)
	_run(START + 1, 1)
	var taken := roundi(CombatRules.mitigated(200, _carrasco._defense()) * 0.6)
	var healed := _carrasco.penance_healed
	assert_eq(hp - _carrasco.hp + healed, taken)


func test_canalizacao_inteira_da_4_dor_cura_tudo_e_prende() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 2.5)
	_carrasco.hp = 200
	_start_penance()
	_run(START + 1, CHANNEL_TICKS - 1)
	assert_true(_carrasco.is_channeling(), "ultimo tick ainda vem")
	assert_eq(_carrasco.pain, 3)
	_run(START + CHANNEL_TICKS, 2)
	assert_false(_carrasco.is_channeling())
	var e := _carrasco.hero_data.skill_e
	var atk := _carrasco.attributes.attack
	var heal := CarrascoRules.with_pain(60.0, 0.4, atk, 10.0, 4)
	assert_eq(_carrasco.hp, 200 + heal, "cura total com a Dor do fim")
	var blast := CarrascoRules.with_pain(50.0, 0.5, atk, 10.0, 4)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(blast, KNIGHT_DEF))
	assert_almost_eq(knight.slow_pct, 1.0, 0.001, "Dor 4: raiz")
	assert_eq(_carrasco.pain, 0, "a explosao consome a Dor")
	assert_eq(_carrasco.blasts, 1)
	assert_almost_eq(e.radius, 3.0, EPS)


func test_e_de_novo_encerra_antes_com_lentidao() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 2.5)
	_start_penance()
	_run(START + 1, 10)  # solta o E
	_carrasco.input.skill_e = true
	_run(START + 11, 2)
	assert_false(_carrasco.is_channeling())
	assert_eq(_carrasco.blasts, 1)
	assert_almost_eq(knight.slow_pct, 0.4, 0.001, "Dor 0: lentidao")
	assert_lt(knight.hp, KNIGHT_HP)


func test_segurar_e_nao_encerra() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	for i: int in 20:
		_carrasco.input.skill_e = true
		_run(START + i, 1)
	assert_true(_carrasco.is_channeling())
	assert_eq(_carrasco.blasts, 0)


func test_dor_acumulada_antes_conta_na_raiz() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 2.0)
	_carrasco.pain = 4
	_carrasco.pain_ticks = 100
	_start_penance()
	_run(START + 1, 3)
	_carrasco.input.skill_e = true
	_run(START + 4, 2)
	assert_almost_eq(knight.slow_pct, 1.0, 0.001)


func test_atordoamento_cancela_sem_explodir_e_a_cura_fica() -> void:
	_spawn_carrasco(LEVEL, RANKS)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 2.5)
	_carrasco.hp = 200
	_start_penance()
	_run(START + 1, 30)
	var healed := _carrasco.penance_healed
	assert_gt(healed, 0)
	var stun := HitEffect.new(0, AHEAD)
	stun.stun_ticks = 10
	_strike_carrasco(START + 31, 9, stun, HitLedger.Slot.Q)
	_run(START + 31, 40)
	assert_false(_carrasco.is_channeling())
	assert_eq(_carrasco.blasts, 0, "sem explosao")
	assert_eq(knight.hp, KNIGHT_HP)
	assert_eq(_carrasco.hp, 200 + healed)
