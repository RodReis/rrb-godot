extends GutTest
## F48 (SPEC-048 §4, §6 item 2): o HeroVisual mostra so as pecas dos slots equipados, troca quando
## o equipment muda e esconde a peca do pack que a peca nova substitui. O runner e headless, entao
## o visual dos itens e ligado a mao (no jogo, so quem desenha liga).

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RANGER: String = "res://scenes/heroes/ranger.tscn"
const BARBARIAN: String = "res://scenes/heroes/barbarian.tscn"
const WIZARD: String = "res://scenes/heroes/fire_wizard.tscn"
const ROGUE: String = "res://scenes/heroes/rogue.tscn"
const ENGINEER: String = "res://scenes/heroes/engineer.tscn"
const DRUID: String = "res://scenes/heroes/druid.tscn"
const BERSERKER: String = "res://scenes/heroes/berserker.tscn"
const OCCULTIST: String = "res://scenes/heroes/occultist.tscn"
const PALADIN: String = "res://scenes/heroes/paladin.tscn"
const FRAME: float = 1.0 / 60.0

var _hero: Hero
var _visual: HeroVisual


func _bind(scene: String, with_items: bool = true) -> void:
	_hero = (load(scene) as PackedScene).instantiate() as Hero
	_hero.name = "1"
	add_child_autofree(_hero)
	_visual = _hero.get_node("Visual") as HeroVisual
	if with_items:
		_visual.use_items(ItemVisuals.for_hero(_hero.hero_data.id))


func _equip(ids: Array[StringName]) -> void:
	var equipment := Inventory.NONE
	for id: StringName in ids:
		equipment = Inventory.equip(equipment, _hero.item_catalog.find(Ids.to_int(id)))
	_hero.equipment = equipment
	_visual._process(FRAME)


func _pieces(pattern: String = "*__*") -> Array[Node]:
	return _visual.model.find_children(pattern, "MeshInstance3D", true, false)


func _part(name: String) -> Node3D:
	return _visual.model.find_child(name) as Node3D


func test_sem_item_nao_tem_peca_e_o_pack_aparece() -> void:
	_bind(KNIGHT)
	_visual._process(FRAME)
	assert_eq(_pieces().size(), 0)
	assert_true(_part("Knight_Helmet").visible)
	assert_true(_part("1H_Sword").visible)


func test_mostra_so_os_slots_equipados() -> void:
	_bind(KNIGHT)
	_equip([&"guard_helm_t1", &"sword_t2"])
	assert_eq(_pieces("guard_helm_t1__*").size(), 1)
	assert_eq(_pieces("knight_sword_t2__*").size(), 1)
	assert_eq(_pieces().size(), 2, "peito e bota vazios")
	assert_false(_part("Knight_Helmet").visible, "elmo novo cobre o do pack")
	assert_false(_part("1H_Sword").visible, "arma nova troca a do pack")


func test_troca_e_tira_pecas_quando_o_equipment_muda() -> void:
	_bind(KNIGHT)
	_equip([&"guard_helm_t1", &"sword_t2"])
	_equip([&"hunter_helm_t3"])
	assert_eq(_pieces("guard_helm_t1__*").size(), 0)
	assert_eq(_pieces("hunter_helm_t3__*").size(), 1)
	assert_eq(_pieces("knight_sword_*").size(), 0)
	assert_true(_part("1H_Sword").visible, "sem arma volta a do pack")


func test_bota_prende_uma_peca_em_cada_osso_da_perna() -> void:
	_bind(RANGER)
	_equip([&"hunter_boots_t2"])
	var bones: Array[String] = []
	for piece: Node in _pieces():
		bones.append(String((piece.get_parent() as BoneAttachment3D).bone_name))
	bones.sort()
	assert_eq(bones, ["foot.l", "foot.r", "lowerleg.l", "lowerleg.r"] as Array[String])


func test_arma_da_arqueira_e_o_arco_dela() -> void:
	_bind(RANGER)
	_equip([&"sword_t3_epic"])
	assert_eq(_pieces("ranger_sword_t3_epic__handslot_l").size(), 1)
	assert_false(_part("bow_withString").visible)


func test_barbaro_usa_o_machado_e_nao_mostra_elmo() -> void:
	_bind(BARBARIAN)
	_equip([&"guard_helm_t3", &"guard_chest_t1", &"sword_t2"])
	assert_eq(_pieces("barbarian_sword_t2__handslot_r").size(), 1)
	assert_false(_part("2H_Axe").visible, "machado novo troca o do pack")
	assert_eq(_pieces("guard_helm_*").size(), 0, "capuz fica (ADR-0011 item 3)")
	assert_true(_part("Barbarian_Hat").visible)
	assert_eq(_pieces("guard_chest_t1__*").size(), 1)
	_hero._refresh_attributes()
	assert_eq(_hero.attributes.defense, 15.0 + 25.0 + 5.0, "o elmo vale sem aparecer")


func test_bruxo_usa_o_cajado_e_nao_mostra_elmo() -> void:
	_bind(WIZARD)
	_equip([&"hunter_helm_t3", &"hunter_chest_t2", &"hunter_boots_t1", &"sword_t3_epic"])
	assert_eq(_pieces("fire_wizard_sword_t3_epic__handslot_r").size(), 1)
	assert_false(_part("2H_Staff").visible, "cajado novo troca o do pack")
	assert_eq(_pieces("hunter_helm_*").size(), 0, "chapeu fica (SPEC-054 §4)")
	assert_true(_part("Mage_Hat").visible)
	assert_eq(_pieces("hunter_chest_t2__*").size(), 1)
	assert_eq(_pieces("hunter_boots_t1__*").size(), 4)
	_hero._refresh_attributes()
	assert_eq(_hero.attributes.attack, 45.0 + 15.0 + 12.0 + 45.0, "o elmo vale sem aparecer")


func test_ladina_usa_a_besta_e_nao_mostra_elmo() -> void:
	_bind(ROGUE)
	_equip([&"guard_helm_t2", &"guard_chest_t3", &"hunter_boots_t2", &"sword_t2"])
	assert_eq(_pieces("rogue_sword_t2__handslot_r").size(), 1)
	assert_false(_part("crossbow_1handed").visible, "besta nova troca a do pack")
	assert_true(_part("dagger").visible, "a faca fica sempre (SPEC-058 §4)")
	assert_eq(_pieces("guard_helm_*").size(), 0, "capuz fica (ADR-0013 item 7)")
	assert_true(_part("RogueHooded_Head").visible)
	assert_eq(_pieces("guard_chest_t3__*").size(), 1)
	assert_eq(_pieces("hunter_boots_t2__*").size(), 4)
	_hero._refresh_attributes()
	assert_eq(_hero.attributes.defense, 14.0 + 15.0 + 22.0, "o elmo vale sem aparecer")


func test_engenheiro_usa_o_bacamarte_peitoral_sem_costas_e_nao_mostra_elmo() -> void:
	_bind(ENGINEER)
	_equip([&"guard_helm_t2", &"guard_chest_t3", &"hunter_boots_t2", &"sword_t3_epic"])
	assert_eq(_pieces("engineer_sword_t3_epic__handslot_r").size(), 1)
	assert_false(_part("shotgun").visible, "bacamarte novo troca o do pack")
	assert_eq(_pieces("guard_helm_*").size(), 0, "cabelo e oculos ficam (ADR-0013 item 7)")
	assert_true(_part("Engineer_Goggles").visible)
	assert_true(_part("Engineer_Backpack").visible, "o peitoral nao esconde a mochila")
	assert_eq(_pieces("engineer_guard_chest_t3__*").size(), 1, "peitoral sem as costas")
	assert_eq(_pieces("hunter_boots_t2__*").size(), 4)
	_hero._refresh_attributes()
	assert_eq(_hero.attributes.defense, 22.0 + 15.0 + 22.0, "o elmo vale sem aparecer")


func test_peca_em_repouso_fica_no_espaco_do_modelo() -> void:
	_bind(KNIGHT)
	_equip([&"guard_chest_t2"])
	var skeleton := _visual.model.find_child("Skeleton3D") as Skeleton3D
	var piece := _pieces()[0] as MeshInstance3D
	var bone := skeleton.find_bone((piece.get_parent() as BoneAttachment3D).bone_name)
	# Com o osso na pose de repouso, o no volta a identidade relativa ao esqueleto.
	var at_rest := skeleton.get_bone_global_rest(bone) * piece.transform
	assert_true(at_rest.is_equal_approx(Transform3D.IDENTITY), str(at_rest))


func test_headless_nao_carrega_pecas() -> void:
	_bind(KNIGHT, false)
	assert_eq(DisplayServer.get_name(), "headless")
	_equip([&"guard_helm_t3", &"guard_chest_t3", &"guard_boots_t3", &"sword_t3_epic"])
	assert_eq(_pieces().size(), 0)
	assert_true(_part("Knight_Helmet").visible)


func test_protetor_usa_o_cajado_e_nao_mostra_elmo() -> void:
	_bind(DRUID)
	_equip([&"guard_helm_t2", &"guard_chest_t3", &"hunter_boots_t2", &"sword_t3_epic"])
	assert_eq(_pieces("druid_staff_t3_epic__handslot_r").size(), 1)
	assert_eq(_pieces("guard_helm_*").size(), 0, "capuz e galhada ficam (ADR-0011 item 3)")
	assert_eq(_pieces("guard_chest_t3__*").size(), 1)
	assert_eq(_pieces("hunter_boots_t2__*").size(), 4)
	_hero._refresh_attributes()
	assert_eq(_hero.attributes.defense, 16.0 + 15.0 + 22.0, "o elmo vale sem aparecer")


func test_ocultista_usa_o_cajado_e_nao_mostra_elmo() -> void:
	_bind(OCCULTIST)
	_equip([&"guard_helm_t2", &"guard_chest_t3", &"hunter_boots_t2", &"sword_t3_epic"])
	assert_eq(_pieces("occultist_staff_t3_epic__handslot_r").size(), 1)
	assert_false(_part("staff").visible, "cajado novo troca o do pack")
	assert_true(_part("spellbook_open").visible, "o livro fica sempre")
	assert_eq(_pieces("guard_helm_*").size(), 0, "capuz fica (ADR-0016 item 8)")
	assert_true(_part("Occultist_Hood").visible)
	assert_eq(_pieces("guard_chest_t3__*").size(), 1)
	assert_eq(_pieces("hunter_boots_t2__*").size(), 4)


func test_paladino_usa_a_maca_mantem_o_escudo_e_nao_mostra_elmo() -> void:
	_bind(PALADIN)
	_equip([&"guard_helm_t2", &"guard_chest_t3", &"hunter_boots_t2", &"sword_t3_epic"])
	assert_eq(_pieces("paladin_mace_t3_epic__handslot_r").size(), 1)
	assert_false(_part("mace").visible, "maca nova troca a do modelo")
	assert_true(_part("shield").visible, "o escudo fica sempre")
	assert_eq(_pieces("guard_helm_*").size(), 0, "sem elmo (ADR-0011 item 3, F76)")
	assert_eq(_pieces("guard_chest_t3__*").size(), 1)
	assert_eq(_pieces("hunter_boots_t2__*").size(), 4)


func test_berserker_usa_os_dois_machados_e_pecas_do_corpo_large() -> void:
	_bind(BERSERKER)
	_equip([&"guard_helm_t2", &"guard_chest_t3", &"hunter_boots_t2", &"sword_t3_epic"])
	assert_eq(_pieces("berserker_axe_t3_epic__handslot_*").size(), 2, "um machado em cada mao")
	assert_eq(_pieces("guard_helm_*").size(), 0, "elmo de chifres fica (ADR-0011 item 3)")
	assert_eq(_pieces("berserker_guard_chest_t3__*").size(), 1)
	assert_eq(_pieces("berserker_hunter_boots_t2__*").size(), 4)
	for axe: Node in _hero.find_child("Model").find_children("Axe_*", "Node3D", true, false):
		assert_false((axe as Node3D).visible, "%s do pack sai com a arma equipada" % axe.name)


func test_ragnarok_poe_o_corpo_em_chamas_e_tira_no_fim() -> void:
	_bind(BERSERKER)
	_equip([&"guard_chest_t3", &"sword_t3_epic"])
	var berserker := _hero as Berserker
	berserker.cc_immune_ticks = 120
	_visual._process(FRAME)
	for mesh: Node in _visual.model.find_children("*", "MeshInstance3D", true, false):
		assert_true((mesh as MeshInstance3D).material_overlay is ShaderMaterial, mesh.name)
	berserker.cc_immune_ticks = 0
	_visual._process(FRAME)
	for mesh: Node in _visual.model.find_children("*", "MeshInstance3D", true, false):
		assert_null((mesh as MeshInstance3D).material_overlay, mesh.name)
