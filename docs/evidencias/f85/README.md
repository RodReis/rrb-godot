# F85 / SPEC-085 — Tutorial guiado

Evidência de aceite (issue #251, ADR-0026 itens 5–6, ADR-0029).

## Testes (aceite 1 a 3)

| Suíte | Resultado |
|---|---|
| Game + shared (`tools/test.ps1 -Module game`) | 1.909/1.909 |
| Launcher + shared (`tools/test.ps1 -Module launcher`) | 830/830 |
| Backend unitário (`pnpm -C backend test`) | 162/162; `lint` e `typecheck` limpos |
| Backend e2e (`pnpm -C backend test:e2e`), inclusive a migração 0004 | **não rodou localmente** (sem Postgres/Docker); fica para a CI |
| `gdformat` / `gdlint` nos `.gd` tocados | sem problemas |

Testes novos: `test_offline_result` (10), `test_tutorial_rules` (14), `test_launch_args_tutorial` (3), `test_match_clock_tutorial` (8), `test_tutorial_flow` e ampliações de `test_lobby_screen` e `test_profile_service` no Launcher, `users`/`queue` no backend.

## Soak (aceite 4)

`tools/soak.ps1 -Count 10 -Parallel 8` com o Game e o BotInput já alterados: **10/10 terminadas, 0 falhas**, todas por `kill_goal`, 364–508 s (média 431 s).

## Verificação do PI (aceite 5) e capturas (aceite 6)

Aprovada pelo PI em 2026-10-22 numa sessão de `game -- --offline --tutorial`. O log da sessão (`[tutorial] passo ...`) mostra os seis passos percorridos em ordem, o relógio saltando para a fase 2 e o bot entrando; a sessão terminou por saída do jogador (`tutorial/quit`), então o caminho "venceu o bot → `completed`" e a liberação da fila pelo Launcher **não foram vistos ao vivo**; ficam cobertos só pelos testes (`OfflineResult.for_match`, `test_tutorial_flow`).

Captura no roadmap: `docs/roadmap/img/mvp4-f85-tutorial-passo1.webp` (cartão do passo 1/6 com o relógio parado, tirada com `tools/screenshot.ps1`).

## Decisões de implementação

- Herói e bot nascem no nível 6 (o R do Cavaleiro exige o 6 e o passo 3 vem antes de qualquer XP); no passo 4 o roteiro completa o XP até faltar 1 para o nível 7, para o abate fechar o nível.
- O relógio da partida fica parado nos passos 1 a 5 e salta para o fim da fase 1 no passo 6; o bot fica parado até a fase 2.
- Derrota para o bot no passo 6 grava `quit` (o tutorial não conta como concluído).
- Motivo `history` na coluna `users.queue_unlock_reason` para quem a migração libera por já ter partida `finished` ou `aborted`.
