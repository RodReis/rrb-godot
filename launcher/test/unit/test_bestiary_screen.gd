extends GutTest
## F27: tela Bestiario (FRONTEND-LAUNCHER §3, §6, §8): estados do StateBox, um card por especie
## com o chefe largo, filtros por tier e busca, numeros so de shared/data (nenhum do prototipo),
## abas do compendio por sinal e o card que ergue com o mouse.

const SCENE: PackedScene = preload("res://scenes/screens/bestiary.tscn")
const SPECIES: int = 6
## Numeros de exemplo do prototipo "Guia & Bestiario" que o GDB nao confirma (§8.3 regra 2).
const PROTOTYPE_NUMBERS: Array[String] = ["220", "450", "320", "750", "1.800", "+65 XP", "+500"]

var _catalog: CatalogService
var _screen: BestiaryScreen


## Catalogo que nao carrega (arquivo ausente): a tela mostra o erro.
class BrokenCatalog:
	extends CatalogService

	func load_all() -> void:
		pass

	func is_loaded() -> bool:
		return false


func before_each() -> void:
	_catalog = CatalogService.new()
	_catalog.load_all()
	_screen = SCENE.instantiate() as BestiaryScreen
	_screen.bind(_catalog)
	add_child_autofree(_screen)
	await wait_process_frames(2)


func _texts(node: Node) -> PackedStringArray:
	var found := PackedStringArray()
	for child: Node in node.find_children("*", "Label", true, false):
		found.append((child as Label).text)
	for child: Node in node.find_children("*", "Button", true, false):
		found.append((child as Button).text)
	return found


func _names(cards: Array[MonsterCard]) -> PackedStringArray:
	var names := PackedStringArray()
	for card: MonsterCard in cards:
		names.append(card.species.lead().display_name)
	return names


func test_pronta_com_os_dados_carregados() -> void:
	assert_eq(_screen.state(), StateBox.State.READY)
	assert_eq(_screen.cards().size(), SPECIES)


func test_sem_catalogo_fica_ocioso_e_catalogo_quebrado_mostra_erro() -> void:
	var idle := SCENE.instantiate() as BestiaryScreen
	add_child_autofree(idle)
	await wait_process_frames(1)
	assert_eq(idle.state(), StateBox.State.IDLE)
	var broken := SCENE.instantiate() as BestiaryScreen
	broken.bind(BrokenCatalog.new())
	add_child_autofree(broken)
	await wait_process_frames(2)
	assert_eq(broken.state(), StateBox.State.ERROR)


func test_fita_de_contadores_vem_dos_dados() -> void:
	var cells := _screen.ribbon_texts()
	assert_eq(cells.size(), 3)
	assert_eq(cells[0][1], "06")
	assert_eq(cells[1][1], "21")
	assert_eq(cells[2][1], "03:30")


func test_nenhum_numero_de_exemplo_do_prototipo() -> void:
	var all := " | ".join(_texts(_screen))
	for number: String in PROTOTYPE_NUMBERS:
		assert_false(all.contains(number), number)
	assert_string_contains(all, "Bestiário (6 monstros)")
	assert_string_contains(all, "Bestiário tático: 6 criaturas")


func test_card_mostra_os_numeros_do_catalogo() -> void:
	var card := _screen.cards()[0]
	var lead := card.species.lead()
	var all := " | ".join(_texts(card))
	assert_string_contains(all, CompendiumFormat.thousands(roundi(lead.hp)))
	assert_string_contains(all, "+%d XP" % lead.xp)
	assert_string_contains(all, CompendiumFormat.drop_text(lead))


func test_golem_junta_a_variante_de_canto() -> void:
	var golem: MonsterCard = null
	for card: MonsterCard in _screen.cards():
		if card.species.id == &"golem_t3":
			golem = card
	assert_not_null(golem)
	var all := " | ".join(_texts(golem))
	assert_string_contains(all, "4 por partida")
	assert_string_contains(all, "Golem de Pedra (canto)")


func test_chefe_e_o_ultimo_e_tem_card_largo() -> void:
	var boss: MonsterCard = _screen.cards().back()
	assert_eq(boss.species.lead().tier, MonsterData.Tier.BOSS)
	assert_string_contains(" | ".join(_texts(boss)), "SURGE ÀS 03:30")


func test_filtro_por_tier() -> void:
	_screen.select_filter(BestiaryScreen.TierFilter.T2)
	assert_eq(
		_names(_screen.visible_cards()),
		PackedStringArray(["Esqueleto Mago", "Esqueleto Guerreiro", "Lobo"])
	)
	_screen.select_filter(BestiaryScreen.TierFilter.BOSS)
	assert_eq(_names(_screen.visible_cards()), PackedStringArray(["Rei Esqueleto"]))
	_screen.select_filter(BestiaryScreen.TierFilter.T3)
	assert_eq(_names(_screen.visible_cards()), PackedStringArray(["Golem de Pedra"]))
	_screen.select_filter(BestiaryScreen.TierFilter.ALL)
	assert_eq(_screen.visible_cards().size(), SPECIES)


func test_busca_por_nome_inclusive_da_variante() -> void:
	_screen.search_field().text = "canto"
	_screen.search_field().text_changed.emit("canto")
	assert_eq(_names(_screen.visible_cards()), PackedStringArray(["Golem de Pedra"]))
	_screen.search_field().text = "rei esqueleto"
	_screen.search_field().text_changed.emit("rei esqueleto")
	assert_eq(_names(_screen.visible_cards()), PackedStringArray(["Rei Esqueleto"]))


func test_busca_sem_resultado_mostra_aviso() -> void:
	_screen.search_field().text = "zzz"
	_screen.search_field().text_changed.emit("zzz")
	assert_eq(_screen.visible_cards().size(), 0)
	assert_true(_screen.no_match_visible())
	_screen.search_field().text = ""
	_screen.search_field().text_changed.emit("")
	assert_false(_screen.no_match_visible())


func test_filtro_e_busca_se_combinam() -> void:
	_screen.select_filter(BestiaryScreen.TierFilter.T2)
	_screen.search_field().text = "lobo"
	_screen.search_field().text_changed.emit("lobo")
	assert_eq(_names(_screen.visible_cards()), PackedStringArray(["Lobo"]))


func test_aba_da_forja_pede_a_rota_e_a_propria_aba_nao() -> void:
	watch_signals(_screen)
	_screen.tab_chip(CompendiumScreen.Tab.BESTIARY).pressed.emit()
	assert_signal_not_emitted(_screen, "navigate_requested")
	_screen.tab_chip(CompendiumScreen.Tab.FORGE).pressed.emit()
	assert_signal_emitted_with_parameters(_screen, "navigate_requested", [Router.FORGE])


func test_primeiro_foco_na_aba_da_tela() -> void:
	await wait_process_frames(2)
	assert_true(_screen.tab_chip(CompendiumScreen.Tab.BESTIARY).has_focus())


func test_aba_ativa_e_a_do_bestiario() -> void:
	assert_true(_screen.tab_chip(CompendiumScreen.Tab.BESTIARY).button_pressed)
	assert_false(_screen.tab_chip(CompendiumScreen.Tab.FORGE).button_pressed)


func test_card_ergue_com_o_mouse_e_desce_ao_sair() -> void:
	var frame := _screen.cards()[0].get_parent() as LiftFrame
	assert_false(frame.is_lifted())
	frame.card().mouse_entered.emit()
	await wait_seconds(UiTokens.DUR_BASE + 0.1)
	assert_true(frame.is_lifted())
	frame.card().mouse_exited.emit()
	await wait_seconds(UiTokens.DUR_BASE + 0.1)
	assert_false(frame.is_lifted())


func test_card_nao_rouba_a_roda_do_mouse() -> void:
	var card := _screen.cards()[0]
	assert_eq(card.mouse_filter, Control.MOUSE_FILTER_PASS, "a rolagem recebe a roda")
	for label: Node in card.find_children("*", "Label", true, false):
		assert_eq((label as Label).mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_voltar_so_com_pilha() -> void:
	assert_false(_screen.can_go_back)
	var back := _screen.find_children("*", "Button", true, false).filter(
		func(button: Node) -> bool: return (button as Button).text == UiIcons.ARROW_BACK
	)
	assert_eq(back.size(), 1)
	assert_false((back[0] as Button).visible)
	_screen.can_go_back = true
	assert_true((back[0] as Button).visible)
