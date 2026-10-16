extends GutTest
## SPEC-066 §4: nome, etiqueta e HP que a moldura do alvo mostra para heroi e monstro.

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const SKELETON: String = "res://scenes/monsters/skeleton_t1.tscn"
const BOSS: String = "res://scenes/monsters/skeleton_king_boss.tscn"
const GOLEM: String = "res://scenes/monsters/golem_t3.tscn"


func _monster(path: String) -> Monster:
	var monster := (load(path) as PackedScene).instantiate() as Monster
	add_child_autofree(monster)
	return monster


func test_heroi_mostra_nome_nivel_e_hp() -> void:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = "2"
	hero.level = 3
	add_child_autofree(hero)
	assert_eq(TargetInfo.name_of(hero), "Cavaleiro")
	assert_eq(TargetInfo.tag_of(hero), "Nv 3")
	assert_eq(TargetInfo.hp_of(hero), Vector2i(hero.hp, hero.attributes.max_hp))


func test_monstro_mostra_nome_tier_e_hp() -> void:
	var skeleton := _monster(SKELETON)
	assert_eq(TargetInfo.name_of(skeleton), "Esqueleto")
	assert_eq(TargetInfo.tag_of(skeleton), "T1")
	assert_eq(TargetInfo.hp_of(skeleton), Vector2i(skeleton.hp, 160))
	assert_eq(TargetInfo.tag_of(_monster(GOLEM)), "T3")


func test_boss_e_chefe() -> void:
	var boss := _monster(BOSS)
	assert_eq(TargetInfo.name_of(boss), "Rei Esqueleto")
	assert_eq(TargetInfo.tag_of(boss), "CHEFE")


func test_alvo_desconhecido_volta_vazio() -> void:
	var other := Combatant.new()
	add_child_autofree(other)
	assert_eq(TargetInfo.name_of(other), "")
	assert_eq(TargetInfo.tag_of(other), "")
	assert_eq(TargetInfo.hp_of(other), Vector2i.ZERO)
