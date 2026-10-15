class_name ExitCodes
extends RefCounted
## Codigos de saida do processo do Game (ARCHITECTURE-GAME §6; o Launcher le em
## ARCHITECTURE-LAUNCHER §5.2). Mudar um numero muda o contrato com o Launcher (exige ADR).

## Partida terminada (ou treino fechado) normalmente: o Launcher vai ao historico.
const OK: int = 0
## Argumentos ou configuracao invalidos (ex.: porta que nao abre, servidor sem backend).
const ARGUMENTS: int = 1
## Token recusado pelo servidor: o Launcher mostra o erro e volta ao lobby.
const AUTH: int = 2
## A partida acabou, mas o resultado nao chegou ao backend (ficou em user://results/).
const RESULT_NOT_REPORTED: int = 3
## Erro interno ou servidor perdido no meio da partida: erro generico no Launcher.
const INTERNAL: int = 4
