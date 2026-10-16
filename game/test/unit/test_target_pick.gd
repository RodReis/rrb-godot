extends GutTest
## SPEC-066 §2: clique do botao direito escolhe o alvo sob o cursor; RT escolhe o mais proximo da
## direcao de mira.

const ORIGIN: Vector3 = Vector3(0.0, 10.0, 0.0)


func _centers(points: Array[Vector3]) -> PackedVector3Array:
	return PackedVector3Array(points)


func test_raio_que_atravessa_o_alvo_escolhe_ele() -> void:
	var centers := _centers([Vector3(5.0, 1.0, 0.0), Vector3(0.0, 1.0, 0.0)])
	var radii := PackedFloat32Array([1.0, 1.0])
	assert_eq(TargetPick.pick(ORIGIN, Vector3.DOWN, centers, radii), 1)


func test_raio_que_erra_todos_devolve_menos_um() -> void:
	var centers := _centers([Vector3(5.0, 1.0, 0.0)])
	assert_eq(TargetPick.pick(ORIGIN, Vector3.DOWN, centers, PackedFloat32Array([1.0])), -1)


func test_escolhe_o_mais_perto_da_camera_quando_o_raio_pega_dois() -> void:
	var centers := _centers([Vector3(0.0, 1.0, 0.0), Vector3(0.0, 4.0, 0.0)])
	var radii := PackedFloat32Array([1.0, 1.0])
	assert_eq(TargetPick.pick(ORIGIN, Vector3.DOWN, centers, radii), 1)


func test_alvo_atras_da_camera_nao_conta() -> void:
	var centers := _centers([Vector3(0.0, 20.0, 0.0)])
	assert_eq(TargetPick.pick(ORIGIN, Vector3.DOWN, centers, PackedFloat32Array([1.0])), -1)


func test_lista_vazia_devolve_menos_um() -> void:
	assert_eq(TargetPick.pick(ORIGIN, Vector3.DOWN, PackedVector3Array(), PackedFloat32Array()), -1)


func test_direcao_escolhe_o_de_menor_angulo() -> void:
	var points := _centers([Vector3(10.0, 0.0, 0.0), Vector3(2.0, 0.0, 6.0)])
	assert_eq(TargetPick.nearest_to_direction(Vector3.ZERO, Vector3.RIGHT, points), 0)
	assert_eq(TargetPick.nearest_to_direction(Vector3.ZERO, Vector3.BACK, points), 1)


func test_direcao_nula_escolhe_o_mais_proximo() -> void:
	var points := _centers([Vector3(10.0, 0.0, 0.0), Vector3(2.0, 0.0, 6.0)])
	assert_eq(TargetPick.nearest_to_direction(Vector3.ZERO, Vector3.ZERO, points), 1)


func test_direcao_sem_candidatos_devolve_menos_um() -> void:
	assert_eq(
		TargetPick.nearest_to_direction(Vector3.ZERO, Vector3.RIGHT, PackedVector3Array()), -1
	)
