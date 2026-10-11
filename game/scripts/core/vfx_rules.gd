class_name VfxRules
extends RefCounted
## Regras puras dos efeitos visuais (F41; bloco visual regra 2). Efeito de habilidade nasce da
## borda do estado replicado/previsto, lida no _process (como o HeroVisual), nunca de dentro do
## _rollback_tick: ressimular restaura o mesmo estado e nao cria borda nova, e o heroi remoto (que
## o cliente nao simula, enable_prediction=false) entra pelo mesmo caminho. A flecha visual anda
## sozinha na velocidade do disparo e so acompanha a posicao da rede, sem nunca voltar atras.

## Ganho da correcao da flecha visual rumo a rede (1/s): ~95 % do erro some em 0,1 s.
const ARROW_CATCH_UP: float = 30.0
## Erro (u) a partir do qual a flecha visual salta para a rede (perda longa, correcao grande).
const ARROW_SNAP: float = 2.0


## Timer de rollback que subiu (recarga ou duracao recomecou): um disparo novo.
static func started(previous: int, current: int) -> bool:
	return current > previous


## Avanco visual (u desde o disparo) da flecha: anda [param speed] por [param delta] e corrige
## rumo a [param network] sem recuar; para em [param end] (alcance).
static func arrow_progress(
	shown: float, network: float, speed: float, delta: float, end: float
) -> float:
	if absf(network - shown) > ARROW_SNAP:
		return minf(network, end)
	var moved := shown + speed * delta
	moved += (network - moved) * (1.0 - exp(-ARROW_CATCH_UP * delta))
	return minf(maxf(moved, shown), end)
