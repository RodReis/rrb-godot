class_name PassiveData
extends Resource
## Passiva de heroi (ADR-0015 item 13): regra que vale sempre, sem botao. So o Berserker tem
## (Frenesi, GDB §2.2-E); HeroData.passive nulo = sem passiva.

enum Kind { NONE, FRENZY }

@export var kind: Kind = Kind.NONE
@export var display_name: String
## Efeito em texto curto para a ficha e a Tela Herois: so o que o GDB ja diz.
@export_multiline var description: String
@export var icon: Texture2D
## Frenesi: velocidade de ataque somada no maximo (0.6 = +60 %), depois da formula D do GDB.
@export var attack_speed_bonus: float
## Frenesi: fracao do dano do basico efetivamente causado que volta como cura, no maximo.
@export var lifesteal: float
## Frenesi: fracao do HP maximo em que o efeito chega ao maximo (teto); a 100 % de HP, nada.
@export var full_at_hp_ratio: float
