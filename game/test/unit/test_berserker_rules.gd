extends GutTest
## F75: curva do Frenesi (GDB §2.2-E) — f em 100/60/20/10 % de HP, velocidade de ataque depois da
## formula D e roubo de vida sobre o dano efetivamente causado.

const EPS: float = 0.0001
## Teto do Frenesi: chega ao maximo com 20 % de HP.
const FULL_AT: float = 0.2


func test_f_em_100_60_20_e_10_por_cento_de_hp() -> void:
	assert_almost_eq(BerserkerRules.frenzy(1000, 1000, FULL_AT), 0.0, EPS, "100 %: nada")
	assert_almost_eq(BerserkerRules.frenzy(600, 1000, FULL_AT), 0.5, EPS, "60 %: metade")
	assert_almost_eq(BerserkerRules.frenzy(200, 1000, FULL_AT), 1.0, EPS, "20 %: maximo")
	assert_almost_eq(BerserkerRules.frenzy(100, 1000, FULL_AT), 1.0, EPS, "10 %: teto")


func test_f_sem_hp_maximo_e_zero() -> void:
	assert_almost_eq(BerserkerRules.frenzy(0, 0, FULL_AT), 0.0, EPS)


func test_velocidade_de_ataque_entra_depois_da_formula_d() -> void:
	# Intervalo ja com a AGI (formula D): 0,8 s. f = 1 => / (1 + 0,6).
	assert_almost_eq(BerserkerRules.attack_interval(0.8, 0.0, 0.6), 0.8, EPS)
	assert_almost_eq(BerserkerRules.attack_interval(0.8, 0.5, 0.6), 0.8 / 1.3, EPS)
	assert_almost_eq(BerserkerRules.attack_interval(0.8, 1.0, 0.6), 0.5, EPS)


func test_roubo_de_vida_sobre_o_dano_causado() -> void:
	assert_eq(BerserkerRules.lifesteal_heal(100, 0.0, 0.25), 0, "100 % de HP: nada")
	assert_eq(BerserkerRules.lifesteal_heal(100, 0.5, 0.25), 13, "12,5 arredonda para 13")
	assert_eq(BerserkerRules.lifesteal_heal(100, 1.0, 0.25), 25)
	assert_eq(BerserkerRules.lifesteal_heal(0, 1.0, 0.25), 0, "errou: nada")
