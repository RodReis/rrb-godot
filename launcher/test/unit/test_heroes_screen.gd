extends GutTest
## F71: tela Heróis (FRONTEND-LAUNCHER §3, §6, §8): estados do StateBox, um card por herói, troca de
## herói no painel, filtro por classe e busca, foco por teclado e todo texto vindo de shared/data
## (nenhum número do protótipo).

const SCENE: PackedScene = preload("res://scenes/screens/heroes.tscn")
const HEROES: int = 8
## Números e textos de exemplo do protótipo "Tela Herois" que o GDB não confirma (§8.3 regras 1-2).
const PROTOTYPE_TEXTS: Array[String] = [
	"1480",
	"24ms",
	"ELO",
	"NÍVEL 12",
	"DOS VENTOS",
	"Duelista_01",
	"10/10",
	"30 FPS",
	"88 Físico",
	"92 / 100",
	"TESTAR NO TREINO",
	"SKINS",
	"TEMPORADA",
	"ARQUEIRA",
	"Arqueira",
]

var _catalog: CatalogService
var _screen: HeroesScreen


## Catálogo que não carrega (arquivo ausente): a tela mostra o erro.
class BrokenCatalog:
	extends CatalogService

	func load_all() -> void:
		pass

	func is_loaded() -> bool:
		return false


## Catálogo que guarda o estado da tela enquanto carrega.
class SpyCatalog:
	extends CatalogService
	var screen: HeroesScreen
	var state_while_loading: StateBox.State = StateBox.State.IDLE

	func load_all() -> void:
		state_while_loading = screen.state()
		super.load_all()


func before_each() -> void:
	_catalog = CatalogService.new()
	_catalog.load_all()
	_screen = SCENE.instantiate() as HeroesScreen
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


func _names(cards: Array[HeroCard]) -> PackedStringArray:
	var names := PackedStringArray()
	for card: HeroCard in cards:
		names.append(card.hero.display_name)
	return names


func _card_of(id: StringName) -> HeroCard:
	for card: HeroCard in _screen.cards():
		if card.hero.id == id:
			return card
	return null


func test_pronta_com_um_card_por_heroi_do_catalogo() -> void:
	assert_eq(_screen.state(), StateBox.State.READY)
	assert_eq(_screen.cards().size(), HEROES)
	assert_eq(_names(_screen.cards()), _names_of_catalog())


func _names_of_catalog() -> PackedStringArray:
	var names := PackedStringArray()
	for hero: HeroData in _catalog.heroes:
		names.append(hero.display_name)
	return names


func test_sem_catalogo_fica_ocioso_e_catalogo_quebrado_mostra_erro_e_tenta_de_novo() -> void:
	var idle := SCENE.instantiate() as HeroesScreen
	add_child_autofree(idle)
	await wait_process_frames(1)
	assert_eq(idle.state(), StateBox.State.IDLE)
	var broken := SCENE.instantiate() as HeroesScreen
	broken.bind(BrokenCatalog.new())
	add_child_autofree(broken)
	await wait_process_frames(2)
	assert_eq(broken.state(), StateBox.State.ERROR)
	broken.bind(_catalog)
	await wait_process_frames(2)
	assert_eq(broken.state(), StateBox.State.READY, "Tentar de novo com o catálogo bom")


func test_mostra_carregando_enquanto_le_o_catalogo_e_termina_pronta() -> void:
	var spy := SpyCatalog.new()
	var screen := SCENE.instantiate() as HeroesScreen
	spy.screen = screen
	add_child_autofree(screen)
	await wait_process_frames(1)
	screen.bind(spy)
	assert_eq(spy.state_while_loading, StateBox.State.LOADING)
	assert_eq(screen.state(), StateBox.State.READY)


func test_comeca_com_o_primeiro_heroi_selecionado_e_o_painel_mostra_ele() -> void:
	var first := _catalog.heroes[0]
	assert_eq(_screen.selected_hero(), first)
	assert_true(_screen.cards()[0].button_pressed)
	assert_true(_screen.cards()[0].is_selected_tag_visible())
	assert_eq(_screen.detail().hero, first)
	assert_true(_texts(_screen.detail()).has(first.display_name))


func test_trocar_de_heroi_troca_o_painel_e_so_um_card_fica_marcado() -> void:
	var ranger := _card_of(&"ranger")
	ranger.pressed.emit()
	await wait_process_frames(1)
	assert_eq(_screen.selected_hero().id, &"ranger")
	assert_eq(_screen.detail().hero.id, &"ranger")
	var marked := 0
	for card: HeroCard in _screen.cards():
		marked += int(card.button_pressed)
	assert_eq(marked, 1)
	assert_true(_texts(_screen.detail()).has("Flecha Perfurante"))
	assert_false(_texts(_screen.detail()).has("Investida"), "habilidade do Cavaleiro some")


func test_painel_mostra_classe_papel_arma_atributos_e_as_4_habilidades_com_descricao() -> void:
	var hero := _catalog.hero(&"knight")
	_screen.select_hero(&"knight")
	var texts := _texts(_screen.detail())
	assert_true(texts.has(hero.summary), "papel curto")
	assert_true(texts.has(hero.weapon_name), "arma")
	assert_true(texts.has("%s u" % CompendiumFormat.decimal(hero.basic_attack.attack_range)))
	assert_true(texts.has("600 → 1.005"), "vida nv 1 → nv 10: %s" % str(texts))
	assert_true(texts.has("30 → 57"), "defesa nv 1 → nv 10")
	for slot: HeroesFormat.SkillSlot in HeroesFormat.skill_slots(hero):
		assert_true(texts.has(slot.skill.display_name), slot.skill.display_name)
		assert_true(texts.has(slot.skill.description), "descrição de %s" % slot.skill.id)
		assert_true(texts.has(slot.key), "tecla %s" % slot.key)


func test_todo_texto_vem_do_catalogo_trocar_o_tres_muda_a_tela() -> void:
	var hero := _catalog.hero(&"ranger")
	var original_name := hero.display_name
	var original_weapon := hero.weapon_name
	var original_skill_name := hero.skill_q.display_name
	var original_description := hero.skill_q.description
	hero.display_name = "Nome Trocado"
	hero.weapon_name = "Arma Trocada"
	hero.skill_q.display_name = "Habilidade Trocada"
	hero.skill_q.description = "Descrição trocada."
	var screen := SCENE.instantiate() as HeroesScreen
	screen.bind(_catalog)
	add_child_autofree(screen)
	await wait_process_frames(2)
	screen.select_hero(&"ranger")
	var texts := _texts(screen)
	for expected: String in ["Arma Trocada", "Habilidade Trocada", "Descrição trocada."]:
		assert_true(texts.has(expected), expected)
	assert_true(_names(screen.cards()).has("Nome Trocado"))
	assert_false(texts.has("Arco"), "o texto antigo não fica")
	# Resource em cache: devolve o valor original para os outros testes.
	hero.display_name = original_name
	hero.weapon_name = original_weapon
	hero.skill_q.display_name = original_skill_name
	hero.skill_q.description = original_description


func test_roda_do_mouse_passa_pelo_painel_mesmo_depois_de_trocar_de_heroi() -> void:
	_screen.select_hero(&"ranger")
	for node: Node in _screen.detail().find_children("*", "Control", true, false):
		assert_ne((node as Control).mouse_filter, Control.MOUSE_FILTER_STOP, str(node.get_path()))


func test_nenhum_numero_ou_texto_de_exemplo_do_prototipo() -> void:
	var all := " | ".join(_texts(_screen))
	for text: String in PROTOTYPE_TEXTS:
		assert_false(all.contains(text), text)
	assert_string_contains(all, "Arqueiro")


func test_fita_de_contadores_vem_dos_dados() -> void:
	var cells := _screen.ribbon_texts()
	assert_eq(cells[1], "08")


func test_filtro_de_classe_mostra_so_a_classe_e_a_contagem_vem_dos_dados() -> void:
	assert_eq(_screen.role_chip("").count_text(), "8")
	assert_eq(_screen.role_chip("Algoz").count_text(), "2")
	_screen.select_role("Algoz")
	assert_eq(_names(_screen.visible_cards()), PackedStringArray(["Bárbaro", "Ladina"]))
	assert_eq(_screen.selected_hero().role, "Algoz", "o painel acompanha o primeiro que sobrou")
	_screen.select_role("")
	assert_eq(_screen.visible_cards().size(), HEROES)


func test_busca_por_nome_classe_ou_arma_e_sem_resultado() -> void:
	_screen.search_field().text = "besta"
	_screen.search_field().text_changed.emit("besta")
	assert_eq(_names(_screen.visible_cards()), PackedStringArray(["Ladina"]))
	_screen.search_field().text = "mago"
	_screen.search_field().text_changed.emit("mago")
	assert_eq(_names(_screen.visible_cards()), PackedStringArray(["Bruxo de Fogo"]))
	_screen.search_field().text = "zzz"
	_screen.search_field().text_changed.emit("zzz")
	assert_true(_screen.no_match_visible())
	assert_eq(_screen.visible_cards().size(), 0)


func test_foco_de_teclado_comeca_no_heroi_selecionado_e_o_card_focado_escolhe() -> void:
	await wait_process_frames(2)
	assert_true(_screen.cards()[0].has_focus(), "primeiro foco no herói selecionado")
	for card: HeroCard in _screen.cards():
		assert_eq(card.focus_mode, Control.FOCUS_ALL, card.hero.id)
	var ranger := _card_of(&"ranger")
	ranger.grab_focus()
	ranger.pressed.emit()
	assert_eq(_screen.selected_hero(), ranger.hero)


func test_botao_voltar_so_aparece_com_pilha_e_emite_back_requested() -> void:
	var back_buttons := func() -> Array:
		return _screen.find_children("*", "Button", true, false).filter(
			func(button: Node) -> bool:
				return (
					(button as Button).text == UiIcons.ARROW_BACK
					and (button as Button).is_visible_in_tree()
				)
		)
	assert_eq(back_buttons.call().size(), 0, "sem tela abaixo não há botão morto")
	_screen.can_go_back = true
	await wait_process_frames(1)
	assert_eq(back_buttons.call().size(), 1)
	watch_signals(_screen)
	(back_buttons.call()[0] as Button).pressed.emit()
	assert_signal_emitted(_screen, "back_requested")


func test_card_da_zoom_no_retrato_e_ergue_com_o_mouse() -> void:
	var card := _screen.cards()[1]
	var frame := card.get_parent() as LiftFrame
	card.mouse_entered.emit()
	await wait_seconds(0.45)
	assert_true(card.is_zoomed())
	assert_true(frame.is_lifted())
	card.mouse_exited.emit()
	await wait_seconds(0.45)
	assert_false(card.is_zoomed())
	assert_false(frame.is_lifted())
