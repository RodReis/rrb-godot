extends RogueTestBase
## Bomba de Fumaca (GDB §4.5, §7.3; ADR-0013; SPEC-058 §8 item 3): a nuvem vale como moita para
## qualquer heroi por 3,0 s — quem esta dentro some para quem esta fora, dois dentro se veem;
## lancar nao revela; o basico de dentro revela por 1,5 s. Servidor = processo do teste.

const ALLY_OBSERVER: int = 9
## 3,0 s e 1,5 s a 30 ticks/s.
const SMOKE_TICKS: int = 90
const REVEAL_TICKS: int = 45


func _cast_smoke() -> void:
	_rogue.input.skill_e = true
	_run(START, 1)


func _spawn_ally_observer(at: Vector3) -> Knight:
	var knight := (load(KNIGHT) as PackedScene).instantiate() as Knight
	knight.name = str(ALLY_OBSERVER)
	knight.team = GateRules.TEAM_A
	knight.transform = Transform3D(Basis(), at)
	add_child_autofree(knight)
	return knight


func test_nuvem_nasce_no_lugar_da_ladina_com_3_s() -> void:
	_spawn_rogue(2, SIDE * 2.0)
	_cast_smoke()
	assert_almost_eq(_rogue.smoke_center, SIDE * 2.0, Vector3.ONE * EPS)
	assert_eq(_rogue.smoke_ticks, SMOKE_TICKS, "conta a partir do tick seguinte")


func test_dentro_da_nuvem_nao_e_vista_de_fora() -> void:
	_spawn_rogue(2)
	var outside := _spawn_knight(AHEAD * 6.0)
	assert_false(_rogue.hidden_from(outside), "antes da fumaca")
	_cast_smoke()
	assert_true(_rogue.hidden_from(outside))
	assert_false(outside.hidden_from(_rogue), "quem esta fora segue visivel")


func test_lancar_a_fumaca_nao_revela() -> void:
	_spawn_rogue(2)
	var outside := _spawn_knight(AHEAD * 6.0)
	_cast_smoke()
	assert_eq(_rogue.reveal_ticks, 0)
	assert_true(_rogue.hidden_from(outside))


func test_dois_dentro_da_nuvem_se_veem() -> void:
	_spawn_rogue(2)
	var inside := _spawn_knight(AHEAD * 2.0)
	_cast_smoke()
	assert_false(_rogue.hidden_from(inside))
	assert_false(inside.hidden_from(_rogue))


func test_adversario_dentro_da_nuvem_tambem_some() -> void:
	_spawn_rogue(2)
	var enemy := _spawn_knight(AHEAD * 2.0)
	var ally := _spawn_ally_observer(AHEAD * 8.0)
	_cast_smoke()
	assert_true(enemy.hidden_from(ally), "a nuvem vale para qualquer heroi")


func test_basico_de_dentro_revela_por_1_5_s() -> void:
	_spawn_rogue(2)
	var outside := _spawn_knight(SIDE * 6.0)  # fora da linha do virote
	_cast_smoke()
	_rogue.input.attack = true
	_run(START + 1, 1)
	assert_eq(_rogue.reveal_ticks, REVEAL_TICKS)
	assert_false(_rogue.hidden_from(outside))
	_run(START + 2, REVEAL_TICKS)
	assert_true(_rogue.hidden_from(outside), "acabou a revelacao, a nuvem ainda esta la")


func test_nuvem_some_aos_3_s() -> void:
	_spawn_rogue(2)
	var outside := _spawn_knight(AHEAD * 6.0)
	_cast_smoke()
	_run(START + 1, SMOKE_TICKS - 1)
	assert_true(_rogue.hidden_from(outside), "ultimo tick da nuvem")
	_run(START + SMOKE_TICKS, 1)
	assert_eq(_rogue.smoke_ticks, 0)
	assert_false(_rogue.hidden_from(outside))


func test_monstro_nao_ve_quem_esta_na_nuvem() -> void:
	_spawn_rogue(2)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	_cast_smoke()
	assert_true(_rogue.hidden_from(golem))


func test_moita_e_nuvem_juntas_se_veem() -> void:
	# Decisao do PI (2026-10-13): quem esta na moita ve quem esta na moita e na nuvem.
	_grass_at(AHEAD * 4.0, Vector3(4, 2.4, 4))
	_spawn_rogue(2, AHEAD * 2.5)  # na moita e, depois, na nuvem
	var in_grass := _spawn_knight(AHEAD * 5.5)  # so na moita
	var outside := _spawn_knight(SIDE * 8.0, VICTIM + 2)
	_cast_smoke()
	assert_false(_rogue.hidden_from(in_grass))
	assert_true(_rogue.hidden_from(outside))


func test_nuvem_emite_smoked_no_servidor() -> void:
	_spawn_rogue(2)
	watch_signals(_rogue)
	_cast_smoke()
	assert_signal_emitted_with_parameters(_rogue, "smoked", [Vector3.ZERO, START])
