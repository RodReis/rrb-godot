extends GutTest
## F58: rogue.tres confere com o GDB §4.5 (ADR-0004): atributos no nivel 1 e 10, recargas e danos
## por rank das 4 habilidades da Ladina.

const ROGUE: HeroData = preload("res://shared/data/heroes/rogue.tres")
const EPS: float = 0.0001


func test_ladina_no_nivel_1_e_10_bate_com_o_gdb() -> void:
	var l := ROGUE
	assert_eq(l.display_name, "Ladina")
	assert_almost_eq(l.base_move_speed, 6.3, EPS)
	var a1 := Stats.attributes(l, 1, [], [])
	assert_eq(a1.max_hp, 450)
	assert_almost_eq(a1.defense, 14.0, EPS)
	assert_almost_eq(a1.attack, 54.0, EPS)
	assert_almost_eq(a1.intelligence, 12.0, EPS)
	assert_almost_eq(a1.agility, 28.0, EPS)
	var a10 := Stats.attributes(l, 10, [], [])
	assert_eq(a10.max_hp, 756)
	assert_almost_eq(a10.defense, 25.7, EPS)
	assert_almost_eq(a10.attack, 97.2, EPS)
	assert_almost_eq(a10.intelligence, 22.8, EPS)
	assert_almost_eq(a10.agility, 49.6, EPS)


func test_habilidades_da_ladina() -> void:
	var l := ROGUE
	# Virote
	assert_almost_eq(l.basic_attack.speed, 24.0, EPS)
	assert_almost_eq(l.basic_attack.attack_range, 7.0, EPS)
	assert_almost_eq(l.basic_attack.radius, 0.3, EPS)
	assert_eq(l.basic_attack.cooldown, PackedFloat64Array([1.0]))
	assert_almost_eq(l.basic_attack.attack_ratio, 1.0, EPS)
	# Q Rajada em Leque (mesma velocidade, alcance e raio do basico; 3 virotes a -12, 0 e +12 graus)
	assert_almost_eq(l.skill_q.speed, l.basic_attack.speed, EPS)
	assert_almost_eq(l.skill_q.attack_range, l.basic_attack.attack_range, EPS)
	assert_almost_eq(l.skill_q.radius, l.basic_attack.radius, EPS)
	assert_eq(l.skill_q.projectile_count, 3)
	assert_almost_eq(l.skill_q.spread_degrees, 12.0, EPS)
	assert_eq(l.skill_q.cooldown, PackedFloat64Array([8.0, 7.5, 7.0, 6.5, 6.0]))
	assert_eq(l.skill_q.base_amount, PackedFloat64Array([30, 45, 60, 75, 90]))
	assert_almost_eq(l.skill_q.attack_ratio, 0.4, EPS)
	assert_almost_eq(l.skill_q.intelligence_ratio, 0.0, EPS)
	assert_eq(l.skill_q.required_hero_level, PackedInt32Array([1]))
	# E Bomba de Fumaca: nuvem de 3 u por 3 s, sem dano
	assert_almost_eq(l.skill_e.radius, 3.0, EPS)
	assert_eq(l.skill_e.duration, PackedFloat64Array([3.0]))
	assert_eq(l.skill_e.cooldown, PackedFloat64Array([14.0, 13.0, 12.0, 11.0, 10.0]))
	assert_eq(l.skill_e.base_amount, PackedFloat64Array())
	assert_eq(l.skill_e.required_hero_level, PackedInt32Array([2]))
	# R Emboscada: avanco de 8 u a 24 u/s; x1,3 oculta
	assert_almost_eq(l.skill_r.distance, 8.0, EPS)
	assert_almost_eq(l.skill_r.speed, 24.0, EPS)
	assert_almost_eq(l.skill_r.ambush_multiplier, 1.3, EPS)
	assert_eq(l.skill_r.cooldown, PackedFloat64Array([50.0, 42.0]))
	assert_eq(l.skill_r.base_amount, PackedFloat64Array([220, 340]))
	assert_almost_eq(l.skill_r.intelligence_ratio, 1.2, EPS)
	assert_almost_eq(l.skill_r.attack_ratio, 0.6, EPS)
	assert_eq(l.skill_r.required_hero_level, PackedInt32Array([6, 10]))
	assert_almost_eq(l.skill_r.knockback, 0.0, EPS, "sem empurrao (SPEC-058 §3)")
