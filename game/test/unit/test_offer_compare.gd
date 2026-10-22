extends GutTest
## Texto da comparacao do card do bau (SPEC-047 §3): atributos +/- e conjuntos antes -> depois.

const CATALOG: ItemCatalog = preload("res://shared/data/items/catalog.tres")


func _item(id: StringName) -> ItemData:
	return CATALOG.find(Ids.to_int(id))


func _equipped(ids: Array[StringName]) -> Vector4i:
	var equipment := Inventory.NONE
	for id: StringName in ids:
		equipment = Inventory.equip(equipment, _item(id))
	return equipment


func _row(rows: Array[OfferCompare.Row], label: String) -> OfferCompare.Row:
	for row: OfferCompare.Row in rows:
		if row.label == label:
			return row
	return null


func test_slot_vazio_mostra_o_valor_cheio_como_ganho() -> void:
	var row := _row(OfferCompare.rows(null, _item(&"guard_chest_t2")), "HP")
	assert_eq(row.value, 110)
	assert_eq(row.delta, 110)
	assert_eq(OfferCompare.delta_text(row), "+110")


func test_item_melhor_mostra_ganho_contra_o_equipado() -> void:
	var rows := OfferCompare.rows(_item(&"guard_chest_t1"), _item(&"guard_chest_t2"))
	assert_eq(_row(rows, "HP").delta, 60)
	assert_eq(_row(rows, "DEF").delta, 7)


func test_escolha_lateral_pode_perder_atributo() -> void:
	var rows := OfferCompare.rows(_item(&"guard_chest_t2"), _item(&"hunter_chest_t2"))
	var hp := _row(rows, "HP")
	assert_eq(hp.value, 75)
	assert_eq(hp.delta, -35)
	assert_eq(OfferCompare.delta_text(hp), "−35")
	var defense := _row(rows, "DEF")
	assert_eq(defense.value, 0, "o equipado tinha DEF; o do bau nao")
	assert_eq(defense.delta, -12)


func test_atributo_que_nenhum_dos_dois_tem_nao_aparece() -> void:
	var rows := OfferCompare.rows(_item(&"sword_t1"), _item(&"sword_t2"))
	assert_null(_row(rows, "INT"))


func test_delta_zero_fica_sem_texto() -> void:
	var rows := OfferCompare.rows(_item(&"guard_chest_t1"), _item(&"guard_chest_t1"))
	assert_eq(OfferCompare.delta_text(_row(rows, "HP")), "")


func test_veredito_slot_vazio_vale_trocar() -> void:
	assert_eq(OfferCompare.verdict(OfferCompare.rows(null, _item(&"guard_chest_t1"))), 1)


func test_veredito_item_melhor_vale_trocar() -> void:
	var rows := OfferCompare.rows(_item(&"guard_chest_t1"), _item(&"guard_chest_t2"))
	assert_eq(OfferCompare.verdict(rows), 1)


func test_veredito_item_pior_nao_vale() -> void:
	var rows := OfferCompare.rows(_item(&"guard_chest_t2"), _item(&"guard_chest_t1"))
	assert_eq(OfferCompare.verdict(rows), -1)


func test_veredito_igual_fica_neutro() -> void:
	var rows := OfferCompare.rows(_item(&"guard_chest_t1"), _item(&"guard_chest_t1"))
	assert_eq(OfferCompare.verdict(rows), 0)


func test_veredito_e_a_soma_dos_deltas() -> void:
	var rows: Array[OfferCompare.Row] = [
		OfferCompare.Row.new("HP", 0, -35), OfferCompare.Row.new("ATK", 40, 40)
	]
	assert_eq(OfferCompare.verdict(rows), 1)


func test_conjuntos_antes_e_depois() -> void:
	var equipment := _equipped([&"guard_helm_t1", &"guard_chest_t1", &"hunter_boots_t1"])
	var text := OfferCompare.set_change(equipment, _item(&"hunter_chest_t1"), CATALOG)
	assert_string_contains(text, "Guarda 2/3 → 1/3")
	assert_string_contains(text, "Caçador 1/3 → 2/3")


func test_conjunto_so_aparece_se_a_contagem_muda() -> void:
	var equipment := _equipped([&"guard_helm_t1", &"hunter_boots_t1"])
	var text := OfferCompare.set_change(equipment, _item(&"guard_helm_t2"), CATALOG)
	assert_eq(text, "")
