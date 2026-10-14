extends GutTest
## BotRules.learn_order (F58): o ponto de habilidade vai primeiro para a habilidade abaixo do rank
## tipico do nivel (GDB §3.2); no tipico, R, Q, E.


func test_ponto_vai_para_a_habilidade_abaixo_do_rank_tipico() -> void:
	# Nivel 2 tipico = Q1 E1 (GDB §3.2): com Q1 E0, o ponto vai para o E, nao para o Q2.
	assert_eq(BotRules.learn_order(Vector3i(1, 0, 0), Vector3i(1, 1, 0))[0], SkillRules.SLOT_E)
	# Nivel 6 tipico = Q3 E2 R1: R primeiro.
	assert_eq(BotRules.learn_order(Vector3i(3, 2, 0), Vector3i(3, 2, 1))[0], SkillRules.SLOT_R)
	# No tipico: R, Q, E (a ordem de antes).
	assert_eq(
		BotRules.learn_order(Vector3i(1, 1, 0), Vector3i(1, 1, 0)),
		PackedInt32Array([SkillRules.SLOT_R, SkillRules.SLOT_Q, SkillRules.SLOT_E])
	)
