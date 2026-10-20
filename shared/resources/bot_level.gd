class_name BotLevel
extends Resource
## Um nivel de dificuldade do bot no treino (F81, ADR-0021/0027). So a inteligencia muda: numeros
## de heroi, itens e regras sao os mesmos. Tempos em ticks, angulos em graus, HP em fracao.

## Nome mostrado no Launcher.
@export var label: String
## O bot decide a cada este numero de ticks (1 = todo tick, como o Medio); entre decisoes repete
## o ultimo movimento e mira e nao aperta habilidade.
@export var reaction_ticks: int
## Erro maximo da mira (graus, sorteado de -x a +x) ao golpear ou usar habilidade.
@export var aim_error_deg: float
## Chance (0 a 1) de cada habilidade pedida sair.
@export var skill_chance: float
## Persegue o adversario na fase 2 (BotRules.wants_chase).
@export var chases: bool
## Mira onde o alvo estara daqui a este tempo (s), pela velocidade dele; 0 = onde ele esta (Medio).
@export var lead_seconds: float
## Usa Q e E nos monstros do farm (o R fica para heroi e boss); false = so o basico (Medio).
@export var farm_skills: bool
## Niveis somados ao do bot ao medir vantagem para brigar (BotRules.has_advantage): 1 = briga
## em nivel igual, e um abaixo se estiver com mais HP.
@export var level_slack: int
## Sobrescrevem BotProfile.retreat_hp_pct e fight_range neste nivel.
@export var retreat_hp_pct: float
@export var fight_range: float
