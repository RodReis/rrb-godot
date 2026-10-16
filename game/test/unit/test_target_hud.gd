extends GutTest
## SPEC-066 §4: moldura do alvo na HUD (HeroPlate) e anel no chao (TargetRing) seguem o alvo
## travado do heroi local, so enquanto o jogador o ve.

const PLATE: PackedScene = preload("res://scenes/ui/hero_plate.tscn")
const RING: PackedScene = preload("res://scenes/vfx/target_ring.tscn")
const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")
## Peer do jogador deste processo (offline = 1): o heroi dele e o unico que aparece sem conexao.
const SHOWN_PEER: int = 1
const LOCAL_PEER: int = 2
const STUB_ID: int = 9
const AT: Vector3 = Vector3(4.0, 0.0, -3.0)


## Alvo de teste que o jogador deixa de ver: ainda nao ha conexao para o Concealment real.
class StubTarget:
	extends Combatant
	var alive: bool = true
	var shown: bool = true

	func combat_id() -> int:
		return STUB_ID

	func is_alive() -> bool:
		return alive

	func is_shown() -> bool:
		return shown


var _hero: Hero
var _foe: Hero
var _stub: StubTarget
var _plate: HeroPlate
var _ring: TargetRing


func before_each() -> void:
	_hero = _knight(LOCAL_PEER, GateRules.TEAM_A)
	_foe = _knight(SHOWN_PEER, GateRules.TEAM_B)
	_foe.global_position = AT
	_stub = StubTarget.new()
	_stub.global_position = AT
	add_child_autofree(_stub)
	_plate = add_child_autofree(PLATE.instantiate())
	_plate.bind(_hero)
	_ring = add_child_autofree(RING.instantiate())
	_ring.bind(_hero)
	await wait_process_frames(1)


func _knight(peer: int, team: int) -> Hero:
	var hero := KNIGHT.instantiate() as Hero
	hero.name = str(peer)
	hero.team = team
	add_child_autofree(hero)
	return hero


func _frame() -> TargetFrame:
	return _plate.get_node("%TargetFrame") as TargetFrame


func test_sem_alvo_a_moldura_e_o_anel_ficam_escondidos() -> void:
	_plate.update()
	await wait_process_frames(1)
	assert_false(_frame().visible)
	assert_false(_ring.visible)


func test_moldura_mostra_nome_etiqueta_e_hp_do_alvo() -> void:
	_hero.target_id = SHOWN_PEER
	_plate.update()
	assert_true(_frame().visible)
	assert_eq((_frame().get_node("%TargetName") as Label).text, "Cavaleiro")
	assert_eq((_frame().get_node("%TargetTag") as Label).text, "Nv 1")
	var numbers := "%d / %d" % [_foe.hp, _foe.attributes.max_hp]
	assert_eq((_frame().get_node("%TargetHp").get_node("%Numbers") as Label).text, numbers)


func test_moldura_segue_o_hp_do_alvo() -> void:
	_hero.target_id = SHOWN_PEER
	_plate.update()
	_foe.hp -= 100
	_plate.update()
	var bar := _frame().get_node("%TargetHp").get_node("%Bar") as ProgressBar
	assert_eq(bar.value, float(_foe.hp))


func test_moldura_some_ao_destravar() -> void:
	_hero.target_id = SHOWN_PEER
	_plate.update()
	_hero.target_id = TargetRules.NONE
	_plate.update()
	assert_false(_frame().visible)


func test_moldura_some_se_o_jogador_nao_ve_mais_o_alvo() -> void:
	_hero.target_id = STUB_ID
	_stub.shown = false
	_plate.update()
	assert_false(_frame().visible)


func test_moldura_some_com_o_alvo_morto() -> void:
	_hero.target_id = SHOWN_PEER
	_foe.hp = 0
	_plate.update()
	assert_false(_frame().visible)


func test_anel_fica_sob_o_alvo() -> void:
	_hero.target_id = SHOWN_PEER
	await wait_process_frames(1)
	assert_true(_ring.visible)
	assert_almost_eq(_ring.global_position.x, AT.x, 0.001)
	assert_almost_eq(_ring.global_position.z, AT.z, 0.001)
	assert_gt(_ring.global_position.y, 0.0, "levantado do chao")


func test_anel_some_quando_o_alvo_sai_da_visao() -> void:
	_hero.target_id = STUB_ID
	_stub.shown = false
	await wait_process_frames(1)
	assert_false(_ring.visible)


func test_tooltip_do_basico_diz_alvo_e_ataque() -> void:
	_plate.update()
	var basic := _plate.get_node("%Basic") as SkillButton
	assert_string_contains(basic.tooltip_text, "RMB")
	assert_string_contains(basic.tooltip_text, "alvo / ataque")
