extends GutTest


func after_each() -> void:
	OS.unset_environment(ServerSession.ENV_SLOT_PORT)


func test_cabecalhos_levam_segredo_e_porta_do_slot() -> void:
	var headers := BackendClient.request_headers("segredo", 7003)
	assert_has(headers, "x-internal-secret: segredo")
	assert_has(headers, "x-slot-port: 7003")
	assert_has(headers, "Content-Type: application/json")


func test_slot_port_valida_do_ambiente() -> void:
	OS.set_environment(ServerSession.ENV_SLOT_PORT, "7012")
	assert_eq(ServerSession.slot_port_from_environment(), 7012)


func test_slot_port_ausente_ou_lixo_vira_zero() -> void:
	for raw: String in ["", "abc", "70x0", "0", "-1", "65536", "7000.5"]:
		OS.set_environment(ServerSession.ENV_SLOT_PORT, raw)
		assert_eq(ServerSession.slot_port_from_environment(), 0, "'%s'" % raw)
