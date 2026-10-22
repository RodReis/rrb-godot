extends GutTest
## Animacao do controle sobre a cabeca (PI 2026-10-22): o CurseMarks le o controle do
## estado replicado e liga o StatusMark do alvo; sem controle, nada nasce.

const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")
const SKELETON: PackedScene = preload("res://scenes/monsters/skeleton_t1.tscn")

var _hero: Hero
var _marks: CurseMarks


func before_each() -> void:
	_hero = KNIGHT.instantiate() as Hero
	_hero.name = "1"
	add_child_autofree(_hero)
	_marks = add_child_autofree(CurseMarks.new()) as CurseMarks


func _indicator(on: Node) -> StatusMark:
	return on.get_node_or_null("StatusMark") as StatusMark


func test_sem_controle_nao_cria_indicador() -> void:
	_marks._process(0.016)
	assert_null(_indicator(_hero))


func test_heroi_atordoado_mostra_as_estrelas() -> void:
	_hero.stun_ticks = 30
	_marks._process(0.016)
	assert_eq(_indicator(_hero).shown_status(), StatusRules.Status.STUN)
	_hero.stun_ticks = 0
	_marks._process(0.016)
	assert_eq(_indicator(_hero).shown_status(), StatusRules.Status.NONE, "acabou: some")


func test_heroi_preso_e_lento() -> void:
	_hero.slow_ticks = 30
	_hero.slow_pct = 1.0
	_marks._process(0.016)
	assert_eq(_indicator(_hero).shown_status(), StatusRules.Status.ROOT)
	_hero.slow_pct = 0.3
	_marks._process(0.016)
	assert_eq(_indicator(_hero).shown_status(), StatusRules.Status.SLOW)


func test_monstro_atordoado_tambem_mostra() -> void:
	var monster := SKELETON.instantiate() as Monster
	add_child_autofree(monster)
	monster._stun_ticks = 20
	_marks._process(0.016)
	assert_eq(monster.status(), StatusRules.Status.STUN)
	assert_not_null(_indicator(monster), "a visibilidade e da neblina (Concealment)")


func test_morto_esconde() -> void:
	_hero.stun_ticks = 30
	_hero.hp = 0
	_marks._process(0.016)
	assert_eq(_indicator(_hero).shown_status(), StatusRules.Status.NONE)
