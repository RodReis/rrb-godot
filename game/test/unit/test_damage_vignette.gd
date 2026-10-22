extends GutTest
## Alerta de dano nas laterais (PI 2026-10-22): acende quando o heroi local perde HP, apaga
## sozinho e fica escondido com HP cheio.

const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")

var _hero: Hero
var _vignette: DamageVignette


func before_each() -> void:
	_hero = KNIGHT.instantiate() as Hero
	_hero.name = "1"
	add_child_autofree(_hero)
	_vignette = add_child_autofree(DamageVignette.new())
	_vignette.bind(_hero)


func test_hp_cheio_sem_vinheta() -> void:
	_vignette._process(0.016)
	assert_eq(_vignette.intensity(), 0.0)


func test_perder_hp_acende_e_depois_apaga() -> void:
	_hero.hp -= 10
	_vignette._process(0.016)
	assert_gt(_vignette.intensity(), 0.0)
	_vignette._process(DamageVignette.FLASH_SECONDS)
	assert_eq(_vignette.intensity(), 0.0, "HP alto: apaga depois do flash")


func test_alerta_desligado_nao_mostra() -> void:
	DamageVignette.enabled = false
	_hero.hp -= 10
	_vignette._process(0.016)
	DamageVignette.enabled = true
	assert_eq(_vignette.intensity(), 0.0)
