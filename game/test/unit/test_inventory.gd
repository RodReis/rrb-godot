extends GutTest
## Inventario de 4 slots (ids inteiros no estado do heroi) e I5: o heroi no servidor chega ao
## mesmo atributo final que shared/core (Forja) para o build da fixture do F6.

const CATALOG: String = "res://shared/data/items/catalog.tres"
const FIXTURE: String = "res://shared/test/fixtures/build_guard_full.tres"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const EPS: float = 0.0001

var _catalog: ItemCatalog


func before_all() -> void:
	_catalog = load(CATALOG) as ItemCatalog


func _item(id: StringName) -> ItemData:
	return _catalog.find(Ids.to_int(id))


func _assert_same(a: HeroAttributes, b: HeroAttributes) -> void:
	assert_eq(a.max_hp, b.max_hp, "max_hp")
	for field: StringName in [
		&"defense",
		&"attack",
		&"intelligence",
		&"agility",
		&"move_speed",
		&"attack_interval",
		&"cdr_percent",
		&"mitigation",
	]:
		assert_almost_eq(a.get(field) as float, b.get(field) as float, EPS, field)


func test_comeca_vazio() -> void:
	assert_eq(Inventory.items(Inventory.NONE, _catalog).size(), 0)
	assert_null(Inventory.item_at(Inventory.NONE, ItemData.Slot.HELM, _catalog))


func test_equipar_ocupa_o_slot_do_item() -> void:
	var eq := Inventory.equip(Inventory.NONE, _item(&"guard_helm_t1"))
	assert_eq(eq[ItemData.Slot.HELM], Ids.to_int(&"guard_helm_t1"))
	assert_eq(eq[ItemData.Slot.WEAPON], Inventory.EMPTY)
	assert_eq(Inventory.item_at(eq, ItemData.Slot.HELM, _catalog).id, &"guard_helm_t1")


func test_equipar_no_slot_ocupado_substitui_sem_mexer_no_original() -> void:
	var before := Inventory.equip(Inventory.NONE, _item(&"sword_t1"))
	var after := Inventory.equip(before, _item(&"sword_t2"))
	assert_eq(after[ItemData.Slot.WEAPON], Ids.to_int(&"sword_t2"))
	assert_eq(before[ItemData.Slot.WEAPON], Ids.to_int(&"sword_t1"))
	assert_eq(Inventory.items(after, _catalog).size(), 1)


func test_troca_automatica_so_com_raridade_maior_ou_slot_vazio() -> void:
	var eq := Inventory.equip(Inventory.NONE, _item(&"guard_helm_t2"))
	assert_eq(Inventory.swap_mode(eq, _item(&"sword_t1"), _catalog), ItemRules.Swap.AUTO)
	assert_eq(Inventory.swap_mode(eq, _item(&"guard_helm_t3"), _catalog), ItemRules.Swap.AUTO)
	assert_eq(Inventory.swap_mode(eq, _item(&"hunter_helm_t2"), _catalog), ItemRules.Swap.CONFIRM)
	assert_eq(Inventory.swap_mode(eq, _item(&"guard_helm_t1"), _catalog), ItemRules.Swap.CONFIRM)


func test_i5_inventario_igual_a_shared_core() -> void:
	var build := load(FIXTURE) as BuildFixture
	var eq := Inventory.NONE
	for item: ItemData in build.items:
		eq = Inventory.equip(eq, item)
	var forge := Stats.attributes(build.hero, build.level, build.items, _catalog.set_bonuses)
	_assert_same(Inventory.attributes(build.hero, build.level, eq, _catalog), forge)


func test_i5_heroi_no_servidor_igual_a_shared_core() -> void:
	var build := load(FIXTURE) as BuildFixture
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = "1"
	hero.level = build.level
	add_child_autofree(hero)
	for item: ItemData in build.items:
		hero.equipment = Inventory.equip(hero.equipment, item)
	hero._refresh_attributes()
	var forge := Stats.attributes(build.hero, build.level, build.items, _catalog.set_bonuses)
	_assert_same(hero.attributes, forge)
	assert_eq(hero.attributes.max_hp, 1282)
