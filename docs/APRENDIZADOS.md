# APRENDIZADOS.md — Armadilhas já pagas

**Leitura obrigatória do Code no passo 1 de todo card.** Curto por desenho.

## Protocolo

- Fonte: seção **Aprendizado** do comentário de encerramento de cada card (skill `fechar-card`). Só entra com fonte verificável (doc oficial, commit, log, comando).
- Consolidação: o Cowork promove para cá no fecho de cada MVP. Entre fechos, o Code pode propor linha por PR de docs.
- **Teto: 30 linhas na seção "Vigentes".** Passou do teto, a mais antiga ou menos recorrente desce para "Arquivo" — ou vira regra em `CLAUDE.md`/`CONVENTION.md` (promoção) e sai daqui.
- Formato: `- [módulo] frase única com a armadilha e o que fazer — fonte`.

## Vigentes

- [game] O `.exe` principal do Godot não imprime no terminal; use o `*_console.exe` para ver saída e crash — `CLAUDE.md` Comandos.
- [game] PowerShell 5.1 trata stderr de executável nativo como exceção com `$ErrorActionPreference='Stop'`; use `'Continue'` ao chamar o Godot — `CLAUDE.md`.
- [game] godot-mcp perde a saída quando o jogo crasha; rode pelo terminal para ver o erro — `README.md`.
- [game] `rg --type gdscript` é erro; use `--glob "*.gd"` — `docs/engine-reference/godot/current-best-practices.md`.
- [game] Clone novo não tem `.godot/`; rode `--import` headless antes de testes, senão o runner não carrega — engine-reference.
- [game] Lambda em GDScript captura local **por valor**; para sinal que marca flag, use Dictionary/objeto — engine-reference.
- [shared] Sem `tools/link-shared.ps1` o projeto abre com erros de `res://shared` — comportamento esperado, não bug — ADR-0003.
- [game] Efeito sobre outro node via `NetworkRollback.mutate` se perde na ressimulação (netfox 1.35.3); use ledger fora do estado e aplique no `_rollback_tick` do alvo — **promovido** a regra em `CLAUDE.md` e `ARCHITECTURE-GAME.md` §3.2 (#5).
- [game] `enable_prediction=false`: node sem input no tick não é simulado nem transmitido; bot e desconectado precisam de input — **promovido** a `ARCHITECTURE-GAME.md` §3.2/§6 (#5).
- [game] O `sanitize` do netfox só confere o dono do input, não o valor; o servidor valida faixa/NaN (`InputRules`) — `addons/netfox/properties/property-snapshot.gd` (#4).
- [game] netfox 1.35.3 inicia o `NetworkTime` pelo `NetworkEvents`; chamar `NetworkTime.start()` à mão dá `ERR_ALREADY_IN_USE` — `network-events.gd:82` (#4).
- [game] GUT 9.7.1 sai com 0 quando não há teste **e** quando um script de teste não compila (`Nothing was run`); `tools/test.ps1` trata isso, não confie só no exit code — PR #10 (#9).
- [game] Cache `game/.godot` gerado antes de copiar `addons/` esconde os plugins; apague `.godot` e reabra — sessão do PI (#2).
- [game] Godot não grava no `project.godot` valor igual ao padrão; ausência de chave ≠ não configurado — commit `9d69a6c` (#2).
- [game] Cliente que trava ~1,4 s no sync inicial (shaders frios) pode ficar com rollback preso (`past the history limit of 64`); visto 1× (#4) — **promovido** a critério de aceite de toda fatia visual: warm-up de shaders antes do `connect` + 3/3 conexões a 100 ms (ADR-0006 item 7).
- [game] Com perda, a RPC de estado pode chegar antes do spawn retransmitido (`Node not found .../RollbackSynchronizer`) e é descartada — F20 precisa de spawn confiável antes de estado (#6).
- [game] `Label3D` com fonte padrão é ilegível a ~15 m; `font_size` alto + `pixel_size` 0.01 — commit `23d3fef` (#5).
- [infra] `tc netem` só numa direção desalinha o relógio do netfox (ida e volta simétricas); `NETEM_DELAY_MS` é o RTT total dividido entre `eth0` e `ifb0` — ADR-0001 (#7).
- [infra] Sob 5 % de perda com jitter, diff states sem referência são descartados (`DiffHistoryEncoder: Reference tick missing`) e o remoto congela; candidatos: `full_state_interval`, `diff_ack_interval`, desligar diff states — ADR-0001, vigiar no F20 (#7).
- [infra] `docker images` no Docker Desktop (containerd) soma camadas comprimidas e descompactadas; meça por `docker history` ou `docker save` — PR #14 (#6).
- [infra] Godot headless em debian-slim imprime `Unable to load fontconfig` no `--import`; inofensivo — F5 (#6).
- [docs] Paleta do DV: `BLUE`/`RED`/`PURPLE` não passam contraste como texto pequeno; use fundo/borda — `design-system/TOKENS.md` (medido 2026-10-08).

## Arquivo

(vazio)
