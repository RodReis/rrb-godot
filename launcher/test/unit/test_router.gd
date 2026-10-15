extends GutTest
## F24: rotas do Launcher (ARCHITECTURE-LAUNCHER §3.4). So rota que existe; o menu do topo so
## aponta para rota (FRONTEND-LAUNCHER §8.4).


func test_toda_rota_tem_cena_que_carrega() -> void:
	for route: StringName in Router.ROUTES:
		assert_true(Router.has_route(route), route)
		assert_not_null(Router.scene(route), route)


func test_rota_desconhecida_nao_tem_cena() -> void:
	assert_false(Router.has_route(&"lobby_que_nao_existe"))
	assert_null(Router.scene(&"lobby_que_nao_existe"))
	assert_push_error("rota")


func test_menu_so_aponta_para_rotas_existentes() -> void:
	for route: StringName in Router.NAV:
		assert_true(Router.has_route(route), route)


func test_tela_inicial_existe() -> void:
	assert_true(Router.has_route(Router.HOME))


func test_cenas_carrega_todas_as_rotas() -> void:
	assert_eq(Router.scenes().keys(), Router.ROUTES.keys())
