extends GutTest
## Revide automatico: quem leva dano de heroi ou monstro sem alvo valido trava o agressor e o
## auto-ataque comeca sozinho (sem o jogador clicar). Dois Cavaleiros; servidor = processo do teste.

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const SKELETON: String = "res://scenes/monsters/skeleton_t1.tscn"
const TICK: float = 1.0 / 30.0
const ME: int = 1
const FOE: int = 2
const OTHER_FOE: int = 3
const MONSTER_UID: int = -5
const IN_REACH: Vector3 = Vector3(2.0, 0.0, 0.0)
const BEYOND_SIGHT: Vector3 = Vector3(0.0, 0.0, -20.0)

var _me: Hero
var _foe: Hero
var _tick: int = 100


func before_each() -> void:
	_tick = 100
	_me = _spawn(ME, GateRules.TEAM_A, Vector3.ZERO)
	_foe = _spawn(FOE, GateRules.TEAM_B, IN_REACH)


func _spawn(id: int, team: int, at: Vector3) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(id)
	hero.team = team
	hero.transform = Transform3D(Basis(), at)
	add_child_autofree(hero)
	return hero


func _step(count: int = 1) -> void:
	for i: int in count:
		_tick += 1
		_me._rollback_tick(TICK, _tick, true)
		_foe._rollback_tick(TICK, _tick, true)


## Golpe de [param aggressor] em [param me] que o alvo aplica no proximo tick.
func _strike(aggressor: int, damage: int = 10, source: int = 99) -> void:
	var effect := HitEffect.new(damage, IN_REACH)
	effect.aggressor_id = aggressor
	_me.receive_hit(_tick + 1, source, effect)


func test_dano_de_heroi_sem_alvo_trava_o_agressor_e_revida() -> void:
	_strike(FOE)
	_step()
	assert_eq(_me.target_id, FOE)
	assert_gt(_me.basic_cooldown, 0, "o basico saiu sem o botao")
	_step(2)
	assert_lt(_foe.hp, _foe.attributes.max_hp, "o auto-ataque feriu o agressor")


func test_dano_de_monstro_sem_alvo_trava_o_monstro() -> void:
	var monster := (load(SKELETON) as PackedScene).instantiate() as Monster
	monster.uid = MONSTER_UID
	monster.transform = Transform3D(Basis(), -IN_REACH)
	add_child_autofree(monster)
	_strike(MONSTER_UID)
	_step()
	assert_eq(_me.target_id, MONSTER_UID)


func test_alvo_valido_nao_e_trocado_pelo_agressor() -> void:
	var other := _spawn(OTHER_FOE, GateRules.TEAM_B, Vector3(0.0, 0.0, -6.0))
	_me.input.target_id = OTHER_FOE
	_step()
	_me.input.target_id = TargetRules.NONE
	_strike(FOE)
	_step()
	assert_eq(_me.target_id, OTHER_FOE)
	assert_not_null(other)


func test_agressor_fora_da_visao_nao_trava() -> void:
	_foe.global_position = BEYOND_SIGHT
	_strike(FOE)
	_step()
	assert_eq(_me.target_id, TargetRules.NONE, "o servidor nunca trava quem o heroi nao ve")


func test_golpe_sem_agressor_nao_trava() -> void:
	_strike(TargetRules.NONE)
	_step()
	assert_eq(_me.target_id, TargetRules.NONE, "zona, saque e XP nao sao agressao")


func test_golpe_sem_dano_nao_trava() -> void:
	_strike(FOE, 0)
	_step()
	assert_eq(_me.target_id, TargetRules.NONE)
