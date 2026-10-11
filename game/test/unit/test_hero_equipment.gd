extends GutTest
## F48 (SPEC-048 §4, §6 item 2): o HeroVisual mostra so as pecas dos slots equipados, troca quando
## o equipment muda e esconde a peca do pack que a peca nova substitui. O runner e headless, entao
## o visual dos itens e ligado a mao (no jogo, so quem desenha liga).

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RANGER: String = "res://scenes/heroes/ranger.tscn"
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
