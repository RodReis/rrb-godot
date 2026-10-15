extends GutTest
## F25: GameProcess (ARCHITECTURE-LAUNCHER §3.3, §5): linha de comando do Game (instalacao e dev)
## e a tabela de codigos de saida (§5.2).

const EXE_DIR: String = "C:/Jogos/Arena"


func test_instalacao_chama_game_exe_ao_lado_do_launcher() -> void:
	var game_args := PackedStringArray(["--connect=10.0.0.5:7003", "--token=tok"])
	var command := GameProcess.command(game_args, PackedStringArray(), EXE_DIR)
	assert_eq(command[0], EXE_DIR + "/game/game.exe")
	assert_eq(command.slice(1), PackedStringArray(["--", "--connect=10.0.0.5:7003", "--token=tok"]))


func test_dev_troca_o_executavel_e_aponta_o_projeto() -> void:
	var launcher_args := PackedStringArray(
		["--api=http://x", "--game-path=D:/godot_console.exe", "--game-project=D:/repo/game"]
	)
	var command := GameProcess.command(
		PackedStringArray(["--offline", "--bot"]), launcher_args, EXE_DIR
	)
	assert_eq(command[0], "D:/godot_console.exe")
	assert_eq(
		command.slice(1), PackedStringArray(["--path", "D:/repo/game", "--", "--offline", "--bot"])
	)


func test_executavel_ausente_nao_lanca() -> void:
	var process := GameProcess.new()
	add_child_autofree(process)
	var args := PackedStringArray(["--game-path=user://nao_existe/game.exe"])
	assert_eq(process.launch(PackedStringArray(["--offline", "--bot"]), args), -1)
	assert_false(process.is_running())
	assert_push_warning("ausente")


func test_codigo_0_e_saida_normal() -> void:
	var outcome := GameProcess.outcome(0)
	assert_eq(outcome.kind, GameProcess.Kind.NORMAL)
	assert_eq(outcome.message, "")


func test_codigo_1_e_erro_de_argumentos() -> void:
	assert_eq(GameProcess.outcome(1).kind, GameProcess.Kind.ERROR)


func test_codigo_2_e_autenticacao_e_oferece_nova_fila() -> void:
	var outcome := GameProcess.outcome(2)
	assert_eq(outcome.kind, GameProcess.Kind.ERROR)
	assert_true(outcome.offer_queue)
	assert_string_contains(outcome.message, "recusou")


func test_codigo_3_avisa_que_o_resultado_pode_demorar() -> void:
	var outcome := GameProcess.outcome(3)
	assert_eq(outcome.kind, GameProcess.Kind.WARNING)
	assert_string_contains(outcome.message, "demorar")


func test_codigo_4_desconhecido_e_morto_sao_erro_generico() -> void:
	for code: int in [4, 5, -1, GameProcess.KILLED]:
		var outcome := GameProcess.outcome(code)
		assert_eq(outcome.kind, GameProcess.Kind.ERROR, str(code))
		assert_false(outcome.offer_queue, str(code))
