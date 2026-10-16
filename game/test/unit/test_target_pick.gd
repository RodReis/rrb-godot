extends GutTest
## SPEC-066 §2: clique do botao direito escolhe o alvo sob o cursor (raio contra a capsula vertical
## de cada corpo); RT escolhe o mais proximo da direcao de mira.

## Camera alta olhando para baixo, como a do jogo (inclinada).
const ORIGIN: Vector3 = Vector3(0.0, 10.0, 6.0)
const HEIGHT: float = 1.8
const RADIUS: float = 0.5


func _feet(points: Array[Vector3]) -> PackedVector3Array:
	return PackedVector3Array(points)


## Raio do olho ate [param at] (unitario).
func _ray_to(at: Vector3) -> Vector3:
	return (at - ORIGIN).normalized()


func _radii(count: int) -> PackedFloat32Array:
	var radii := PackedFloat32Array()
	radii.resize(count)
	radii.fill(RADIUS)
	return radii


func test_raio_no_peito_pega_o_alvo() -> void:
	var feet := _feet([Vector3(0.0, 0.0, 0.0)])
	var ray := _ray_to(Vector3(0.0, 1.0, 0.0))
	assert_eq(TargetPick.pick(ORIGIN, ray, feet, _radii(1), HEIGHT), 0)


func test_raio_na_cabeca_e_nos_pes_tambem_pega() -> void:
	var feet := _feet([Vector3(0.0, 0.0, 0.0)])
	assert_eq(TargetPick.pick(ORIGIN, _ray_to(Vector3(0.0, 1.7, 0.0)), feet, _radii(1), HEIGHT), 0)
	assert_eq(TargetPick.pick(ORIGIN, _ray_to(Vector3(0.0, 0.1, 0.0)), feet, _radii(1), HEIGHT), 0)


func test_raio_que_passa_longe_do_corpo_nao_pega() -> void:
	var feet := _feet([Vector3(0.0, 0.0, 0.0)])
	var ray := _ray_to(Vector3(3.0, 0.0, 0.0))
	assert_eq(TargetPick.pick(ORIGIN, ray, feet, _radii(1), HEIGHT), TargetPick.NOT_FOUND)


func test_raio_logo_acima_da_cabeca_nao_pega() -> void:
	var feet := _feet([Vector3(0.0, 0.0, 0.0)])
	var ray := _ray_to(Vector3(0.0, HEIGHT + 1.5, 0.0))
	assert_eq(TargetPick.pick(ORIGIN, ray, feet, _radii(1), HEIGHT), TargetPick.NOT_FOUND)


func test_escolhe_o_mais_perto_da_camera_quando_o_raio_pega_dois() -> void:
	var near := Vector3(0.0, 0.0, 2.0)
	var behind := Vector3(0.0, 0.0, 1.2)  # o raio que pega o peito do 1o segue ate os pes deste
	var feet := _feet([behind, near])
	var ray := _ray_to(near + Vector3(0.0, 1.0, 0.0))
	assert_eq(TargetPick.pick(ORIGIN, ray, feet, _radii(2), HEIGHT), 1)
	var reversed := _feet([near, behind])
	assert_eq(TargetPick.pick(ORIGIN, ray, reversed, _radii(2), HEIGHT), 0)


func test_alvo_atras_da_camera_nao_conta() -> void:
	var feet := _feet([Vector3(0.0, 30.0, 12.0)])
	assert_eq(TargetPick.pick(ORIGIN, Vector3.DOWN, feet, _radii(1), HEIGHT), TargetPick.NOT_FOUND)


func test_lista_vazia_devolve_menos_um() -> void:
	var none := PackedVector3Array()
	assert_eq(
		TargetPick.pick(ORIGIN, Vector3.DOWN, none, PackedFloat32Array(), HEIGHT),
		TargetPick.NOT_FOUND
	)


func test_direcao_escolhe_o_de_menor_angulo() -> void:
	var points := _feet([Vector3(10.0, 0.0, 0.0), Vector3(2.0, 0.0, 6.0)])
	assert_eq(TargetPick.nearest_to_direction(Vector3.ZERO, Vector3.RIGHT, points), 0)
	assert_eq(TargetPick.nearest_to_direction(Vector3.ZERO, Vector3.BACK, points), 1)


func test_direcao_nula_escolhe_o_mais_proximo() -> void:
	var points := _feet([Vector3(10.0, 0.0, 0.0), Vector3(2.0, 0.0, 6.0)])
	assert_eq(TargetPick.nearest_to_direction(Vector3.ZERO, Vector3.ZERO, points), 1)


func test_direcao_sem_candidatos_devolve_menos_um() -> void:
	assert_eq(
		TargetPick.nearest_to_direction(Vector3.ZERO, Vector3.RIGHT, PackedVector3Array()), -1
	)
