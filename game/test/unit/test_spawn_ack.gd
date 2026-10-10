extends GutTest
## SpawnAck (F20): o servidor so manda estado de um node a quem confirmou que ja o tem.

var _owner: Node3D
var _sync: StateSynchronizer


func before_each() -> void:
	_owner = Node3D.new()
	add_child_autofree(_owner)
	_sync = StateSynchronizer.new()
	_sync.root = _owner
	_owner.add_child(_sync)


func test_no_servidor_ninguem_recebe_estado_antes_de_confirmar() -> void:
	SpawnAck.guard(_owner, [_sync.visibility_filter])
	assert_false(_sync.visibility_filter.get_visibility_for(5))


func test_confirmar_libera_so_quem_confirmou() -> void:
	var ack := SpawnAck.guard(_owner, [_sync.visibility_filter])
	ack.confirm(5)
	assert_true(_sync.visibility_filter.get_visibility_for(5))
	assert_false(_sync.visibility_filter.get_visibility_for(6))


func test_vale_para_todos_os_filtros_do_node() -> void:
	var other := StateSynchronizer.new()
	other.root = _owner
	_owner.add_child(other)
	var ack := SpawnAck.guard(_owner, [_sync.visibility_filter, other.visibility_filter])
	ack.confirm(7)
	assert_true(other.visibility_filter.get_visibility_for(7))
