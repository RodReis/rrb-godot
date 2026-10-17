extends GutTest
## --intro-ready-delay (dev, F69): atraso artificial do ready da cinematica de abertura, para
## provar o corte aos 8 s com um dos dois clientes atrasado.


func test_ausente_nao_atrasa() -> void:
	assert_eq(LaunchArgs.parse(PackedStringArray([]))["intro_ready_delay"], 0.0)


func test_valor_valido_vale() -> void:
	var parsed := LaunchArgs.parse(PackedStringArray(["--intro-ready-delay=4.5"]))
	assert_eq(parsed["intro_ready_delay"], 4.5)


func test_valor_invalido_ou_negativo_volta_a_zero() -> void:
	for invalid: String in ["--intro-ready-delay=abc", "--intro-ready-delay=-2"]:
		assert_eq(
			LaunchArgs.parse(PackedStringArray([invalid]))["intro_ready_delay"],
			0.0,
			"%s volta a zero" % invalid
		)
