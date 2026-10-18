extends GutTest
## F71: o que a Tela Heróis lê de cada HeroData — nome, classe, papel curto e arma visível — está
## preenchido nos 8 heróis (GDB §4, PRD §4.1) e o Ranger se chama "Arqueiro" (ADR-0013 item 9).

const HEROES_DIR: String = "res://shared/data/heroes/"
## id -> [nome, classe, arma visível] (GDB §4.x "Modelo" e "Ataque Básico"; PRD §4.1).
const ROSTER: Dictionary[StringName, Array] = {
	&"knight": ["Cavaleiro", "Tanque", "Espada Curta"],
	&"ranger": ["Arqueiro", "Ranger", "Arco"],
	&"barbarian": ["Bárbaro", "Algoz", "Machado"],
	&"fire_wizard": ["Bruxo de Fogo", "Mago", "Cajado"],
	&"rogue": ["Ladina", "Algoz", "Besta"],
	&"engineer": ["Engenheiro", "Engenheiro", "Bacamarte"],
	&"druid": ["Protetor da Selva", "Controle", "Cajado"],
	&"berserker": ["Berserker", "Lutador", "Machados"],
}


func test_nome_classe_e_arma_de_cada_heroi() -> void:
	for id: StringName in ROSTER:
		var data := load("%s%s.tres" % [HEROES_DIR, id]) as HeroData
		var expected: Array = ROSTER[id]
		assert_eq(data.display_name, expected[0], "nome de %s" % id)
		assert_eq(data.role, expected[1], "classe de %s" % id)
		assert_eq(data.weapon_name, expected[2], "arma de %s" % id)
		assert_false(data.summary.is_empty(), "papel curto de %s" % id)


func test_a_arqueira_nao_existe() -> void:
	for id: StringName in ROSTER:
		var data := load("%s%s.tres" % [HEROES_DIR, id]) as HeroData
		assert_ne(data.display_name, "Arqueira")
