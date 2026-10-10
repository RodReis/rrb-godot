extends GutTest
## Neblina no cliente (F37, CONVENTION §4.9): mascara de explorado so da posicao do proprio heroi,
## quad de tela desenhado antes da parede da zona (a zona e sempre visivel, no mundo e no minimapa,
## que desenha o mesmo World3D).

const KNIGHT: String = "res://scenes/heroes/knight.tscn"

var _fog: FogOfWar
var _hero: Hero


func before_each() -> void:
	_hero = (load(KNIGHT) as PackedScene).instantiate() as Hero
	_hero.name = "1"
	add_child_autofree(_hero)
	_fog = FogOfWar.new()
	add_child_autofree(_fog)


func test_comeca_sem_nada_explorado() -> void:
	assert_false(_fog.is_explored(Vector3.ZERO))


func test_explora_o_raio_do_proprio_heroi() -> void:
	_hero.global_position = Vector3(-20.0, 0.0, 10.0)
	_fog.bind(_hero)
	_fog._process(0.0)
	assert_true(_fog.is_explored(Vector3(-20.0, 0.0, 10.0)))
	assert_true(_fog.is_explored(Vector3(-20.0, 0.0, 21.5)), "11,5 u: dentro do raio")
	assert_false(_fog.is_explored(Vector3(-20.0, 0.0, -3.0)), "13 u: fora")


func test_explorado_fica_depois_que_o_heroi_sai() -> void:
	_hero.global_position = Vector3(-20.0, 0.0, 10.0)
	_fog.bind(_hero)
	_fog._process(0.0)
	_hero.global_position = Vector3(20.0, 0.0, -10.0)
	_fog._process(0.0)
	assert_true(_fog.is_explored(Vector3(-20.0, 0.0, 10.0)))
	assert_true(_fog.is_explored(Vector3(20.0, 0.0, -10.0)))


func test_shader_recebe_a_posicao_e_o_raio() -> void:
	_hero.global_position = Vector3(3.0, 0.0, -4.0)
	_fog.bind(_hero)
	_fog._process(0.0)
	var material := _fog.shader_material()
	assert_eq(material.get_shader_parameter(&"viewer_xz"), Vector2(3.0, -4.0))
	assert_eq(material.get_shader_parameter(&"vision_radius"), 12.0)


func test_zona_sempre_visivel_desenhada_depois_da_neblina() -> void:
	var ring := ZoneRing.new()
	ring.rules = preload("res://shared/data/rules/match_pacing.tres")
	ring.clock = MatchClock.new()
	add_child_autofree(ring.clock)
	add_child_autofree(ring)
	assert_gt(ring._material.render_priority, _fog.shader_material().render_priority)
	assert_null(ring.get_node_or_null(NodePath(Concealment.NODE_NAME)), "nada filtra a zona")
