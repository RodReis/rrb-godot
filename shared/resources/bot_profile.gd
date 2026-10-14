class_name BotProfile
extends Resource
## Comportamento do bot da fase 1 (PRD §3.7; limiares aprovados pelo PI em 2026-10-09, F12).
## Distancias em u, tempos em s, HP em fracao do maximo.

## Abaixo disso, com perigo perto, o bot recua.
@export var retreat_hp_pct: float
## Heroi inimigo ou monstro vivo a ate esta distancia = perigo.
@export var danger_range: float
## Segundos seguidos sem perigo para sair do recuo.
@export var safe_seconds: float
## Heroi inimigo a ate esta distancia pode virar briga (se o bot tiver vantagem).
@export var fight_range: float
## Contesta o boss so com HP a partir disto; abaixo farma e saqueia (PI 2026-10-10, #74).
@export var contest_hp_pct: float
## Barbaro (SPEC-053 §5): Salto com o alvo a ate isto (e fora do alcance do basico).
@export var leap_range: float
## Barbaro: Rodopio com inimigo a ate isto.
@export var spin_range: float
## Barbaro: Execucao com o alvo a ate isto.
@export var execute_range: float
## Bruxo de Fogo (SPEC-054 §5): Explosao de Chamas com o alvo a ate isto.
@export var blast_range: float
## Bruxo: Anel de Fogo com inimigo a ate isto.
@export var ring_range: float
## Bruxo: Meteoro com o alvo a ate isto (mira a posicao atual dele).
@export var meteor_range: float
## Ladina (SPEC-058 §7): Rajada em Leque com o alvo a ate isto.
@export var fan_range: float
## Ladina: Bomba de Fumaca para fugir com HP abaixo disto (fracao) e inimigo a ate smoke_range.
@export var smoke_hp_pct: float
@export var smoke_range: float
## Ladina: Emboscada com o alvo a ate isto (mira a posicao atual dele).
@export var ambush_range: float
## Engenheiro (SPEC-059 §7): Garra Mecanica com o alvo alem do alcance do bacamarte e ate isto;
## Torreta com o inimigo (heroi ou monstro farmado) a ate turret_range; Dinamite a ate
## dynamite_range.
@export var claw_range: float
@export var turret_range: float
@export var dynamite_range: float
## Fase 2 (F19): a menos disto da borda da zona (ou fora dela) o bot foge para dentro. Escolha do
## Code: nenhum documento fixa o valor; a zona encolhe ~0,15 u/s, 2 u sao ~13 s de folga.
@export var zone_margin: float
