extends GutTest
## F85 (ADR-0029): `--offline --tutorial` abre o tutorial roteirizado. O tutorial decide quando o
## bot entra, entao nao combina com --bot / --bot-difficulty.


func test_tutorial_ausente_por_padrao() -> void:
	assert_false(LaunchArgs.parse(PackedStringArray([]))["tutorial"])
	assert_false(LaunchArgs.parse(PackedStringArray(["--offline", "--bot"]))["tutorial"])


func test_tutorial_liga_o_modo_offline() -> void:
	var r := LaunchArgs.parse(PackedStringArray(["--tutorial"]))
	assert_true(r["tutorial"])
	assert_true(r["offline"])


func test_tutorial_ignora_bot_e_nivel_do_bot() -> void:
	var r := LaunchArgs.parse(
		PackedStringArray(["--offline", "--tutorial", "--bot", "--bot-difficulty=3"])
	)
	assert_true(r["tutorial"])
	assert_false(r["bot"])
	assert_eq(r["bot_difficulty"], LaunchArgs.NO_DIFFICULTY)
