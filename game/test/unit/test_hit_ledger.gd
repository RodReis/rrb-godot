extends GutTest

const ATTACKER_A: int = 11
const ATTACKER_B: int = 22


func _key(attacker: int, slot: HitLedger.Slot = HitLedger.Slot.BASIC) -> int:
	return HitLedger.source_key(attacker, slot)


func _damages(ledger: HitLedger, tick: int) -> Array[int]:
	var result: Array[int] = []
	for effect: HitEffect in ledger.effects_at(tick):
		result.append(effect.damage)
	result.sort()
	return result


func test_registro_novo_esta_vazio() -> void:
	assert_true(HitLedger.new().is_empty())


func test_com_golpe_nao_esta_vazio_e_trim_esvazia() -> void:
	var ledger := HitLedger.new()
	ledger.set_hit(10, _key(ATTACKER_A), HitEffect.new(120))
	assert_false(ledger.is_empty())
	ledger.trim_before(11)
	assert_true(ledger.is_empty())


func test_tick_sem_golpe_retorna_vazio() -> void:
	assert_eq(_damages(HitLedger.new(), 10), [] as Array[int])


func test_efeito_guarda_dano_empurrao_atordoamento_e_origem() -> void:
	var ledger := HitLedger.new()
	var push := Vector3(1.5, 0, 0)
	ledger.set_hit(10, _key(ATTACKER_A, HitLedger.Slot.Q), HitEffect.new(80, Vector3.ONE, push, 36))
	var effect: HitEffect = ledger.effects_at(10)[0]
	assert_eq(
		[effect.damage, effect.source, effect.push, effect.stun_ticks], [80, Vector3.ONE, push, 36]
	)


func test_ler_nao_consome_o_golpe() -> void:
	# Ressimular o alvo precisa reaplicar o mesmo golpe.
	var ledger := HitLedger.new()
	ledger.set_hit(10, _key(ATTACKER_A), HitEffect.new(120))
	ledger.effects_at(10)
	assert_eq(_damages(ledger, 10), [120] as Array[int])


func test_mesma_fonte_no_mesmo_tick_sobrescreve() -> void:
	# Ressimular o atacante nao pode duplicar o golpe.
	var ledger := HitLedger.new()
	ledger.set_hit(10, _key(ATTACKER_A), HitEffect.new(120))
	ledger.set_hit(10, _key(ATTACKER_A), HitEffect.new(120))
	assert_eq(_damages(ledger, 10), [120] as Array[int])


func test_habilidades_diferentes_do_mesmo_atacante_somam() -> void:
	var ledger := HitLedger.new()
	ledger.set_hit(10, _key(ATTACKER_A, HitLedger.Slot.BASIC), HitEffect.new(40))
	ledger.set_hit(10, _key(ATTACKER_A, HitLedger.Slot.R), HitEffect.new(171))
	assert_eq(_damages(ledger, 10), [40, 171] as Array[int])


func test_dois_atacantes_no_mesmo_tick_somam_dois_golpes() -> void:
	var ledger := HitLedger.new()
	ledger.set_hit(10, _key(ATTACKER_A), HitEffect.new(120))
	ledger.set_hit(10, _key(ATTACKER_B), HitEffect.new(50))
	assert_eq(_damages(ledger, 10), [50, 120] as Array[int])


func test_clear_hit_remove_so_aquela_fonte() -> void:
	var ledger := HitLedger.new()
	ledger.set_hit(10, _key(ATTACKER_A), HitEffect.new(120))
	ledger.set_hit(10, _key(ATTACKER_B), HitEffect.new(50))
	ledger.clear_hit(10, _key(ATTACKER_A))
	assert_eq(_damages(ledger, 10), [50] as Array[int])


func test_clear_hit_inexistente_nao_falha() -> void:
	var ledger := HitLedger.new()
	ledger.clear_hit(10, _key(ATTACKER_A))
	assert_eq(_damages(ledger, 10), [] as Array[int])


func test_trim_before_descarta_ticks_antigos_e_mantem_o_limite() -> void:
	var ledger := HitLedger.new()
	ledger.set_hit(5, _key(ATTACKER_A), HitEffect.new(120))
	ledger.set_hit(10, _key(ATTACKER_A), HitEffect.new(120))
	ledger.trim_before(10)
	assert_eq(_damages(ledger, 5), [] as Array[int])
	assert_eq(_damages(ledger, 10), [120] as Array[int])
