extends GutTest

const PEER: int = 1001


func test_sem_amostra_nao_ha_media() -> void:
	assert_eq(PingAverage.new().average(PEER), PingAverage.NONE)


func test_media_inteira_das_amostras() -> void:
	var ping := PingAverage.new()
	for rtt: int in [40, 50, 61]:
		ping.add(PEER, rtt)
	assert_eq(ping.average(PEER), 50)


func test_media_arredonda_ao_mais_proximo() -> void:
	var ping := PingAverage.new()
	ping.add(PEER, 10)
	ping.add(PEER, 11)
	assert_eq(ping.average(PEER), 11)


func test_amostra_negativa_e_ignorada() -> void:
	var ping := PingAverage.new()
	ping.add(PEER, -1)
	assert_eq(ping.average(PEER), PingAverage.NONE)
	ping.add(PEER, 30)
	ping.add(PEER, -1)
	assert_eq(ping.average(PEER), 30)


func test_peers_nao_se_misturam() -> void:
	var ping := PingAverage.new()
	ping.add(PEER, 20)
	ping.add(PEER + 1, 100)
	assert_eq(ping.average(PEER), 20)
	assert_eq(ping.average(PEER + 1), 100)


func test_zero_ms_e_amostra_valida() -> void:
	var ping := PingAverage.new()
	ping.add(PEER, 0)
	assert_eq(ping.average(PEER), 0)
