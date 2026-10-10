extends GutTest
## VisionRules (F37, CONVENTION §4.9, GDB §7.3): raio de visao de 12 u no plano, combinado com o
## mato alto (F32); mascara de explorado so com a posicao do proprio heroi.

const RULES: MatchRules = preload("res://shared/data/rules/match_pacing.tres")
## Mascara de teste: [-4, 4] em x e z com celula de 1 u = 8 x 8 celulas.
const EXTENT: float = 4.0
const CELL: float = 1.0


func test_raio_de_visao_e_12_u() -> void:
	assert_eq(RULES.vision_radius, 12.0)


func test_dentro_do_raio_ve() -> void:
	assert_true(VisionRules.in_sight(Vector3.ZERO, Vector3(11.9, 0.0, 0.0), 12.0))
	assert_true(VisionRules.in_sight(Vector3.ZERO, Vector3(0.0, 0.0, -12.0), 12.0), "na borda ve")


func test_fora_do_raio_nao_ve() -> void:
	assert_false(VisionRules.in_sight(Vector3.ZERO, Vector3(12.1, 0.0, 0.0), 12.0))
	assert_false(VisionRules.in_sight(Vector3.ZERO, Vector3(9.0, 0.0, 9.0), 12.0), "diagonal 12,7")


func test_altura_nao_conta() -> void:
	assert_true(VisionRules.in_sight(Vector3(0.0, 5.0, 0.0), Vector3(11.0, -3.0, 0.0), 12.0))


func test_heroi_no_raio_e_fora_da_moita_aparece() -> void:
	assert_true(VisionRules.hero_shown(true, false))


func test_heroi_fora_do_raio_nao_aparece_mesmo_fora_da_moita() -> void:
	assert_false(VisionRules.hero_shown(false, false))


func test_moita_esconde_dentro_do_raio() -> void:
	assert_false(VisionRules.hero_shown(true, true))


func test_mascara_cobre_o_mapa_com_celulas_inteiras() -> void:
	assert_eq(VisionRules.mask_side(EXTENT, CELL), 8)
	assert_eq(VisionRules.mask_side(37.0, 0.5), 148)


func test_mascara_comeca_toda_nao_vista() -> void:
	var mask := VisionRules.new_mask(EXTENT, CELL)
	assert_eq(mask.size(), 64)
	assert_eq(mask.count(VisionRules.UNSEEN), 64)


func test_explorar_marca_so_as_celulas_no_raio() -> void:
	var mask := VisionRules.new_mask(EXTENT, CELL)
	# Centro da celula (4, 4) = (0,5; 0,5); raio 1,2 pega ela e as 4 vizinhas (centros a 1 u).
	var seen := VisionRules.explore(mask, EXTENT, CELL, Vector3(0.5, 0.0, 0.5), 1.2)
	assert_eq(seen.count(VisionRules.SEEN), 5)
	assert_eq(seen[_index(4, 4)], VisionRules.SEEN)
	assert_eq(seen[_index(3, 4)], VisionRules.SEEN)
	assert_eq(seen[_index(4, 5)], VisionRules.SEEN)
	assert_eq(seen[_index(3, 3)], VisionRules.UNSEEN, "diagonal a 1,41 u fica de fora")


func test_explorar_nao_altera_a_mascara_recebida() -> void:
	var mask := VisionRules.new_mask(EXTENT, CELL)
	VisionRules.explore(mask, EXTENT, CELL, Vector3.ZERO, 2.0)
	assert_eq(mask.count(VisionRules.UNSEEN), 64)


func test_explorado_fica_visto_depois_de_sair() -> void:
	var mask := VisionRules.new_mask(EXTENT, CELL)
	mask = VisionRules.explore(mask, EXTENT, CELL, Vector3(-3.5, 0.0, -3.5), 0.5)
	mask = VisionRules.explore(mask, EXTENT, CELL, Vector3(3.5, 0.0, 3.5), 0.5)
	assert_eq(mask[_index(0, 0)], VisionRules.SEEN)
	assert_eq(mask[_index(7, 7)], VisionRules.SEEN)


func test_raio_fora_do_mapa_e_cortado_na_borda() -> void:
	var mask := VisionRules.new_mask(EXTENT, CELL)
	mask = VisionRules.explore(mask, EXTENT, CELL, Vector3(100.0, 0.0, 0.0), 12.0)
	assert_eq(mask.count(VisionRules.SEEN), 0)
	mask = VisionRules.explore(mask, EXTENT, CELL, Vector3(4.0, 0.0, 0.0), 0.8)
	assert_eq(mask.count(VisionRules.SEEN), 2, "so a coluna da borda: celulas (7, 3) e (7, 4)")


func test_celula_do_ponto() -> void:
	assert_eq(VisionRules.cell_of(Vector3(-4.0, 0.0, -4.0), EXTENT, CELL), Vector2i(0, 0))
	assert_eq(VisionRules.cell_of(Vector3(0.5, 9.0, -0.5), EXTENT, CELL), Vector2i(4, 3))


## Indice da celula da coluna [param x] (eixo x do mundo) e linha [param z] (eixo z).
func _index(x: int, z: int) -> int:
	return z * VisionRules.mask_side(EXTENT, CELL) + x
