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


func test_nivel_padrao_e_1() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray([]))["level"], 1)


func test_nivel_de_dev() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray(["--server", "--level=6"]))["level"], 6)


func test_nivel_invalido_volta_ao_padrao() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray(["--level=0"]))["level"], 1)
	assert_eq(LaunchArgs.parse(PackedStringArray(["--level=abc"]))["level"], 1)


func test_offline_e_bot() -> void:
	var none := LaunchArgs.parse(PackedStringArray([]))
	assert_eq([none["offline"], none["bot"]], [false, false])
	var both := LaunchArgs.parse(PackedStringArray(["--offline", "--bot"]))
	assert_eq([both["offline"], both["bot"]], [true, true])
	var server_bot := LaunchArgs.parse(PackedStringArray(["--server", "--bot"]))
	assert_eq(
		[server_bot["mode"], server_bot["offline"], server_bot["bot"]], ["server", false, true]
	)


func test_tempo_inicial_de_dev() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray([]))["time"], 0.0)
	assert_eq(LaunchArgs.parse(PackedStringArray(["--server", "--time=200"]))["time"], 200.0)
	assert_eq(LaunchArgs.parse(PackedStringArray(["--time=-5"]))["time"], 0.0)
	assert_eq(LaunchArgs.parse(PackedStringArray(["--time=abc"]))["time"], 0.0)


func test_seed_dos_baus() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray([]))["seed"], 0)
	assert_eq(LaunchArgs.parse(PackedStringArray(["--server", "--seed=1234"]))["seed"], 1234)
	assert_eq(LaunchArgs.parse(PackedStringArray(["--seed=xyz"]))["seed"], 0)


func test_piloto_bot_no_cliente() -> void:
	var none := LaunchArgs.parse(PackedStringArray([]))
	assert_false(none["bot_pilot"])
	var r := LaunchArgs.parse(PackedStringArray(["--connect=127.0.0.1", "--autopilot=bot"]))
	assert_eq([r["autopilot"], r["bot_pilot"]], [false, true])


func test_sonda_de_rede() -> void:
	assert_false(LaunchArgs.parse(PackedStringArray([]))["probe"])
	assert_true(LaunchArgs.parse(PackedStringArray(["--server", "--probe"]))["probe"])


func test_daynight_forca_o_inicio_da_luz() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray([]))["daynight"], LaunchArgs.DAYNIGHT_AUTO)
	assert_eq(
		LaunchArgs.parse(PackedStringArray(["--daynight=day"]))["daynight"], LaunchArgs.DAYNIGHT_DAY
	)
	assert_eq(
		LaunchArgs.parse(PackedStringArray(["--server", "--daynight=night"]))["daynight"],
		LaunchArgs.DAYNIGHT_NIGHT
	)
	assert_eq(
		LaunchArgs.parse(PackedStringArray(["--daynight=tarde"]))["daynight"],
		LaunchArgs.DAYNIGHT_AUTO,
		"valor invalido volta ao sorteio"
	)


func test_heroi_do_bot_de_dev() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray([]))["bot_hero"], &"")
	var r := LaunchArgs.parse(PackedStringArray(["--offline", "--bot", "--bot-hero=barbarian"]))
	assert_eq(r["bot_hero"], &"barbarian")


func test_dois_bots_no_servidor_sem_cliente() -> void:
	assert_false(LaunchArgs.parse(PackedStringArray(["--server"]))["bots"])
	assert_true(LaunchArgs.parse(PackedStringArray(["--server", "--bots"]))["bots"])


func test_herois_dos_dois_bots_um_por_time() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--bots", "--bot-heroes=knight,ranger"]))
	assert_eq(r["bot_heroes"], [&"knight", &"ranger"] as Array[StringName])
	assert_eq(LaunchArgs.parse(PackedStringArray([]))["bot_heroes"], [] as Array[StringName])


func test_herois_dos_bots_malformados_voltam_ao_padrao() -> void:
	for bad: String in ["knight", "knight,", ",ranger", "a,b,c", ""]:
		var r := LaunchArgs.parse(PackedStringArray(["--bot-heroes=" + bad]))
		assert_eq(r["bot_heroes"], [] as Array[StringName], bad)
