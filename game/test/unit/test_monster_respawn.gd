extends GutTest
## Respawn de monstros na fase 1 (GDB §5, PI 2026-10-10, F36), com o relogio injetado: o teste
## chama SpawnDirector.update(tick) e stop_respawns(tick) com ticks proprios, sem o NetworkTime.
## Monstro nao-boss renasce no proprio marcador 90 s depois de morrer, so na fase 1; na
## transicao os pendentes sao cancelados; o boss nunca renasce.

const ARENA: String = "res://scenes/arena/arena.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RULES: MatchRules = preload("res://shared/data/rules/match_pacing.tres")
const DT: float = 1.0 / 30.0

var _director: SpawnDirector
var _hero: Hero
var _tick: int = 100


func before_each() -> void:
	_tick = 100
	add_child_autofree((load(ARENA) as PackedScene).instantiate())
	_director = SpawnDirector.new()
	_director.loot_seed = 7
	add_child_autofree(_director)
	_hero = (load(KNIGHT) as PackedScene).instantiate() as Hero
	_hero.name = "1"
	_hero.team = GateRules.TEAM_A
	add_child_autofree(_hero)


func _respawn_ticks() -> int:
	return SkillRules.seconds_to_ticks(RULES.monster_respawn_phase1, NetworkTime.tickrate)


func _first_monster() -> Monster:
	for node: Node in _director.get_children():
		if node is Monster:
			return node as Monster
	return null


## Golpe letal do heroi no tick seguinte; devolve o tick da morte.
func _kill(monster: Monster) -> int:
	_tick += 1
	var effect := HitEffect.new(monster.hp)
	effect.attacker_id = _hero.peer_id
	monster.receive_hit(_tick, HitLedger.source_key(_hero.peer_id, HitLedger.Slot.BASIC), effect)
	_hero._rollback_tick(DT, _tick, true)
	return _tick


func test_respawn_de_90s_vem_do_match_pacing() -> void:
	assert_eq(RULES.monster_respawn_phase1, 90.0)


func test_renasce_aos_90s_no_marcador_com_hp_cheio() -> void:
	var monster := _first_monster()
	var home := monster.global_position
	var died_at := _kill(monster)
	monster.global_position += Vector3(3.0, 0.0, 0.0)  # morreu longe do marcador (perseguindo)
	_director.update(died_at + _respawn_ticks() - 1)
	assert_false(monster.is_alive(), "renasceu antes dos 90 s")
	_director.update(died_at + _respawn_ticks())
	assert_true(monster.is_alive())
	assert_eq(monster.hp, roundi(monster.data.hp))
	assert_almost_eq(monster.global_position, home, Vector3.ONE * 0.01)
	assert_eq(monster.state, MonsterRules.State.IDLE)
	assert_ne(monster.collision_mask, 0, "renasceu sem colisao")


func test_monstro_renascido_da_xp_de_novo() -> void:
	var monster := _first_monster()
	var died_at := _kill(monster)
	var xp := _hero.xp
	assert_gt(xp, 0)
	_tick = died_at + _respawn_ticks()
	_director.update(_tick)
	_kill(monster)
	assert_gt(_hero.xp, xp)


func test_nao_renasce_na_fase_2() -> void:
	_director.stop_respawns(_tick)
	var monster := _first_monster()
	var died_at := _kill(monster)
	_director.update(died_at + _respawn_ticks() * 2)
	assert_false(monster.is_alive())


func test_timer_pendente_na_transicao_e_cancelado() -> void:
	var monster := _first_monster()
	var died_at := _kill(monster)
	_director.stop_respawns(died_at + 10)
	_director.update(died_at + _respawn_ticks() * 2)
	assert_false(monster.is_alive())


func test_vivos_na_transicao_continuam_vivos() -> void:
	var monster := _first_monster()
	_director.stop_respawns(_tick)
	_director.update(_tick + _respawn_ticks())
	assert_true(monster.is_alive())


func test_boss_nunca_renasce() -> void:
	_director.spawn_boss()
	var boss := _director.get_node(SpawnDirector.BOSS_NAME) as Monster
	var died_at := _kill(boss)
	_director.update(died_at + _respawn_ticks() * 2)
	assert_false(boss.is_alive())
