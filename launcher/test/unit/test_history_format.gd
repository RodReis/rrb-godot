extends GutTest
## F26: textos do Historico (nomes de heroi e conjunto de shared/data, motivo de fim, duracao,
## data local e id curto). Funcoes puras, sem cena.


func test_heroi_vem_de_shared_data() -> void:
	assert_eq(HistoryFormat.hero_name("ranger"), "Arqueiro")
	assert_eq(HistoryFormat.hero_role("barbarian"), "Algoz")
	assert_not_null(HistoryFormat.hero("knight"))


func test_todo_heroi_do_catalogo_tem_retrato_1x1() -> void:
	var catalog := CatalogService.new()
	catalog.load_all()
	for hero: HeroData in catalog.heroes:
		assert_not_null(HistoryFormat.portrait(String(hero.id)), "retrato 1:1 de %s" % hero.id)


func test_heroi_vazio_ou_desconhecido_nao_quebra() -> void:
	assert_null(HistoryFormat.hero(""))
	assert_null(HistoryFormat.hero("nao_existe"))
	assert_eq(HistoryFormat.hero_name(""), HistoryFormat.NO_HERO)
	assert_eq(HistoryFormat.hero_name("nao_existe"), HistoryFormat.NO_HERO)
	assert_eq(HistoryFormat.hero_role("nao_existe"), "")


func test_id_do_heroi_nao_escapa_do_diretorio() -> void:
	assert_null(HistoryFormat.hero("../items/catalog"))
	assert_null(HistoryFormat.hero("knight/../ranger"))
	assert_null(HistoryFormat.hero("knight\n"), "quebra de linha no fim")
	assert_null(HistoryFormat.portrait("knight\n"))
	assert_eq(HistoryFormat.active_set_name("hunter\n"), "")


func test_conjunto_ativo_pelo_nome_do_bonus() -> void:
	assert_eq(HistoryFormat.active_set_name("hunter"), "Caçador")
	assert_eq(HistoryFormat.active_set_name("guard"), "Guarda")
	assert_eq(HistoryFormat.active_set_name("fantasma"), "")
	assert_eq(HistoryFormat.active_set_name(""), "")


func test_motivo_de_fim_em_portugues() -> void:
	assert_eq(HistoryFormat.end_reason("kill_goal"), "Meta de abates")
	assert_eq(HistoryFormat.end_reason("collapse_hp"), "Colapso: mais vida")
	assert_eq(HistoryFormat.end_reason("left"), "Abandono")  # F80: saiu pelo menu
	assert_eq(HistoryFormat.end_reason("heartbeat_lost"), "Servidor sem sinal")
	assert_eq(HistoryFormat.end_reason("token_expired"), "Ninguém entrou a tempo")
	assert_eq(HistoryFormat.end_reason(""), "")
	assert_eq(HistoryFormat.end_reason("motivo_novo"), HistoryFormat.UNKNOWN_REASON)


func test_duracao_em_minutos_e_segundos() -> void:
	assert_eq(HistoryFormat.duration(522), "08:42 min")
	assert_eq(HistoryFormat.duration(600), "10:00 min")
	assert_eq(HistoryFormat.duration(0), "00:00 min")
	assert_eq(HistoryFormat.duration(-1), "")


func test_data_no_fuso_local() -> void:
	assert_eq(HistoryFormat.played_at("2026-10-15T12:10:00.000Z", -180), "15/10/2026 09:10")
	assert_eq(HistoryFormat.played_at("2026-10-15T01:05:00.000Z", -180), "14/10/2026 22:05")
	assert_eq(HistoryFormat.played_at("2026-10-15T12:10:00.000Z", 0), "15/10/2026 12:10")
	assert_eq(HistoryFormat.played_at("lixo", 0), "")


func test_id_curto_da_partida() -> void:
	assert_eq(HistoryFormat.short_id("0b7e9f00-1111-4222-8333-444455556666"), "#0B7E9F00")
	assert_eq(HistoryFormat.short_id(""), "")
