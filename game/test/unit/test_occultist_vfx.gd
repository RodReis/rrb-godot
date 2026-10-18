extends GutTest
## F77 (SPEC-077 §VFX): efeitos do Ocultista pela borda do estado (clarao no cajado, corpo e rastro
## do projetil por tipo), pelo impacto confirmado (estouro roxo e verde), pelo evento do
## ImpactRelay (Circulo Profano) e as marcas de Maldicao e a Praga sobre qualquer alvo
## (CurseMarks). Aqui o processo e o host (peer 1).

const OCCULTIST: String = "res://scenes/heroes/occultist.tscn"
const OCCULTIST_VFX: PackedScene = preload("res://scenes/vfx/occultist_vfx.tscn")
const GOLEM: String = "res://scenes/monsters/golem_t3.tscn"
const FRAME: float = 1.0 / 60.0
const AIM: Vector3 = Vector3(0, 0, -1)

var _hero: Occultist
var _pool: VfxPool
var _driver: OccultistVfx


func _bind() -> void:
	_hero = (load(OCCULTIST) as PackedScene).instantiate() as Occultist
	_hero.name = "1"
	_hero.level = 6
	add_child_autofree(_hero)
	_pool = VfxPool.new()
	add_child_autofree(_pool)
	_driver = OCCULTIST_VFX.instantiate() as OccultistVfx
	add_child_autofree(_driver)
	_driver.bind(_hero, _pool)
	_frame()  # 1o valor visto nao e borda


func _frame() -> void:
	_driver._process(FRAME)


func _effects() -> int:
	return _pool.get_child_count()


func _last_effect() -> Node:
	return _pool.get_child(_effects() - 1)


func _now() -> int:
	return NetworkTime.tick


func _body(arrow: Arrow, body_name: String) -> Node3D:
	return arrow.find_child(body_name, false, false) as Node3D


func test_basico_e_q_soltam_um_clarao_cada() -> void:
	_bind()
	_hero.basic_cooldown = 30
	_frame()
	assert_eq(_effects(), 1)
	_hero.q_cooldown = 300
	_frame()
	assert_eq(_effects(), 2)


func test_so_um_clarao_por_disparo() -> void:
	_bind()
	_hero.basic_cooldown = 30
	_frame()
	_hero.basic_cooldown = 29
	_frame()
	assert_eq(_effects(), 1)


func test_corpo_e_rastro_do_projetil_seguem_o_tipo() -> void:
	_bind()
	var arrow := _hero.get_node("Arrows/Arrow0") as Arrow
	arrow.launch(Arrow.Kind.SHADOW, Vector3(0, 1, 0), AIM, 7.5, 40)
	arrow._process(FRAME)
	_frame()
	assert_true(_body(arrow, "ShadowBody").visible)
	assert_false(_body(arrow, "PlagueBody").visible)
	assert_true(_driver._shadow_trails[0].emitting)
	assert_false(_driver._plague_trails[0].emitting)
	arrow.launch(Arrow.Kind.PLAGUE, Vector3(0, 1, 0), AIM, 8.0, 60)
	arrow._process(FRAME)
	_frame()
	assert_false(_body(arrow, "ShadowBody").visible)
	assert_true(_body(arrow, "PlagueBody").visible)
	assert_false(_driver._shadow_trails[0].emitting)
	assert_true(_driver._plague_trails[0].emitting)


func test_corpo_provisorio_da_cena_do_heroi_fica_oculto() -> void:
	_bind()
	var arrow := _hero.get_node("Arrows/Arrow0") as Arrow
	arrow.launch(Arrow.Kind.SHADOW, Vector3(0, 1, 0), AIM, 7.5, 40)
	_frame()
	for node: Node in arrow.get_children():
		if node is MeshInstance3D and node.name != &"ShadowBody" and node.name != &"PlagueBody":
			assert_false((node as MeshInstance3D).visible, "%s" % node.name)


func test_cada_projetil_do_pool_ganha_seus_corpos_e_rastros() -> void:
	_bind()
	var arrows := _hero.get_node("Arrows").get_child_count()
	assert_eq(_driver._shadow_trails.size(), arrows)
	assert_eq(_driver._plague_bodies.size(), arrows)
	assert_ne(_driver._shadow_trails[0], _driver._shadow_trails[arrows - 1])


func test_impacto_do_basico_e_da_praga_soltam_um_estouro_cada() -> void:
	_bind()
	_driver.impact(HitLedger.Slot.BASIC, Vector3(0, 0, -3))
	assert_eq(_effects(), 1)
	_driver.impact(HitLedger.Slot.Q, Vector3(0, 0, -3))
	assert_eq(_effects(), 2)
	assert_almost_eq(_last_effect().global_position.y, OccultistVfx.STRIKE_HEIGHT, 0.001)


func test_pulso_do_circulo_solta_estouro_menor_e_o_r_nada() -> void:
	_bind()
	_driver.impact(HitLedger.Slot.E, Vector3(0, 0, -3))
	assert_eq(_effects(), 1)
	assert_almost_eq((_last_effect() as Node3D).scale.x, OccultistVfx.PULSE_BURST, 0.001)
	_driver.impact(HitLedger.Slot.R, Vector3(0, 0, -3))
	assert_eq(_effects(), 1)


func test_circulo_nasce_no_ponto_com_raio_e_tempo_do_e() -> void:
	_bind()
	var center := Vector3(2, 0, -5)
	_driver.zone(Occultist.Zone.CIRCLE, center, _now())
	assert_eq(_effects(), 1)
	var circle := _last_effect() as ProfaneCircleVfx
	assert_not_null(circle)
	assert_almost_eq(circle.global_position, center, Vector3.ONE * 0.001)
	assert_almost_eq(circle.lifetime, 3.0, 0.001)
	assert_almost_eq((circle.get_node("Ring") as Node3D).scale.x, 2.5, 0.001, "raio de 2,5 u")
	assert_almost_eq((circle.get_node("Glyph") as Node3D).scale.x, 2.5, 0.001)


func test_circulo_atrasado_mostra_o_que_falta_e_o_acabado_nao_aparece() -> void:
	_bind()
	_driver.zone(Occultist.Zone.CIRCLE, Vector3.ZERO, _now() - NetworkTime.tickrate)
	assert_almost_eq((_last_effect() as ProfaneCircleVfx).lifetime, 2.0, 0.05)
	_driver.zone(Occultist.Zone.CIRCLE, Vector3.ZERO, _now() - 4 * NetworkTime.tickrate)
	assert_eq(_effects(), 1, "o de 4 s atras ja acabou")


func test_circulo_gira_o_glifo_e_acaba() -> void:
	_bind()
	_driver.zone(Occultist.Zone.CIRCLE, Vector3.ZERO, _now())
	var circle := _last_effect() as ProfaneCircleVfx
	var glyph := circle.get_node("Glyph") as Node3D
	var before := glyph.rotation.y
	circle._process(0.5)
	assert_ne(glyph.rotation.y, before)
	for i: int in 240:  # 4 s a 60 quadros
		circle._process(FRAME)
	assert_false(circle.visible, "acabou")


func test_spawner_tem_o_efeito_do_ocultista_e_as_marcas() -> void:
	var players := Node.new()
	add_child_autofree(players)
	var relay := ImpactRelay.new()
	relay.players = players
	add_child_autofree(relay)
	var spawner := VfxSpawner.new()
	spawner.players = players
	spawner.relay = relay
	add_child_autofree(spawner)
	assert_true(VfxSpawner.DRIVERS.has(&"occultist"))
	assert_not_null(spawner.get_node_or_null("Curses"), "marcas e Praga vivem no spawner")


# --- Marcas de Maldicao e Praga sobre o alvo (CurseMarks) ---


func _marks() -> CurseMarks:
	var marks := CurseMarks.new()
	add_child_autofree(marks)
	return marks


func _indicator(marks: CurseMarks) -> CurseIndicator:
	for child: Node in marks.get_children():
		if child is CurseIndicator:
			return child as CurseIndicator
	return null


func _visible_marks(indicator: CurseIndicator) -> int:
	var count := 0
	for mark: Node3D in indicator._marks:
		count += int(mark.visible)
	return count


func test_sem_marca_nem_praga_nao_cria_indicador() -> void:
	_bind()
	var marks := _marks()
	marks._process(FRAME)
	assert_null(_indicator(marks))


func test_marcas_do_heroi_aparecem_de_1_a_3_e_somem_juntas() -> void:
	_bind()
	var marks := _marks()
	for stacks: int in [1, 2, 3]:
		_hero.curse_stacks = stacks
		marks._process(FRAME)
		var indicator := _indicator(marks)
		assert_not_null(indicator)
		assert_eq(_visible_marks(indicator), stacks)
		indicator._process(FRAME)
	_hero.curse_stacks = 0
	marks._process(FRAME)
	var idle := _indicator(marks)
	assert_eq(_visible_marks(idle), 0)
	assert_false(idle.visible, "ocioso: oculto")
	assert_false(idle.is_processing(), "ocioso: sem _process")


func test_marcas_ficam_acima_da_barra_e_centradas() -> void:
	_bind()
	var marks := _marks()
	_hero.curse_stacks = 3
	marks._process(FRAME)
	var indicator := _indicator(marks)
	indicator._process(FRAME)
	var floor_y := _hero.hp_bar.position.y + CurseIndicator.MARK_LIFT - CurseIndicator.BOB_HEIGHT
	var xs := 0.0
	for mark: Node3D in indicator._marks:
		assert_gt(mark.position.y, floor_y - 0.001)
		xs += mark.position.x
	assert_almost_eq(xs, 0.0, 0.001, "fileira centrada")


func test_monstro_tambem_mostra_marcas_e_praga() -> void:
	_bind()
	var golem := (load(GOLEM) as PackedScene).instantiate() as Monster
	golem.uid = -2
	golem.position = Vector3(0, 0, -3)
	add_child_autofree(golem)
	# O monstro nasce sem dono: so a visao o mostra.
	golem._concealment._shown[multiplayer.get_unique_id()] = true
	var marks := _marks()
	golem.curse_stacks = 2
	golem.dot_ticks = 90
	marks._process(FRAME)
	var indicator := _indicator(marks)
	assert_not_null(indicator)
	assert_eq(_visible_marks(indicator), 2)
	assert_true(indicator._mist.emitting, "Praga ativa")
	assert_almost_eq(indicator.global_position, golem.global_position, Vector3.ONE * 0.001)
	golem.dot_ticks = 0
	marks._process(FRAME)
	assert_false(indicator._mist.emitting)


func test_alvo_morto_nao_mostra() -> void:
	_bind()
	var marks := _marks()
	_hero.curse_stacks = 3
	_hero.dot_ticks = 10
	marks._process(FRAME)
	var indicator := _indicator(marks)
	assert_eq(_visible_marks(indicator), 3)
	_hero.hp = 0
	marks._process(FRAME)
	assert_eq(_visible_marks(indicator), 0)
	assert_false(indicator._mist.emitting)


func test_marca_nova_infla_a_runa_e_assenta() -> void:
	_bind()
	var marks := _marks()
	_hero.curse_stacks = 1
	marks._process(FRAME)
	var indicator := _indicator(marks)
	indicator._process(FRAME)
	var inflated := indicator._marks[0].scale.x
	indicator._process(CurseIndicator.POP_SECONDS)
	assert_gt(inflated, indicator._marks[0].scale.x)
	assert_almost_eq(indicator._marks[0].scale.x, CurseIndicator.MARK_SCALE, 0.001)


func test_alvo_que_sai_da_arvore_solta_o_indicador() -> void:
	_bind()
	var marks := _marks()
	_hero.curse_stacks = 1
	marks._process(FRAME)
	var indicator := _indicator(marks)
	assert_eq(marks._tracked.size(), 1)
	_hero.tree_exiting.emit()  # tirar o heroi da arvore em teste faz o netfox reclamar do disconnect
	assert_true(indicator.is_queued_for_deletion())
	assert_eq(marks._tracked.size(), 0)
