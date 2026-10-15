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
