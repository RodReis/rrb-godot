extends GutTest

const ATTACKER_A: int = 11
const ATTACKER_B: int = 22

func test_registro_novo_esta_vazio() -> void:
	assert_true(HitLedger.new().is_empty())

func test_com_golpe_nao_esta_vazio_e_trim_esvazia() -> void:
	var ledger := HitLedger.new()
	ledger.set_hit(10, ATTACKER_A, 120)
	assert_false(ledger.is_empty())
	ledger.trim_before(11)
	assert_true(ledger.is_empty())

func test_tick_sem_golpe_retorna_vazio() -> void:
	var ledger := HitLedger.new()
	assert_eq(ledger.damages_at(10), [] as Array[int])

func test_golpe_registrado_aparece_no_tick() -> void:
	var ledger := HitLedger.new()
	ledger.set_hit(10, ATTACKER_A, 120)
	assert_eq(ledger.damages_at(10), [120] as Array[int])

func test_ler_nao_consome_o_golpe() -> void:
	# Ressimular o alvo precisa reaplicar o mesmo golpe.
	var ledger := HitLedger.new()
	ledger.set_hit(10, ATTACKER_A, 120)
	ledger.damages_at(10)
	assert_eq(ledger.damages_at(10), [120] as Array[int])

func test_mesmo_atacante_no_mesmo_tick_sobrescreve() -> void:
	# Ressimular o atacante nao pode duplicar o golpe.
	var ledger := HitLedger.new()
	ledger.set_hit(10, ATTACKER_A, 120)
	ledger.set_hit(10, ATTACKER_A, 120)
	assert_eq(ledger.damages_at(10), [120] as Array[int])

func test_dois_atacantes_no_mesmo_tick_somam_dois_golpes() -> void:
	var ledger := HitLedger.new()
	ledger.set_hit(10, ATTACKER_A, 120)
	ledger.set_hit(10, ATTACKER_B, 50)
	var damages := ledger.damages_at(10)
	damages.sort()
	assert_eq(damages, [50, 120] as Array[int])

func test_clear_hit_remove_so_o_golpe_daquele_atacante() -> void:
	var ledger := HitLedger.new()
	ledger.set_hit(10, ATTACKER_A, 120)
	ledger.set_hit(10, ATTACKER_B, 50)
	ledger.clear_hit(10, ATTACKER_A)
	assert_eq(ledger.damages_at(10), [50] as Array[int])

func test_clear_hit_inexistente_nao_falha() -> void:
	var ledger := HitLedger.new()
	ledger.clear_hit(10, ATTACKER_A)
	assert_eq(ledger.damages_at(10), [] as Array[int])

func test_trim_before_descarta_ticks_antigos_e_mantem_o_limite() -> void:
	var ledger := HitLedger.new()
	ledger.set_hit(5, ATTACKER_A, 120)
	ledger.set_hit(10, ATTACKER_A, 120)
	ledger.trim_before(10)
	assert_eq(ledger.damages_at(5), [] as Array[int])
	assert_eq(ledger.damages_at(10), [120] as Array[int])
