extends GutTest
## F48 (SPEC-048 §6 item 1): todo item do catalogo tem peca e icone para cada heroi; cada no
## de peca aponta para um osso que existe no rig do heroi e no slot certo; a peca do pack que o
## slot substitui existe no modelo. Barbaro (F53), Bruxo (F54), Ladina (F58), Engenheiro (F59) e Protetor da Selva (F74),
## ADR-0011 item 3 e ADR-0013 item 7: elmo sem peca (o capuz e o chapeu ficam), mas com icone.

const CATALOG: String = "res://shared/data/items/catalog.tres"
## Heroi -> modelo (mesmo rig KayKit nos dois).
const MODELS: Dictionary[StringName, String] = {
	&"knight": "res://shared/assets/kaykit/adventurers/Knight.glb",
	&"ranger": "res://shared/assets/rrb/heroes/ranger.glb",
	&"barbarian": "res://shared/assets/kaykit/adventurers/Barbarian.glb",
	&"fire_wizard": "res://shared/assets/kaykit/adventurers/Mage.glb",
	&"rogue": "res://shared/assets/rrb/heroes/rogue.glb",
	&"engineer": "res://shared/assets/rrb/heroes/engineer.glb",
	&"druid": "res://shared/assets/rrb/heroes/druid.glb",
}
## Herois cujo elmo nao aparece (ADR-0011 item 3).
const HELMLESS: Array[StringName] = [&"barbarian", &"fire_wizard", &"rogue", &"engineer", &"druid"]
## Indice = ItemData.Slot: prefixos (separados por "|") dos ossos que as pecas do slot usam.
const SLOT_BONES: Array[String] = ["handslot.", "head", "chest", "foot.|lowerleg."]

var _catalog: ItemCatalog = load(CATALOG) as ItemCatalog


func _model(hero: StringName) -> Node3D:
	var model := (load(MODELS[hero]) as PackedScene).instantiate() as Node3D
	autofree(model)
	return model


func test_osso_vem_do_nome_do_no() -> void:
	assert_eq(ItemVisuals.bone_of(&"guard_boots_t1__foot_l"), "foot.l")
	assert_eq(ItemVisuals.bone_of(&"knight_sword_t2__handslot_r"), "handslot.r")
	assert_eq(ItemVisuals.bone_of(&"guard_helm_t3__head"), "head")


func _has_piece(hero: StringName, item: ItemData) -> bool:
	return not (HELMLESS.has(hero) and item.slot == ItemData.Slot.HELM)


func test_todo_item_tem_peca_e_icone_em_cada_heroi() -> void:
	for hero: StringName in MODELS:
		var visuals := ItemVisuals.for_hero(hero)
		assert_not_null(visuals, hero)
		for item: ItemData in _catalog.items:
			var piece: Variant = visuals.pieces.get(item.id)
			if _has_piece(hero, item):
				assert_not_null(piece, "%s: peca de %s" % [hero, item.id])
			else:
				assert_null(piece, "%s: %s nao aparece" % [hero, item.id])
			assert_not_null(visuals.icon(item), "%s: icone de %s" % [hero, item.id])


func test_heroi_sem_visual_e_nulo() -> void:
	assert_null(ItemVisuals.for_hero(&"golem"))


func test_pecas_presas_a_ossos_do_rig_no_slot_certo() -> void:
	for hero: StringName in MODELS:
		var skeleton := _model(hero).find_child("Skeleton3D") as Skeleton3D
		var visuals := ItemVisuals.for_hero(hero)
		for item: ItemData in _catalog.items:
			if not _has_piece(hero, item):
				continue
			var piece := (visuals.pieces[item.id] as PackedScene).instantiate()
			assert_gt(piece.get_child_count(), 0, item.id)
			for node: Node in piece.get_children():
				var bone := ItemVisuals.bone_of(node.name)
				assert_gt(skeleton.find_bone(bone), -1, "%s: %s" % [hero, node.name])
				var in_slot := false
				for prefix: String in SLOT_BONES[item.slot].split("|"):
					in_slot = in_slot or bone.begins_with(prefix)
				assert_true(in_slot, "%s: %s fora do slot" % [hero, node.name])
				assert_true(node is MeshInstance3D, node.name)
			piece.free()


func test_peca_do_pack_substituida_existe_no_modelo() -> void:
	for hero: StringName in MODELS:
		var model := _model(hero)
		for part: StringName in ItemVisuals.for_hero(hero).pack_parts:
			if part != &"":
				assert_not_null(model.find_child(part), "%s: %s" % [hero, part])
