extends GutTest
## Telemetria da HUD (F57): FPS · PING · TICK no canto superior esquerdo, no lugar da linha de
## rede do rodape durante a partida.


func test_format_online() -> void:
	assert_eq(HudTelemetry.format(144, 21, 3887, false), "FPS 144 · PING 21 ms · TICK 3887")


## Sem conexao com servidor (host offline): ping nao se aplica.
func test_format_offline_has_no_ping() -> void:
	assert_eq(HudTelemetry.format(60, -1, 10, false), "FPS 60 · PING — · TICK 10")


func test_format_autopilot() -> void:
	assert_eq(HudTelemetry.format(60, 30, 5, true), "FPS 60 · PING 30 ms · TICK 5 · AUTOPILOT")
