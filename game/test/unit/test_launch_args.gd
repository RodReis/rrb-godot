extends GutTest


func test_sem_argumentos_e_cliente_sem_host_na_porta_padrao() -> void:
	var r := LaunchArgs.parse(PackedStringArray([]))
	assert_eq(r["mode"], "client")
	assert_eq(r["host"], "")
	assert_eq(r["port"], 7000)
	assert_false(r["autopilot"])


func test_server_usa_porta_padrao() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--server"]))
	assert_eq(r["mode"], "server")
	assert_eq(r["port"], 7000)


func test_server_com_porta() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--server", "--port=7010"]))
	assert_eq(r["mode"], "server")
	assert_eq(r["port"], 7010)


func test_connect_com_host_e_porta() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--connect=10.0.0.5:7001"]))
	assert_eq(r["mode"], "client")
	assert_eq(r["host"], "10.0.0.5")
	assert_eq(r["port"], 7001)


func test_connect_sem_porta_usa_padrao() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--connect=10.0.0.5"]))
	assert_eq(r["host"], "10.0.0.5")
	assert_eq(r["port"], 7000)


func test_porta_invalida_cai_no_padrao() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray(["--port=abc"]))["port"], 7000)
	assert_eq(LaunchArgs.parse(PackedStringArray(["--port=70000"]))["port"], 7000)
	assert_eq(LaunchArgs.parse(PackedStringArray(["--port=0"]))["port"], 7000)


func test_autopilot() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--connect=127.0.0.1:7000", "--autopilot"]))
	assert_true(r["autopilot"])
