# PRS.md — Pull requests: boas práticas, revisão e métricas

Complementa `GITHUB.md` (branches, commits, merge) e `CI-PR.md` (jobs e limites). Mantido pelo Code.

## 1. Tamanho e idade

| Métrica | Alvo | Limite (pede justificativa na descrição) |
|---|---|---|
| Linhas alteradas (sem `.tres`, `.tscn` gerados, lock files) | ≤ 400 | 800 |
| Arquivos tocados | ≤ 15 | 30 |
| Idade (abertura → merge) | ≤ 2 dias | 5 dias |
| Rodadas de CI até verde | 1–2 | 4 |
| Módulos tocados | 1 (+ `shared`) | 2 — PR que toca `game` e `launcher` juntos só por mudança em `shared/` |

PR grande demais não se "aprova com ressalva": parte-se. Exceção documentada: `.tres` gerados em massa (F6), import de assets (F7/F8).

## 2. Descrição (template `.github/pull_request_template.md`)

```
## Problema
<o que estava errado ou faltando, com link para a issue: refs #N — nunca closes>

## Antes / Depois
<comportamento observável; captura para UI; saída de comando para CLI>

## SPEC / Fonte
<SPEC-nnn ou seção do PRD/GDB/ADR que justifica>

## Validação executada
<comandos rodados e saída real — GUT, soak, roteiro de rede, prova por tela>

## Limitações / o que não entrou
<débito registrado em DEBITO.md ou FORA-DE-ESCOPO.md, se houver>
```

Descrição explica o resultado, não narra tentativas. Sem "WIP" na `main`: PR em rascunho até estar pronta.

## 3. Rotina de revisão (autorrevisão, fluxo solo)

1. Diff completo contra a base, inclusive arquivos já commitados (`engineering:code-review`).
2. Checklist por tipo de mudança:
   - **`core/` / `shared/core`:** função pública tem GUT? número literal? função pura mesmo (sem Node, sem `await`)?
   - **`net/`:** estado só em `_rollback_tick`? `NetworkRollback.mutate` após alterar outro node? input por `BaseNetInput`? validação de faixa em RPC? nome de API do netfox conferido no addon?
   - **`match/`:** transição nova no FSM está em `CONVENTION.md` §3? evento novo listado em `ARCHITECTURE-GAME.md` §3.3?
   - **UI (`launcher/` ou HUD):** 5 estados? `%unique names`? componente de `COMPONENTS.md`? `add_theme_*_override`? prova por tela anexada?
   - **`backend/`:** zod no DTO? guard no endpoint? migração versionada? e2e cobre o caminho feliz e o 4xx?
   - **`shared/`:** CI dos dois módulos rodou? `I5` ainda passa?
   - **Qualquer:** `DEVELOPMENT.md` e `STATUS.md` atualizados? aprendizado para o comentário de encerramento?
3. Achados P0 (quebra regra normativa ou invariante I1–I9) e P1 (viola `CLAUDE.md`/arquitetura) bloqueiam. P2 vira `[FIX]` ou linha em `DEBITO.md`.
4. CI: `gh pr checks <n> --watch`; nunca afirmar estado sem verificar no momento.

## 4. Métricas do fluxo

Consolidadas pelo Code no fecho de cada MVP a partir de `gh pr list --state merged --json` e `docs/ci/durations.csv`. Tabela mantida aqui:

| MVP | PRs | Linhas/PR (p50) | Idade (p50) | Rodadas CI (p50) | Gate (p50 / p95) | Flakes | Lead time* | Taxa de `[FIX]` pós-merge |
|---|---|---|---|---|---|---|---|---|
| MVP0 | — | — | — | — | — | — | — | — |

\* **DORA** adaptado ao fluxo solo: *lead time* = primeiro commit da branch → merge; *frequência de deploy* = merges/semana na `main`; *taxa de falha* = `[FIX]` abertos sobre cards `done` do MVP; *tempo de restauração* = abertura do `[FIX]` → merge. Sem "deploy" real até F28; até lá, merge na `main` conta como deploy.

## 5. Antipadrões (recusar na autorrevisão)

- PR que mistura fatia e refactor oportunista.
- "Corrige CI" junto com feature.
- Commit de `.godot/`, `export_presets.cfg`, `.env`, `*.exe`, `*.pck`.
- Teste que passa sem assert, ou `assert_true(true)` para "cobrir".
- Número do GDB copiado para um script "só por enquanto".
- Tela sem estado `error`/`empty` "porque nunca acontece".
- Afirmar "funciona" sem saída real de comando na descrição.

