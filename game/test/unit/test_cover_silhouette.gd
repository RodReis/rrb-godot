extends GutTest
## F72 (SPEC-072, ADR-0015 item 10; F95, PI 2026-10-21): no cliente, o heroi de quem controla fica
## translucido com o proprio visual e a moita abre em volta dele enquanto ele esta na moita ou na
## fumaca. So visual: regra, servidor
## e replicacao (SPEC-032) ficam como estao. O runner e headless, entao o HeroVisual e ligado a mao
## (no jogo, so quem desenha e controla liga).

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const GRASS: ShaderMaterial = preload("res://shared/resources/materials/tall_grass.tres")
const FRAME: float = 1.0 / 60.0
const INSIDE: Vector3 = Vector3(10, 0, 0)
const OUTSIDE: Vector3 = Vector3(30, 0, 0)
const GRASS_SIZE: Vector3 = Vector3(4, 4, 4)
const VISIBILITY_RULES: GDScript = preload("res://scripts/core/visibility_rules.gd")

var _hero: Hero
var _visual: HeroVisual


func before_each() -> void:
	_grass_at(INSIDE, GRASS_SIZE)  # antes do heroi, que le as moitas no _ready


func after_each() -> void:
	GRASS.set_shader_parameter(&"reveal_radius", 0.0)


func _bind(at: Vector3, id: String = "1", bot: bool = false) -> void:
	_hero = (load(KNIGHT) as PackedScene).instantiate() as Hero
	_hero.name = id
	_hero.is_bot = bot
	_hero.transform = Transform3D(Basis(), at)
	add_child_autofree(_hero)
	_visual = _hero.get_node("Visual") as HeroVisual


func _grass_at(at: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.add_to_group(VisibilityRules.GROUP)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	area.position = at
	add_child_autofree(area)


func _overlays() -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	for mesh: Node in _visual.model.find_children("*", "MeshInstance3D", true, false):
		found.append(mesh as MeshInstance3D)
	return found


func _silhouetted() -> int:
	var count := 0
	for mesh: MeshInstance3D in _overlays():
		count += 1 if mesh.transparency > 0.0 else 0
	return count


func test_dentro_da_moita_liga_a_silhueta_e_abre_a_moita() -> void:
	_bind(INSIDE)
	_visual.use_cover_silhouette(true)
	_visual._process(FRAME)
	assert_eq(_silhouetted(), _overlays().size(), "todas as malhas ganham o passe")
	assert_gt(_overlays().size(), 0)
	assert_eq(GRASS.get_shader_parameter(&"reveal_radius"), HeroVisual.REVEAL_RADIUS)
	assert_eq(GRASS.get_shader_parameter(&"hero_pos"), INSIDE)


func test_fora_da_moita_nada_liga() -> void:
	_bind(OUTSIDE)
	_visual.use_cover_silhouette(true)
	_visual._process(FRAME)
	assert_eq(_silhouetted(), 0)
	assert_eq(GRASS.get_shader_parameter(&"reveal_radius"), 0.0)


func test_sair_da_moita_desliga_nos_dois() -> void:
	_bind(INSIDE)
	_visual.use_cover_silhouette(true)
	_visual._process(FRAME)
	_hero.global_position = OUTSIDE
	_visual._process(FRAME)
	assert_eq(_silhouetted(), 0)
	assert_eq(GRASS.get_shader_parameter(&"reveal_radius"), 0.0)


func test_a_abertura_acompanha_o_heroi_dentro_da_moita() -> void:
	_bind(INSIDE)
	_visual.use_cover_silhouette(true)
	_visual._process(FRAME)
	var moved := INSIDE + Vector3(1, 0, 1)
	_hero.global_position = moved
	_visual._process(FRAME)
	assert_eq(GRASS.get_shader_parameter(&"hero_pos"), moved)


## F95 (PI 2026-10-21): o proprio visual translucido, sem a silhueta azul por cima.
func test_heroi_translucido_com_o_proprio_visual() -> void:
	_bind(INSIDE)
	_visual.use_cover_silhouette(true)
	_visual._process(FRAME)
	for mesh: MeshInstance3D in _overlays():
		assert_almost_eq(mesh.transparency, HeroVisual.COVER_TRANSPARENCY, 0.0001, mesh.name)
		assert_null(mesh.material_overlay, "sem passe de cor por cima: %s" % mesh.name)
	assert_almost_eq(HeroVisual.COVER_TRANSPARENCY, 0.45, 0.0001)
	assert_almost_eq(HeroVisual.REVEAL_RADIUS, 2.5, 0.0001)


func test_heroi_morto_na_moita_desliga() -> void:
	_bind(INSIDE)
	_visual.use_cover_silhouette(true)
	_visual._process(FRAME)
	_hero.hp = 0
	_visual._process(FRAME)
	assert_eq(_silhouetted(), 0)
	assert_eq(GRASS.get_shader_parameter(&"reveal_radius"), 0.0)


func test_peca_equipada_dentro_da_moita_tambem_ganha_a_silhueta() -> void:
	_bind(INSIDE)
	_visual.use_items(ItemVisuals.for_hero(_hero.hero_data.id))
	_visual.use_cover_silhouette(true)
	_visual._process(FRAME)
	_hero.equipment = Inventory.equip(
		Inventory.NONE, _hero.item_catalog.find(Ids.to_int(&"guard_helm_t1"))
	)
	_visual._process(FRAME)
	assert_eq(_silhouetted(), _overlays().size())
	assert_gt(
		_visual.model.find_children("guard_helm_t1__*", "MeshInstance3D", true, false).size(), 0
	)


func test_sair_da_arvore_dentro_da_moita_fecha_a_abertura() -> void:
	_bind(INSIDE)
	_visual.use_cover_silhouette(true)
	_visual._process(FRAME)
	_visual._exit_tree()  # remove_child no teste faz o netfox reclamar do proprio _exit_tree
	assert_eq(GRASS.get_shader_parameter(&"reveal_radius"), 0.0, "sem heroi nao sobra buraco")


func test_desligado_nao_faz_nada_mesmo_dentro_da_moita() -> void:
	_bind(INSIDE)
	_visual._process(FRAME)
	assert_eq(_silhouetted(), 0)
	assert_eq(GRASS.get_shader_parameter(&"reveal_radius"), 0.0)


func test_so_o_heroi_controlado_aqui_liga_no_cliente() -> void:
	_bind(INSIDE, str(multiplayer.get_unique_id()))
	assert_true(_visual._controlled_here())
	_bind(INSIDE, str(multiplayer.get_unique_id() + 1))
	assert_false(_visual._controlled_here(), "adversario nao ganha silhueta")


func test_bot_do_treino_nao_ganha_silhueta() -> void:
	_bind(INSIDE, str(multiplayer.get_unique_id()), true)
	assert_false(_visual._controlled_here())


func test_servidor_headless_nao_liga_nada_sozinho() -> void:
	_bind(INSIDE, str(multiplayer.get_unique_id()))
	_visual._process(FRAME)
	assert_eq(_silhouetted(), 0, "o runner e headless: so quem desenha liga")
	assert_eq(GRASS.get_shader_parameter(&"reveal_radius"), 0.0)


## SPEC-032 intacta (ADR-0015 item 10): a regra de visibilidade nao ganha nem perde API. Mudar
## isto exige ADR; a silhueta e so cliente e le a regra, nao a altera.
func test_a_api_da_visibilidade_continua_a_mesma() -> void:
	var methods: Array[String] = []
	for method: Dictionary in VISIBILITY_RULES.get_script_method_list():
		methods.append(String(method["name"]))
	methods.sort()
	var expected: Array[String] = [
		"acted",
		"grass_at",
		"grass_box",
		"is_hidden",
		"is_hidden_in",
		"reveal_ticks",
		"shown_on_client",
		"smoke_bit",
		"smoke_covers",
	]
	assert_eq(methods, expected)
	var constants: Array[String] = []
	for key: Variant in VISIBILITY_RULES.get_script_constant_map().keys():
		constants.append(String(key))
	constants.sort()
	assert_eq(constants, ["GROUP", "HALF", "NO_GRASS", "NO_SMOKE"] as Array[String])
