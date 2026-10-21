class_name SkillData
extends Resource
## Habilidade de heroi: ataque basico, Q, E ou R (GDB §4). Campos "por rank" sao arrays
## indexados por rank - 1; o ultimo valor vale para os ranks seguintes. Campo que a
## habilidade nao usa fica zerado.

@export var id: StringName
@export var display_name: String
## Efeito em texto curto para a ficha do heroi (F62): so o que o GDB §4 ja diz, sem regra nova.
@export_multiline var description: String
## Icone do SkillButton (placeholder geometrico ate a arte, DEBITO DS-06); nulo = inicial.
@export var icon: Texture2D
@export var max_rank: int
## Nivel minimo do heroi para cada rank (Q [1], E [2], R [6, 10]).
@export var required_hero_level: PackedInt32Array
@export var cooldown: PackedFloat64Array
## Dano base (ou escudo, no E do Cavaleiro) por rank, antes das razoes.
@export var base_amount: PackedFloat64Array
@export var attack_ratio: float
@export var intelligence_ratio: float
@export var max_hp_ratio: float
## Fracao do HP faltante do alvo somada ao dano, antes da DEF (R do Barbaro).
@export var missing_hp_ratio: float
## Alcance do golpe/projetil (u).
@export var attack_range: float
## Raio da area ou da colisao do projetil (u).
@export var radius: float
@export var arc_degrees: float
@export var speed: float
@export var distance: float
@export var knockback: float
## Distancia maxima para posicionar a area (R da Arqueira).
@export var cast_range: float
## Duracao do efeito (escudo, rolamento, saraivada) por rank; no Meteoro do Bruxo, o atraso da
## queda depois da marcacao.
@export var duration: PackedFloat64Array
@export var stun_duration: PackedFloat64Array
@export var invulnerability: float
@export var pulse_count: int
@export var pulse_interval: float
## Fracao de lentidao (0.25 = 25 %).
@export var slow: float
## Velocidade de movimento somada enquanto dura (0.15 = +15 %; Grito de Guerra e Ragnarok).
@export var move_speed_bonus: float
## Perda de dano por alvo atravessado e dano minimo, em fracao.
@export var pierce_decay: float
@export var pierce_min: float
@export var resets_basic_attack: bool
## Projeteis lancados juntos e abertura entre eles em graus (Rajada em Leque da Ladina: 3, a
## -12/0/+12).
@export var projectile_count: int
@export var spread_degrees: float
## Marcas de Maldicao que o golpe soma ao alvo (basico do Ocultista, F77: 1); a duracao da marca
## vem de `duration`. A DEF tirada por marca e o teto ficam em OccultistRules.
@export var curse_marks: int
## Fator do dano se a Ladina estava oculta no tick do uso (Emboscada).
@export var ambush_multiplier: float
## Largura da faixa a frente em que o golpe pega o 1o alvo (Golpe Consagrado do Paladino, F76); o
## comprimento e `attack_range`.
@export var strip_width: float
## Fracao do dano recebido (depois da DEF) devolvida ao atacante, por rank (Retribuicao do Paladino,
## F76); o alcance da origem do golpe e `attack_range` e o bonus de ATK e `attack_ratio`.
@export var reflect_ratio: PackedFloat64Array
## Recast (Espinhos do Carrasco, F98): janela em s para lancar o projetil depois do golpe, e dano dele
## (base por rank + fracao do ATK). Velocidade, alcance e raio do projetil: speed, distance, radius.
@export var recast_window: float
@export var recast_amount: PackedFloat64Array
@export var recast_attack_ratio: float
## Duracao da lentidao em s (Espinhos e Penitencia do Carrasco); a fracao e `slow`.
@export var slow_duration: float
## Fracao do dano recebido, depois da DEF, que a canalizacao tira (Penitencia: 0.4 = -40 %).
@export var mitigation: float
## Cura total da canalizacao (Penitencia): base por rank + fracao do ATK + per_pain por Dor.
@export var heal_amount: PackedFloat64Array
@export var heal_attack_ratio: float
## Somado por ponto de Dor do Carrasco a cura e ao dano da Penitencia.
@export var per_pain: float
## Penitencia: com Dor >= root_min_pain a explosao prende (raiz por root_duration s); senao, lentidao.
@export var root_min_pain: int
@export var root_duration: float
## Correntes do Julgamento: raio do raio de luz no ponto do acerto e fracao do HP maximo abaixo da
## qual quem esta dentro dela e executado.
@export var light_radius: float
@export var execute_hp_ratio: float


## Valor de [param values] no [param rank] (1..). Vazio = 0; rank alem do array = ultimo.
static func at_rank(values: PackedFloat64Array, rank: int) -> float:
	if values.is_empty():
		return 0.0
	return values[clampi(rank - 1, 0, values.size() - 1)]
