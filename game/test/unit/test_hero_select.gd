# gdlint: ignore=max-public-methods
extends GutTest
## Tela de selecao (F51, prototipo "Seleção de Heróis") ligada ao MatchController: abre com o
## primeiro heroi disponivel, a grade so tem heroi com cena, o card esquerdo mostra papel,
## descricao, Q/E/R e atributos do HeroData, o lock-in so vale quando o servidor confirma, e o
## pick do adversario aparece no card dele (espelho permitido).

const SCENE: String = "res://scenes/ui/hero_select.tscn"
const RULES: String = "res://shared/data/rules/match_pacing.tres"
const ROSTER: Array[HeroData] = [
	preload("res://shared/data/heroes/knight.tres"),
	preload("res://shared/data/heroes/ranger.tres"),
]
const FULL_ROSTER: Array[HeroData] = [
	ROSTER[0],
	ROSTER[1],
	preload("res://shared/data/heroes/barbarian.tres"),
	preload("res://shared/data/heroes/fire_wizard.tres"),
	preload("res://shared/data/heroes/rogue.tres"),
	preload("res://shared/data/heroes/engineer.tres"),
	preload("res://shared/data/heroes/druid.tres"),
	preload("res://shared/data/heroes/berserker.tres"),
	preload("res://shared/data/heroes/occultist.tres"),
	preload("res://shared/data/heroes/paladin.tres"),
	preload("res://shared/data/heroes/carrasco.tres"),
]
const KNIGHT_ONLY: Array[StringName] = [&"knight"]
const ALL_SCENES: Array[StringName] = [
	&"knight",
	&"ranger",
	&"barbarian",
	&"fire_wizard",
	&"rogue",
	&"engineer",
	&"druid",
	&"berserker",
	&"occultist",
	&"paladin",
	&"carrasco"
]
const RATE: int = 30
const START: int = 1000
const RIVAL: int = 22

var _match: MatchController
var _screen: HeroSelect


func before_each() -> void:
	var rules := load(RULES) as MatchRules
	var clock := MatchClock.new()
	clock.rules = rules
	add_child_autofree(clock)
	_match = MatchController.new()
	_match.rules = rules
	_match.clock = clock
	_match.available_heroes = KNIGHT_ONLY.duplicate()
	add_child_autofree(_match)
	_match.open(START, RATE)
	_match.join(multiplayer.get_unique_id(), GateRules.TEAM_A, false, START)
	_match.join(RIVAL, GateRules.TEAM_B, false, START)
	_screen = _make_screen(ROSTER, KNIGHT_ONLY.duplicate())


## Troca de modelo no preview usa queue_free: deixa o frame liberar antes da contagem de orfaos.
func after_each() -> void:
	await wait_process_frames(1)


func _make_screen(roster: Array[HeroData], available: Array[StringName]) -> HeroSelect:
	var screen := (load(SCENE) as PackedScene).instantiate() as HeroSelect
	add_child_autofree(screen)
	screen.bind(_match, roster, available)
	screen.open(24.0)
	return screen


func _press(screen: HeroSelect, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	screen._unhandled_input(event)


func _my_hero() -> StringName:
	for seat: MatchController.Seat in _match.seats():
		if seat.peer == multiplayer.get_unique_id():
			return seat.hero
	return &"?"


func test_abre_com_o_cavaleiro_e_a_grade_so_tem_heroi_com_cena() -> void:
	assert_true(_screen.visible)
	assert_eq(_screen._player_name.text, "CAVALEIRO")
	assert_eq(_screen._cards.keys(), [0], "Arqueira sem cena fica fora da grade")
	assert_eq(_screen._choices.get_child_count(), 1)
	assert_true(_screen._cards[0]._tag.visible, "selo ATIVO no escolhido")


## #229: os previews grandes (voce e oponente) comecam de frente e so depois giram; 180 = de frente
## nos KayKit (MonsterPreview3D.facing).
func test_previews_comecam_de_frente() -> void:
	assert_eq(HeroSelect.PREVIEW_FACING, 180.0)
	assert_eq(_screen._player_preview.facing, HeroSelect.PREVIEW_FACING)
	assert_eq(_screen._enemy_preview.facing, HeroSelect.PREVIEW_FACING)


func test_tecla_2_nao_escolhe_heroi_sem_cena() -> void:
	_press(_screen, KEY_2)
	assert_eq(_screen._player_name.text, "CAVALEIRO")


func test_card_esquerdo_mostra_dados_do_heroi() -> void:
	var knight := ROSTER[0]
	assert_eq(_screen._player_role.text, "TANQUE")
	assert_eq(_screen._player_summary.text, knight.summary)
	assert_eq(_screen._player_icon.texture, knight.basic_attack.icon)
	assert_eq(_screen._skill_names[0].text, knight.skill_q.display_name)
	assert_eq(_screen._skill_names[2].text, knight.skill_r.display_name)
	assert_eq(_screen._skill_cooldowns[0].text, "Recarga 8 s")
	assert_eq(_screen._skill_cooldowns[2].text, "Recarga 50 s")


func test_atributos_comparaveis_entre_os_herois() -> void:
	var hp := _screen._stat_bars[0]
	var best := maxf(ROSTER[0].base_hp, ROSTER[1].base_hp)
	assert_eq(hp.max_value, best)
	assert_eq(hp.value, ROSTER[0].base_hp)
	assert_eq(_screen._stat_values[0].text, "%d / %d" % [ROSTER[0].base_hp, best])
	var atk := maxf(ROSTER[0].base_attack, ROSTER[1].base_attack)
	assert_eq(_screen._stat_values[2].text, "%d / %d" % [ROSTER[0].base_attack, atk])


func test_espaco_confirma_e_o_servidor_registra() -> void:
	var space := InputEventAction.new()
	space.action = &"ui_accept"
	space.pressed = true
	_screen._unhandled_input(space)
	assert_eq(_my_hero(), &"knight")
	assert_string_contains(_screen._status.text, "PRONTO")
	assert_eq(_screen._you_status.text, "Status: Pronto")
	assert_true(_screen._lock_in.disabled)
	assert_true(_screen._player_locked.visible)
	_screen.lock_in()
	assert_eq(_match.state, MatchState.State.HERO_PICK, "segundo lock-in nao muda nada")


func test_oponente_escolhendo_ate_o_servidor_confirmar() -> void:
	assert_eq(_screen._enemy_state.text, "ESCOLHENDO...")
	assert_true(_screen._enemy_unknown.visible)
	assert_false(_screen._enemy_role_tag.visible)
	assert_false(_screen._enemy_locked.visible)
	assert_eq(_screen._rival_status.text, "Status: Escolhendo...")


func test_pick_do_adversario_aparece_no_card_dele() -> void:
	_match.submit_pick(RIVAL, &"knight", START)
	assert_eq(_screen._enemy_name.text, "CAVALEIRO")
	assert_eq(_screen._enemy_role.text, "TANQUE")
	assert_eq(_screen._enemy_state.text, "PRONTO PARA COMBATE")
	assert_true(_screen._enemy_locked.visible)
	assert_false(_screen._enemy_unknown.visible)
	assert_eq(_screen._rival_status.text, "Status: Pronto")
	assert_eq(_screen._player_name.text, "CAVALEIRO", "meu card nao muda")


func test_timeout_mostra_o_heroi_padrao_como_meu() -> void:
	_match.update(START + 24 * RATE)
	assert_eq(_match.state, MatchState.State.INTRO)
	assert_eq(_screen._player_name.text, "CAVALEIRO")
	assert_true(_screen._lock_in.disabled)


func test_close_esconde() -> void:
	_screen.close()
	assert_false(_screen.visible)


## #228: com os 11 herois (F98) a tela inteira cabe na base do projeto (1920x1080, canvas_items): o
## minimo do conteudo nao passa da base, senao o stretch nao salva e o topo e o rodape somem.
## Montada numa SubViewport do tamanho da base: o minimo depende da largura (os textos quebram em
## linhas).
func test_onze_herois_cabem_na_base_do_projeto() -> void:
	var base := Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	var viewport := SubViewport.new()
	viewport.size = base
	add_child_autofree(viewport)
	var screen := (load(SCENE) as PackedScene).instantiate() as HeroSelect
	viewport.add_child(screen)
	screen.bind(_match, FULL_ROSTER, ALL_SCENES)
	screen.open(24.0)
	await wait_process_frames(2)
	var need := (screen.get_node("Root/Column") as Control).get_combined_minimum_size()
	assert_lte(need.y, float(base.y), "altura minima %s da base %s" % [need.y, base.y])
	assert_lte(need.x, float(base.x), "largura minima %s da base %s" % [need.x, base.x])


func test_onze_herois_com_cena_e_tecla_4_escolhe_o_bruxo() -> void:
	var screen := _make_screen(FULL_ROSTER, ALL_SCENES)
	assert_eq(screen._choices.get_child_count(), 11)
	_press(screen, KEY_4)
	assert_eq(screen._player_name.text, "BRUXO DE FOGO")
	assert_eq(screen._player_role.text, "MAGO")
	assert_true(screen._cards[3]._tag.visible)
	assert_false(screen._cards[0]._tag.visible)


func test_tecla_0_escolhe_o_paladino() -> void:
	var screen := _make_screen(FULL_ROSTER, ALL_SCENES)
	_press(screen, KEY_0)
	assert_eq(screen._player_name.text, "PALADINO RADIANTE")
	assert_eq(screen._player_role.text, "TANQUE")


func test_tecla_menos_escolhe_o_carrasco() -> void:
	var screen := _make_screen(FULL_ROSTER, ALL_SCENES)
	_press(screen, KEY_MINUS)
	assert_eq(screen._player_name.text, "CARRASCO")
	assert_eq(screen._player_role.text, "TANQUE")
	assert_true(screen._cards[10]._tag.visible)


func test_tecla_5_escolhe_a_ladina() -> void:
	var screen := _make_screen(FULL_ROSTER, ALL_SCENES)
	_press(screen, KEY_5)
	assert_eq(screen._player_name.text, "LADINA")
	assert_eq(screen._player_role.text, "ALGOZ")
	assert_true(screen._cards[4]._tag.visible)


func test_tecla_6_escolhe_o_engenheiro_com_os_dados_reais() -> void:
	var screen := _make_screen(FULL_ROSTER, ALL_SCENES)
	_press(screen, KEY_6)
	assert_eq(screen._player_name.text, "ENGENHEIRO")
	assert_eq(screen._player_role.text, "ENGENHEIRO")
	assert_true(screen._cards[5]._tag.visible)
	assert_false(screen._cards[4]._tag.visible)


func test_tecla_7_escolhe_o_protetor_da_selva_com_os_dados_reais() -> void:
	var screen := _make_screen(FULL_ROSTER, ALL_SCENES)
	_press(screen, KEY_7)
	assert_eq(screen._player_name.text, "PROTETOR DA SELVA")
	assert_eq(screen._player_role.text, "CONTROLE")
	assert_true(screen._cards[6]._tag.visible)
	assert_false(screen._cards[5]._tag.visible)


func test_tecla_8_escolhe_o_berserker_com_os_dados_reais() -> void:
	var screen := _make_screen(FULL_ROSTER, ALL_SCENES)
	_press(screen, KEY_8)
	assert_eq(screen._player_name.text, "BERSERKER")
	assert_eq(screen._player_role.text, "LUTADOR")
	assert_true(screen._cards[7]._tag.visible)
	assert_false(screen._cards[6]._tag.visible)


func test_tecla_9_escolhe_o_ocultista_com_os_dados_reais() -> void:
	var screen := _make_screen(FULL_ROSTER, ALL_SCENES)
	_press(screen, KEY_9)
	assert_eq(screen._player_name.text, "OCULTISTA")
	assert_eq(screen._player_role.text, "MAGO")
	assert_true(screen._cards[8]._tag.visible)
	assert_false(screen._cards[7]._tag.visible)


func test_retrato_enquadra_o_corpo_maior_do_berserker_com_o_idle_dele() -> void:
	var knight := HeroSelect.model_of(&"knight")
	var berserker := HeroSelect.model_of(&"berserker")
	autofree(knight)
	autofree(berserker)
	assert_eq(knight.get_meta(&"portrait_height"), 0.0, "altura padrao do card")
	assert_gt(berserker.get_meta(&"portrait_height") as float, 1.9, "Barbarian_Large e mais alto")
	assert_eq(berserker.get_meta(&"idle"), &"Idle_A")


func test_modelo_so_do_heroi_com_cena() -> void:
	var model := HeroSelect.model_of(&"knight")
	assert_not_null(model)
	assert_false(model.is_in_group(Hero.GROUP))
	model.free()
	var ranger := HeroSelect.model_of(&"ranger")  # cena da Arqueira desde o F14
	assert_not_null(ranger)
	ranger.free()
	assert_null(HeroSelect.model_of(&"mage"))


func test_carrasco_traz_a_faixa_e_o_giro_do_card() -> void:
	# F98: o Carrasco, realista e esguio, mostra da cintura para cima e girado no card. Faixa e altura
	# ja na escala 1,2 do modelo na cena do heroi.
	var model := HeroSelect.model_of(&"carrasco")
	autofree(model)
	assert_eq(model.get_meta(&"portrait_band"), Vector2(1.18, 2.14))
	assert_almost_eq(
		float(model.get_meta(&"portrait_height")), 2.16, 0.001, "corpo inteiro no grande"
	)
	# Pose de descanso (escudo ao lado, PI 2026-10-22): de frente no card, sem o giro do F98.
	assert_almost_eq(float(model.get_meta(&"portrait_turn")), 0.0, 0.001)
	# PI 2026-10-22: na selecao, pose de descanso (o Idle dele e guarda de combate).
	assert_eq(model.get_meta(&"idle"), &"Portrait")
	var player := model.find_child("AnimationPlayer") as AnimationPlayer
	assert_true(player.has_animation(&"Portrait"), "clipe exportado no carrasco.glb")
	var knight := HeroSelect.model_of(&"knight")
	autofree(knight)
	assert_eq(knight.get_meta(&"portrait_band"), Vector2.ZERO, "KayKit: enquadramento comum")


## Destaque sem lock-in (PI 2026-10-22): a tela avisa o servidor do heroi mostrado.
func test_heroi_mostrado_vira_o_destaque_no_servidor() -> void:
	for seat: MatchController.Seat in _match.seats():
		if seat.peer == multiplayer.get_unique_id():
			assert_eq(seat.shown, &"knight", "o aberto ja conta")
