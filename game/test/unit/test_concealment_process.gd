extends GutTest
## Concealment no cliente que ainda nao conectou (FIX #148): o peer offline responde is_server(),
## mas nao e servidor; o _process nao pode se desligar ali, senao monstros e baus (que existem desde
## o load, antes da conexao) nunca mais atualizam last_hidden_tick nem contam ciclos de neblina.

var _target: Node3D
var _sync: StateSynchronizer
var _concealment: Concealment


func before_each() -> void:
	_target = Node3D.new()
	add_child_autofree(_target)
	_sync = StateSynchronizer.new()
	_sync.root = _target
	_target.add_child(_sync)
	_concealment = Concealment.guard(_target, func(_o: Hero) -> bool: return false, _sync)


func test_peer_offline_nao_desliga_o_process() -> void:
	assert_true(multiplayer.multiplayer_peer is OfflineMultiplayerPeer, "premissa do teste")
	assert_true(_concealment.is_processing())
	_concealment._process(0.0)
	assert_true(_concealment.is_processing(), "offline nao e servidor")


func test_peer_offline_segue_sem_marcar_escondido() -> void:
	_concealment._process(0.0)
	assert_eq(_concealment.last_hidden_tick, -1, "so marca com peer conectado")


## Fim da partida (gate MVP2): o heroi sai da arvore antes de ser liberado e o sinal do rollback
## ainda chega; fora da arvore nao ha multiplayer, entao o handler nao faz nada (sem SCRIPT ERROR).
func test_fora_da_arvore_ignora_o_tick_do_rollback() -> void:
	remove_child(_target)  # o netfox reclama ao sair (desconexao inexistente): ruido conhecido
	_concealment._on_network_rollback_after_process_tick(0)
	for error: GutTrackedError in get_errors():
		assert_false(error.contains_text("is_server"), error.to_s())
		error.handled = true
	add_child(_target)  # volta para o autofree liberar
