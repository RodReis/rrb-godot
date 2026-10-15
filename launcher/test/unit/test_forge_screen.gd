extends GutTest
## F27: tela Forja (FRONTEND-LAUNCHER §3, §6, §8): cards de regra, conjuntos, armas e filtros com
## busca, sem numero do prototipo; simulador = shared/core para o caso de referencia do GDB (I5).

const SCENE: PackedScene = preload("res://scenes/screens/forge.tscn")
const FIXTURE: String = "res://shared/test/fixtures/build_guard_full.tres"
const EPS: float = 0.0001
## Numeros e regras de exemplo do prototipo "Equipamentos & Forja" que mudaram ou nao existem.
const PROTOTYPE_TEXTS: Array[String] = [
	"12 ITENS", "0.5s", "0,5 s", "Recomendado para", "1397", "1150", "105 Def"
]

var _catalog: CatalogService
var _screen: ForgeScreen
var _sim: ForgeSimulator


func before_each() -> void:
	_catalog = CatalogService.new()
	_catalog.load_all()
	_screen = SCENE.instantiate() as ForgeScreen
	_screen.bind(_catalog)
	add_child_autofree(_screen)
	await wait_process_frames(2)
	_sim = _screen.simulator


func _texts(node: Node) -> PackedStringArray:
	var found := PackedStringArray()
	for child: Node in node.find_children("*", "Label", true, false):
		found.append((child as Label).text)
	for child: Node in node.find_children("*", "Button", true, false):
		found.append((child as Button).text)
	return found


func _equip_reference() -> void:
	var fixture := load(FIXTURE) as BuildFixture
	_sim.select_hero(fixture.hero.id)
	_sim.set_level(fixture.level)
	for item: ItemData in fixture.items:
		_sim.choose(item.slot, item)


func test_pronta_com_conjuntos_e_armas_do_catalogo() -> void:
	assert_eq(_screen.state(), StateBox.State.READY)
	assert_eq(_screen.set_panels().size(), 2)
	assert_eq(_screen.weapon_cards().size(), 3)


func test_fita_de_contadores_vem_dos_dados() -> void:
	var cells := _screen.ribbon_texts()
	assert_eq(cells[0][1], "21")
	assert_eq(cells[1][1], "02")
	assert_eq(cells[1][2], "3/3")
	assert_eq(cells[2][1], "03")


func test_nenhum_texto_de_exemplo_do_prototipo() -> void:
	var all := " | ".join(_texts(_screen))
	for text: String in PROTOTYPE_TEXTS:
		assert_false(all.contains(text), text)


func test_aba_ativa_e_a_da_forja_e_a_do_bestiario_navega() -> void:
	assert_true(_screen.tab_chip(CompendiumScreen.Tab.FORGE).button_pressed)
	watch_signals(_screen)
	_screen.tab_chip(CompendiumScreen.Tab.FORGE).pressed.emit()
	assert_signal_not_emitted(_screen, "navigate_requested")
	_screen.tab_chip(CompendiumScreen.Tab.BESTIARY).pressed.emit()
	assert_signal_emitted_with_parameters(_screen, "navigate_requested", [Router.BESTIARY])


func test_conjunto_mostra_efeito_e_pecas_do_catalogo() -> void:
	var guard := _screen.set_panels()[0]
	var all := " | ".join(_texts(guard)).to_upper()
	assert_string_contains(all, "+15% HP MÁXIMO · +10 DEF")
	assert_string_contains(all, "3/3 PEÇAS")
	assert_string_contains(all, "COMUM: +8 DEF")
	assert_string_contains(all, "ÉPICO: +220 HP, +22 DEF")
	assert_eq(guard.rows.size(), 3, "elmo, peitoral e botas")


func test_arma_epica_mostra_passiva_e_origem() -> void:
	var epic := _screen.weapon_cards()[2]
	var all := " | ".join(_texts(epic))
	assert_string_contains(all, "+45 ATQ")
	assert_string_contains(all, "Fúria")
	assert_string_contains(all, "Rei Esqueleto: 100% garantido")
	var common := " | ".join(_texts(_screen.weapon_cards()[0]))
	assert_string_contains(common, "Baús comuns (6 por base)")


func test_filtro_armas_esconde_conjuntos() -> void:
	_screen.select_filter(ForgeScreen.Section.WEAPONS)
	assert_eq(_screen.visible_set_panels().size(), 0)
	assert_eq(_screen.visible_weapon_cards().size(), 3)


func test_filtro_de_conjunto_mostra_so_ele_e_esconde_armas() -> void:
	_screen.select_filter(ForgeScreen.Section.SET, &"hunter")
	assert_eq(_screen.visible_set_panels().size(), 1)
	assert_eq(_screen.visible_set_panels()[0].bonus.set_id, &"hunter")
	assert_eq(_screen.visible_weapon_cards().size(), 0)
	_screen.select_filter(ForgeScreen.Section.ALL)
	assert_eq(_screen.visible_set_panels().size(), 2)
	assert_eq(_screen.visible_weapon_cards().size(), 3)


func test_busca_por_atributo() -> void:
	_screen.search_field().text = "fúria"
	_screen.search_field().text_changed.emit("fúria")
	assert_eq(_screen.visible_weapon_cards().size(), 1)
	assert_eq(_screen.visible_set_panels().size(), 0)
	_screen.search_field().text = "agi"
	_screen.search_field().text_changed.emit("agi")
	assert_eq(_screen.visible_set_panels().size(), 2, "botas e elmos com AGI nos dois conjuntos")


func test_busca_sem_resultado_mostra_aviso() -> void:
	_screen.search_field().text = "zzz"
	_screen.search_field().text_changed.emit("zzz")
	assert_true(_screen.no_match_visible())
	_screen.search_field().text = ""
	_screen.search_field().text_changed.emit("")
	assert_false(_screen.no_match_visible())


func test_simulador_comeca_no_cavaleiro_no_nivel_maximo() -> void:
	assert_eq(_sim.build.hero.id, &"knight")
	assert_eq(_sim.build.level, XpTable.max_level(_catalog.xp_curve))
	assert_eq(_sim.build.items().size(), 0)


func test_simulador_bate_com_shared_core_no_caso_de_referencia() -> void:
	_equip_reference()
	var fixture := load(FIXTURE) as BuildFixture
	var server := Stats.attributes(fixture.hero, fixture.level, fixture.items, _catalog.set_bonuses)
	assert_eq(_sim.hp_text(), CompendiumFormat.thousands(server.max_hp))
	assert_eq(_sim.hp_text(), "1.282")
	assert_eq(_sim.defense_text(), CompendiumFormat.decimal(server.defense))
	assert_eq(_sim.absorption_text(), CompendiumFormat.percent(server.mitigation))
	assert_eq(_sim.stat_text(&"attack"), "116,5")
	assert_almost_eq(_sim.build.attributes(_catalog.set_bonuses).attack, server.attack, EPS)


func test_bonus_de_conjunto_ativa_com_tres_pecas() -> void:
	_equip_reference()
	var lines := _sim.set_lines_text()
	assert_string_contains(lines[0], "Guarda 3/3")
	assert_string_contains(lines[0], "ATIVO")
	assert_string_contains(lines[1], "Caçador 0/3")
	assert_string_contains(lines[1], "inativo")
	_sim.choose(ItemData.Slot.CHEST, null)
	assert_string_contains(_sim.set_lines_text()[0], "inativo")
	assert_eq(_sim.hp_text(), "1.005", "sem o peitoral nem o bônus: só o HP do nível")


func test_escolher_o_mesmo_slot_troca_e_o_botao_acompanha() -> void:
	var low := _catalog.item(&"guard_helm_t1")
	var high := _catalog.item(&"guard_helm_t3")
	_sim.choose(ItemData.Slot.HELM, low)
	_sim.choose(ItemData.Slot.HELM, high)
	assert_eq(_sim.build.item_in(ItemData.Slot.HELM), high)
	var pressed := _sim.picker_buttons(ItemData.Slot.HELM).filter(
		func(button: Button) -> bool: return button.button_pressed
	)
	assert_eq(pressed.size(), 1)


func test_clicar_no_botao_escolhe_o_item() -> void:
	var buttons := _sim.picker_buttons(ItemData.Slot.WEAPON)
	assert_eq(buttons.size(), 4, "sem arma + 3 armas")
	(buttons[3] as Button).pressed.emit()
	assert_eq(_sim.build.item_in(ItemData.Slot.WEAPON).id, &"sword_t3_epic")
	(buttons[0] as Button).pressed.emit()
	assert_null(_sim.build.item_in(ItemData.Slot.WEAPON))


func test_trocar_de_heroi_muda_os_atributos_e_mantem_os_itens() -> void:
	var helm := _catalog.item(&"guard_helm_t2")
	_sim.choose(ItemData.Slot.HELM, helm)
	var knight_hp := _sim.hp_text()
	_sim.select_hero(&"ranger")
	assert_eq(_sim.build.hero.id, &"ranger")
	assert_eq(_sim.build.item_in(ItemData.Slot.HELM), helm)
	assert_ne(_sim.hp_text(), knight_hp)
	assert_true(_sim.hero_chip(&"ranger").button_pressed)


func test_nivel_respeita_os_limites() -> void:
	var max_level := XpTable.max_level(_catalog.xp_curve)
	var buttons := _sim.level_buttons()
	assert_true(buttons[1].disabled, "no máximo, + desliga")
	buttons[0].pressed.emit()
	assert_eq(_sim.build.level, max_level - 1)
	_sim.set_level(0)
	assert_eq(_sim.build.level, 1)
	assert_true(buttons[0].disabled, "no 1, − desliga")
	_sim.set_level(999)
	assert_eq(_sim.build.level, max_level)
	assert_eq(_sim.level_text(), str(max_level))


func test_formula_escrita_vem_de_stats() -> void:
	var all := " | ".join(_texts(_sim))
	var scale_text := CompendiumFormat.decimal(Stats.DEFENSE_SCALE)
	assert_string_contains(all, "dano × %s / (%s + DEF)" % [scale_text, scale_text])


func test_faixa_final_navega() -> void:
	watch_signals(_screen)
	var buttons := _screen.find_children("*", "Button", true, false).filter(
		func(button: Node) -> bool: return (button as Button).text.contains("LOBBY")
	)
	assert_eq(buttons.size(), 1)
	(buttons[0] as Button).pressed.emit()
	assert_signal_emitted_with_parameters(_screen, "navigate_requested", [Router.LOBBY])
	var bestiary := _screen.find_children("*", "Button", true, false).filter(
		func(button: Node) -> bool: return (button as Button).text.contains("GUIA DO BESTIÁRIO")
	)
	(bestiary[0] as Button).pressed.emit()
	assert_signal_emitted_with_parameters(_screen, "navigate_requested", [Router.BESTIARY])
