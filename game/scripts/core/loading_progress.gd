class_name LoadingProgress
extends RefCounted
## Progresso da tela de loading do Game (F68, SPEC-068): tres etapas reais, do boot ate a selecao de
## herois. Cada etapa guarda a maior fracao ja vista e o total soma os pesos; por isso o valor so
## sobe (0 -> 1), mesmo que uma etapa reporte um numero menor que o anterior.

enum Stage { WARMUP, CONNECT, WAIT }

## Peso de cada etapa no total (soma 1). O warm-up e o que mais demora (~2 s); a conexao e curta;
## a espera pelo adversario so completa quando a selecao abre.
const WEIGHTS: Dictionary[int, float] = {
	Stage.WARMUP: 0.6,
	Stage.CONNECT: 0.25,
	Stage.WAIT: 0.15,
}
## Texto de estado de cada etapa (a primeira ainda incompleta).
const STATUS: Dictionary[int, String] = {
	Stage.WARMUP: "Preparando shaders…",
	Stage.CONNECT: "Conectando…",
	Stage.WAIT: "Aguardando adversário…",
}

var _fractions: Dictionary[int, float] = {Stage.WARMUP: 0.0, Stage.CONNECT: 0.0, Stage.WAIT: 0.0}


## Registra a fracao [param fraction] (0..1) da etapa; valor menor que o ja visto e ignorado.
func report(stage: Stage, fraction: float) -> void:
	_fractions[stage] = maxf(_fractions[stage], clampf(fraction, 0.0, 1.0))


func complete(stage: Stage) -> void:
	report(stage, 1.0)


## Total 0..1, nunca decrescente.
func value() -> float:
	var total := 0.0
	for stage: int in WEIGHTS:
		total += WEIGHTS[stage] * _fractions[stage]
	return clampf(total, 0.0, 1.0)


## Texto da primeira etapa incompleta; vazio quando tudo terminou.
func status() -> String:
	for stage: int in STATUS:
		if _fractions[stage] < 1.0:
			return STATUS[stage]
	return ""
