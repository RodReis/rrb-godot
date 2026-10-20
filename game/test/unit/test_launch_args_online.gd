extends GutTest
## Argumentos da partida online (F23): --token do cliente e --no-backend do servidor de dev.


func test_token_da_partida_online() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray([]))["token"], "")
	var r := LaunchArgs.parse(PackedStringArray(["--connect=10.0.0.5:7001", "--token=a.b.c"]))
	assert_eq([r["host"], r["port"], r["token"]], ["10.0.0.5", 7001, "a.b.c"])


func test_token_com_igual_dentro_e_preservado() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--token=abc==.def"]))
	assert_eq(r["token"], "abc==.def")


func test_sem_backend_so_para_dev() -> void:
	assert_false(LaunchArgs.parse(PackedStringArray(["--server"]))["no_backend"])
	assert_true(LaunchArgs.parse(PackedStringArray(["--server", "--no-backend"]))["no_backend"])


func test_nivel_do_bot_no_treino() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray(["--offline", "--bot"]))["bot_difficulty"], 0)
	var r := LaunchArgs.parse(PackedStringArray(["--offline", "--bot", "--bot-difficulty=3"]))
	assert_eq(r["bot_difficulty"], 3)


func test_nivel_do_bot_invalido_vira_ausente() -> void:
	for text: String in ["--bot-difficulty=hard", "--bot-difficulty=", "--bot-difficulty=2.5"]:
		assert_eq(LaunchArgs.parse(PackedStringArray([text]))["bot_difficulty"], 0, text)


func test_niveis_dos_dois_bots_do_soak() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--bots", "--bot-levels=3,2"]))
	assert_eq(r["bot_levels"], [3, 2] as Array[int])
	for text: String in ["--bot-levels=3", "--bot-levels=a,2", "--bot-levels=1,2,3"]:
		assert_eq(LaunchArgs.parse(PackedStringArray([text]))["bot_levels"], [] as Array[int], text)
