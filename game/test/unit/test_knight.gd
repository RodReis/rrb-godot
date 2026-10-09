extends GutTest
## knight.tscn le tudo de knight.tres e xp_table.tres (GDB §3.2, §4.1).

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const EPS: float = 0.0001


func _spawn(level: int) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = "1"
	hero.level = level
	add_child_autofree(hero)
	return hero


func test_nivel_1_tem_os_atributos_base() -> void:
	var hero := _spawn(1)
	assert_eq(hero.hp, 600)
	assert_eq(hero.attributes.max_hp, 600)
	assert_almost_eq(hero.attributes.move_speed, 5.8 * (1.0 + 10.0 * 0.004), EPS)
	assert_eq(hero.ranks, Vector3i(1, 0, 0))


func test_nivel_6_cresce_e_libera_o_terremoto() -> void:
	var hero := _spawn(6)
	assert_eq(hero.hp, 600 + 45 * 5)
	assert_eq(hero.ranks, Vector3i(3, 2, 1))
	assert_true(SkillRules.can_use(hero.hero_data.skill_r, hero.ranks.z, hero.level))


func test_nivel_acima_do_maximo_vira_10() -> void:
	var hero := _spawn(99)
	assert_eq(hero.level, 10)
	assert_eq(hero.hp, 1005)


func test_sem_escudo_e_sem_atordoamento_ao_nascer() -> void:
	var hero := _spawn(1)
	assert_eq([hero.shield_hp, hero.shield_ticks, hero.stun_ticks, hero.dash_ticks], [0, 0, 0, 0])
