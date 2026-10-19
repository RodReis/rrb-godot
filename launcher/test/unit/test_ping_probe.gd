extends GutTest
## #233: o PingProbe mede o GET /health numa conexao que fica aberta (sem DNS e TLS a cada
## chamada). Servidor HTTP falso em processo; mede de verdade, sem rede externa.

var _server: FakeHttpServer
var _probe: PingProbe
var _url: String = ""


func before_each() -> void:
	_server = FakeHttpServer.new()
	add_child_autofree(_server)
	_url = "http://127.0.0.1:%d" % _server.start()
	_probe = PingProbe.new()
	add_child_autofree(_probe)


## A ultima medida volta de dentro do _process do probe (o sinal dele): ceder um quadro tira a
## liberacao do autofree de cima da emissao.
func after_each() -> void:
	_probe.close()
	await wait_process_frames(1)


## Fechar o Launcher no meio de uma medida nao pode retomar a corrotina de um objeto liberado.
func test_liberar_com_medida_pendente_nao_gera_erro() -> void:
	var probe := PingProbe.new()
	add_child(probe)
	probe.measure(_url)
	probe.queue_free()
	await wait_process_frames(3)
	assert_false(is_instance_valid(probe))


func test_fora_da_arvore_nao_mede() -> void:
	var lonely := PingProbe.new()
	assert_eq(await lonely.measure(_url), PingProbe.FAILED)
	lonely.free()


func test_url_https_usa_443_e_tls() -> void:
	var target := PingProbe.parse_url("https://api.lootstart.cloud")
	assert_eq(target["host"], "api.lootstart.cloud")
	assert_eq(target["port"], 443)
	assert_true(target["tls"])


func test_url_http_com_porta() -> void:
	var target := PingProbe.parse_url("http://127.0.0.1:3000/")
	assert_eq(target["host"], "127.0.0.1")
	assert_eq(target["port"], 3000)
	assert_false(target["tls"])


func test_url_http_sem_porta_usa_80() -> void:
	assert_eq(PingProbe.parse_url("http://exemplo.com")["port"], 80)


func test_mede_o_health_em_ms() -> void:
	var ms: int = await _probe.measure(_url)
	assert_gte(ms, 0)
	assert_eq(_server.requests, 2, "aquecimento da conexao nova + a medida")


func test_a_conexao_fica_aberta_entre_as_medidas() -> void:
	for i: int in 3:
		assert_gte(await _probe.measure(_url), 0)
	assert_eq(_server.requests, 4, "1 aquecimento + 3 medidas")
	assert_eq(_server.connections, 1, "uma conexao so: DNS e handshake fora da medida")


func test_mede_o_atraso_do_servidor_e_nao_o_da_conexao() -> void:
	_server.delay_msec = 60
	await _probe.measure(_url)
	var ms: int = await _probe.measure(_url)
	assert_gte(ms, 60)
	assert_lt(ms, 200)


func test_reconecta_se_o_servidor_fechou_a_conexao() -> void:
	_server.close_after_reply = true
	assert_gte(await _probe.measure(_url), 0)
	assert_gte(await _probe.measure(_url), 0)
	assert_gte(_server.connections, 2, "sem keep-alive cada medida abre a sua")


func test_sem_servidor_devolve_falha() -> void:
	var dead := FakeHttpServer.new()
	add_child_autofree(dead)
	var port := dead.start()
	dead.queue_free()
	await wait_process_frames(2)
	var ms: int = await _probe.measure("http://127.0.0.1:%d" % port)
	assert_eq(ms, PingProbe.FAILED)


func test_troca_de_url_abre_outra_conexao() -> void:
	await _probe.measure(_url)
	var other := FakeHttpServer.new()
	add_child_autofree(other)
	var other_url := "http://127.0.0.1:%d" % other.start()
	assert_gte(await _probe.measure(other_url), 0)
	assert_eq(other.requests, 2)
